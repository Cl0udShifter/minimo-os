#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import os
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

def main():
    state_file = os.path.expanduser("~/.config/minimo-os/state.json")
    try:
        with open(state_file, "r") as f:
            state = json.load(f)
    except Exception:
        state = {}

    split = state.get("splitWorkspaces", True)

    mon_raw = send_hypr("j/monitors")
    monitors = []
    if mon_raw:
        try:
            monitors = json.loads(mon_raw)
        except Exception:
            pass

    out = "-- SPDX-License-Identifier: MIT\n"
    out += "-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS\n"
    out += "-- Regras de workspaces independentes por monitor — gerado dinamicamente.\n\n"

    if split and len(monitors) > 0:
        for idx, m in enumerate(monitors):
            name = m.get("name", "")
            mid = m.get("id", idx)
            if not name:
                continue
            out += f"-- Monitor {mid}: {name} (Workspaces {mid * 10 + 1} a {mid * 10 + 9})\n"
            for w in range(1, 10):
                ws_id = mid * 10 + w
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
            with open(p, "w") as f:
                f.write(out)
        except Exception:
            pass

    send_hypr("reload")

if __name__ == "__main__":
    main()
