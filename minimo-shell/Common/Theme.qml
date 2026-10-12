// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell

// Tokens visuales de Minimo OS: blanco, minimalista, estilo iOS. Grilla de 8pt.
Singleton {
    readonly property color card: "#FFFFFF"
    readonly property color text: "#0A0A0B"
    readonly property color textDim: "#8E8E93"
    readonly property color field: "#F2F2F7"
    readonly property color track: "#E5E5EA"
    readonly property color fill: "#0A0A0B"
    readonly property color hover: "#E9E9EE"
    readonly property color sphere: "#0B0B0C"
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.16)

    readonly property int radiusCard: 28
    readonly property int radiusField: 12

    readonly property string font: "Adwaita Sans"

    readonly property int durFast: 160
    readonly property int durNormal: 360
    readonly property int hideDelay: 600

    readonly property int compactW: 112
    readonly property int compactH: 36
    readonly property int expandedW: 400
    readonly property int maxExpandedH: 900
    readonly property int topMargin: 8
}
