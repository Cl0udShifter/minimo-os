#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
"""
Gerenciador de filtro de notificações por aplicativo no Minimo OS.
Persiste as preferências do usuário em ~/.config/minimo-os/notifications.json.
"""

import sys
import os
import json
import re
from pathlib import Path

HOME = Path(os.environ.get("HOME", "/home/daniel"))
CONFIG_DIR = HOME / ".config" / "minimo-os"
CONFIG_FILE = CONFIG_DIR / "notifications.json"

def load_config():
    """Carrega a configuração de notificações do JSON."""
    if not CONFIG_FILE.is_file():
        return {
            "dnd": False,
            "mutedApps": [],
            "knownApps": {}
        }
    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            return {
                "dnd": bool(data.get("dnd", False)),
                "mutedApps": list(data.get("mutedApps", [])),
                "knownApps": dict(data.get("knownApps", {}))
            }
    except Exception as e:
        print(f"Erro ao ler {CONFIG_FILE}: {e}", file=sys.stderr)
        return {
            "dnd": False,
            "mutedApps": [],
            "knownApps": {}
        }

def save_config(cfg):
    """Salva a configuração no JSON."""
    try:
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(cfg, f, indent=2, ensure_ascii=False)
        return True
    except Exception as e:
        print(f"Erro ao salvar {CONFIG_FILE}: {e}", file=sys.stderr)
        return False

def normalize_id(app_id):
    """Normaliza o ID do aplicativo (remover .desktop e minúsculas)."""
    if not app_id:
        return ""
    clean = app_id.replace(".desktop", "").strip().lower()
    return clean

def get_config():
    cfg = load_config()
    print(json.dumps(cfg, ensure_ascii=False))

def set_muted(app_id, muted_str, name="", icon=""):
    cfg = load_config()
    clean_id = normalize_id(app_id)
    if not clean_id:
        print(json.dumps({"status": "error", "message": "ID inválido"}))
        return

    is_muted = muted_str.lower() in ("true", "1", "yes", "sim")
    current_muted = set(cfg.get("mutedApps", []))

    if is_muted:
        current_muted.add(clean_id)
    else:
        current_muted.discard(clean_id)

    cfg["mutedApps"] = sorted(list(current_muted))

    # Registrar em knownApps se fornecido
    if name or icon:
        if "knownApps" not in cfg:
            cfg["knownApps"] = {}
        cfg["knownApps"][clean_id] = {
            "name": name or clean_id,
            "icon": icon or clean_id
        }

    save_config(cfg)
    print(json.dumps({"status": "ok", "appId": clean_id, "muted": is_muted, "mutedApps": cfg["mutedApps"]}))

def set_dnd(dnd_str):
    cfg = load_config()
    is_dnd = dnd_str.lower() in ("true", "1", "yes", "sim")
    cfg["dnd"] = is_dnd
    save_config(cfg)
    print(json.dumps({"status": "ok", "dnd": is_dnd}))

def record_app(app_id, name="", icon=""):
    cfg = load_config()
    clean_id = normalize_id(app_id)
    if not clean_id:
        return
    if "knownApps" not in cfg:
        cfg["knownApps"] = {}

    existing = cfg["knownApps"].get(clean_id, {})
    cfg["knownApps"][clean_id] = {
        "name": name or existing.get("name") or clean_id,
        "icon": icon or existing.get("icon") or clean_id
    }
    save_config(cfg)
    print(json.dumps({"status": "ok", "knownApps": cfg["knownApps"]}))

def main():
    if len(sys.argv) < 2:
        get_config()
        return

    cmd = sys.argv[1].lower()

    if cmd == "get":
        get_config()
    elif cmd == "set-muted" and len(sys.argv) >= 4:
        app_id = sys.argv[2]
        muted = sys.argv[3]
        name = sys.argv[4] if len(sys.argv) > 4 else ""
        icon = sys.argv[5] if len(sys.argv) > 5 else ""
        set_muted(app_id, muted, name, icon)
    elif cmd == "set-dnd" and len(sys.argv) >= 3:
        set_dnd(sys.argv[2])
    elif cmd == "record-app" and len(sys.argv) >= 3:
        app_id = sys.argv[2]
        name = sys.argv[3] if len(sys.argv) > 3 else ""
        icon = sys.argv[4] if len(sys.argv) > 4 else ""
        record_app(app_id, name, icon)
    elif cmd == "list-muted":
        cfg = load_config()
        print(json.dumps(cfg.get("mutedApps", [])))
    else:
        print(f"Uso: {sys.argv[0]} [get | set-muted <app_id> <true|false> [name] [icon] | set-dnd <true|false> | record-app <app_id> [name] [icon]]", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
