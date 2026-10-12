#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
# Instalador de Minimo OS (Hyprland + minimo-shell) para Arch Linux.
# Uso:  ./install.sh [--dry-run] [--yes]
#   o:  curl -fsSL https://raw.githubusercontent.com/Diegolede/minimo-os/main/install.sh | bash
#       (con opciones: ... | bash -s -- --dry-run)
# Si no se ejecuta desde una copia del repo, lo clona en ~/Proyectos/minimo-os y se
# vuelve a ejecutar desde ahí. Las preguntas se leen de /dev/tty (funciona con tubería).
# Es idempotente: se puede volver a correr sin romper nada.
set -euo pipefail

REPO_SLUG="Diegolede/minimo-os"
REPO_URL="https://github.com/$REPO_SLUG.git"
DEST="$HOME/Proyectos/minimo-os"
TS=$(date +%Y%m%d-%H%M%S)

DRY=0; YES=0
for a in "$@"; do
    case "$a" in
        --dry-run|-n) DRY=1 ;;
        --yes|-y) YES=1 ;;
        -h|--help) sed -n '2,5p' "$0" 2>/dev/null || true; exit 0 ;;
        *) echo "Opción desconocida: $a" >&2; exit 2 ;;
    esac
done

# --- salida ---
if [ -t 1 ]; then B=$'\e[1m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; C=$'\e[36m'; D=$'\e[2m'; N=$'\e[0m'
else B=; G=; Y=; R=; C=; D=; N=; fi
step() { printf '\n%s==>%s %s%s%s\n' "$C" "$N" "$B" "$*" "$N"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
die()  { printf '%s✗ %s%s\n' "$R" "$*" "$N" >&2; exit 1; }
# run: ejecuta (o solo muestra en --dry-run)
run() {
    if [ "$DRY" = 1 ]; then printf '  %s[dry-run]%s %s\n' "$D" "$N" "$*"
    else printf '  %s$ %s%s\n' "$D" "$*" "$N"; "$@"; fi
}
confirm() {
    [ "$YES" = 1 ] && return 0
    [ "$DRY" = 1 ] && return 0
    local r; read -r -p "  $1 [S/n] " r </dev/tty || r=s
    case "${r,,}" in n|no) return 1 ;; *) return 0 ;; esac
}

# --- comprobaciones ---
step "Comprobaciones"
command -v pacman >/dev/null || die "Esto no parece Arch Linux (falta pacman)."
[ "$(id -u)" -ne 0 ] || die "No lo ejecutes como root; usa tu usuario (se pedirá sudo)."
command -v sudo >/dev/null || die "Falta sudo."
ok "Arch Linux, usuario $USER"
[ "$DRY" = 1 ] && warn "Modo --dry-run: no se cambia nada."

# --- repo: si no se ejecuta desde dentro del repo, clonarlo ---
SELF_DIR=""
if [ -f "${BASH_SOURCE[0]:-}" ]; then SELF_DIR=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd); fi
if [ -n "$SELF_DIR" ] && [ -d "$SELF_DIR/minimo-shell" ] && [ -d "$SELF_DIR/hypr" ]; then
    REPO="$SELF_DIR"
else
    REPO="$DEST"
    step "Repositorio"
    if [ -d "$REPO/.git" ]; then
        ok "Ya existe $REPO (git pull)"
        run git -C "$REPO" pull --ff-only || warn "No se pudo actualizar; sigo con lo que hay."
    else
        command -v git >/dev/null || run sudo pacman -S --needed --noconfirm git
        run mkdir -p "$(dirname "$REPO")"
        if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
            run gh repo clone "$REPO_SLUG" "$REPO"
        else
            run git clone "$REPO_URL" "$REPO"
        fi
    fi
    # Continuar con el instalador del repo clonado (la copia por tubería puede ser vieja).
    if [ -f "$REPO/install.sh" ] && [ -z "${MINIMO_REEXEC:-}" ]; then
        ok "Continuando desde $REPO/install.sh"
        MINIMO_REEXEC=1 exec bash "$REPO/install.sh" "$@"
    fi
    if [ ! -d "$REPO/minimo-shell" ]; then
        [ "$DRY" = 1 ] && { warn "En --dry-run no se clona: el resto se mostraría después de clonar."; exit 0; }
        die "No se pudo obtener el repositorio en $REPO (si es privado: gh auth login)."
    fi
fi
ok "Repo: $REPO"

# --- paquetes (todos en los repos oficiales: extra) ---
PKGS=(
    hyprland xdg-desktop-portal-hyprland hyprpolkitagent       # compositor, portal, polkit
    quickshell qt6-declarative qt6-svg qt6-wayland             # shell (QtQuick, Effects, iconos SVG)
    pipewire pipewire-pulse wireplumber                        # audio (Pipewire en la shell)
    cava                                                       # niveles de audio (baile del personaje)
    ghostty grim slurp wf-recorder zenity                      # terminal, capturas, grabación, selector de fondo
    adwaita-fonts                                              # tipografía Adwaita Sans
    networkmanager                                             # Wi-Fi en la isla (nmcli)
    git
)
OPTIONAL=(fuzzel playerctl wl-clipboard github-cli)
step "Paquetes"
missing=()
for p in "${PKGS[@]}"; do pacman -Q "$p" >/dev/null 2>&1 || missing+=("$p"); done
if [ ${#missing[@]} -eq 0 ]; then ok "Todo instalado"
else
    warn "Faltan: ${missing[*]}"
    if confirm "¿Instalar con pacman?"; then run sudo pacman -S --needed --noconfirm "${PKGS[@]}"; else die "Cancelado."; fi
fi
# Marcar como instalados explícitamente: así `pacman -Rns` de otro paquete (p. ej. otra shell)
# nunca los borra como dependencias huérfanas.
deps=()
for p in "${PKGS[@]}"; do pacman -Qqd "$p" >/dev/null 2>&1 && deps+=("$p"); done
if [ ${#deps[@]} -gt 0 ]; then run sudo pacman -D --asexplicit "${deps[@]}"; fi
optmissing=()
for p in "${OPTIONAL[@]}"; do pacman -Q "$p" >/dev/null 2>&1 || optmissing+=("$p"); done
if [ ${#optmissing[@]} -gt 0 ]; then
    if confirm "¿Instalar opcionales (${optmissing[*]})?"; then run sudo pacman -S --needed --noconfirm "${optmissing[@]}"; fi
else ok "Opcionales instalados"; fi

# --- enlaces ---
# link SRC DST: symlink idempotente; respalda un archivo real existente.
link() {
    local src=$1 dst=$2
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then ok "$dst"; return; fi
    run mkdir -p "$(dirname "$dst")"
    run ln -sfn "$src" "$dst"
}

step "Configuración de Hyprland"
HYPR="$HOME/.config/hypr"
needs_backup=0
if [ -e "$HYPR" ]; then
    # solo respaldar si hay algo que no sea ya un enlace a este repo
    while IFS= read -r -d '' f; do
        case "$f" in */monitores.lua) continue ;; esac
        [ -L "$f" ] && [[ "$(readlink -f "$f")" == "$REPO"/* ]] && continue
        needs_backup=1; break
    done < <(find "$HYPR" \( -type f -o -type l \) -name '*.lua' -print0)
fi
if [ "$needs_backup" = 1 ]; then
    run cp -a "$HYPR" "$HYPR.bak-$TS"
    ok "Respaldo: $HYPR.bak-$TS"
fi
link "$REPO/hypr/hyprland.lua" "$HYPR/hyprland.lua"
link "$REPO/hypr/minimo.lua"   "$HYPR/minimo.lua"
for f in "$REPO"/hypr/minimo/*.lua; do
    n=$(basename "$f")
    [ "$n" = monitores.lua ] && continue
    link "$f" "$HYPR/minimo/$n"
done
# Monitores: específico de cada PC → copia (auto) solo si no existe.
MON="$HYPR/minimo/monitores.lua"
if [ -f "$MON" ] && [ ! -L "$MON" ]; then ok "$MON (se conserva el de esta PC)"
else
    [ -L "$MON" ] && run rm -f "$MON"
    run install -Dm644 "$REPO/hypr/minimo/monitores.lua" "$MON"
fi

step "Fondos de pantalla"
WALL="$HOME/Imágenes/Fondos"
run mkdir -p "$WALL"
for f in "$REPO"/assets/wallpapers/*; do
    [ -e "$WALL/$(basename "$f")" ] && { ok "$WALL/$(basename "$f")"; continue; }
    run cp "$f" "$WALL/"
done

step "Servicio de la shell (systemd --user)"
UNITS="$HOME/.config/systemd/user"
link "$REPO/systemd/minimo-shell.service" "$UNITS/minimo-shell.service"
link "$REPO/systemd/hyprland-session.target" "$UNITS/hyprland-session.target"
if [ "$REPO" != "$DEST" ]; then
    warn "El repo no está en $DEST: la unidad y el atajo Super+B asumen esa ruta."
fi
run systemctl --user daemon-reload
run systemctl --user enable minimo-shell.service
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    run systemctl --user restart minimo-shell.service
    run hyprctl reload
else
    ok "Se iniciará al entrar en Hyprland"
fi

printf '\n%s%sMinimo OS instalado.%s Cerrá sesión y entrá en Hyprland. Desinstalar: %s/uninstall.sh\n' "$G" "$B" "$N" "$REPO"
