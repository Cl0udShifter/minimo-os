#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
# Agente de autenticação Polkit do Minimo OS

export GTK_THEME="Adwaita:dark"

if [ -x /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]; then
    exec /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
elif [ -x /usr/lib/hyprpolkitagent/hyprpolkitagent ]; then
    exec /usr/lib/hyprpolkitagent/hyprpolkitagent
elif [ -x /usr/lib/polkit-kde-authentication-agent-1 ]; then
    exec /usr/lib/polkit-kde-authentication-agent-1
fi
