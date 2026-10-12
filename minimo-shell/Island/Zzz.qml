// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import "../Common"

// "z" que flotan hacia arriba y se desvanecen mientras el personaje duerme.
Item {
    id: root
    property bool running: false
    // Al despertar las z no desaparecen de golpe: se desvanecen.
    opacity: running ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutSine } }
    width: 14; height: 30
    visible: opacity > 0

    Loader {
        anchors.fill: parent
        active: root.visible          // despierto: sin objetos ni animaciones
        sourceComponent: zs
    }
    Component { id: zs; Item { anchors.fill: parent
    Repeater {
        model: 3
        delegate: Text {
            enabled: false              // texto decorativo: sin interacción ni selección
            id: z
            required property int index
            text: "z"
            color: Theme.textSecondary
            Behavior on color { ColorAnimation { duration: 250 } }
            font.family: Theme.font
            font.pixelSize: 9 + index * 1.5
            font.weight: Font.Normal
            opacity: 0
            x: 0; y: root.height
            SequentialAnimation {
                running: root.running
                loops: Animation.Infinite
                PauseAnimation { duration: z.index * 900 }
                ParallelAnimation {
                    NumberAnimation { target: z; property: "y"; from: root.height - 10; to: -4; duration: 2700; easing.type: Easing.OutSine }
                    NumberAnimation { target: z; property: "x"; from: 0; to: 8; duration: 2700; easing.type: Easing.InOutSine }
                    SequentialAnimation {
                        NumberAnimation { target: z; property: "opacity"; from: 0; to: 0.85; duration: 700; easing.type: Easing.OutCubic }
                        NumberAnimation { target: z; property: "opacity"; to: 0; duration: 2000; easing.type: Easing.InOutSine }
                    }
                }
                PauseAnimation { duration: (2 - z.index) * 900 }
            }
        }
    }
    } }
}
