// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Common"

// Histórico de Área de Transferência do Minimo OS (Super + V).
// Janela flutuante compacta e centralizada estilo Spotlight com busca instantânea,
// detecção de código/texto, pré-visualização e cópia rápida.
PanelWindow {
    id: win

    readonly property bool open: ClipboardState.open
    property real t: open ? 1 : 0
    Behavior on t { NumberAnimation { duration: win.open ? 120 : 90; easing.type: Easing.OutCubic } }

    visible: open || t > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "minimo-clipboard"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property int selectedIndex: 0

    readonly property var filteredItems: {
        const list = ClipboardState.items || []
        const q = searchField.text.trim().toLowerCase()
        if (!q) return list
        return list.filter(item => (item.preview || "").toLowerCase().indexOf(q) !== -1)
    }

    onFilteredItemsChanged: {
        selectedIndex = 0
        if (listView) listView.positionViewAtIndex(0, ListView.Beginning)
    }

    onOpenChanged: {
        if (open) {
            searchField.text = ""
            selectedIndex = 0
            if (listView) listView.positionViewAtIndex(0, ListView.Beginning)
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 15
        onTriggered: searchField.forceActiveFocus()
    }

    function copySelected() {
        if (filteredItems.length > 0 && selectedIndex >= 0 && selectedIndex < filteredItems.length) {
            ClipboardState.copyItem(filteredItems[selectedIndex].id)
        }
    }

    function deleteSelected() {
        if (filteredItems.length > 0 && selectedIndex >= 0 && selectedIndex < filteredItems.length) {
            ClipboardState.deleteItem(filteredItems[selectedIndex].id)
        }
    }

    // Fundo com velo sutil que fecha ao clicar fora
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.12 * win.t)
        MouseArea {
            anchors.fill: parent
            onPressed: ClipboardState.hide()
        }
    }

    // Sombra suave do cartão flutuante
    Rectangle {
        id: cardShadow
        x: card.x; y: card.y
        width: card.width; height: card.height
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

    // Cartão Principal Flutuante (Estilo Spotlight)
    Rectangle {
        id: card
        width: 580
        height: Math.min(win.height * 0.72, contentCol.implicitHeight + 28)
        x: (win.width - width) / 2
        y: win.height * 0.18
        radius: 28
        color: Theme.cardSolid
        opacity: win.t
        scale: 0.97 + 0.03 * win.t
        clip: true
        border.width: 1
        border.color: Theme.track

        Behavior on height { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            // Bloqueia clique para não fechar ao clicar no cartão
        }

        Column {
            id: contentCol
            x: 16; y: 16
            width: parent.width - 32
            spacing: 12

            // 1. Cabeçalho com Título, Contador e Botão Limpar Tudo
            Row {
                width: parent.width
                height: 32
                spacing: 8

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "clipboard"
                        tone: "dark"
                        size: 18
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Área de Transferência"
                        color: Theme.textPrimary
                        font.family: Theme.font
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }

                    // Contador de itens salvos
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 20
                        width: countText.implicitWidth + 12
                        radius: 10
                        color: Theme.field

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: filteredItems.length.toString()
                            color: Theme.textSecondary
                            font.family: Theme.font
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }
                }

                Item {
                    // Espaçador flexível
                    width: Math.max(0, parent.width - 240 - clearBtn.width)
                    height: 1
                }

                // Botão 'Limpar Tudo'
                Rectangle {
                    id: clearBtn
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    height: 28
                    width: clearRow.implicitWidth + 18
                    radius: 14
                    color: clearMouse.containsMouse ? Theme.field : "transparent"
                    visible: (ClipboardState.items && ClipboardState.items.length > 0)

                    Row {
                        id: clearRow
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "trash"
                            tone: clearMouse.containsMouse ? "dark" : "gray"
                            size: 13
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Limpar tudo"
                            color: clearMouse.containsMouse ? Theme.danger : Theme.textSecondary
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ClipboardState.clearAll()
                    }
                }
            }

            // 2. Campo de Busca Instantânea
            Rectangle {
                width: parent.width
                height: 44
                radius: 22
                color: Theme.field
                border.width: searchField.activeFocus ? 1 : 0
                border.color: Theme.track

                Icon {
                    id: searchIcon
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    name: "search"
                    tone: "gray"
                    size: 16
                }

                TextInput {
                    id: searchField
                    anchors.left: searchIcon.right
                    anchors.leftMargin: 10
                    anchors.right: clearSearchBtn.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.textPrimary
                    font.family: Theme.font
                    font.pixelSize: 14
                    clip: true
                    selectByMouse: true

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !searchField.text
                        text: "Buscar no histórico..."
                        color: Theme.textSecondary
                        font: searchField.font
                    }

                    Keys.onDownPressed: {
                        if (win.filteredItems.length > 0) {
                            win.selectedIndex = Math.min(win.filteredItems.length - 1, win.selectedIndex + 1)
                            listView.positionViewAtIndex(win.selectedIndex, ListView.Contain)
                        }
                    }

                    Keys.onUpPressed: {
                        if (win.filteredItems.length > 0) {
                            win.selectedIndex = Math.max(0, win.selectedIndex - 1)
                            listView.positionViewAtIndex(win.selectedIndex, ListView.Contain)
                        }
                    }

                    Keys.onReturnPressed: win.copySelected()
                    Keys.onEnterPressed: win.copySelected()
                    Keys.onEscapePressed: ClipboardState.hide()
                    Keys.onDeletePressed: win.deleteSelected()
                }

                // Botão 'X' para limpar busca
                Rectangle {
                    id: clearSearchBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    radius: 10
                    color: clearSearchMouse.containsMouse ? Theme.track : "transparent"
                    visible: searchField.text !== ""

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Theme.textSecondary
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: clearSearchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchField.text = ""
                            searchField.forceActiveFocus()
                        }
                    }
                }
            }

            // 3. Lista de Itens do Histórico
            Item {
                width: parent.width
                height: Math.min(380, Math.max(120, listView.contentHeight))
                clip: true

                ListView {
                    id: listView
                    anchors.fill: parent
                    model: win.filteredItems
                    spacing: 6
                    boundsBehavior: Flickable.StopAtBounds
                    visible: win.filteredItems.length > 0

                    delegate: Rectangle {
                        id: itemRow
                        width: listView.width
                        height: Math.max(54, itemTextCol.implicitHeight + 18)
                        radius: 14

                        readonly property bool isSelected: index === win.selectedIndex
                        readonly property bool isHovered: itemMouse.containsMouse

                        color: isSelected ? Theme.fill : (isHovered ? Theme.hover : Theme.field)

                        Behavior on color { ColorAnimation { duration: 80 } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 12

                            // Distintivo de tipo (Código vs Texto)
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28
                                height: 28
                                radius: 8
                                color: itemRow.isSelected ? Qt.rgba(1, 1, 1, 0.18) : (modelData.isCode ? Qt.rgba(0.2, 0.6, 1.0, 0.12) : Qt.rgba(0, 0, 0, 0.05))

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.isCode ? "{ }" : "Aa"
                                    color: itemRow.isSelected ? Theme.onFill : (modelData.isCode ? "#007AFF" : Theme.textSecondary)
                                    font.family: modelData.isCode ? "JetBrains Mono" : Theme.font
                                    font.pixelSize: modelData.isCode ? 11 : 12
                                    font.weight: Font.Bold
                                }
                            }

                            // Texto e informações
                            Column {
                                id: itemTextCol
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 92
                                spacing: 3

                                Text {
                                    width: parent.width
                                    text: modelData.preview || ""
                                    color: itemRow.isSelected ? Theme.onFill : Theme.textPrimary
                                    font.family: modelData.isCode ? "JetBrains Mono" : Theme.font
                                    font.pixelSize: modelData.isCode ? 12 : 13
                                    font.weight: Font.Normal
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.WrapAnywhere
                                }

                                Row {
                                    spacing: 8
                                    Text {
                                        text: (modelData.isCode ? "Código" : "Texto") + " • " + (modelData.length || 0) + " caracteres"
                                        color: itemRow.isSelected ? Qt.rgba(Theme.onFill.r, Theme.onFill.g, Theme.onFill.b, 0.7) : Theme.textSecondary
                                        font.family: Theme.font
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            // Botões de Ação na Direita
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                // Botão Copiar
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: itemCopyMouse.containsMouse ? (itemRow.isSelected ? Qt.rgba(1, 1, 1, 0.25) : Theme.track) : "transparent"

                                    Icon {
                                        anchors.centerIn: parent
                                        name: "copy"
                                        tone: itemRow.isSelected ? "white" : "gray"
                                        size: 14
                                    }

                                    MouseArea {
                                        id: itemCopyMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ClipboardState.copyItem(modelData.id)
                                    }
                                }

                                // Botão Deletar Item
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: itemDelMouse.containsMouse ? (itemRow.isSelected ? Qt.rgba(1, 1, 1, 0.25) : Theme.track) : "transparent"

                                    Icon {
                                        anchors.centerIn: parent
                                        name: "trash"
                                        tone: itemRow.isSelected ? "white" : (itemDelMouse.containsMouse ? "dark" : "gray")
                                        size: 14
                                    }

                                    MouseArea {
                                        id: itemDelMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ClipboardState.deleteItem(modelData.id)
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            z: -1
                            onEntered: win.selectedIndex = index
                            onClicked: ClipboardState.copyItem(modelData.id)
                        }
                    }
                }

                // Estado Vazio (Sem itens ou busca sem resultado)
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: win.filteredItems.length === 0
                    width: parent.width - 40

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: searchField.text ? "search" : "clipboard"
                        tone: "gray"
                        size: 32
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: searchField.text ? "Nenhum resultado encontrado" : "Nenhum item copiado ainda"
                        color: Theme.textPrimary
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: searchField.text ? "Tente buscar por outro termo." : "Textos e códigos copiados com Ctrl+C aparecerão aqui."
                        color: Theme.textSecondary
                        font.family: Theme.font
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
