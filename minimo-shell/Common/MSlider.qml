// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick

// Slider estilo Centro de Control: pista gruesa gris, relleno negro, icono adentro.
Item {
    id: s
    property string icon
    property string label
    property real from: 0
    property real to: 1
    property real value: 0
    property string valueText: Math.round(frac * 100) + "%"
    property bool iconClickable: false
    readonly property real frac: Math.max(0, Math.min(1, (value - from) / (to - from)))
    signal moved(real v)
    signal iconClicked()

    implicitHeight: 40
    implicitWidth: 320

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.track
        clip: true
        Rectangle {
            id: fillRect
            height: parent.height
            width: Math.max(parent.height, parent.width * s.frac)
            radius: height / 2
            color: Theme.fill
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
    }
    MouseArea {
        id: drag
        anchors.fill: parent
        anchors.leftMargin: s.iconClickable ? 40 : 0
        cursorShape: Qt.PointingHandCursor
        function upd(mx) {
            const f = Math.max(0, Math.min(1, (mx + anchors.leftMargin) / s.width))
            s.moved(s.from + f * (s.to - s.from))
        }
        onPressed: m => upd(m.x)
        onPositionChanged: m => { if (pressed) upd(m.x) }
        onWheel: w => s.moved(Math.max(s.from, Math.min(s.to, s.value + (w.angleDelta.y > 0 ? 1 : -1) * (s.to - s.from) * 0.05)))
    }
    Icon {
        x: 12; anchors.verticalCenter: parent.verticalCenter
        size: 18
        name: s.icon
        tone: fillRect.width > 36 ? "white" : "dark"
        MouseArea {
            anchors.fill: parent; anchors.margins: -10
            enabled: s.iconClickable
            cursorShape: Qt.PointingHandCursor
            onClicked: s.iconClicked()
        }
    }
    Text {
        anchors.right: parent.right; anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: s.valueText
        color: s.frac > 0.9 ? "white" : Theme.textDim
        font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium
        font.features: { "tnum": 1 }
    }
}
