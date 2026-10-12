// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import QtQuick.Shapes
import "../Common"

// Corazón plano (caricias): aparece con escala, sube con leve deriva y se desvanece
// (~1.2 s). Se destruye solo al terminar. Sin brillo ni contorno.
Item {
    id: h
    property real size: 10
    property real rise: 40
    property real drift: 0
    width: size; height: size
    scale: 0.4
    opacity: 0
    transformOrigin: Item.Center

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: Theme.heart
            strokeWidth: -1
            scale: Qt.size(h.size / 24, h.size / 24)
            PathSvg { path: "M12 21.2C10.9 20.3 2.5 14.2 2.5 8.4 2.5 5.3 4.9 3 7.8 3c1.8 0 3.3.9 4.2 2.3C12.9 3.9 14.4 3 16.2 3c2.9 0 5.3 2.3 5.3 5.4 0 5.8-8.4 11.9-9.5 12.8z" }
        }
    }

    ParallelAnimation {
        running: true
        NumberAnimation { target: h; property: "y"; to: h.y - h.rise; duration: 1200; easing.type: Easing.OutCubic }
        NumberAnimation { target: h; property: "x"; to: h.x + h.drift; duration: 1200; easing.type: Easing.InOutSine }
        NumberAnimation { target: h; property: "scale"; to: 1; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.0 }
        NumberAnimation { target: h; property: "rotation"; from: -h.drift * 0.4; to: h.drift * 0.4; duration: 1200; easing.type: Easing.InOutSine }
        SequentialAnimation {
            NumberAnimation { target: h; property: "opacity"; to: 0.95; duration: 200; easing.type: Easing.OutCubic }
            PauseAnimation { duration: 450 }
            NumberAnimation { target: h; property: "opacity"; to: 0; duration: 550; easing.type: Easing.InOutSine }
        }
        onFinished: h.destroy()
    }
}
