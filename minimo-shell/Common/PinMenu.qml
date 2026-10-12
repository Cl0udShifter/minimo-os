// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick

// Menú contextual mínimo: una sola opción "Anclar" / "Desanclar". Se coloca en
// coordenadas del padre con openAt(); se cierra al elegir, al salir el mouse o con close().
Rectangle {
    id: m
    property var entry: null
    readonly property bool pinned: Apps.isPinned(entry)
    visible: entry !== null
    z: 100
    width: label.implicitWidth + 36; height: 36; radius: 18
    color: "white"
    border.width: 1; border.color: Theme.track

    function openAt(e, px, py) {
        entry = e
        x = Math.max(0, Math.min(px, parent.width - width))
        y = parent.height > height ? Math.max(0, Math.min(py, parent.height - height)) : py
        leave.interval = 2500; leave.restart()
    }
    function close() { entry = null }

    Rectangle {
        anchors.fill: parent; anchors.margins: 3
        radius: height / 2
        color: area.containsMouse ? Theme.field : "transparent"
    }
    Text {
        id: label
        enabled: false
        anchors.centerIn: parent
        text: m.pinned ? "Desanclar" : "Anclar"
        color: Theme.text; font.family: Theme.font; font.pixelSize: 13
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { Apps.togglePin(m.entry); m.close() }
        onExited: { leave.interval = 600; leave.restart() }
        onEntered: leave.stop()
    }
    Timer { id: leave; interval: 700; onTriggered: m.close() }
}
