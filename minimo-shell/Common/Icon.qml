// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick

// Icono de línea monocromo desde assets/icons/<tono>/<nombre>.svg.
Image {
    property string name
    property string tone: "dark"   // dark | gray | white
    property int size: 20
    width: size; height: size
    sourceSize: Qt.size(size * 2, size * 2)
    source: name ? Qt.resolvedUrl("../assets/icons/" + tone + "/" + name + ".svg") : ""
    smooth: true
}
