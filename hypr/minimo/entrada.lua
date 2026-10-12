-- SPDX-License-Identifier: MIT
-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
-- Entrada: distribución del sistema, Bloq Num activo, foco solo con clic, touchpad natural.

hl.config({
	input = {
		kb_layout = "",               -- vacío: usa XKB_DEFAULT_LAYOUT (o "us")
		numlock_by_default = true,
		follow_mouse = 0,             -- el foco no sigue al mouse
		touchpad = {
			tap_to_click = true,
			natural_scroll = true,
		},
	},
})

-- Tres dedos en horizontal: cambiar de escritorio.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
