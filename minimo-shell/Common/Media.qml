// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// Estado de reproducción (MPRIS) y nivel de audio para el baile del personaje.
// cava corre en modo crudo solo mientras hay música y un personaje visible bailando.
Singleton {
    id: root
    readonly property bool playing: Mpris.players.values.some(p => p.isPlaying)
    property int users: 0
    property real level: 0          // 0..1, suavizado
    property bool hasLevel: false
    function acquire() { users++ }
    function release() { users = Math.max(0, users - 1) }

    readonly property string conf: Qt.resolvedUrl("../scripts/cava-raw.conf").toString().replace("file://", "")

    Process {
        id: cava
        running: root.users > 0 && root.playing
        command: ["cava", "-p", root.conf]
        stdout: SplitParser {
            onRead: line => {
                const v = line.split(";").filter(x => x !== "").map(Number)
                if (v.length === 0) return
                // graves pesan más
                const lv = (v[0] * 2 + v[1] * 2 + v.slice(2).reduce((a, b) => a + b, 0)) / ((v.length + 2) * 100)
                root.level = root.level * 0.6 + lv * 0.4
                root.hasLevel = true
            }
        }
        onRunningChanged: if (!running) { root.hasLevel = false; root.level = 0 }
    }
}
