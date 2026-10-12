#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
# Vuelve a mostrar una app de la bandeja (panel "En segundo plano").
# Uso: tray-open.py <id del item SNI> [desktop entry id]
# Muchas apps (Steam/libappindicator, Electron) ignoran Activate, así que después de
# pedírselo desde QML seguimos esta cadena: ventana existente → enfocarla;
# si no hay → relanzar (las apps de instancia única muestran la ventana que ya tienen).
import json, os, subprocess, sys, time

def run(*a, timeout=4):
    try:
        return subprocess.run(a, capture_output=True, text=True, timeout=timeout).stdout
    except Exception:
        return ""

def log(msg):
    print("tray-open:", msg, file=sys.stderr, flush=True)

# Modo "--quit <id>": cerrar la app con amabilidad (SIGTERM), para items sin menú propio.
quit_mode = len(sys.argv) > 1 and sys.argv[1] == "--quit"
args = sys.argv[2:] if quit_mode else sys.argv[1:]
item_id = args[0] if len(args) > 0 else ""
entry = args[1] if len(args) > 1 else ""

def item_pid():
    """PID dueño del item SNI con ese Id (vía el watcher y el bus)."""
    out = run("busctl", "--user", "--json=short", "get-property", "org.kde.StatusNotifierWatcher",
              "/StatusNotifierWatcher", "org.kde.StatusNotifierWatcher", "RegisteredStatusNotifierItems")
    try:
        items = json.loads(out)["data"]
    except Exception:
        return 0
    for it in items:
        svc, _, path = it.partition("/")
        path = "/" + path if path else "/StatusNotifierItem"
        got = run("busctl", "--user", "--json=short", "get-property", svc, path, "org.kde.StatusNotifierItem", "Id")
        try:
            if json.loads(got)["data"] != item_id:
                continue
            pid = run("busctl", "--user", "--json=short", "call", "org.freedesktop.DBus", "/org/freedesktop/DBus",
                      "org.freedesktop.DBus", "GetConnectionUnixProcessID", "s", svc)
            return int(json.loads(pid)["data"][0])
        except Exception:
            continue
    return 0

def family(pid):
    """El PID y todos sus descendientes: la ventana de Steam la dibuja un nieto
    (steamwebhelper) y las de Electron, procesos hijos."""
    kids = {}
    try:
        for p in os.listdir("/proc"):
            if p.isdigit():
                try:
                    with open(f"/proc/{p}/stat") as f:
                        ppid = int(f.read().rsplit(")", 1)[1].split()[1])
                    kids.setdefault(ppid, []).append(int(p))
                except (OSError, ValueError, IndexError):
                    pass
    except OSError:
        pass
    fam, todo = {pid}, [pid]
    while todo:
        for k in kids.get(todo.pop(), []):
            if k not in fam:
                fam.add(k); todo.append(k)
    return fam

def comm(pid):
    try:
        with open(f"/proc/{pid}/comm") as f:
            return f.read().strip().lower()
    except Exception:
        return ""

def find_window(pid):
    try:
        clients = json.loads(run("hyprctl", "clients", "-j") or "[]")
    except ValueError:
        clients = []
    fam = family(pid) if pid else set()
    keys = {k for k in (item_id.lower(), entry.lower().removesuffix(".desktop"), comm(pid)) if k}
    hit = [c for c in clients if c.get("pid") in fam]
    if not hit:
        hit = [c for c in clients if (c.get("class") or "").lower() in keys]
    hit = [c for c in hit if c.get("mapped", True) and not c.get("hidden")
           and (c.get("size") or [1, 1])[0] > 40 and (c.get("size") or [1, 1])[1] > 40]
    return min(hit, key=lambda c: c.get("focusHistoryID", 999)) if hit else None

if not item_id:
    sys.exit(0)
if quit_mode:
    import signal
    pid = item_pid()
    me = {os.getpid(), os.getppid()}
    if pid <= 1 or pid in me or comm(pid) in ("qs", "quickshell", "systemd", "hyprland"):
        log(f"{item_id}: no se cierra (pid {pid})")
        sys.exit(1)
    os.kill(pid, signal.SIGTERM)
    log(f"{item_id}: SIGTERM a {pid} ({comm(pid)})")
    sys.exit(0)
time.sleep(0.6)   # darle tiempo al Activate que ya mandó QML
pid = item_pid()
c = find_window(pid)
if c:
    addr = c["address"]
    if (c.get("workspace") or {}).get("name", "").startswith("special:"):
        try:
            cur = json.loads(run("hyprctl", "activeworkspace", "-j") or "{}").get("id", 1)
        except ValueError:
            cur = 1
        run("hyprctl", "dispatch", 'hl.dsp.window.move({ workspace = "%s", follow = true, window = "address:%s" })' % (cur, addr))
    run("hyprctl", "dispatch", 'hl.dsp.focus({ window = "address:%s" })' % addr)
    log(f"{item_id}: ventana {addr} enfocada")
    sys.exit(0)

# Sin ventana: relanzar.
name = (entry or comm(pid) or item_id).lower().removesuffix(".desktop")
if comm(pid) in ("qs", "quickshell"):
    sys.exit(0)
if "steam" in name:
    cmd = ["steam", "steam://open/main"]
elif entry:
    cmd = ["gtk-launch", entry.removesuffix(".desktop")]
elif pid and os.path.exists(f"/proc/{pid}/exe"):
    cmd = [os.readlink(f"/proc/{pid}/exe")]
else:
    log(f"{item_id}: sin ventana ni forma de relanzar")
    sys.exit(1)
subprocess.Popen(cmd, start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
log(f"{item_id}: relanzado con {cmd}")
