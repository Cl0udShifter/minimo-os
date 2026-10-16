#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
"""
Gerenciador de Temas de Cursor e Ícones do Minimo OS.
Permite listar, detectar e aplicar temas de cursor e ícones no GNOME, Hyprland e aplicações legadas.
"""

import sys
import os
import json
import configparser
import subprocess
from pathlib import Path

HOME = Path.home()
STATE_DIR = HOME / ".config" / "minimo-os"
THEME_JSON = STATE_DIR / "theme.json"
CURSOR_LUA = HOME / ".config" / "hypr" / "minimo" / "cursor.lua"
DEFAULT_ICONS_THEME = HOME / ".icons" / "default" / "index.theme"

SEARCH_DIRS = [
    Path("/usr/share/icons"),
    HOME / ".local" / "share" / "icons",
    HOME / ".icons",
]

def run_cmd(cmd, check=False):
    """Executa um comando de terminal silenciosamente."""
    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=check)
        return res.stdout.strip()
    except Exception:
        return ""

def get_hypr_env():
    """Garante que as variáveis de ambiente do Hyprland estejam presentes."""
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

def get_current_settings():
    """Obtém configurações atuais via gsettings e fallback para theme.json."""
    cursor_theme = run_cmd(["gsettings", "get", "org.gnome.desktop.interface", "cursor-theme"]).strip("'\"")
    cursor_size_str = run_cmd(["gsettings", "get", "org.gnome.desktop.interface", "cursor-size"])
    icon_theme = run_cmd(["gsettings", "get", "org.gnome.desktop.interface", "icon-theme"]).strip("'\"")

    try:
        cursor_size = int(cursor_size_str)
    except ValueError:
        cursor_size = 24

    if not cursor_theme or cursor_theme == "default":
        cursor_theme = "Adwaita"
    if not icon_theme:
        icon_theme = "Adwaita"

    # Ler theme.json se existir para sincronização
    if THEME_JSON.is_file():
        try:
            with open(THEME_JSON, "r", encoding="utf-8") as f:
                saved = json.load(f)
                if not cursor_theme or cursor_theme == "default":
                    cursor_theme = saved.get("cursorTheme", cursor_theme)
                if not cursor_size:
                    cursor_size = saved.get("cursorSize", cursor_size)
                if not icon_theme:
                    icon_theme = saved.get("iconTheme", icon_theme)
        except Exception:
            pass

    return {
        "cursorTheme": cursor_theme,
        "cursorSize": cursor_size,
        "iconTheme": icon_theme
    }

def scan_themes():
    """Varre os diretórios de ícones e temas de cursor."""
    cursors = {}
    icons = {}

    for base in SEARCH_DIRS:
        if not base.is_dir():
            continue
        try:
            entries = sorted(list(base.iterdir()))
        except Exception:
            continue

        for entry in entries:
            if not entry.is_dir():
                continue
            dir_name = entry.name
            index_path = entry / "index.theme"
            cursors_dir = entry / "cursors"

            name = dir_name
            comment = ""
            inherits = ""
            has_directories = False

            if index_path.is_file():
                cp = configparser.ConfigParser(interpolation=None)
                try:
                    cp.read(index_path, encoding="utf-8")
                    if "Icon Theme" in cp:
                        sec = cp["Icon Theme"]
                        name = sec.get("Name", dir_name)
                        comment = sec.get("Comment", "")
                        inherits = sec.get("Inherits", "")
                        has_directories = "Directories" in sec
                except Exception:
                    pass

            is_cursor = cursors_dir.is_dir()
            if is_cursor and dir_name not in cursors:
                cursors[dir_name] = {
                    "id": dir_name,
                    "name": name,
                    "comment": comment
                }

            # Tema de ícones: precisa ter index.theme com Directories ou ícones reais, e não ser apenas cursor/default
            if (has_directories or (index_path.is_file() and not is_cursor)) and dir_name not in ["default"]:
                if dir_name not in icons:
                    icons[dir_name] = {
                        "id": dir_name,
                        "name": name,
                        "comment": comment
                    }

    # Se Adwaita estiver presente, garantir nomes amigáveis
    if "Adwaita" in cursors and cursors["Adwaita"]["name"] == "Adwaita":
        cursors["Adwaita"]["name"] = "Adwaita (Padrão GNOME)"

    current = get_current_settings()

    return {
        "cursorThemes": list(cursors.values()),
        "iconThemes": list(icons.values()),
        "currentCursor": current["cursorTheme"],
        "currentCursorSize": current["cursorSize"],
        "currentIcon": current["iconTheme"]
    }

