// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import "../Common"
import "../Character"
import "sections"

// Menú de la isla expandida: compone las secciones con entrada escalonada.
Item {
    id: root
    signal done()
    property bool open: false
    readonly property bool searchFocused: search.hasFocus
    property alias character: chr
    property string page: "menu"   // "menu" | "desks" | "calendar"
    implicitHeight: (page === "desks" ? desks.implicitHeight : page === "calendar" ? calendarView.implicitHeight : col.implicitHeight) + 48

    // El buscador no se enfoca solo: se activa al hacerle clic.
    function opened() { search.reset() }

    // Entrada escalonada: stage sube de a uno cada 45 ms al abrir.
    property int stage: 0
    Timer {
        id: stagger; interval: 45; repeat: true
        running: root.open && root.stage < 6
        onTriggered: root.stage++
    }
    onOpenChanged: if (!open) { stage = 0; page = "menu" }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    component Reveal: Item {
        property int step: 0
        opacity: root.stage > step ? 1 : 0
        transform: Translate { y: root.stage > step ? 0 : 8; Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } } }
        Behavior on opacity { NumberAnimation { duration: 260 } }
    }

    Column {
        id: col
        x: root.page === "menu" ? 24 : -root.width * 0.3
        y: 24
        opacity: root.page === "menu" ? 1 : 0
        visible: opacity > 0
        enabled: root.page === "menu"
        Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 220 } }
        width: parent.width - 48
        spacing: 24

        Reveal {
            step: 0; width: parent.width; height: 48
            Item {
                width: parent.width; height: 48

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Character {
                        id: chr; size: 44; active: root.open && DisplayState.characterAnimated; anchors.verticalCenter: parent.verticalCenter
                        // Clic en el personaje: guiño, risita… (4+ clics rápidos: caricias)
                        MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: m => chr.clicked((m.x - width / 2) / (width / 2)) }
                    }

                    Rectangle {
                        id: datePill
                        anchors.verticalCenter: parent.verticalCenter
                        height: 44
                        width: dateCol.implicitWidth + 14
                        radius: 10
                        color: dateMouse.containsMouse ? Theme.field : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }

                        Column {
                            id: dateCol
                            anchors.centerIn: parent
                            spacing: 0
                            Text {
                                text: Qt.formatDateTime(clock.date, "HH:mm")
                                color: Theme.textPrimary; font.family: Theme.font
                                font.pixelSize: 24; font.weight: Font.Medium
                                font.features: { "tnum": 1 }
                            }
                            Text {
                                text: { const t = clock.date.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM"); return t.charAt(0).toUpperCase() + t.slice(1) }
                                color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            id: dateMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.page = "calendar"
                        }
                    }
                }

                // Botão de Calendário no topo direito do Notch
                Rectangle {
                    id: calBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38; height: 38; radius: 19
                    color: calMouse.containsMouse ? Theme.hover : Theme.field
                    scale: calMouse.pressed ? 0.92 : 1
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Icon {
                        anchors.centerIn: parent
                        name: "calendar"
                        size: 18
                    }

                    MouseArea {
                        id: calMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.page = "calendar"
                    }
                }
            }
        }
        Reveal { step: 1; width: parent.width; height: search.implicitHeight
            SearchSection { id: search; width: parent.width; onLaunched: root.done() } }
        Reveal { step: 2; width: parent.width; height: media.implicitHeight; visible: media.player !== null
            MediaSection { id: media; width: parent.width } }
        Reveal { step: 3; width: parent.width; height: wifi.implicitHeight; visible: wifi.visible
            WifiSection { id: wifi; width: parent.width; active: root.open } }
        Reveal { step: 3; width: parent.width; height: sliders.implicitHeight
            Column { id: sliders; width: parent.width; spacing: 8
                VolumeSection { width: parent.width }
                DisplaySection { width: parent.width } } }
        Reveal { step: 4; width: parent.width; height: actions.implicitHeight
            ActionsSection { id: actions; anchors.horizontalCenter: parent.horizontalCenter; onDone: root.done(); onDesktops: { desks.refresh(); root.page = "desks" }
                onSettings: { root.done(); SettingsState.show() } } }
    }

    WorkspacesView {
        id: desks
        x: root.page === "desks" ? 24 : root.width * 0.3
        y: 24
        width: root.width - 48
        opacity: root.page === "desks" ? 1 : 0
        visible: opacity > 0
        enabled: root.page === "desks"
        Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 220 } }
        onBack: root.page = "menu"
        onPicked: root.done()
    }

    CalendarView {
        id: calendarView
        x: root.page === "calendar" ? 24 : root.width * 0.3
        y: 24
        width: root.width - 48
        opacity: root.page === "calendar" ? 1 : 0
        visible: opacity > 0
        enabled: root.page === "calendar"
        Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 220 } }
        onBack: root.page = "menu"
    }
}
