// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Canal para disparar reacciones del personaje y mostrar la isla desde afuera:
//   qs -p ~/Proyectos/minimo-os/minimo-shell ipc call character react giggle
//   qs -p ~/Proyectos/minimo-os/minimo-shell ipc call character list | look 0.9 0 | sleep | wake
//   qs -p ~/Proyectos/minimo-os/minimo-shell ipc call island reveal|dismiss|open|close
Singleton {
    id: root
    signal react(string name)
    signal islandCommand(string cmd)
    signal gaze(real x, real y, int ms)
    signal pet()
    readonly property var names: ["hop", "doubleHop", "spin", "giggle", "lookAround", "barrelRoll", "surprise",
                                  "wink", "dizzy", "yawn", "curious", "greet", "happyBounce", "startled"]

    IpcHandler {
        target: "character"
        function react(name: string): string {
            if (root.names.indexOf(name) < 0) return "desconocida: " + name
            root.react(name); return "ok"
        }
        function list(): string { return root.names.join(" ") }
        // Forzar la mirada (x, y en -1..1) durante unos segundos.
        function look(x: real, y: real): void { root.gaze(x, y, 4000) }
        // Caricia (como varios clics seguidos sobre el personaje).
        function pet(): void { root.pet() }
        function sleep(): void { IdleState.sleepNow() }
        function wake(): void { IdleState.wake() }
    }
    IpcHandler {
        target: "island"
        function reveal(): void { root.islandCommand("show") }
        function dismiss(): void { root.islandCommand("hide") }
        function open(): void { root.islandCommand("open") }
        function close(): void { root.islandCommand("close") }
        function status(): void { root.islandCommand("status") }
    }
}