def save_state(cursor_theme, cursor_size, icon_theme):
    """Salva o estado em ~/.config/minimo-os/theme.json."""
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    data = {
        "cursorTheme": cursor_theme,
        "cursorSize": cursor_size,
        "iconTheme": icon_theme
    }
    with open(THEME_JSON, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

def set_cursor(theme_id, size=None):
    """Aplica o tema e tamanho do cursor no GNOME, Hyprland e X11."""
    current = get_current_settings()
    theme = theme_id or current["cursorTheme"]
    size = int(size) if size else current["cursorSize"]

    # 1. GNOME / GTK via gsettings
    run_cmd(["gsettings", "set", "org.gnome.desktop.interface", "cursor-theme", theme])
    run_cmd(["gsettings", "set", "org.gnome.desktop.interface", "cursor-size", str(size)])

    # 2. Hyprland em tempo real
    env = get_hypr_env()
    subprocess.run(["hyprctl", "setcursor", theme, str(size)], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # 3. Legado X11 (~/.icons/default/index.theme)
    try:
        DEFAULT_ICONS_THEME.parent.mkdir(parents=True, exist_ok=True)
        with open(DEFAULT_ICONS_THEME, "w", encoding="utf-8") as f:
            f.write(f"[Icon Theme]\nName=Default\nComment=Default Cursor Theme\nInherits={theme}\n")
    except Exception:
        pass

    # 4. Gravar arquivo Lua para carregamento automático no Hyprland
    try:
        CURSOR_LUA.parent.mkdir(parents=True, exist_ok=True)
        with open(CURSOR_LUA, "w", encoding="utf-8") as f:
            f.write(f"""-- SPDX-License-Identifier: MIT
-- Configuração de cursor do Minimo OS gerada automaticamente
hl.env({{
	XCURSOR_THEME = "{theme}",
	XCURSOR_SIZE = "{size}",
	HYPRCURSOR_THEME = "{theme}",
	HYPRCURSOR_SIZE = "{size}",
}})
""")
    except Exception:
        pass

    save_state(theme, size, current["iconTheme"])
    print(json.dumps({"status": "ok", "cursorTheme": theme, "cursorSize": size}))

def set_icon(theme_id):
    """Aplica o tema de ícones no GNOME / GTK."""
    current = get_current_settings()
    theme = theme_id or current["iconTheme"]

    run_cmd(["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", theme])

    save_state(current["cursorTheme"], current["cursorSize"], theme)
    print(json.dumps({"status": "ok", "iconTheme": theme}))

def apply_saved():
    """Reaplica todas as configurações salvas."""
    current = get_current_settings()
    set_cursor(current["cursorTheme"], current["cursorSize"])
    set_icon(current["iconTheme"])

def main():
    if len(sys.argv) < 2 or sys.argv[1] == "list":
        print(json.dumps(scan_themes(), indent=2))
        return

    cmd = sys.argv[1]
    if cmd == "set-cursor":
        theme = sys.argv[2] if len(sys.argv) > 2 else ""
        size = sys.argv[3] if len(sys.argv) > 3 else None
        set_cursor(theme, size)
    elif cmd == "set-icon":
        theme = sys.argv[2] if len(sys.argv) > 2 else ""
        set_icon(theme)
    elif cmd == "apply-saved":
        apply_saved()
    elif cmd == "get":
        print(json.dumps(get_current_settings(), indent=2))
    else:
        print(f"Comando desconhecido: {cmd}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
