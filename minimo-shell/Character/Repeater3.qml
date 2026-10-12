// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick

// Risita: tres sacudidas rápidas con rebotecitos.
SequentialAnimation {
    id: g
    property Item target
    property real amp: 8
    property real drop: 2
    NumberAnimation { target: g.target; property: "rRot"; to: g.amp; duration: 70; easing.type: Easing.OutQuad }
    ParallelAnimation { NumberAnimation { target: g.target; property: "rRot"; to: -g.amp; duration: 90 } NumberAnimation { target: g.target; property: "bounceY"; to: -g.drop; duration: 90 } }
    ParallelAnimation { NumberAnimation { target: g.target; property: "rRot"; to: g.amp; duration: 90 } NumberAnimation { target: g.target; property: "bounceY"; to: 0; duration: 90 } }
    ParallelAnimation { NumberAnimation { target: g.target; property: "rRot"; to: -g.amp; duration: 90 } NumberAnimation { target: g.target; property: "bounceY"; to: -g.drop; duration: 90 } }
    ParallelAnimation { NumberAnimation { target: g.target; property: "rRot"; to: g.amp * 0.7; duration: 90 } NumberAnimation { target: g.target; property: "bounceY"; to: 0; duration: 90 } }
    ParallelAnimation { NumberAnimation { target: g.target; property: "rRot"; to: -g.amp * 0.5; duration: 90 } NumberAnimation { target: g.target; property: "bounceY"; to: -g.drop; duration: 90 } }
    ParallelAnimation { NumberAnimation { target: g.target; property: "rRot"; to: 0; duration: 90 } NumberAnimation { target: g.target; property: "bounceY"; to: 0; duration: 90 } }
}
