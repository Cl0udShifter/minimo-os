// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import QtQuick.Effects
import "../Common"

// Personaje de Minimo OS (v2, según reference2): esfera negra mate con dos ojos
// pastilla blancos, PARALELOS. La "cara" (el par de ojos) se desliza por la
// superficie de la esfera hacia donde mira, con proyección esférica: cerca del borde
// los ojos se acortan en la dirección radial y el par se inclina en las diagonales.
// Además: parpadeo, respiración, trucos espontáneos, giro al abrir/cerrar, baile con
// música (cava) y modo dormir tras un minuto sin mover el mouse.
Item {
    id: c
    property int size: 22
    property bool active: true          // anima solo si está visible
    width: size; height: size

    readonly property real s: size
    readonly property real r: size / 2

    // ===== Mirada =====
    // look: vector en el disco unidad (0,0 = te mira de frente; |look| = 1 = máximo giro).
    property real lookX: 0
    property real lookY: 0
    readonly property bool tracking: Cursor.ok && Cursor.x >= 0
    onActiveChanged: active ? Cursor.acquire() : Cursor.release()
    Component.onCompleted: if (active) Cursor.acquire()
    Component.onDestruction: { if (active) Cursor.release(); if (dancing) Media.release() }

    property real idleX: 0
    property real idleY: 0

    function updateLook() {
        if (!active) return
        if (asleep) { lookX = 0; lookY = 0.75; return }
        const idle = !tracking || Date.now() - Cursor.lastMove > 4000
        if (idle) { lookX = idleX; lookY = idleY; return }
        const win = c.Window.window
        const p = c.mapToItem(null, width / 2, height / 2)
        const sx = (win && win.screen) ? win.screen.x : 0
        const sy = (win && win.screen) ? win.screen.y : 0
        const dx = Cursor.x - (sx + p.x), dy = Cursor.y - (sy + p.y)
        // Escala anisotrópica: la isla está pegada al borde superior, así que hacia
        // arriba hay poco recorrido; se normaliza con la distancia al borde.
        const nx = dx / 320
        const ny = dy < 0 ? dy / Math.max(24, sy + p.y) : dy / 320
        const m = Math.sqrt(nx * nx + ny * ny)
        const k = m > 1 ? 1 / m : 1             // cerca = te mira de frente
        lookX = nx * k; lookY = ny * k
    }
    Connections {
        target: Cursor
        function onXChanged() { c.cursorMoved() }
        function onYChanged() { c.cursorMoved() }
    }
    // Velocidad del mouse: si se mueve muy rápido, sobresalto (con enfriamiento).
    property real _px: -1
    property real _py: -1
    property real _pt: 0
    property real _lastStartle: 0
    function cursorMoved() {
        updateLook()
        const now = Date.now()
        if (_pt > 0 && now - _pt < 200) {
            const d = Math.hypot(Cursor.x - _px, Cursor.y - _py)
            const v = d / Math.max(16, now - _pt) * 1000          // px/s
            if (v > 4500 && now - _lastStartle > 5000 && !reactions.busy && active && !dancing) {
                _lastStartle = now; reactions.play("startled")
            }
        }
        _px = Cursor.x; _py = Cursor.y; _pt = now
    }

    Timer {
        // mirada distraída ocasional cuando el mouse está quieto (despierto)
        running: c.active && !c.asleep; repeat: true; interval: 2600
        onTriggered: {
            if (Math.random() < 0.5) { const t = Math.random() * Math.PI * 2, m = 0.3 + Math.random() * 0.5; c.idleX = Math.cos(t) * m; c.idleY = Math.sin(t) * m }
            else { c.idleX = 0; c.idleY = 0 }
            c.updateLook()
        }
    }

    // Mirada suavizada con resorte (más lenta al dormirse).
    property real eyeX: lookX
    property real eyeY: lookY
    // Mirada efectiva: seguimiento del mouse mezclado con la de la reacción (override)
    // y un bamboleo circular opcional (mareo).
    readonly property real bX: eyeX * (1 - lookOverride) + oX * lookOverride + wobble * Math.cos(wobblePh)
    readonly property real bY: eyeY * (1 - lookOverride) + oY * lookOverride + wobble * Math.sin(wobblePh)
    // Mirada forzada desde afuera (ipc "character look"), independiente de las reacciones.
    property real gX: 0
    property real gY: 0
    property real gOn: 0
    Behavior on gOn { NumberAnimation { duration: 250 } }
    readonly property real fX: bX * (1 - gOn) + gX * gOn
    readonly property real fY: bY * (1 - gOn) + gY * gOn
    Behavior on eyeX { SpringAnimation { spring: c.asleep ? 0.6 : 3.2; damping: c.asleep ? 0.9 : 0.32; epsilon: 0.003 } }
    Behavior on eyeY { SpringAnimation { spring: c.asleep ? 0.6 : 3.2; damping: c.asleep ? 0.9 : 0.32; epsilon: 0.003 } }

    // ===== Geometría de la cara (proyección esférica) =====
    // Medidas tomadas de reference2 (esfera de diámetro D): ojo 0.149D x 0.3375D,
    // separación entre centros 0.30D; desplazamiento máximo ≈ 0.62R.
    readonly property real eyeW: s * 0.149
    readonly property real eyeH: s * 0.3375
    readonly property real eyeSep: s * 0.149        // medio desplazamiento entre centros
    // Proyección esférica: la mirada se traduce en yaw/pitch de la cabeza. Cada ojo
    // es un punto sobre la esfera (yaw ± separación angular); su posición en pantalla
    // es R·sin(ángulo) — se mueve menos cerca del borde — y se escorza con cos(yaw)
    // en ancho y cos(pitch) en alto. El ojo más cercano al borde se comprime más y,
    // si pasa la silueta, queda recortado por la máscara circular de la cara.
    readonly property real lookLen: Math.sqrt(fX * fX + fY * fY)
    readonly property real gk: lookLen > 1 ? 1 / lookLen : 1          // limitar al disco unidad
    readonly property real yaw: fX * gk * 0.80                        // rad (máx ≈ 46°)
    readonly property real pitch: fY * gk * (fY > 0 ? 0.66 : 0.6)     // arriba hay menos lugar (isla)
    readonly property real eyeAng: Math.asin(Math.min(0.9, eyeSep / r))   // separación angular de cada ojo
    readonly property real sinP: Math.sin(pitch)
    readonly property real cosP: Math.cos(pitch)
    // Leve rotación siguiendo la curvatura en diagonales ("//" mirando arriba-izquierda).
    readonly property real tilt: Math.max(-30, Math.min(30, 120 * Math.sin(yaw) * sinP))

    // ===== Estados: parpadeo, dormir, baile =====
    property real blink: 1
    SequentialAnimation {
        id: blinkAnim
        NumberAnimation { target: c; property: "blink"; to: 0.08; duration: 70 }
        NumberAnimation { target: c; property: "blink"; to: 1; duration: 110 }
    }
    Timer {
        running: c.active && !c.asleep; repeat: true
        interval: 3200
        onTriggered: { interval = 2200 + Math.random() * 3200; blinkAnim.restart() }
    }

    // Dormir: cuando toda la PC está inactiva (IdleState, ext-idle-notify), salvo si
    // suena música (baila) o se está grabando. Al volver la actividad: estira y parpadea.
    readonly property bool asleep: IdleState.sleeping && !Media.playing && !Recorder.recording
    property real sleepy: asleep ? 1 : 0
    Behavior on sleepy { NumberAnimation { duration: c.asleep ? 2200 : 250; easing.type: Easing.InOutSine } }
    onAsleepChanged: { updateLook(); if (!asleep && active) wakeAnim.restart() }
    function wake() { IdleState.wake() }
    readonly property bool dancing: active && Media.playing
    onDancingChanged: dancing ? Media.acquire() : Media.release()
    readonly property real amp: Media.hasLevel ? 0.35 + Math.min(1, Media.level * 1.6) : 1
    property real beat: 0
    property real sway: 0
    NumberAnimation on beat { running: c.dancing; loops: Animation.Infinite; from: 0; to: 1; duration: 500 }
    NumberAnimation on sway { running: c.dancing; loops: Animation.Infinite; from: 0; to: 1; duration: 1000 }
    property real danceOn: dancing ? 1 : 0
    Behavior on danceOn { NumberAnimation { duration: 250 } }
    readonly property real hopT: Math.sin(Math.PI * beat)
    readonly property real danceY: -hopT * s * 0.16 * amp * danceOn
    readonly property real danceSy: 1 + danceOn * amp * (0.06 * hopT - 0.13 * Math.pow(1 - hopT, 3))
    readonly property real danceSx: 1 + danceOn * amp * (0.11 * Math.pow(1 - hopT, 3) - 0.04 * hopT)
    readonly property real danceRot: danceOn * amp * 7 * Math.sin(2 * Math.PI * sway)
    property real happy: dancing ? 0.62 : 1
    Behavior on happy { NumberAnimation { duration: 220 } }

    // Apertura final de los ojos (1 = abiertos; dormido = pastilla fina).
    readonly property real openness: blink * happy * half * (1 - 0.9 * sleepy)

    // ===== Reacciones (ver Reactions.qml) =====
    function spin() { if (active) reactions.playOpen() }
    function spinBack() { if (active) reactions.play("spinBack") }
    function hop() { if (active && !asleep && !reactions.busy) reactions.play("hop") }
    function react(name) { if (active && !asleep) reactions.play(name) }
    function clicked() { if (!active) return; if (asleep) wake(); else reactions.playClick() }

    // Propiedades que animan las reacciones (valores neutros).
    property real roll: 0          // giro de la cara
    property real bounceY: 0
    property real squashX: 1
    property real squashY: 1
    property real breath: 1
    property real rScale: 1        // escala de todo el cuerpo
    property real rX: 0            // desplazamiento del cuerpo
    property real rY: 0
    property real rRot: 0          // inclinación/giro del cuerpo
    property real lookOverride: 0  // 0 = mouse, 1 = mirada de la reacción (oX, oY)
    property real oX: 0
    property real oY: 0
    property real eyeHMul: 1       // ojos más altos/anchos (sorpresa)
    property real eyeWMul: 1
    property real openL: 1         // apertura por ojo (guiño)
    property real openR: 1
    property real arc: 0           // ojos felices "^ ^" (0..1)
    property real wobble: 0        // radio del bamboleo de la mirada (mareo)
    property real wobblePh: 0
    property real half: 1          // ojos entrecerrados (bostezo)

    Reactions { id: reactions; c: c }

    Connections {
        target: CharacterBus
        function onReact(name) { c.react(name) }
        function onGaze(x, y, ms) { if (!c.active) return; c.gX = x; c.gY = y; c.gOn = 1; gazeHold.interval = ms; gazeHold.restart() }
    }

    Timer {
        // reacción espontánea cada 6–14 s (despierto, visible y sin música)
        running: c.active && !c.asleep && !c.dancing; repeat: true
        interval: 9000
        onTriggered: {
            interval = 6000 + Math.random() * 8000
            if (!reactions.busy) reactions.playRandom(Date.now() - Cursor.lastMove)
        }
    }
    Timer { id: gazeHold; onTriggered: c.gOn = 0 }
    SequentialAnimation {
        // al despertar: se estira, se aplasta un poco y parpadea
        id: wakeAnim
        Squash { who: c; sx: 0.88; sy: 1.14; toY: -c.s * 0.06; ms: 260; ease: Easing.OutQuad }
        Squash { who: c; sx: 1.08; sy: 0.92; toY: 0; ms: 180 }
        Squash { who: c; sx: 1; sy: 1; toY: 0; ms: 240; ease: Easing.OutBack }
        ScriptAction { script: blinkAnim.restart() }
        PauseAnimation { duration: 260 }
        ScriptAction { script: blinkAnim.restart() }
    }
    SequentialAnimation {
        // respiración (más lenta y profunda dormido)
        running: c.active; loops: Animation.Infinite
        NumberAnimation { target: c; property: "breath"; to: c.asleep ? 1.05 : 1.035; duration: c.asleep ? 3000 : 1800; easing.type: Easing.InOutSine }
        NumberAnimation { target: c; property: "breath"; to: 1.0; duration: c.asleep ? 3000 : 1800; easing.type: Easing.InOutSine }
    }

    // ===== Dibujo =====
    Item {
        id: body
        width: c.s; height: c.s
        rotation: c.danceRot + c.rRot
        transform: [
            Scale { origin.x: c.s / 2; origin.y: c.s; xScale: c.squashX * c.breath * c.danceSx; yScale: c.squashY * c.breath * c.danceSy },
            Scale { origin.x: c.s / 2; origin.y: c.s / 2; xScale: c.rScale; yScale: c.rScale },
            Translate { x: c.rX; y: c.bounceY + c.danceY + c.rY }
        ]

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.sphere
            antialiasing: true
        }
        // Máscara circular: los ojos que pasan la silueta quedan recortados.
        Item {
            id: faceMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            layer.smooth: true
            Rectangle { anchors.fill: parent; radius: width / 2; antialiasing: true }
        }
        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect { maskEnabled: true; maskSource: faceMask; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0 }

        // Cara: gira entera con los trucos (roll). Los ojos son siempre paralelos.
        Item {
            anchors.fill: parent
            rotation: c.roll
            Repeater {
                model: [-1, 1]
                delegate: Item {
                    id: eye
                    required property int modelData
                    // Punto del ojo sobre la esfera.
                    readonly property real yw: c.yaw + modelData * c.eyeAng
                    readonly property real cosY: Math.cos(yw)
                    readonly property real px: c.r * Math.sin(yw) * c.cosP
                    readonly property real py: c.r * c.sinP
                    // giro del par por `tilt` alrededor del centro de la cara
                    readonly property real t: c.tilt * Math.PI / 180
                    readonly property real fcx: c.r * Math.sin(c.yaw) * c.cosP     // centro de la cara
                    readonly property real dx: px - fcx
                    readonly property real cx: c.r + fcx + dx * Math.cos(t)
                    readonly property real cy: c.r + py + dx * Math.sin(t)
                    // escorzo (pastilla siempre): ancho por cos(yaw) del ojo, alto por cos(pitch)
                    readonly property real kB: Math.max(0.12, cosY)
                    readonly property real kA: Math.max(0.2, c.cosP)
                    readonly property real own: modelData < 0 ? c.openL : c.openR
                    readonly property real w: c.eyeW * kB * c.eyeWMul
                    opacity: cosY > 0 ? 1 : 0
                    x: cx; y: cy
                    rotation: c.tilt

                    // Ojo pastilla.
                    Rectangle {
                        width: eye.w
                        height: Math.max(width * 0.35, c.eyeH * eye.kA * c.eyeHMul * c.openness * eye.own)
                        radius: Math.min(width, height) / 2
                        x: -width / 2; y: -height / 2
                        color: Theme.eye
                        antialiasing: true
                        opacity: 1 - c.arc
                    }
                    // Ojo feliz "^": dos pastillas cortas que se juntan arriba.
                    Repeater {
                        model: [-1, 1]
                        delegate: Rectangle {
                            required property int modelData
                            visible: c.arc > 0.01
                            opacity: c.arc
                            width: eye.w * 0.85
                            height: c.eyeH * 0.48
                            radius: width / 2
                            x: -width / 2 + modelData * c.eyeH * 0.13
                            y: -height / 2 + c.eyeH * 0.02
                            rotation: modelData * 38
                            transformOrigin: Item.Center
                            color: Theme.eye
                            antialiasing: true
                        }
                    }
                }
            }
        }
        }
    }
}
