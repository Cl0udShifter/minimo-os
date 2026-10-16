// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Gerenciador central de atalhos de teclado do Minimo OS.
// Persiste configurações em ~/.config/minimo-os/shortcuts.json
// e gera o arquivo Lua ativo ~/.config/hypr/minimo/atajos.lua.
Singleton {
    id: root

    property bool loaded: false
    property bool dirty: false
    property bool saveSuccess: false
    property string searchFilter: ""
    property var shortcutsList: []

    IpcHandler {
        target: "shortcuts"
        function search(query: string) {
            root.searchFilter = (query || "").trim().toLowerCase()
        }
        function save() {
            root.saveChanges()
        }
        function reset() {
            root.resetAllToDefaults()
        }
    }

    readonly property string stateDir: Quickshell.env("HOME") + "/.config/minimo-os"
    readonly property string jsonPath: stateDir + "/shortcuts.json"
    readonly property string atajosLuaPath: Quickshell.env("HOME") + "/.config/hypr/minimo/atajos.lua"
    readonly property string repoLuaPath: Quickshell.env("HOME") + "/Projetos/minimo-os/hypr/minimo/atajos.lua"

    // Definição de todos os atalhos disponíveis no Minimo OS
    readonly property var defaultDefinitions: [
        // 1. Aplicativos e Shell
        { id: "launcher", cat: "Aplicativos e Shell", name: "Lançador de Aplicativos", desc: "Abre a busca rápida e inicializador de apps estilo Spotlight", icon: "search", defaultKeys: "SUPER + space" },
        { id: "settings", cat: "Aplicativos e Shell", name: "Configurações", desc: "Abre o painel de configurações do Minimo OS", icon: "settings", defaultKeys: "SUPER + comma" },
        { id: "terminal", cat: "Aplicativos e Shell", name: "Terminal", desc: "Abre o terminal acelerado por GPU", icon: "terminal", defaultKeys: "SUPER + T" },
        { id: "island", cat: "Aplicativos e Shell", name: "Menu da Ilha (Notch)", desc: "Expande a ilha dinâmica de controle e monitoramento", icon: "apps", defaultKeys: "SUPER + X" },
        { id: "recorder", cat: "Aplicativos e Shell", name: "Gravação de Tela", desc: "Inicia ou para a gravação da tela", icon: "record", defaultKeys: "SUPER + SHIFT + R" },
        { id: "toggle_kb_layout", cat: "Aplicativos e Shell", name: "Alternar Layout de Teclado", desc: "Alterna rapidamente entre Português (ABNT2) e Inglês (Internacional)", icon: "keyboard", defaultKeys: "SUPER + backslash" },

        // 2. Janelas
        { id: "close_window", cat: "Janelas", name: "Fechar Janela", desc: "Fecha a janela atualmente em foco", icon: "power", defaultKeys: "SUPER + Q" },
        { id: "toggle_maximize", cat: "Janelas", name: "Maximizar Janela", desc: "Alterna entre janela normal e maximizada", icon: "external", defaultKeys: "SUPER + F" },
        { id: "toggle_fullscreen", cat: "Janelas", name: "Tela Cheia Completa", desc: "Alterna tela cheia real (sem bordas ou margens)", icon: "external", defaultKeys: "SUPER + SHIFT + F" },
        { id: "toggle_floating", cat: "Janelas", name: "Janela Flutuante", desc: "Alterna entre janela em mosaico e flutuante", icon: "chip", defaultKeys: "SUPER + SHIFT + T" },
        { id: "toggle_group", cat: "Janelas", name: "Agrupar Janelas (Abas)", desc: "Agrupa ou desagrupa janelas em formato de abas", icon: "folder", defaultKeys: "SUPER + W" },
        { id: "toggle_split", cat: "Janelas", name: "Alternar Divisão", desc: "Alterna a direção de divisão do mosaico", icon: "desktops", defaultKeys: "SUPER + R" },

        // 3. Navegação e Foco
        { id: "focus_left", cat: "Navegação", name: "Focar Janela à Esquerda", desc: "Move o foco para a janela da esquerda", icon: "prev", defaultKeys: "SUPER + left" },
        { id: "focus_right", cat: "Navegação", name: "Focar Janela à Direita", desc: "Move o foco para a janela da direita", icon: "next", defaultKeys: "SUPER + right" },
        { id: "focus_up", cat: "Navegação", name: "Focar Janela Acima", desc: "Move o foco para a janela de cima", icon: "chevron", defaultKeys: "SUPER + up" },
        { id: "focus_down", cat: "Navegação", name: "Focar Janela Abaixo", desc: "Move o foco para a janela de baixo", icon: "chevron", defaultKeys: "SUPER + down" },
        { id: "move_left", cat: "Navegação", name: "Mover Janela à Esquerda", desc: "Move a janela ativa para a posição da esquerda", icon: "prev", defaultKeys: "SUPER + SHIFT + left" },
        { id: "move_right", cat: "Navegação", name: "Mover Janela à Direita", desc: "Move a janela ativa para a posição da direita", icon: "next", defaultKeys: "SUPER + SHIFT + right" },
        { id: "move_up", cat: "Navegação", name: "Mover Janela Acima", desc: "Move a janela ativa para cima", icon: "chevron", defaultKeys: "SUPER + SHIFT + up" },
        { id: "move_down", cat: "Navegação", name: "Mover Janela Abaixo", desc: "Move a janela ativa para baixo", icon: "chevron", defaultKeys: "SUPER + SHIFT + down" },

        // 4. Áudio e Multimídia
        { id: "volume_up", cat: "Áudio e Mídia", name: "Aumentar Volume", desc: "Aumenta o volume do áudio do sistema", icon: "volume", defaultKeys: "SUPER + F12" },
        { id: "volume_down", cat: "Áudio e Mídia", name: "Diminuir Volume", desc: "Diminui o volume do áudio do sistema", icon: "volume", defaultKeys: "SUPER + F11" },
        { id: "volume_mute", cat: "Áudio e Mídia", name: "Mutar / Desmutar Áudio", desc: "Alterna mudo da saída de som", icon: "mute", defaultKeys: "SUPER + F10" },
        { id: "mic_mute", cat: "Áudio e Mídia", name: "Mutar Microfone", desc: "Alterna mudo da entrada do microfone", icon: "mute", defaultKeys: "XF86AudioMicMute" },
        { id: "play_pause", cat: "Áudio e Mídia", name: "Play / Pausar Música", desc: "Alterna reprodução do tocador ativo", icon: "play", defaultKeys: "XF86AudioPlay" },
        { id: "media_next", cat: "Áudio e Mídia", name: "Próxima Música", desc: "Avança para a próxima faixa", icon: "next", defaultKeys: "XF86AudioNext" },
        { id: "media_prev", cat: "Áudio e Mídia", name: "Música Anterior", desc: "Retorna para a faixa anterior", icon: "prev", defaultKeys: "XF86AudioPrev" },

        // 5. Capturas de Tela
        { id: "screenshot_area", cat: "Capturas", name: "Captura de Área (Seleção)", desc: "Seleciona um pedaço da tela para salvar", icon: "capture", defaultKeys: "Print" },
        { id: "screenshot_full", cat: "Capturas", name: "Captura de Tela Inteira", desc: "Captura e salva imagem da tela completa", icon: "capture", defaultKeys: "CTRL + Print" },

        // 6. Áreas de Trabalho
        { id: "ws_next", cat: "Áreas de Trabalho", name: "Próxima Área de Trabalho", desc: "Alterna para a próxima área de trabalho", icon: "desktops", defaultKeys: "SUPER + Page_Down" },
        { id: "ws_prev", cat: "Áreas de Trabalho", name: "Área de Trabalho Anterior", desc: "Alterna para a área de trabalho anterior", icon: "desktops", defaultKeys: "SUPER + Page_Up" },
        { id: "ws_move_next", cat: "Áreas de Trabalho", name: "Mover Janela para Próxima Área", desc: "Leva a janela ativa para a próxima área", icon: "desktops", defaultKeys: "SUPER + SHIFT + Page_Down" },
        { id: "ws_move_prev", cat: "Áreas de Trabalho", name: "Mover Janela para Área Anterior", desc: "Leva a janela ativa para a área anterior", icon: "desktops", defaultKeys: "SUPER + SHIFT + Page_Up" },
        { id: "ws_1", cat: "Áreas de Trabalho", name: "Ir para Área de Trabalho 1", desc: "Alterna o foco para a área de trabalho 1", icon: "desktops", defaultKeys: "SUPER + 1" },
        { id: "ws_2", cat: "Áreas de Trabalho", name: "Ir para Área de Trabalho 2", desc: "Alterna o foco para a área de trabalho 2", icon: "desktops", defaultKeys: "SUPER + 2" },
        { id: "ws_3", cat: "Áreas de Trabalho", name: "Ir para Área de Trabalho 3", desc: "Alterna o foco para a área de trabalho 3", icon: "desktops", defaultKeys: "SUPER + 3" },
        { id: "ws_4", cat: "Áreas de Trabalho", name: "Ir para Área de Trabalho 4", desc: "Alterna o foco para a área de trabalho 4", icon: "desktops", defaultKeys: "SUPER + 4" },
        { id: "ws_5", cat: "Áreas de Trabalho", name: "Ir para Área de Trabalho 5", desc: "Alterna o foco para a área de trabalho 5", icon: "desktops", defaultKeys: "SUPER + 5" },
        { id: "ws_6", cat: "Áreas de Trabalho", name: "Ir para Área de Trabalho 6", desc: "Alterna o foco para a área de trabalho 6", icon: "desktops", defaultKeys: "SUPER + 6" },
        { id: "ws_7", cat: "Áreas de Trabalho", name: "Ir para Área de Trabalho 7", desc: "Alterna o foco para a área de trabalho 7", icon: "desktops", defaultKeys: "SUPER + 7" },
        { id: "ws_8", cat: "Áreas de Trabalho", name: "Ir para Área de Trabalho 8", desc: "Alterna o foco para a área de trabalho 8", icon: "desktops", defaultKeys: "SUPER + 8" },
        { id: "ws_9", cat: "Áreas de Trabalho", name: "Ir para Área de Trabalho 9", desc: "Alterna o foco para a área de trabalho 9", icon: "desktops", defaultKeys: "SUPER + 9" },
        { id: "ws_move_1", cat: "Áreas de Trabalho", name: "Mover Janela para Área 1", desc: "Leva a janela ativa para a área de trabalho 1", icon: "desktops", defaultKeys: "SUPER + SHIFT + 1" },
        { id: "ws_move_2", cat: "Áreas de Trabalho", name: "Mover Janela para Área 2", desc: "Leva a janela ativa para a área de trabalho 2", icon: "desktops", defaultKeys: "SUPER + SHIFT + 2" },
        { id: "ws_move_3", cat: "Áreas de Trabalho", name: "Mover Janela para Área 3", desc: "Leva a janela ativa para a área de trabalho 3", icon: "desktops", defaultKeys: "SUPER + SHIFT + 3" },
        { id: "ws_move_4", cat: "Áreas de Trabalho", name: "Mover Janela para Área 4", desc: "Leva a janela ativa para a área de trabalho 4", icon: "desktops", defaultKeys: "SUPER + SHIFT + 4" },
        { id: "ws_move_5", cat: "Áreas de Trabalho", name: "Mover Janela para Área 5", desc: "Leva a janela ativa para a área de trabalho 5", icon: "desktops", defaultKeys: "SUPER + SHIFT + 5" },
        { id: "ws_move_6", cat: "Áreas de Trabalho", name: "Mover Janela para Área 6", desc: "Leva a janela ativa para a área de trabalho 6", icon: "desktops", defaultKeys: "SUPER + SHIFT + 6" },
        { id: "ws_move_7", cat: "Áreas de Trabalho", name: "Mover Janela para Área 7", desc: "Leva a janela ativa para a área de trabalho 7", icon: "desktops", defaultKeys: "SUPER + SHIFT + 7" },
        { id: "ws_move_8", cat: "Áreas de Trabalho", name: "Mover Janela para Área 8", desc: "Leva a janela ativa para a área de trabalho 8", icon: "desktops", defaultKeys: "SUPER + SHIFT + 8" },
        { id: "ws_move_9", cat: "Áreas de Trabalho", name: "Mover Janela para Área 9", desc: "Leva a janela ativa para a área de trabalho 9", icon: "desktops", defaultKeys: "SUPER + SHIFT + 9" },

        // 7. Sessão
        { id: "session_lock", cat: "Sessão", name: "Bloquear Tela", desc: "Bloqueia a sessão imediatamente", icon: "lock", defaultKeys: "SUPER + L" },
        { id: "session_exit", cat: "Sessão", name: "Encerrar Sessão", desc: "Sai do Minimo OS e retorna à tela de login", icon: "logout", defaultKeys: "SUPER + SHIFT + E" },
        { id: "session_dpms", cat: "Sessão", name: "Desligar / Suspender Telas", desc: "Alterna energia dos monitores", icon: "power", defaultKeys: "SUPER + SHIFT + P" }
    ]

    // Inicialização e leitura do arquivo
    Process {
        id: initDir
        running: true
        command: ["mkdir", "-p", root.stateDir]
        onExited: file.path = root.jsonPath
    }

    FileView {
        id: file
        blockLoading: false
        printErrors: false
        onLoaded: {
            try {
                const saved = JSON.parse(text())
                root.initList(saved)
            } catch (e) {
                root.initList({})
            }
            root.loaded = true
        }
        onLoadFailed: {
            root.initList({})
            root.loaded = true
        }
    }

    function initList(customMap) {
        let list = []
        for (let i = 0; i < defaultDefinitions.length; i++) {
            let def = defaultDefinitions[i]
            let assignedKeys = (customMap && customMap[def.id]) ? customMap[def.id] : def.defaultKeys
            list.push({
                id: def.id,
                cat: def.cat,
                name: def.name,
                desc: def.desc,
                icon: def.icon,
                defaultKeys: def.defaultKeys,
                keys: assignedKeys
            })
        }
        root.shortcutsList = list
        root.dirty = false
    }

    // Normalização das teclas para garantir ordem consistente (SUPER + CTRL + SHIFT + ALT + KEY)
    function normalizeKeys(keysStr) {
        if (!keysStr) return ""
        let tokens = keysStr.split("+").map(s => s.trim()).filter(s => s.length > 0)
        let hasSuper = false, hasCtrl = false, hasShift = false, hasAlt = false
        let mainKeys = []
        for (let i = 0; i < tokens.length; i++) {
            let u = tokens[i].toUpperCase()
            if (u === "SUPER" || u === "META" || u === "WIN") hasSuper = true
            else if (u === "CTRL" || u === "CONTROL") hasCtrl = true
            else if (u === "SHIFT") hasShift = true
            else if (u === "ALT") hasAlt = true
            else mainKeys.push(tokens[i])
        }
        let parts = []
        if (hasSuper) parts.push("SUPER")
        if (hasCtrl) parts.push("CTRL")
        if (hasShift) parts.push("SHIFT")
        if (hasAlt) parts.push("ALT")
        for (let j = 0; j < mainKeys.length; j++) parts.push(mainKeys[j])
        return parts.join(" + ")
    }

    // Divide uma string de atalho em array de badges visuais
    function parseBadges(keysStr) {
        if (!keysStr) return []
        return keysStr.split("+").map(s => s.trim()).filter(s => s.length > 0)
    }

    // Conta total de teclas na combinação
    function countKeys(keysStr) {
        return parseBadges(keysStr).length
    }

    // Verifica se já existe outra função usando essa combinação de teclas
    function findConflict(actionId, candidateKeys) {
        let targetNorm = normalizeKeys(candidateKeys).toLowerCase()
        if (!targetNorm) return null
        for (let i = 0; i < root.shortcutsList.length; i++) {
            let s = root.shortcutsList[i]
            if (s.id === actionId) continue
            if (normalizeKeys(s.keys).toLowerCase() === targetNorm) {
                return s
            }
        }
        return null
    }

    // Atualiza o atalho de uma ação
    function updateShortcut(actionId, newKeys) {
        let normalized = normalizeKeys(newKeys)
        let list = []
        for (let i = 0; i < root.shortcutsList.length; i++) {
            let s = root.shortcutsList[i]
            if (s.id === actionId) {
                list.push({
                    id: s.id,
                    cat: s.cat,
                    name: s.name,
                    desc: s.desc,
                    icon: s.icon,
                    defaultKeys: s.defaultKeys,
                    keys: normalized
                })
            } else {
                list.push(s)
            }
        }
        root.shortcutsList = list
        root.dirty = true
    }

    // Restaura um único atalho para o padrão
    function resetSingle(actionId) {
        for (let i = 0; i < defaultDefinitions.length; i++) {
            if (defaultDefinitions[i].id === actionId) {
                updateShortcut(actionId, defaultDefinitions[i].defaultKeys)
                break
            }
        }
    }

    // Restaura todos os atalhos para os valores padrão
    function resetAllToDefaults() {
        let list = []
        for (let i = 0; i < defaultDefinitions.length; i++) {
            let def = defaultDefinitions[i]
            list.push({
                id: def.id,
                cat: def.cat,
                name: def.name,
                desc: def.desc,
                icon: def.icon,
                defaultKeys: def.defaultKeys,
                keys: def.defaultKeys
            })
        }
        root.shortcutsList = list
        root.dirty = true
    }

    // Gerador de código Lua para o Hyprland
    function generateLuaScript(map) {
        let out = "-- SPDX-License-Identifier: MIT\n"
        out += "-- Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS\n"
        out += "-- Atalhos de teclado do Minimo OS.\n"
        out += "-- Gerado automaticamente por Configurações › Atalhos do Minimo OS.\n\n"
        out += "local bind, dsp = hl.bind, hl.dsp\n"
        out += 'local qs = "qs -p " .. os.getenv("HOME") .. "/Projetos/minimo-os/minimo-shell ipc call "\n'
        out += 'local ws = os.getenv("HOME") .. "/Projetos/minimo-os/minimo-shell/scripts/minimo-ws "\n'
        out += 'local switch_kb = os.getenv("HOME") .. "/Projetos/minimo-os/minimo-shell/scripts/switch-layout.sh"\n'
        out += "local fixo, repete = { locked = true }, { locked = true, repeating = true }\n"
        out += 'local dir = [[d="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Imagens")/Capturas"; mkdir -p "$d"; f="$d/captura-$(date +%Y%m%d-%H%M%S).png"; ]]\n\n'
        out += "local mod_syms = {\n"
        out += '    SUPER = { "Super_L", "Super_R" },\n'
        out += '    CTRL = { "Control_L", "Control_R" },\n'
        out += '    SHIFT = { "Shift_L", "Shift_R" },\n'
        out += '    ALT = { "Alt_L", "Alt_R" },\n'
        out += "}\n\n"
        out += "local function bind_key(combo, action, opts)\n"
        out += '    if not combo or combo == "" then return end\n'
        out += "    local tokens = {}\n"
        out += '    for token in string.gmatch(combo, "[^%+%s]+") do\n'
        out += "        table.insert(tokens, token)\n"
        out += "    end\n"
        out += "    local all_mods = true\n"
        out += "    for _, t in ipairs(tokens) do\n"
        out += "        local u = string.upper(t)\n"
        out += "        if not mod_syms[u] then\n"
        out += "            all_mods = false\n"
        out += "            break\n"
        out += "        end\n"
        out += "    end\n"
        out += "    if not all_mods or #tokens == 0 then\n"
        out += "        bind(combo, action, opts)\n"
        out += "        return\n"
        out += "    end\n"
        out += "    if #tokens == 1 then\n"
        out += "        local u = string.upper(tokens[1])\n"
        out += "        local syms = mod_syms[u] or { tokens[1] }\n"
        out += "        for _, s in ipairs(syms) do\n"
        out += "            bind(s, action, opts)\n"
        out += "        end\n"
        out += "    elseif #tokens == 2 then\n"
        out += "        local m1, m2 = string.upper(tokens[1]), string.upper(tokens[2])\n"
        out += "        local syms1 = mod_syms[m1] or { m1 }\n"
        out += "        local syms2 = mod_syms[m2] or { m2 }\n"
        out += "        for _, s in ipairs(syms2) do\n"
        out += '            bind(m1 .. " + " .. s, action, opts)\n'
        out += "        end\n"
        out += "        for _, s in ipairs(syms1) do\n"
        out += '            bind(m2 .. " + " .. s, action, opts)\n'
        out += "        end\n"
        out += "    elseif #tokens >= 3 then\n"
        out += "        for i, target in ipairs(tokens) do\n"
        out += "            local u = string.upper(target)\n"
        out += "            local remaining = {}\n"
        out += "            for j, other in ipairs(tokens) do\n"
        out += "                if i ~= j then\n"
        out += "                    table.insert(remaining, string.upper(other))\n"
        out += "                end\n"
        out += "            end\n"
        out += '            local prefix = table.concat(remaining, " + ")\n'
        out += "            local syms = mod_syms[u] or { target }\n"
        out += "            for _, s in ipairs(syms) do\n"
        out += '                bind(prefix .. " + " .. s, action, opts)\n'
        out += "            end\n"
        out += "        end\n"
        out += "    end\n"
        out += "end\n\n"

        out += "-- Aplicativos e shell\n"
        out += 'bind_key("' + map.launcher + '", dsp.exec_cmd(qs .. "launcher toggle"))\n'
        out += 'bind_key("' + map.settings + '", dsp.exec_cmd(qs .. "settings toggle"))\n'
        out += 'bind_key("' + map.terminal + '", dsp.exec_cmd("ghostty"))\n'
        out += 'bind_key("' + map.island + '", dsp.exec_cmd(qs .. "island open"))\n'
        out += 'bind_key("' + map.recorder + '", dsp.exec_cmd(qs .. "recorder toggle"))\n'
        if (map.toggle_kb_layout) {
            out += 'bind_key("' + map.toggle_kb_layout + '", dsp.exec_cmd(switch_kb), fixo)\n'
        }
        out += "\n"

        out += "-- Sessão\n"
        if (map.session_lock) {
            out += 'bind_key("' + map.session_lock + '", dsp.exec_cmd(qs .. "lock lock"), fixo)\n'
        }
        out += 'bind_key("' + map.session_exit + '", dsp.exit())\n'
        out += 'bind_key("' + map.session_dpms + '", dsp.dpms({ action = "toggle" }))\n\n'

        out += "-- Volume e música\n"
        out += 'bind_key("' + map.volume_up + '", dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 3%+ && " .. qs .. "volume trigger"), repete)\n'
        out += 'bind_key("' + map.volume_down + '", dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%- && " .. qs .. "volume trigger"), repete)\n'
        out += 'bind_key("' + map.volume_mute + '", dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && " .. qs .. "volume trigger"), fixo)\n'
        out += 'bind_key("' + map.mic_mute + '", dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), fixo)\n'
        out += 'bind_key("' + map.play_pause + '", dsp.exec_cmd("playerctl play-pause"), fixo)\n'
        out += 'bind_key("' + map.media_next + '", dsp.exec_cmd("playerctl next"), fixo)\n'
        out += 'bind_key("' + map.media_prev + '", dsp.exec_cmd("playerctl previous"), fixo)\n\n'

        out += "-- Suporte direto a knobs e teclas de mídia física do teclado\n"
        out += 'if "' + map.volume_up + '" ~= "XF86AudioRaiseVolume" then\n'
        out += '    bind_key("XF86AudioRaiseVolume", dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 3%+ && " .. qs .. "volume trigger"), repete)\n'
        out += 'end\n'
        out += 'if "' + map.volume_down + '" ~= "XF86AudioLowerVolume" then\n'
        out += '    bind_key("XF86AudioLowerVolume", dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%- && " .. qs .. "volume trigger"), repete)\n'
        out += 'end\n'
        out += 'if "' + map.volume_mute + '" ~= "XF86AudioMute" then\n'
        out += '    bind_key("XF86AudioMute", dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && " .. qs .. "volume trigger"), fixo)\n'
        out += 'end\n\n'

        out += "-- Capturas de tela\n"
        out += 'bind_key("' + map.screenshot_area + '", dsp.exec_cmd([[sh -c \']] .. dir .. [[g=$(slurp) && grim -g "$g" "$f"\']]))\n'
        out += 'bind_key("' + map.screenshot_full + '", dsp.exec_cmd([[sh -c \']] .. dir .. [[grim "$f"\']]))\n\n'

        out += "-- Gerenciamento de Janelas\n"
        out += 'bind_key("' + map.close_window + '", dsp.window.close())\n'
        out += 'bind_key("' + map.toggle_maximize + '", dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))\n'
        out += 'bind_key("' + map.toggle_fullscreen + '", dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))\n'
        out += 'bind_key("' + map.toggle_floating + '", dsp.window.float({ action = "toggle" }))\n'
        out += 'bind_key("' + map.toggle_group + '", dsp.group.toggle())\n'
        out += 'bind_key("' + map.toggle_split + '", dsp.layout("togglesplit"))\n\n'

        out += "-- Navegação e Foco\n"
        out += 'bind_key("' + map.focus_left + '", dsp.focus({ direction = "l" }))\n'
        out += 'bind_key("' + map.focus_right + '", dsp.focus({ direction = "r" }))\n'
        out += 'bind_key("' + map.focus_up + '", dsp.focus({ direction = "u" }))\n'
        out += 'bind_key("' + map.focus_down + '", dsp.focus({ direction = "d" }))\n'
        out += 'bind_key("' + map.move_left + '", dsp.window.move({ direction = "l" }))\n'
        out += 'bind_key("' + map.move_right + '", dsp.window.move({ direction = "r" }))\n'
        out += 'bind_key("' + map.move_up + '", dsp.window.move({ direction = "u" }))\n'
        out += 'bind_key("' + map.move_down + '", dsp.window.move({ direction = "d" }))\n\n'

        out += "-- Áreas de trabalho\n"
        out += 'bind_key("' + map.ws_next + '", dsp.exec_cmd(ws .. "next"))\n'
        out += 'bind_key("' + map.ws_prev + '", dsp.exec_cmd(ws .. "prev"))\n'
        out += 'bind_key("' + map.ws_move_next + '", dsp.exec_cmd(ws .. "move-next"))\n'
        out += 'bind_key("' + map.ws_move_prev + '", dsp.exec_cmd(ws .. "move-prev"))\n\n'

        out += "-- Mover e redimensionar janelas com mouse (Super + botão esquerdo/direito)\n"
        out += 'bind_key("SUPER + mouse:272", dsp.window.drag(), { mouse = true, description = "Mover janela" })\n'
        out += 'bind_key("SUPER + mouse:273", dsp.window.resize(), { mouse = true, description = "Redimensionar janela" })\n\n'

        out += "-- Redimensionamento pelo teclado\n"
        out += "local r = { repeating = true }\n"
        out += 'bind_key("SUPER + minus", dsp.window.resize({ x = -100, y = 0, relative = true }), r)\n'
        out += 'bind_key("SUPER + equal", dsp.window.resize({ x = 100, y = 0, relative = true }), r)\n'
        out += 'bind_key("SUPER + SHIFT + minus", dsp.window.resize({ x = 0, y = -100, relative = true }), r)\n'
        out += 'bind_key("SUPER + SHIFT + equal", dsp.window.resize({ x = 0, y = 100, relative = true }), r)\n\n'

        out += "-- Áreas de trabalho diretas 1 a 9\n"
        for (let i = 1; i <= 9; i++) {
            let kFocus = (map && map["ws_" + i]) ? map["ws_" + i] : ("SUPER + " + i)
            let kMove = (map && map["ws_move_" + i]) ? map["ws_move_" + i] : ("SUPER + SHIFT + " + i)
            out += 'bind_key("' + kFocus + '", dsp.exec_cmd(ws .. "focus ' + i + '"))\n'
            out += 'bind_key("' + kMove + '", dsp.exec_cmd(ws .. "move ' + i + '"))\n'
        }

        return out
    }

    // Salva as alterações nos arquivos e recarrega o Hyprland
    function saveChanges() {
        let map = {}
        for (let i = 0; i < root.shortcutsList.length; i++) {
            let s = root.shortcutsList[i]
            map[s.id] = s.keys
        }

        // Salva shortcuts.json
        file.setText(JSON.stringify(map, null, 2))

        // Gera o script atajos.lua
        let luaContent = generateLuaScript(map)

        // Escreve os arquivos e recarrega o Hyprland
        saveProc.command = [
            "sh", "-c",
            'mkdir -p "$(dirname "$1")"; ' +
            'printf "%s" "$3" > "$1.tmp" && mv -f "$1.tmp" "$1"; ' +
            'if [ -d "$(dirname "$2")" ]; then printf "%s" "$3" > "$2.tmp" && mv -f "$2.tmp" "$2"; fi; ' +
            'SIG=$(ls -1t /run/user/$(id -u)/hypr 2>/dev/null | head -n1); export HYPRLAND_INSTANCE_SIGNATURE=$SIG; hyprctl reload',
            "save_shortcuts",
            root.atajosLuaPath,
            root.repoLuaPath,
            luaContent
        ]
        saveProc.running = true
        root.dirty = false
        root.saveSuccess = true
        successTimer.restart()
    }

    Timer {
        id: successTimer
        interval: 3500
        onTriggered: root.saveSuccess = false
    }

    Process {
        id: saveProc
        onExited: console.log("ShortcutsManager: atajos.lua gravado e Hyprland recarregado.")
    }
}
