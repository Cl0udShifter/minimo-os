// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick

// Slider estilo Centro de Control: pista gruesa gris, relleno negro, icono adentro.
// Suporta incrementos precisos e edição manual ao clicar no valor.
Item {
    id: s
    property string icon
    property string label
    property real from: 0
    property real to: 1
    property real value: 0
    property string valueText: Math.round(frac * 100) + "%"
    property bool iconClickable: false
    property bool editable: false
    property bool editing: false
    property real step: 0.01

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
            Behavior on width { enabled: !drag.pressed && !s.editing; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        anchors.leftMargin: s.iconClickable ? 40 : 0
        anchors.rightMargin: s.editable ? 64 : 0
        enabled: !s.editing
        cursorShape: Qt.PointingHandCursor

        function upd(mx) {
            const availableWidth = s.width - (anchors.leftMargin + anchors.rightMargin)
            const f = Math.max(0, Math.min(1, (mx) / availableWidth))
            const raw = s.from + f * (s.to - s.from)
            const rounded = s.step > 0 ? (Math.round(raw / s.step) * s.step) : raw
            s.moved(Math.max(s.from, Math.min(s.to, rounded)))
        }

        onPressed: m => upd(m.x)
        onPositionChanged: m => { if (pressed) upd(m.x) }
        onWheel: w => {
            const delta = (w.angleDelta.y > 0 ? 1 : -1) * (s.step > 0 ? s.step : 0.01)
            const nextVal = Math.round((s.value + delta) * 100) / 100
            s.moved(Math.max(s.from, Math.min(s.to, nextVal)))
        }
    }

    Icon {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        size: 18
        name: s.icon
        tone: fillRect.width > 36 ? "white" : "dark"

        MouseArea {
            anchors.fill: parent
            anchors.margins: -10
            enabled: s.iconClickable
            cursorShape: Qt.PointingHandCursor
            onClicked: s.iconClicked()
        }
    }

    // Exibição e edição do valor à direita
    Item {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: s.editing ? editBox.width : (s.editable ? valBox.width : valText.implicitWidth + 8)
        height: 28

        // Modo Leitura / Clique para editar
        Rectangle {
            id: valBox
            anchors.centerIn: parent
            visible: !s.editing
            width: valText.implicitWidth + (s.editable ? 14 : 8)
            height: 26
            radius: 13
            color: s.editable && valMouse.containsMouse ? (s.frac > 0.85 ? Qt.rgba(255, 255, 255, 0.25) : Theme.hover) : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                id: valText
                anchors.centerIn: parent
                text: s.valueText
                color: s.frac > 0.85 ? Theme.onAccent : Theme.textPrimary
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: Font.Medium
                font.features: { "tnum": 1 }
            }

            MouseArea {
                id: valMouse
                anchors.fill: parent
                enabled: s.editable
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    s.editing = true
                    editInput.text = (Math.round(s.value * 100) / 100).toFixed(2).replace(".", ",")
                    editInput.forceActiveFocus()
                    editInput.selectAll()
                }
            }
        }

        // Modo Edição Manual (TextInput inline)
        Rectangle {
            id: editBox
            anchors.centerIn: parent
            visible: s.editing
            width: Math.max(54, editInput.implicitWidth + 16)
            height: 26
            radius: 13
            color: Theme.raised
            border.width: 1
            border.color: Theme.fill

            TextInput {
                id: editInput
                anchors.centerIn: parent
                width: Math.max(34, implicitWidth)
                horizontalAlignment: TextInput.AlignHCenter
                color: Theme.textPrimary
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: Font.DemiBold
                selectByMouse: true
                inputMethodHints: Qt.ImhFormattedNumbersOnly

                function commit() {
                    if (!s.editing) return
                    const raw = editInput.text.trim().replace(",", ".")
                    const num = parseFloat(raw)
                    if (!isNaN(num)) {
                        const clamped = Math.max(s.from, Math.min(s.to, num))
                        const finalVal = s.step > 0 ? (Math.round(clamped / s.step) * s.step) : clamped
                        s.moved(Math.round(finalVal * 100) / 100)
                    }
                    s.editing = false
                }

                Keys.onReturnPressed: commit()
                Keys.onEnterPressed: commit()
                Keys.onEscapePressed: s.editing = false
                onActiveFocusChanged: {
                    if (!activeFocus && s.editing) commit()
                }
            }
        }
    }
}
