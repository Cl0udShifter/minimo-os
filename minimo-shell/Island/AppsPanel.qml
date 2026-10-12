// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../Common"
import "../Character"

// Panel "En segundo plano" (deslizar la isla de derecha a izquierda): las apps de la
// bandeja del sistema (Steam, Discord…), como los iconos ocultos de Windows 11.
// Clic = volver a mostrar la app; si solo ofrece menú, se relanza su desktop entry.
Item {
    id: root
    property bool open: false
    implicitHeight: col.implicitHeight + 32

    onOpenChanged: if (open) greetLater.restart()
    Timer { id: greetLater; interval: 280; onTriggered: chr.react("greet") }

    // Tocar SystemTray siempre registra el StatusNotifierWatcher, así las apps publican
    // su icono aunque el panel esté cerrado. La lista solo se enlaza con el panel abierto.
    readonly property var trayItems: SystemTray.items.values
    readonly property var items: open ? trayItems.filter(i => !!i) : []

    function entryOf(id) { return id ? DesktopEntries.heuristicLookup(id) : null }
    function nameOf(i) { const e = entryOf(i.id); return e && e.name ? e.name : (i.title || i.id) }
    function activate(i) {
        if (!i.onlyMenu) i.activate()
        else { const e = entryOf(i.id); Quickshell.execDetached(["gtk-launch", e ? e.id : i.id]) }
        CharacterBus.islandCommand("close")
    }

    component Title: Text {
        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold
        leftPadding: 4
    }

    Column {
        id: col
        x: 16; y: 16; width: parent.width - 32
        spacing: 8

        Item {
            width: parent.width; height: 76
            Character {
                id: chr
                size: 60
                anchors.centerIn: parent
                active: root.open && DisplayState.characterAnimated
                MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: m => chr.clicked((m.x - width / 2) / (width / 2)) }
            }
        }

        Title { text: "En segundo plano" }
        Rectangle {
            width: parent.width; radius: 18; color: Theme.field
            height: (root.items.length === 0 ? empty.height : list.implicitHeight) + 8
            Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            clip: true
            Text {
                id: empty
                visible: root.items.length === 0
                y: 4; width: parent.width; height: 44
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                text: "No hay apps en segundo plano"; color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 13
            }
            Column {
                id: list
                y: 4; width: parent.width
                Repeater {
                    model: root.items
                    delegate: Item {
                        id: row
                        required property var modelData
                        width: list.width; height: 40
                        Rectangle {
                            x: 6; width: parent.width - 12; height: 36; radius: 18
                            anchors.verticalCenter: parent.verticalCenter
                            color: ma.containsMouse ? Theme.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        Image {
                            x: 16; width: 20; height: 20; anchors.verticalCenter: parent.verticalCenter
                            source: row.modelData.icon; sourceSize: Qt.size(40, 40); asynchronous: true
                        }
                        Text {
                            x: 46; width: parent.width - 60; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight
                            text: root.nameOf(row.modelData)
                            color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 13
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.activate(row.modelData)
                        }
                    }
                }
            }
        }
    }
}
