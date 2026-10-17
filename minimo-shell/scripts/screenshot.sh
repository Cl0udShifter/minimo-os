#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
# Captura de tela com notificação integrada para o Minimo OS

MODE="${1:-area}"
DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Imagens")/Capturas"
mkdir -p "$DIR" || exit 1

FILENAME="captura-$(date +%Y%m%d-%H%M%S).png"
FILEPATH="$DIR/$FILENAME"

if [ "$MODE" = "full" ]; then
    grim "$FILEPATH" || exit 1
else
    # Captura de área selecionada
    GEOM=$(slurp 2>/dev/null)
    if [ -z "$GEOM" ]; then
        # Usuário cancelou com Escape
        exit 0
    fi
    grim -g "$GEOM" "$FILEPATH" || exit 1
fi

if [ -f "$FILEPATH" ]; then
    # Copia a imagem capturada para a área de transferência caso wl-copy esteja disponível
    if command -v wl-copy >/dev/null 2>&1; then
        wl-copy < "$FILEPATH" 2>/dev/null &
    fi

    # Envia notificação no sistema padrão do desktop (capturada pelo NotificationServer do Notch)
    if command -v notify-send >/dev/null 2>&1; then
        notify-send \
            -a "Captura de Tela" \
            -i "$FILEPATH" \
            "Captura salva" \
            "$FILENAME em $DIR"
    fi
fi
