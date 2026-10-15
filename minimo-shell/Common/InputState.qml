// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Gerenciador central de configurações de Mouse, Teclado e Touchpad do Minimo OS.
// Persiste configurações em ~/.config/minimo-os/input.json
// e aplica dinamicamente ao Hyprland, regravando hypr/minimo/entrada.lua.
Singleton {
    id: root

    property string kbLayout: "br"
    property string kbVariant: "abnt2"
    property string kbModel: ""
    property bool numlockByDefault: true
    property int followMouse: 1              // 1 = foco segue o mouse (hover), 0 = apenas ao clicar
    property real sensitivity: 0.0          // -1.0 a 1.0 (0.0 = normal)
    property string accelProfile: "adaptive" // "adaptive" | "flat"
    property bool naturalScrollMouse: false  // inverter scroll do mouse normal
    property bool touchpadTapToClick: true
    property bool touchpadNaturalScroll: true
    property real touchpadScrollFactor: 1.0  // 0.2 a 2.0
    property bool touchpadGestures: true
    property bool loaded: false

    readonly property var keyboardLayouts: [
        { id: "br", variant: "abnt2", label: "Português (Brasil - ABNT2)", desc: "Layout brasileiro com tecla Ç física" },
        { id: "br", variant: "", label: "Português (Brasil - Padrão)", desc: "Layout brasileiro sem variante específica" },
        { id: "us", variant: "intl", label: "Inglês (EUA - Internacional)", desc: "Acentos e cedilha com dead keys (' + c = ç)" },
        { id: "us", variant: "altgr-intl", label: "Inglês (EUA - AltGr Internacional)", desc: "Acentos e cedilha usando a tecla AltGr" },
        { id: "us", variant: "", label: "Inglês (EUA - Padrão)", desc: "Layout norte-americano QWERTY tradicional" },
        { id: "latam", variant: "", label: "Espanhol (América Latina)", desc: "Layout padrão hispânico com tecla Ñ" },
        { id: "es", variant: "", label: "Espanhol (Espanha)", desc: "Layout castelhano padrão" },
        { id: "de", variant: "", label: "Alemão (QWERTZ)", desc: "Layout padrão da Alemanha" },
        { id: "fr", variant: "", label: "Francês (AZERTY)", desc: "Layout padrão da França" }
    ]

    readonly property string stateDir: Quickshell.env("HOME") + "/.config/minimo-os"
    readonly property string jsonPath: stateDir + "/input.json"
    readonly property string applyScript: Qt.resolvedUrl("../scripts/apply-input.py").toString().replace("file://", "")

    function setKbLayout(layout, variant) {
        kbLayout = layout
        kbVariant = variant || ""
        scheduleApply()
    }

    function setNumlockByDefault(v) {
        numlockByDefault = v
        scheduleApply()
    }

    function setFollowMouse(v) {
        followMouse = v
        scheduleApply()
    }

    function setSensitivity(v) {
        sensitivity = Math.max(-1.0, Math.min(1.0, v))
        scheduleApply()
    }

    function setAccelProfile(v) {
        accelProfile = v
        scheduleApply()
    }

    function setNaturalScrollMouse(v) {
        naturalScrollMouse = v
        scheduleApply()
    }

    function setTouchpadTapToClick(v) {
        touchpadTapToClick = v
        scheduleApply()
    }

    function setTouchpadNaturalScroll(v) {
        touchpadNaturalScroll = v
        scheduleApply()
    }

    function setTouchpadScrollFactor(v) {
        touchpadScrollFactor = Math.max(0.2, Math.min(2.0, v))
        scheduleApply()
    }

    function setTouchpadGestures(v) {
        touchpadGestures = v
        scheduleApply()
    }

    function getConfigObject() {
        return {
            kbLayout: root.kbLayout,
            kbVariant: root.kbVariant,
            kbModel: root.kbModel,
            numlockByDefault: root.numlockByDefault,
            followMouse: root.followMouse,
            sensitivity: root.sensitivity,
            accelProfile: root.accelProfile,
            naturalScrollMouse: root.naturalScrollMouse,
            touchpadTapToClick: root.touchpadTapToClick,
            touchpadNaturalScroll: root.touchpadNaturalScroll,
            touchpadScrollFactor: root.touchpadScrollFactor,
            touchpadGestures: root.touchpadGestures
        }
    }

    function scheduleApply() {
        if (!root.loaded) return
        applyTimer.restart()
    }

    Timer {
        id: applyTimer
        interval: 100
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
                if (s.kbLayout !== undefined) root.kbLayout = s.kbLayout
                if (s.kbVariant !== undefined) root.kbVariant = s.kbVariant
                if (s.kbModel !== undefined) root.kbModel = s.kbModel
                if (s.numlockByDefault !== undefined) root.numlockByDefault = s.numlockByDefault
                if (s.followMouse !== undefined) root.followMouse = s.followMouse
                if (s.sensitivity !== undefined) root.sensitivity = s.sensitivity
                if (s.accelProfile !== undefined) root.accelProfile = s.accelProfile
                if (s.naturalScrollMouse !== undefined) root.naturalScrollMouse = s.naturalScrollMouse
                if (s.touchpadTapToClick !== undefined) root.touchpadTapToClick = s.touchpadTapToClick
                if (s.touchpadNaturalScroll !== undefined) root.touchpadNaturalScroll = s.touchpadNaturalScroll
                if (s.touchpadScrollFactor !== undefined) root.touchpadScrollFactor = s.touchpadScrollFactor
                if (s.touchpadGestures !== undefined) root.touchpadGestures = s.touchpadGestures
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
