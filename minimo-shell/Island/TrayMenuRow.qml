// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import "../Common"

// Fila del menú de una app de la bandeja (texto, separador, deshabilitada, check).
// Las de submenú emiten toggle() para expandirse en línea; el resto, activated().
Item {
    id: mr
    required property var entry
    property bool expanded: false
    signal toggle()
    signal activated()
    width: parent ? parent.width : 0
    height: entry.isSeparator ? 9 : 32
    Rectangle {
        visible: mr.entry.isSeparator
        x: 12; width: parent.width - 24; height: 1; anchors.verticalCenter: parent.verticalCenter
        color: Theme.track
    }
    Rectangle {
        visible: !mr.entry.isSeparator
        x: 4; width: parent.width - 8; height: 28; radius: 14; anchors.verticalCenter: parent.verticalCenter
        color: mrMa.containsMouse && mr.entry.enabled ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    Text {
        visible: !mr.entry.isSeparator
        x: 16; width: parent.width - 48; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight
        text: (mr.entry.text || "").replace(/_(?=\S)/g, "")
        color: mr.entry.enabled ? Theme.textPrimary : Theme.textSecondary
        opacity: mr.entry.enabled ? 1 : 0.6
        font.family: Theme.font; font.pixelSize: 13
    }
    Icon {
        visible: !mr.entry.isSeparator && (mr.entry.hasChildren || mr.entry.checkState === Qt.Checked)
        anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
        name: mr.entry.hasChildren ? "chevron" : "check"; size: 12; tone: "gray"
        rotation: mr.entry.hasChildren ? (mr.expanded ? 90 : 0) : 0
        Behavior on rotation { NumberAnimation { duration: 160 } }
    }
    MouseArea {
        id: mrMa
        anchors.fill: parent; hoverEnabled: true
        enabled: !mr.entry.isSeparator && mr.entry.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: mr.entry.hasChildren ? mr.toggle() : mr.activated()
    }
}
