// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../Common"

// Personalización: fondo de pantalla + opciones de la isla y del personaje.
Column {
    id: root
    spacing: 20
    signal pickerOpened()       // el selector de archivos necesita el teclado

    readonly property string mainDir: Quickshell.env("HOME") + "/Imagens/Wallpapers"
    property var images: []
    property bool cursorDrawerOpen: false
    property bool iconDrawerOpen: false

    function refresh() {
        scan.running = false
        scan.running = true
        ThemeState.refresh()
    }
    Component.onCompleted: refresh()

    // Apenas papéis de parede reais: o atual, os escolhidos antes e os que o usuário adicionou
    // em ~/Imagens/Wallpapers (sem os de exemplo "minimo-*"). Arquivos inexistentes são descartados.
    Process {
        id: scan
        property var found: []
        command: ["sh", "-c",
            'mkdir -p "$HOME/Imagens/Wallpapers"; for f in "$@"; do [ -f "$f" ] && echo "$f" || echo "!$f"; done; ' +
            'for d in "$HOME/Imagens/Wallpapers" "$HOME/Imagens/Fondos" "$HOME/Pictures/Wallpapers" "$HOME/Imágenes/Fondos"; do [ -d "$d" ] && find "$d" -maxdepth 1 -type f \\( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \\) | sort; done',
            "sh"].concat(DisplayState.wallpaper ? [DisplayState.wallpaper] : []).concat(DisplayState.wallpaperHistory)
        stdout: SplitParser { onRead: line => scan.found.push(line) }
        onStarted: found = []
        onExited: {
            const missing = found.filter(l => l.startsWith("!")).map(l => l.slice(1))
            const ok = found.filter(l => l !== "" && !l.startsWith("!"))
            root.images = ok.filter((p, i) => ok.indexOf(p) === i)
            if (missing.some(p => DisplayState.wallpaperHistory.indexOf(p) >= 0)) DisplayState.forgetWallpapers(missing)
        }
    }
    Process {
        id: picker
        command: ["zenity", "--file-selection", "--title=Escolher papel de parede",
                  "--filename=" + root.mainDir + "/",
                  "--file-filter=Imagens | *.png *.jpg *.jpeg *.webp"]
        stdout: SplitParser { onRead: line => { if (line.trim() !== "") DisplayState.setWallpaper(line.trim()) } }
        onExited: root.refresh()
    }

    SectionTitle { text: "Papel de parede" }

    Grid {
        id: grid
        columns: 3
        spacing: 14
        width: parent.width
        readonly property real tileW: (width - spacing * (columns - 1)) / columns

        Repeater {
            model: root.images
            delegate: Item {
                required property string modelData
                readonly property bool current: modelData === DisplayState.wallpaper
                width: grid.tileW; height: Math.round(grid.tileW * 10 / 16)

                Image {
                    id: thumb
                    anchors.fill: parent; anchors.margins: 4
                    source: "file://" + modelData
                    sourceSize: Qt.size(400, 250)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }
                Item {
                    id: mask
                    anchors.fill: thumb
                    visible: false
                    layer.enabled: true
                    layer.smooth: true
                    Rectangle { anchors.fill: parent; radius: 14; antialiasing: true }
                }
                Rectangle { anchors.fill: thumb; radius: 14; color: Theme.field }
                MultiEffect {
                    anchors.fill: thumb
                    source: thumb
                    maskEnabled: true
                    maskSource: mask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }
                Rectangle {
                    anchors.fill: parent; radius: 18
                    color: "transparent"
                    border.width: current ? 2.5 : (tm.containsMouse ? 1.5 : 0)
                    border.color: current ? Theme.textPrimary : Theme.track
                    antialiasing: true
                }
                MouseArea {
                    id: tm
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: DisplayState.setWallpaper(modelData)
                }
            }
        }
    }

    Row {
        spacing: 8
        PillButton { icon: "folder"; text: "Escolher imagem…"; onClicked: if (!picker.running) { root.pickerOpened(); picker.running = true } }
        PillButton { text: "Sem fundo"; outlined: true; onClicked: DisplayState.setWallpaper("") }
    }
    Text { text: "Pasta: ~/Imagens/Wallpapers"; color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 11 }

    SectionTitle { text: "Aparência" }
    Rectangle {
        width: parent.width
        height: ap.implicitHeight
        radius: 20
        color: Theme.field

        Column {
            id: ap
            width: parent.width

            // 1. Modo de Cor (Claro / Escuro)
            Item {
                width: parent.width; height: 56
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Modo do sistema"
                    color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium
                }
                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                    width: 184; height: 32; radius: 16; color: Theme.raised
                    Row {
                        anchors.fill: parent; anchors.margins: 3
                        Repeater {
                            model: [{ id: "light", label: "Claro" }, { id: "dark", label: "Escuro" }]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool cur: DisplayState.theme === modelData.id
                                width: parent.width / 2; height: parent.height; radius: height / 2
                                color: cur ? Theme.fill : (thm.containsMouse ? Theme.field : "transparent")
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: parent.cur ? Theme.onAccent : Theme.textPrimary
                                    font.family: Theme.font; font.pixelSize: 12
                                    font.weight: parent.cur ? Font.DemiBold : Font.Normal
                                }
                                MouseArea { id: thm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: DisplayState.setTheme(modelData.id) }
                            }
                        }
                    }
                }
            }

            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

            // 2. Tema do Cursor do Mouse
            Item {
                width: parent.width
                height: Math.max(64, cursorTextCol.implicitHeight + 20)

                Column {
                    id: cursorTextCol
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: cursorPill.left; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Tema do cursor do mouse"
                        color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: {
                            const cur = ThemeState.cursorThemes.find(t => t.id === ThemeState.currentCursor)
                            return cur ? cur.name : ThemeState.currentCursor
                        }
                        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                    }
                }

                Rectangle {
                    id: cursorPill
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: cursorBtnRow.implicitWidth + 24; height: 32; radius: 16
                    color: cursorMouse.containsMouse ? Theme.hover : Theme.raised
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Row {
                        id: cursorBtnRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: root.cursorDrawerOpen ? "Fechar" : "Alterar..."
                            color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium
                        }
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "chevron"
                            size: 14
                            rotation: root.cursorDrawerOpen ? 90 : 0
                            Behavior on rotation { NumberAnimation { duration: 180 } }
                        }
                    }

                    MouseArea {
                        id: cursorMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.cursorDrawerOpen = !root.cursorDrawerOpen
                            if (root.cursorDrawerOpen) root.iconDrawerOpen = false
                        }
                    }
                }
            }

            // Gaveta de seleção de temas de cursor
            Column {
                id: cursorDrawer
                width: parent.width
                height: root.cursorDrawerOpen ? implicitHeight : 0
                visible: height > 0 || root.cursorDrawerOpen
                clip: true
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

                Repeater {
                    model: ThemeState.cursorThemes
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isSelected: ThemeState.currentCursor === modelData.id
                        width: parent.width
                        height: 52
                        color: cItemMouse.containsMouse ? Theme.hover : "transparent"

                        Row {
                            anchors.left: parent.left; anchors.leftMargin: 24
                            anchors.right: parent.right; anchors.rightMargin: 24
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Rectangle {
                                width: 8; height: 8; radius: 4
                                anchors.verticalCenter: parent.verticalCenter
                                color: parent.parent.isSelected ? Theme.fill : "transparent"
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 50
                                spacing: 2

                                Text {
                                    text: modelData.name || modelData.id
                                    color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 13
                                    font.weight: parent.parent.isSelected ? Font.Bold : Font.Normal
                                }
                                Text {
                                    visible: (modelData.comment || "") !== ""
                                    text: modelData.comment || ""
                                    color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 11
                                    elide: Text.ElideRight; width: parent.width
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: parent.parent.isSelected
                                text: "Ativo"
                                color: Theme.fill; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            id: cItemMouse
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ThemeState.setCursorTheme(modelData.id)
                                root.cursorDrawerOpen = false
                            }
                        }
                    }
                }
            }

            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

            // 3. Tamanho do Cursor
            Item {
                width: parent.width
                height: 56

                Column {
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        text: "Tamanho do cursor"
                        color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium
                    }
                    Text {
                        text: "Dimensão em pixels"
                        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                    }
                }

                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                    width: 240; height: 32; radius: 16; color: Theme.raised
                    Row {
                        anchors.fill: parent; anchors.margins: 3
                        Repeater {
                            model: [24, 28, 32, 48]
                            delegate: Rectangle {
                                required property int modelData
                                readonly property bool cur: ThemeState.currentCursorSize === modelData
                                width: parent.width / 4; height: parent.height; radius: height / 2
                                color: cur ? Theme.fill : (cszMouse.containsMouse ? Theme.field : "transparent")
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData + " px"
                                    color: parent.cur ? Theme.onAccent : Theme.textPrimary
                                    font.family: Theme.font; font.pixelSize: 11
                                    font.weight: parent.cur ? Font.DemiBold : Font.Normal
                                }
                                MouseArea {
                                    id: cszMouse
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: ThemeState.setCursorSize(modelData)
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

            // 4. Tema de Ícones
            Item {
                width: parent.width
                height: Math.max(64, iconTextCol.implicitHeight + 20)

                Column {
                    id: iconTextCol
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: iconPill.left; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Tema de ícones"
                        color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: {
                            const cur = ThemeState.iconThemes.find(t => t.id === ThemeState.currentIcon)
                            return cur ? cur.name : ThemeState.currentIcon
                        }
                        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12
                    }
                }

                Rectangle {
                    id: iconPill
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: iconBtnRow.implicitWidth + 24; height: 32; radius: 16
                    color: iconMouse.containsMouse ? Theme.hover : Theme.raised
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Row {
                        id: iconBtnRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: root.iconDrawerOpen ? "Fechar" : "Alterar..."
                            color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium
                        }
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "chevron"
                            size: 14
                            rotation: root.iconDrawerOpen ? 90 : 0
                            Behavior on rotation { NumberAnimation { duration: 180 } }
                        }
                    }

                    MouseArea {
                        id: iconMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.iconDrawerOpen = !root.iconDrawerOpen
                            if (root.iconDrawerOpen) root.cursorDrawerOpen = false
                        }
                    }
                }
            }

            // Gaveta de seleção de temas de ícones
            Column {
                id: iconDrawer
                width: parent.width
                height: root.iconDrawerOpen ? implicitHeight : 0
                visible: height > 0 || root.iconDrawerOpen
                clip: true
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }

                Repeater {
                    model: ThemeState.iconThemes
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isSelected: ThemeState.currentIcon === modelData.id
                        width: parent.width
                        height: 52
                        color: iItemMouse.containsMouse ? Theme.hover : "transparent"

                        Row {
                            anchors.left: parent.left; anchors.leftMargin: 24
                            anchors.right: parent.right; anchors.rightMargin: 24
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Rectangle {
                                width: 8; height: 8; radius: 4
                                anchors.verticalCenter: parent.verticalCenter
                                color: parent.parent.isSelected ? Theme.fill : "transparent"
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 50
                                spacing: 2

                                Text {
                                    text: modelData.name || modelData.id
                                    color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 13
                                    font.weight: parent.parent.isSelected ? Font.Bold : Font.Normal
                                }
                                Text {
                                    visible: (modelData.comment || "") !== ""
                                    text: modelData.comment || ""
                                    color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 11
                                    elide: Text.ElideRight; width: parent.width
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: parent.parent.isSelected
                                text: "Ativo"
                                color: Theme.fill; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            id: iItemMouse
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ThemeState.setIconTheme(modelData.id)
                                root.iconDrawerOpen = false
                            }
                        }
                    }
                }
            }
        }
    }

    Row {
        spacing: 6
        Icon { name: "folder"; size: 13; tone: "gray"; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: "Onde instalar temas: ~/.icons ou ~/.local/share/icons (ou pacotes pacman/AUR)"
            color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 11
        }
    }

    SectionTitle { text: "Ilha dinâmica" }
    Rectangle {
        width: parent.width
        height: opts.implicitHeight
        radius: 20
        color: Theme.field
        Column {
            id: opts
            width: parent.width
            SwitchRow {
                width: parent.width
                text: "Ocultar ilha automaticamente"
                detail: "Esconde no topo e aparece ao passar o mouse."
                checked: DisplayState.islandAutoHide
                onToggled: v => DisplayState.setIslandAutoHide(v)
            }
            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }
            SwitchRow {
                width: parent.width
                text: "Ocultamento inteligente"
                detail: "Oculta a ilha quando há um aplicativo aberto na área de trabalho."
                checked: DisplayState.islandSmartHide
                onToggled: v => DisplayState.setIslandSmartHide(v)
            }
            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }
            SwitchRow {
                width: parent.width
                text: "Personagem animado"
                detail: "Segue o mouse, pisca, dança e dorme."
                checked: DisplayState.characterAnimated
                onToggled: v => DisplayState.setCharacterAnimated(v)
            }
            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }
            // Dormir após inatividade (segmentado 1/2/5 min).
            Item {
                width: parent.width; height: 64
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text { text: "Dormir após inatividade"; color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14 }
                    Text { text: "Sem teclado ou mouse em todo o computador."; color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12 }
                }
                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                    width: 168; height: 32; radius: 16; color: Theme.raised
                    Row {
                        anchors.fill: parent; anchors.margins: 3
                        Repeater {
                            model: [1, 2, 5]
                            delegate: Rectangle {
                                required property int modelData
                                readonly property bool cur: DisplayState.sleepMinutes === modelData
                                width: parent.width / 3; height: parent.height; radius: height / 2
                                color: cur ? Theme.fill : (zm.containsMouse ? Theme.field : "transparent")
                                Text { anchors.centerIn: parent; text: modelData + " min"; color: parent.cur ? Theme.onAccent : Theme.textPrimary; font.family: Theme.font; font.pixelSize: 12; font.weight: parent.cur ? Font.DemiBold : Font.Normal }
                                MouseArea { id: zm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: DisplayState.setSleepMinutes(modelData) }
                            }
                        }
                    }
                }
            }
        }
    }
}
