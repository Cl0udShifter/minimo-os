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

    anim_preset = cfg.get("animPreset", "smooth")
    if anim_preset not in ["smooth", "fast", "instant", "disabled"]:
        anim_preset = "smooth"
    anim_enabled = "false" if anim_preset == "disabled" else "true"

    blur_enabled = "true" if cfg.get("blurEnabled", True) else "false"
    blur_size = max(3, min(14, int(round(cfg.get("blurSize", 8)))))
    blur_passes = 3 if blur_size >= 11 else (2 if blur_size >= 6 else 1)

    shadow_enabled = "true" if cfg.get("shadowEnabled", True) else "false"
    shadow_range = max(10, min(60, int(round(cfg.get("shadowRange", 30)))))

    # Presets de animação
    if anim_preset == "disabled":
        anim_lua_block = "-- Animações desativadas.\n"
        anim_eval_block = ""
    elif anim_preset == "instant":
        anim_lua_block = (
            "-- Animações instantâneas (mínimas).\n"
            "for leaf, speed in pairs({ windowsIn = 0.8, windowsOut = 0.8, windowsMove = 1.0, workspaces = 1.2, fade = 0.8, border = 0.8 }) do\n"
            "\thl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = \"default\" })\n"
            "end\n"
        )
        anim_eval_block = (
            "for leaf, speed in pairs({ windowsIn = 0.8, windowsOut = 0.8, windowsMove = 1.0, workspaces = 1.2, fade = 0.8, border = 0.8 }) do "
            "hl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = 'default' }) end "
        )
    elif anim_preset == "fast":
        anim_lua_block = (
            "-- Animações rápidas e ágeis.\n"
            "for leaf, speed in pairs({ windowsIn = 1.8, windowsOut = 1.8, windowsMove = 2.2, workspaces = 2.8, fade = 1.8, border = 1.8 }) do\n"
            "\thl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = \"default\" })\n"
            "end\n"
        )
        anim_eval_block = (
            "for leaf, speed in pairs({ windowsIn = 1.8, windowsOut = 1.8, windowsMove = 2.2, workspaces = 2.8, fade = 1.8, border = 1.8 }) do "
            "hl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = 'default' }) end "
        )
    else:  # "smooth"
        anim_lua_block = (
            "-- Animações suaves com a curva padrão do Minimo OS.\n"
            "for leaf, speed in pairs({ windowsIn = 3, windowsOut = 3, windowsMove = 4, workspaces = 5, fade = 3, border = 3 }) do\n"
            "\thl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = \"default\" })\n"
            "end\n"
        )
        anim_eval_block = (
            "for leaf, speed in pairs({ windowsIn = 3, windowsOut = 3, windowsMove = 4, workspaces = 5, fade = 3, border = 3 }) do "
            "hl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = 'default' }) end "
        )

    # 1. Persistir no arquivo ~/.config/hypr/minimo/apariencia.lua e repo
    content = "-- SPDX-License-Identifier: MIT\n"
    content += "-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS\n"
    content += f"-- Aparência: janelas com cantos de {rounding} px, espaçamento {gaps_in}/{gaps_out} px, borda {border_size} px, blur {blur_size} px e sombras.\n"
    content += "-- Gerado automaticamente por Configurações do Minimo OS.\n\n"
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
    content += f"\t\t\tenabled = {shadow_enabled},\n"
    content += f"\t\t\trange = {shadow_range},\n"
    content += "\t\t\trender_power = 5,\n"
    content += '\t\t\toffset = "0 5",\n'
    content += '\t\t\tcolor = "rgba(00000070)",\n'
    content += "\t\t},\n"
    content += "\t\tblur = {\n"
    content += f"\t\t\tenabled = {blur_enabled},\n"
    content += f"\t\t\tsize = {blur_size},\n"
    content += f"\t\t\tpasses = {blur_passes},\n"
    content += "\t\t\tnew_optimizations = true,\n"
    content += "\t\t\txray = false,\n"
    content += "\t\t\tignore_opacity = true,\n"
    content += "\t\t},\n"
    content += "\t},\n"
    content += "\tanimations = {\n"
    content += f"\t\tenabled = {anim_enabled},\n"
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
    content += anim_lua_block

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
        f'hl.config({{ '
        f'general = {{ '
        f'gaps_in = {gaps_in}, '
        f'gaps_out = {gaps_out}, '
        f'border_size = {border_size}, '
        f'resize_on_border = {resize_on_border} '
        f'}}, '
        f'decoration = {{ '
        f'rounding = {rounding}, '
        f'active_opacity = {active_opacity:.2f}, '
        f'inactive_opacity = {inactive_opacity:.2f}, '
        f'shadow = {{ '
        f'enabled = {shadow_enabled}, '
        f'range = {shadow_range} '
        f'}}, '
        f'blur = {{ '
        f'enabled = {blur_enabled}, '
        f'size = {blur_size}, '
        f'passes = {blur_passes} '
        f'}} '
        f'}}, '
        f'animations = {{ '
        f'enabled = {anim_enabled} '
        f'}} '
        f'}}) '
        f'{anim_eval_block}'
        f'return "ok"'
    )
    send_hypr(f"eval {lua_eval}\n")
    send_hypr('eval package.loaded["minimo.apariencia"] = nil\n')

if __name__ == "__main__":
    main()
