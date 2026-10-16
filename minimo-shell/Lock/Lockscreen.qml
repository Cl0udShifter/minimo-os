// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.UPower
import "../Common"
import "../Character"

// Tela de Bloqueio (Lockscreen) do Minimo OS:
// - Fundo: Wallpaper atual com desfoque profundo (blur) e escurecimento suave.
// - Hub Central: Relógio grande moderno, data por extenso em português.
// - Bonequinho do Notch destacado (tamanho 80px):
//     * Dormindo: Olhos fechados, respiração lenta e letrinhas 'Zzz' flutuantes.
//     * Ao acordar: Abre os olhinhos e olha fixo para a pílula de senha.
//     * Ao digitar: Franze os olhinhos suavemente a cada tecla.
//     * Erro de senha: Shake da pílula, borda vermelha e reação assustada (worry).
//     * Sucesso: Sorri alegremente, dá um pulinho (hop) e desbloqueia com fade suave.
//     * Retorno ao sono: 15 segundos sem atividade fecha os olhos e volta a dormir.
// - Rodapé discreto com layout do teclado ativo (BR/US) e bateria.
// - Autenticação nativa com PAM (Quickshell.Services.Pam).
PanelWindow {
    id: win

    readonly property bool locked: LockscreenState.locked
    property real t: locked ? 1 : 0
    Behavior on t { NumberAnimation { duration: win.locked ? 240 : 340; easing.type: Easing.OutCubic } }

    visible: locked || t > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "black"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "minimo-lockscreen"
    WlrLayershell.keyboardFocus: locked ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property real shakeOffset: 0
    property string pendingPassword: ""

    onLockedChanged: {
        if (locked) {
            passInput.text = ""
            pendingPassword = ""
            shakeOffset = 0
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 50
        onTriggered: {
            passInput.forceActiveFocus()
        }
    }

    SequentialAnimation {
        id: shakeAnim
        alwaysRunToEnd: true
        NumberAnimation { target: win; property: "shakeOffset"; to: -16; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: win; property: "shakeOffset"; to: 16; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: win; property: "shakeOffset"; to: -11; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: win; property: "shakeOffset"; to: 11; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: win; property: "shakeOffset"; to: -5; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: win; property: "shakeOffset"; to: 5; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: win; property: "shakeOffset"; to: 0; duration: 45; easing.type: Easing.OutQuad }
    }

    Connections {
        target: LockscreenState
        function onShake() {
            shakeAnim.restart()
        }
        function onFocusField() {
            passInput.text = ""
            focusTimer.restart()
        }
        function onCharacterSquint() {
            character.squint = 1
            squintRelax.restart()
        }
        function onCharacterWorry() {
            character.mood = "worried"
            worryReset.restart()
        }
        function onCharacterJoy() {
            character.mood = ""
            character.smile = 1
            character.hop()
        }
        function onSubmitRequested(pwd) {
            LockscreenState.wake()
            passInput.text = pwd
            win.doUnlock()
        }
    }

    Timer {
        id: squintRelax
        interval: 320
        onTriggered: character.squint = 0
    }

    Timer {
        id: worryReset
        interval: 3500
        onTriggered: {
            if (character.mood === "worried") character.mood = ""
        }
    }

    // Interceptação de PAM para desbloqueio
    PamContext {
        id: pam
        user: LockscreenState.user
        config: "system-auth"
    }

    Connections {
        target: pam
        function onCompleted(result) {
            if (result === PamResult.Success) {
                LockscreenState.notifySuccess()
            } else {
                passInput.text = ""
                focusTimer.restart()
                LockscreenState.notifyWrongPassword("Senha incorreta. Tente novamente.")
            }
        }
        function onError(err) {
            passInput.text = ""
            focusTimer.restart()
            LockscreenState.notifyWrongPassword("Erro de autenticação.")
        }
        function onResponseRequiredChanged() {
            if (pam.responseRequired && win.pendingPassword !== "") {
                pam.respond(win.pendingPassword)
                win.pendingPassword = ""
            }
        }
    }

    function doUnlock() {
        LockscreenState.wake()
        if (LockscreenState.authenticating) return
        const pwd = LockscreenState.currentPassword || passInput.text
        if (pwd.length === 0) {
            LockscreenState.notifyWrongPassword("Digite sua senha para desbloquear.")
            return
        }
        LockscreenState.authenticating = true
        LockscreenState.errorMsg = ""
        win.pendingPassword = pwd
        pam.start()
    }

    // Fundo: Wallpaper com Desfoque Profundo (MultiEffect com cache de camada)
    Item {
        anchors.fill: parent
        opacity: win.t
        layer.enabled: true
        layer.smooth: true

        Image {
            id: bgWall
            anchors.fill: parent
            source: DisplayState.wallpaper ? "file://" + DisplayState.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            sourceSize: Qt.size(win.width, win.height)
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: bgWall
            blurEnabled: true
            blur: 1.0
            blurMax: 48
            saturation: 0.85
            brightness: -0.15
        }

        // Camada de escurecimento suave para contraste perfeito
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.42)
        }
    }

    Timer {
        id: idleGazeTimer
        interval: 2200
        repeat: false
        onTriggered: {
            if (!LockscreenState.asleep) {
                character.gOn = 1
            }
        }
    }

    // Área global de captura de clique e movimento do mouse
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: mouse => {
            LockscreenState.wake()
            idleGazeTimer.restart()
            if (character.gOn !== 0) character.gOn = 0
            character.trackDirect(mouse.x, mouse.y)
        }
        onPressed: {
            LockscreenState.wake()
            passInput.forceActiveFocus()
        }
    }

    // Hub Centralizado
    Column {
        anchors.centerIn: parent
        spacing: 34
        width: Math.min(parent.width - 40, 480)
        opacity: win.t
        scale: 0.95 + 0.05 * win.t

        // 1. Relógio Grande e Data
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: "#FFFFFF"
                font.family: Theme.font
                font.pixelSize: 84
                font.weight: Font.DemiBold
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    const t = clock.date.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM")
                    return t.charAt(0).toUpperCase() + t.slice(1)
                }
                color: Qt.rgba(1, 1, 1, 0.75)
                font.family: Theme.font
                font.pixelSize: 17
                font.weight: Font.Normal
            }
        }

        // 2. Bonequinho do Notch Ampliado com 'Zzz' Flutuante
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 88
            height: 88

            Character {
                id: character
                anchors.centerIn: parent
                size: 80
                active: win.visible
                customAsleep: LockscreenState.asleep
                directTracking: true
                gX: 0
                gY: 0.85 // Olhar direcionado para baixo, para a pílula de senha
                gOn: 0
            }

            ZzzParticles {
                anchors.left: parent.horizontalCenter
                anchors.leftMargin: 20
                anchors.bottom: parent.verticalCenter
                anchors.bottomMargin: 14
                active: LockscreenState.asleep
            }
        }

        // 3. Campo de Senha em Pílula
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            x: win.shakeOffset

            Rectangle {
                id: passField
                width: 320
                height: 48
                radius: 24
                color: Qt.rgba(0.12, 0.12, 0.14, 0.78)
                border.width: 1
                border.color: LockscreenState.errorMsg !== "" ? Theme.danger : (passInput.activeFocus ? "#FFFFFF" : Qt.rgba(1, 1, 1, 0.22))

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 12
                    spacing: 10

                    Icon {
                        name: "lock"
                        size: 16
                        tone: "white"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        id: passInput
                        width: parent.width - 66
                        height: parent.height
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: "#FFFFFF"
                        font.family: Theme.font
                        font.pixelSize: 18
                        selectionColor: Qt.rgba(1, 1, 1, 0.3)
                        selectedTextColor: "#FFFFFF"
                        clip: true
                        text: LockscreenState.currentPassword

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !passInput.text
                            text: "Digite sua senha..."
                            color: Qt.rgba(1, 1, 1, 0.45)
                            font: passInput.font
                        }

                        onTextEdited: {
                            LockscreenState.currentPassword = passInput.text
                            character.gOn = 1
                            LockscreenState.notifyKeystroke()
                        }

                        Keys.onReturnPressed: win.doUnlock()
                        Keys.onEnterPressed: win.doUnlock()
                        Keys.onPressed: event => {
                            LockscreenState.wake()
                        }
                    }

                    // Botão de envio / Spinner
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: LockscreenState.authenticating ? "transparent" : (submitMouse.containsMouse ? Theme.fillHover : Theme.fill)
                        anchors.verticalCenter: parent.verticalCenter

                        Icon {
                            anchors.centerIn: parent
                            name: "next"
                            size: 14
                            tone: "white"
                            visible: !LockscreenState.authenticating
                        }

                        // Indicador animado durante a verificação PAM
                        Rectangle {
                            anchors.centerIn: parent
                            width: 16; height: 16; radius: 8
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.textPrimary
                            visible: LockscreenState.authenticating
                            NumberAnimation on rotation {
                                running: LockscreenState.authenticating
                                loops: Animation.Infinite
                                from: 0; to: 360; duration: 800
                            }
                        }

                        MouseArea {
                            id: submitMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.doUnlock()
                        }
                    }
                }
            }

            // Mensagem de Erro
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: LockscreenState.errorMsg !== ""
                text: LockscreenState.errorMsg
                color: Theme.danger
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: Font.Medium
            }
        }
    }

    // 4. Rodapé Discreto: Layout de Teclado + Bateria
    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12
        opacity: win.t

        // Badge de Layout de Teclado
        Rectangle {
            height: 28
            width: kbRow.implicitWidth + 20
            radius: 14
            color: Theme.cardSolid
            border.width: 1
            border.color: Theme.track

            Row {
                id: kbRow
                anchors.centerIn: parent
                spacing: 6
                Icon {
                    name: "keyboard"
                    size: 13
                    tone: "gray"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: InputState.activeBadgeText
                    color: Theme.textPrimary
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    InputState.toggleKbLayout()
                    LockscreenState.wake()
                }
            }
        }

        // Badge de Bateria (se presente)
        Rectangle {
            visible: UPower.displayDevice.isPresent
            height: 28
            width: batRow.implicitWidth + 20
            radius: 14
            color: Theme.cardSolid
            border.width: 1
            border.color: Theme.track

            Row {
                id: batRow
                anchors.centerIn: parent
                spacing: 6

                Item {
                    width: 18; height: 10
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        width: 16; height: 10; radius: 3
                        color: "transparent"; border.width: 1; border.color: Theme.textSecondary
                        Rectangle {
                            x: 2; y: 2; height: 6
                            width: Math.max(2, Math.min(12, 12 * (UPower.displayDevice.percentage || 1)))
                            radius: 1.5
                            color: (UPower.displayDevice.percentage < 0.2) ? Theme.danger : Theme.textPrimary
                        }
                    }
                    Rectangle {
                        x: 16; y: 3; width: 1.5; height: 4; radius: 0.5
                        color: Theme.textSecondary
                    }
                }

                Text {
                    text: Math.round(UPower.displayDevice.percentage * 100) + "%"
                    color: Theme.textPrimary
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
