// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import "../../Common"
import ".."

// Accesos rápidos y energía (las de energía piden confirmación).
Column {
    id: root
    signal done()
    signal desktops()
    signal settings()
    spacing: 8

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); root.done() }

    readonly property string shotCmd: 'd="$HOME/Imágenes/Capturas"; mkdir -p "$d"; g=$(slurp) || exit 0; grim -g "$g" "$d/captura-$(date +%Y%m%d-%H%M%S).png"'

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        MenuButton { icon: "terminal"; label: "Terminal"; onActivated: root.run("ghostty") }
        // Grabar pantalla: cierra la isla y arranca a los 0,4 s (para no grabarla abierta).
        MenuButton {
            icon: Recorder.recording ? "stop" : "record"
            label: Recorder.recording ? "Detener" : "Grabar"
            active: Recorder.recording
            onActivated: { if (Recorder.recording) Recorder.stop(); else Recorder.start(400); root.done() }
        }
        MenuButton { icon: "capture"; label: "Captura"; onActivated: root.run("sleep 0.3; " + root.shotCmd) }
        MenuButton { icon: "desktops"; label: "Escritorios"; onActivated: root.desktops() }
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        MenuButton { icon: "logout"; label: "Cerrar sesión"; confirm: true; onActivated: root.run("hyprctl dispatch 'hl.dsp.exit()'") }
        MenuButton { icon: "restart"; label: "Reiniciar"; confirm: true; onActivated: root.run("systemctl reboot") }
        MenuButton { icon: "power"; label: "Apagar"; confirm: true; onActivated: root.run("systemctl poweroff") }
        MenuButton { icon: "settings"; label: "Ajustes"; onActivated: root.settings() }
    }
}
