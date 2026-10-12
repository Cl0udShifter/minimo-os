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
    function reset() { field.text = ""; field.focus = false }

    readonly property var results: Apps.search(query, 5)
    onResultsChanged: selected = 0

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
            Keys.onDownPressed: root.selected = Math.min(root.selected + 1, root.results.length - 1)
            Keys.onUpPressed: root.selected = Math.max(root.selected - 1, 0)
            onAccepted: root.launch(root.results[root.selected])
        }
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
                onClicked: root.launch(modelData)
                onWheel: w => w.accepted = true   // no cambiar de workspace sobre la lista
            }
        }
    }
}
