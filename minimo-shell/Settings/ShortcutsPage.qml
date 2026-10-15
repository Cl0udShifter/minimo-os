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
                    onTextChanged: ShortcutsManager.searchFilter = text.trim().toLowerCase()
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

    // Modal de Edição de Atalho (re-parented para o card central de configurações)
    Rectangle {
        id: modalOverlay
        parent: card
        anchors.fill: parent
        color: Theme.scrim
        visible: root.editingItem !== null
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        z: 999

        MouseArea { anchors.fill: parent; onClicked: root.closeEditor() }

        Rectangle {
            id: modalCard
            width: 460
            height: modalCol.implicitHeight + 48
            anchors.centerIn: parent
            radius: 28
            color: Theme.cardSolid
            border.width: 1
            border.color: Theme.track

            MouseArea { anchors.fill: parent } // não fechar ao clicar dentro

            Column {
                id: modalCol
                x: 24; y: 24
                width: parent.width - 48
                spacing: 16

                // Cabeçalho do Modal
                Row {
                    width: parent.width
                    spacing: 12
                    Rectangle {
                        width: 38; height: 38; radius: 12; color: Theme.field
                        anchors.verticalCenter: parent.verticalCenter
                        Icon {
                            anchors.centerIn: parent
                            name: root.editingItem ? (root.editingItem.icon || "keyboard") : "keyboard"
                            size: 20
                            tone: "dark"
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        width: parent.width - 90
                        Text {
                            text: root.editingItem ? root.editingItem.name : ""
                            color: Theme.textPrimary
                            font.family: Theme.font
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: root.editingItem ? root.editingItem.desc : ""
                            color: Theme.textSecondary
                            font.family: Theme.font
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                    // Botão Fechar (X)
                    Rectangle {
                        width: 28; height: 28; radius: 14; color: closeMa.containsMouse ? Theme.hover : Theme.field
                        anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "✕"; color: Theme.textSecondary; font.pixelSize: 13 }
                        MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closeEditor() }
                    }
                }

                // Caixa de Pré-visualização da Combinação de Teclas
                Rectangle {
                    width: parent.width
                    height: 56
                    radius: 14
                    color: Theme.field
                    border.width: 1
                    border.color: root.tempConflict ? Theme.danger : Theme.track

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Repeater {
                            model: ShortcutsManager.parseBadges(root.tempKeys)
                            delegate: Rectangle {
                                required property string modelData
                                height: 32
                                width: pTxt.implicitWidth + 18
                                radius: 8
                                color: Theme.cardSolid
                                border.width: 1
                                border.color: Theme.track
                                Text {
                                    id: pTxt
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: Theme.textPrimary
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                        Text {
                            visible: !root.tempKeys
                            text: "Nenhuma tecla selecionada"
                            color: Theme.textSecondary
                            font.family: Theme.font
                            font.pixelSize: 13
                        }
                    }
                }

                // Área Interativa de Captura pelo Teclado
                Rectangle {
                    id: keyCaptureZone
                    width: parent.width
                    height: 44
                    radius: 12
                    color: keyCaptureZone.activeFocus ? Theme.hover : Theme.field
                    border.width: keyCaptureZone.activeFocus ? 2 : 1
                    border.color: keyCaptureZone.activeFocus ? Theme.fill : Theme.track
                    focus: true

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Icon { name: "keyboard"; size: 16; tone: keyCaptureZone.activeFocus ? "white" : "gray"; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: keyCaptureZone.activeFocus ? "Pressione as teclas no teclado..." : "Clique aqui para gravar pelo teclado"
                            color: keyCaptureZone.activeFocus ? Theme.textPrimary : Theme.textSecondary
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.weight: keyCaptureZone.activeFocus ? Font.Medium : Font.Normal
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: keyCaptureZone.forceActiveFocus()
                    }

                    Keys.onPressed: event => {
                        event.accepted = true
                        let key = event.key
                        let text = event.text
                        let mods = event.modifiers

                        // Atualiza flags de modificadores
                        let s = (mods & Qt.MetaModifier) !== 0
                        let c = (mods & Qt.ControlModifier) !== 0
                        let sh = (mods & Qt.ShiftModifier) !== 0
                        let a = (mods & Qt.AltModifier) !== 0

                        // Verifica tecla principal
                        let k = root.keyToHypr(key, text)
                        if (k && !["SUPER", "CTRL", "SHIFT", "ALT"].includes(k.toUpperCase())) {
                            root.mainKey = k
                        }

                        // Se a tecla pressionada foi um modificador puro, alterna
                        if (key === Qt.Key_Super_L || key === Qt.Key_Super_R || key === Qt.Key_Meta) s = true
                        if (key === Qt.Key_Control) c = true
                        if (key === Qt.Key_Shift) sh = true
                        if (key === Qt.Key_Alt) a = true

                        root.modSuper = s
                        root.modCtrl = c
                        root.modShift = sh
                        root.modAlt = a
                        root.updateFromInputs()
                    }
                }

                // Seleção Manual de Modificadores (Permite 1, 2 ou 3 teclas)
                Column {
                    width: parent.width
                    spacing: 8
                    Text { text: "Modificadores (clique para alternar):"; color: Theme.textSecondary; font.pixelSize: 11; font.family: Theme.font }

                    Row {
                        spacing: 8
                        Repeater {
                            model: [
                                { label: "SUPER", prop: "modSuper" },
                                { label: "CTRL", prop: "modCtrl" },
                                { label: "SHIFT", prop: "modShift" },
                                { label: "ALT", prop: "modAlt" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool active: root[modelData.prop]
                                width: 94; height: 32; radius: 10
                                color: active ? Theme.fill : Theme.field
                                border.width: 1
                                border.color: active ? Theme.fill : Theme.track
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: active ? Theme.onAccent : Theme.textPrimary
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    font.weight: active ? Font.DemiBold : Font.Normal
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root[modelData.prop] = !root[modelData.prop]
                                        root.updateFromInputs()
                                    }
                                }
                            }
                        }
                    }
                }

                // Tecla Principal: Atalhos Populares / Seleção Rápida
                Column {
                    width: parent.width
                    spacing: 8
                    Text { text: "Tecla Principal:"; color: Theme.textSecondary; font.pixelSize: 11; font.family: Theme.font }

                    Flow {
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: ["space", "T", "Q", "F", "R", "W", "X", "comma", "Print", "1", "2", "3", "4", "5", "6", "7", "8", "9", "F10", "F11", "F12", "left", "right", "up", "down", "Page_Down", "Page_Up"]
                            delegate: Rectangle {
                                required property string modelData
                                readonly property bool cur: root.mainKey.toLowerCase() === modelData.toLowerCase()
                                height: 26
                                width: pkTxt.implicitWidth + 14
                                radius: 8
                                color: cur ? Theme.fill : (pkArea.containsMouse ? Theme.hover : Theme.field)
                                border.width: 1
                                border.color: cur ? Theme.fill : Theme.track
                                Text {
                                    id: pkTxt
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: cur ? Theme.onAccent : Theme.textPrimary
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    font.weight: cur ? Font.DemiBold : Font.Normal
                                }
                                MouseArea {
                                    id: pkArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.mainKey = modelData
                                        root.updateFromInputs()
                                    }
                                }
                            }
                        }
                    }
                }

                // Mensagem de Validação / Conflito
                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 10
                    color: root.tempConflict ? Qt.rgba(1, 0, 0, 0.1) : (root.isKeyCountValid() ? Qt.rgba(0, 0.8, 0, 0.1) : Qt.rgba(1, 0.6, 0, 0.1))
                    border.width: 1
                    border.color: root.tempConflict ? Theme.danger : "transparent"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: {
                                if (root.tempConflict) return "⚠️ Atalho já em uso por: " + root.tempConflict.name
                                let count = ShortcutsManager.countKeys(root.tempKeys)
                                if (count === 0) return "Selecione ao menos 1 tecla"
                                if (count > 3) return "Máximo de 3 teclas permitidas"
                                return "✓ Combinação disponível (" + count + (count === 1 ? " tecla)" : " teclas)")
                            }
                            color: root.tempConflict ? Theme.danger : (root.isKeyCountValid() ? Theme.textPrimary : Theme.textSecondary)
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                    }
                }

                // Botões do Rodapé do Modal
                Row {
                    anchors.right: parent.right
                    spacing: 10

                    PillButton {
                        text: "Restaurar Padrão"
                        outlined: true
                        onClicked: {
                            if (root.editingItem) {
                                root.setFromKeys(root.editingItem.defaultKeys)
                            }
                        }
                    }

                    PillButton {
                        text: "Cancelar"
                        outlined: true
                        onClicked: root.closeEditor()
                    }

                    PillButton {
                        text: "Confirmar"
                        primary: true
                        enabled: !root.tempConflict && root.isKeyCountValid()
                        opacity: enabled ? 1 : 0.4
                        onClicked: {
                            if (enabled && root.editingItem) {
                                ShortcutsManager.updateShortcut(root.editingItem.id, root.tempKeys)
                                root.closeEditor()
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
        root.editingItem = item
        root.setFromKeys(item.keys)
        keyCaptureZone.forceActiveFocus()
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
