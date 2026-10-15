-- SPDX-License-Identifier: MIT
-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
-- Atalhos de teclado do Minimo OS.
-- Gerado automaticamente por Configurações › Atalhos do Minimo OS.

local bind, dsp = hl.bind, hl.dsp
local qs = "qs -p " .. os.getenv("HOME") .. "/Projetos/minimo-os/minimo-shell ipc call "
local fixo, repete = { locked = true }, { locked = true, repeating = true }
local dir = [[d="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Imagens")/Capturas"; mkdir -p "$d"; f="$d/captura-$(date +%Y%m%d-%H%M%S).png"; ]]

-- Aplicativos e shell
bind("SUPER + space", dsp.exec_cmd(qs .. "launcher toggle"))
bind("SUPER + comma", dsp.exec_cmd(qs .. "settings toggle"))
bind("SUPER + T", dsp.exec_cmd("ghostty"))
bind("SUPER + X", dsp.exec_cmd(qs .. "island open"))
bind("SUPER + SHIFT + R", dsp.exec_cmd(qs .. "recorder toggle"))

-- Sessão
bind("SUPER + SHIFT + E", dsp.exit())
bind("SUPER + SHIFT + P", dsp.dpms({ action = "toggle" }))

-- Volume e música
bind("SUPER + F12", dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 3%+ && " .. qs .. "volume trigger"), repete)
bind("SUPER + F11", dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%- && " .. qs .. "volume trigger"), repete)
bind("SUPER + F10", dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && " .. qs .. "volume trigger"), fixo)
bind("XF86AudioMicMute", dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), fixo)
bind("XF86AudioPlay", dsp.exec_cmd("playerctl play-pause"), fixo)
bind("XF86AudioNext", dsp.exec_cmd("playerctl next"), fixo)
bind("XF86AudioPrev", dsp.exec_cmd("playerctl previous"), fixo)

-- Suporte direto a knobs e teclas de mídia física do teclado
if "SUPER + F12" ~= "XF86AudioRaiseVolume" then
    bind("XF86AudioRaiseVolume", dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 3%+ && " .. qs .. "volume trigger"), repete)
end
if "SUPER + F11" ~= "XF86AudioLowerVolume" then
    bind("XF86AudioLowerVolume", dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%- && " .. qs .. "volume trigger"), repete)
end
if "SUPER + F10" ~= "XF86AudioMute" then
    bind("XF86AudioMute", dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && " .. qs .. "volume trigger"), fixo)
end

-- Capturas de tela
bind("Print", dsp.exec_cmd([[sh -c ']] .. dir .. [[g=$(slurp) && grim -g "$g" "$f"']]))
bind("CTRL + Print", dsp.exec_cmd([[sh -c ']] .. dir .. [[grim "$f"']]))

-- Gerenciamento de Janelas
bind("SUPER + Q", dsp.window.close())
bind("SUPER + F", dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
bind("SUPER + SHIFT + F", dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
bind("SUPER + SHIFT + T", dsp.window.float({ action = "toggle" }))
bind("SUPER + W", dsp.group.toggle())
bind("SUPER + R", dsp.layout("togglesplit"))

-- Navegação e Foco
bind("SUPER + left", dsp.focus({ direction = "l" }))
bind("SUPER + right", dsp.focus({ direction = "r" }))
bind("SUPER + up", dsp.focus({ direction = "u" }))
bind("SUPER + down", dsp.focus({ direction = "d" }))
bind("SUPER + SHIFT + left", dsp.window.move({ direction = "l" }))
bind("SUPER + SHIFT + right", dsp.window.move({ direction = "r" }))
bind("SUPER + SHIFT + up", dsp.window.move({ direction = "u" }))
bind("SUPER + SHIFT + down", dsp.window.move({ direction = "d" }))

-- Áreas de trabalho
bind("SUPER + Page_Down", dsp.focus({ workspace = "e+1" }))
bind("SUPER + Page_Up", dsp.focus({ workspace = "e-1" }))
bind("SUPER + SHIFT + Page_Down", dsp.window.move({ workspace = "e+1" }))
bind("SUPER + SHIFT + Page_Up", dsp.window.move({ workspace = "e-1" }))

-- Mover e redimensionar janelas com mouse (Super + botão esquerdo/direito)
bind("SUPER + mouse:272", dsp.window.drag(), { mouse = true, description = "Mover janela" })
bind("SUPER + mouse:273", dsp.window.resize(), { mouse = true, description = "Redimensionar janela" })

-- Redimensionamento pelo teclado
local r = { repeating = true }
bind("SUPER + minus", dsp.window.resize({ x = -100, y = 0, relative = true }), r)
bind("SUPER + equal", dsp.window.resize({ x = 100, y = 0, relative = true }), r)
bind("SUPER + SHIFT + minus", dsp.window.resize({ x = 0, y = -100, relative = true }), r)
bind("SUPER + SHIFT + equal", dsp.window.resize({ x = 0, y = 100, relative = true }), r)

-- Áreas de trabalho diretas 1 a 9
bind("ALT + 1", dsp.focus({ workspace = "1" }))
bind("SUPER + SHIFT + 1", dsp.window.move({ workspace = "1" }))
bind("ALT + 2", dsp.focus({ workspace = "2" }))
bind("SUPER + SHIFT + 2", dsp.window.move({ workspace = "2" }))
bind("ALT + 3", dsp.focus({ workspace = "3" }))
bind("SUPER + SHIFT + 3", dsp.window.move({ workspace = "3" }))
bind("ALT + 4", dsp.focus({ workspace = "4" }))
bind("SUPER + SHIFT + 4", dsp.window.move({ workspace = "4" }))
bind("ALT + 5", dsp.focus({ workspace = "5" }))
bind("SUPER + SHIFT + 5", dsp.window.move({ workspace = "5" }))
bind("ALT + 6", dsp.focus({ workspace = "6" }))
bind("SUPER + SHIFT + 6", dsp.window.move({ workspace = "6" }))
bind("ALT + 7", dsp.focus({ workspace = "7" }))
bind("SUPER + SHIFT + 7", dsp.window.move({ workspace = "7" }))
bind("ALT + 8", dsp.focus({ workspace = "8" }))
bind("SUPER + SHIFT + 8", dsp.window.move({ workspace = "8" }))
bind("ALT + 9", dsp.focus({ workspace = "9" }))
bind("SUPER + SHIFT + 9", dsp.window.move({ workspace = "9" }))
