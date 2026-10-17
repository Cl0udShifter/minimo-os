// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../Common"

// Página de Aplicativos de Inicialização Automática (Autostart) nas Configurações.
Column {
    id: root

    property bool addModalOpen: false
    property string expandedAppId: ""

    readonly property var sortedMonitors: {
        const mons = (Hyprland.monitors ? Hyprland.monitors.values : []).slice().filter(m => !m.disabled).sort((a, b) => {
            const ax = a.x || 0, bx = b.x || 0
            if (ax !== bx) return ax - bx
            return (a.y || 0) - (b.y || 0)
        })
        return mons
    }

    width: parent ? parent.width : 500
    spacing: 18

    function openAddModal() {
        addModalOpen = true
    }

    // =========================================================================
    // BARRA SUPERIOR: Descrição e Botão Adicionar
    // =========================================================================
    Item {
        width: parent.width
        height: 40

        Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
                text: "Aplicativos que iniciam automaticamente ao ligar o computador."
                color: Theme.textSecondary
                font.family: Theme.font
                font.pixelSize: 13
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            // Contador de apps ativos
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: countText.implicitWidth + 20
                height: 32
                radius: 16
                color: Theme.field
                border.width: 1
                border.color: Theme.track

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: {
                        const count = (AutostartManager.autostartApps || []).filter(a => a.enabled !== false).length
                        return count + (count === 1 ? " ativo" : " ativos")
                    }
                    color: Theme.textSecondary
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }

            // Botão Novo Aplicativo
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: addBtnRow.implicitWidth + 24
                height: 32
                radius: 16
                color: addMouse.containsMouse ? Theme.hover : Theme.fill

                Row {
                    id: addBtnRow
                    anchors.centerIn: parent
                    spacing: 6
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "plus"
                        size: 14
                        tone: addMouse.containsMouse ? "dark" : "white"
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Novo Aplicativo"
                        color: addMouse.containsMouse ? Theme.textPrimary : Theme.onAccent
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }

                MouseArea {
                    id: addMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openAddModal()
                }
            }
        }
    }

    // =========================================================================
    // ESTADO VAZIO: Nenhum aplicativo configurado
    // =========================================================================
    Rectangle {
        width: parent.width
        height: 180
        radius: 20
        color: Theme.cardSolid
        border.width: 1
        border.color: Theme.track
        visible: !AutostartManager.autostartApps || AutostartManager.autostartApps.length === 0

        Column {
            anchors.centerIn: parent
            spacing: 10

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 48
                height: 48
                radius: 24
                color: Theme.field
                Icon {
                    anchors.centerIn: parent
                    name: "play"
                    size: 24
                    tone: "gray"
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Nenhum aplicativo configurado para iniciar automaticamente."
                color: Theme.textSecondary
                font.family: Theme.font
                font.pixelSize: 13
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: emptyAddRow.implicitWidth + 24
                height: 32
                radius: 16
                color: emptyAddMouse.containsMouse ? Theme.hover : Theme.raised

                Row {
                    id: emptyAddRow
                    anchors.centerIn: parent
                    spacing: 6
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "plus"
                        size: 12
                        tone: "gray"
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Adicionar primeiro aplicativo"
                        color: Theme.textPrimary
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }

                MouseArea {
                    id: emptyAddMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openAddModal()
                }
            }
        }
    }

    // =========================================================================
    // LISTA DE APLICATIVOS DE INICIALIZAÇÃO
    // =========================================================================
    Rectangle {
        width: parent.width
        height: appListCol.implicitHeight
        radius: 20
        color: Theme.cardSolid
        border.width: 1
        border.color: Theme.track
        visible: AutostartManager.autostartApps && AutostartManager.autostartApps.length > 0
        clip: true

        Column {
            id: appListCol
            width: parent.width

            Repeater {
                model: AutostartManager.autostartApps
                delegate: Column {
                    id: appRow
                    required property var modelData
                    required property int index

                    readonly property bool isExpanded: root.expandedAppId === modelData.id
                    readonly property int ws: modelData.workspace || 0

                    width: parent.width

                    // Divisor entre itens
                    Rectangle {
                        width: parent.width - 32
                        height: 1
                        x: 16
                        color: Theme.track
                        visible: index > 0
                    }

                        // Linha principal do aplicativo
                        Item {
                            width: parent.width
                            height: 60

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 18
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 14

                                // Ícone do Aplicativo
                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 10
                                    color: Theme.field
                                    anchors.verticalCenter: parent.verticalCenter

                                    Image {
                                        anchors.centerIn: parent
                                        width: 24
                                        height: 24
                                        source: modelData.icon || ""
                                        sourceSize: Qt.size(48, 48)
                                        fillMode: Image.PreserveAspectFit
                                        visible: status === Image.Ready
                                    }

                                    Icon {
                                        anchors.centerIn: parent
                                        name: "play"
                                        size: 16
                                        tone: "gray"
                                        visible: !modelData.icon || parent.children[0].status !== Image.Ready
                                    }
                                }

                                // Nome e Comando
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    width: 220

                                    Text {
                                        text: modelData.name || modelData.id
                                        color: modelData.enabled !== false ? Theme.textPrimary : Theme.textSecondary
                                        font.family: Theme.font
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Text {
                                        text: modelData.exec || ""
                                        color: Theme.textSecondary
                                        font.family: Theme.font
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }
                            }

                            // Controles à Direita: Botão Workspace + Botão Testar + Toggle + Lixeira
                            Row {
                                anchors.right: parent.right
                                anchors.rightMargin: 18
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                // Seletor de Área de Trabalho (Pill)
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: wsPillRow.implicitWidth + 20
                                    height: 30
                                    radius: 15
                                    color: appRow.ws > 0 ? Theme.fill : (wsPillMouse.containsMouse ? Theme.hover : Theme.raised)

                                    Row {
                                        id: wsPillRow
                                        anchors.centerIn: parent
                                        spacing: 5
                                        Text {
                                            text: {
                                                const w = appRow.ws
                                                if (w === 0) return "Área: Livre"
                                                if (root.sortedMonitors.length > 1) {
                                                    if (w >= 1 && w <= 9) {
                                                        const name = root.sortedMonitors[0] ? root.sortedMonitors[0].name : "M1"
                                                        return name + ": Área " + w
                                                    }
                                                    if (w >= 11 && w <= 19) {
                                                        const name = root.sortedMonitors[1] ? root.sortedMonitors[1].name : "M2"
                                                        return name + ": Área " + (w - 10)
                                                    }
                                                }
                                                if (w >= 11 && w <= 19) return "Mon 2: Área " + (w - 10)
                                                return "Área " + w
                                            }
                                            color: appRow.ws > 0 ? Theme.onAccent : Theme.textPrimary
                                            font.family: Theme.font
                                            font.pixelSize: 11
                                            font.weight: appRow.ws > 0 ? Font.DemiBold : Font.Normal
                                        }
                                        Icon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            name: "chevron"
                                            size: 11
                                            rotation: appRow.isExpanded ? 90 : 0
                                            tone: appRow.ws > 0 ? "white" : "gray"
                                            Behavior on rotation { NumberAnimation { duration: 160 } }
                                        }
                                    }

                                    MouseArea {
                                        id: wsPillMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.expandedAppId === modelData.id) {
                                                root.expandedAppId = ""
                                            } else {
                                                root.expandedAppId = modelData.id
                                            }
                                        }
                                    }
                                }

                                // Botão Testar Execução
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: testMouse.containsMouse ? Theme.hover : Theme.field

                                    Icon {
                                        anchors.centerIn: parent
                                        name: "play"
                                        size: 13
                                        tone: "gray"
                                    }

                                    MouseArea {
                                        id: testMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: AutostartManager.launchApp(modelData.id)
                                    }
                                }

                                // Toggle Switch (Ativar/Desativar)
                                MSwitch {
                                    anchors.verticalCenter: parent.verticalCenter
                                    checked: modelData.enabled !== false
                                    onToggled: AutostartManager.toggleApp(modelData.id, checked)
                                }

                                // Botão Excluir
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: delMouse.containsMouse ? Theme.hover : "transparent"

                                    Icon {
                                        anchors.centerIn: parent
                                        name: "trash"
                                        size: 14
                                        tone: delMouse.containsMouse ? "dark" : "gray"
                                    }

                                    MouseArea {
                                        id: delMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: AutostartManager.removeApp(modelData.id)
                                    }
                                }
                            }
                        }

                        // Gaveta expansível de seleção de Workspace
                        Column {
                            width: parent.width
                            height: appRow.isExpanded ? implicitHeight : 0
                            visible: height > 0 || appRow.isExpanded
                            clip: true
                            spacing: 8
                            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

                            Text {
                                x: 20
                                text: "Abrir automaticamente na área de trabalho:"
                                color: Theme.textSecondary
                                font.family: Theme.font
                                font.pixelSize: 11
                            }

                            Flow {
                                x: 20
                                width: parent.width - 40
                                spacing: 6
                                bottomPadding: 12

                                // Livre
                                Rectangle {
                                    width: 70; height: 28; radius: 14
                                    color: appRow.ws === 0 ? Theme.fill : (freeMouse.containsMouse ? Theme.raised : Theme.field)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Livre"
                                        color: appRow.ws === 0 ? Theme.onAccent : Theme.textPrimary
                                        font.family: Theme.font; font.pixelSize: 11
                                        font.weight: appRow.ws === 0 ? Font.DemiBold : Font.Normal
                                    }
                                    MouseArea {
                                        id: freeMouse
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            AutostartManager.setWorkspace(modelData.id, 0)
                                            root.expandedAppId = ""
                                        }
                                    }
                                }

                                // Monitor 1: 1 a 5
                                Repeater {
                                    model: [1, 2, 3, 4, 5]
                                    delegate: Rectangle {
                                        id: m1Btn
                                        required property int modelData
                                        readonly property bool cur: appRow.ws === modelData
                                        readonly property string monLabel: {
                                            if (root.sortedMonitors.length > 1 && root.sortedMonitors[0]) {
                                                return root.sortedMonitors[0].name + ":"
                                            }
                                            return Quickshell.screens.length > 1 ? "M1:" : "Área"
                                        }
                                        width: Math.max(54, m1Text.implicitWidth + 18)
                                        height: 28; radius: 14
                                        color: cur ? Theme.fill : (m1Mouse.containsMouse ? Theme.raised : Theme.field)
                                        Text {
                                            id: m1Text
                                            anchors.centerIn: parent
                                            text: m1Btn.monLabel + " " + m1Btn.modelData
                                            color: m1Btn.cur ? Theme.onAccent : Theme.textPrimary
                                            font.family: Theme.font; font.pixelSize: 11
                                            font.weight: m1Btn.cur ? Font.DemiBold : Font.Normal
                                        }
                                        MouseArea {
                                            id: m1Mouse
                                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                AutostartManager.setWorkspace(appRow.modelData.id, m1Btn.modelData)
                                                root.expandedAppId = ""
                                            }
                                        }
                                    }
                                }

                                // Monitor 2: 11 a 15
                                Repeater {
                                    model: (root.sortedMonitors.length > 1 || Quickshell.screens.length > 1) ? [11, 12, 13, 14, 15] : []
                                    delegate: Rectangle {
                                        id: m2Btn
                                        required property int modelData
                                        readonly property bool cur: appRow.ws === modelData
                                        readonly property string monLabel: {
                                            if (root.sortedMonitors.length > 1 && root.sortedMonitors[1]) {
                                                return root.sortedMonitors[1].name + ":"
                                            }
                                            return "M2:"
                                        }
                                        width: Math.max(54, m2Text.implicitWidth + 18)
                                        height: 28; radius: 14
                                        color: cur ? Theme.fill : (m2Mouse.containsMouse ? Theme.raised : Theme.field)
                                        Text {
                                            id: m2Text
                                            anchors.centerIn: parent
                                            text: m2Btn.monLabel + " " + (m2Btn.modelData - 10)
                                            color: m2Btn.cur ? Theme.onAccent : Theme.textPrimary
                                            font.family: Theme.font; font.pixelSize: 11
                                            font.weight: m2Btn.cur ? Font.DemiBold : Font.Normal
                                        }
                                        MouseArea {
                                            id: m2Mouse
                                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                AutostartManager.setWorkspace(appRow.modelData.id, m2Btn.modelData)
                                                root.expandedAppId = ""
                                            }
                                        }
                                    }
                                }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // CARTÃO INFORMATIVO DE DICA
    // =========================================================================
    Rectangle {
        width: parent.width
        height: tipRow.implicitHeight + 20
        radius: 16
        color: Theme.field
        border.width: 1
        border.color: Theme.track

        Row {
            id: tipRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "info"
                size: 16
                tone: "gray"
            }

            Text {
                width: parent.width - 30
                text: "Os aplicativos configurados aqui são abertos silenciosamente em segundo plano na área de trabalho selecionada sempre que você inicia a sua sessão no Minimo OS."
                color: Theme.textSecondary
                font.family: Theme.font
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }
        }
    }
}
