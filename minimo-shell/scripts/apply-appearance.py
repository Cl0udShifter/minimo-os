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

    gaps_in = max(0, min(16, int(round(cfg.get("gapsIn", 4)))))
    gaps_out = max(0, min(24, int(round(cfg.get("gapsOut", 4)))))
    rounding = max(0, min(24, int(round(cfg.get("rounding", 12)))))
    border_size = max(0, min(4, int(round(cfg.get("borderSize", 0)))))
    active_opacity = max(0.70, min(1.00, float(cfg.get("activeOpacity", 1.0))))
    inactive_opacity = max(0.70, min(1.00, float(cfg.get("inactiveOpacity", 1.0))))
    resize_on_border = "true" if cfg.get("resizeOnBorder", False) else "false"

    # 1. Persistir no arquivo ~/.config/hypr/minimo/apariencia.lua e repo
    content = "-- SPDX-License-Identifier: MIT\n"
    content += "-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS\n"
    content += f"-- Aparência: janelas com cantos de {rounding} px, espaçamento {gaps_in}/{gaps_out} px, borda {border_size} px e sombra suave.\n"
    content += "-- Gerado automaticamente por Configurações › Janelas e Espaçamento do Minimo OS.\n\n"
    content += 'local acento = "rgb(9aa38f)"    -- verde acinzentado\n'
    content += 'local apagado = "rgb(807f7c)"\n'
    content += 'local bloqueado = "rgb(ff7568)"\n\n'
    content += "hl.config({\n"
    content += "\tgeneral = {\n"
    content += '\t\tlayout = "dwindle",\n'
    content += f"\t\tgaps_in = {gaps_in},\n"
    content += f"\t\tgaps_out = {gaps_out},\n"
    content += f"\t\tborder_size = {border_size},\n"
    content += f"\t\tresize_on_border = {resize_on_border},\n"
    content += "\t\tcol = { active_border = acento, inactive_border = apagado },\n"
    content += "\t},\n"
    content += "\tdecoration = {\n"
    content += f"\t\trounding = {rounding},\n"
    content += f"\t\tactive_opacity = {active_opacity:.2f},\n"
    content += f"\t\tinactive_opacity = {inactive_opacity:.2f},\n"
    content += "\t\tshadow = {\n"
    content += "\t\t\tenabled = true,\n"
    content += "\t\t\trange = 30,\n"
    content += "\t\t\trender_power = 5,\n"
    content += '\t\t\toffset = "0 5",\n'
    content += '\t\t\tcolor = "rgba(00000070)",\n'
    content += "\t\t},\n"
    content += "\t},\n"
    content += "\tgroup = {\n"
    content += "\t\tcol = {\n"
    content += "\t\t\tborder_active = acento,\n"
    content += "\t\t\tborder_inactive = apagado,\n"
    content += "\t\t\tborder_locked_active = bloqueado,\n"
    content += "\t\t\tborder_locked_inactive = apagado,\n"
    content += "\t\t},\n"
    content += "\t\tgroupbar = {\n"
    content += "\t\t\tcol = { active = acento, inactive = apagado, locked_active = bloqueado, locked_inactive = apagado },\n"
    content += "\t\t},\n"
    content += "\t},\n"
    content += "\tdwindle = { preserve_split = true },\n"
    content += "\tmaster = { mfact = 0.5 },\n"
    content += "\tmisc = {\n"
    content += "\t\tdisable_hyprland_logo = true,\n"
    content += "\t\tdisable_splash_rendering = true,\n"
    content += "\t},\n"
    content += "})\n\n"
    content += "-- Animações curtas com a curva padrão.\n"
    content += 'for leaf, speed in pairs({ windowsIn = 3, windowsOut = 3, windowsMove = 4, workspaces = 5, fade = 3, border = 3 }) do\n'
    content += '\thl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = "default" })\n'
    content += "end\n"

    target_paths = [
        os.path.expanduser("~/.config/hypr/minimo/apariencia.lua"),
        os.path.expanduser("~/Projetos/minimo-os/hypr/minimo/apariencia.lua")
    ]
    for p in target_paths:
        try:
            os.makedirs(os.path.dirname(p), exist_ok=True)
            with open(p, "w") as f:
                f.write(content)
        except Exception:
            pass

    # 2. Aplicar dinamicamente ao Hyprland via eval
    lua_eval = (
        f'return hl.config({{ '
        f'general = {{ '
        f'gaps_in = {gaps_in}, '
        f'gaps_out = {gaps_out}, '
        f'border_size = {border_size}, '
        f'resize_on_border = {resize_on_border} '
        f'}}, '
        f'decoration = {{ '
        f'rounding = {rounding}, '
        f'active_opacity = {active_opacity:.2f}, '
        f'inactive_opacity = {inactive_opacity:.2f} '
        f'}} '
        f'}})'
    )
    send_hypr(f"eval {lua_eval}\n")
    send_hypr('eval package.loaded["minimo.apariencia"] = nil\n')

if __name__ == "__main__":
    main()
