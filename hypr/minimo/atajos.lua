-- SPDX-License-Identifier: MIT
-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
-- Atalhos de teclado do Minimo OS. Super é a tecla principal.

local bind, dsp = hl.bind, hl.dsp
local qs = "qs -p " .. os.getenv("HOME") .. "/Projetos/minimo-os/minimo-shell ipc call "

-- Aplicativos e shell
bind("SUPER + T", dsp.exec_cmd("ghostty"))
bind("SUPER + space", dsp.exec_cmd(qs .. "launcher toggle"))
bind("SUPER + B", dsp.exec_cmd(qs .. "launcher toggle"))
bind("SUPER + comma", dsp.exec_cmd(qs .. "settings toggle"))
bind("SUPER + X", dsp.exec_cmd(qs .. "island open"))
bind("SUPER + SHIFT + R", dsp.exec_cmd(qs .. "recorder toggle"))

-- Sessão
bind("SUPER + SHIFT + E", dsp.exit())
bind("SUPER + SHIFT + P", dsp.dpms({ action = "toggle" }))

-- Volume e música (funcionam também com a tela bloqueada)
local fixo, repete = { locked = true }, { locked = true, repeating = true }
bind("XF86AudioRaiseVolume", dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 3%+"), repete)
bind("XF86AudioLowerVolume", dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%-"), repete)
bind("XF86AudioMute", dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), fixo)
bind("XF86AudioMicMute", dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), fixo)
bind("XF86AudioPlay", dsp.exec_cmd("playerctl play-pause"), fixo)
bind("XF86AudioPause", dsp.exec_cmd("playerctl play-pause"), fixo)
bind("XF86AudioNext", dsp.exec_cmd("playerctl next"), fixo)
bind("XF86AudioPrev", dsp.exec_cmd("playerctl previous"), fixo)

-- Capturas (em ~/Imagens/Capturas)
local dir = [[d="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Imagens")/Capturas"; mkdir -p "$d"; f="$d/captura-$(date +%Y%m%d-%H%M%S).png"; ]]
bind("Print", dsp.exec_cmd([[sh -c ']] .. dir .. [[g=$(slurp) && grim -g "$g" "$f"']]))
bind("CTRL + Print", dsp.exec_cmd([[sh -c ']] .. dir .. [[grim "$f"']]))

-- Janelas
bind("SUPER + Q", dsp.window.close())
bind("SUPER + F", dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
bind("SUPER + SHIFT + F", dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
bind("SUPER + CTRL + F", dsp.window.fullscreen({ mode = "maximized", action = "set" }))
bind("SUPER + SHIFT + T", dsp.window.float({ action = "toggle" }))
bind("SUPER + W", dsp.group.toggle())
bind("SUPER + R", dsp.layout("togglesplit"))
bind("SUPER + bracketleft", dsp.layout("preselect l"))
bind("SUPER + bracketright", dsp.layout("preselect r"))
bind("SUPER + Home", dsp.focus({ window = "first" }))
bind("SUPER + End", dsp.focus({ window = "last" }))

-- Mover/redimensionar com o mouse (Super + clique esquerdo/direito)
bind("SUPER + mouse:272", dsp.window.drag(), { mouse = true, description = "Mover janela" })
bind("SUPER + mouse:273", dsp.window.resize(), { mouse = true, description = "Redimensionar janela" })

-- Redimensionar com o teclado
local r = { repeating = true }
bind("SUPER + minus", dsp.window.resize({ x = -100, y = 0, relative = true }), r)
bind("SUPER + equal", dsp.window.resize({ x = 100, y = 0, relative = true }), r)
bind("SUPER + SHIFT + minus", dsp.window.resize({ x = 0, y = -100, relative = true }), r)
bind("SUPER + SHIFT + equal", dsp.window.resize({ x = 0, y = 100, relative = true }), r)
bind("SUPER + code:20", dsp.window.resize({ x = -100, y = 0, relative = true }))
bind("SUPER + code:21", dsp.window.resize({ x = 100, y = 0, relative = true }))

-- Foco, mover janela e monitores: setas ou h/j/k/l
local dirs = { left = "l", down = "d", up = "u", right = "r", H = "l", J = "d", K = "u", L = "r" }
for tecla, d in pairs(dirs) do
	bind("SUPER + " .. tecla, dsp.focus({ direction = d }))
	bind("SUPER + SHIFT + " .. tecla, dsp.window.move({ direction = d }))
	bind("SUPER + SHIFT + CTRL + " .. tecla, dsp.window.move({ monitor = d }))
end
for tecla, d in pairs({ left = "l", right = "r", H = "l", J = "d", K = "u", L = "r" }) do
	bind("SUPER + CTRL + " .. tecla, dsp.focus({ monitor = d }))
end

-- Áreas de trabalho: anterior/seguinte (não vazias)
for _, t in ipairs({ { "Page_Down", "U", "e+1" }, { "Page_Up", "I", "e-1" } }) do
	local a, b, ws = t[1], t[2], t[3]
	bind("SUPER + " .. a, dsp.focus({ workspace = ws }))
	bind("SUPER + " .. b, dsp.focus({ workspace = ws }))
	bind("SUPER + SHIFT + " .. a, dsp.window.move({ workspace = ws }))
	bind("SUPER + SHIFT + " .. b, dsp.window.move({ workspace = ws }))
	bind("SUPER + CTRL + " .. b, dsp.window.move({ workspace = ws }))
end
bind("SUPER + CTRL + down", dsp.window.move({ workspace = "e+1" }))
bind("SUPER + CTRL + up", dsp.window.move({ workspace = "e-1" }))
bind("SUPER + mouse_down", dsp.focus({ workspace = "e+1" }))
bind("SUPER + mouse_up", dsp.focus({ workspace = "e-1" }))
bind("SUPER + CTRL + mouse_down", dsp.window.move({ workspace = "e+1" }))
bind("SUPER + CTRL + mouse_up", dsp.window.move({ workspace = "e-1" }))

-- Áreas de trabalho 1–9
for i = 1, 9 do
	bind("SUPER + " .. i, dsp.focus({ workspace = tostring(i) }))
	bind("SUPER + SHIFT + " .. i, dsp.window.move({ workspace = tostring(i) }))
end
