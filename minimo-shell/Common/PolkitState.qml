// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Gerenciador de estado para o diálogo de autenticação Polkit do Minimo OS.
// Recebe requisições do daemon minimo-polkit-agent e envia respostas via socket.
Singleton {
    id: root

    property bool open: false
    property string actionId: ""
    property string message: "Autenticação é necessária para executar esta ação."
    property string user: ""
    property string iconName: "lock"
    property string errorMsg: ""
    property bool busy: false

    signal shake()
    signal focusField()

    readonly property string sendScript: Qt.resolvedUrl("../scripts/polkit-send.py").toString().replace("file://", "")

    function showDialog(data) {
        actionId = data.actionId || ""
        message = data.message || "Autenticação é necessária para executar esta ação."
        user = data.user || "root"
        iconName = data.iconName || "lock"
        errorMsg = ""
        busy = false
        open = true
        focusField()
    }

    function dismiss() {
        open = false
        busy = false
        errorMsg = ""
    }

    function submitPassword(password) {
        busy = true
        errorMsg = ""
        Quickshell.execDetached(["python3", root.sendScript, "auth", password])
    }

    function cancelAuth() {
        Quickshell.execDetached(["python3", root.sendScript, "cancel"])
        dismiss()
    }

    IpcHandler {
        target: "polkit"

        function open(payloadJson: string): void {
            try {
                const data = JSON.parse(payloadJson)
                root.showDialog(data)
            } catch (e) {
                console.error("PolkitState: erro ao parsear payload:", e)
            }
        }

        function error(msg: string): void {
            root.busy = false
            root.errorMsg = msg || "Senha incorreta. Tente novamente."
            root.shake()
            root.focusField()
        }

        function success(): void {
            root.dismiss()
        }

        function close(): void {
            root.dismiss()
        }
    }
}
