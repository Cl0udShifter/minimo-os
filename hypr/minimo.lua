-- SPDX-License-Identifier: MIT
-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
-- Minimo OS: atalhos próprios (carregado ao final de hyprland.lua).

-- Super+B: lançador de aplicativos do Minimo (IpcHandler "launcher" na shell).
hl.bind("SUPER + B", hl.dsp.exec_cmd("qs -p " .. os.getenv("HOME") .. "/Projetos/minimo-os/minimo-shell ipc call launcher toggle"))
