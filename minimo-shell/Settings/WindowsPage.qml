// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import "../Common"

// Página de configurações de Janelas e Espaçamento (gaps, bordas, arredondamento e opacidade).
Column {
    id: root
    spacing: 16
    width: parent ? parent.width : 500

    property string appFilter: ""
    property string expandedAppId: ""
    readonly property var appsList: Apps.search(appFilter, 0, true)

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

    // =========================================================================
    // SEÇÃO 4: REGRAS POR APLICATIVO
    // =========================================================================
    SectionTitle { text: "Regras por Aplicativo" }

    // Barra de busca rápida de aplicativos
    Rectangle {
        width: parent.width
        height: 42
        radius: 21
        color: Theme.field
        border.width: appSearchInput.activeFocus ? 1 : 0
        border.color: Theme.fill

        Row {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 10

            Icon {
                name: "search"
                size: 16
                anchors.verticalCenter: parent.verticalCenter
                tone: "gray"
            }

            TextInput {
                id: appSearchInput
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 32
                color: Theme.textPrimary
                font.family: Theme.font
                font.pixelSize: 13
                text: root.appFilter
                onTextChanged: root.appFilter = text
                clip: true

                Text {
                    anchors.fill: parent
                    text: "Pesquisar aplicativo (ex: Nautilus, Calculadora, Firefox)..."
                    color: Theme.textSecondary
                    font.family: Theme.font
                    font.pixelSize: 13
                    visible: appSearchInput.text === "" && !appSearchInput.activeFocus
                }
            }
        }
    }

    // Card com lista de aplicativos e regras
    Rectangle {
        width: parent.width
        height: appsCol.implicitHeight
        radius: 20
        color: Theme.field

        Column {
            id: appsCol
            width: parent.width

            Repeater {
                model: root.appsList.slice(0, 50)
                delegate: Column {
                    id: appDelegate
                    required property var modelData
                    required property int index
                    readonly property var rule: WindowRulesState.getRule(modelData.id)
                    readonly property bool isExpanded: root.expandedAppId === modelData.id
                    readonly property string appClass: WindowRulesState.deriveClass(modelData)

                    width: parent.width

                    Rectangle {
                        x: 18
                        width: parent.width - 36
                        height: 1
                        color: Theme.track
                        visible: appDelegate.index > 0
                    }

                    Item {
                        width: parent.width
                        height: 64

                        // Ícone + Nome + ID/Classe
                        Row {
                            anchors.left: parent.left; anchors.leftMargin: 18
                            anchors.right: controlsRow.left; anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Image {
                                width: 32; height: 32
                                anchors.verticalCenter: parent.verticalCenter
                                source: Apps.iconFor(appDelegate.modelData)
                                sourceSize: Qt.size(64, 64)
                                fillMode: Image.PreserveAspectFit
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 44
                                spacing: 2

                                Text {
                                    text: appDelegate.modelData.name || appDelegate.modelData.id
                                    color: Theme.textPrimary
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: (appDelegate.modelData.id || "").replace(/\.desktop$/, "")
                                    color: Theme.textSecondary
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }

                        // Controles à direita: Modo (Padrão/Mosaico/Flutuante) + Área de Trabalho
                        Row {
                            id: controlsRow
                            anchors.right: parent.right; anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            // Pílula segmentada para o modo
                            Rectangle {
                                width: 195; height: 32; radius: 16
                                color: Theme.raised

                                Row {
                                    anchors.fill: parent; anchors.margins: 3
                                    Repeater {
                                        model: [
                                            { id: "default", label: "Padrão" },
                                            { id: "tile", label: "Mosaico" },
                                            { id: "float", label: "Flutuante" }
                                        ]
                                        delegate: Rectangle {
                                            required property var modelData
                                            readonly property bool cur: (appDelegate.rule.mode || "default") === modelData.id
                                            width: parent.width / 3; height: parent.height; radius: height / 2
                                            color: cur ? Theme.fill : (mMouse.containsMouse ? Theme.field : "transparent")
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                color: parent.cur ? Theme.onAccent : Theme.textPrimary
                                                font.family: Theme.font; font.pixelSize: 11
                                                font.weight: parent.cur ? Font.DemiBold : Font.Normal
                                            }
                                            MouseArea {
                                                id: mMouse
                                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    WindowRulesState.setMode(appDelegate.modelData.id,
                                                                            appDelegate.modelData.name,
                                                                            appDelegate.appClass,
                                                                            modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Botão de área de trabalho
                            Rectangle {
                                width: wsBtnRow.implicitWidth + 20; height: 32; radius: 16
                                color: (appDelegate.rule.workspace && appDelegate.rule.workspace > 0) ? Theme.fill : (wsMouse.containsMouse ? Theme.hover : Theme.raised)

                                Row {
                                    id: wsBtnRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: {
                                            const w = appDelegate.rule.workspace || 0
                                            if (w === 0) return "Área: Livre"
                                            if (w >= 11 && w <= 19) return "Mon 2: Área " + (w - 10)
                                            return "Área " + w
                                        }
                                        color: (appDelegate.rule.workspace && appDelegate.rule.workspace > 0) ? Theme.onAccent : Theme.textPrimary
                                        font.family: Theme.font; font.pixelSize: 11
                                        font.weight: (appDelegate.rule.workspace && appDelegate.rule.workspace > 0) ? Font.DemiBold : Font.Normal
                                    }
                                    Icon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: "chevron"
                                        size: 12
                                        rotation: appDelegate.isExpanded ? 90 : 0
                                        tone: (appDelegate.rule.workspace && appDelegate.rule.workspace > 0) ? "white" : "gray"
                                        Behavior on rotation { NumberAnimation { duration: 180 } }
                                    }
                                }

                                MouseArea {
                                    id: wsMouse
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.expandedAppId === appDelegate.modelData.id) {
                                            root.expandedAppId = ""
                                        } else {
                                            root.expandedAppId = appDelegate.modelData.id
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Gaveta de seleção de workspace
                    Column {
                        id: wsDrawer
                        width: parent.width
                        height: appDelegate.isExpanded ? implicitHeight : 0
                        visible: height > 0 || appDelegate.isExpanded
                        clip: true
                        spacing: 8
                        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

                        Text {
                            x: 20
                            text: "Abrir automaticamente na área de trabalho:"
                            color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 11
                        }

                        Flow {
                            x: 20
                            width: parent.width - 40
                            spacing: 6

                            // Livre (Sem fixar)
                            Rectangle {
                                width: 70; height: 28; radius: 14
                                color: (appDelegate.rule.workspace || 0) === 0 ? Theme.fill : (freeMouse.containsMouse ? Theme.raised : Theme.field)
                                Text {
                                    anchors.centerIn: parent
                                    text: "Livre"
                                    color: (appDelegate.rule.workspace || 0) === 0 ? Theme.onAccent : Theme.textPrimary
                                    font.family: Theme.font; font.pixelSize: 11
                                    font.weight: (appDelegate.rule.workspace || 0) === 0 ? Font.DemiBold : Font.Normal
                                }
                                MouseArea {
                                    id: freeMouse
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        WindowRulesState.setWorkspace(appDelegate.modelData.id,
                                                                    appDelegate.modelData.name,
                                                                    appDelegate.appClass,
                                                                    0)
                                        root.expandedAppId = ""
                                    }
                                }
                            }

                            // Workspaces do Monitor 1 (1 a 5)
                            Repeater {
                                model: [1, 2, 3, 4, 5]
                                delegate: Rectangle {
                                    required property int modelData
                                    readonly property bool cur: (appDelegate.rule.workspace || 0) === modelData
                                    width: 52; height: 28; radius: 14
                                    color: cur ? Theme.fill : (w1Mouse.containsMouse ? Theme.raised : Theme.field)
                                    Text {
                                        anchors.centerIn: parent
                                        text: (Quickshell.screens.length > 1 ? "M1: " : "Área ") + modelData
                                        color: parent.cur ? Theme.onAccent : Theme.textPrimary
                                        font.family: Theme.font; font.pixelSize: 11
                                        font.weight: parent.cur ? Font.DemiBold : Font.Normal
                                    }
                                    MouseArea {
                                        id: w1Mouse
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            WindowRulesState.setWorkspace(appDelegate.modelData.id,
                                                                        appDelegate.modelData.name,
                                                                        appDelegate.appClass,
                                                                        modelData)
                                            root.expandedAppId = ""
                                        }
                                    }
                                }
                            }

                            // Workspaces do Monitor 2 (se conectado: 11 a 15)
                            Repeater {
                                model: Quickshell.screens.length > 1 ? [11, 12, 13, 14, 15] : []
                                delegate: Rectangle {
                                    required property int modelData
                                    readonly property bool cur: (appDelegate.rule.workspace || 0) === modelData
                                    width: 52; height: 28; radius: 14
                                    color: cur ? Theme.fill : (w2Mouse.containsMouse ? Theme.raised : Theme.field)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "M2: " + (modelData - 10)
                                        color: parent.cur ? Theme.onAccent : Theme.textPrimary
                                        font.family: Theme.font; font.pixelSize: 11
                                        font.weight: parent.cur ? Font.DemiBold : Font.Normal
                                    }
                                    MouseArea {
                                        id: w2Mouse
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            WindowRulesState.setWorkspace(appDelegate.modelData.id,
                                                                        appDelegate.modelData.name,
                                                                        appDelegate.appClass,
                                                                        modelData)
                                            root.expandedAppId = ""
                                        }
                                    }
                                }
                            }
                        }

                        Item { width: 1; height: 6 }
                    }
                }
            }

            // Estado vazio quando não encontra nenhum app na busca
            Item {
                width: parent.width
                height: 60
                visible: root.appsList.length === 0
                Text {
                    anchors.centerIn: parent
                    text: "Nenhum aplicativo encontrado."
                    color: Theme.textSecondary
                    font.family: Theme.font
                    font.pixelSize: 13
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
            text: "Restaurar Padrões de Janelas"
            outlined: true
            onClicked: AppearanceState.resetDefaults()
        }
    }

    Item { width: 1; height: 10 }
}

