// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell

// Búsqueda de aplicaciones instaladas, compartida por la isla y el lanzador.
Singleton {
    // Devuelve aplicaciones ordenadas: empieza con > contiene > genérico/keywords.
    // Si query está vacío y allowEmpty es true, devuelve todas las apps ordenadas alfabéticamente.
    function search(query, limit, allowEmpty) {
        const q = (query || "").trim().toLowerCase()
        if (q === "") {
            if (!allowEmpty) return []
            const all = []
            for (const e of DesktopEntries.applications.values) {
                if (e.noDisplay) continue
                all.push(e)
            }
            all.sort((a, b) => (a.name || "").localeCompare(b.name || ""))
            return limit && limit > 0 ? all.slice(0, limit) : all
        }
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
        const res = out.map(o => o.e)
        return limit && limit > 0 ? res.slice(0, limit) : res
    }

    function iconFor(entry) {
        const p = Quickshell.iconPath(entry ? entry.icon : "", true)
        return p !== "" ? p : Qt.resolvedUrl("../assets/icons/gray/apps.svg")
    }
}
