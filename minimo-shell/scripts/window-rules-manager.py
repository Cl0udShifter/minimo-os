#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
"""
Gerenciador de Regras de Janelas do Minimo OS.
Gera o arquivo Lua com regras por aplicativo (mosaico vs flutuante, workspaces por monitor)
e aplica dinamicamente ao Hyprland.
"""

import sys
import os
import json
import subprocess
from pathlib import Path

HOME = Path.home()
CONFIG_DIR = HOME / ".config" / "minimo-os"
RULES_JSON = CONFIG_DIR / "window-rules.json"

TARGET_LUA_PATHS = [
    HOME / ".config" / "hypr" / "minimo" / "regras_usuario.lua",
    HOME / "Projetos" / "minimo-os" / "hypr" / "minimo" / "regras_usuario.lua"
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

def load_rules():
    """Carrega as regras salvas do JSON."""
    if not RULES_JSON.is_file():
        return {}
    try:
        with open(RULES_JSON, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data.get("rules", {})
    except Exception:
        return {}

def save_rules(rules):
    """Salva as regras no JSON."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    with open(RULES_JSON, "w", encoding="utf-8") as f:
        json.dump({"rules": rules}, f, indent=2, ensure_ascii=False)

def build_lua_content(rules):
    """Gera o código Lua para as regras de janelas do Hyprland."""
    lines = [
        "-- SPDX-License-Identifier: MIT",
        "-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS",
        "-- Regras de janelas personalizadas geradas pelas Configurações do Minimo OS.",
        "",
    ]

    count = 0
    for app_id, r in rules.items():
        mode = r.get("mode", "default")
        ws = r.get("workspace", 0)
        app_class = r.get("class", "")
        name = r.get("name", app_id)

        if not app_class:
            continue

        if mode == "default" and ws == 0:
            continue

        lines.append(f"-- {name} ({app_id})")

        rule_kwargs = [f'match = {{ class = [=[{app_class}]=] }}']

        if mode == "tile":
            rule_kwargs.append("tile = true")
        elif mode == "float":
            rule_kwargs.append("float = true")

        if ws > 0:
            rule_kwargs.append(f'workspace = "{ws}"')

        lines.append(f'hl.window_rule({{ {", ".join(rule_kwargs)} }})')
        count += 1

    if count == 0:
        lines.append("-- Nenhuma regra personalizada configurada.")

    lines.append("")
    return "\n".join(lines)

def apply():
    """Compila o arquivo JSON para Lua e recarrega o Hyprland."""
    rules = load_rules()
    content = build_lua_content(rules)

    for target in TARGET_LUA_PATHS:
        try:
            target.parent.mkdir(parents=True, exist_ok=True)
            with open(target, "w", encoding="utf-8") as f:
                f.write(content)
        except Exception as e:
            print(f"Aviso ao salvar {target}: {e}", file=sys.stderr)

    reload_hyprland()
    print(json.dumps({"status": "ok", "rulesCount": len(rules)}))

def set_rule(app_id, name, app_class, mode="default", workspace=0):
    """Define ou atualiza a regra de um aplicativo."""
    rules = load_rules()
    
    if mode == "default" and int(workspace) == 0:
        if app_id in rules:
            del rules[app_id]
    else:
        rules[app_id] = {
            "id": app_id,
            "name": name,
            "class": app_class,
            "mode": mode,
            "workspace": int(workspace)
        }

    save_rules(rules)
    apply()

def main():
    if len(sys.argv) < 2 or sys.argv[1] == "apply":
        apply()
    elif sys.argv[1] == "get":
        print(json.dumps(load_rules(), indent=2))
    elif sys.argv[1] == "set":
        # set <id> <name> <class> [mode] [workspace]
        app_id = sys.argv[2]
        name = sys.argv[3] if len(sys.argv) > 3 else app_id
        app_class = sys.argv[4] if len(sys.argv) > 4 else f"^({app_id})$"
        mode = sys.argv[5] if len(sys.argv) > 5 else "default"
        ws = int(sys.argv[6]) if len(sys.argv) > 6 else 0
        set_rule(app_id, name, app_class, mode, ws)
    elif sys.argv[1] == "delete":
        app_id = sys.argv[2]
        rules = load_rules()
        if app_id in rules:
            del rules[app_id]
            save_rules(rules)
            apply()
        else:
            print(json.dumps({"status": "not_found"}))
    else:
        print(f"Comando desconhecido: {sys.argv[1]}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
