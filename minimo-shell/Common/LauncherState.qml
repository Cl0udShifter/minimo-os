// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Estado do lançador (Super+B). A partir do Hyprland:
//   qs -p ~/Projetos/minimo-os/minimo-shell ipc call launcher toggle
Singleton {
    id: root
    property bool open: false
    function toggle() { open = !open }
    function show() { open = true }
    function hide() { open = false }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle() }
        function open(): void { root.show() }
        function close(): void { root.hide() }
    }
}
