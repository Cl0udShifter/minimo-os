// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import "../Common"

// Indicador breve de layout do teclado (BR / US) exibido no notch/ilha.
// Desvanece suavemente após ~1.2 s, no mesmo estilo visual dos pontos de workspace.
Item {
    id: root
    property bool showing: false
    opacity: showing ? 1 : 0
    width: showing ? badgePill.width : 0
    height: 20
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    visible: showing || width > 0 || opacity > 0
    clip: true

    Behavior on opacity { NumberAnimation { duration: 220 } }
    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    Rectangle {
        id: badgePill
        anchors.verticalCenter: parent.verticalCenter
        width: badgeText.implicitWidth + 14
        height: 20
        radius: 10
        color: Theme.raised

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: InputState.activeBadgeText
            color: Theme.textPrimary
            font.family: Theme.font
            font.pixelSize: 11
            font.weight: Font.Bold
        }
    }

    Connections {
        target: InputState
        function onLayoutSwitched() {
            root.showing = true
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: root.showing = false
    }
}
