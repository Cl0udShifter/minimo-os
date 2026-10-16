#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
# Alternância instantânea de layout de teclado para Minimo OS / Hyprland

# 1. Garante a assinatura do Hyprland caso não esteja exportada no ambiente
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    for d in /run/user/$(id -u)/hypr/*/; do
        if [ -S "${d}.socket.sock" ]; then
            export HYPRLAND_INSTANCE_SIGNATURE="$(basename "$d")"
            break
        fi
    done
fi

# 2. Alterna instantaneamente para o próximo layout em todas as entradas de teclado
hyprctl switchxkblayout all next >/dev/null 2>&1
