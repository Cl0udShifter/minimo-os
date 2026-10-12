#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
# Trae al frente la ventana de una app (por desktop entry o nombre): si estaba
# minimizada (special:minimized) la devuelve al escritorio actual, y la enfoca.
import json, subprocess, sys

def hypr(*a):
    return subprocess.run(["hyprctl", *a], capture_output=True, text=True, timeout=5).stdout

keys = [k.lower().removesuffix(".desktop") for k in sys.argv[1:] if k]
if not keys:
    sys.exit(0)
clients = json.loads(hypr("clients", "-j") or "[]")
def match(c):
    cls = (c.get("class") or c.get("initialClass") or "").lower()
    return cls and any(k == cls or k in cls or cls in k for k in keys)
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
