// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick

// Paso de squash & stretch (y salto) para el personaje. Mantener |1 - sx|, |1 - sy| ≤ 0.08
// y sx·sy ≈ 1 (conserva volumen).
ParallelAnimation {
    id: sq
    property Item who
    property real sx: 1
    property real sy: 1
    property real toY: 0
    property int ms: 100
    property int ease: Easing.InOutSine
    property real overshoot: 1.0     // OutBack sutil (por defecto de Qt: 1.7, demasiado)
    NumberAnimation { target: sq.who; property: "squashX"; to: sq.sx; duration: sq.ms; easing.type: sq.ease; easing.overshoot: sq.overshoot }
    NumberAnimation { target: sq.who; property: "squashY"; to: sq.sy; duration: sq.ms; easing.type: sq.ease; easing.overshoot: sq.overshoot }
    NumberAnimation { target: sq.who; property: "bounceY"; to: sq.toY; duration: sq.ms; easing.type: sq.ease; easing.overshoot: sq.overshoot }
}
