// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import "../Common"

// Página de configurações de Animações e Efeitos Visuais (presets de velocidade, blur e sombras).
Column {
    id: root
    spacing: 16
    width: parent ? parent.width : 500

    // =========================================================================
    // SEÇÃO 1: ANIMAÇÕES
    // =========================================================================
    SectionTitle { text: "Animações" }

    Rectangle {
        width: parent.width
        height: animCol.implicitHeight
        radius: 20
        color: Theme.field

        Column {
            id: animCol
            width: parent.width

            // Presets de velocidade de animação
            Item {
                width: parent.width
                height: Math.max(68, animTextCol.implicitHeight + 20)

                Column {
                    id: animTextCol
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: animPill.left; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Velocidade das animações"
                        color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: {
                            if (AppearanceState.animPreset === "smooth") return "Transições fluídas e elegantes com a curva padrão do Minimo OS."
                            if (AppearanceState.animPreset === "fast") return "Transições ágeis com velocidade aumentada nas janelas e espaços."
                            if (AppearanceState.animPreset === "instant") return "Transições quase imediatas (latência visual mínima)."
                            return "Animações desativadas. Janelas e alternância 100% instantâneas."
                        }
                        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                    }
                }

                Rectangle {
                    id: animPill
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 320; height: 32; radius: 16
                    color: Theme.raised

                    Row {
                        anchors.fill: parent; anchors.margins: 3
                        Repeater {
                            model: [
                                { id: "smooth", label: "Suave" },
                                { id: "fast", label: "Rápido" },
                                { id: "instant", label: "Instantâneo" },
                                { id: "disabled", label: "Desativado" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool cur: AppearanceState.animPreset === modelData.id
                                width: parent.width / 4; height: parent.height; radius: height / 2
                                color: cur ? Theme.fill : (apm.containsMouse ? Theme.field : "transparent")
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: parent.cur ? Theme.onAccent : Theme.textPrimary
                                    font.family: Theme.font; font.pixelSize: 11
                                    font.weight: parent.cur ? Font.DemiBold : Font.Normal
                                }
                                MouseArea {
                                    id: apm
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: AppearanceState.setAnimPreset(modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // SEÇÃO 2: DESFOQUE (DUAL-KAWASE BLUR)
    // =========================================================================
    SectionTitle { text: "Desfoque (Dual-Kawase Blur)" }

    Rectangle {
        width: parent.width
        height: blurCol.implicitHeight
        radius: 20
        color: Theme.field
        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Column {
            id: blurCol
            width: parent.width

            // Ativar / Desativar Blur
            SwitchRow {
                width: parent.width
                text: "Desfoque Dual-Kawase (Blur)"
                detail: "Efeito de vidro fosco suave sob janelas translúcidas e menus."
                checked: AppearanceState.blurEnabled
                onToggled: v => AppearanceState.setBlurEnabled(v)
            }

            Rectangle {
                x: 18; width: parent.width - 36; height: 1; color: Theme.track
                visible: AppearanceState.blurEnabled
            }

            // Slider de intensidade do Blur
            Item {
                width: parent.width
                height: AppearanceState.blurEnabled ? Math.max(66, blurSizeCol.implicitHeight + 16) : 0
                visible: AppearanceState.blurEnabled
                clip: true
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Column {
                    id: blurSizeCol
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: blurSlider.left; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Intensidade do desfoque"
                        color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Dispersão do efeito de vidro fosco. Toque no ícone para redefinir a 8 px."
                        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                    }
                }

                MSlider {
                    id: blurSlider
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 250
                    icon: "drop"
                    iconClickable: true
                    from: 3; to: 14
                    value: AppearanceState.blurSize
                    valueText: AppearanceState.blurSize + " px"
                    onIconClicked: AppearanceState.setBlurSize(8)
                    onMoved: v => AppearanceState.setBlurSize(Math.round(v))
                }
            }
        }
    }

    // =========================================================================
    // SEÇÃO 3: SOMBRAS (DROP SHADOWS)
    // =========================================================================
    SectionTitle { text: "Sombras sob as Janelas" }

    Rectangle {
        width: parent.width
        height: shadowCol.implicitHeight
        radius: 20
        color: Theme.field
        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Column {
            id: shadowCol
            width: parent.width

            // Ativar / Desativar Sombras
            SwitchRow {
                width: parent.width
                text: "Sombras das janelas (Drop shadows)"
                detail: "Projeta sombras suaves ao redor das janelas para profundidade visual."
                checked: AppearanceState.shadowEnabled
                onToggled: v => AppearanceState.setShadowEnabled(v)
            }

            Rectangle {
                x: 18; width: parent.width - 36; height: 1; color: Theme.track
                visible: AppearanceState.shadowEnabled
            }

            // Slider de alcance da sombra
            Item {
                width: parent.width
                height: AppearanceState.shadowEnabled ? Math.max(66, shadowRangeCol.implicitHeight + 16) : 0
                visible: AppearanceState.shadowEnabled
                clip: true
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Column {
                    id: shadowRangeCol
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: shadowSlider.left; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Alcance da sombra"
                        color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Dispersão da sombra projetada pelas janelas. Toque no ícone para 30 px."
                        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                    }
                }

                MSlider {
                    id: shadowSlider
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 250
                    icon: "brush"
                    iconClickable: true
                    from: 10; to: 60
                    value: AppearanceState.shadowRange
                    valueText: AppearanceState.shadowRange + " px"
                    onIconClicked: AppearanceState.setShadowRange(30)
                    onMoved: v => AppearanceState.setShadowRange(Math.round(v))
                }
            }
        }
    }

    // Botão de restaurar padrões
    Item {
        width: parent.width
        height: 38

        PillButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "Restaurar Padrões"
            outlined: true
            onClicked: AppearanceState.resetEffectsDefaults()
        }
    }

    Item { width: 1; height: 10 }
}
