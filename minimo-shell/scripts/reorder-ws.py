#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
# Reordena escritorios moviendo ventanas (sin seguirlas) y deja el foco en el
# contenido que estaba activo. Uso: reorder-ws.py "1,2,3" "3,1,2" <activo>
import json, subprocess, sys

def hypr(*a):
    return subprocess.run(["hyprctl", *a], capture_output=True, text=True, timeout=5).stdout

def main():
    ids = [int(x) for x in sys.argv[1].split(",") if x]
    order = [int(x) for x in sys.argv[2].split(",") if x]
    active = int(sys.argv[3]) if len(sys.argv) > 3 else -1
    if sorted(ids) != sorted(order) or ids == order:
        return
    clients = json.loads(hypr("clients", "-j") or "[]")
    by_ws = {}
    for c in clients:
        wid = (c.get("workspace") or {}).get("id", -1)
        if wid > 0 and c.get("mapped", True):
            by_ws.setdefault(wid, []).append(c["address"])
    # Direcciones capturadas antes de mover: cada ventana se mueve una sola vez.
    for i, src in enumerate(order):
        dst = ids[i]
        if src == dst:
            continue
        for addr in by_ws.get(src, []):
            hypr("dispatch", 'hl.dsp.window.move({ workspace = "%d", follow = false, window = "address:%s" })' % (dst, addr))
    if active in order:
        hypr("dispatch", 'hl.dsp.focus({ workspace = "%d" })' % ids[order.index(active)])

if __name__ == "__main__":
    main()
