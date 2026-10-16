// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Gerenciador central de aplicativos de inicialização do Minimo OS.
// Persiste configurações em ~/.config/minimo-os/autostart.json
// e compila para hypr/minimo/autostart.lua.
Singleton {
    id: root

    property var autostartApps: []
    property bool loaded: false

    readonly property string configDir: Quickshell.env("HOME") + "/.config/minimo-os"
    readonly property string jsonPath: configDir + "/autostart.json"
    readonly property string managerScript: Qt.resolvedUrl("../scripts/autostart-manager.py").toString().replace("file://", "")

    function isAutostart(appId) {
        if (!appId) return false
        for (let i = 0; i < autostartApps.length; ++i) {
            if (autostartApps[i].id === appId) return true
        }
        return false
    }

    function addApp(appId, name, execCmd, icon, workspace) {
        if (!appId || !execCmd) return

        const ws = parseInt(workspace) || 0
        const item = {
            id: appId,
            name: name || appId,
            exec: execCmd,
            icon: icon || "",
            workspace: ws,
            enabled: true
        }

        const next = []
        for (let i = 0; i < autostartApps.length; ++i) {
            if (autostartApps[i].id !== appId) {
                next.push(autostartApps[i])
            }
        }
        next.push(item)
        root.autostartApps = next

        Quickshell.execDetached([
            "python3", root.managerScript, "add",
            appId, name || appId, execCmd, icon || "", ws.toString()
        ])
    }

    function removeApp(appId) {
        if (!appId) return

        const next = []
        for (let i = 0; i < autostartApps.length; ++i) {
            if (autostartApps[i].id !== appId) {
                next.push(autostartApps[i])
            }
        }
        root.autostartApps = next

        Quickshell.execDetached(["python3", root.managerScript, "remove", appId])
    }

    function toggleApp(appId, enabled) {
        if (!appId) return

        const next = []
        for (let i = 0; i < autostartApps.length; ++i) {
            const item = Object.assign({}, autostartApps[i])
            if (item.id === appId) {
                item.enabled = (enabled !== undefined) ? !!enabled : !item.enabled
            }
            next.push(item)
        }
        root.autostartApps = next

        Quickshell.execDetached([
            "python3", root.managerScript, "toggle",
            appId, enabled ? "true" : "false"
        ])
    }

    function setWorkspace(appId, workspace) {
        if (!appId) return

        const ws = parseInt(workspace) || 0
        const next = []
        for (let i = 0; i < autostartApps.length; ++i) {
            const item = Object.assign({}, autostartApps[i])
            if (item.id === appId) {
                item.workspace = ws
            }
            next.push(item)
        }
        root.autostartApps = next

        Quickshell.execDetached([
            "python3", root.managerScript, "set-workspace",
            appId, ws.toString()
        ])
    }

    function launchApp(appId) {
        if (!appId) return
        Quickshell.execDetached(["python3", root.managerScript, "launch", appId])
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
                root.autostartApps = Array.isArray(parsed) ? parsed : []
            } catch (e) {
                root.autostartApps = []
            }
            root.loaded = true
        }
    }
}
