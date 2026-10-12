// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick

// Un paso de la risita: inclinación + rebotecito, ease-in-out.
ParallelAnimation {
    id: st
    property Item who
    property real rot: 0
    property real y: 0
    property int ms: 120
    NumberAnimation { target: st.who; property: "rRot"; to: st.rot; duration: st.ms; easing.type: Easing.InOutSine }
    NumberAnimation { target: st.who; property: "bounceY"; to: st.y; duration: st.ms; easing.type: Easing.InOutSine }
}
