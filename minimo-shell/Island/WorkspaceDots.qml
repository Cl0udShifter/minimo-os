// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import "../Common"

// Indicador sutil de workspaces: puntos, el activo en negro. Se desvanece a ~1 s.
Row {
    id: root
    spacing: 4
    property bool showing: false
    opacity: showing ? 1 : 0
    width: showing ? implicitWidth : 0
    clip: true
    Behavior on opacity { NumberAnimation { duration: 220 } }
    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    Connections {
        target: Workspaces
        function onLastSwitchChanged() { root.showing = true; hideLater.restart() }
    }
    Timer { id: hideLater; interval: 1100; onTriggered: root.showing = false }

    Repeater {
        model: Workspaces.list
        delegate: Rectangle {
            required property var modelData
            readonly property bool active: modelData.id === Workspaces.activeId
            anchors.verticalCenter: parent.verticalCenter
            width: active ? 12 : 5; height: 5; radius: 2.5
            color: active ? Theme.text : "#C7C7CC"
            Behavior on width { NumberAnimation { duration: 180 } }
        }
    }
}
