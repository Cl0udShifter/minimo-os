// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import QtQuick.Effects
import "../Common"

// Modal de Edição de Atalho de Teclado, apresentado centralizado sobre o card de Configurações.
Rectangle {
    id: root

    property var page: null

    anchors.fill: parent
    color: Theme.scrim
    visible: page && page.editingItem !== null
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150 } }
    z: 999

    MouseArea {
        anchors.fill: parent
        onClicked: if (root.page) root.page.closeEditor()
    }

    Rectangle {
        id: modalCard
        width: 480
        height: modalCol.implicitHeight + 48
        anchors.centerIn: parent
        radius: 28
        color: Theme.cardSolid
        border.width: 1
        border.color: Theme.track

        MouseArea { anchors.fill: parent } // não fechar ao clicar dentro do card

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
                    Image {
                        visible: root.page && root.page.editingItem && root.page.editingItem.isCustomApp
                        anchors.centerIn: parent
                        width: 24; height: 24
                        source: (root.page && root.page.editingItem && root.page.editingItem.isCustomApp && root.page.editingItem.icon) ? root.page.editingItem.icon : ""
                        sourceSize: Qt.size(48, 48)
                        fillMode: Image.PreserveAspectFit
                    }
                    Icon {
                        visible: !root.page || !root.page.editingItem || !root.page.editingItem.isCustomApp
                        anchors.centerIn: parent
                        name: (root.page && root.page.editingItem) ? (root.page.editingItem.icon || "keyboard") : "keyboard"
                        size: 20
                        tone: "dark"
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    width: parent.width - 90
                    Text {
                        text: (root.page && root.page.editingItem) ? root.page.editingItem.name : ""
                        color: Theme.textPrimary
                        font.family: Theme.font
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: (root.page && root.page.editingItem) ? root.page.editingItem.desc : ""
                        color: Theme.textSecondary
                        font.family: Theme.font
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
                // Botão Fechar (X)
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: closeMa.containsMouse ? Theme.hover : Theme.field
                    anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: "✕"; color: Theme.textSecondary; font.pixelSize: 13 }
                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.page) root.page.closeEditor()
                    }
                }
            }

            // Caixa de Pré-visualização da Combinação de Teclas
            Rectangle {
                width: parent.width
                height: 56
                radius: 14
                color: Theme.field
                border.width: 1
                border.color: (root.page && root.page.tempConflict) ? Theme.danger : Theme.track

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Repeater {
                        model: root.page ? ShortcutsManager.parseBadges(root.page.tempKeys) : []
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
                        visible: !root.page || !root.page.tempKeys
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
                    Icon {
                        name: "keyboard"
                        size: 16
                        tone: keyCaptureZone.activeFocus ? "white" : "gray"
                        anchors.verticalCenter: parent.verticalCenter
                    }
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
                    if (!root.page) return
                    event.accepted = true
                    let key = event.key
                    let text = event.text
                    let mods = event.modifiers

                    // Se pressionar Backspace ou Delete, limpa a tecla principal
                    if (key === Qt.Key_Backspace || key === Qt.Key_Delete) {
                        root.page.mainKey = ""
                        root.page.updateFromInputs()
                        return
                    }

                    // Atualiza flags de modificadores
                    let s = (mods & Qt.MetaModifier) !== 0
                    let c = (mods & Qt.ControlModifier) !== 0
                    let sh = (mods & Qt.ShiftModifier) !== 0
                    let a = (mods & Qt.AltModifier) !== 0

                    // Se a tecla pressionada for um modificador isolado
                    let isModOnly = false
                    if (key === Qt.Key_Super_L || key === Qt.Key_Super_R || key === Qt.Key_Meta) { s = true; isModOnly = true }
                    if (key === Qt.Key_Control) { c = true; isModOnly = true }
                    if (key === Qt.Key_Shift) { sh = true; isModOnly = true }
                    if (key === Qt.Key_Alt) { a = true; isModOnly = true }

                    // Verifica tecla principal se não for modificador puro
                    if (!isModOnly) {
                        let k = root.page.keyToHypr(key, text)
                        if (k && !["SUPER", "CTRL", "SHIFT", "ALT"].includes(k.toUpperCase())) {
                            root.page.mainKey = k
                        }
                    }

                    root.page.modSuper = s
                    root.page.modCtrl = c
                    root.page.modShift = sh
                    root.page.modAlt = a
                    root.page.updateFromInputs()
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
                            readonly property bool active: root.page ? root.page[modelData.prop] : false
                            width: 100; height: 32; radius: 10
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
                                    if (root.page) {
                                        root.page[modelData.prop] = !root.page[modelData.prop]
                                        root.page.updateFromInputs()
                                    }
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

                Row {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Tecla Principal:"
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        font.family: Theme.font
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Badge mostrando a tecla selecionada com botão para remover
                    Rectangle {
                        visible: root.page ? (root.page.mainKey !== "") : false
                        height: 22
                        width: remKeyRow.implicitWidth + 14
                        radius: 6
                        color: Theme.hover
                        border.width: 1
                        border.color: Theme.track
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            id: remKeyRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: root.page ? root.page.mainKey : ""
                                color: Theme.textPrimary
                                font.family: Theme.font
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "✕"
                                color: Theme.danger
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.page) {
                                    root.page.mainKey = ""
                                    root.page.updateFromInputs()
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.page ? (root.page.mainKey !== "") : false
                        text: "(clique para remover)"
                        color: Theme.textSecondary
                        font.pixelSize: 10
                        font.family: Theme.font
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Flow {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: [
                            "space", "backslash", "slash", "Tab", "Return", "Escape",
                            "T", "Q", "F", "R", "W", "X", "comma", "period", "minus", "equal",
                            "Print", "1", "2", "3", "4", "5", "6", "7", "8", "9",
                            "F10", "F11", "F12", "left", "right", "up", "down", "Page_Down", "Page_Up"
                        ]
                        delegate: Rectangle {
                            required property string modelData
                            readonly property bool cur: (root.page && root.page.mainKey.toLowerCase() === modelData.toLowerCase())
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
                                    if (root.page) {
                                        if (root.page.mainKey.toLowerCase() === modelData.toLowerCase()) {
                                            root.page.mainKey = ""
                                        } else {
                                            root.page.mainKey = modelData
                                        }
                                        root.page.updateFromInputs()
                                    }
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
                color: (root.page && root.page.tempConflict) ? Qt.rgba(1, 0, 0, 0.1) : ((root.page && root.page.isKeyCountValid()) ? Qt.rgba(0, 0.8, 0, 0.1) : Qt.rgba(1, 0.6, 0, 0.1))
                border.width: 1
                border.color: (root.page && root.page.tempConflict) ? Theme.danger : "transparent"

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: {
                            if (!root.page) return ""
                            if (root.page.tempConflict) return "⚠️ Atalho já em uso por: " + root.page.tempConflict.name
                            let count = ShortcutsManager.countKeys(root.page.tempKeys)
                            if (count === 0) return "Selecione ao menos 1 tecla"
                            if (count > 3) return "Máximo de 3 teclas permitidas"
                            return "✓ Combinação disponível (" + count + (count === 1 ? " tecla)" : " teclas)")
                        }
                        color: (root.page && root.page.tempConflict) ? Theme.danger : ((root.page && root.page.isKeyCountValid()) ? Theme.textPrimary : Theme.textSecondary)
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
                    visible: root.page && root.page.editingItem && !root.page.editingItem.isCustomApp
                    text: "Restaurar Padrão"
                    outlined: true
                    onClicked: {
                        if (root.page && root.page.editingItem) {
                            root.page.setFromKeys(root.page.editingItem.defaultKeys)
                        }
                    }
                }

                PillButton {
                    text: "Cancelar"
                    outlined: true
                    onClicked: if (root.page) root.page.closeEditor()
                }

                PillButton {
                    text: "Confirmar"
                    primary: true
                    enabled: root.page ? (!root.page.tempConflict && root.page.isKeyCountValid()) : false
                    opacity: enabled ? 1 : 0.4
                    onClicked: {
                        if (enabled && root.page && root.page.editingItem) {
                            ShortcutsManager.updateShortcut(root.page.editingItem.id, root.page.tempKeys)
                            root.page.closeEditor()
                        }
                    }
                }
            }
        }
    }
}
