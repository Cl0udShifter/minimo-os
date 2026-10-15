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

    function refresh() { scan.running = false; scan.running = true }
    Component.onCompleted: refresh()

    // Apenas papéis de parede reais: o atual, os escolhidos antes e os que o usuário adicionou
    // em ~/Imagens/Wallpapers (sem os de exemplo "minimo-*"). Arquivos inexistentes são descartados.
    Process {
        id: scan
        property var found: []
        command: ["sh", "-c",
            'mkdir -p "$HOME/Imagens/Wallpapers"; for f in "$@"; do [ -f "$f" ] && echo "$f" || echo "!$f"; done; ' +
            'for d in "$HOME/Imagens/Wallpapers" "$HOME/Imagens/Fondos" "$HOME/Pictures/Wallpapers" "$HOME/Imágenes/Fondos"; do [ -d "$d" ] && find "$d" -maxdepth 1 -type f ! -name "minimo-*" \\( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \\) | sort; done',
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
            Item {
                width: parent.width; height: 56
                Text { anchors.left: parent.left; anchors.leftMargin: 18; anchors.verticalCenter: parent.verticalCenter; text: "Aparência"; color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14 }
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
                                Text { anchors.centerIn: parent; text: modelData.label; color: parent.cur ? Theme.onAccent : Theme.textPrimary; font.family: Theme.font; font.pixelSize: 12; font.weight: parent.cur ? Font.DemiBold : Font.Normal }
                                MouseArea { id: thm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: DisplayState.setTheme(modelData.id) }
                            }
                        }
                    }
                }
            }
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
