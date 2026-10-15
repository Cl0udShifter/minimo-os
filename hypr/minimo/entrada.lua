-- SPDX-License-Identifier: MIT
-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
-- Entrada: layout do sistema, Num Lock ativo, foco apenas com clique, touchpad natural.

hl.config({
	input = {
		kb_layout = "",               -- vazio: usa XKB_DEFAULT_LAYOUT (ou "us")
		numlock_by_default = true,
		follow_mouse = 0,             -- o foco não segue o mouse
		touchpad = {
			tap_to_click = true,
			natural_scroll = true,
		},
	},
})

-- Três dedos na horizontal: alternar área de trabalho.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

