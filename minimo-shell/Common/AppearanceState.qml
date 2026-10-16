// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Gerenciador central de aparência das janelas (gaps, bordas, arredondamento e opacidade).
// Persiste configurações em ~/.config/minimo-os/appearance.json
// e aplica dinamicamente ao Hyprland, regravando hypr/minimo/apariencia.lua.
Singleton {
    id: root

    property int gapsIn: 4
    property int gapsOut: 4
    property int rounding: 12
    property int borderSize: 0
    property real activeOpacity: 1.0
    property real inactiveOpacity: 1.0
    property bool resizeOnBorder: false
    property bool loaded: false

    readonly property string stateDir: Quickshell.env("HOME") + "/.config/minimo-os"
    readonly property string jsonPath: stateDir + "/appearance.json"
    readonly property string applyScript: Qt.resolvedUrl("../scripts/apply-appearance.py").toString().replace("file://", "")

    IpcHandler {
        target: "appearance"
        function reset() {
            root.resetDefaults()
        }
        function setGapsIn(v: int) { root.setGapsIn(v) }
        function setGapsOut(v: int) { root.setGapsOut(v) }
        function setRounding(v: int) { root.setRounding(v) }
        function setBorderSize(v: int) { root.setBorderSize(v) }
        function setActiveOpacity(v: real) { root.setActiveOpacity(v) }
        function setInactiveOpacity(v: real) { root.setInactiveOpacity(v) }
        function setResizeOnBorder(v: bool) { root.setResizeOnBorder(v) }
    }

    function setGapsIn(v) {
        gapsIn = Math.max(0, Math.min(16, Math.round(v)))
        scheduleApply()
    }

    function setGapsOut(v) {
        gapsOut = Math.max(0, Math.min(24, Math.round(v)))
        scheduleApply()
    }

    function setRounding(v) {
        rounding = Math.max(0, Math.min(24, Math.round(v)))
        scheduleApply()
    }

    function setBorderSize(v) {
        borderSize = Math.max(0, Math.min(4, Math.round(v)))
        scheduleApply()
    }

    function setActiveOpacity(v) {
        activeOpacity = Math.max(0.70, Math.min(1.0, Math.round(v * 100) / 100))
        scheduleApply()
    }

    function setInactiveOpacity(v) {
        inactiveOpacity = Math.max(0.70, Math.min(1.0, Math.round(v * 100) / 100))
        scheduleApply()
    }

    function setResizeOnBorder(v) {
        resizeOnBorder = v
        scheduleApply()
    }

    function resetDefaults() {
        gapsIn = 4
        gapsOut = 4
        rounding = 12
        borderSize = 0
        activeOpacity = 1.0
        inactiveOpacity = 1.0
        resizeOnBorder = false
        scheduleApply()
    }

    function getConfigObject() {
        return {
            gapsIn: root.gapsIn,
            gapsOut: root.gapsOut,
            rounding: root.rounding,
            borderSize: root.borderSize,
            activeOpacity: root.activeOpacity,
            inactiveOpacity: root.inactiveOpacity,
            resizeOnBorder: root.resizeOnBorder
        }
    }

    function scheduleApply() {
        if (!root.loaded) return
        applyTimer.restart()
    }

    Timer {
        id: applyTimer
        interval: 80
        onTriggered: {
            const data = root.getConfigObject()
            file.setText(JSON.stringify(data, null, 2))
            Quickshell.execDetached([root.applyScript, JSON.stringify(data)])
        }
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.stateDir]
        onExited: file.path = root.jsonPath
    }

    FileView {
        id: file
        blockLoading: false
        printErrors: false
        onLoaded: {
            try {
                const s = JSON.parse(text())
                if (s.gapsIn !== undefined) root.gapsIn = s.gapsIn
                if (s.gapsOut !== undefined) root.gapsOut = s.gapsOut
                if (s.rounding !== undefined) root.rounding = s.rounding
                if (s.borderSize !== undefined) root.borderSize = s.borderSize
                if (s.activeOpacity !== undefined) root.activeOpacity = s.activeOpacity
                if (s.inactiveOpacity !== undefined) root.inactiveOpacity = s.inactiveOpacity
                if (s.resizeOnBorder !== undefined) root.resizeOnBorder = s.resizeOnBorder
            } catch (e) {}
            root.loaded = true
        }
        onLoadFailed: {
            root.loaded = true
            // Salva os padrões iniciais se for o primeiro uso
            scheduleApply()
        }
    }
}
