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

    readonly property string mainDir: Quickshell.env("HOME") + "/Imágenes/Fondos"
    property var images: []

    function refresh() { scan.running = false; scan.running = true }
    Component.onCompleted: refresh()

    Process {
        id: scan
        property var found: []
        command: ["sh", "-c",
            'mkdir -p "$HOME/Imágenes/Fondos"; for d in "$HOME/Imágenes/Fondos" "$HOME/Pictures/Wallpapers" "$HOME/Imágenes"; do ' +
            '[ -d "$d" ] && find "$d" -maxdepth 1 -type f \\( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \\) | sort; done | awk "!seen[\\$0]++"']
        stdout: SplitParser { onRead: line => scan.found.push(line) }
        onStarted: found = []
        // El fondo actual siempre aparece (aunque esté en otra carpeta).
        onExited: root.images = (DisplayState.wallpaper && found.indexOf(DisplayState.wallpaper) < 0) ? [DisplayState.wallpaper].concat(found) : found
    }
    Process {
        id: picker
        command: ["zenity", "--file-selection", "--title=Elegir fondo de pantalla",
                  "--filename=" + root.mainDir + "/",
                  "--file-filter=Imágenes | *.png *.jpg *.jpeg *.webp"]
        stdout: SplitParser { onRead: line => { if (line.trim() !== "") DisplayState.setWallpaper(line.trim()) } }
        onExited: root.refresh()
    }

    SectionTitle { text: "Fondo de pantalla" }

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
        PillButton { icon: "folder"; text: "Elegir imagen…"; onClicked: if (!picker.running) { root.pickerOpened(); picker.running = true } }
        PillButton { text: "Sin fondo"; outlined: true; onClicked: DisplayState.setWallpaper("") }
    }
    Text { text: "Carpeta: ~/Imágenes/Fondos"; color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 11 }

    SectionTitle { text: "Apariencia" }
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
                Text { anchors.left: parent.left; anchors.leftMargin: 18; anchors.verticalCenter: parent.verticalCenter; text: "Apariencia"; color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14 }
                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                    width: 184; height: 32; radius: 16; color: Theme.raised
                    Row {
                        anchors.fill: parent; anchors.margins: 3
                        Repeater {
                            model: [{ id: "light", label: "Claro" }, { id: "dark", label: "Oscuro" }]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool cur: DisplayState.theme === modelData.id
                                width: parent.width / 2; height: parent.height; radius: height / 2
                                color: cur ? Theme.fill : (tm.containsMouse ? Theme.field : "transparent")
                                Text { anchors.centerIn: parent; text: modelData.label; color: parent.cur ? Theme.onAccent : Theme.textPrimary; font.family: Theme.font; font.pixelSize: 12; font.weight: parent.cur ? Font.DemiBold : Font.Normal }
                                MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: DisplayState.setTheme(modelData.id) }
                            }
                        }
                    }
                }
            }
        }
    }

    SectionTitle { text: "Isla dinámica" }
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
                text: "Ocultar isla automáticamente"
                detail: "Se esconde arriba y aparece al pasar el mouse."
                checked: DisplayState.islandAutoHide
                onToggled: v => DisplayState.setIslandAutoHide(v)
            }
            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }
            SwitchRow {
                width: parent.width
                text: "Ocultamiento inteligente"
                detail: "Oculta la isla cuando hay una app abierta en el escritorio."
                checked: DisplayState.islandSmartHide
                onToggled: v => DisplayState.setIslandSmartHide(v)
            }
            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }
            SwitchRow {
                width: parent.width
                text: "Personaje animado"
                detail: "Sigue el mouse, parpadea, baila y se duerme."
                checked: DisplayState.characterAnimated
                onToggled: v => DisplayState.setCharacterAnimated(v)
            }
            Rectangle { x: 18; width: parent.width - 36; height: 1; color: Theme.track }
            // Dormir tras inactividad (segmentado 1/2/5 min).
            Item {
                width: parent.width; height: 64
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text { text: "Dormir tras inactividad"; color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14 }
                    Text { text: "Sin teclado ni mouse en toda la PC."; color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12 }
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
