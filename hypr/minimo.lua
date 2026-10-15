-- SPDX-License-Identifier: MIT
-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
-- Minimo OS: atalhos próprios (carregado ao final de hyprland.lua).

-- Super+B e Super+Espaço: lançador de aplicativos do Minimo (IpcHandler "launcher" na shell).
local qs = "qs -p " .. os.getenv("HOME") .. "/Projetos/minimo-os/minimo-shell ipc call "
hl.bind("SUPER + space", hl.dsp.exec_cmd(qs .. "launcher toggle"))
hl.bind("SUPER + B", hl.dsp.exec_cmd(qs .. "launcher toggle"))
