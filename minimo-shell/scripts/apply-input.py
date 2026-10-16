#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import sys
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
    if len(sys.argv) < 2:
        return
    try:
        cfg = json.loads(sys.argv[1])
    except Exception:
        return

    kb_layout = cfg.get("kbLayout", "br")
    kb_variant = cfg.get("kbVariant", "abnt2")
    kb_model = cfg.get("kbModel", "")

    # Suporte a múltiplos layouts nativos do XKB para alternância instantânea sem recarga de mapa
    if kb_layout == "br":
        multi_layout = "br,us"
        multi_variant = f"{kb_variant or 'abnt2'},intl"
    elif kb_layout == "us":
        multi_layout = "us,br"
        multi_variant = f"{kb_variant or 'intl'},abnt2"
    else:
        multi_layout = f"{kb_layout},us"
        multi_variant = f"{kb_variant},intl"

    numlock_by_default = "true" if cfg.get("numlockByDefault", True) else "false"
    follow_mouse = int(cfg.get("followMouse", 1))
    sensitivity = float(cfg.get("sensitivity", 0.0))
    accel_profile = cfg.get("accelProfile", "adaptive")
    natural_scroll_mouse = "true" if cfg.get("naturalScrollMouse", False) else "false"
    touchpad_tap = "true" if cfg.get("touchpadTapToClick", True) else "false"
    touchpad_natural = "true" if cfg.get("touchpadNaturalScroll", True) else "false"
    touchpad_scroll_factor = float(cfg.get("touchpadScrollFactor", 1.0))
    gestures = cfg.get("touchpadGestures", True)

    # 1. Persistir no arquivo ~/.config/hypr/minimo/entrada.lua e repo
    content = "-- SPDX-License-Identifier: MIT\n"
    content += "-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS\n"
    content += "-- Entrada: layout do sistema, Num Lock ativo, foco segue o mouse, touchpad natural.\n"
    content += "-- Gerado automaticamente por Configurações › Mouse e Teclado do Minimo OS.\n\n"
    content += "hl.config({\n"
    content += "\tinput = {\n"
    content += f'\t\tkb_layout = "{multi_layout}",\n'
    content += f'\t\tkb_variant = "{multi_variant}",\n'
    content += f'\t\tkb_model = "{kb_model}",\n'
    content += f"\t\tnumlock_by_default = {numlock_by_default},\n"
    content += f"\t\tfollow_mouse = {follow_mouse},\n"
    content += f"\t\tsensitivity = {sensitivity:.2f},\n"
    content += f'\t\taccel_profile = "{accel_profile}",\n'
    content += f"\t\tnatural_scroll = {natural_scroll_mouse},\n"
    content += "\t\ttouchpad = {\n"
    content += f"\t\t\ttap_to_click = {touchpad_tap},\n"
    content += f"\t\t\tnatural_scroll = {touchpad_natural},\n"
    content += f"\t\t\tscroll_factor = {touchpad_scroll_factor:.2f},\n"
    content += "\t\t},\n"
    content += "\t},\n"
    content += "})\n\n"

    if gestures:
        content += "-- Três dedos na horizontal: alternar área de trabalho.\n"
        content += 'hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })\n'

    target_paths = [
        os.path.expanduser("~/.config/hypr/minimo/entrada.lua"),
        os.path.expanduser("~/Projetos/minimo-os/hypr/minimo/entrada.lua")
    ]
    for p in target_paths:
        try:
            os.makedirs(os.path.dirname(p), exist_ok=True)
            with open(p, "w") as f:
                f.write(content)
        except Exception:
            pass

    # 2. Aplicar dinamicamente ao Hyprland via eval e reload
    lua_eval = (
        f'return hl.config({{ '
        f'input = {{ '
        f'kb_layout = "{multi_layout}", '
        f'kb_variant = "{multi_variant}", '
        f'kb_model = "{kb_model}", '
        f'numlock_by_default = {numlock_by_default}, '
        f'follow_mouse = {follow_mouse}, '
        f'sensitivity = {sensitivity:.2f}, '
        f'accel_profile = "{accel_profile}", '
        f'natural_scroll = {natural_scroll_mouse}, '
        f'touchpad = {{ '
        f'tap_to_click = {touchpad_tap}, '
        f'natural_scroll = {touchpad_natural}, '
        f'scroll_factor = {touchpad_scroll_factor:.2f} '
        f'}} '
        f'}} '
        f'}})'
    )
    send_hypr(f"eval {lua_eval}\n")
    send_hypr('eval package.loaded["minimo.entrada"] = nil\n')

if __name__ == "__main__":
    main()

