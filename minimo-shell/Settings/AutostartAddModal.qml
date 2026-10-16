// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import "../Common"

// Modal para adicionar um aplicativo ou comando à Inicialização Automática.
Rectangle {
    id: root

    property var page: null
    readonly property bool open: page ? page.addModalOpen : false

    anchors.fill: parent
    color: Theme.scrim
    visible: open
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150 } }
    z: 999

    property int tabIndex: 0 // 0: Aplicativo Instalado, 1: Comando Personalizado
    property var selectedApp: null
    property string appSearchQuery: ""
    property string customName: ""
    property string customExec: ""
    property int selectedWorkspace: 0 // 0 = Livre

    function reset() {
        tabIndex = 0
        selectedApp = null
        appSearchQuery = ""
        customName = ""
        customExec = ""
        selectedWorkspace = 0
    }

    onOpenChanged: {
        if (open) {
            reset()
        }
    }

    function cleanExec(app) {
        if (!app) return ""
        const raw = app.exec || ""
        return raw.replace(/%[a-zA-Z]/g, "").trim()
    }

    function isValid() {
        if (tabIndex === 0) {
            return selectedApp !== null
        }
        return customName.trim().length > 0 && customExec.trim().length > 0
    }

    function submit() {
        if (!isValid()) return

        let id = ""
        let name = ""
        let exec = ""
        let icon = ""

        if (tabIndex === 0 && selectedApp) {
            id = selectedApp.id || selectedApp.name
            name = selectedApp.name || selectedApp.id
            exec = cleanExec(selectedApp)
            if (!exec && selectedApp.id) {
                exec = String(selectedApp.id).replace(/\.desktop$/, "")
            }
            icon = Apps.iconFor(selectedApp) || ""
        } else {
            id = "custom." + Date.now()
            name = customName.trim()
            exec = customExec.trim()
            icon = Qt.resolvedUrl("../assets/icons/gray/terminal.svg")
        }

        AutostartManager.addApp(id, name, exec, icon, selectedWorkspace)
        if (root.page) root.page.addModalOpen = false
    }

    // Clique fora fecha o modal
    MouseArea {
        anchors.fill: parent
        onClicked: if (root.page) root.page.addModalOpen = false
    }

    // Cartão central do Modal
    Rectangle {
        id: modalCard
        width: 520
        height: Math.min(580, parent.height - 40)
        anchors.centerIn: parent
        radius: 28
        color: Theme.cardSolid
        border.width: 1
        border.color: Theme.track
        clip: true

        MouseArea { anchors.fill: parent } // não fechar ao clicar no cartão

        Flickable {
            id: modalFlick
            anchors.fill: parent
            anchors.margins: 24
            contentHeight: modalCol.implicitHeight + 16
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: modalCol
                width: parent.width
                spacing: 14

                // Cabeçalho
                Item {
                    width: parent.width
                    height: 48

                    Column {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: "Adicionar à Inicialização"
                            color: Theme.textPrimary
                            font.family: Theme.font
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "Escolha um aplicativo para iniciar silenciosamente ao ligar o PC."
                            color: Theme.textSecondary
                            font.family: Theme.font
                            font.pixelSize: 12
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        radius: 16
                        color: closeBtnMouse.containsMouse ? Theme.hover : Theme.field

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: Theme.textSecondary
                            font.family: Theme.font
                            font.pixelSize: 13
                        }
                        MouseArea {
                            id: closeBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.page) root.page.addModalOpen = false
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.track }

                // Alternador de Abas: App vs Comando
                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 18
                    color: Theme.field

                    Row {
                        anchors.fill: parent
                        anchors.margins: 3

                        Rectangle {
                            width: parent.width / 2; height: parent.height; radius: height / 2
                            color: root.tabIndex === 0 ? Theme.fill : (t0Mouse.containsMouse ? Theme.hover : "transparent")
                            Text {
                                anchors.centerIn: parent
                                text: "Aplicativo Instalado"
                                color: root.tabIndex === 0 ? Theme.onAccent : Theme.textPrimary
                                font.family: Theme.font; font.pixelSize: 12
                                font.weight: root.tabIndex === 0 ? Font.DemiBold : Font.Normal
                            }
                            MouseArea {
                                id: t0Mouse
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.tabIndex = 0
                            }
                        }

                        Rectangle {
                            width: parent.width / 2; height: parent.height; radius: height / 2
                            color: root.tabIndex === 1 ? Theme.fill : (t1Mouse.containsMouse ? Theme.hover : "transparent")
                            Text {
                                anchors.centerIn: parent
                                text: "Comando Personalizado"
                                color: root.tabIndex === 1 ? Theme.onAccent : Theme.textPrimary
                                font.family: Theme.font; font.pixelSize: 12
                                font.weight: root.tabIndex === 1 ? Font.DemiBold : Font.Normal
                            }
                            MouseArea {
                                id: t1Mouse
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.tabIndex = 1
                            }
                        }
                    }
                }

                // =============================================================
                // TAB 0: APLICATIVO INSTALADO
                // =============================================================
                Column {
                    width: parent.width
                    spacing: 8
                    visible: root.tabIndex === 0

                    Text {
                        text: "1. Selecionar Aplicativo:"
                        color: Theme.textSecondary; font.pixelSize: 11; font.family: Theme.font; font.weight: Font.Medium
                    }

                    // Se nenhum selecionado: Busca + Lista
                    Column {
                        width: parent.width
                        spacing: 8
                        visible: root.selectedApp === null

                        Rectangle {
                            width: parent.width
                            height: 38
                            radius: 19
                            color: Theme.field
                            border.width: appSearchInput.activeFocus ? 1 : 0
                            border.color: Theme.fill

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12; anchors.rightMargin: 12
                                spacing: 8
                                Icon { name: "search"; size: 14; anchors.verticalCenter: parent.verticalCenter; tone: "gray" }
                                TextInput {
                                    id: appSearchInput
                                    width: parent.width - 26
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 12
                                    selectByMouse: true; clip: true
                                    text: root.appSearchQuery
                                    onTextChanged: root.appSearchQuery = text
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Buscar aplicativo (ex: Nautilus, Firefox, Spotify)..."
                                        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                                        visible: !appSearchInput.text && !appSearchInput.activeFocus
                                    }
                                }
                            }
                        }

                        // Lista rolável de aplicativos encontrados
                        Rectangle {
                            width: parent.width
                            height: 140
                            radius: 14
                            color: Theme.field
                            clip: true

                            ListView {
                                id: appLv
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 4
                                clip: true
                                model: Apps.search(root.appSearchQuery, 14, true)
                                delegate: Rectangle {
                                    required property var modelData
                                    width: appLv.width
                                    height: 38
                                    radius: 10
                                    color: aMouse.containsMouse ? Theme.hover : "transparent"

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8; anchors.rightMargin: 8
                                        spacing: 10

                                        Image {
                                            width: 24; height: 24
                                            anchors.verticalCenter: parent.verticalCenter
                                            source: Apps.iconFor(modelData)
                                            sourceSize: Qt.size(48, 48)
                                            fillMode: Image.PreserveAspectFit
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - 40
                                            spacing: 1
                                            Text {
                                                text: modelData.name || modelData.id
                                                color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium
                                                elide: Text.ElideRight; width: parent.width
                                            }
                                            Text {
                                                text: root.cleanExec(modelData)
                                                color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 10
                                                elide: Text.ElideRight; width: parent.width
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: aMouse
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectedApp = modelData
                                    }
                                }
                            }
                        }
                    }

                    // Se selecionado: Cartão do app selecionado
                    Rectangle {
                        width: parent.width
                        height: 52
                        radius: 14
                        color: Theme.field
                        border.width: 1
                        border.color: Theme.track
                        visible: root.selectedApp !== null

                        Row {
                            anchors.left: parent.left; anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Image {
                                width: 28; height: 28
                                anchors.verticalCenter: parent.verticalCenter
                                source: root.selectedApp ? Apps.iconFor(root.selectedApp) : ""
                                sourceSize: Qt.size(56, 56)
                                fillMode: Image.PreserveAspectFit
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text {
                                    text: root.selectedApp ? (root.selectedApp.name || root.selectedApp.id) : ""
                                    color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold
                                }
                                Text {
                                    text: root.cleanExec(root.selectedApp)
                                    color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 11
                                }
                            }
                        }

                        // Botão Trocar
                        Rectangle {
                            anchors.right: parent.right; anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 68; height: 28; radius: 14
                            color: changeMouse.containsMouse ? Theme.hover : Theme.raised

                            Text {
                                anchors.centerIn: parent
                                text: "Trocar"
                                color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Medium
                            }
                            MouseArea {
                                id: changeMouse
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedApp = null
                            }
                        }
                    }
                }

                // =============================================================
                // TAB 1: COMANDO PERSONALIZADO
                // =============================================================
                Column {
                    width: parent.width
                    spacing: 10
                    visible: root.tabIndex === 1

                    Text {
                        text: "1. Detalhes do Comando:"
                        color: Theme.textSecondary; font.pixelSize: 11; font.family: Theme.font; font.weight: Font.Medium
                    }

                    Rectangle {
                        width: parent.width; height: 38; radius: 12; color: Theme.field
                        border.width: nameInput.activeFocus ? 1 : 0; border.color: Theme.fill
                        Item {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                            TextInput {
                                id: nameInput
                                anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter
                                color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 12
                                selectByMouse: true
                                text: root.customName
                                onTextChanged: root.customName = text
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Nome (ex: Servidor Local, Script de Backup)..."
                                    color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                                    visible: !nameInput.text && !nameInput.activeFocus
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width; height: 38; radius: 12; color: Theme.field
                        border.width: execInput.activeFocus ? 1 : 0; border.color: Theme.fill
                        Item {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                            TextInput {
                                id: execInput
                                anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter
                                color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 12
                                selectByMouse: true
                                text: root.customExec
                                onTextChanged: root.customExec = text
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Comando (ex: ghostty -e btop, /usr/bin/my-script)..."
                                    color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                                    visible: !execInput.text && !execInput.activeFocus
                                }
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.track }

                // =============================================================
                // SEÇÃO 2: ÁREA DE TRABALHO E MONITOR
                // =============================================================
                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "2. Área de Trabalho Inicial:"
                        color: Theme.textSecondary; font.pixelSize: 11; font.family: Theme.font; font.weight: Font.Medium
                    }

                    Flow {
                        width: parent.width
                        spacing: 6

                        // Opção Livre (Área atual)
                        Rectangle {
                            width: 76; height: 30; radius: 15
                            color: root.selectedWorkspace === 0 ? Theme.fill : (freeWsMouse.containsMouse ? Theme.raised : Theme.field)

                            Text {
                                anchors.centerIn: parent
                                text: "Livre"
                                color: root.selectedWorkspace === 0 ? Theme.onAccent : Theme.textPrimary
                                font.family: Theme.font; font.pixelSize: 11
                                font.weight: root.selectedWorkspace === 0 ? Font.DemiBold : Font.Normal
                            }
                            MouseArea {
                                id: freeWsMouse
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedWorkspace = 0
                            }
                        }

                        // Monitor 1: Workspaces 1 a 5
                        Repeater {
                            model: [1, 2, 3, 4, 5]
                            delegate: Rectangle {
                                required property int modelData
                                readonly property bool cur: root.selectedWorkspace === modelData
                                width: 56; height: 30; radius: 15
                                color: cur ? Theme.fill : (m1WsMouse.containsMouse ? Theme.raised : Theme.field)

                                Text {
                                    anchors.centerIn: parent
                                    text: (Quickshell.screens.length > 1 ? "M1: " : "Área ") + modelData
                                    color: parent.cur ? Theme.onAccent : Theme.textPrimary
                                    font.family: Theme.font; font.pixelSize: 11
                                    font.weight: parent.cur ? Font.DemiBold : Font.Normal
                                }
                                MouseArea {
                                    id: m1WsMouse
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectedWorkspace = modelData
                                }
                            }
                        }

                        // Monitor 2: Workspaces 11 a 15 (se múltiplos monitores)
                        Repeater {
                            model: Quickshell.screens.length > 1 ? [11, 12, 13, 14, 15] : []
                            delegate: Rectangle {
                                required property int modelData
                                readonly property bool cur: root.selectedWorkspace === modelData
                                width: 56; height: 30; radius: 15
                                color: cur ? Theme.fill : (m2WsMouse.containsMouse ? Theme.raised : Theme.field)

                                Text {
                                    anchors.centerIn: parent
                                    text: "M2: " + (modelData - 10)
                                    color: parent.cur ? Theme.onAccent : Theme.textPrimary
                                    font.family: Theme.font; font.pixelSize: 11
                                    font.weight: parent.cur ? Font.DemiBold : Font.Normal
                                }
                                MouseArea {
                                    id: m2WsMouse
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectedWorkspace = modelData
                                }
                            }
                        }
                    }
                }

                Item { width: 1; height: 6 }

                // =============================================================
                // BOTÕES DE AÇÃO: CANCELAR E ADICIONAR
                // =============================================================
                Row {
                    anchors.right: parent.right
                    spacing: 10

                    // Cancelar
                    Rectangle {
                        width: 90; height: 34; radius: 17
                        color: cancelMouse.containsMouse ? Theme.hover : Theme.field

                        Text {
                            anchors.centerIn: parent
                            text: "Cancelar"
                            color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium
                        }
                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.page) root.page.addModalOpen = false
                        }
                    }

                    // Adicionar
                    Rectangle {
                        width: 100; height: 34; radius: 17
                        color: root.isValid() ? Theme.fill : Theme.raised
                        opacity: root.isValid() ? 1 : 0.5

                        Text {
                            anchors.centerIn: parent
                            text: "Adicionar"
                            color: root.isValid() ? Theme.onAccent : Theme.textSecondary
                            font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold
                        }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: root.isValid()
                            cursorShape: root.isValid() ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (root.isValid()) root.submit()
                        }
                    }
                }
            }
        }
    }
}
