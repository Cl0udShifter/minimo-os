// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Gerenciador central de regras de janelas por aplicativo do Minimo OS.
// Persiste regras em ~/.config/minimo-os/window-rules.json
// e compila para hypr/minimo/regras_usuario.lua.
Singleton {
    id: root

    property var rules: ({})
    property bool loaded: false
    property string searchQuery: ""

    readonly property string configDir: Quickshell.env("HOME") + "/.config/minimo-os"
    readonly property string jsonPath: configDir + "/window-rules.json"
    readonly property string managerScript: Qt.resolvedUrl("../scripts/window-rules-manager.py").toString().replace("file://", "")

    function deriveClass(e) {
        if (!e) return ""
        const idClean = (e.id || "").replace(/\.desktop$/, "")
        const execPart = (e.exec || "").split(" ")[0].split("/").pop() || ""
        const execBinary = execPart.toLowerCase()
        const parts = []
        if (idClean) parts.push(idClean.replace(/\./g, "\\."))
        if (execBinary && execBinary !== idClean.toLowerCase() && execBinary !== "sh" && execBinary !== "bash") {
            parts.push(execBinary.replace(/\./g, "\\."))
        }
        return "^(" + (parts.length > 0 ? parts.join("|") : idClean) + ")$"
    }

    function getRule(appId) {
        if (!appId || !rules[appId]) {
            return { id: appId, mode: "default", workspace: 0, class: "" }
        }
        return rules[appId]
    }

    function setMode(appId, name, appClass, mode) {
        const cur = getRule(appId)
        const ws = cur.workspace || 0
        const cls = appClass || cur.class || ("^(" + appId + ")$")
        
        const newRules = Object.assign({}, root.rules)
        if (mode === "default" && ws === 0) {
            delete newRules[appId]
        } else {
            newRules[appId] = {
                id: appId,
                name: name || appId,
                class: cls,
                mode: mode,
                workspace: ws
            }
        }
        root.rules = newRules
        Quickshell.execDetached(["python3", root.managerScript, "set", appId, name || appId, cls, mode, ws.toString()])
    }

    function setWorkspace(appId, name, appClass, ws) {
        const cur = getRule(appId)
        const mode = cur.mode || "default"
        const cls = appClass || cur.class || ("^(" + appId + ")$")

        const newRules = Object.assign({}, root.rules)
        if (mode === "default" && ws === 0) {
            delete newRules[appId]
        } else {
            newRules[appId] = {
                id: appId,
                name: name || appId,
                class: cls,
                mode: mode,
                workspace: ws
            }
        }
        root.rules = newRules
        Quickshell.execDetached(["python3", root.managerScript, "set", appId, name || appId, cls, mode, ws.toString()])
    }

    function resetRule(appId) {
        const newRules = Object.assign({}, root.rules)
        delete newRules[appId]
        root.rules = newRules
        Quickshell.execDetached(["python3", root.managerScript, "delete", appId])
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
                root.rules = JSON.parse(loaderProcess.buffer.trim()) || {}
            } catch (e) {
                root.rules = {}
            }
            root.loaded = true
        }
    }
}
