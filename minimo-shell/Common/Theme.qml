// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell

// Tokens visuales de Minimo OS. Claro (blanco, estilo iOS) u oscuro (casi negro, estilo
// Apple), con transparencia de superficies. Todo color de la shell sale de acá; los
// cambios de tema los animan los consumidores (~250 ms).
// Sin dependencias a otros singletons: DisplayState empuja dark/surfaceOpacity acá.
Singleton {
    id: t
    property bool dark: false              // lo fija DisplayState al cargar/cambiar
    property real surfaceOpacity: 1.0      // lo fija DisplayState (0.5..1)

    function pick(light, darkc) { return t.dark ? darkc : light }
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    // Superficies
    property color cardSolid: pick("#FFFFFF", "#1C1C1E")
    readonly property color card: alpha(cardSolid, surfaceOpacity)     // isla, lanzador, ajustes
    property color field: pick("#F2F2F7", "#2C2C2E")                   // campos y filas
    property color raised: pick("#FFFFFF", "#3A3A3C")                  // chips dentro de un campo
    property color subtle: pick("#F7F7FA", "#242426")                  // barra lateral, hover suave
    property color hover: pick("#E9E9EE", "#3A3A3C")
    property color track: pick("#E5E5EA", "#3A3A3C")                   // pistas y bordes
    property color dot: pick("#C7C7CC", "#48484A")
    property color scrim: pick(Qt.rgba(1, 1, 1, 0.6), Qt.rgba(0, 0, 0, 0.5))
    property color wallFallback: pick("#E9E9EC", "#121214")
    // Texto y acento
    property color text: pick("#0A0A0B", "#F5F5F7")
    property color textDim: pick("#8E8E93", "#98989F")
    property color fill: pick("#0A0A0B", "#F5F5F7")                    // relleno fuerte (activo)
    property color fillHover: pick("#2A2A2E", "#D1D1D6")
    property color onFill: pick("#FFFFFF", "#0A0A0B")                  // texto/ícono sobre `fill`
    property color danger: pick("#FF3B30", "#FF453A")
    // Personaje: negro con ojos blancos (claro) / blanco con ojos negros (oscuro)
    property color sphere: pick("#0B0B0C", "#F5F5F7")
    property color eye: pick("#FFFFFF", "#0B0B0C")
    readonly property color shadow: Qt.rgba(0, 0, 0, dark ? 0.45 : 0.16)


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
