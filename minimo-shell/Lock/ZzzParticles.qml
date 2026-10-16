// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import "../Common"

// Animação procedural de letras 'Zzz' flutuantes e orgânicas
// exibidas suavemente acima do bonequinho enquanto ele dorme.
Item {
    id: root

    property bool active: false
    width: 60
    height: 80

    property real time: 0
    NumberAnimation on time {
        running: root.active
        loops: Animation.Infinite
        from: 0
        to: 320000
        duration: 320000
    }

    Repeater {
        model: 3
        delegate: Item {
            id: pItem
            required property int index

            readonly property real delay: index * 1060
            readonly property string zChar: index === 0 ? "z" : (index === 1 ? "z" : "Z")
            readonly property real baseSize: index === 0 ? 12 : (index === 1 ? 16 : 22)

            readonly property real prog: ((root.time + delay) % 3200) / 3200

            x: 8 + Math.sin(prog * Math.PI * 2.2) * 14 + prog * 24
            y: root.height - 15 - (prog * 65)
            scale: 0.6 + prog * 0.55
            rotation: -8 + Math.sin(prog * Math.PI * 2.5) * 16

            opacity: {
                if (!root.active) return 0
                if (prog < 0.2) return prog / 0.2
                if (prog > 0.75) return (1 - prog) / 0.25
                return 0.85
            }

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            Text {
                text: pItem.zChar
                color: Theme.textPrimary
                font.family: Theme.font
                font.pixelSize: pItem.baseSize
                font.weight: Font.DemiBold
            }
        }
    }
}
