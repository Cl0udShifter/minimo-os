// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import QtQuick.Shapes
import "../Common"

// Corazón plano de las caricias, del color del cuerpo del personaje (negro en claro,
// blanco en oscuro). Aparece con un "pop" (overshoot), sube con deriva y un vaivén
// suave, y se desvanece (~1.3 s). Se destruye solo al terminar.
Item {
    id: h
    property real size: 10
    property real rise: 40
    property real drift: 0
    property int delay: 0
    width: size; height: size
    scale: 0.3
    opacity: 0
    transformOrigin: Item.Center
    Component.onCompleted: CharacterBus.hearts++
    Component.onDestruction: CharacterBus.hearts--
    // Física aleatoria: duración, vaivén y escala final varían por partícula.
    readonly property int life: 1150 + Math.round(Math.random() * 350)
    readonly property real sway: 6 + Math.random() * 6
    readonly property real peak: 0.9 + Math.random() * 0.2

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: Theme.sphere
            strokeWidth: -1
            scale: Qt.size(h.size / 24, h.size / 24)
            PathSvg { path: "M12 21.2C10.9 20.3 2.5 14.2 2.5 8.4 2.5 5.3 4.9 3 7.8 3c1.8 0 3.3.9 4.2 2.3C12.9 3.9 14.4 3 16.2 3c2.9 0 5.3 2.3 5.3 5.4 0 5.8-8.4 11.9-9.5 12.8z" }
        }
    }

    SequentialAnimation {
        running: true
        PauseAnimation { duration: h.delay }
        ParallelAnimation {
            NumberAnimation { target: h; property: "y"; to: h.y - h.rise; duration: h.life; easing.type: Easing.OutCubic }
            NumberAnimation { target: h; property: "x"; to: h.x + h.drift; duration: h.life; easing.type: Easing.InOutSine }
            NumberAnimation { target: h; property: "scale"; to: h.peak; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
            SequentialAnimation {   // vaivén
                NumberAnimation { target: h; property: "rotation"; to: h.sway; duration: 320; easing.type: Easing.InOutSine }
                NumberAnimation { target: h; property: "rotation"; to: -h.sway * 0.8; duration: 420; easing.type: Easing.InOutSine }
                NumberAnimation { target: h; property: "rotation"; to: h.sway * 0.4; duration: 560; easing.type: Easing.InOutSine }
            }
            SequentialAnimation {
                NumberAnimation { target: h; property: "opacity"; to: 1; duration: 160; easing.type: Easing.OutCubic }
                PauseAnimation { duration: h.life - 740 }
                NumberAnimation { target: h; property: "opacity"; to: 0; duration: 580; easing.type: Easing.InOutSine }
            }
        }
        ScriptAction { script: h.destroy() }
    }
}
