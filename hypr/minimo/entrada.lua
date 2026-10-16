-- SPDX-License-Identifier: MIT
-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
-- Entrada: layout do sistema, Num Lock ativo, foco segue o mouse, touchpad natural.
-- Gerado automaticamente por Configurações › Mouse e Teclado do Minimo OS.

hl.config({
	input = {
		kb_layout = "br,us",
		kb_variant = "abnt2,intl",
		kb_model = "",
		kb_options = "grp:ctrl_shift_toggle",
		numlock_by_default = true,
		follow_mouse = 1,
		sensitivity = 0.00,
		accel_profile = "flat",
		natural_scroll = false,
		touchpad = {
			tap_to_click = true,
			natural_scroll = true,
			scroll_factor = 1.00,
		},
	},
	cursor = {
		no_warps = false,
		inactive_timeout = 0,
		hide_on_key_press = false,
		hide_on_touch = false,
		no_hardware_cursors = true,
	},
})

-- Três dedos na horizontal: alternar área de trabalho.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
