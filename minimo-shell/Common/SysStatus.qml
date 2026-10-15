// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Estado del sistema para el panel de la isla (deslizar sobre la isla compacta).
// - Siempre: chequeo liviano de conectividad (nmcli) cada 10 s → `online` (punto rojo).
// - Solo con el panel abierto (acquire/release): recursos cada 2 s y red/dispositivos cada 8 s,
//   con scripts/sysstatus.py (un proceso corto por consulta, nada fijo).
// No lee otros singletons.
Singleton {
    id: root
    property int users: 0
    function acquire() { users++; if (users === 1) { full.go(); conn.go() } }
    function release() { users = Math.max(0, users - 1) }

    // Conectividad: "full" | "limited" | "portal" | "none" | "unknown"
    property string connectivity: "unknown"
    readonly property bool known: connectivity !== "unknown" && connectivity !== ""
    readonly property bool online: connectivity === "full"

    property var res: null      // { cpu, memUsed, memTotal, diskUsed, diskTotal, temp }
    property var net: null      // { type, name, device, signal, connectivity }
    property var dev: null      // { keyboards, mice, audio, bluetooth, usb }
    property var gpu: null      // { name, util, temp } | null

    readonly property string script: Qt.resolvedUrl("../scripts/sysstatus.py").toString().replace("file://", "")

    function gib(b) { return (b / 1073741824).toFixed(1).replace(".", ",") }

    function setAudioSink(sinkId) {
        Quickshell.execDetached(["pactl", "set-default-sink", sinkId])
        if (root.dev && root.dev.audioSinks) {
            let activeName = root.dev.audio
            const list = root.dev.audioSinks.map(s => {
                const item = Object.assign({}, s, { active: s.id === sinkId })
                if (item.active) activeName = item.name
                return item
            })
            root.dev = Object.assign({}, root.dev, { audioSinks: list, audio: activeName })
        }
        audioRefreshTimer.restart()
    }
    Timer { id: audioRefreshTimer; interval: 350; onTriggered: full.go() }

    Process {
        id: conn
        function go() { if (!running) running = true }
        command: ["nmcli", "networking", "connectivity", "check"]
        stdout: StdioCollector { onStreamFinished: root.connectivity = text.trim() || "unknown" }
    }
    Timer { running: true; repeat: true; interval: 10000; triggeredOnStart: true; onTriggered: conn.go() }

    Process {
        id: resP
        function go() { if (!running) running = true }
        command: [root.script, "res"]
        stdout: StdioCollector { onStreamFinished: { try { root.res = JSON.parse(text).res } catch (e) {} } }
    }
    Process {
        id: full
        function go() { if (!running) running = true }
        command: [root.script, "full"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    root.res = j.res; root.net = j.net; root.dev = j.dev; root.gpu = j.gpu
                    if (j.net && j.net.connectivity) root.connectivity = j.net.connectivity
                } catch (e) {}
            }
        }
    }
    Timer { running: root.users > 0; repeat: true; interval: 2000; onTriggered: resP.go() }
    Timer { running: root.users > 0; repeat: true; interval: 8000; onTriggered: full.go() }
}
