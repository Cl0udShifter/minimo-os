// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Gerenciador central do estado da Tela de Bloqueio (Lockscreen) do Minimo OS.
Singleton {
    id: root

    property bool locked: false
    property bool asleep: true
    property string user: Quickshell.env("USER") || "daniel"
    property string errorMsg: ""
    property bool authenticating: false
    property string currentPassword: ""

    signal shake()
    signal characterSquint()
    signal characterWorry()
    signal characterJoy()
    signal focusField()

    // Timer de inatividade na lockscreen: 15 segundos para voltar a dormir
    Timer {
        id: sleepTimer
        interval: 15000
        repeat: false
        onTriggered: {
            if (root.locked) {
                root.asleep = true
            }
        }
    }

    function wake() {
        if (!root.locked) return
        if (root.asleep) {
            root.asleep = false
        }
        sleepTimer.restart()
    }

    function lock() {
        errorMsg = ""
        currentPassword = ""
        authenticating = false
        asleep = true
        locked = true
        sleepTimer.stop()
        focusField()
    }

    function unlock() {
        sleepTimer.stop()
        errorMsg = ""
        currentPassword = ""
        authenticating = false
        locked = false
    }

    function toggle() {
        if (locked) unlock()
        else lock()
    }

    function notifyKeystroke() {
        wake()
        characterSquint()
    }

    function notifyWrongPassword(msg) {
        wake()
        currentPassword = ""
        authenticating = false
        errorMsg = msg || "Senha incorreta. Tente novamente."
        shake()
        characterWorry()
    }

    function notifySuccess() {
        wake()
        authenticating = false
        errorMsg = ""
        characterJoy()
        unlockTimer.restart()
    }

    // Pequeno delay para exibir o hop e sorriso do boneco antes de fechar a tela
    Timer {
        id: unlockTimer
        interval: 450
        repeat: false
        onTriggered: {
            root.unlock()
        }
    }

    signal submitRequested(string password)

    function submitPassword(pwd) {
        wake()
        submitRequested(pwd)
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock()
        }

        function unlock(): void {
            root.unlock()
        }

        function toggle(): void {
            root.toggle()
        }

        function wake(): void {
            root.wake()
        }

        function submit(password: string): void {
            root.submitPassword(password)
        }

        function status(): string {
            return root.locked ? "locked" : "unlocked"
        }
    }
}
