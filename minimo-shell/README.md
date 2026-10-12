# Minimo Shell

Shell mínima de Minimo OS en Quickshell (QML), escrita desde cero.

## Estructura
- `shell.qml` — raíz (`ShellRoot`), crea una isla por monitor.
- `Common/Theme.qml` — singleton con colores, radios, fuentes, duraciones y tamaños.
- `Island/Island.qml` — ventana layer-shell (arriba, capa overlay, `exclusiveZone: 0`), auto-ocultar y expansión.
- `Island/IslandCompact.qml` — estado compacto: avatar + hora (HH:mm).
- `Island/IslandMenu.qml` — menú: Terminal, Aplicaciones, Captura, Bloquear, Cerrar sesión, Reiniciar, Apagar.
- `Island/MenuButton.qml` — botón icono+etiqueta; las acciones de energía piden un segundo clic ("¿Seguro?").
- `assets/avatar.svg` — avatar original (carita de bot).

## Comportamiento
- Se esconde 600 ms después de que el puntero sale; reaparece al tocar la franja de 3 px del borde superior.
- La máscara de input es UNA sola región (`hoverZone`) que cambia de tamaño: franja oculta ↔ píldora visible.
- Clic en la isla: se expande. Escape o clic afuera (`HyprlandFocusGrab`): se colapsa.
- "Aplicaciones" aparece solo si hay `fuzzel` o `rofi`; "Captura" solo si hay `grim` (con `slurp` usa selección de región). Capturas en `~/Imágenes/Capturas`.

## Probar
```
./run-preview.sh
```

## Diseño (rediseño blanco)
- Tarjeta blanca con sombra difusa (MultiEffect), texto #0A0A0B / #8E8E93, sin emojis.
- `Character/Character.qml`: personaje (esfera negra + ojos-cápsula) dibujado en QML. Mira al cursor,
  parpadea, respira, salta al aparecer, gira y rebota al abrir, gira de vuelta al cerrar.
- `Common/Cursor.qml`: posición global del cursor vía `hyprctl cursorpos` (~25 Hz), solo mientras
  el personaje está visible.
- `Common/Icon.qml` + `assets/icons/`: iconos de línea propios (ver `assets/icons/README.md`).
- `Common/MSlider.qml`: sliders estilo Centro de Control. `Island/MenuButton.qml`: botones circulares.

## Lanzador (Super+B)
- `Launcher/Launcher.qml`: tarjeta tipo Spotlight; `Common/LauncherState.qml` expone el IpcHandler `launcher`
  (`qs -p ~/Proyectos/minimo-os/minimo-shell ipc call launcher toggle`).
- Atajo en `hypr/minimo.lua` (copiar a `~/.config/hypr/minimo.lua` y agregar `require("minimo")` al final de `hyprland.lua`).
- `Common/Apps.qml`: búsqueda de apps compartida por la isla y el lanzador.
