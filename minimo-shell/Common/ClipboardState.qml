// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Gerenciador de estado do Histórico da Área de Transferência (Clipboard Manager).
Singleton {
    id: root

    property bool open: false
    property var items: []
    property bool loading: false
    property string filterText: ""

    function show() {
        open = true
        refresh()
    }

    function hide() {
        open = false
    }

    function toggle() {
        if (open) hide()
        else show()
    }

    function refresh() {
        loading = true
        listProc.running = false
        listProc.running = true
    }

    function copyItem(id) {
        if (!id) return
        copyProc.run(id)
        hide()
    }

    function deleteItem(id) {
        if (!id) return
        deleteProc.run(id)
    }

    function clearAll() {
        clearProc.running = false
        clearProc.running = true
    }

    Process {
        id: listProc
        command: ["python3", Qt.resolvedUrl("../scripts/clipboard.py").toString().replace("file://", ""), "list"]
        stdout: StdioCollector {
            onDataChanged: {
                if (!data) return
                try {
                    root.items = JSON.parse(data)
                } catch (e) {
                    console.log("Erro ao interpretar histórico do clipboard:", e)
                }
                root.loading = false
            }
        }
    }

    Process {
        id: copyProc
        function run(cid) {
            command = ["python3", Qt.resolvedUrl("../scripts/clipboard.py").toString().replace("file://", ""), "copy", cid.toString()]
            running = true
        }
    }

    Process {
        id: deleteProc
        function run(cid) {
            command = ["python3", Qt.resolvedUrl("../scripts/clipboard.py").toString().replace("file://", ""), "delete", cid.toString()]
            running = true
        }
        onExited: root.refresh()
    }

    Process {
        id: clearProc
        command: ["python3", Qt.resolvedUrl("../scripts/clipboard.py").toString().replace("file://", ""), "clear"]
        onExited: {
            root.items = []
            root.refresh()
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            root.toggle()
        }

        function show(): void {
            root.show()
        }

        function hide(): void {
            root.hide()
        }

        function clear(): void {
            root.clearAll()
        }

        function refresh(): void {
            root.refresh()
        }
    }
}
