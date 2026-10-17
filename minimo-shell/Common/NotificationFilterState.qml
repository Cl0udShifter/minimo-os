// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Gerenciador de estado do filtro de notificações por aplicativo.
// Controla Não Perturbe (DND) e lista de aplicativos com notificações silenciadas.
Singleton {
    id: root

    property var mutedApps: []
    property bool dnd: false
    property var knownApps: ({})
    property bool loaded: false

    signal configChanged()
    onMutedAppsChanged: configChanged()
    onDndChanged: configChanged()

    readonly property string managerScript: Qt.resolvedUrl("../scripts/notification-filter-manager.py").toString().replace("file://", "")

    // Verifica se um aplicativo está silenciado
    function isMuted(appId, appName) {
        if (!appId && !appName) return false
        const id1 = (appId || "").toLowerCase().replace(".desktop", "").trim()
        const id2 = (appName || "").toLowerCase().trim()

        for (let i = 0; i < root.mutedApps.length; ++i) {
            const m = (root.mutedApps[i] || "").toLowerCase().trim()
            if (!m) continue
            if (m === id1 || m === id2) return true
            // Tratar casos de pacote reverso (ex: org.mozilla.firefox e firefox)
            if (id1.endsWith("." + m) || m.endsWith("." + id1)) return true
            const lastPart1 = id1.split(".").pop()
            const lastPartM = m.split(".").pop()
            if (lastPart1 === lastPartM && lastPart1 !== "") return true
        }
        return false
    }

    // Alternar silenciamento de um aplicativo
    function toggleMute(appId, name, icon) {
        const cleanId = (appId || "").toLowerCase().replace(".desktop", "").trim()
        if (!cleanId) return
        const current = isMuted(cleanId, name)
        setMuted(cleanId, !current, name, icon)
    }

    // Definir silenciamento explícito
    function setMuted(appId, muted, name, icon) {
        const cleanId = (appId || "").toLowerCase().replace(".desktop", "").trim()
        if (!cleanId) return

        const currentList = root.mutedApps.slice()
        const index = currentList.indexOf(cleanId)

        if (muted && index < 0) {
            currentList.push(cleanId)
        } else if (!muted && index >= 0) {
            currentList.splice(index, 1)
        }

        root.mutedApps = currentList

        // Atualizar knownApps
        if (name || icon) {
            const nextKnown = Object.assign({}, root.knownApps)
            nextKnown[cleanId] = {
                name: name || cleanId,
                icon: icon || cleanId
            }
            root.knownApps = nextKnown
        }

        Quickshell.execDetached([
            "python3", root.managerScript, "set-muted",
            cleanId, muted ? "true" : "false", name || "", icon || ""
        ])
    }

    // Definir Não Perturbe global
    function setDnd(enabled) {
        root.dnd = !!enabled
        Notifs.dnd = root.dnd
        Quickshell.execDetached([
            "python3", root.managerScript, "set-dnd",
            enabled ? "true" : "false"
        ])
    }

    // Registrar aplicativo que enviou notificação
    function recordNotification(appId, appName, icon) {
        const cleanId = (appId || appName || "").toLowerCase().replace(".desktop", "").trim()
        if (!cleanId) return

        if (!root.knownApps[cleanId]) {
            const nextKnown = Object.assign({}, root.knownApps)
            nextKnown[cleanId] = {
                name: appName || cleanId,
                icon: icon || cleanId
            }
            root.knownApps = nextKnown

            Quickshell.execDetached([
                "python3", root.managerScript, "record-app",
                cleanId, appName || "", icon || ""
            ])
        }
    }

    function refresh() {
        loaderProcess.buffer = ""
        loaderProcess.running = true
    }

    Component.onCompleted: refresh()

    Process {
        id: loaderProcess
        property string buffer: ""
        command: ["python3", root.managerScript, "get"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => loaderProcess.buffer += data
        }
        onExited: {
            try {
                const parsed = JSON.parse(loaderProcess.buffer.trim())
                root.dnd = !!parsed.dnd
                Notifs.dnd = root.dnd
                root.mutedApps = Array.isArray(parsed.mutedApps) ? parsed.mutedApps : []
                root.knownApps = (parsed.knownApps && typeof parsed.knownApps === "object") ? parsed.knownApps : {}
            } catch (e) {
                console.warn("Erro ao processar notificações salvas:", e)
            }
            root.loaded = true
        }
    }

    IpcHandler {
        target: "notifications"
        function toggleDnd(): void { root.setDnd(!root.dnd) }
        function setDnd(val: bool): void { root.setDnd(val) }
        function getDnd(): bool { return root.dnd }
    }
}
