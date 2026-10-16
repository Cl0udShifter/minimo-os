-- SPDX-License-Identifier: MIT
-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
-- Regras de janelas e camadas.

local function flutuar(classe) hl.window_rule({ match = { class = classe }, float = true }) end
local function mosaico(classe) hl.window_rule({ match = { class = classe }, tile = true }) end

-- Utilitários pequenos que ficam melhores em modo flutuante.
for _, c in ipairs({
	"^(blueman-manager)$", "^(xdg-desktop-portal)$", "^(zoom)$",
}) do flutuar(c) end

-- Gerenciadores de arquivos, utilitários e painéis que convém organizar em mosaico (tiling).
for _, c in ipairs({
	"^(org\\.gnome\\.Nautilus)$", "^(nautilus)$",
	"^(org\\.gnome\\.Calculator)$", "^(gnome-calculator)$", "^(galculator)$",
	"^(org\\.wezfurlong\\.wezterm)$", "^(gnome-control-center)$", "^(pavucontrol)$", "^(nm-connection-editor)$",
}) do mosaico(c) end

hl.window_rule({ match = { class = "^(org\\.gnome\\.)" }, rounding = 12 })
hl.window_rule({ match = { class = "^(firefox)$", title = "^(Picture-in-Picture)$" }, float = true })
hl.window_rule({ match = { class = "^(steam)$", title = "^(notificationtoasts)" }, no_initial_focus = true, pin = true })

-- Diálogos de autenticação e elevação de privilégios (Polkit)
for _, c in ipairs({
	"^(polkit-gnome-authentication-agent-1)$",
	"^(hyprpolkitagent)$",
	"^(org\\.kde\\.polkit-kde-authentication-agent-1)$",
}) do
	hl.window_rule({
		match = { class = c },
		float = true,
		center = true,
		stay_focused = true,
		dim_around = true,
		rounding = 16,
	})
end

-- Camadas da shell do Minimo: sem animação do Hyprland (a própria shell se anima).
hl.layer_rule({ match = { namespace = "^(quickshell)$" }, no_anim = true })
hl.layer_rule({ match = { namespace = "^minimo-.*" }, no_anim = true })


