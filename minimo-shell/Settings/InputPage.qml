// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import "../Common"

// Página de configurações de Mouse, Teclado e Touchpad.
Column {
    id: root
    spacing: 20
    width: parent ? parent.width : 500

    property bool layoutPickerOpen: false

    // =========================================================================
    // SEÇÃO 1: MOUSE
    // =========================================================================
    SectionTitle { text: "Mouse" }

    Rectangle {
        width: parent.width
        height: mouseCol.implicitHeight
        radius: 20
        color: Theme.field

        Column {
            id: mouseCol
            width: parent.width

            // Foco ao apontar (Hover vs Click)
            Item {
                width: parent.width
                height: 64

                Column {
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: focusPill.left; anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text { text: "Comportamento do foco"; color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14 }
                    Text { text: "Escolha se a janela ganha destaque ao passar o cursor ou apenas ao clicar."; color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12 }
                }

                Rectangle {
                    id: focusPill
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 250; height: 32; radius: 16
                    color: Theme.raised

                    Row {
                        anchors.fill: parent; anchors.margins: 3
                        Repeater {
                            model: [
                                { id: 1, label: "Passar o mouse" },
                                { id: 0, label: "Ao clicar" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool cur: InputState.followMouse === modelData.id
                                width: parent.width / 2; height: parent.height; radius: height / 2
                                color: cur ? Theme.fill : (fpm.containsMouse ? Theme.field : "transparent")
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: parent.cur ? Theme.onAccent : Theme.textPrimary
                                    font.family: Theme.font; font.pixelSize: 12
                                    font.weight: parent.cur ? Font.DemiBold : Font.Normal
                                }
                                MouseArea {
                                    id: fpm
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: InputState.setFollowMouse(modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

            // Perfil de aceleração
            Item {
                width: parent.width
                height: 64

                Column {
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: accelPill.left; anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text { text: "Aceleração do cursor"; color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14 }
                    Text { text: "Aceleração suave para uso geral ou resposta direta 1:1 para jogos."; color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12 }
                }

                Rectangle {
                    id: accelPill
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 250; height: 32; radius: 16
                    color: Theme.raised

                    Row {
                        anchors.fill: parent; anchors.margins: 3
                        Repeater {
                            model: [
                                { id: "adaptive", label: "Adaptativa" },
                                { id: "flat", label: "Plana (Gamer)" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool cur: InputState.accelProfile === modelData.id
                                width: parent.width / 2; height: parent.height; radius: height / 2
                                color: cur ? Theme.fill : (apm.containsMouse ? Theme.field : "transparent")
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: parent.cur ? Theme.onAccent : Theme.textPrimary
                                    font.family: Theme.font; font.pixelSize: 12
                                    font.weight: parent.cur ? Font.DemiBold : Font.Normal
                                }
                                MouseArea {
                                    id: apm
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: InputState.setAccelProfile(modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

            // Velocidade do ponteiro (Slider)
            Item {
                width: parent.width
                height: 72

                Column {
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: sensSlider.left; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text { text: "Velocidade do ponteiro"; color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14 }
                    Text { text: "Sensibilidade do cursor. Toque no ícone para redefinir."; color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12 }
                }

                MSlider {
                    id: sensSlider
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 250
                    icon: "mouse"
                    iconClickable: true
                    from: -1.0; to: 1.0
                    value: InputState.sensitivity
                    valueText: (value > 0 ? "+" : "") + Math.round(value * 100) + "%"
                    onIconClicked: InputState.setSensitivity(0.0)
                    onMoved: v => InputState.setSensitivity(v)
                }
            }

            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

            // Rolagem natural do mouse
            SwitchRow {
                width: parent.width
                text: "Rolagem natural da roda do mouse"
                detail: "Inverte a direção da roda tradicional do mouse."
                checked: InputState.naturalScrollMouse
                onToggled: v => InputState.setNaturalScrollMouse(v)
            }
        }
    }

    // =========================================================================
    // SEÇÃO 2: TECLADO
    // =========================================================================
    SectionTitle { text: "Teclado" }

    Rectangle {
        width: parent.width
        height: kbCol.implicitHeight
        radius: 20
        color: Theme.field

        Column {
            id: kbCol
            width: parent.width

            // Layout do Teclado (Cartão de seleção rápida)
            Item {
                width: parent.width
                height: 68

                Row {
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Rectangle {
                        width: 40; height: 40; radius: 12; color: Theme.raised
                        Icon { anchors.centerIn: parent; name: "keyboard"; size: 20 }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: "Disposição do teclado"
                            color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium
                        }
                        Text {
                            text: {
                                const cur = InputState.keyboardLayouts.find(l => l.id === InputState.kbLayout && l.variant === InputState.kbVariant)
                                return cur ? cur.label : (InputState.kbLayout + (InputState.kbVariant ? " (" + InputState.kbVariant + ")" : ""))
                            }
                            color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: changeBtnText.implicitWidth + 24; height: 32; radius: 16
                    color: changeMouse.containsMouse ? Theme.hover : Theme.raised
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            id: changeBtnText
                            text: root.layoutPickerOpen ? "Fechar" : "Alterar..."
                            color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium
                        }
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "chevron"
                            size: 14
                            rotation: root.layoutPickerOpen ? 90 : 0
                            Behavior on rotation { NumberAnimation { duration: 180 } }
                        }
                    }

                    MouseArea {
                        id: changeMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.layoutPickerOpen = !root.layoutPickerOpen
                    }
                }
            }

            // Gaveta de seleção de layouts
            Column {
                width: parent.width
                visible: root.layoutPickerOpen
                clip: true

                Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

                Repeater {
                    model: InputState.keyboardLayouts
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isSelected: InputState.kbLayout === modelData.id && InputState.kbVariant === modelData.variant
                        width: parent.width
                        height: 52
                        color: layMouse.containsMouse ? Theme.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Row {
                            anchors.left: parent.left; anchors.leftMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Rectangle {
                                width: 20; height: 20; radius: 10
                                color: isSelected ? Theme.fill : Theme.raised
                                border.width: isSelected ? 0 : 1.5
                                border.color: Theme.track
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 8; height: 8; radius: 4
                                    color: Theme.onAccent
                                    visible: isSelected
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    text: modelData.label
                                    color: isSelected ? Theme.textPrimary : Theme.textPrimary
                                    font.family: Theme.font; font.pixelSize: 13
                                    font.weight: isSelected ? Font.DemiBold : Font.Normal
                                }
                                Text {
                                    text: modelData.desc
                                    color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 11
                                }
                            }
                        }

                        MouseArea {
                            id: layMouse
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                InputState.setKbLayout(modelData.id, modelData.variant)
                                root.layoutPickerOpen = false
                            }
                        }
                    }
                }
            }

            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

            // Num Lock inicial
            SwitchRow {
                width: parent.width
                text: "Ativar teclado numérico (Num Lock)"
                detail: "Inicia a sessão com o teclado numérico sempre ligado."
                checked: InputState.numlockByDefault
                onToggled: v => InputState.setNumlockByDefault(v)
            }
        }
    }

    // =========================================================================
    // SEÇÃO 3: TOUCHPAD
    // =========================================================================
    SectionTitle { text: "Touchpad" }

    Rectangle {
        width: parent.width
        height: touchCol.implicitHeight
        radius: 20
        color: Theme.field

        Column {
            id: touchCol
            width: parent.width

            // Tocar para clicar
            SwitchRow {
                width: parent.width
                text: "Tocar para clicar"
                detail: "Um toque leve na superfície equivale a um clique primário."
                checked: InputState.touchpadTapToClick
                onToggled: v => InputState.setTouchpadTapToClick(v)
            }

            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

            // Rolagem natural
            SwitchRow {
                width: parent.width
                text: "Rolagem natural no touchpad"
                detail: "O conteúdo se desloca na mesma direção dos dedos."
                checked: InputState.touchpadNaturalScroll
                onToggled: v => InputState.setTouchpadNaturalScroll(v)
            }

            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

            // Velocidade de rolagem (Slider)
            Item {
                width: parent.width
                height: 72

                Column {
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: scrollSlider.left; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text { text: "Velocidade de rolagem"; color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14 }
                    Text { text: "Multiplicador de scroll. Toque no ícone para redefinir a 100%."; color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12 }
                }

                MSlider {
                    id: scrollSlider
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 250
                    icon: "drop"
                    iconClickable: true
                    from: 0.2; to: 2.0
                    value: InputState.touchpadScrollFactor
                    valueText: Math.round(value * 100) + "%"
                    onIconClicked: InputState.setTouchpadScrollFactor(1.0)
                    onMoved: v => InputState.setTouchpadScrollFactor(v)
                }
            }

            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

            // Gestos de 3 dedos
            SwitchRow {
                width: parent.width
                text: "Gestos na área de trabalho"
                detail: "Deslize 3 dedos na horizontal para alternar entre as áreas de trabalho."
                checked: InputState.touchpadGestures
                onToggled: v => InputState.setTouchpadGestures(v)
            }
        }
    }

    Item { width: 1; height: 10 }
}
