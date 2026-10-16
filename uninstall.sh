#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
# Desinstala o Minimo OS: desativa a shell e restaura o último backup de ~/.config/hypr.
# Uso: ./uninstall.sh [--dry-run] [--yes]   (não remove pacotes instalados)
set -euo pipefail
DRY=0; YES=0
for a in "$@"; do case "$a" in --dry-run|-n) DRY=1 ;; --yes|-y) YES=1 ;; *) echo "Opção desconhecida: $a" >&2; exit 2 ;; esac; done
if [ -t 1 ]; then G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; D=$'\e[2m'; N=$'\e[0m'; else G=; Y=; C=; D=; N=; fi
run() { if [ "$DRY" = 1 ]; then printf '  %s[dry-run]%s %s\n' "$D" "$N" "$*"; else printf '  %s$ %s%s\n' "$D" "$*" "$N"; "$@"; fi; }
[ "$(id -u)" -ne 0 ] || { echo "Não execute como root." >&2; exit 1; }

printf '%s==>%s Serviço\n' "$C" "$N"
run systemctl --user disable --now minimo-shell.service || true
run systemctl --user disable --now minimo-polkit.service || true
for u in minimo-shell.service minimo-polkit.service hyprland-session.target; do
    [ -L "$HOME/.config/systemd/user/$u" ] && run rm -f "$HOME/.config/systemd/user/$u"
done
run systemctl --user daemon-reload

printf '%s==>%s Terminal\n' "$C" "$N"
[ -L "$HOME/.local/bin/minimo-hello" ] && run rm -f "$HOME/.local/bin/minimo-hello"
[ -L "$HOME/.config/ghostty/config" ] && run rm -f "$HOME/.config/ghostty/config"
printf '  %s!%s A linha do minimo-hello em ~/.bashrc agora é inofensiva (apenas verifica se o arquivo existe).\n' "$Y" "$N"

printf '%s==>%s Hyprland\n' "$C" "$N"
HYPR="$HOME/.config/hypr"
last=$(ls -d "$HYPR".bak-* 2>/dev/null | sort | tail -1 || true)
if [ -z "$last" ]; then
    printf '  %s!%s Nenhum backup encontrado de %s; mantendo como está.\n' "$Y" "$N" "$HYPR"
else
    if [ "$YES" = 0 ] && [ "$DRY" = 0 ]; then
        read -r -p "  Deseja restaurar $last? [S/n] " r </dev/tty || r=s
        case "${r,,}" in n|no|nao|não) exit 0 ;; esac
    fi
    run rm -rf "$HYPR"
    run cp -a "$last" "$HYPR"
    printf '  %s✓%s Restaurado %s com sucesso\n' "$G" "$N" "$last"
fi
printf '%sConcluído.%s Reinicie sua sessão. (Pacotes e papéis de parede não foram modificados.)\n' "$G" "$N"
