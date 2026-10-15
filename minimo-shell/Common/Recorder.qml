// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Gravação de tela com wf-recorder (saída em foco, com áudio do sistema se
// houver pactl). Parar envia SIGINT para que o .mp4 seja finalizado corretamente.
// A partir do Hyprland: qs -p ~/Projetos/minimo-os/minimo-shell ipc call recorder toggle
Singleton {
    id: root
    property string bin: "wf-recorder"
    property bool recording: false
    property bool starting: false
    property int elapsed: 0                 // segundos
    property string file: ""
    property string notice: ""              // mensaje breve para la isla compacta
    readonly property string elapsedText: {
        const m = Math.floor(elapsed / 60), s = elapsed % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    function toggle() { if (recording || starting) stop(); else start() }

    // Arranca tras `delay` ms (para que la isla se cierre antes de grabar).
    function start(delay) {
        if (recording || starting) return
        starting = true
        startDelay.interval = delay || 0
        startDelay.restart()
    }
    function stop() {
        startDelay.stop()
        starting = false
        if (proc.running) {
            proc.signal(2)   // SIGINT → wf-recorder finaliza o arquivo mp4
            forceStopTimer.restart()
        } else {
            recording = false
        }
    }
    function say(msg, ms) { notice = msg; noticeTimer.interval = ms || 2200; noticeTimer.restart() }

    Timer { id: startDelay; onTriggered: root.launch() }
    Timer { id: noticeTimer; onTriggered: root.notice = "" }
    Timer { running: root.recording; interval: 1000; repeat: true; onTriggered: root.elapsed++ }
    Timer {
        id: forceStopTimer
        interval: 2500
        onTriggered: {
            if (proc.running) {
                console.warn("Recorder: wf-recorder não respondeu a SIGINT a tempo, forçando encerramento...")
                proc.signal(15)
                Quickshell.execDetached(["sh", "-c", "sleep 0.8; pkill -9 wf-recorder 2>/dev/null || true"])
            }
            root.recording = false
        }
    }

    function launch() {
        const stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss")
        root.file = "Minimo-" + stamp + ".mp4"
        proc.command = ["sh", "-c",
            'command -v "$1" >/dev/null 2>&1 || exit 127\n' +
            'dir=$(xdg-user-dir VIDEOS 2>/dev/null); [ -n "$dir" ] && [ "$dir" != "$HOME" ] || dir="$HOME/Vídeos"\n' +
            'dir="$dir/Gravações"; mkdir -p "$dir"; echo "DIR:$dir"\n' +
            'out=$(hyprctl activeworkspace 2>/dev/null | sed -n "1s/.* on monitor \\(.*\\):$/\\1/p")\n' +
            'set -- "$1" -f "$dir/$2"; [ -n "$out" ] && set -- "$@" -o "$out"\n' +
            'exec "$@"',
            "minimo-rec", root.bin, root.file]
        root.elapsed = 0
        root.starting = false
        root.recording = true
        proc.running = true
    }

    Process {
        id: proc
        stdout: SplitParser { onRead: l => { if (l.startsWith("DIR:")) root.dir = l.slice(4) } }
        onExited: (code, status) => {
            forceStopTimer.stop()
            const was = root.recording
            root.recording = false
            if (code === 127) root.say("Instale o wf-recorder", 3500)
            else if (was && root.elapsed > 0) root.say("Salvo · " + root.file)
            else if (was) root.say("Não foi possível gravar", 2500)
        }
    }
    property string dir: ""

    IpcHandler {
        target: "recorder"
        function toggle(): void { root.toggle() }
        function start(): void { root.start(0) }
        function stop(): void { root.stop() }
    }
}
