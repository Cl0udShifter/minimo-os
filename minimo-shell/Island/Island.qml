// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Effects
import "../Common"

// Ventana de la isla: layer-shell arriba, overlay, sin reservar espacio.
// Una sola región de hover (hoverZone) en la máscara de input: cuando la isla
// está oculta es una franja de 3px; cuando se muestra crece hasta cubrir la isla.
PanelWindow {
    id: win

    property bool expanded: false
    readonly property bool hovered: hoverZone.containsMouse
    property bool shown: true
    property bool dragging: false      // arrastrando sobre la isla: tira de escritorios

    anchors { top: true; left: true; right: true; bottom: win.expanded }
    implicitHeight: Theme.maxExpandedH + Theme.topMargin + 8
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "minimo-island"
    WlrLayershell.keyboardFocus: (expanded || dragging) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region { x: win.expanded ? 0 : hoverZone.x; y: 0; width: win.expanded ? win.width : hoverZone.width; height: win.expanded ? win.height : hoverZone.height }

    function collapse() { expanded = false }

    // Auto-ocultar
    Timer {
        id: hideTimer
        interval: Theme.hideDelay
        onTriggered: if (DisplayState.islandAutoHide && !win.dragging && !win.hovered && !win.expanded && !menu.searchFocused && Recorder.notice === "") win.shown = false
    }
    onHoveredChanged: {
        if (hovered) { hideTimer.stop(); shown = true }
        else if (!expanded) hideTimer.restart()
    }
    onExpandedChanged: {
        // Al abrir y al cerrar, el foco va a la píldora (no al buscador), así no
        // queda el cursor "|" parpadeando. El buscador se activa solo con un clic.
        menu.opened(); pill.forceActiveFocus(); unfocusLater.restart()
        if (expanded) { hideTimer.stop(); shown = true }
        else if (!hovered) hideTimer.restart()
    }
    Timer { id: unfocusLater; interval: 150; onTriggered: { menu.opened(); pill.forceActiveFocus() } }
    Component.onCompleted: hideTimer.restart()
    // Si se desactiva el auto-ocultar, la isla queda siempre visible.
    Connections {
        target: DisplayState
        function onIslandAutoHideChanged() { if (!DisplayState.islandAutoHide) win.shown = true; else hideTimer.restart() }
    }

    // Mensajes de la grabadora: mostrar la isla mientras dure el aviso.
    Connections {
        target: Recorder
        function onNoticeChanged() {
            if (Recorder.notice !== "") { win.shown = true; hideTimer.stop() }
            else if (!win.hovered && !win.expanded) hideTimer.restart()
        }
    }

    // Clic afuera de la isla mientras está expandida: colapsa.
    MouseArea {
        anchors.fill: parent
        enabled: win.expanded
        acceptedButtons: Qt.AllButtons
        onPressed: win.collapse()
    }

    // Región única de hover/input. Nunca se reemplaza por otro item.
    MouseArea {
        id: hoverZone
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: win.expanded ? Qt.ArrowCursor : Qt.PointingHandCursor
        onPressed: mouse => { if (!win.expanded) win.expanded = true }
        x: win.shown ? pill.x : 0
        y: 0
        width: win.shown ? pill.width : win.width
        height: win.shown ? pill.y + pill.height : 3
    }


    // Sombra suave y difusa detrás de la tarjeta (no recorta, no recibe input).
    Rectangle {
        id: shadowSrc
        x: pill.x; y: pill.y; width: pill.width; height: pill.height
        radius: pill.radius
        color: Theme.card
        opacity: win.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 1.0
            blurMax: 40
            shadowVerticalOffset: 8
            autoPaddingEnabled: true
        }
    }

    Rectangle {
        id: pill
        width: win.expanded ? Theme.expandedW
             : win.dragging ? strip.implicitWidth + 16
             : Math.max(Theme.compactW, compact.implicitWidth + 32)
        height: win.expanded ? Math.min(menu.implicitHeight, Theme.maxExpandedH) : Theme.compactH
        x: (win.width - width) / 2
        y: win.shown ? Theme.topMargin : -height - 64
        radius: Math.min(height / 2, Theme.radiusCard)
        color: Theme.card
        clip: true

        Behavior on width { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        Behavior on height { NumberAnimation { duration: Theme.durNormal + 40; easing.type: Easing.OutBack; easing.overshoot: 0.7 } }
        Behavior on y { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutQuint } }

        focus: win.expanded || win.dragging
        Keys.onEscapePressed: { if (win.dragging) { dragArea.cancelled = true; win.dragging = false } else win.collapse() }

        IslandCompact {
            id: compact
            anchors.centerIn: parent
            active: win.shown && !win.expanded
            opacity: (win.expanded || win.dragging) ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
        }

        // Arrastrar en horizontal: tira de escritorios ocupados.
        WorkspaceStrip {
            id: strip
            anchors.centerIn: parent
            opacity: win.dragging ? 1 : 0
            visible: opacity > 0
            scale: win.dragging ? 1 : 0.92
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
            Behavior on scale { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutBack } }
        }

        // Clic: expandir. Arrastre horizontal (>12 px): elegir escritorio y soltar para ir.
        MouseArea {
            id: dragArea
            anchors.fill: parent
            preventStealing: true
            property real pressX: 0
            property bool cancelled: false
            cursorShape: win.expanded ? Qt.ArrowCursor : (win.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor)
            onPressed: m => { pressX = m.x; cancelled = false }
            onPositionChanged: m => {
                if (win.expanded || cancelled) return
                if (!win.dragging && Math.abs(m.x - pressX) > 12) { win.dragging = true; strip.hovered = -1 }
                if (win.dragging) strip.hoverAt(mapToItem(strip, m.x, m.y))
            }
            onReleased: m => {
                if (win.dragging) {
                    const ws = strip.hoveredWs
                    win.dragging = false
                    if (ws && ws.id !== Workspaces.activeId) Workspaces.goTo(ws.id)
                } else if (!cancelled && !win.expanded && containsMouse) win.expanded = true
            }
            onCanceled: win.dragging = false
            // Rueda sobre la isla: workspace anterior/siguiente.
            onWheel: w => Workspaces.wheel(w.angleDelta.y)
        }

        IslandMenu {
            id: menu
            width: Theme.expandedW
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            open: win.expanded
            opacity: win.expanded ? 1 : 0
            visible: opacity > 0
            enabled: win.expanded
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
            onDone: win.collapse()
        }
    }

    // Control externo (ipc "island"): show/hide/open/close.
    Connections {
        target: CharacterBus
        function onIslandCommand(cmd) {
            if (cmd === "show") { win.shown = true; hideTimer.stop() }
            else if (cmd === "hide") { win.expanded = false; win.shown = false }
            else if (cmd === "open") win.expanded = true
            else if (cmd === "close") win.expanded = false
        }
    }

    // Reacciones del personaje.
    onShownChanged: if (shown && !expanded) compact.character.hop()
    Connections {
        target: win
        function onExpandedChanged() {
            if (win.expanded) menu.character.spin()
            else compact.character.spinBack()
        }
    }
}
