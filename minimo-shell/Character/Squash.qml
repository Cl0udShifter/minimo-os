// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick

// Paso de squash & stretch (y salto) para el personaje.
ParallelAnimation {
    id: sq
    property Item who
    property real sx: 1
    property real sy: 1
    property real toY: 0
    property int ms: 100
    property int ease: Easing.Linear
    NumberAnimation { target: sq.who; property: "squashX"; to: sq.sx; duration: sq.ms; easing.type: sq.ease }
    NumberAnimation { target: sq.who; property: "squashY"; to: sq.sy; duration: sq.ms; easing.type: sq.ease }
    NumberAnimation { target: sq.who; property: "bounceY"; to: sq.toY; duration: sq.ms; easing.type: Easing.OutQuad }
}
