// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../Common"

// Pantalla: disposição visual de monitores (arrastrar y ordenar) +
// resolução/frequência, escala, brilho e saturação.
// As alterações de posição são aplicadas com a API Lua do Hyprland (hyprctl eval 'hl.monitor{…}')
// e gravadas em ~/.config/hypr/minimo/monitores.lua.
Column {
    id: root
    spacing: 20

    property var monitors: []
    property var layoutList: []
    property int selectedMonitorIndex: 0
    property bool positionsDirty: false
    property var pending: null          // { name, prev:{mode,scale,pos}, next:{…} }
    property int countdown: 0
    readonly property var scales: [1, 1.25, 1.5, 2]
    readonly property string outputsFile: Quickshell.env("HOME") + "/.config/hypr/minimo/monitores.lua"
    readonly property bool hasHeadless: (layoutList || []).some(m => m.name && m.name.indexOf("HEADLESS") === 0)

    function refresh() { query.running = false; query.running = true }
    Component.onCompleted: refresh()
    onVisibleChanged: if (visible) root.refresh()

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            const n = ev.name
            if (n === "monitoradded" || n === "monitorremoved" || n === "monitoraddedv2") {
                root.refresh()
            }
        }
    }

    Process {
        id: query
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text).filter(m => !m.disabled)
                } catch (e) {
                    root.monitors = []
                }
            }
        }
    }
    QtObject { id: saver; property bool armed: false }

    onMonitorsChanged: {
        if (saver.armed) {
            saver.armed = false
            writeOutputs()
        }
        if (!monitors || monitors.length === 0) {
            layoutList = []
            return
        }
        let names = monitors.map(m => m.name).sort().join(",")
        let currentNames = (layoutList || []).map(m => m.name).sort().join(",")
        if (!positionsDirty || names !== currentNames) {
            let list = []
            for (let i = 0; i < monitors.length; i++) {
                let m = monitors[i]
                list.push({
                    id: m.id !== undefined ? m.id : i,
                    name: m.name,
                    model: (m.make && m.model) ? (m.make + " " + m.model) : (m.model || m.name),
                    width: m.width,
                    height: m.height,
                    scale: m.scale || 1,
                    refreshRate: m.refreshRate || 60,
                    x: m.x || 0,
                    y: m.y || 0,
                    availableModes: m.availableModes || []
                })
            }
            layoutList = list
            positionsDirty = false
        } else if (positionsDirty && names === currentNames) {
            // Atualiza modos/resolução mantendo posições editadas
            let list = []
            for (let i = 0; i < monitors.length; i++) {
                let m = monitors[i]
                let cur = layoutList.find(x => x.name === m.name)
                list.push({
                    id: m.id !== undefined ? m.id : i,
                    name: m.name,
                    model: (m.make && m.model) ? (m.make + " " + m.model) : (m.model || m.name),
                    width: m.width,
                    height: m.height,
                    scale: m.scale || 1,
                    refreshRate: m.refreshRate || 60,
                    x: cur ? cur.x : (m.x || 0),
                    y: cur ? cur.y : (m.y || 0),
                    availableModes: m.availableModes || []
                })
            }
            layoutList = list
        }
        if (selectedMonitorIndex >= (layoutList || []).length) {
            selectedMonitorIndex = 0
        }
    }

    function modeOf(m) {
        const rr = (m.refreshRate && m.refreshRate > 0) ? m.refreshRate.toFixed(2) : "60.00"
        return m.width + "x" + m.height + "@" + rr
    }

    function posOf(m) {
        let lm = (layoutList || []).find(x => x.name === m.name)
        if (lm) return lm.x + "x" + lm.y
        return m.x + "x" + m.y
    }

    function rule(name, cfg) {
        return 'hl.monitor({ output = [=[' + name + ']=], mode = [=[' + cfg.mode + ']=], position = [=[' + cfg.pos + ']=], scale = ' + cfg.scale + ' })'
    }

    function applyCfg(name, cfg) {
        Quickshell.execDetached(["hyprctl", "eval", rule(name, cfg)])
        refreshLater.restart()
    }
    Timer { id: refreshLater; interval: 400; onTriggered: root.refresh() }

    // Bounding box e coordenadas do canvas visual
    function getBoundingBox() {
        if (!layoutList || layoutList.length === 0) return { minX: 0, maxX: 1920, minY: 0, maxY: 1080 }
        let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity
        for (let i = 0; i < layoutList.length; i++) {
            let m = layoutList[i]
            let mw = (m.width || 1920) / (m.scale || 1)
            let mh = (m.height || 1080) / (m.scale || 1)
            minX = Math.min(minX, m.x)
            maxX = Math.max(maxX, m.x + mw)
            minY = Math.min(minY, m.y)
            maxY = Math.max(maxY, m.y + mh)
        }
        if (minX === Infinity) return { minX: 0, maxX: 1920, minY: 0, maxY: 1080 }
        return { minX: minX, maxX: maxX, minY: minY, maxY: maxY }
    }

    readonly property real canvasZoom: {
        let bbox = getBoundingBox()
        let spanW = Math.max(bbox.maxX - bbox.minX, 1920)
        let spanH = Math.max(bbox.maxY - bbox.minY, 1080)
        let availW = Math.max(200, canvasBox.width - 64)
        let availH = Math.max(100, canvasBox.height - 48)
        let zw = availW / (spanW + 400)
        let zh = availH / (spanH + 200)
        return Math.min(0.09, Math.max(0.035, Math.min(zw, zh)))
    }

    readonly property real canvasOriginX: {
        let bbox = getBoundingBox()
        let centerBBoxX = (bbox.minX + bbox.maxX) / 2
        return (canvasBox.width / 2) - (centerBBoxX * canvasZoom)
    }

    readonly property real canvasOriginY: {
        let bbox = getBoundingBox()
        let centerBBoxY = (bbox.minY + bbox.maxY) / 2
        return (canvasBox.height / 2) - (centerBBoxY * canvasZoom)
    }

    function checkOverlap(index) {
        if (!layoutList || layoutList.length < 2 || index >= layoutList.length) return false
        let cur = layoutList[index]
        let curW = (cur.width || 1920) / (cur.scale || 1)
        let curH = (cur.height || 1080) / (cur.scale || 1)
        for (let i = 0; i < layoutList.length; i++) {
            if (i === index) continue
            let other = layoutList[i]
            let otherW = (other.width || 1920) / (other.scale || 1)
            let otherH = (other.height || 1080) / (other.scale || 1)
            let noOverlap = (cur.x + curW <= other.x) || (other.x + otherW <= cur.x) || (cur.y + curH <= other.y) || (other.y + otherH <= cur.y)
            if (!noOverlap) return true
        }
        return false
    }

    function applyMove(targetIndex, targetX, targetY) {
        if (!layoutList || layoutList.length === 0 || targetIndex >= layoutList.length) return
        let list = []
        for (let i = 0; i < layoutList.length; i++) list.push(Object.assign({}, layoutList[i]))

        let tgt = list[targetIndex]
        let tgtW = (tgt.width || 1920) / (tgt.scale || 1)
        let tgtH = (tgt.height || 1080) / (tgt.scale || 1)
        tgt.x = targetX
        tgt.y = targetY

        const snapDist = 140

        for (let i = 0; i < list.length; i++) {
            if (i === targetIndex) continue
            let other = list[i]
            let otherW = (other.width || 1920) / (other.scale || 1)
            let otherH = (other.height || 1080) / (other.scale || 1)

            // Encaixe magnético horizontal
            if (Math.abs(tgt.x - (other.x + otherW)) < snapDist) {
                tgt.x = other.x + otherW
            } else if (Math.abs((tgt.x + tgtW) - other.x) < snapDist) {
                tgt.x = other.x - tgtW
            } else if (Math.abs(tgt.x - other.x) < snapDist) {
                tgt.x = other.x
            } else if (Math.abs((tgt.x + tgtW) - (other.x + otherW)) < snapDist) {
                tgt.x = other.x + otherW - tgtW
            }

            // Encaixe magnético vertical
            if (Math.abs(tgt.y - (other.y + otherH)) < snapDist) {
                tgt.y = other.y + otherH
            } else if (Math.abs((tgt.y + tgtH) - other.y) < snapDist) {
                tgt.y = other.y - tgtH
            } else if (Math.abs(tgt.y - other.y) < snapDist) {
                tgt.y = other.y
            } else if (Math.abs((tgt.y + tgtH) - (other.y + otherH)) < snapDist) {
                tgt.y = other.y + otherH - tgtH
            }
        }

        // Normalização: minX = 0, minY = 0
        let minX = tgt.x
        let minY = tgt.y
        for (let i = 0; i < list.length; i++) {
            if (i === targetIndex) continue
            minX = Math.min(minX, list[i].x)
            minY = Math.min(minY, list[i].y)
        }

        let changed = false
        for (let i = 0; i < list.length; i++) {
            let nx = Math.round(list[i].x - minX)
            let ny = Math.round(list[i].y - minY)
            if (layoutList[i].x !== nx || layoutList[i].y !== ny) {
                changed = true
            }
            list[i].x = nx
            list[i].y = ny
        }

        if (changed) {
            layoutList = list
            positionsDirty = true
        }
    }

    function alignSelected(action) {
        if (!layoutList || layoutList.length < 2 || selectedMonitorIndex >= layoutList.length) return
        let list = []
        for (let i = 0; i < layoutList.length; i++) list.push(Object.assign({}, layoutList[i]))

        let tgt = list[selectedMonitorIndex]
        let tgtW = (tgt.width || 1920) / (tgt.scale || 1)
        let tgtH = (tgt.height || 1080) / (tgt.scale || 1)

        let refIndex = (selectedMonitorIndex === 0) ? 1 : 0
        let ref = list[refIndex]
        let refW = (ref.width || 1920) / (ref.scale || 1)
        let refH = (ref.height || 1080) / (ref.scale || 1)

        if (action === "left") {
            tgt.x = ref.x - tgtW
            tgt.y = ref.y
        } else if (action === "right") {
            tgt.x = ref.x + refW
            tgt.y = ref.y
        } else if (action === "above") {
            tgt.x = ref.x
            tgt.y = ref.y - tgtH
        } else if (action === "below") {
            tgt.x = ref.x
            tgt.y = ref.y + refH
        } else if (action === "align_top") {
            tgt.y = ref.y
        } else if (action === "swap") {
            let tx = tgt.x; let ty = tgt.y
            tgt.x = ref.x; tgt.y = ref.y
            ref.x = tx; ref.y = ty
        }

        let minX = Infinity, minY = Infinity
        for (let i = 0; i < list.length; i++) {
            minX = Math.min(minX, list[i].x)
            minY = Math.min(minY, list[i].y)
        }
        for (let i = 0; i < list.length; i++) {
            list[i].x = Math.round(list[i].x - minX)
            list[i].y = Math.round(list[i].y - minY)
        }

        layoutList = list
        positionsDirty = true
    }

    function nudgeSelected(dx, dy) {
        if (!layoutList || layoutList.length === 0 || selectedMonitorIndex >= layoutList.length) return
        let list = []
        for (let i = 0; i < layoutList.length; i++) list.push(Object.assign({}, layoutList[i]))
        let tgt = list[selectedMonitorIndex]
        tgt.x += dx
        tgt.y += dy

        let minX = Infinity, minY = Infinity
        for (let i = 0; i < list.length; i++) {
            minX = Math.min(minX, list[i].x)
            minY = Math.min(minY, list[i].y)
        }
        for (let i = 0; i < list.length; i++) {
            list[i].x = Math.round(list[i].x - minX)
            list[i].y = Math.round(list[i].y - minY)
        }
        layoutList = list
        positionsDirty = true
    }

    function restorePositions() {
        positionsDirty = false
        refresh()
    }

    function savePositions() {
        if (!layoutList || layoutList.length === 0) return

        // 1. Aplica ao vivo no Hyprland via eval
        for (let i = 0; i < layoutList.length; i++) {
            const m = layoutList[i]
            const cfg = {
                mode: modeOf(m),
                pos: m.x + "x" + m.y,
                scale: m.scale || 1
            }
            Quickshell.execDetached(["hyprctl", "eval", rule(m.name, cfg)])
        }

        // 2. Persiste em ~/.config/hypr/minimo/monitores.lua
        let txt = "-- Monitores deste PC — escrito por Configurações › Tela do Minimo OS.\n\n"
        txt += 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })\n'
        for (let i = 0; i < layoutList.length; i++) {
            const m = layoutList[i]
            txt += rule(m.name, { mode: modeOf(m), pos: m.x + "x" + m.y, scale: m.scale || 1 }) + "\n"
        }

        writer.command = [
            "sh", "-c",
            'f="$1"; mkdir -p "$(dirname "$f")"; [ -e "$f" ] && { [ -e "$f.bak" ] || cp -a "$f" "$f.bak"; }; printf "%s" "$2" > "$f.tmp" && mv "$f.tmp" "$f" && hyprctl reload',
            "w", outputsFile, txt
        ]
        writer.running = true

        positionsDirty = false
        saveToast.show("Posições dos monitores salvas com sucesso!")
        refreshLater.restart()
    }

    function toggleSimulation() {
        if (hasHeadless) {
            let h = layoutList.find(m => m.name && m.name.indexOf("HEADLESS") === 0)
            if (h) {
                Quickshell.execDetached(["hyprctl", "output", "remove", h.name])
            }
        } else {
            Quickshell.execDetached(["hyprctl", "output", "create", "headless"])
        }
        refreshLater.restart()
    }

    // Pide un cambio: aplica y arranca la cuenta regresiva.
    function request(m, mode, scale) {
        const prev = { mode: modeOf(m), scale: m.scale, pos: posOf(m) }
        const next = { mode: mode, scale: scale, pos: prev.pos }
        if (next.mode === prev.mode && Math.abs(next.scale - prev.scale) < 0.001) return
        if (pending) revert()
        pending = { name: m.name, prev: prev, next: next }
        applyCfg(m.name, next)
        countdown = 15
        tick.restart()
    }
    function keep() {
        if (!pending) return
        tick.stop()
        pending = null
        saveLater.restart()
    }
    function revert() {
        if (!pending) return
        tick.stop()
        const p = pending
        pending = null
        applyCfg(p.name, p.prev)
    }
    Timer { id: tick; interval: 1000; repeat: true; onTriggered: { if (--root.countdown <= 0) root.revert() } }
    Timer { id: saveLater; interval: 500; onTriggered: { saver.armed = true; query.running = false; query.running = true } }


    function writeOutputs() {
        let txt = "-- Monitores deste PC — escrito por Configurações › Tela do Minimo OS.\n\n"
        txt += 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })\n'
        for (const m of monitors) txt += rule(m.name, { mode: modeOf(m), pos: posOf(m), scale: m.scale }) + "\n"
        writer.command = ["sh", "-c", 'f="$1"; mkdir -p "$(dirname "$f")"; [ -e "$f" ] && { [ -e "$f.bak" ] || cp -a "$f" "$f.bak"; }; printf "%s" "$2" > "$f.tmp" && mv "$f.tmp" "$f" && hyprctl reload', "w", outputsFile, txt]
        writer.running = true
    }
    Process { id: writer }

    // =========================================================================
    // SEÇÃO 1: DISPOSIÇÃO VISUAL DOS MONITORES
    // =========================================================================
    SectionTitle { text: "Disposição dos Monitores" }

    Column {
        width: parent.width
        spacing: 10

        Text {
            width: parent.width
            text: "Arraste as telas no quadro abaixo para definir a posição física dos seus monitores. Salve para gravar as alterações no Hyprland."
            color: Theme.textSecondary
            font.family: Theme.font; font.pixelSize: 13
            wrapMode: Text.WordWrap
        }

        Row {
            spacing: 8

            PillButton {
                text: root.hasHeadless ? "Remover Tela de Teste" : "+ Simular 2ª Tela"
                icon: "display"
                outlined: true
                onClicked: root.toggleSimulation()
            }

            PillButton {
                visible: root.positionsDirty
                text: "Restaurar"
                outlined: true
                onClicked: root.restorePositions()
            }

            PillButton {
                text: "Salvar Posições"
                primary: root.positionsDirty
                outlined: !root.positionsDirty
                icon: "check"
                onClicked: root.savePositions()
            }
        }
    }

    // Toast de confirmação ao salvar posições
    Rectangle {
        id: saveToast
        width: parent.width; height: 38; radius: 19
        color: Theme.fill
        visible: opacity > 0.01
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        property alias text: toastLabel.text

        function show(msg) {
            text = msg
            opacity = 1
            toastTimer.restart()
        }

        Row {
            anchors.centerIn: parent
            spacing: 8
            Icon { name: "check"; size: 16; tone: "white"; anchors.verticalCenter: parent.verticalCenter }
            Text {
                id: toastLabel
                text: "Posições dos monitores salvas com sucesso!"
                color: Theme.onAccent
                font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Timer {
            id: toastTimer
            interval: 3000
            onTriggered: saveToast.opacity = 0
        }
    }

    // Quadro / Canvas Interativo de Arranjo dos Monitores
    Rectangle {
        id: canvasBox
        width: parent.width
        height: 220
        radius: 20
        color: Theme.field
        clip: true
        border.width: 1
        border.color: Theme.track

        Repeater {
            model: root.layoutList
            delegate: Item {
                id: slot
                required property var modelData
                required property int index
                readonly property bool isSelected: root.selectedMonitorIndex === index
                readonly property real logicalW: (modelData.width || 1920) / (modelData.scale || 1)
                readonly property real logicalH: (modelData.height || 1080) / (modelData.scale || 1)
                readonly property bool overlapping: root.checkOverlap(index)

                x: Math.round(root.canvasOriginX + modelData.x * root.canvasZoom)
                y: Math.round(root.canvasOriginY + modelData.y * root.canvasZoom)
                width: Math.max(80, Math.round(logicalW * root.canvasZoom))
                height: Math.max(50, Math.round(logicalH * root.canvasZoom))
                z: dragArea.drag.active ? 100 : (isSelected ? 10 : 1)

                Rectangle {
                    id: cardRect
                    x: 0; y: 0
                    width: parent.width; height: parent.height
                    radius: 14
                    color: slot.isSelected ? Theme.cardSolid : Theme.raised
                    border.width: slot.overlapping ? 2 : (slot.isSelected ? 2 : 1)
                    border.color: slot.overlapping ? Theme.danger : (slot.isSelected ? Theme.fill : Theme.track)
                    scale: dragArea.drag.active ? 1.05 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        // Número do monitor em destaque
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 26; height: 26; radius: 13
                            color: slot.isSelected ? Theme.fill : Theme.subtle
                            Text {
                                anchors.centerIn: parent
                                text: (slot.index + 1)
                                color: slot.isSelected ? Theme.onAccent : Theme.textPrimary
                                font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Bold
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: slot.modelData.name
                            color: Theme.textPrimary
                            font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: slot.modelData.x + "×" + slot.modelData.y
                            color: slot.overlapping ? Theme.danger : Theme.textSecondary
                            font.family: Theme.font; font.pixelSize: 10
                            font.features: { "tnum": 1 }
                        }
                    }

                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        drag.target: cardRect
                        hoverEnabled: true
                        cursorShape: dragArea.drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                        onPressed: {
                            root.selectedMonitorIndex = slot.index
                        }

                        onReleased: {
                            let dx = cardRect.x / root.canvasZoom
                            let dy = cardRect.y / root.canvasZoom
                            cardRect.x = 0
                            cardRect.y = 0
                            if (Math.abs(dx) > 15 || Math.abs(dy) > 15) {
                                root.applyMove(slot.index, slot.modelData.x + dx, slot.modelData.y + dy)
                            }
                        }
                    }
                }
            }
        }

        // Mensagem discreta quando há apenas 1 monitor
        Row {
            visible: root.layoutList.length <= 1
            anchors.bottom: parent.bottom; anchors.bottomMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            Icon { name: "info"; size: 14; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: "1 tela detectada. Use '+ Simular 2ª Tela' para testar a disposição multimonitor."
                color: Theme.textSecondary
                font.family: Theme.font; font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Barra de ações e alinhamento do monitor selecionado
    Rectangle {
        width: parent.width
        height: alignCol.implicitHeight + 24
        radius: 16
        color: Theme.field
        visible: root.layoutList.length > 0

        readonly property var selMon: (root.layoutList.length > root.selectedMonitorIndex) ? root.layoutList[root.selectedMonitorIndex] : null

        Column {
            id: alignCol
            x: 16; y: 12
            width: parent.width - 32
            spacing: 12

            Row {
                width: parent.width
                spacing: 10
                Text {
                    text: "Monitor " + (root.selectedMonitorIndex + 1) + (alignCol.parent.selMon ? (" (" + alignCol.parent.selMon.name + ")") : "") + ":"
                    color: Theme.textPrimary
                    font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: alignCol.parent.selMon ? ("Posição: " + alignCol.parent.selMon.x + "×" + alignCol.parent.selMon.y + " · Resolução: " + alignCol.parent.selMon.width + "×" + alignCol.parent.selMon.height) : ""
                    color: Theme.textSecondary
                    font.family: Theme.font; font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Botões de posicionamento rápido (visíveis quando há 2+ monitores)
            Flow {
                width: parent.width
                spacing: 8
                visible: root.layoutList.length >= 2

                PillButton {
                    text: "◀ À Esquerda"
                    outlined: true
                    onClicked: root.alignSelected("left")
                }
                PillButton {
                    text: "À Direita ▶"
                    outlined: true
                    onClicked: root.alignSelected("right")
                }
                PillButton {
                    text: "▲ Acima"
                    outlined: true
                    onClicked: root.alignSelected("above")
                }
                PillButton {
                    text: "Abaixo ▼"
                    outlined: true
                    onClicked: root.alignSelected("below")
                }
                PillButton {
                    text: "Alinhar Topo"
                    outlined: true
                    onClicked: root.alignSelected("align_top")
                }
                PillButton {
                    text: "Inverter Posições"
                    outlined: true
                    onClicked: root.alignSelected("swap")
                }
            }

            // Ajuste fino de coordenadas
            Row {
                spacing: 20

                // Eixo X
                Row {
                    spacing: 6
                    Text { text: "X:"; color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle {
                        width: 30; height: 28; radius: 14; color: Theme.raised
                        Text { anchors.centerIn: parent; text: "-"; color: Theme.textPrimary; font.pixelSize: 14; font.weight: Font.Bold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.nudgeSelected(-100, 0) }
                    }
                    Rectangle {
                        width: 60; height: 28; radius: 8; color: Theme.raised
                        Text { anchors.centerIn: parent; text: alignCol.parent.selMon ? alignCol.parent.selMon.x : "0"; color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 12; font.features: { "tnum": 1 } }
                    }
                    Rectangle {
                        width: 30; height: 28; radius: 14; color: Theme.raised
                        Text { anchors.centerIn: parent; text: "+"; color: Theme.textPrimary; font.pixelSize: 14; font.weight: Font.Bold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.nudgeSelected(100, 0) }
                    }
                }

                // Eixo Y
                Row {
                    spacing: 6
                    Text { text: "Y:"; color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle {
                        width: 30; height: 28; radius: 14; color: Theme.raised
                        Text { anchors.centerIn: parent; text: "-"; color: Theme.textPrimary; font.pixelSize: 14; font.weight: Font.Bold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.nudgeSelected(0, -100) }
                    }
                    Rectangle {
                        width: 60; height: 28; radius: 8; color: Theme.raised
                        Text { anchors.centerIn: parent; text: alignCol.parent.selMon ? alignCol.parent.selMon.y : "0"; color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 12; font.features: { "tnum": 1 } }
                    }
                    Rectangle {
                        width: 30; height: 28; radius: 14; color: Theme.raised
                        Text { anchors.centerIn: parent; text: "+"; color: Theme.textPrimary; font.pixelSize: 14; font.weight: Font.Bold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.nudgeSelected(0, 100) }
                    }
                }
            }
        }
    }

    Item { width: 1; height: 4 }

    // =========================================================================
    // SEÇÃO 2: OPÇÕES INDIVIDUAIS DOS MONITORES
    // =========================================================================
    SectionTitle { text: "Monitores" }

    Repeater {
        model: root.monitors
        delegate: Rectangle {
            id: mcard
            required property var modelData
            readonly property var m: modelData
            property bool listOpen: false
            width: root.width
            height: mcol.implicitHeight + 32
            radius: 20
            color: Theme.field

            Column {
                id: mcol
                x: 18; y: 16
                width: parent.width - 36
                spacing: 14

                Row {
                    spacing: 12
                    Rectangle {
                        width: 40; height: 40; radius: 12; color: Theme.raised
                        Icon { anchors.centerIn: parent; name: "display"; size: 22 }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: (mcard.m.make && mcard.m.model) ? mcard.m.model : mcard.m.name; color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.DemiBold }
                        Text { text: mcard.m.name + " · " + mcard.m.width + "×" + mcard.m.height + " · " + Math.round(mcard.m.refreshRate) + " Hz · ×" + mcard.m.scale + " · Posição: " + root.posOf(mcard.m); color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 12 }
                    }
                }

                // Resolução e frequência (menu suspenso).
                Text { text: "Resolução"; color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 13 }
                Rectangle {
                    width: parent.width; height: 40; radius: 20; color: Theme.raised
                    Text {
                        x: 18; anchors.verticalCenter: parent.verticalCenter
                        text: mcard.m.width + " × " + mcard.m.height + "  ·  " + mcard.m.refreshRate.toFixed(2) + " Hz"
                        color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 13
                    }
                    Icon { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; name: "chevron"; size: 18; rotation: mcard.listOpen ? 180 : 0 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: mcard.listOpen = !mcard.listOpen }
                }
                Rectangle {
                    visible: mcard.listOpen
                    width: parent.width; height: Math.min(240, modes.contentHeight + 12); radius: 20; color: Theme.raised
                    clip: true
                    ListView {
                        id: modes
                        anchors.fill: parent; anchors.margins: 6
                        readonly property string currentMode: root.modeOf(mcard.m)
                        model: mcard.listOpen ? mcard.m.availableModes : []
                        boundsBehavior: Flickable.StopAtBounds

                        function selectMode(newMode) {
                            mcard.listOpen = false
                            root.request(mcard.m, newMode, mcard.m.scale)
                        }

                        delegate: Rectangle {
                            id: modeItem
                            required property string modelData
                            readonly property string mode: modelData.replace("Hz", "")
                            readonly property var view: ListView.view
                            readonly property bool cur: view ? (mode === view.currentMode) : false
                            width: view ? view.width : 0; height: 34; radius: 17
                            color: mm.containsMouse ? Theme.field : "transparent"
                            Text {
                                x: 14; anchors.verticalCenter: parent.verticalCenter
                                text: modelData.replace("x", " × ").replace("@", "  ·  ").replace("Hz", " Hz")
                                color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 13
                                font.weight: modeItem.cur ? Font.DemiBold : Font.Normal
                            }
                            Icon { visible: modeItem.cur; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; name: "check"; size: 16 }
                            MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: if (modeItem.view) modeItem.view.selectMode(modeItem.mode) }
                        }
                    }
                }

                // Escala (segmentado).
                Text { text: "Escala"; color: Theme.textPrimary; font.family: Theme.font; font.pixelSize: 13 }
                Rectangle {
                    width: parent.width; height: 40; radius: 20; color: Theme.raised
                    Row {
                        anchors.fill: parent; anchors.margins: 4
                        Repeater {
                            model: root.scales
                            delegate: Rectangle {
                                required property real modelData
                                readonly property bool cur: Math.abs(modelData - mcard.m.scale) < 0.01
                                width: (parent.width) / root.scales.length; height: parent.height; radius: height / 2
                                color: cur ? Theme.fill : (sm.containsMouse ? Theme.field : "transparent")
                                Text { anchors.centerIn: parent; text: "×" + modelData; color: parent.cur ? Theme.onAccent : Theme.textPrimary; font.family: Theme.font; font.pixelSize: 13; font.weight: parent.cur ? Font.DemiBold : Font.Normal }
                                MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.request(mcard.m, root.modeOf(mcard.m), modelData) }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // SEÇÃO 3: BRILHO E COR
    // =========================================================================
    SectionTitle { text: "Brilho e cor" }
    Column {
        width: parent.width
        spacing: 10
        MSlider {
            width: parent.width; icon: "sun"
            from: 0.3; to: 1.0
            value: DisplayState.brightness
            valueText: Math.round(value * 100) + "%"
            onMoved: v => DisplayState.set(DisplayState.saturation, v)
        }
        MSlider {
            width: parent.width; icon: "drop"
            from: 0; to: 2
            value: DisplayState.saturation
            valueText: Math.round(value * 100) + "%"
            iconClickable: true
            onIconClicked: DisplayState.set(1.0, DisplayState.brightness)
            onMoved: v => DisplayState.set(Math.abs(v - 1) < 0.04 ? 1.0 : v, DisplayState.brightness)
        }
        Text { text: "Por software (shader do Hyprland). Toque na gota para voltar a 100%."; color: Theme.textSecondary; font.family: Theme.font; font.pixelSize: 11 }
    }
}
