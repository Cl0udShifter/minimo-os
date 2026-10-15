// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import QtQuick.Effects
import Quickshell
import "../Common"

// Página de Gerenciamento de Atalhos de Teclado do Minimo OS.
// Permite visualizar, pesquisar, editar (1 a 3 teclas) com validação de conflitos e salvar.
Column {
    id: root
    spacing: 16

    property var editingItem: null
    property string tempKeys: ""
    property var tempConflict: null
    property bool modSuper: false
    property bool modCtrl: false
    property bool modShift: false
    property bool modAlt: false
    property string mainKey: ""

    IpcHandler {
        target: "shortcutEditor"
        function edit(id: string) {
            let item = ShortcutsManager.shortcutsList.find(s => s.id === id)
            if (item) root.openEditor(item)
        }
        function close() {
            root.closeEditor()
        }
    }

    onVisibleChanged: {
        if (visible) {
            if (typeof flick !== "undefined" && flick) flick.contentY = 0
        }
    }

    // Barra Superior: Busca, Notificação de Sucesso, Restaurar e Salvar
    Row {
        width: root.width
        spacing: 10

        // Campo de Busca
        Rectangle {
            width: root.width - (ShortcutsManager.dirty ? 290 : 170)
            height: 38
            radius: 19
            color: Theme.field
            border.width: sInput.activeFocus ? 1 : 0
            border.color: Theme.fill

            Row {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10
                Icon {
                    name: "search"
                    size: 16
                    anchors.verticalCenter: parent.verticalCenter
                    tone: "gray"
                }
                TextInput {
                    id: sInput
                    width: parent.width - 32
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.textPrimary
                    font.family: Theme.font
                    font.pixelSize: 13
                    selectByMouse: true
                    clip: true
                    text: ShortcutsManager.searchFilter
                    onTextEdited: ShortcutsManager.searchFilter = text.trim().toLowerCase()
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Buscar atalhos..."
                        color: Theme.textSecondary
                        font.family: Theme.font
                        font.pixelSize: 13
                        visible: !sInput.text && !sInput.activeFocus
                    }
                }
            }
        }

        // Botão Restaurar Padrões
        PillButton {
            text: "Padrões"
            outlined: true
            onClicked: ShortcutsManager.resetAllToDefaults()
        }

        // Botão Salvar Alterações (só visível/destacado se houver mudanças)
        PillButton {
            visible: ShortcutsManager.dirty
            text: "Salvar"
            primary: true
            onClicked: ShortcutsManager.saveChanges()
        }
    }

    // Banner de Sucesso ao Salvar
    Rectangle {
        width: root.width
        height: ShortcutsManager.saveSuccess ? 40 : 0
        radius: 12
        color: Theme.fill
        opacity: ShortcutsManager.saveSuccess ? 1 : 0
        visible: height > 0
        clip: true
        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        Row {
            anchors.centerIn: parent
            spacing: 8
            Icon { name: "check"; size: 16; tone: "white"; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: "Atalhos salvos e recarregados no Hyprland com sucesso!"
                color: Theme.onAccent
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Lista de Categorias e Atalhos
    Repeater {
        model: [
            "Aplicativos e Shell",
            "Janelas",
            "Navegação",
            "Áudio e Mídia",
            "Capturas",
            "Áreas de Trabalho",
            "Sessão"
        ]

        delegate: Column {
            id: catCol
            required property string modelData
            readonly property string catName: modelData
            readonly property var items: {
                let filter = ShortcutsManager.searchFilter
                let list = ShortcutsManager.shortcutsList.filter(s => s.cat === catName)
                if (!filter) return list
                return list.filter(s =>
                    s.name.toLowerCase().includes(filter) ||
                    s.desc.toLowerCase().includes(filter) ||
                    s.keys.toLowerCase().includes(filter)
                )
            }
            visible: items.length > 0
            width: root.width
            spacing: 10

            SectionTitle { text: catCol.catName }

            Rectangle {
                width: root.width
                height: rowsCol.implicitHeight + 16
                radius: 20
                color: Theme.field

                Column {
                    id: rowsCol
                    x: 12; y: 8
                    width: parent.width - 24
                    spacing: 4

                    Repeater {
                        model: catCol.items
                        delegate: Rectangle {
                            id: sRow
                            required property var modelData
                            readonly property var item: modelData
                            width: rowsCol.width
                            height: 52
                            radius: 14
                            color: rowArea.containsMouse ? Theme.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                x: 12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 14

                                Rectangle {
                                    width: 32; height: 32; radius: 10
                                    color: Theme.raised
                                    anchors.verticalCenter: parent.verticalCenter
                                    Icon {
                                        anchors.centerIn: parent
                                        name: sRow.item.icon || "keyboard"
                                        size: 16
                                        tone: "dark"
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    Text {
                                        text: sRow.item.name
                                        color: Theme.textPrimary
                                        font.family: Theme.font
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                    }
                                    Text {
                                        text: sRow.item.desc
                                        color: Theme.textSecondary
                                        font.family: Theme.font
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            // Lado Direito: Teclas e Botão Editar
                            Row {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10

                                // Badges de teclas estilo keycaps
                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4
                                    Repeater {
                                        model: ShortcutsManager.parseBadges(sRow.item.keys)
                                        delegate: Rectangle {
                                            required property string modelData
                                            height: 24
                                            width: badgeTxt.implicitWidth + 14
                                            radius: 6
                                            color: Theme.raised
                                            border.width: 1
                                            border.color: Theme.track
                                            Text {
                                                id: badgeTxt
                                                anchors.centerIn: parent
                                                text: modelData
                                                color: Theme.textPrimary
                                                font.family: Theme.font
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                            }
                                        }
                                    }
                                }

                                PillButton {
                                    text: "Editar"
                                    outlined: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    onClicked: root.openEditor(sRow.item)
                                }
                            }

                            MouseArea {
                                id: rowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openEditor(sRow.item)
                            }
                        }
                    }
                }
            }
        }
    }

    // Métodos utilitários de controle do modal e das teclas
    function isKeyCountValid() {
        let count = ShortcutsManager.countKeys(root.tempKeys)
        return count >= 1 && count <= 3
    }

    function openEditor(item) {
        console.log("openEditor called for item:", item ? item.name : "null")
        root.editingItem = item
        root.setFromKeys(item.keys)
    }

    function closeEditor() {
        root.editingItem = null
        root.tempKeys = ""
        root.tempConflict = null
    }

    function setFromKeys(keysStr) {
        let tokens = ShortcutsManager.parseBadges(keysStr)
        root.modSuper = false
        root.modCtrl = false
        root.modShift = false
        root.modAlt = false
        root.mainKey = ""

        for (let i = 0; i < tokens.length; i++) {
            let u = tokens[i].toUpperCase()
            if (u === "SUPER" || u === "META" || u === "WIN") root.modSuper = true
            else if (u === "CTRL" || u === "CONTROL") root.modCtrl = true
            else if (u === "SHIFT") root.modShift = true
            else if (u === "ALT") root.modAlt = true
            else root.mainKey = tokens[i]
        }
        root.updateFromInputs()
    }

    function updateFromInputs() {
        let parts = []
        if (root.modSuper) parts.push("SUPER")
        if (root.modCtrl) parts.push("CTRL")
        if (root.modShift) parts.push("SHIFT")
        if (root.modAlt) parts.push("ALT")
        if (root.mainKey && !["SUPER", "CTRL", "SHIFT", "ALT"].includes(root.mainKey.toUpperCase())) {
            parts.push(root.mainKey)
        }
        root.tempKeys = parts.join(" + ")
        root.tempConflict = root.editingItem ? ShortcutsManager.findConflict(root.editingItem.id, root.tempKeys) : null
    }

    function keyToHypr(key, text) {
        switch (key) {
            case Qt.Key_Space: return "space"
            case Qt.Key_Comma: return "comma"
            case Qt.Key_Period: return "period"
            case Qt.Key_Minus: return "minus"
            case Qt.Key_Equal: return "equal"
            case Qt.Key_BracketLeft: return "bracketleft"
            case Qt.Key_BracketRight: return "bracketright"
            case Qt.Key_Slash: return "slash"
            case Qt.Key_Backslash: return "backslash"
            case Qt.Key_Semicolon: return "semicolon"
            case Qt.Key_Apostrophe: return "apostrophe"
            case Qt.Key_Print: return "Print"
            case Qt.Key_PageUp: return "Page_Up"
            case Qt.Key_PageDown: return "Page_Down"
            case Qt.Key_Home: return "Home"
            case Qt.Key_End: return "End"
            case Qt.Key_Left: return "left"
            case Qt.Key_Right: return "right"
            case Qt.Key_Up: return "up"
            case Qt.Key_Down: return "down"
            case Qt.Key_Return: case Qt.Key_Enter: return "Return"
            case Qt.Key_Tab: return "Tab"
            case Qt.Key_Backspace: return "BackSpace"
            case Qt.Key_Delete: return "Delete"
            case Qt.Key_Insert: return "Insert"
            case Qt.Key_Escape: return "Escape"
            case Qt.Key_F1: return "F1"
            case Qt.Key_F2: return "F2"
            case Qt.Key_F3: return "F3"
            case Qt.Key_F4: return "F4"
            case Qt.Key_F5: return "F5"
            case Qt.Key_F6: return "F6"
            case Qt.Key_F7: return "F7"
            case Qt.Key_F8: return "F8"
            case Qt.Key_F9: return "F9"
            case Qt.Key_F10: return "F10"
            case Qt.Key_F11: return "F11"
            case Qt.Key_F12: return "F12"
            default:
                if (key >= Qt.Key_0 && key <= Qt.Key_9) return String.fromCharCode(key)
                if (key >= Qt.Key_A && key <= Qt.Key_Z) return String.fromCharCode(key)
                if (text && text.length === 1 && text.trim() !== "") return text
                return ""
        }
    }
}
