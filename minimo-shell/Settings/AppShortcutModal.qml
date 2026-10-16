// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import QtQuick.Effects
import Quickshell
import "../Common"

// Modal de Criação de Atalho Personalizado para Aplicativos.
// Permite escolher qualquer app instalado (.desktop) ou digitar um comando de terminal,
// além de gravar a combinação de teclas de atalho com detecção de conflitos.
Rectangle {
    id: root

    property var page: null

    anchors.fill: parent
    color: Theme.scrim
    visible: page && page.addingAppShortcut
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150 } }
    z: 998

    // Estado da seleção do aplicativo
    property int tabIndex: 0 // 0: Aplicativo Instalado, 1: Comando Personalizado
    property var selectedApp: null
    property string appSearchQuery: ""
    property string customName: ""
    property string customExec: ""

    // Estado das teclas
    property string tempKeys: "SUPER + E"
    property var tempConflict: null
    property bool modSuper: true
    property bool modCtrl: false
    property bool modShift: false
    property bool modAlt: false
    property string mainKey: "E"

    function resetModal() {
        tabIndex = 0
        selectedApp = null
        appSearchQuery = ""
        customName = ""
        customExec = ""
        modSuper = true
        modCtrl = false
        modShift = false
        modAlt = false
        mainKey = "E"
        updateKeys()
    }

    onVisibleChanged: {
        if (visible) {
            resetModal()
        }
    }

    function isKeyCountValid() {
        let count = ShortcutsManager.countKeys(tempKeys)
        return count >= 1 && count <= 3
    }

    function updateKeys() {
        let parts = []
        if (modSuper) parts.push("SUPER")
        if (modCtrl) parts.push("CTRL")
        if (modShift) parts.push("SHIFT")
        if (modAlt) parts.push("ALT")
        if (mainKey && !["SUPER", "CTRL", "SHIFT", "ALT"].includes(mainKey.toUpperCase())) {
            parts.push(mainKey)
        }
        tempKeys = parts.join(" + ")
        tempConflict = ShortcutsManager.findConflict(null, tempKeys)
    }

    function isAppValid() {
        if (tabIndex === 0) {
            return selectedApp !== null
        } else {
            return customName.trim() !== "" && customExec.trim() !== ""
        }
    }

    function cleanExec(execStr) {
        if (!execStr) return ""
        return execStr.replace(/%[a-zA-Z]/g, "").trim()
    }

    function submit() {
        if (!isAppValid() || !isKeyCountValid() || tempConflict) return

        let name = ""
        let exec = ""
        let icon = ""

        if (tabIndex === 0 && selectedApp) {
            name = selectedApp.name || selectedApp.id
            exec = cleanExec(selectedApp.exec)
            icon = Apps.iconFor(selectedApp)
        } else {
            name = customName.trim()
            exec = customExec.trim()
            icon = Qt.resolvedUrl("../assets/icons/gray/terminal.svg")
        }

        ShortcutsManager.addAppShortcut(name, exec, icon, tempKeys)
        if (root.page) root.page.closeAppShortcutModal()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: if (root.page) root.page.closeAppShortcutModal()
    }

    Rectangle {
        id: modalCard
        width: 520
        height: Math.min(620, parent.height - 40)
        anchors.centerIn: parent
        radius: 28
        color: Theme.cardSolid
        border.width: 1
        border.color: Theme.track
        clip: true

        MouseArea { anchors.fill: parent } // não fechar ao clicar dentro do card

        Flickable {
            id: modalFlick
            anchors.fill: parent
            anchors.margins: 24
            contentHeight: modalCol.implicitHeight + 12
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: modalCol
                width: parent.width
                spacing: 14

                // Cabeçalho do Modal
                Row {
                    width: parent.width
                    spacing: 12
                    Rectangle {
                        width: 38; height: 38; radius: 12; color: Theme.field
                        anchors.verticalCenter: parent.verticalCenter
                        Icon {
                            anchors.centerIn: parent
                            name: "apps"
                            size: 20
                            tone: "dark"
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        width: parent.width - 90
                        Text {
                            text: "Adicionar Atalho de Aplicativo"
                            color: Theme.textPrimary
                            font.family: Theme.font
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "Vincule teclas de atalho para abrir qualquer programa instantaneamente"
                            color: Theme.textSecondary
                            font.family: Theme.font
                            font.pixelSize: 11
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
                            onClicked: if (root.page) root.page.closeAppShortcutModal()
                        }
                    }
                }

                // Aba de Modo: Aplicativo Instalado vs Comando Personalizado
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
                // SEÇÃO 1: ESCOLHA DO APLICATIVO
                // =============================================================

                // Caso Tab 0: Aplicativo Instalado
                Column {
                    width: parent.width
                    spacing: 8
                    visible: root.tabIndex === 0

                    Text {
                        text: "1. Aplicativo:"
                        color: Theme.textSecondary; font.pixelSize: 11; font.family: Theme.font; font.weight: Font.Medium
                    }

                    // Se nenhum aplicativo foi selecionado: Campo de busca + lista compacta
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

                        // Lista de resultados filtrada (rolável)
                        Rectangle {
                            width: parent.width
                            height: 130
                            radius: 14
                            color: Theme.field
                            clip: true

                            ListView {
                                id: appLv
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 4
                                clip: true
                                model: Apps.search(root.appSearchQuery, 12, true)
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
                                                text: root.cleanExec(modelData.exec)
                                                color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 10
                                                elide: Text.ElideRight; width: parent.width
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: aMouse
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.selectedApp = modelData
                                            // Se o nome tiver uma letra inicial marcante, podemos sugerir como tecla
                                            let letter = (modelData.name || "").charAt(0).toUpperCase()
                                            if (letter >= "A" && letter <= "Z") {
                                                root.mainKey = letter
                                                root.updateKeys()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Se um aplicativo já está selecionado: card de confirmação com botão de troca
                    Rectangle {
                        visible: root.selectedApp !== null
                        width: parent.width
                        height: 54
                        radius: 14
                        color: Theme.field
                        border.width: 1
                        border.color: Theme.fill

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 12

                            Image {
                                width: 34; height: 34
                                anchors.verticalCenter: parent.verticalCenter
                                source: root.selectedApp ? Apps.iconFor(root.selectedApp) : ""
                                sourceSize: Qt.size(68, 68)
                                fillMode: Image.PreserveAspectFit
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 130
                                spacing: 2
                                Text {
                                    text: root.selectedApp ? (root.selectedApp.name || root.selectedApp.id) : ""
                                    color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold
                                    elide: Text.ElideRight; width: parent.width
                                }
                                Text {
                                    text: root.selectedApp ? ("Executa: " + root.cleanExec(root.selectedApp.exec)) : ""
                                    color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 11
                                    elide: Text.ElideRight; width: parent.width
                                }
                            }

                            PillButton {
                                text: "Trocar"
                                outlined: true
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: root.selectedApp = null
                            }
                        }
                    }
                }

                // Caso Tab 1: Comando Personalizado
                Column {
                    width: parent.width
                    spacing: 8
                    visible: root.tabIndex === 1

                    Text {
                        text: "1. Comando e Nome:"
                        color: Theme.textSecondary; font.pixelSize: 11; font.family: Theme.font; font.weight: Font.Medium
                    }

                    // Campo de Nome
                    Rectangle {
                        width: parent.width
                        height: 38
                        radius: 12
                        color: Theme.field
                        border.width: cNameIn.activeFocus ? 1 : 0
                        border.color: Theme.fill

                        TextInput {
                            id: cNameIn
                            anchors.fill: parent
                            anchors.leftMargin: 12; anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 12
                            selectByMouse: true; clip: true
                            text: root.customName
                            onTextChanged: root.customName = text
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Nome (ex: Monitor Btop, Painel de Áudio)..."
                                color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                                visible: !cNameIn.text && !cNameIn.activeFocus
                            }
                        }
                    }

                    // Campo de Comando
                    Rectangle {
                        width: parent.width
                        height: 38
                        radius: 12
                        color: Theme.field
                        border.width: cExecIn.activeFocus ? 1 : 0
                        border.color: Theme.fill

                        TextInput {
                            id: cExecIn
                            anchors.fill: parent
                            anchors.leftMargin: 12; anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 12
                            selectByMouse: true; clip: true
                            text: root.customExec
                            onTextChanged: root.customExec = text
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Comando bash (ex: ghostty -e btop, pavucontrol)..."
                                color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                                visible: !cExecIn.text && !cExecIn.activeFocus
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.track }

                // =============================================================
                // SEÇÃO 2: COMBINAÇÃO DE TECLAS
                // =============================================================
                Column {
                    width: parent.width
                    spacing: 10

                    Text {
                        text: "2. Teclas de Atalho:"
                        color: Theme.textSecondary; font.pixelSize: 11; font.family: Theme.font; font.weight: Font.Medium
                    }

                    // Caixa de Pré-visualização da Combinação de Teclas
                    Rectangle {
                        width: parent.width
                        height: 50
                        radius: 12
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
                                    height: 30
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
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }
                            Text {
                                visible: !root.tempKeys
                                text: "Nenhuma tecla selecionada"
                                color: Theme.textSecondary
                                font.family: Theme.font
                                font.pixelSize: 12
                            }
                        }
                    }

                    // Área Interativa de Gravação pelo Teclado
                    Rectangle {
                        id: appKeyZone
                        width: parent.width
                        height: 40
                        radius: 10
                        color: appKeyZone.activeFocus ? Theme.hover : Theme.field
                        border.width: appKeyZone.activeFocus ? 2 : 1
                        border.color: appKeyZone.activeFocus ? Theme.fill : Theme.track
                        focus: true

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Icon {
                                name: "keyboard"
                                size: 14
                                tone: appKeyZone.activeFocus ? "white" : "gray"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: appKeyZone.activeFocus ? "Pressione as teclas no teclado..." : "Clique aqui para gravar pelo teclado físico"
                                color: appKeyZone.activeFocus ? Theme.textPrimary : Theme.textSecondary
                                font.family: Theme.font
                                font.pixelSize: 11
                                font.weight: appKeyZone.activeFocus ? Font.Medium : Font.Normal
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: appKeyZone.forceActiveFocus()
                        }

                        Keys.onPressed: event => {
                            event.accepted = true
                            let key = event.key
                            let text = event.text
                            let mods = event.modifiers

                            if (key === Qt.Key_Backspace || key === Qt.Key_Delete) {
                                root.mainKey = ""
                                root.updateKeys()
                                return
                            }

                            let s = (mods & Qt.MetaModifier) !== 0
                            let c = (mods & Qt.ControlModifier) !== 0
                            let sh = (mods & Qt.ShiftModifier) !== 0
                            let a = (mods & Qt.AltModifier) !== 0

                            let isModOnly = false
                            if (key === Qt.Key_Super_L || key === Qt.Key_Super_R || key === Qt.Key_Meta) { s = true; isModOnly = true }
                            if (key === Qt.Key_Control) { c = true; isModOnly = true }
                            if (key === Qt.Key_Shift) { sh = true; isModOnly = true }
                            if (key === Qt.Key_Alt) { a = true; isModOnly = true }

                            if (!isModOnly) {
                                let k = ShortcutsManager.keyToHypr(key, text)
                                if (k && !["SUPER", "CTRL", "SHIFT", "ALT"].includes(k.toUpperCase())) {
                                    root.mainKey = k
                                }
                            }

                            root.modSuper = s
                            root.modCtrl = c
                            root.modShift = sh
                            root.modAlt = a
                            root.updateKeys()
                        }
                    }

                    // Botões de Modificadores (SUPER, CTRL, SHIFT, ALT)
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
                                width: (modalCol.width - 24) / 4; height: 30; radius: 8
                                color: active ? Theme.fill : Theme.field
                                border.width: 1
                                border.color: active ? Theme.fill : Theme.track
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: active ? Theme.onAccent : Theme.textPrimary
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    font.weight: active ? Font.DemiBold : Font.Normal
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root[modelData.prop] = !root[modelData.prop]
                                        root.updateKeys()
                                    }
                                }
                            }
                        }
                    }

                    // Teclas Populares Rápida Escolha
                    Flow {
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: [
                                "E", "B", "F", "T", "N", "C", "W", "D", "M", "V", "P", "R", "Q", "I",
                                "space", "Return", "1", "2", "3", "4", "5"
                            ]
                            delegate: Rectangle {
                                required property string modelData
                                readonly property bool cur: root.mainKey.toLowerCase() === modelData.toLowerCase()
                                height: 24
                                width: pkTxt.implicitWidth + 14
                                radius: 7
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
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.mainKey.toLowerCase() === modelData.toLowerCase()) {
                                            root.mainKey = ""
                                        } else {
                                            root.mainKey = modelData
                                        }
                                        root.updateKeys()
                                    }
                                }
                            }
                        }
                    }

                    // Validação de Conflitos e Teclas
                    Rectangle {
                        width: parent.width
                        height: 32
                        radius: 8
                        color: root.tempConflict ? Qt.rgba(1, 0, 0, 0.1) : (root.isKeyCountValid() ? Qt.rgba(0, 0.8, 0, 0.1) : Qt.rgba(1, 0.6, 0, 0.1))
                        border.width: 1
                        border.color: root.tempConflict ? Theme.danger : "transparent"

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: {
                                    if (root.tempConflict) return "⚠️ Atalho já em uso por: " + root.tempConflict.name
                                    let count = ShortcutsManager.countKeys(root.tempKeys)
                                    if (count === 0) return "Defina ao menos 1 tecla"
                                    if (count > 3) return "Máximo de 3 teclas permitidas"
                                    return "✓ Combinação disponível (" + count + (count === 1 ? " tecla)" : " teclas)")
                                }
                                color: root.tempConflict ? Theme.danger : (root.isKeyCountValid() ? Theme.textPrimary : Theme.textSecondary)
                                font.family: Theme.font
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }
                    }
                }

                // =============================================================
                // SEÇÃO 3: BOTÕES DE AÇÃO
                // =============================================================
                Row {
                    anchors.right: parent.right
                    spacing: 10

                    PillButton {
                        text: "Cancelar"
                        outlined: true
                        onClicked: if (root.page) root.page.closeAppShortcutModal()
                    }

                    PillButton {
                        text: "Adicionar Atalho"
                        primary: true
                        readonly property bool ready: root.isAppValid() && root.isKeyCountValid() && !root.tempConflict
                        enabled: ready
                        opacity: ready ? 1 : 0.4
                        onClicked: root.submit()
                    }
                }
            }
        }
    }
}
