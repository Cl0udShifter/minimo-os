// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Estado global do OSD de volume.
Singleton {
    id: root
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.audio !== null
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false

    property bool initialized: false
    signal triggered()

    Timer {
        id: initTimer
        interval: 1000
        running: true
        onTriggered: root.initialized = true
    }

    Connections {
        target: root.ready ? root.sink.audio : null
        function onVolumeChanged() {
            if (!root.initialized) return
            root.show()
        }
        function onMutedChanged() {
            if (!root.initialized) return
            root.show()
        }
    }

    onVolumeChanged: {
        if (!initialized) return
        root.show()
    }

    onMutedChanged: {
        if (!initialized) return
        root.show()
    }

    function show() {
        console.log("VolumeOSDState: show() called, volume=" + root.volume + " muted=" + root.muted)
        triggered()
    }

    IpcHandler {
        target: "volume"
        function trigger(): void { root.show() }
        function open(): void { root.show() }
        function bump(): void { root.show() }
    }
}
