// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Common"

// Lançador estilo Spotlight (Super+Espaço): cartão branco centralizado, buscador grande,
// resultados com ícones, navegação com teclado (setas/tab). Clique fora, Escape ou Super+Espaço fecha.
PanelWindow {
    id: win
    readonly property bool open: LauncherState.open
    property real t: open ? 1 : 0          // progresso da animação
    Behavior on t { NumberAnimation { duration: win.open ? 80 : 60; easing.type: Easing.OutCubic } }

    visible: open || t > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "minimo-launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var results: Apps.search(field.text, 0, true)
    property int selected: 0
    readonly property int visibleItems: Math.min(results.length, 3)

    onResultsChanged: {
        selected = 0
        if (appList) appList.positionViewAtIndex(0, ListView.Beginning)
    }

    onOpenChanged: {
        if (open) {
            field.text = ""
            selected = 0
            if (appList) appList.positionViewAtIndex(0, ListView.Beginning)
            field.forceActiveFocus()
            focusLater.restart()
        }
    }
    Timer { id: focusLater; interval: 10; onTriggered: field.forceActiveFocus() }

    function launch(entry) {
        if (!entry) return
        entry.execute()
        LauncherState.hide()
    }

    // Velo muito sutil + clique fora fecha.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.08 * win.t)
        MouseArea { anchors.fill: parent; onPressed: LauncherState.hide() }
    }

    Rectangle {
        id: shadowSrc
        x: card.x; y: card.y; width: card.width; height: card.height
        radius: card.radius; color: Theme.card
        opacity: win.t; scale: card.scale
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true; shadowColor: Theme.shadow
            shadowBlur: 1.0; blurMax: 24; shadowVerticalOffset: 8; autoPaddingEnabled: true
        }
    }

    Rectangle {
        id: card
        width: 600
        height: col.implicitHeight + 20
        x: (win.width - width) / 2
        y: win.height * 0.22
        radius: Math.min(height / 2, 32)
        color: Theme.card
        opacity: win.t
        scale: 0.98 + 0.02 * win.t
        clip: true
        Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }   // não fechar ao clicar dentro

        Column {
            id: col
            x: 10; y: 10
            width: parent.width - 20
            spacing: 4

            Rectangle {
                width: parent.width; height: 56
                radius: height / 2
                color: Theme.field
                Icon { id: lupa; x: 20; anchors.verticalCenter: parent.verticalCenter; name: "search"; tone: "gray"; size: 22 }
                TextInput {
                    id: field
                    onTextChanged: if (activeFocus) CharacterBus.typed()
                    onActiveFocusChanged: if (!activeFocus) CharacterBus.typingStopped()
                    anchors.left: lupa.right; anchors.leftMargin: 12
                    anchors.right: parent.right; anchors.rightMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.textPrimary
                    font.family: Theme.font; font.pixelSize: 21
                    selectionColor: Theme.track; selectedTextColor: Theme.textPrimary
                    cursorDelegate: Rectangle { width: 2; radius: 1; color: Theme.textPrimary; visible: field.activeFocus }
                    clip: true
                    Text { visible: !field.text; text: "Buscar aplicativos"; color: Theme.textSecondary; font: field.font }
                    Keys.onEscapePressed: LauncherState.hide()
                    Keys.onDownPressed: {
                        if (win.results.length > 0) {
                            win.selected = (win.selected + 1) % win.results.length
                            appList.positionViewAtIndex(win.selected, ListView.Contain)
                        }
                    }
                    Keys.onUpPressed: {
                        if (win.results.length > 0) {
                            win.selected = (win.selected - 1 + win.results.length) % win.results.length
                            appList.positionViewAtIndex(win.selected, ListView.Contain)
                        }
                    }
                    Keys.onTabPressed: {
                        if (win.results.length > 0) {
                            win.selected = (win.selected + 1) % win.results.length
                            appList.positionViewAtIndex(win.selected, ListView.Contain)
                        }
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Space && (event.modifiers & Qt.MetaModifier)) {
                            LauncherState.hide()
                            event.accepted = true
                        }
                    }
                    onAccepted: {
                        if (win.results.length > 0) {
                            win.launch(win.results[win.selected])
                        }
                    }
                }
            }

            Item { width: 1; height: 4; visible: win.results.length > 0 }

            Item {
                width: parent.width
                height: win.visibleItems > 0 ? (win.visibleItems * 52 + (win.visibleItems - 1) * 4) : 0
                visible: win.results.length > 0
                clip: true

                ListView {
                    id: appList
                    anchors.fill: parent
                    spacing: 4
                    clip: true
                    model: win.results
                    currentIndex: win.selected
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 60
                    reuseItems: true

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: appList.width; height: 52; radius: height / 2
                        color: index === win.selected ? Theme.field : (rm.containsMouse ? Theme.subtle : "transparent")
                        Behavior on color { ColorAnimation { duration: 60 } }

                        // Ícone dentro de um "squircle"
                        Rectangle {
                            id: ic
                            x: 8; anchors.verticalCenter: parent.verticalCenter
                            width: 38; height: 38; radius: 12
                            color: index === win.selected ? Theme.raised : Theme.field
                            Image {
                                anchors.centerIn: parent
                                width: 26; height: 26; sourceSize: Qt.size(52, 52)
                                source: Apps.iconFor(modelData)
                            }
                        }
                        Column {
                            anchors.left: ic.right; anchors.leftMargin: 14
                            anchors.right: parent.right; anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            Text { width: parent.width; elide: Text.ElideRight; text: modelData.name; color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 15 }
                            Text { width: parent.width; elide: Text.ElideRight; text: modelData.genericName || modelData.comment || ""; visible: text !== ""; color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12 }
                        }
                        MouseArea {
                            id: rm
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onEntered: win.selected = index
                            onClicked: win.launch(modelData)
                        }
                    }
                }

                // Indicador sutil de rolagem à direita se houver mais de 3 itens
                Item {
                    id: scrollTrack
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 3
                    visible: win.results.length > 3
                    Rectangle {
                        width: 3
                        radius: 1.5
                        color: Theme.textSecondary
                        opacity: 0.35
                        y: appList.visibleArea.yPosition * scrollTrack.height
                        height: Math.max(16, appList.visibleArea.heightRatio * scrollTrack.height)
                    }
                }
            }
        }
    }
}
