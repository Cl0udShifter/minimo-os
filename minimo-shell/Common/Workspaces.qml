// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Workspaces de Hyprland (sintaxis de dispatch Lua de Hyprland 0.56).
Singleton {
    id: root
    readonly property var list: Hyprland.workspaces.values.filter(w => w.id > 0).sort((a, b) => a.id - b.id)
    readonly property int activeId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
    property real lastSwitch: 0      // para el indicador de puntos
    property real lastWheel: 0

    function dispatchWs(target) {
        // Hyprland.dispatch() no entiende la sintaxis Lua: se usa hyprctl.
        Quickshell.execDetached(["sh", "-c", "hyprctl dispatch 'hl.dsp.focus({workspace=\"" + target + "\"})' >/dev/null 2>&1"])
        lastSwitch = Date.now()
    }
    // Una muesca de rueda = un workspace (con enfriamiento).
    function wheel(deltaY) {
        const now = Date.now()
        if (deltaY === 0 || now - lastWheel < 220) return
        lastWheel = now
        dispatchWs(deltaY > 0 ? "r-1" : "r+1")
    }
    function goTo(id) { dispatchWs(String(id)) }
    function goEmpty() { dispatchWs("emptynm") }
}
