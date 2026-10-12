// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick

// Apps ancladas: íconos redondos con su nombre debajo. Clic lanza; clic derecho pide
// el menú contextual (signal menuRequested). `selected` resalta para navegar con teclado.
Item {
    id: root
    property int iconSize: 44
    property int cellW: 72
    property int selected: -1
    readonly property var apps: Apps.pinned
    readonly property int columns: Math.max(1, Math.floor(width / cellW))
    signal launched(var entry)
    signal menuRequested(var entry, real x, real y)

    visible: apps.length > 0
    implicitHeight: visible ? flow.implicitHeight : 0

    // Navegación: dx/dy en celdas. Devuelve true si se movió.
    function move(dx, dy) {
        if (apps.length === 0) return false
        let i = selected < 0 ? 0 : selected + dx + dy * columns
        selected = Math.max(0, Math.min(apps.length - 1, i))
        return true
    }
    function current() { return selected >= 0 && selected < apps.length ? apps[selected] : null }

    Flow {
        id: flow
        width: root.columns * root.cellW
        anchors.horizontalCenter: parent.horizontalCenter
        Repeater {
            model: root.apps
            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                readonly property bool hot: index === root.selected || cm.containsMouse
                width: root.cellW; height: root.iconSize + 30
                Rectangle {
                    id: bubble
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4
                    width: root.iconSize; height: root.iconSize; radius: width / 2
                    color: cell.hot ? Theme.hover : Theme.field
                    scale: cm.pressed ? 0.92 : 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Image {
                        anchors.centerIn: parent
                        width: Math.round(root.iconSize * 0.58); height: width
                        sourceSize: Qt.size(width * 2, width * 2)
                        source: Apps.iconFor(cell.modelData)
                        smooth: true
                    }
                }
                Text {
                    enabled: false
                    anchors.top: bubble.bottom; anchors.topMargin: 5
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.cellW - 6
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: cell.modelData.name
                    color: cell.index === root.selected ? Theme.text : Theme.textDim
                    font.family: Theme.font; font.pixelSize: 11
                }
                MouseArea {
                    id: cm
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: m => {
                        if (m.button === Qt.RightButton) {
                            const p = mapToItem(root, m.x, m.y)
                            root.menuRequested(cell.modelData, p.x, p.y)
                        } else root.launched(cell.modelData)
                    }
                    onWheel: w => w.accepted = true
                }
            }
        }
    }
}
