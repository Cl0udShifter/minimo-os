// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Common"

// Pop-up rápido (OSD) no canto inferior central ao alterar o volume.
PanelWindow {
    id: win

    property bool open: false
    onOpenChanged: console.log("VolumeOSD: open=" + open)
    property real t: open ? 1 : 0
    Behavior on t { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    visible: open || t > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "minimo-volume-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // 100% click-through (não intercepta cliques do mouse)
    mask: Region {}

    Connections {
        target: VolumeOSDState
        function onTriggered() {
            win.open = true
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: win.open = false
    }

    Item {
        id: container
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(130, Math.round(parent.height * 0.14))
        width: 250
        height: 50
        opacity: win.t
        scale: 0.94 + 0.06 * win.t
        transform: Translate { y: (1 - win.t) * 12 }

        // Sombra suave difusa
        Rectangle {
            id: shadowSrc
            anchors.fill: parent
            radius: height / 2
            color: Theme.card
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true; shadowColor: Theme.shadow
                shadowBlur: 1.0; blurMax: 20; shadowVerticalOffset: 6; autoPaddingEnabled: true
            }
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: height / 2
            color: Theme.card
            clip: true

        Row {
            anchors.centerIn: parent
            spacing: 12

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: VolumeOSDState.muted || VolumeOSDState.volume <= 0.005 ? "mute" : "volume"
                tone: VolumeOSDState.muted ? "gray" : "dark"
                size: 20
            }

            // Barra de volume em formato de pílula
            Rectangle {
                id: barTrack
                anchors.verticalCenter: parent.verticalCenter
                width: 110; height: 8; radius: 4
                color: Theme.field

                Rectangle {
                    id: barFill
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(0, Math.min(1, VolumeOSDState.muted ? 0 : VolumeOSDState.volume)) * barTrack.width
                    radius: barTrack.radius
                    color: VolumeOSDState.muted ? Theme.textSecondary : Theme.textPrimary
                    Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                horizontalAlignment: Text.AlignRight
                text: VolumeOSDState.muted ? "Mudo" : Math.round(Math.min(1, VolumeOSDState.volume) * 100) + "%"
                color: VolumeOSDState.muted ? Theme.textSecondary : Theme.textPrimary
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.Medium
                font.features: { "tnum": 1 }
            }
        }
    }
}
}
