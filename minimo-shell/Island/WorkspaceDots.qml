// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell.Hyprland
import "../Common"

// Indicador sutil de workspaces: puntos, el activo en negro. Se desvanece a ~1 s.
Row {
    id: root
    spacing: 4
    property var screen: null
    property bool showing: false
    opacity: showing ? 1 : 0
    width: showing ? implicitWidth : 0
    visible: showing || width > 0 || opacity > 0
    clip: true
    Behavior on opacity { NumberAnimation { duration: 220 } }
    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    readonly property var mon: screen ? Hyprland.monitorFor(screen) : null
    readonly property int monId: mon ? mon.id : 0
    readonly property int baseWs: DisplayState.splitWorkspaces ? (monId * 10) : 0
    readonly property var filteredList: {
        if (!DisplayState.splitWorkspaces) return Workspaces.list
        return Workspaces.list.filter(w => w.id > baseWs && w.id <= baseWs + 9)
    }
    readonly property int currentWsId: (DisplayState.splitWorkspaces && mon && mon.activeWorkspace) ? mon.activeWorkspace.id : Workspaces.activeId

    Connections {
        target: Workspaces
        function onLastSwitchChanged() { root.showing = true; hideLater.restart() }
        function onSwitched() { root.showing = true; hideLater.restart() }
    }
    Timer { id: hideLater; interval: 1100; onTriggered: root.showing = false }

    Repeater {
        model: root.filteredList
        delegate: Rectangle {
            required property var modelData
            readonly property bool active: modelData.id === root.currentWsId
            anchors.verticalCenter: parent.verticalCenter
            width: active ? 12 : 5; height: 5; radius: 2.5
            color: active ? Theme.textPrimary : Theme.dot
            Behavior on width { NumberAnimation { duration: 180 } }
        }
    }
}
