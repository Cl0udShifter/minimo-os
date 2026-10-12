// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import "../../Common"

// Buscador de aplicaciones instaladas (DesktopEntries).
Column {
    id: root
    signal launched()
    property alias query: field.text
    readonly property bool hasFocus: field.activeFocus
    property int selected: 0
    spacing: 4

    function focusField() { field.text = ""; field.forceActiveFocus() }
    function reset() { field.text = ""; field.focus = false; pins.selected = -1; menu.close() }

    readonly property var results: Apps.search(query, 5)
    onResultsChanged: selected = 0
    readonly property bool showPinned: query.trim() === "" && Apps.pinned.length > 0
    onQueryChanged: { pins.selected = -1; menu.close() }

    function launch(entry) { if (entry) { entry.execute(); root.launched() } }

    Rectangle {
        width: parent.width; height: 40
        radius: Theme.radiusField
        color: Theme.field
        Icon {
            id: lupa
            x: 12; anchors.verticalCenter: parent.verticalCenter
            name: "search"; tone: "gray"; size: 16
        }
        TextInput {
            id: field
            cursorVisible: activeFocus
            anchors.left: lupa.right; anchors.leftMargin: 8
            anchors.right: parent.right; anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            selectionColor: Theme.track
            selectedTextColor: Theme.text
            // El cursor "|" solo se dibuja cuando el buscador tiene el foco.
            cursorDelegate: Rectangle { width: 2; radius: 1; color: Theme.text; visible: field.activeFocus && field.cursorVisible }
            font.family: Theme.font; font.pixelSize: 14
            clip: true
            Text {
                visible: !field.text
                text: "Buscar"
                color: Theme.textDim
                font: field.font
            }
            Keys.onDownPressed: { if (root.showPinned) pins.move(0, pins.selected < 0 ? 0 : 1); else root.selected = Math.min(root.selected + 1, root.results.length - 1) }
            Keys.onUpPressed: { if (root.showPinned) pins.move(0, -1); else root.selected = Math.max(root.selected - 1, 0) }
            Keys.onLeftPressed: e => { if (root.showPinned) pins.move(-1, 0); else e.accepted = false }
            Keys.onRightPressed: e => { if (root.showPinned) pins.move(1, 0); else e.accepted = false }
            onAccepted: root.launch(root.showPinned ? pins.current() : root.results[root.selected])
        }
    }

    // Ancladas (con el buscador vacío).
    PinnedGrid {
        id: pins
        width: root.width
        visible: root.showPinned
        iconSize: 44; cellW: 70
        onLaunched: e => root.launch(e)
        onMenuRequested: (e, px, py) => { const p = pins.mapToItem(menuHolder, px, py); menu.openAt(e, p.x, p.y) }
    }

    Repeater {
        model: root.results
        delegate: Rectangle {
            required property var modelData
            required property int index
            width: root.width; height: 40; radius: 10
            color: index === root.selected || hov.containsMouse ? Theme.field : "transparent"
            Image {
                id: ic
                x: 12; anchors.verticalCenter: parent.verticalCenter
                width: 24; height: 24
                sourceSize: Qt.size(48, 48)
                source: Apps.iconFor(modelData)
            }
            Text {
                anchors.left: ic.right; anchors.leftMargin: 12
                anchors.right: parent.right; anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: modelData.name
                color: Theme.text; font.family: Theme.font; font.pixelSize: 13
            }
            MouseArea {
                id: hov
                anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: m => {
                    if (m.button === Qt.RightButton) { const p = mapToItem(menuHolder, m.x, m.y); menu.openAt(modelData, p.x, p.y) }
                    else root.launch(modelData)
                }
                onWheel: w => w.accepted = true   // no cambiar de workspace sobre la lista
            }
        }
    }

    // Menú contextual (no ocupa lugar en la columna).
    Item {
        id: menuHolder
        width: root.width; height: 0
        PinMenu { id: menu }
    }
}
