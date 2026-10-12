// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick

// Sistema de reacciones del personaje: animaciones con nombre, elegidas al azar
// con pesos y sin repetir las últimas dos. Animan propiedades "r*" del personaje
// (cuerpo) y modificadores de ojos; al terminar todo vuelve a su valor neutro y la
// mirada se mezcla de nuevo con el seguimiento del mouse.
Item {
    id: rx
    required property Item c
    property var history: []
    readonly property bool busy: current !== null && current.running
    property var current: null

    // Pesos del repertorio espontáneo. "yawn" sube cuando lleva rato quieto.
    function idleWeights(idleMs) {
        return { hop: 2, doubleHop: 1, spin: 1, giggle: 1.3, lookAround: 1.3, barrelRoll: 0.7,
                 surprise: 0.8, wink: 1.1, dizzy: 0.6, curious: 1.1, yawn: idleMs > 25000 ? 3 : 0.4 }
    }
    function pick(weights) {
        const ks = Object.keys(weights).filter(k => history.indexOf(k) < 0)
        let total = 0; for (const k of ks) total += weights[k]
        let x = Math.random() * total
        for (const k of ks) { x -= weights[k]; if (x <= 0) return k }
        return ks[ks.length - 1]
    }
    function playRandom(idleMs) { play(pick(idleWeights(idleMs))) }
    function playOpen() { play(pick({ spin: 1, greet: 1.2, happyBounce: 1.2 })) }
    function playClick() { play(pick({ giggle: 1.4, spin: 1, barrelRoll: 0.6, wink: 0.8 })) }

    readonly property var anims: ({ hop: hop, doubleHop: doubleHop, spin: spin, giggle: giggle, lookAround: lookAround,
        barrelRoll: barrelRoll, surprise: surprise, wink: wink, dizzy: dizzy, yawn: yawn, curious: curious,
        greet: greet, happyBounce: happyBounce, startled: startled, spinBack: spinBack })

    function play(name) {
        const a = anims[name]
        if (!a) return
        if (current && current.running) current.stop()
        reset()
        history = [name].concat(history).slice(0, 2)
        current = a
        a.start()
    }
    function reset() {
        c.rScale = 1; c.rX = 0; c.rY = 0; c.rRot = 0; c.roll = 0
        c.bounceY = 0; c.squashX = 1; c.squashY = 1
        c.lookOverride = 0; c.oX = 0; c.oY = 0
        c.eyeHMul = 1; c.eyeWMul = 1; c.openL = 1; c.openR = 1; c.arc = 0; c.wobble = 0; c.half = 1
    }

    // ---------- clásicas ----------
    SequentialAnimation {
        id: hop
        Squash { who: rx.c; sx: 1.12; sy: 0.88; toY: 0; ms: 80 }
        Squash { who: rx.c; sx: 0.94; sy: 1.06; toY: -rx.c.s * 0.22; ms: 160 }
        Squash { who: rx.c; sx: 1; sy: 1; toY: 0; ms: 220; ease: Easing.OutBack }
    }
    SequentialAnimation {
        id: doubleHop
        Squash { who: rx.c; sx: 1.12; sy: 0.88; toY: 0; ms: 80 }
        Squash { who: rx.c; sx: 0.94; sy: 1.06; toY: -rx.c.s * 0.2; ms: 160 }
        Squash { who: rx.c; sx: 1.1; sy: 0.9; toY: 0; ms: 150 }
        Squash { who: rx.c; sx: 0.92; sy: 1.08; toY: -rx.c.s * 0.28; ms: 180 }
        Squash { who: rx.c; sx: 1; sy: 1; toY: 0; ms: 240; ease: Easing.OutBack }
    }
    SequentialAnimation {
        id: spin
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "roll"; from: 0; to: 360; duration: 620; easing.type: Easing.InOutCubic }
            SequentialAnimation {
                Squash { who: rx.c; sx: 0.9; sy: 1.1; toY: -rx.c.s * 0.35; ms: 260 }
                Squash { who: rx.c; sx: 1; sy: 1; toY: 0; ms: 240 }
                Squash { who: rx.c; sx: 1.14; sy: 0.86; toY: 0; ms: 90 }
                Squash { who: rx.c; sx: 1; sy: 1; toY: 0; ms: 260; ease: Easing.OutBack }
            }
        }
        PropertyAction { target: rx.c; property: "roll"; value: 0 }
    }
    SequentialAnimation {
        id: spinBack
        NumberAnimation { target: rx.c; property: "roll"; from: 0; to: -360; duration: 380; easing.type: Easing.OutCubic }
        PropertyAction { target: rx.c; property: "roll"; value: 0 }
    }

    // ---------- Alejarse y reír ----------
    SequentialAnimation {
        id: giggle
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "rScale"; to: 0.8; duration: 260; easing.type: Easing.OutCubic }
            NumberAnimation { target: rx.c; property: "rY"; to: -rx.c.s * 0.08; duration: 260; easing.type: Easing.OutCubic }
            NumberAnimation { target: rx.c; property: "arc"; to: 1; duration: 180 }
        }
        Repeater3 { target: rx.c; amp: 9; drop: rx.c.s * 0.06 }
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "rScale"; to: 1; duration: 340; easing.type: Easing.OutBack }
            NumberAnimation { target: rx.c; property: "rY"; to: 0; duration: 340; easing.type: Easing.OutBack }
            NumberAnimation { target: rx.c; property: "rRot"; to: 0; duration: 200 }
            SequentialAnimation { PauseAnimation { duration: 160 } NumberAnimation { target: rx.c; property: "arc"; to: 0; duration: 180 } }
        }
    }

    // ---------- Giro de cabeza ----------
    SequentialAnimation {
        id: lookAround
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "lookOverride"; to: 1; duration: 200 }
            NumberAnimation { target: rx.c; property: "oX"; from: 0; to: -0.95; duration: 420; easing.type: Easing.InOutSine }
            NumberAnimation { target: rx.c; property: "rRot"; to: -7; duration: 420; easing.type: Easing.InOutSine }
            NumberAnimation { target: rx.c; property: "rX"; to: -rx.c.s * 0.04; duration: 420; easing.type: Easing.InOutSine }
        }
        PauseAnimation { duration: 260 }
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "oX"; to: 0.95; duration: 760; easing.type: Easing.InOutCubic }
            NumberAnimation { target: rx.c; property: "rRot"; to: 7; duration: 760; easing.type: Easing.InOutCubic }
            NumberAnimation { target: rx.c; property: "rX"; to: rx.c.s * 0.04; duration: 760; easing.type: Easing.InOutCubic }
        }
        PauseAnimation { duration: 300 }
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "oX"; to: 0; duration: 380; easing.type: Easing.OutCubic }
            NumberAnimation { target: rx.c; property: "rRot"; to: 0; duration: 380; easing.type: Easing.OutBack }
            NumberAnimation { target: rx.c; property: "rX"; to: 0; duration: 380; easing.type: Easing.OutCubic }
        }
        NumberAnimation { target: rx.c; property: "lookOverride"; to: 0; duration: 300 }
    }

    // ---------- Voltereta ----------
    SequentialAnimation {
        id: barrelRoll
        Squash { who: rx.c; sx: 1.15; sy: 0.85; toY: 0; ms: 110 }
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "rRot"; from: 0; to: 360; duration: 640; easing.type: Easing.InOutQuad }
            SequentialAnimation {
                Squash { who: rx.c; sx: 0.95; sy: 1.05; toY: -rx.c.s * 0.45; ms: 320; ease: Easing.OutQuad }
                Squash { who: rx.c; sx: 1; sy: 1; toY: 0; ms: 320; ease: Easing.InQuad }
            }
        }
        PropertyAction { target: rx.c; property: "rRot"; value: 0 }
        Squash { who: rx.c; sx: 1.16; sy: 0.84; toY: 0; ms: 90 }
        Squash { who: rx.c; sx: 1; sy: 1; toY: 0; ms: 280; ease: Easing.OutBack }
    }

    // ---------- Sorpresa ----------
    SequentialAnimation {
        id: surprise
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "eyeHMul"; to: 1.3; duration: 120; easing.type: Easing.OutBack }
            NumberAnimation { target: rx.c; property: "eyeWMul"; to: 1.35; duration: 120; easing.type: Easing.OutBack }
            Squash { who: rx.c; sx: 0.88; sy: 1.14; toY: -rx.c.s * 0.18; ms: 140 }
            NumberAnimation { target: rx.c; property: "rScale"; to: 0.92; duration: 140 }
        }
        Squash { who: rx.c; sx: 1.08; sy: 0.92; toY: 0; ms: 140 }
        Squash { who: rx.c; sx: 1; sy: 1; toY: 0; ms: 200; ease: Easing.OutBack }
        PauseAnimation { duration: 500 }
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "eyeHMul"; to: 1; duration: 300; easing.type: Easing.InOutSine }
            NumberAnimation { target: rx.c; property: "eyeWMul"; to: 1; duration: 300; easing.type: Easing.InOutSine }
            NumberAnimation { target: rx.c; property: "rScale"; to: 1; duration: 300; easing.type: Easing.OutBack }
        }
    }

    // ---------- Guiño ----------
    SequentialAnimation {
        id: wink
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "openR"; to: 0.12; duration: 110; easing.type: Easing.InQuad }
            NumberAnimation { target: rx.c; property: "rRot"; to: 8; duration: 180; easing.type: Easing.OutCubic }
            Squash { who: rx.c; sx: 1.06; sy: 0.94; toY: 0; ms: 160 }
        }
        PauseAnimation { duration: 380 }
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "openR"; to: 1; duration: 160; easing.type: Easing.OutBack }
            NumberAnimation { target: rx.c; property: "rRot"; to: 0; duration: 300; easing.type: Easing.OutBack }
            Squash { who: rx.c; sx: 1; sy: 1; toY: 0; ms: 260; ease: Easing.OutBack }
        }
    }

    // ---------- Mareo ----------
    SequentialAnimation {
        id: dizzy
        NumberAnimation { target: rx.c; property: "roll"; from: 0; to: 720; duration: 700; easing.type: Easing.InOutCubic }
        PropertyAction { target: rx.c; property: "roll"; value: 0 }
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "wobble"; to: 0.5; duration: 160 }
            NumberAnimation { target: rx.c; property: "wobblePh"; from: 0; to: Math.PI * 6; duration: 1500; easing.type: Easing.OutSine }
            SequentialAnimation {
                NumberAnimation { target: rx.c; property: "rRot"; to: 10; duration: 300; easing.type: Easing.InOutSine }
                NumberAnimation { target: rx.c; property: "rRot"; to: -8; duration: 400; easing.type: Easing.InOutSine }
                NumberAnimation { target: rx.c; property: "rRot"; to: 5; duration: 400; easing.type: Easing.InOutSine }
                NumberAnimation { target: rx.c; property: "rRot"; to: 0; duration: 400; easing.type: Easing.OutSine }
            }
            SequentialAnimation { PauseAnimation { duration: 1100 } NumberAnimation { target: rx.c; property: "wobble"; to: 0; duration: 400 } }
        }
    }

    // ---------- Bostezo / estirarse ----------
    SequentialAnimation {
        id: yawn
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "half"; to: 0.4; duration: 400; easing.type: Easing.InOutSine }
            Squash { who: rx.c; sx: 0.86; sy: 1.2; toY: -rx.c.s * 0.04; ms: 700; ease: Easing.InOutSine }
            NumberAnimation { target: rx.c; property: "lookOverride"; to: 1; duration: 400 }
            NumberAnimation { target: rx.c; property: "oY"; to: -0.5; duration: 700; easing.type: Easing.InOutSine }
        }
        PauseAnimation { duration: 350 }
        ParallelAnimation {
            Squash { who: rx.c; sx: 1.14; sy: 0.86; toY: 0; ms: 260; ease: Easing.OutQuad }
            NumberAnimation { target: rx.c; property: "oY"; to: 0.2; duration: 300 }
        }
        ParallelAnimation {
            Squash { who: rx.c; sx: 1; sy: 1; toY: 0; ms: 380; ease: Easing.OutBack }
            NumberAnimation { target: rx.c; property: "half"; to: 1; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { target: rx.c; property: "lookOverride"; to: 0; duration: 600 }
        }
    }

    // ---------- Curioso ----------
    SequentialAnimation {
        id: curious
        property real side: 1
        ScriptAction { script: curious.side = Math.random() < 0.5 ? -1 : 1 }
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "rRot"; to: 12 * curious.side; duration: 380; easing.type: Easing.OutBack }
            NumberAnimation { target: rx.c; property: "rX"; to: rx.c.s * 0.06 * curious.side; duration: 380; easing.type: Easing.OutCubic }
            NumberAnimation { target: rx.c; property: "lookOverride"; to: 1; duration: 260 }
            NumberAnimation { target: rx.c; property: "oX"; to: 0.95 * curious.side; duration: 380; easing.type: Easing.OutCubic }
            NumberAnimation { target: rx.c; property: "oY"; to: -0.2; duration: 380 }
            NumberAnimation { target: rx.c; property: "eyeHMul"; to: 1.1; duration: 300 }
        }
        PauseAnimation { duration: 900 }
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "rRot"; to: 0; duration: 420; easing.type: Easing.OutBack }
            NumberAnimation { target: rx.c; property: "rX"; to: 0; duration: 420 }
            NumberAnimation { target: rx.c; property: "lookOverride"; to: 0; duration: 420 }
            NumberAnimation { target: rx.c; property: "eyeHMul"; to: 1; duration: 300 }
        }
    }

    // ---------- Saludo (al abrir) ----------
    SequentialAnimation {
        id: greet
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "arc"; to: 1; duration: 160 }
            Squash { who: rx.c; sx: 0.92; sy: 1.08; toY: -rx.c.s * 0.18; ms: 200 }
        }
        NumberAnimation { target: rx.c; property: "rRot"; to: 14; duration: 140; easing.type: Easing.OutQuad }
        NumberAnimation { target: rx.c; property: "rRot"; to: -14; duration: 200; easing.type: Easing.InOutSine }
        NumberAnimation { target: rx.c; property: "rRot"; to: 12; duration: 200; easing.type: Easing.InOutSine }
        NumberAnimation { target: rx.c; property: "rRot"; to: -8; duration: 180; easing.type: Easing.InOutSine }
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "rRot"; to: 0; duration: 220; easing.type: Easing.OutBack }
            Squash { who: rx.c; sx: 1; sy: 1; toY: 0; ms: 260; ease: Easing.OutBack }
        }
        NumberAnimation { target: rx.c; property: "arc"; to: 0; duration: 200 }
    }

    // ---------- Rebote feliz (al abrir) ----------
    SequentialAnimation {
        id: happyBounce
        NumberAnimation { target: rx.c; property: "arc"; to: 1; duration: 120 }
        Squash { who: rx.c; sx: 1.12; sy: 0.88; toY: 0; ms: 70 }
        Squash { who: rx.c; sx: 0.94; sy: 1.06; toY: -rx.c.s * 0.2; ms: 140 }
        Squash { who: rx.c; sx: 1.1; sy: 0.9; toY: 0; ms: 120 }
        Squash { who: rx.c; sx: 0.94; sy: 1.06; toY: -rx.c.s * 0.16; ms: 130 }
        Squash { who: rx.c; sx: 1.08; sy: 0.92; toY: 0; ms: 110 }
        Squash { who: rx.c; sx: 0.96; sy: 1.04; toY: -rx.c.s * 0.1; ms: 110 }
        Squash { who: rx.c; sx: 1; sy: 1; toY: 0; ms: 220; ease: Easing.OutBack }
        NumberAnimation { target: rx.c; property: "arc"; to: 0; duration: 200 }
    }

    // ---------- Sobresalto (mouse muy rápido) ----------
    SequentialAnimation {
        id: startled
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "eyeHMul"; to: 1.25; duration: 90 }
            NumberAnimation { target: rx.c; property: "eyeWMul"; to: 1.25; duration: 90 }
            Squash { who: rx.c; sx: 0.9; sy: 1.1; toY: -rx.c.s * 0.12; ms: 110 }
        }
        ParallelAnimation {
            Squash { who: rx.c; sx: 1; sy: 1; toY: 0; ms: 220; ease: Easing.OutBack }
            NumberAnimation { target: rx.c; property: "wobble"; to: 0.25; duration: 120 }
            NumberAnimation { target: rx.c; property: "wobblePh"; from: 0; to: Math.PI * 4; duration: 700 }
        }
        ParallelAnimation {
            NumberAnimation { target: rx.c; property: "wobble"; to: 0; duration: 300 }
            NumberAnimation { target: rx.c; property: "eyeHMul"; to: 1; duration: 300 }
            NumberAnimation { target: rx.c; property: "eyeWMul"; to: 1; duration: 300 }
        }
    }
}
