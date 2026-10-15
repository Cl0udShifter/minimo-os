// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Workspaces de Hyprland (sintaxis de dispatch Lua de Hyprland 0.56).
Singleton {
    id: root
    readonly property var list: Hyprland.workspaces.values.filter(w => w.id > 0).sort((a, b) => a.id - b.id)
    readonly property int activeId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
    property real lastSwitch: 0      // para el indicador de puntos
    property real lastWheel: 0

    signal switched()
    function triggerSwitch() {
        lastSwitch = Date.now()
        switched()
    }

    property bool ready: false
    Component.onCompleted: Qt.callLater(() => { ready = true })

    onActiveIdChanged: {
        if (ready) triggerSwitch()
    }

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            const n = ev.name
            if (n === "workspace" || n === "workspacev2" || n === "focusedmon") {
                Hyprland.refreshWorkspaces()
                if (root.ready) root.triggerSwitch()
            } else if (n === "createworkspace" || n === "createworkspacev2" || n === "destroyworkspace" || n === "destroyworkspacev2") {
                Hyprland.refreshWorkspaces()
            }
        }
    }

    function dispatchWs(target) {
        // Hyprland.dispatch() no entiende la sintaxis Lua: se usa hyprctl.
        Quickshell.execDetached(["sh", "-c", "hyprctl dispatch 'hl.dsp.focus({workspace=\"" + target + "\"})' >/dev/null 2>&1"])
        triggerSwitch()
    }
    // Una muesca de rueda = un workspace (con enfriamiento).
    function wheel(deltaY) {
        const now = Date.now()
        if (deltaY === 0 || now - lastWheel < 220) return
        lastWheel = now
        dispatchWs(deltaY > 0 ? "r-1" : "r+1")
    }
    // Reordenar: `order` es la nueva secuencia de IDs; el contenido del escritorio que
    // quedó en la posición i pasa al ID i-ésimo original. Ignora si ya hay uno en curso.
    function reorder(order) {
        const ids = list.map(w => w.id)
        if (reorderProc.running || order.length !== ids.length || order.every((id, i) => id === ids[i])) { reordered(); return }
        reorderProc.command = [Qt.resolvedUrl("../scripts/reorder-ws.py").toString().replace("file://", ""),
                               ids.join(","), order.join(","), String(activeId)]
        reorderProc.running = true
        triggerSwitch()
    }
    signal reordered()
    Process { id: reorderProc; onExited: { Hyprland.refreshWorkspaces(); Hyprland.refreshToplevels(); root.reordered() } }
    function goTo(id) { dispatchWs(String(id)) }
    function goEmpty() { dispatchWs("emptynm") }
}
