// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import "../Common"
import "../Character"

// Panel "Apps abiertas" (se abre deslizando de derecha a izquierda sobre la isla).
// Ventanas de Hyprland agrupadas por app, con escritorio o "minimizada"; clic = traerla,
// × = cerrarla con amabilidad. Solo observa Hyprland mientras está abierto.
Item {
    id: root
    property bool open: false
    implicitHeight: col.implicitHeight + 32

    onOpenChanged: if (open) { Hyprland.refreshToplevels(); greetLater.restart(); sync() } else rows.clear()
    Timer { id: greetLater; interval: 280; onTriggered: chr.react("greet") }

    // ---- datos (vacíos con el panel cerrado: sin trabajo de fondo) ----
    readonly property var wins: open ? Hyprland.toplevels.values.filter(t => t && t.address && root.userWindow(t)) : []
    onWinsChanged: syncLater.restart()
    Timer { id: syncLater; interval: 40; onTriggered: root.sync() }   // una vez por ráfaga de cambios

    function clsOf(t) {
        if (t.wayland && t.wayland.appId) return t.wayland.appId
        const o = t.lastIpcObject
        return o && o["class"] ? o["class"] : "?"
    }
    // Fuera ventanas auxiliares: sin mapear, ocultas, diminutas o popups sin título.
    function userWindow(t) {
        const o = t.lastIpcObject
        if (!o || o.mapped === undefined) return true          // aún sin datos: mostrar
        if (!o.mapped || o.hidden) return false
        if (o.size && (o.size[0] < 40 || o.size[1] < 40)) return false
        return (t.title || o.title || "") !== "" || !!(o["class"])
    }
    function entryOf(cls) { return cls && cls !== "?" ? DesktopEntries.heuristicLookup(cls) : null }
    function appName(cls) { const e = entryOf(cls); return e && e.name ? e.name : cls }
    function iconOf(cls) {
        const e = entryOf(cls)
        const p = Quickshell.iconPath(e ? e.icon : cls, true)
        return p !== "" ? p : Qt.resolvedUrl("../assets/icons/gray/apps.svg")
    }
    function wsName(t) { return t.workspace ? (t.workspace.name || String(t.workspace.id)) : "" }
    function minimized(t) { return wsName(t).startsWith("special:minimized") }
    property var byAddr: ({})

    // Modelo plano (encabezado de app + ventanas) sincronizado por diferencias,
    // así las filas entran/salen animadas en vez de reconstruirse.
    ListModel { id: rows }
    function sync() {
        if (!open) return
        const groups = {}, map = {}
        for (const t of wins) {
            const c = clsOf(t)
            map[t.address] = t
            ;(groups[c] = groups[c] || []).push(t)
        }
        byAddr = map
        const want = []
        for (const c of Object.keys(groups).sort((a, b) => appName(a).localeCompare(appName(b)))) {
            want.push({ key: "h:" + c, kind: "head", cls: c, address: "" })
            for (const t of groups[c]) want.push({ key: "w:" + t.address, kind: "win", cls: c, address: t.address })
        }
        const keys = want.map(w => w.key)
        for (let i = rows.count - 1; i >= 0; i--) if (keys.indexOf(rows.get(i).key) < 0) rows.remove(i)
        for (let i = 0; i < want.length; i++) {
            let j = -1
            for (let k = i; k < rows.count; k++) if (rows.get(k).key === want[i].key) { j = k; break }
            if (j < 0) rows.insert(i, want[i])
            else if (j !== i) rows.move(j, i, 1)
        }
    }

    // MPRIS sin ventana propia: "En segundo plano".
    // Tocar SystemTray siempre: registra el StatusNotifierWatcher para que Steam/Discord
    // publiquen su icono de bandeja aunque el panel esté cerrado (es barato).
    readonly property var trayItems: SystemTray.items.values
    function hasWindow(id) {
        id = (id || "").toLowerCase()
        return id !== "" && wins.some(t => { const c = clsOf(t).toLowerCase(); return c.includes(id) || id.includes(c) })
    }
    readonly property var trayBg: !open ? [] : trayItems.filter(i => i && !hasWindow(i.id) && !hasWindow(i.title))
    function activateTray(i) {
        if (!i.onlyMenu) i.activate()
        else { const e = entryOf(i.id); Quickshell.execDetached(["gtk-launch", e ? e.id : i.id]) }
        CharacterBus.islandCommand("close")
    }
    readonly property var background: trayBg.concat(players)
    readonly property var players: !open ? [] : Mpris.players.values.filter(p => {
        if ((p.dbusName || "").indexOf("playerctld") >= 0) return false
        const id = ((p.desktopEntry || p.identity || "") + "").toLowerCase()
        return id !== "" && !wins.some(t => { const c = clsOf(t).toLowerCase(); return c.includes(id) || id.includes(c) })
    })

    function focusWin(addr, cls) {
        const e = entryOf(cls)
        Quickshell.execDetached([Qt.resolvedUrl("../scripts/focus-app.py").toString().replace("file://", ""), "--address", addr, "--launch", e ? e.id : cls])
        CharacterBus.islandCommand("close")
    }
    function closeWin(addr) {
        Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.window.close({ window = "address:' + addr + '" })'])
    }

    component Title: Text {
        color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold
        leftPadding: 4
    }

    Column {
        id: col
        x: 16; y: 16; width: parent.width - 32
        spacing: 8

        Item {
            width: parent.width; height: 76
            Character {
                id: chr
                size: 60
                anchors.centerIn: parent
                active: root.open && DisplayState.characterAnimated
                MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: m => chr.clicked((m.x - width / 2) / (width / 2)) }
            }
        }

        Title { text: "Apps abiertas" }
        Rectangle {
            width: parent.width; radius: 18; color: Theme.field
            height: (rows.count === 0 ? empty.height : list.contentHeight) + 8
            Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            clip: true
            Text {
                id: empty
                visible: rows.count === 0
                y: 4; width: parent.width; height: 44
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                text: "No hay apps abiertas"; color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 13
            }
            ListView {
                id: list
                y: 4; width: parent.width; height: contentHeight
                interactive: false
                model: rows
                add: Transition { NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic } }
                remove: Transition { NumberAnimation { properties: "opacity"; to: 0; duration: 160; easing.type: Easing.OutCubic } }
                displaced: Transition { NumberAnimation { properties: "y"; duration: 260; easing.type: Easing.OutCubic } }
                move: Transition { NumberAnimation { properties: "y"; duration: 260; easing.type: Easing.OutCubic } }
                delegate: Item {
                    id: row
                    required property string kind
                    required property string cls
                    required property string address
                    required property int index
                    readonly property var t: kind === "win" ? (root.byAddr[address] || null) : null
                    width: list.width
                    height: kind === "head" ? 34 : 40

                    // Encabezado de app: icono + nombre.
                    Row {
                        visible: row.kind === "head"
                        x: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                        Image { width: 20; height: 20; sourceSize: Qt.size(40, 40); source: row.kind === "head" ? root.iconOf(row.cls) : ""; asynchronous: true; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: root.appName(row.cls); color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    }

                    // Ventana: título, escritorio, × al pasar el mouse.
                    Rectangle {
                        visible: row.kind === "win"
                        x: 6; width: parent.width - 12; height: 36; radius: 18
                        anchors.verticalCenter: parent.verticalCenter
                        color: wm.containsMouse ? Theme.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            x: 38; anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 38 - badge.width - 52
                            elide: Text.ElideRight
                            text: row.t ? (row.t.title || root.appName(row.cls)) : ""
                            color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 13
                        }
                        Rectangle {
                            id: badge
                            readonly property bool mini: row.t ? root.minimized(row.t) : false
                            anchors.right: parent.right; anchors.rightMargin: 40; anchors.verticalCenter: parent.verticalCenter
                            height: 22; radius: 11; width: bt.implicitWidth + 16
                            color: Theme.raised
                            Text {
                                id: bt; anchors.centerIn: parent
                                text: !row.t ? "" : badge.mini ? "minimizada" : root.wsName(row.t).startsWith("special") ? "especial" : root.wsName(row.t)
                                color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 11; font.features: { "tnum": 1 }
                            }
                        }
                        MouseArea {
                            id: wm
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.focusWin(row.address, row.cls)
                        }
                        // × de cerrar (sutil, aparece con el hover).
                        Rectangle {
                            anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
                            width: 26; height: 26; radius: 13
                            color: xm.containsMouse ? Theme.track : Theme.raised
                            opacity: wm.containsMouse || xm.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                            Icon { anchors.centerIn: parent; name: "close"; size: 12; tone: "gray" }
                            MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closeWin(row.address) }
                        }
                    }
                }
            }
        }

        Title { text: "En segundo plano"; topPadding: 4; visible: root.background.length > 0 }
        Rectangle {
            visible: root.background.length > 0
            width: parent.width; radius: 18; color: Theme.field
            height: bgCol.implicitHeight + 8
            Column {
                id: bgCol; y: 4; width: parent.width
                Repeater {
                    model: root.background
                    delegate: Item {
                        required property var modelData
                        width: bgCol.width; height: 40
                        readonly property bool isTray: modelData.onlyMenu !== undefined
                        Icon { visible: !parent.isTray; x: 16; anchors.verticalCenter: parent.verticalCenter; name: "music"; size: 18; tone: "dark" }
                        Image { visible: parent.isTray; x: 16; width: 18; height: 18; anchors.verticalCenter: parent.verticalCenter; source: parent.isTray ? modelData.icon : ""; sourceSize: Qt.size(36, 36) }
                        Text {
                            x: 46; width: parent.width - 60; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight
                            text: parent.isTray ? (root.appName(modelData.id) || modelData.title) : modelData.identity + (modelData.trackTitle ? "  ·  " + modelData.trackTitle : "")
                            color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 13
                        }
                        MouseArea { anchors.fill: parent; enabled: parent.isTray || modelData.canRaise; cursorShape: Qt.PointingHandCursor; onClicked: parent.isTray ? root.activateTray(modelData) : modelData.raise() }
                    }
                }
            }
        }
    }
}
