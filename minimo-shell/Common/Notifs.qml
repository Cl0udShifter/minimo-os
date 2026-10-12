// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications

// Servidor de notificaciones de Minimo OS (org.freedesktop.Notifications).
// Las muestra de a una en la isla compacta, en cola (máx. 8), ~5 s cada una.
// Si la app de origen está enfocada, el aviso es más breve (2,5 s): ya la estás viendo.
// "No molestar": qs ipc call notifs dnd  (las críticas se muestran igual).
Singleton {
    id: root
    property var queue: []
    readonly property var current: queue.length > 0 ? queue[0] : null
    property bool dnd: false
    // Mouse encima de alguna isla (una por monitor): no corre el tiempo.
    property int hovers: 0
    readonly property bool paused: hovers > 0

    function keyOf(n) { return ((n.desktopEntry || n.appName || "") + "").toLowerCase() }
    // ¿La app de la notificación es la ventana enfocada?
    function fromFocused(n) {
        const t = Hyprland.activeToplevel
        const cls = t && t.lastIpcObject ? ((t.lastIpcObject["class"] || "") + "").toLowerCase() : ""
        const k = keyOf(n)
        return k !== "" && cls !== "" && (cls.includes(k) || k.includes(cls))
    }
    function iconOf(n) {
        if (!n) return ""
        if (n.image) return n.image
        const p = Quickshell.iconPath(n.appIcon || n.desktopEntry || "", true)
        if (p !== "") return p
        const e = n.desktopEntry ? DesktopEntries.byId(n.desktopEntry) : DesktopEntries.heuristicLookup(n.appName || "")
        return e ? Quickshell.iconPath(e.icon, true) : ""
    }

    function next() {
        const q = queue.slice(1)
        queue = q
    }
    // Cierra la actual (el usuario la descartó o se venció el tiempo).
    function dismiss() { const n = current; next(); if (n) n.dismiss() }
    // Clic en el aviso: acción "default" si existe; si no, trae la app (desminimiza y enfoca).
    function activate() {
        const n = current
        if (!n) return
        const def = Array.from(n.actions || []).find(a => a.identifier === "default")
        if (def) def.invoke()
        else Quickshell.execDetached([Qt.resolvedUrl("../scripts/focus-app.py").toString().replace("file://", ""),
                                      n.desktopEntry || "", n.appName || ""])
        next(); n.dismiss()
    }
    function invoke(action) { const n = current; action.invoke(); next(); if (n) n.dismiss() }

    NotificationServer {
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true
        persistenceSupported: false
        onNotification: n => {
            const critical = n.urgency === NotificationUrgency.Critical
            if (root.dnd && !critical) { n.expire(); return }
            n.tracked = true
            // Si la app cierra/reemplaza la notificación, sale de la cola.
            n.closed.connect(() => { root.queue = root.queue.filter(x => x !== n) })
            let q = root.queue.concat([n])
            while (q.length > 8) { const old = q.splice(1, 1)[0]; old.expire() }
            root.queue = q
        }
    }

    Timer {
        id: life
        interval: root.current ? (root.current.urgency === NotificationUrgency.Critical ? 9000
                                  : root.fromFocused(root.current) ? 2500 : 5000) : 5000
        running: root.current !== null && !root.paused
        onTriggered: { const n = root.current; root.next(); if (n) n.expire() }
    }
    onCurrentChanged: if (current) life.restart()

    IpcHandler {
        target: "notifs"
        function dnd(): string { root.dnd = !root.dnd; return root.dnd ? "no molestar: sí" : "no molestar: no" }
        function clear(): void { const q = root.queue; root.queue = []; q.forEach(n => n.dismiss()) }
    }
}
