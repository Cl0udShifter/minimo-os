// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell

// Búsqueda de aplicaciones instaladas, compartida por la isla y el lanzador.
Singleton {
    // Devuelve hasta `limit` DesktopEntry ordenadas: empieza con > contiene > genérico/keywords.
    function search(query, limit) {
        const q = (query || "").trim().toLowerCase()
        if (q === "") return []
        const out = []
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue
            const name = (e.name || "").toLowerCase()
            let score = -1
            if (name.startsWith(q)) score = 0
            else if (name.includes(q)) score = 1
            else if ((e.genericName || "").toLowerCase().includes(q) || (e.keywords || []).join(" ").toLowerCase().includes(q)) score = 2
            if (score >= 0) out.push({ e: e, s: score, n: name })
        }
        out.sort((a, b) => a.s - b.s || a.n.localeCompare(b.n))
        return out.slice(0, limit || 5).map(o => o.e)
    }

    // ----- Apps ancladas (ids en DisplayState.pinnedApps; se ignoran las desinstaladas) -----
    readonly property var pinned: {
        const out = []
        for (const id of DisplayState.pinnedApps) {
            const e = DesktopEntries.byId(id)
            if (e && !e.noDisplay) out.push(e)
        }
        return out
    }
    function isPinned(entry) { return !!entry && DisplayState.pinnedApps.indexOf(entry.id) >= 0 }
    function pin(entry) {
        if (!entry || isPinned(entry)) return
        DisplayState.setPinnedApps(DisplayState.pinnedApps.concat([entry.id]))
    }
    function unpin(entry) {
        if (!entry) return
        DisplayState.setPinnedApps(DisplayState.pinnedApps.filter(id => id !== entry.id))
    }
    function togglePin(entry) { isPinned(entry) ? unpin(entry) : pin(entry) }

    function iconFor(entry) {
        const p = Quickshell.iconPath(entry ? entry.icon : "", true)
        return p !== "" ? p : Qt.resolvedUrl("../assets/icons/gray/apps.svg")
    }
}
