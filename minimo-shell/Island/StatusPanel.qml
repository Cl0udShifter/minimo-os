// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import "../Common"
import "../Character"

// Panel de estado del sistema (se abre deslizando sobre la isla): Internet, Recursos, Dispositivos.
// Consulta datos solo mientras está abierto.
Item {
    id: root
    property bool open: false
    implicitHeight: col.implicitHeight + 32

    onOpenChanged: {
        open ? SysStatus.acquire() : SysStatus.release()
        if (open) greetLater.restart()
        if (!open) audioRow.menuOpen = false
    }
    Timer { id: greetLater; interval: 280; onTriggered: chr.react("greet") }

    // Ánimo del personaje según el estado: sin internet → preocupado; CPU >85 % o
    // temperatura alta (≥85 °C CPU / ≥85 °C GPU) → cansado; si no, feliz.
    readonly property string mood: SysStatus.known && !SysStatus.online ? "worried"
        : (r && (r.cpu > 85 || (r.temp !== null && r.temp !== undefined && r.temp >= 85)))
          || (SysStatus.gpu && SysStatus.gpu.temp >= 85) ? "tired" : ""
    Component.onDestruction: if (open) SysStatus.release()

    readonly property var r: SysStatus.res
    readonly property var n: SysStatus.net
    readonly property var d: SysStatus.dev

    component Title: Text {
        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold
        leftPadding: 4
    }
    component Row2: Item {
        id: rw
        property string icon
        property string label
        property string value
        property color valueColor: Theme.textSecondary
        width: parent ? parent.width : 0; height: 40
        Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; name: rw.icon; size: 18; tone: "dark" }
        Text {
            x: 44; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.5 - 44
            text: rw.label; color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; elide: Text.ElideRight
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.5 - 14; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight
            text: rw.value; color: rw.valueColor; font.family: Theme.font; font.pixelSize: 13; font.features: { "tnum": 1 }
        }
    }
    component Card: Rectangle {
        default property alias content: inner.children
        width: parent ? parent.width : 0; height: inner.implicitHeight + 8
        radius: 18; color: Theme.field
        Column { id: inner; y: 4; width: parent.width }
    }
    component Bar: Item {
        id: br
        property real frac: 0
        width: parent ? parent.width - 28 : 0; x: 14; height: 10
        Rectangle {
            anchors.top: parent.top; width: parent.width; height: 4; radius: 2; color: Theme.track
            Rectangle {
                height: parent.height; radius: 2; color: br.frac > 0.9 ? Theme.danger : Theme.fill
                width: parent.width * Math.max(0, Math.min(1, br.frac))
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
    }

    Column {
        id: col
        x: 16; y: 16; width: parent.width - 32
        spacing: 8

        // Personaje: sigue el mouse solo con el panel abierto (activo = visible).
        Item {
            width: parent.width; height: 76
            Character {
                id: chr
                size: 60
                anchors.centerIn: parent
                active: root.open && DisplayState.characterAnimated
                mood: root.mood
                // Clic → reacción; varios clics seguidos → caricias.
                MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: m => chr.clicked((m.x - width / 2) / (width / 2)) }
            }
        }

        // Internet
        Title { text: "Internet" }
        Card {
            Row2 {
                icon: root.n && root.n.type === "wifi" ? "wifi" : "ethernet"
                label: !root.n || !root.n.type ? "Sem conexão" : (root.n.type === "wifi" ? (root.n.name || "Wi-Fi") : "Ethernet")
                value: !SysStatus.known ? "Verificando…"
                     : SysStatus.online ? "Conectado"
                     : SysStatus.connectivity === "portal" ? "Requer login na rede"
                     : SysStatus.connectivity === "limited" ? "Sem internet (rede limitada)" : "Sem internet"
                valueColor: SysStatus.known && !SysStatus.online ? Theme.danger : Theme.textSecondary
            }
            Row2 {
                visible: !!(root.n && root.n.type === "wifi")
                icon: "wifi"; label: "Sinal"
                value: root.n ? root.n.signal + "%" : ""
            }
        }

        // Recursos
        Title { text: "Recursos"; topPadding: 4 }
        Card {
            Row2 { icon: "chip"; label: "CPU"; value: root.r ? root.r.cpu + "%" + (root.r.temp !== null && root.r.temp !== undefined ? " · " + root.r.temp + " °C" : "") : "…" }
            Bar { frac: root.r ? root.r.cpu / 100 : 0 }
            Row2 { icon: "apps"; label: "Memória"; value: root.r ? SysStatus.gib(root.r.memUsed) + " / " + SysStatus.gib(root.r.memTotal) + " GB" : "…" }
            Bar { frac: root.r ? root.r.memUsed / root.r.memTotal : 0 }
            Row2 { icon: "folder"; label: "Disco"; value: root.r ? Math.round(100 * root.r.diskUsed / root.r.diskTotal) + "% · " + SysStatus.gib(root.r.diskTotal - root.r.diskUsed) + " GB livres" : "…" }
            Bar { frac: root.r ? root.r.diskUsed / root.r.diskTotal : 0 }
            Row2 {
                visible: !!SysStatus.gpu
                icon: "display"; label: SysStatus.gpu ? SysStatus.gpu.name : "GPU"
                value: SysStatus.gpu ? SysStatus.gpu.util + "% · " + SysStatus.gpu.temp + " °C" : ""
            }
        }

        // Dispositivos
        Title { text: "Dispositivos"; topPadding: 4 }
        Card {
            Repeater { model: root.d ? root.d.keyboards : []; Row2 { required property var modelData; icon: "keyboard"; label: "Teclado"; value: modelData } }
            Repeater { model: root.d ? root.d.mice : []; Row2 { required property var modelData; icon: "mouse"; label: "Mouse"; value: modelData } }
            // Áudio com seletor interativo
            Column {
                id: audioRow
                visible: !!(root.d && (root.d.audio || (root.d.audioSinks && root.d.audioSinks.length > 0)))
                width: parent ? parent.width : 0
                property bool menuOpen: false
                readonly property var sinks: (root.d && root.d.audioSinks) ? root.d.audioSinks : []
                readonly property bool hasChoices: sinks.length > 0

                // Cabeçalho da linha de áudio
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 12
                    color: hArea.containsMouse && audioRow.hasChoices ? Theme.hover : "transparent"

                    Icon {
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        name: VolumeOSDState.muted ? "mute" : "volume"
                        size: 18
                        tone: "dark"
                    }
                    Text {
                        x: 44
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Áudio"
                        color: Theme.textPrimary
                        font.family: Theme.font
                        font.pixelSize: 14
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, audioRow.width - 150)
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                            text: (root.d ? (root.d.audio || (audioRow.sinks.length > 0 ? audioRow.sinks[0].name : "")) : "") + (VolumeOSDState.muted ? " (Mudo)" : "")
                            color: VolumeOSDState.muted ? Theme.textSecondary : Theme.textPrimary
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.features: { "tnum": 1 }
                        }
                        Icon {
                            visible: audioRow.hasChoices
                            anchors.verticalCenter: parent.verticalCenter
                            name: "chevron"
                            size: 14
                            tone: "dark"
                            rotation: audioRow.menuOpen ? 180 : 0
                            Behavior on rotation { NumberAnimation { duration: Theme.durFast } }
                        }
                    }

                    MouseArea {
                        id: hArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: audioRow.hasChoices ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (audioRow.hasChoices) audioRow.menuOpen = !audioRow.menuOpen
                    }
                }

                // Lista de opções quando expandido
                Column {
                    id: sinksCol
                    visible: audioRow.menuOpen && audioRow.hasChoices
                    width: parent.width
                    spacing: 2
                    bottomPadding: 4

                    Repeater {
                        model: audioRow.menuOpen ? audioRow.sinks : []

                        Rectangle {
                            id: sinkItem
                            required property var modelData
                            width: parent.width - 24
                            x: 12
                            height: 34
                            radius: 10
                            color: sArea.containsMouse ? Theme.hover : (modelData.active ? Theme.raised : "transparent")

                            Text {
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 44
                                text: modelData.name
                                color: Theme.textPrimary
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: modelData.active ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                            }

                            Icon {
                                visible: !!modelData.active
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                name: "check"
                                size: 14
                                tone: "dark"
                            }

                            MouseArea {
                                id: sArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SysStatus.setAudioSink(sinkItem.modelData.id)
                            }
                        }
                    }
                }
            }
            Repeater { model: root.d ? root.d.bluetooth : []; Row2 { required property var modelData; icon: "bluetooth"; label: "Bluetooth"; value: modelData } }
            Repeater { model: root.d ? root.d.usb : []; Row2 { required property var modelData; icon: "usb"; label: "USB"; value: modelData } }
            Row2 { visible: !root.d; icon: "info"; label: "Buscando…"; value: "" }
        }
    }
}
