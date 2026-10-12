// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Brillo y saturación por software (shader de Hyprland), persistidos en
// ~/.config/minimo-os/state.json y reaplicados al iniciar. También guarda el fondo.
Singleton {
    id: root
    property real saturation: 1.0
    property real brightness: 1.0
    property bool loaded: false
    property string wallpaper: ""
    property bool islandAutoHide: true      // ocultar la isla automáticamente
    property bool characterAnimated: true   // personaje animado (si no, quieto)
    property string theme: "light"          // "light" | "dark"
    property int sleepMinutes: 1            // dormir tras inactividad (1, 2 o 5 min)

    function setWallpaper(path) { wallpaper = path; save() }
    function setIslandAutoHide(v) { islandAutoHide = v; save() }
    function setCharacterAnimated(v) { characterAnimated = v; save() }
    function setSleepMinutes(v) { sleepMinutes = v; save() }
    function setTheme(v) { theme = v; save() }
    // Empuja el tema al singleton Theme (sin dependencia inversa: evita init cíclico).
    onThemeChanged: Theme.dark = theme === "dark"
    function save() {
        file.setText(JSON.stringify({ saturation: root.saturation, brightness: root.brightness, wallpaper: root.wallpaper,
                                     islandAutoHide: root.islandAutoHide, characterAnimated: root.characterAnimated,
                                     sleepMinutes: root.sleepMinutes, theme: root.theme }, null, 2))
    }

    readonly property string stateDir: Quickshell.env("HOME") + "/.config/minimo-os"
    readonly property string applyScript: Qt.resolvedUrl("../scripts/apply-color.sh").toString().replace("file://", "")

    function set(sat, bri) {
        saturation = Math.max(0, Math.min(2, sat))
        brightness = Math.max(0.3, Math.min(1, bri))
        applyTimer.restart()
    }

    Timer {
        id: applyTimer
        interval: 150
        onTriggered: {
            Quickshell.execDetached([root.applyScript, root.saturation.toFixed(3), root.brightness.toFixed(3)])
            root.save()
        }
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.stateDir]
        onExited: file.path = root.stateDir + "/state.json"
    }

    FileView {
        id: file
        blockLoading: false
        printErrors: false
        onLoaded: {
            try {
                const s = JSON.parse(text())
                root.wallpaper = s.wallpaper ?? ""
                root.islandAutoHide = s.islandAutoHide ?? true
                root.characterAnimated = s.characterAnimated ?? true
                root.sleepMinutes = s.sleepMinutes ?? 1
                root.theme = s.theme === "dark" ? "dark" : "light"
                root.set(s.saturation ?? 1.0, s.brightness ?? 1.0)
            } catch (e) {}
            root.loaded = true
        }
        onLoadFailed: root.loaded = true
    }
}
