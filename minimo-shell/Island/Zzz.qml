// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import "../Common"

// "z" que flotan hacia arriba y se desvanecen mientras el personaje duerme.
Item {
    id: root
    property bool running: false
    width: 14; height: 30
    visible: running

    Repeater {
        model: 3
        delegate: Text {
            enabled: false              // texto decorativo: sin interacción ni selección
            id: z
            required property int index
            text: "z"
            color: Theme.textDim
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
                        NumberAnimation { target: z; property: "opacity"; from: 0; to: 0.9; duration: 600 }
                        NumberAnimation { target: z; property: "opacity"; to: 0; duration: 2100 }
                    }
                }
                PauseAnimation { duration: (2 - z.index) * 900 }
            }
        }
    }
}
