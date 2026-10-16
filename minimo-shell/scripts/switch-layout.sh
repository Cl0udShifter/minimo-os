#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
# Alternância instantânea de layout de teclado para Minimo OS / Hyprland

STATE_FILE="$HOME/.config/minimo-os/input.json"
CURRENT=$(grep -o '"kbLayout": "[^"]*"' "$STATE_FILE" 2>/dev/null | cut -d'"' -f4)

if [ "$CURRENT" = "br" ]; then
    TARGET_IDX=1
else
    TARGET_IDX=0
fi

if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    SIG=$(ls -1t /run/user/$(id -u)/hypr 2>/dev/null | head -n1)
    export HYPRLAND_INSTANCE_SIGNATURE="$SIG"
fi

hyprctl switchxkblayout all $TARGET_IDX >/dev/null 2>&1
