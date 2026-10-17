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

    readonly property string shotCmd: 'd="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Imagens")/Capturas"; mkdir -p "$d"; fn="captura-$(date +%Y%m%d-%H%M%S).png"; f="$d/$fn"; g=$(slurp) || exit 0; grim -g "$g" "$f" && (wl-copy < "$f" 2>/dev/null || true) && notify-send -a "Captura de Tela" -i "$f" "Captura salva" "$fn em $d"'

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        MenuButton { icon: "terminal"; label: "Terminal"; onActivated: root.run("ghostty") }
        // Gravar tela: fecha a ilha e inicia após 0,4 s (para não gravá-la aberta).
        MenuButton {
            icon: Recorder.recording ? "stop" : "record"
            label: Recorder.recording ? "Parar" : "Gravar"
            active: Recorder.recording
            onActivated: { if (Recorder.recording) Recorder.stop(); else Recorder.start(400); root.done() }
        }
        MenuButton { icon: "capture"; label: "Captura"; onActivated: root.run("sleep 0.3; " + root.shotCmd) }
        MenuButton { icon: "desktops"; label: "Áreas de trabalho"; onActivated: root.desktops() }
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        MenuButton { icon: "logout"; label: "Encerrar sessão"; confirm: true; onActivated: root.run("hyprctl dispatch 'hl.dsp.exit()'") }
        MenuButton { icon: "restart"; label: "Reiniciar"; confirm: true; onActivated: root.run("systemctl reboot") }
        MenuButton { icon: "power"; label: "Desligar"; confirm: true; onActivated: root.run("systemctl poweroff") }
        MenuButton { icon: "settings"; label: "Configurações"; onActivated: root.settings() }
    }
}
