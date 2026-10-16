#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
# Agente de autenticação Polkit do Minimo OS

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Se o binário nativo não existir ou o fonte for mais recente, compila
if [ ! -x "$DIR/minimo-polkit-agent" ] || [ "$DIR/minimo-polkit-agent.c" -nt "$DIR/minimo-polkit-agent" ]; then
    if command -v gcc >/dev/null 2>&1 && command -v pkg-config >/dev/null 2>&1; then
        gcc -O2 -DPOLKIT_AGENT_I_KNOW_API_IS_SUBJECT_TO_CHANGE \
            "$DIR/minimo-polkit-agent.c" \
            $(pkg-config --cflags --libs polkit-agent-1) \
            -o "$DIR/minimo-polkit-agent" 2>/dev/null
    fi
fi

if [ -x "$DIR/minimo-polkit-agent" ]; then
    exec "$DIR/minimo-polkit-agent"
elif [ -x /usr/lib/hyprpolkitagent/hyprpolkitagent ]; then
    exec /usr/lib/hyprpolkitagent/hyprpolkitagent
elif [ -x /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]; then
    exec /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
elif [ -x /usr/lib/polkit-kde-authentication-agent-1 ]; then
    exec /usr/lib/polkit-kde-authentication-agent-1
fi
