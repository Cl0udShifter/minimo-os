// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick.Effects
import "../Common"

// Ventana de la isla: layer-shell arriba, overlay, sin reservar espacio.
// Una sola región de hover (hoverZone) en la máscara de input: cuando la isla
// está oculta es una franja de 3px; cuando se muestra crece hasta cubrir la isla.
PanelWindow {
    id: win

    property bool expanded: false
    property bool panel: false            // panel de estado del sistema (deslizar)
    readonly property bool open: expanded || panel
    readonly property bool hovered: hoverZone.containsMouse
    property bool shown: true
    // Ocultamiento inteligente: hay ventanas en el escritorio activo del monitor de ESTA isla.
    // Solo se evalúa con la opción activa; los escritorios especiales (id < 0) no cuentan.
    readonly property var monitorWs: DisplayState.islandSmartHide ? (Hyprland.monitorFor(win.screen)?.activeWorkspace ?? null) : null
    readonly property int wsWindows: monitorWs && monitorWs.id > 0 ? monitorWs.toplevels.values.length : 0
    readonly property bool occupied: wsWindows > 0
    readonly property bool hideWanted: DisplayState.islandAutoHide || (DisplayState.islandSmartHide && occupied)

    anchors { top: true; left: true; right: true; bottom: win.open }
    implicitHeight: Theme.maxExpandedH + Theme.topMargin + 8
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "minimo-island"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region { x: win.open ? 0 : hoverZone.x; y: 0; width: win.open ? win.width : hoverZone.width; height: win.open ? win.height : hoverZone.height }

    function collapse() { expanded = false; panel = false }

    // Auto-ocultar
    Timer {
        id: hideTimer
        interval: Theme.hideDelay
        onTriggered: if (win.hideWanted && !win.hovered && !win.open && !menu.searchFocused && Recorder.notice === "" && Notifs.current === null) win.shown = false
    }
    onHoveredChanged: {
        if (hovered) { hideTimer.stop(); shown = true }
        else if (!open) hideTimer.restart()
    }
    onPanelChanged: {
        pill.forceActiveFocus()
        if (panel) { hideTimer.stop(); shown = true }
        else if (!hovered) hideTimer.restart()
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
        function onIslandAutoHideChanged() { win.syncHide() }
        function onIslandSmartHideChanged() { win.syncHide() }
    }
    // Reactivo a abrir/cerrar/mover ventanas y cambiar de escritorio (eventos de Hyprland).
    onHideWantedChanged: syncHide()
    // Tras cerrar/mover ventanas se refresca la lista de toplevels (un evento, sin sondeo).
    Connections {
        target: Hyprland
        enabled: DisplayState.islandSmartHide
        function onRawEvent(ev) {
            const n = ev.name
            if (n === "closewindow" || n === "movewindowv2" || n === "openwindow") toplevelsLater.restart()
        }
    }
    // Una sola actualización por ráfaga de eventos, fuera del manejador de eventos de Hyprland.
    Timer { id: toplevelsLater; interval: 120; onTriggered: Hyprland.refreshToplevels() }
    function syncHide() {
        if (!hideWanted) { hideTimer.stop(); shown = true }
        else if (!hovered && !open) hideTimer.restart()
    }

    // Mensajes de la grabadora: mostrar la isla mientras dure el aviso.
    Connections {
        target: Recorder
        function onNoticeChanged() {
            if (Recorder.notice !== "") { win.shown = true; hideTimer.stop() }
            else if (!win.hovered && !win.open) hideTimer.restart()
        }
    }

    // Notificaciones: la isla aparece mientras haya una en pantalla; el mouse encima pausa el tiempo.
    Connections {
        target: Notifs
        function onCurrentChanged() {
            if (Notifs.current !== null) { win.shown = true; hideTimer.stop() }
            else if (!win.hovered && !win.open) hideTimer.restart()
        }
    }
    Binding { target: Notifs; property: "paused"; value: win.hovered }

    // Clic afuera de la isla mientras está expandida: colapsa.
    MouseArea {
        anchors.fill: parent
        enabled: win.open
        acceptedButtons: Qt.AllButtons
        onPressed: win.collapse()
    }

    // Región única de hover/input. Nunca se reemplaza por otro item.
    // También es el ÚNICO receptor de clics de la isla compacta (cubre toda la píldora y
    // el margen superior, con su tamaño final aunque la píldora esté animando).
    MouseArea {
        id: hoverZone
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: win.expanded ? Qt.ArrowCursor : Qt.PointingHandCursor
        // Margen extra alrededor de la píldora: un clic/arrastre que empieza justo en el
        // borde no "se escapa" a la ventana de abajo (que seleccionaría su texto).
        readonly property int pad: 8
        x: win.shown ? pill.x - pad : 0
        y: 0
        width: win.shown ? pill.width + pad * 2 : win.width
        height: win.shown ? Theme.topMargin + pill.height + pad : 3

        preventStealing: true
        // Clic → menú (al soltar). Arrastre horizontal (>8 px) → panel de estado del sistema;
        // con el panel abierto, deslizar de nuevo lo cierra. La píldora sigue al dedo (elástico).
        property real pressX: 0
        property bool dragging: false
        property real dragDx: 0
        // Coordenadas de ventana: la zona se mueve con la píldora mientras se arrastra.
        onPressed: m => { pressX = mapToItem(null, m.x, m.y).x; dragging = false; dragDx = 0 }
        onPositionChanged: m => {
            if (!pressed || win.expanded) return
            const dx = mapToItem(null, m.x, m.y).x - pressX
            if (!dragging && Math.abs(dx) > 8) dragging = true
            if (dragging) dragDx = dx
        }
        onReleased: m => {
            // Con una notificación: clic = abrir la app, clic derecho = descartar.
            if (!dragging && !win.open && Notifs.current !== null) {
                if (m.button === Qt.RightButton) Notifs.dismiss(); else Notifs.activate()
                dragging = false; dragDx = 0; return
            }
            if (m.button === Qt.RightButton) return
            if (dragging) {
                if (Math.abs(dragDx) > 40) win.panel = !win.panel
            } else if (!win.open) win.expanded = true
            dragging = false; dragDx = 0
        }
        onCanceled: { dragging = false; dragDx = 0 }
        // Rueda sobre la isla compacta: escritorio anterior/siguiente.
        onWheel: w => { if (!win.open) Workspaces.wheel(w.angleDelta.y) }
    }


    // Sombra suave y difusa detrás de la tarjeta (no recorta, no recibe input).
    Rectangle {
        id: shadowSrc
        x: pill.x; y: pill.y; width: pill.width; height: pill.height
        radius: pill.radius
        color: Theme.card
        Behavior on color { ColorAnimation { duration: 250 } }
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
        // Elástico: mientras se arrastra, la píldora se estira y se corre un poco con el dedo.
        readonly property real rubber: hoverZone.dragging ? hoverZone.dragDx / (1 + Math.abs(hoverZone.dragDx) / 60) : 0
        width: win.expanded ? Theme.expandedW
             : win.panel ? Theme.expandedW
             : Math.max(Theme.compactW, compact.implicitWidth + 32) + Math.abs(rubber) * 1.2
        height: win.expanded ? Math.min(menu.implicitHeight, Theme.maxExpandedH)
              : win.panel ? Math.min(status.implicitHeight, Theme.maxExpandedH) : Theme.compactH
        x: (win.width - width) / 2 + rubber * 0.5
        y: win.shown ? Theme.topMargin : -height - 64
        radius: Math.min(height / 2, Theme.radiusCard)
        color: Theme.card
        Behavior on color { ColorAnimation { duration: 250 } }
        clip: true

        Behavior on width { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        Behavior on height { NumberAnimation { duration: Theme.durNormal + 40; easing.type: Easing.OutBack; easing.overshoot: 0.7 } }
        Behavior on y { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutQuint } }

        focus: win.open
        Keys.onEscapePressed: win.collapse()

        IslandCompact {
            id: compact
            anchors.centerIn: parent
            active: win.shown && !win.open
            opacity: win.open ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
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

        StatusPanel {
            id: status
            width: Theme.expandedW
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            open: win.panel
            opacity: win.panel ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
        }
    }

    // Control externo (ipc "island"): show/hide/open/close.
    Connections {
        target: CharacterBus
        function onIslandCommand(cmd) {
            if (cmd === "show") { win.shown = true; hideTimer.stop() }
            else if (cmd === "hide") { win.expanded = false; win.shown = false }
            else if (cmd === "open") win.expanded = true
            else if (cmd === "close") win.collapse()
            else if (cmd === "status") win.panel = !win.panel
        }
    }

    // Reacciones del personaje.
    onShownChanged: if (shown && !expanded) compact.character.hop()
    Connections {
        target: win
        function onExpandedChanged() {
            if (win.expanded) menu.character.opened()
        }
    }
}
