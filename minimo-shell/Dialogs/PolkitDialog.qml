// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Common"

// Diálogo de Autenticação Polkit estilo Minimo OS:
// Cartão flutuante centralizado, cantos 28px, ícone de cadeado,
// campo de senha em formato de pílula, botões Cancelar e Autenticar,
// e tremor suave (shake animation) em caso de senha incorreta.
PanelWindow {
    id: win

    readonly property bool open: PolkitState.open
    property real t: open ? 1 : 0
    Behavior on t { NumberAnimation { duration: win.open ? 120 : 90; easing.type: Easing.OutCubic } }

    visible: open || t > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "minimo-polkit"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property real shakeOffset: 0

    onOpenChanged: {
        if (open) {
            passInput.text = ""
            shakeOffset = 0
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 30
        onTriggered: {
            passInput.forceActiveFocus()
        }
    }

    Connections {
        target: PolkitState
        function onShake() {
            shakeAnim.restart()
        }
        function onFocusField() {
            passInput.text = ""
            focusTimer.restart()
        }
    }

    SequentialAnimation {
        id: shakeAnim
        alwaysRunToEnd: true
        NumberAnimation { target: win; property: "shakeOffset"; to: -14; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: win; property: "shakeOffset"; to: 14; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: win; property: "shakeOffset"; to: -10; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: win; property: "shakeOffset"; to: 10; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: win; property: "shakeOffset"; to: -5; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: win; property: "shakeOffset"; to: 5; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: win; property: "shakeOffset"; to: 0; duration: 45; easing.type: Easing.OutQuad }
    }

    function doAuth() {
        if (PolkitState.busy) return
        if (passInput.text.length === 0) {
            PolkitState.errorMsg = "Digite sua senha para continuar."
            PolkitState.shake()
            return
        }
        PolkitState.submitPassword(passInput.text)
    }

    function doCancel() {
        PolkitState.cancelAuth()
    }

    // Fundo escurecido suave (scrim)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45 * win.t)
        MouseArea {
            anchors.fill: parent
            // Não fecha ao clicar fora para evitar cancelamentos acidentais durante tarefas críticas
        }
    }

    // Sombra do cartão
    Rectangle {
        id: shadowSrc
        x: card.x
        y: card.y
        width: card.width
        height: card.height
        radius: card.radius
        color: Theme.cardSolid
        opacity: win.t
        scale: card.scale
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 1.0
            blurMax: 32
            shadowVerticalOffset: 10
            autoPaddingEnabled: true
        }
    }

    // Cartão principal
    Rectangle {
        id: card
        width: 460
        height: col.implicitHeight + 48
        x: ((win.width - width) / 2) + win.shakeOffset
        y: (win.height - height) / 2
        radius: 28
        color: Theme.cardSolid
        opacity: win.t
        scale: 0.96 + 0.04 * win.t
        clip: true
        border.width: 1
        border.color: PolkitState.errorMsg !== "" ? Theme.danger : Theme.track

        MouseArea { anchors.fill: parent } // absorve cliques

        Column {
            id: col
            x: 24; y: 24
            width: parent.width - 48
            spacing: 18

            // Cabeçalho: Ícone de Cadeado + Título + Usuário
            Row {
                width: parent.width
                spacing: 16

                Rectangle {
                    width: 46; height: 46; radius: 15
                    color: Theme.field
                    anchors.verticalCenter: parent.verticalCenter
                    Icon {
                        anchors.centerIn: parent
                        name: "lock"
                        size: 22
                        tone: "dark"
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    width: parent.width - 62

                    Text {
                        text: "Autenticação Necessária"
                        color: Theme.textPrimary
                        font.family: Theme.font
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }

                    Row {
                        spacing: 6
                        Text {
                            text: "Identidade:"
                            color: Theme.textSecondary
                            font.family: Theme.font
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            height: 20
                            width: userTxt.implicitWidth + 14
                            radius: 10
                            color: Theme.raised
                            border.width: 1
                            border.color: Theme.track
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                id: userTxt
                                anchors.centerIn: parent
                                text: PolkitState.user || "daniel"
                                color: Theme.textPrimary
                                font.family: Theme.font
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }
                    }
                }
            }

            // Descrição da ação / comando que solicitou autenticação
            Text {
                width: parent.width
                text: PolkitState.message
                wrapMode: Text.Wrap
                color: Theme.textSecondary
                font.family: Theme.font
                font.pixelSize: 13
                lineHeight: 1.25
            }

            // Campo de Senha em formato de Pílula
            Column {
                width: parent.width
                spacing: 6

                Rectangle {
                    width: parent.width
                    height: 46
                    radius: 23
                    color: Theme.field
                    border.width: 1
                    border.color: passInput.activeFocus ? Theme.textPrimary : Theme.track

                    TextInput {
                        id: passInput
                        anchors.left: parent.left; anchors.leftMargin: 20
                        anchors.right: parent.right; anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: Theme.textPrimary
                        font.family: Theme.font
                        font.pixelSize: 17
                        selectionColor: Theme.track
                        selectedTextColor: Theme.textPrimary
                        cursorDelegate: Rectangle {
                            width: 2
                            radius: 1
                            color: Theme.textPrimary
                            visible: passInput.activeFocus
                        }
                        clip: true

                        Text {
                            visible: !passInput.text
                            text: "Digite sua senha..."
                            color: Theme.textSecondary
                            font: passInput.font
                        }

                        Keys.onReturnPressed: win.doAuth()
                        Keys.onEnterPressed: win.doAuth()
                        Keys.onEscapePressed: win.doCancel()
                    }
                }

                // Mensagem de erro caso a senha seja inválida
                Text {
                    visible: PolkitState.errorMsg !== ""
                    text: PolkitState.errorMsg
                    color: Theme.danger
                    font.family: Theme.font
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    leftPadding: 8
                }
            }

            // Botões de Ação
            Row {
                anchors.right: parent.right
                spacing: 10

                // Botão Cancelar
                Rectangle {
                    width: cancelTxt.implicitWidth + 32; height: 38; radius: 19
                    color: cancelMouse.containsMouse ? Theme.hover : "transparent"
                    border.width: 1; border.color: Theme.track

                    Text {
                        id: cancelTxt
                        anchors.centerIn: parent
                        text: "Cancelar"
                        color: Theme.textSecondary
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.weight: Font.Normal
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.doCancel()
                    }
                }

                // Botão Autenticar
                Rectangle {
                    width: authTxt.implicitWidth + 36; height: 38; radius: 19
                    color: authMouse.containsMouse ? Theme.fillHover : Theme.fill

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Icon {
                            name: "check"
                            visible: !PolkitState.busy
                            size: 14
                            tone: "white"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            id: authTxt
                            text: PolkitState.busy ? "Autenticando..." : "Autenticar"
                            color: Theme.onAccent
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: authMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.doAuth()
                    }
                }
            }
        }
    }
}
