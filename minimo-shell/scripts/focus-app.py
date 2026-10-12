#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
# Trae al frente la ventana de una app (por desktop entry o nombre): si estaba
# minimizada (special:minimized) la devuelve al escritorio actual, y la enfoca.
import json, subprocess, sys

def hypr(*a):
    return subprocess.run(["hyprctl", *a], capture_output=True, text=True, timeout=5).stdout

clients = json.loads(hypr("clients", "-j") or "[]")
# Modo directo: focus-app.py --address 0x… (panel "Apps abiertas").
if len(sys.argv) > 2 and sys.argv[1] == "--address":
    want = sys.argv[2]
    keys = []
    cands = [c for c in clients if c.get("address") == want]
    # La ventana ya no existe (p. ej. la app se fue a la bandeja): relanzarla la vuelve a mostrar.
    if not cands and len(sys.argv) > 4 and sys.argv[3] == "--launch":
        subprocess.Popen(["gtk-launch", sys.argv[4]], start_new_session=True,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        sys.exit(0)
else:
    keys = [k.lower().removesuffix(".desktop") for k in sys.argv[1:] if k]
    cands = None
if cands is None and not keys:
    sys.exit(0)
def match(c):
    cls = (c.get("class") or c.get("initialClass") or "").lower()
    return cls and any(k == cls or k in cls or cls in k for k in keys)
if cands is None:
    cands = [c for c in clients if match(c)]
if not cands:
    sys.exit(0)
# La usada más recientemente primero.
c = min(cands, key=lambda c: c.get("focusHistoryID", 999))
addr = c["address"]
ws = (c.get("workspace") or {}).get("name", "")
if ws.startswith("special:minimized"):
    cur = json.loads(hypr("activeworkspace", "-j") or "{}").get("id", 1)
    hypr("dispatch", 'hl.dsp.window.move({ workspace = "%s", follow = true, window = "address:%s" })' % (cur, addr))
hypr("dispatch", 'hl.dsp.focus({ window = "address:%s" })' % addr)
