#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
# Corre la shell de Minimo OS para pruebas manuales (Ctrl+C para salir).
exec qs -p "$(dirname "$(realpath "$0")")" "$@"
