# Minimo Shell

Shell minimalista do Minimo OS em Quickshell (QML), desenvolvida do zero.

## Estrutura
- `shell.qml` — raiz (`ShellRoot`), cria uma ilha por monitor.
- `Common/Theme.qml` — singleton com cores, raios, fontes, durações e tamanhos.
- `Island/Island.qml` — janela layer-shell (topo, camada overlay, `exclusiveZone: 0`), ocultamento automático e expansão.
- `Island/IslandCompact.qml` — estado compacto: avatar + hora (HH:mm).
- `Island/IslandMenu.qml` — menu: Terminal, Aplicativos, Captura, Bloquear, Encerrar sessão, Reiniciar, Desligar.
- `Island/MenuButton.qml` — botão ícone+legenda; ações de energia solicitam um segundo clique ("Tem certeza?").
- `assets/avatar.svg` — avatar original (carinha de bot).

## Comportamento
- Oculta-se 600 ms após o ponteiro sair; reaparece ao tocar a faixa de 3 px na borda superior.
- A máscara de input é UMA única região (`hoverZone`) que altera o tamanho: faixa oculta ↔ pílula visível.
- Clique na ilha: expande. Tecla Escape ou clique fora (`HyprlandFocusGrab`): colapsa.
- "Aplicativos" aparece apenas se houver `fuzzel` ou `rofi`; "Captura" apenas se houver `grim` (com `slurp` usa seleção de região). Capturas salvas em `~/Imagens/Capturas`.

## Testar
```bash
./run-preview.sh
```

## Design (redesign branco)
- Cartão branco com sombra difusa (MultiEffect), texto #0A0A0B / #636366 (escuro: #F5F5F7 / #AEAEB2), contraste AA, sem emojis.
- `Character/Character.qml`: mascote (esfera preta + olhos-cápsula) desenhado em QML. Olha para o cursor, pisca, respira, pula ao aparecer, gira e rebate ao abrir, gira de volta ao fechar.
- `Common/Cursor.qml`: posição global do cursor via `hyprctl cursorpos` (~25 Hz), somente enquanto o mascote estiver visível.
- `Common/Icon.qml` + `assets/icons/`: ícones de linha próprios (consulte `assets/icons/README.md`).
- `Common/MSlider.qml`: controles deslizantes estilo Central de Controle. `Island/MenuButton.qml`: botões circulares.

## Lançador (Super+B)
- `Launcher/Launcher.qml`: cartão estilo Spotlight; `Common/LauncherState.qml` expõe o IpcHandler `launcher` (`qs -p ~/Projetos/minimo-os/minimo-shell ipc call launcher toggle`).
- Atalho em `hypr/minimo.lua` (copiar para `~/.config/hypr/minimo.lua` e adicionar `require("minimo")` ao final de `hyprland.lua`).
- `Common/Apps.qml`: busca de aplicativos compartilhada pela ilha e pelo lançador.
