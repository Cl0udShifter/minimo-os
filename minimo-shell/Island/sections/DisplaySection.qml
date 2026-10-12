// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import "../../Common"

// Brillo y saturación por software (shader de pantalla de Hyprland).
Column {
    spacing: 8
    MSlider {
        width: parent.width
        icon: "sun"
        from: 0.3; to: 1.0
        value: DisplayState.brightness
        valueText: Math.round(value * 100) + "%"
        onMoved: v => DisplayState.set(DisplayState.saturation, v)
    }
    MSlider {
        width: parent.width
        icon: "drop"
        from: 0; to: 2
        value: DisplayState.saturation
        valueText: Math.round(value * 100) + "%"
        iconClickable: true
        onIconClicked: DisplayState.set(1.0, DisplayState.brightness)
        onMoved: v => DisplayState.set(Math.abs(v - 1) < 0.04 ? 1.0 : v, DisplayState.brightness)
    }
}
