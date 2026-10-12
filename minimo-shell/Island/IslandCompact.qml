// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import "../Common"
import "../Character"

// Estado compacto: personaje + hora (HH:mm).
Item {
    id: root
    property alias character: chr
    property bool active: true
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.compactH

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10
        Character { id: chr; size: 22; active: root.active && DisplayState.characterAnimated; anchors.verticalCenter: parent.verticalCenter }
        Text {
            enabled: false              // texto decorativo: sin interacción ni selección
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.textPrimary
            font.family: Theme.font
            font.pixelSize: 15
            font.weight: Font.Medium
            font.features: { "tnum": 1 }
        }
        // Grabando: punto rojo que late + tiempo transcurrido.
        Row {
            visible: Recorder.recording && Recorder.notice === ""
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 8; height: 8; radius: 4
                color: Theme.recording
                SequentialAnimation on opacity {
                    running: Recorder.recording && root.active
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
                }
            }
            Text {
                enabled: false              // texto decorativo: sin interacción ni selección
                anchors.verticalCenter: parent.verticalCenter
                text: Recorder.elapsedText
                color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 13
                font.features: { "tnum": 1 }
            }
        }
        // Mensaje breve (Guardado / Instalá wf-recorder).
        Text {
            enabled: false              // texto decorativo: sin interacción ni selección
            visible: Recorder.notice !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: Recorder.notice
            color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
            elide: Text.ElideMiddle
            width: Math.min(implicitWidth, 230)
        }
        WorkspaceDots { anchors.verticalCenter: parent.verticalCenter }
    }

    // Zzz al dormir (flotan desde el personaje).
    Zzz {
        x: row.x + chr.x + chr.width - 1
        y: row.y + chr.y - 14
        running: chr.asleep && root.active
    }
}
