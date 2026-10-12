// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick

// Interruptor estilo iOS (negro encendido, gris apagado).
Item {
    id: sw
    property bool checked: false
    signal toggled(bool value)
    width: 46; height: 28
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: sw.checked ? Theme.fill : Theme.track
        Behavior on color { ColorAnimation { duration: 160 } }
        Rectangle {
            width: 22; height: 22; radius: 11
            y: 3; x: sw.checked ? parent.width - width - 3 : 3
            color: sw.checked ? Theme.onFill : "#FFFFFF"
            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sw.toggled(!sw.checked) }
}
