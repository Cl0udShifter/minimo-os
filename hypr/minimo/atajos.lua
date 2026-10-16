-- SPDX-License-Identifier: MIT
-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
-- Atalhos de teclado do Minimo OS.
-- Gerado automaticamente por Configurações › Atalhos do Minimo OS.

local bind, dsp = hl.bind, hl.dsp
local qs = "qs -p " .. os.getenv("HOME") .. "/Projetos/minimo-os/minimo-shell ipc call "
local ws = os.getenv("HOME") .. "/Projetos/minimo-os/minimo-shell/scripts/minimo-ws "
local switch_kb = os.getenv("HOME") .. "/Projetos/minimo-os/minimo-shell/scripts/switch-layout.sh"
local fixo, repete = { locked = true }, { locked = true, repeating = true }
local dir = [[d="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Imagens")/Capturas"; mkdir -p "$d"; f="$d/captura-$(date +%Y%m%d-%H%M%S).png"; ]]

local mod_syms = {
    SUPER = { "Super_L", "Super_R" },
    CTRL = { "Control_L", "Control_R" },
    SHIFT = { "Shift_L", "Shift_R" },
    ALT = { "Alt_L", "Alt_R" },
}

local function bind_key(combo, action, opts)
    if not combo or combo == "" then return end
    local tokens = {}
    for token in string.gmatch(combo, "[^%+%s]+") do
        table.insert(tokens, token)
    end
    local all_mods = true
    for _, t in ipairs(tokens) do
        local u = string.upper(t)
        if not mod_syms[u] then
            all_mods = false
            break
        end
    end
    if not all_mods or #tokens == 0 then
        bind(combo, action, opts)
        return
    end
    if #tokens == 1 then
        local u = string.upper(tokens[1])
        local syms = mod_syms[u] or { tokens[1] }
        for _, s in ipairs(syms) do
            bind(s, action, opts)
        end
    elseif #tokens == 2 then
        local m1, m2 = string.upper(tokens[1]), string.upper(tokens[2])
        local syms1 = mod_syms[m1] or { m1 }
        local syms2 = mod_syms[m2] or { m2 }
        for _, s in ipairs(syms2) do
            bind(m1 .. " + " .. s, action, opts)
        end
        for _, s in ipairs(syms1) do
            bind(m2 .. " + " .. s, action, opts)
        end
    elseif #tokens >= 3 then
        for i, target in ipairs(tokens) do
            local u = string.upper(target)
            local remaining = {}
            for j, other in ipairs(tokens) do
                if i ~= j then
                    table.insert(remaining, string.upper(other))
                end
            end
            local prefix = table.concat(remaining, " + ")
            local syms = mod_syms[u] or { target }
            for _, s in ipairs(syms) do
                bind(prefix .. " + " .. s, action, opts)
            end
        end
    end
end

-- Aplicativos e shell
bind_key("SUPER + space", dsp.exec_cmd(qs .. "launcher toggle"))
bind_key("SUPER + comma", dsp.exec_cmd(qs .. "settings toggle"))
bind_key("SUPER + V", dsp.exec_cmd(qs .. "clipboard toggle"), fixo)
bind_key("SUPER + T", dsp.exec_cmd("ghostty"))
bind_key("SUPER + X", dsp.exec_cmd(qs .. "island open"))
bind_key("SUPER + SHIFT + R", dsp.exec_cmd(qs .. "recorder toggle"))
bind_key("CTRL + SHIFT", dsp.exec_cmd(switch_kb), fixo)

-- Sessão
bind_key("SUPER + L", dsp.exec_cmd(qs .. "lock lock"), fixo)
bind_key("SUPER + SHIFT + E", dsp.exit())
bind_key("SUPER + SHIFT + P", dsp.dpms({ action = "toggle" }))

-- Volume e música
bind_key("SUPER + F12", dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 3%+ && " .. qs .. "volume trigger"), repete)
bind_key("SUPER + F11", dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%- && " .. qs .. "volume trigger"), repete)
bind_key("SUPER + F10", dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && " .. qs .. "volume trigger"), fixo)
bind_key("XF86AudioMicMute", dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), fixo)
bind_key("XF86AudioPlay", dsp.exec_cmd("playerctl play-pause"), fixo)
bind_key("XF86AudioNext", dsp.exec_cmd("playerctl next"), fixo)
bind_key("XF86AudioPrev", dsp.exec_cmd("playerctl previous"), fixo)

-- Suporte direto a knobs e teclas de mídia física do teclado
if "SUPER + F12" ~= "XF86AudioRaiseVolume" then
    bind_key("XF86AudioRaiseVolume", dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 3%+ && " .. qs .. "volume trigger"), repete)
end
if "SUPER + F11" ~= "XF86AudioLowerVolume" then
    bind_key("XF86AudioLowerVolume", dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%- && " .. qs .. "volume trigger"), repete)
end
if "SUPER + F10" ~= "XF86AudioMute" then
    bind_key("XF86AudioMute", dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && " .. qs .. "volume trigger"), fixo)
end

-- Capturas de tela
bind_key("Print", dsp.exec_cmd([[sh -c ']] .. dir .. [[g=$(slurp) && grim -g "$g" "$f"']]))
bind_key("CTRL + Print", dsp.exec_cmd([[sh -c ']] .. dir .. [[grim "$f"']]))

-- Gerenciamento de Janelas
bind_key("SUPER + Q", dsp.window.close())
bind_key("SUPER + F", dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
bind_key("SUPER + SHIFT + F", dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
bind_key("SUPER + SHIFT + T", dsp.window.float({ action = "toggle" }))
bind_key("SUPER + W", dsp.group.toggle())
bind_key("SUPER + R", dsp.layout("togglesplit"))

-- Navegação e Foco
bind_key("SUPER + left", dsp.focus({ direction = "l" }))
bind_key("SUPER + right", dsp.focus({ direction = "r" }))
bind_key("SUPER + up", dsp.focus({ direction = "u" }))
bind_key("SUPER + down", dsp.focus({ direction = "d" }))
bind_key("SUPER + SHIFT + left", dsp.window.move({ direction = "l" }))
bind_key("SUPER + SHIFT + right", dsp.window.move({ direction = "r" }))
bind_key("SUPER + SHIFT + up", dsp.window.move({ direction = "u" }))
bind_key("SUPER + SHIFT + down", dsp.window.move({ direction = "d" }))

-- Áreas de trabalho
bind_key("SUPER + Page_Down", dsp.exec_cmd(ws .. "next"))
bind_key("SUPER + Page_Up", dsp.exec_cmd(ws .. "prev"))
bind_key("SUPER + SHIFT + Page_Down", dsp.exec_cmd(ws .. "move-next"))
bind_key("SUPER + SHIFT + Page_Up", dsp.exec_cmd(ws .. "move-prev"))

-- Mover e redimensionar janelas com mouse (Super + botão esquerdo/direito)
bind_key("SUPER + mouse:272", dsp.window.drag(), { mouse = true, description = "Mover janela" })
bind_key("SUPER + mouse:273", dsp.window.resize(), { mouse = true, description = "Redimensionar janela" })

-- Redimensionamento pelo teclado
local r = { repeating = true }
bind_key("SUPER + minus", dsp.window.resize({ x = -100, y = 0, relative = true }), r)
bind_key("SUPER + equal", dsp.window.resize({ x = 100, y = 0, relative = true }), r)
bind_key("SUPER + SHIFT + minus", dsp.window.resize({ x = 0, y = -100, relative = true }), r)
bind_key("SUPER + SHIFT + equal", dsp.window.resize({ x = 0, y = 100, relative = true }), r)

-- Áreas de trabalho diretas 1 a 9
bind_key("ALT + 1", dsp.exec_cmd(ws .. "focus 1"))
bind_key("SUPER + SHIFT + 1", dsp.exec_cmd(ws .. "move 1"))
bind_key("ALT + 2", dsp.exec_cmd(ws .. "focus 2"))
bind_key("SUPER + SHIFT + 2", dsp.exec_cmd(ws .. "move 2"))
bind_key("ALT + 3", dsp.exec_cmd(ws .. "focus 3"))
bind_key("SUPER + SHIFT + 3", dsp.exec_cmd(ws .. "move 3"))
bind_key("ALT + 4", dsp.exec_cmd(ws .. "focus 4"))
bind_key("SUPER + SHIFT + 4", dsp.exec_cmd(ws .. "move 4"))
bind_key("ALT + 5", dsp.exec_cmd(ws .. "focus 5"))
bind_key("SUPER + SHIFT + 5", dsp.exec_cmd(ws .. "move 5"))
bind_key("ALT + 6", dsp.exec_cmd(ws .. "focus 6"))
bind_key("SUPER + SHIFT + 6", dsp.exec_cmd(ws .. "move 6"))
bind_key("ALT + 7", dsp.exec_cmd(ws .. "focus 7"))
bind_key("SUPER + SHIFT + 7", dsp.exec_cmd(ws .. "move 7"))
bind_key("ALT + 8", dsp.exec_cmd(ws .. "focus 8"))
bind_key("SUPER + SHIFT + 8", dsp.exec_cmd(ws .. "move 8"))
bind_key("ALT + 9", dsp.exec_cmd(ws .. "focus 9"))
bind_key("SUPER + SHIFT + 9", dsp.exec_cmd(ws .. "move 9"))
