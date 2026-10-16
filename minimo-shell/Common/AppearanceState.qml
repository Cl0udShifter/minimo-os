// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Gerenciador central de aparência, janelas e efeitos visuais do Minimo OS.
// Persiste configurações em ~/.config/minimo-os/appearance.json
// e aplica dinamicamente ao Hyprland, regravando hypr/minimo/apariencia.lua.
Singleton {
    id: root

    // Janelas e Espaçamento
    property int gapsIn: 4
    property int gapsOut: 4
    property int rounding: 12
    property int borderSize: 0
    property real activeOpacity: 1.0
    property real inactiveOpacity: 1.0
    property bool resizeOnBorder: false

    // Animações e Efeitos Visuais
    property string animPreset: "smooth"     // "smooth" | "fast" | "instant" | "disabled"
    property bool blurEnabled: true
    property int blurSize: 8                // 3 a 14 px
    property int blurPasses: 2              // 1 a 4 passes
    property bool shadowEnabled: true
    property int shadowRange: 30            // 10 a 60 px

    property bool loaded: false

    readonly property string stateDir: Quickshell.env("HOME") + "/.config/minimo-os"
    readonly property string jsonPath: stateDir + "/appearance.json"
    readonly property string applyScript: Qt.resolvedUrl("../scripts/apply-appearance.py").toString().replace("file://", "")

    IpcHandler {
        target: "appearance"
        function reset() {
            root.resetDefaults()
        }
        function resetEffects() {
            root.resetEffectsDefaults()
        }
        function setGapsIn(v: int) { root.setGapsIn(v) }
        function setGapsOut(v: int) { root.setGapsOut(v) }
        function setRounding(v: int) { root.setRounding(v) }
        function setBorderSize(v: int) { root.setBorderSize(v) }
        function setActiveOpacity(v: real) { root.setActiveOpacity(v) }
        function setInactiveOpacity(v: real) { root.setInactiveOpacity(v) }
        function setResizeOnBorder(v: bool) { root.setResizeOnBorder(v) }
        function setAnimPreset(v: string) { root.setAnimPreset(v) }
        function setBlurEnabled(v: bool) { root.setBlurEnabled(v) }
        function setBlurSize(v: int) { root.setBlurSize(v) }
        function setShadowEnabled(v: bool) { root.setShadowEnabled(v) }
        function setShadowRange(v: int) { root.setShadowRange(v) }
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

    function setAnimPreset(v) {
        if (v === "smooth" || v === "fast" || v === "instant" || v === "disabled") {
            animPreset = v
            scheduleApply()
        }
    }

    function setBlurEnabled(v) {
        blurEnabled = v
        scheduleApply()
    }

    function setBlurSize(v) {
        blurSize = Math.max(3, Math.min(14, Math.round(v)))
        blurPasses = blurSize >= 11 ? 3 : (blurSize >= 6 ? 2 : 1)
        scheduleApply()
    }

    function setShadowEnabled(v) {
        shadowEnabled = v
        scheduleApply()
    }

    function setShadowRange(v) {
        shadowRange = Math.max(10, Math.min(60, Math.round(v)))
        scheduleApply()
    }

    function resetEffectsDefaults() {
        animPreset = "smooth"
        blurEnabled = true
        blurSize = 8
        blurPasses = 2
        shadowEnabled = true
        shadowRange = 30
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
        resetEffectsDefaults()
    }

    function getConfigObject() {
        return {
            gapsIn: root.gapsIn,
            gapsOut: root.gapsOut,
            rounding: root.rounding,
            borderSize: root.borderSize,
            activeOpacity: root.activeOpacity,
            inactiveOpacity: root.inactiveOpacity,
            resizeOnBorder: root.resizeOnBorder,
            animPreset: root.animPreset,
            blurEnabled: root.blurEnabled,
            blurSize: root.blurSize,
            blurPasses: root.blurPasses,
            shadowEnabled: root.shadowEnabled,
            shadowRange: root.shadowRange
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
                if (s.animPreset !== undefined) root.animPreset = s.animPreset
                if (s.blurEnabled !== undefined) root.blurEnabled = s.blurEnabled
                if (s.blurSize !== undefined) root.blurSize = s.blurSize
                if (s.blurPasses !== undefined) root.blurPasses = s.blurPasses
                if (s.shadowEnabled !== undefined) root.shadowEnabled = s.shadowEnabled
                if (s.shadowRange !== undefined) root.shadowRange = s.shadowRange
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
