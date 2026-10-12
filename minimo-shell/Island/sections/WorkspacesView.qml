// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../Common"

// Vista de escritorios dentro de la isla: grilla de workspaces con los iconos
// de sus ventanas, el activo con contorno negro, y un "+" para uno nuevo.
Item {
    id: root
    signal back()
    signal picked()
    implicitHeight: col.implicitHeight

    function refresh() { Hyprland.refreshToplevels(); Hyprland.refreshWorkspaces() }

    function iconFor(t) {
        let cls = ""
        if (t.wayland && t.wayland.appId) cls = t.wayland.appId
        else if (t.lastIpcObject && t.lastIpcObject["class"]) cls = t.lastIpcObject["class"]
        const e = cls ? DesktopEntries.heuristicLookup(cls) : null
        const p = Quickshell.iconPath(e ? e.icon : cls, true)
        return p !== "" ? p : Qt.resolvedUrl("../../assets/icons/gray/apps.svg")
    }

    Column {
        id: col
        width: parent.width
        spacing: 16

        Item {
            width: parent.width; height: 32
            Rectangle {
                id: backBtn
                width: 32; height: 32; radius: 16
                color: backMouse.containsMouse ? Theme.hover : Theme.field
                Icon { anchors.centerIn: parent; name: "back"; size: 18 }
                MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.back() }
            }
            Text {
                anchors.centerIn: parent
                text: "Escritorios"
                color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.DemiBold
            }
        }

        Grid {
            id: grid
            columns: 3
            spacing: 8
            readonly property real tileW: (col.width - spacing * (columns - 1)) / columns

            Repeater {
                model: Workspaces.list
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool active: modelData.id === Workspaces.activeId
                    width: grid.tileW; height: 76; radius: 14
                    color: tileMouse.containsMouse ? Theme.hover : Theme.field
                    border.width: active ? 2 : 0
                    border.color: Theme.textPrimary
                    Text {
                        x: 10; y: 8
                        text: modelData.name || modelData.id
                        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Medium
                    }
                    Row {
                        anchors.centerIn: parent; anchors.verticalCenterOffset: 6
                        spacing: 6
                        Repeater {
                            model: modelData.toplevels ? modelData.toplevels.values.slice(0, 4) : []
                            delegate: Image {
                                required property var modelData
                                width: 24; height: 24; sourceSize: Qt.size(48, 48)
                                source: root.iconFor(modelData)
                            }
                        }
                    }
                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { Workspaces.goTo(modelData.id); root.picked() }
                    }
                }
            }
            Rectangle {
                width: grid.tileW; height: 76; radius: 14
                color: "transparent"
                border.width: 1.5; border.color: plusMouse.containsMouse ? Theme.textSecondary : Theme.track
                Icon { anchors.centerIn: parent; name: "plus"; tone: "gray"; size: 22 }
                MouseArea {
                    id: plusMouse
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { Workspaces.goEmpty(); root.picked() }
                }
            }
        }
    }
}
