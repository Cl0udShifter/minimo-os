// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../Common"

// Tira de escritorios ocupados (al arrastrar sobre la isla compacta): una píldora por
// escritorio con su número y hasta 3 íconos de apps. El activo va en negro; el que
// está bajo el cursor se resalta. `hoverAt(p)` actualiza el resaltado.
Row {
    id: root
    spacing: 6
    property int hovered: -1                   // índice en `items`, -1 = ninguno
    readonly property var items: Workspaces.list.filter(w =>
        w.id === Workspaces.activeId || (w.toplevels && w.toplevels.values.length > 0))
    readonly property var hoveredWs: hovered >= 0 && hovered < items.length ? items[hovered] : null

    function hoverAt(p) {
        // p en coordenadas de esta fila; fuera de la franja vertical = sin selección
        if (p.y < -24 || p.y > height + 24) { hovered = -1; return }
        for (let i = 0; i < rep.count; i++) {
            const it = rep.itemAt(i)
            if (p.x >= it.x - spacing / 2 && p.x <= it.x + it.width + spacing / 2) { hovered = i; return }
        }
        hovered = -1
    }

    function iconFor(t) {
        let cls = ""
        if (t.wayland && t.wayland.appId) cls = t.wayland.appId
        else if (t.lastIpcObject && t.lastIpcObject["class"]) cls = t.lastIpcObject["class"]
        const e = cls ? DesktopEntries.heuristicLookup(cls) : null
        const p = Quickshell.iconPath(e ? e.icon : cls, true)
        return p !== "" ? p : Qt.resolvedUrl("../assets/icons/gray/apps.svg")
    }

    Repeater {
        id: rep
        model: root.items
        delegate: Rectangle {
            id: chip
            required property var modelData
            required property int index
            readonly property bool active: modelData.id === Workspaces.activeId
            readonly property bool hot: index === root.hovered
            readonly property var apps: modelData.toplevels ? modelData.toplevels.values.slice(0, 3) : []
            height: 28
            width: row.implicitWidth + 20
            radius: height / 2
            color: active ? Theme.fill : (hot ? Theme.hover : Theme.field)
            scale: hot ? 1.08 : 1
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on scale { SpringAnimation { spring: 4; damping: 0.35; epsilon: 0.002 } }
            border.width: hot && active ? 2 : 0
            border.color: Theme.textDim

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 5
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: chip.modelData.name || chip.modelData.id
                    color: chip.active ? "white" : Theme.text
                    font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                }
                Repeater {
                    model: chip.apps
                    delegate: Image {
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16; sourceSize: Qt.size(32, 32)
                        source: root.iconFor(modelData)
                        smooth: true
                    }
                }
            }
        }
    }
}
