#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
"""
Gerenciador de Aplicativos de Inicialização (Autostart) do Minimo OS.
Persiste a lista de aplicativos em ~/.config/minimo-os/autostart.json,
compila para hypr/minimo/autostart.lua e aplica dinamicamente.
"""

import sys
import os
import json
import subprocess
from pathlib import Path

HOME = Path.home()
CONFIG_DIR = HOME / ".config" / "minimo-os"
AUTOSTART_JSON = CONFIG_DIR / "autostart.json"

TARGET_LUA_PATHS = [
    HOME / ".config" / "hypr" / "minimo" / "autostart.lua",
    HOME / "Projetos" / "minimo-os" / "hypr" / "minimo" / "autostart.lua"
]

def get_hypr_env():
    """Obtém as variáveis de ambiente necessárias para o Hyprland."""
    env = os.environ.copy()
    if "XDG_RUNTIME_DIR" not in env:
        uid = os.getuid()
        env["XDG_RUNTIME_DIR"] = f"/run/user/{uid}"
    
    if "HYPRLAND_INSTANCE_SIGNATURE" not in env:
        runtime_dir = Path(env["XDG_RUNTIME_DIR"]) / "hypr"
        if runtime_dir.is_dir():
            instances = [p.name for p in runtime_dir.iterdir() if p.is_dir()]
            if instances:
                env["HYPRLAND_INSTANCE_SIGNATURE"] = instances[0]
    return env

def reload_hyprland():
    """Recarrega a configuração do Hyprland."""
    env = get_hypr_env()
    try:
        subprocess.run(["hyprctl", "reload"], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2.0)
    except Exception:
        pass

def load_autostart():
    """Carrega os aplicativos salvos do JSON."""
    if not AUTOSTART_JSON.is_file():
        return []
    try:
        with open(AUTOSTART_JSON, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data.get("apps", [])
    except Exception:
        return []

def save_autostart(apps):
    """Salva os aplicativos no JSON."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    with open(AUTOSTART_JSON, "w", encoding="utf-8") as f:
        json.dump({"apps": apps}, f, indent=2, ensure_ascii=False)

def build_lua_content(apps):
    """Gera o código Lua para execução na inicialização do Hyprland."""
    lines = [
        "-- SPDX-License-Identifier: MIT",
        "-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS",
        "-- Aplicativos de inicialização automática gerados pelas Configurações do Minimo OS.",
        "",
        'hl.on("hyprland.start", function()',
    ]

    count = 0
    for app in apps:
        if not app.get("enabled", True):
            continue
        exec_cmd = app.get("exec", "").strip()
        if not exec_cmd:
            continue
        ws = int(app.get("workspace", 0))
        name = app.get("name", app.get("id", "app"))

        lines.append(f"    -- {name}")
        if ws > 0:
            lines.append(f"    hl.exec_cmd([=[[workspace {ws} silent] {exec_cmd}]=])")
        else:
            lines.append(f"    hl.exec_cmd([=[{exec_cmd}]=])")
        count += 1

    if count == 0:
        lines.append("    -- Nenhum aplicativo configurado para iniciar automaticamente.")

    lines.append("end)")
    lines.append("")
    return "\n".join(lines)

def apply():
    """Compila o arquivo JSON para Lua e recarrega o Hyprland."""
    apps = load_autostart()
    content = build_lua_content(apps)

    for target in TARGET_LUA_PATHS:
        try:
            target.parent.mkdir(parents=True, exist_ok=True)
            with open(target, "w", encoding="utf-8") as f:
                f.write(content)
        except Exception as e:
            print(f"Aviso ao salvar {target}: {e}", file=sys.stderr)

    reload_hyprland()
    print(json.dumps({"status": "ok", "appsCount": len(apps)}))

def add_app(app_id, name, exec_cmd, icon, workspace=0):
    """Adiciona ou atualiza um aplicativo na inicialização."""
    apps = load_autostart()
    # Remove duplicata se já existir
    apps = [a for a in apps if a.get("id") != app_id]

    apps.append({
        "id": app_id,
        "name": name,
        "exec": exec_cmd,
        "icon": icon,
        "workspace": int(workspace),
        "enabled": True
    })

    save_autostart(apps)
    apply()

def remove_app(app_id):
    """Remove um aplicativo da inicialização."""
    apps = load_autostart()
    apps = [a for a in apps if a.get("id") != app_id]
    save_autostart(apps)
    apply()

def toggle_app(app_id, enabled=None):
    """Ativa ou desativa um aplicativo na inicialização."""
    apps = load_autostart()
    for a in apps:
        if a.get("id") == app_id:
            if enabled is None:
                a["enabled"] = not a.get("enabled", True)
            else:
                a["enabled"] = bool(enabled)
            break
    save_autostart(apps)
    apply()

def set_workspace(app_id, workspace):
    """Atualiza a área de trabalho associada ao aplicativo."""
    apps = load_autostart()
    for a in apps:
        if a.get("id") == app_id:
            a["workspace"] = int(workspace)
            break
    save_autostart(apps)
    apply()

def launch_app(app_id):
    """Dispara a execução imediata de um aplicativo."""
    apps = load_autostart()
    app = next((a for a in apps if a.get("id") == app_id), None)
    if not app:
        return
    exec_cmd = app.get("exec", "").strip()
    if not exec_cmd:
        return
    env = get_hypr_env()
    try:
        subprocess.Popen(exec_cmd, shell=True, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(json.dumps({"status": "launched", "id": app_id}))
    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}))

def main():
    if len(sys.argv) < 2 or sys.argv[1] == "apply":
        apply()
    elif sys.argv[1] == "get":
        print(json.dumps(load_autostart(), indent=2))
    elif sys.argv[1] == "add":
        # add <id> <name> <exec> <icon> [workspace]
        app_id = sys.argv[2]
        name = sys.argv[3] if len(sys.argv) > 3 else app_id
        exec_cmd = sys.argv[4] if len(sys.argv) > 4 else ""
        icon = sys.argv[5] if len(sys.argv) > 5 else ""
        workspace = int(sys.argv[6]) if len(sys.argv) > 6 else 0
        add_app(app_id, name, exec_cmd, icon, workspace)
    elif sys.argv[1] == "remove":
        # remove <id>
        if len(sys.argv) > 2:
            remove_app(sys.argv[2])
    elif sys.argv[1] == "toggle":
        # toggle <id> [true|false]
        app_id = sys.argv[2]
        enabled = None
        if len(sys.argv) > 3:
            enabled = sys.argv[3].lower() in ("true", "1", "yes")
        toggle_app(app_id, enabled)
    elif sys.argv[1] == "set-workspace":
        # set-workspace <id> <workspace>
        app_id = sys.argv[2]
        ws = int(sys.argv[3]) if len(sys.argv) > 3 else 0
        set_workspace(app_id, ws)
    elif sys.argv[1] == "launch":
        # launch <id>
        if len(sys.argv) > 2:
            launch_app(sys.argv[2])
    else:
        print(f"Comando desconhecido: {sys.argv[1]}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
