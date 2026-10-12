// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

// Inactividad de TODA la PC (protocolo ext-idle-notify): sin teclado ni mouse en
// ningún lado durante DisplayState.sleepMinutes, el personaje se duerme. Respeta los
// inhibidores (videos, etc.). `sleepNow()` fuerza el sueño hasta la próxima actividad.
Singleton {
    id: root
    property bool forced: false
    readonly property bool sleeping: monitor.isIdle || forced
    // Nadie mira la pantalla (inactividad real, no sueño forzado): se pausan animaciones continuas.
    readonly property bool unattended: monitor.isIdle

    function sleepNow() { forced = true }
    function wake() { forced = false }

    IdleMonitor {
        id: monitor
        timeout: Math.max(1, DisplayState.sleepMinutes) * 60
        respectInhibitors: true
        onIsIdleChanged: if (!isIdle) root.forced = false
    }
}
