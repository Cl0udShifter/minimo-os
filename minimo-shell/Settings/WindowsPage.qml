// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import "../Common"

// Página de configurações de Janelas e Espaçamento (gaps, bordas, arredondamento e opacidade).
Column {
    id: root
    spacing: 16
    width: parent ? parent.width : 500

    // =========================================================================
    // SEÇÃO 1: ESPAÇAMENTO
    // =========================================================================
    SectionTitle { text: "Espaçamento" }

    Rectangle {
        width: parent.width
        height: gapsCol.implicitHeight
        radius: 20
        color: Theme.field

        Column {
            id: gapsCol
            width: parent.width

            // Gaps interno (entre janelas)
            Item {
                width: parent.width
                height: Math.max(66, gapsInCol.implicitHeight + 16)

                Column {
                    id: gapsInCol
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: gapsInSlider.left; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Entre janelas (gaps interno)"
                        color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Espaço entre as janelas lado a lado na área de trabalho. Toque no ícone para 4 px."
                        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                    }
                }

                MSlider {
                    id: gapsInSlider
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 250
                    icon: "desktops"
                    iconClickable: true
                    from: 0; to: 16
                    value: AppearanceState.gapsIn
                    valueText: AppearanceState.gapsIn + " px"
                    onIconClicked: AppearanceState.setGapsIn(4)
                    onMoved: v => AppearanceState.setGapsIn(Math.round(v))
                }
            }

            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

            // Gaps externo (bordas da tela)
            Item {
                width: parent.width
                height: Math.max(66, gapsOutCol.implicitHeight + 16)

                Column {
                    id: gapsOutCol
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: gapsOutSlider.left; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Bordas da tela (gaps externo)"
                        color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Distância entre as janelas e as extremidades do monitor. Toque no ícone para 4 px."
                        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                    }
                }

                MSlider {
                    id: gapsOutSlider
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 250
                    icon: "desktops"
                    iconClickable: true
                    from: 0; to: 24
                    value: AppearanceState.gapsOut
                    valueText: AppearanceState.gapsOut + " px"
                    onIconClicked: AppearanceState.setGapsOut(4)
                    onMoved: v => AppearanceState.setGapsOut(Math.round(v))
                }
            }
        }
    }

    // =========================================================================
    // SEÇÃO 2: BORDAS E CANTOS
    // =========================================================================
    SectionTitle { text: "Bordas e Cantos" }

    Rectangle {
        width: parent.width
        height: bordersCol.implicitHeight
        radius: 20
        color: Theme.field

        Column {
            id: bordersCol
            width: parent.width

            // Arredondamento (rounding)
            Item {
                width: parent.width
                height: Math.max(66, roundCol.implicitHeight + 16)

                Column {
                    id: roundCol
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: roundSlider.left; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Cantos arredondados"
                        color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Curvatura dos cantos das janelas. Toque no ícone para redefinir a 12 px."
                        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                    }
                }

                MSlider {
                    id: roundSlider
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 250
                    icon: "brush"
                    iconClickable: true
                    from: 0; to: 24
                    value: AppearanceState.rounding
                    valueText: AppearanceState.rounding === 0 ? "Reto (0 px)" : (AppearanceState.rounding + " px")
                    onIconClicked: AppearanceState.setRounding(12)
                    onMoved: v => AppearanceState.setRounding(Math.round(v))
                }
            }

            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

            // Espessura da borda (border_size)
            Item {
                width: parent.width
                height: Math.max(66, borderCol.implicitHeight + 16)

                Column {
                    id: borderCol
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: borderSlider.left; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Espessura da borda"
                        color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Linha de contorno ao redor das janelas. 0 para manter o estilo sem bordas."
                        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                    }
                }

                MSlider {
                    id: borderSlider
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 250
                    icon: "brush"
                    iconClickable: true
                    from: 0; to: 4
                    value: AppearanceState.borderSize
                    valueText: AppearanceState.borderSize === 0 ? "Sem borda" : (AppearanceState.borderSize + " px")
                    onIconClicked: AppearanceState.setBorderSize(0)
                    onMoved: v => AppearanceState.setBorderSize(Math.round(v))
                }
            }

            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

            // Redimensionamento pelas bordas
            SwitchRow {
                width: parent.width
                text: "Redimensionar pelas bordas"
                detail: "Permite arrastar a borda da janela com o cursor para alterar seu tamanho."
                checked: AppearanceState.resizeOnBorder
                onToggled: v => AppearanceState.setResizeOnBorder(v)
            }
        }
    }

    // =========================================================================
    // SEÇÃO 3: OPACIDADE E TRANSPARÊNCIA
    // =========================================================================
    SectionTitle { text: "Opacidade e Transparência" }

    Rectangle {
        width: parent.width
        height: opacityCol.implicitHeight
        radius: 20
        color: Theme.field

        Column {
            id: opacityCol
            width: parent.width

            // Janela ativa
            Item {
                width: parent.width
                height: Math.max(66, activeOpCol.implicitHeight + 16)

                Column {
                    id: activeOpCol
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: activeOpSlider.left; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Janela ativa"
                        color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Nível de opacidade da janela em foco. Toque no ícone para redefinir a 100%."
                        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                    }
                }

                MSlider {
                    id: activeOpSlider
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 250
                    icon: "sun"
                    iconClickable: true
                    from: 0.70; to: 1.00
                    value: AppearanceState.activeOpacity
                    valueText: Math.round(AppearanceState.activeOpacity * 100) + "%"
                    onIconClicked: AppearanceState.setActiveOpacity(1.0)
                    onMoved: v => AppearanceState.setActiveOpacity(Math.round(v * 100) / 100)
                }
            }

            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

            // Janelas inativas
            Item {
                width: parent.width
                height: Math.max(66, inactOpCol.implicitHeight + 16)

                Column {
                    id: inactOpCol
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: inactOpSlider.left; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Janelas em segundo plano"
                        color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Nível de opacidade das janelas sem foco. Toque no ícone para redefinir a 100%."
                        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                    }
                }

                MSlider {
                    id: inactOpSlider
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 250
                    icon: "sun"
                    iconClickable: true
                    from: 0.70; to: 1.00
                    value: AppearanceState.inactiveOpacity
                    valueText: Math.round(AppearanceState.inactiveOpacity * 100) + "%"
                    onIconClicked: AppearanceState.setInactiveOpacity(1.0)
                    onMoved: v => AppearanceState.setInactiveOpacity(Math.round(v * 100) / 100)
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
            onClicked: AppearanceState.resetDefaults()
        }
    }

    Item { width: 1; height: 10 }
}
