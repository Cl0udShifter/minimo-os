#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
# Uso: apply-color.sh SATURACION BRILLO  (1.0 = normal)
# Genera ~/.config/minimo-os/color.frag desde la plantilla y lo aplica en Hyprland.
set -eu
sat=$(LC_ALL=C printf '%.3f' "${1:-1}")
bri=$(LC_ALL=C printf '%.3f' "${2:-1}")
here=$(dirname "$(realpath "$0")")
out="$HOME/.config/minimo-os/color.frag"
mkdir -p "$(dirname "$out")"
if [ "$sat" = "1.000" ] && [ "$bri" = "1.000" ]; then
    hyprctl eval 'hl.config({decoration={screen_shader=""}})' >/dev/null
    exit 0
fi
sed -e "s/@SAT@/$sat/" -e "s/@BRI@/$bri/" "$here/../shaders/color.frag.in" > "$out.tmp"
mv "$out.tmp" "$out"
# Vaciar primero fuerza a Hyprland a recompilar el archivo.
hyprctl eval 'hl.config({decoration={screen_shader=""}})' >/dev/null
hyprctl eval "hl.config({decoration={screen_shader=\"$out\"}})" >/dev/null
