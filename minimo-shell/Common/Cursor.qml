// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Posición global del cursor (Hyprland). Un único proceso liviano consulta
// `hyprctl cursorpos` ~25 veces/seg, y solo corre mientras algún consumidor
// (personaje visible) lo necesita. Sin consumidores no hay sondeo.
Singleton {
    id: root
    property int users: 0
    property real x: -1
    property real y: -1
    property bool ok: false
    property real lastMove: 0

    function acquire() { if (users === 0) lastMove = Date.now(); users++ }
    function release() { users = Math.max(0, users - 1) }

    Process {
        running: root.users > 0
        command: ["sh", "-c", "while hyprctl cursorpos; do sleep 0.04; done"]
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/^(-?\d+),\s*(-?\d+)/)
                if (!m) return
                const nx = +m[1], ny = +m[2]
                if (nx !== root.x || ny !== root.y) { root.lastMove = Date.now(); root.x = nx; root.y = ny }
                root.ok = true
            }
        }
    }
}
