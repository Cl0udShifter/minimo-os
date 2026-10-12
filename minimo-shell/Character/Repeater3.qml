// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick

// Risita: balanceo suave que se amortigua, con rebotecitos (ease-in-out, sin golpes).
SequentialAnimation {
    id: g
    property Item target
    property real amp: 6
    property real drop: 2
    GiggleStep { who: g.target; rot: g.amp; y: -g.drop; ms: 110 }
    GiggleStep { who: g.target; rot: -g.amp * 0.85; y: 0 }
    GiggleStep { who: g.target; rot: g.amp * 0.6; y: -g.drop * 0.7 }
    GiggleStep { who: g.target; rot: -g.amp * 0.35; y: 0 }
    GiggleStep { who: g.target; rot: 0; y: 0; ms: 160 }
}
