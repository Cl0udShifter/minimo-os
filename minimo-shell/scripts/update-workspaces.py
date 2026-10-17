#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import os
import sys
import json
import socket

def send_hypr(cmd_str):
    try:
        sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
        if not sig:
            hypr_dir = f"/run/user/{os.getuid()}/hypr"
            if not os.path.exists(hypr_dir):
                return None
            sigs = sorted(
                [s for s in os.listdir(hypr_dir) if os.path.isdir(os.path.join(hypr_dir, s))],
                key=lambda s: os.path.getmtime(os.path.join(hypr_dir, s)),
                reverse=True
            )
            if not sigs:
                return None
            sig = sigs[0]
        sock_path = f"/run/user/{os.getuid()}/hypr/{sig}/.socket.sock"
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(sock_path)
        payload = cmd_str.encode() if isinstance(cmd_str, str) else cmd_str
        s.sendall(payload)
        res = b""
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            res += chunk
            if len(chunk) < 4096:
                break
        s.close()
        return res.decode()
    except Exception:
        return None

def get_state():
    state_file = os.path.expanduser("~/.config/minimo-os/state.json")
    try:
        with open(state_file, "r") as f:
            return json.load(f)
    except Exception:
        return {}

def main():
    state = get_state()
    split = state.get("splitWorkspaces", True)

    mon_raw = send_hypr("j/monitors")
    monitors = []
    if mon_raw:
        try:
            monitors = json.loads(mon_raw)
        except Exception:
            pass

    # Ordenação estável e determinística dos monitores:
    # Monitor principal (DP-1 ou menor X/Y) é sempre o índice 0 (Monitor 1)
    primary_name = state.get("primaryMonitor")
    active_mons = [m for m in monitors if not m.get("disabled")]

    def sort_key(m):
        name = m.get("name", "")
        is_primary = (name == primary_name) if primary_name else (m.get("x", 0) == 0 and m.get("y", 0) == 0)
        return (0 if is_primary else 1, m.get("x", 0), m.get("y", 0))

    sorted_monitors = sorted(active_mons, key=sort_key)

    # Persistir lista estável de monitores para consumo pelo shell
    monitors_info = []
    for idx, m in enumerate(sorted_monitors):
        monitors_info.append({
            "index": idx,
            "number": idx + 1,
            "name": m.get("name", ""),
            "model": (m.get("make", "") + " " + m.get("model", "")).strip() or m.get("name", ""),
            "primary": idx == 0,
            "x": m.get("x", 0),
            "y": m.get("y", 0),
            "width": m.get("width", 1920),
            "height": m.get("height", 1080),
            "scale": m.get("scale", 1.0)
        })

    monitors_json_path = os.path.expanduser("~/.config/minimo-os/monitors.json")
    try:
        os.makedirs(os.path.dirname(monitors_json_path), exist_ok=True)
        with open(monitors_json_path, "w", encoding="utf-8") as f:
            json.dump({"monitors": monitors_info}, f, indent=2, ensure_ascii=False)
    except Exception:
        pass

    out = "-- SPDX-License-Identifier: MIT\n"
    out += "-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS\n"
    out += "-- Regras de workspaces independentes por monitor — gerado dinamicamente.\n\n"

    if split and len(sorted_monitors) > 0:
        for idx, m in enumerate(sorted_monitors):
            name = m.get("name", "")
            if not name:
                continue
            base = idx * 10
            out += f"-- Monitor {idx + 1}: {name} (Workspaces {base + 1} a {base + 9})\n"
            for w in range(1, 10):
                ws_id = base + w
                is_default = "true" if w == 1 else "false"
                out += f'hl.workspace_rule({{ workspace = "{ws_id}", monitor = "{name}", default = {is_default} }})\n'
            out += "\n"

    target_paths = [
        os.path.expanduser("~/.config/hypr/minimo/workspaces.lua"),
        os.path.expanduser("~/Projetos/minimo-os/hypr/minimo/workspaces.lua")
    ]

    for p in target_paths:
        try:
            os.makedirs(os.path.dirname(p), exist_ok=True)
            with open(p, "w", encoding="utf-8") as f:
                f.write(out)
        except Exception:
            pass

    send_hypr("reload")

if __name__ == "__main__":
    main()
