// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Gerenciador central de temas de cursor do mouse e ícones do Minimo OS.
// Faz a ponte entre as Configurações e o theme-manager.py.
Singleton {
    id: root

    property var cursorThemes: []
    property var iconThemes: []
    property string currentCursor: "Adwaita"
    property int currentCursorSize: 24
    property string currentIcon: "Adwaita"
    property bool loaded: false
    property bool scanning: false

    readonly property string managerScript: Qt.resolvedUrl("../scripts/theme-manager.py").toString().replace("file://", "")

    function refresh() {
        if (scanProcess.running) return
        scanning = true
        scanProcess.buffer = ""
        scanProcess.running = true
    }

    function setCursorTheme(themeId) {
        if (!themeId || themeId === currentCursor) return
        currentCursor = themeId
        Quickshell.execDetached(["python3", root.managerScript, "set-cursor", themeId, root.currentCursorSize.toString()])
    }

    function setCursorSize(size) {
        if (!size || size === currentCursorSize) return
        currentCursorSize = size
        Quickshell.execDetached(["python3", root.managerScript, "set-cursor", root.currentCursor, size.toString()])
    }

    function setIconTheme(themeId) {
        if (!themeId || themeId === currentIcon) return
        currentIcon = themeId
        Quickshell.execDetached(["python3", root.managerScript, "set-icon", themeId])
    }

    Component.onCompleted: refresh()

    Process {
        id: scanProcess
        property string buffer: ""
        command: ["python3", root.managerScript, "list"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => scanProcess.buffer += data
        }
        onExited: {
            root.scanning = false
            try {
                const res = JSON.parse(scanProcess.buffer.trim())
                root.cursorThemes = res.cursorThemes || []
                root.iconThemes = res.iconThemes || []
                if (res.currentCursor) root.currentCursor = res.currentCursor
                if (res.currentCursorSize) root.currentCursorSize = res.currentCursorSize
                if (res.currentIcon) root.currentIcon = res.currentIcon
            } catch (e) {
                console.warn("[ThemeState] Falha ao processar lista de temas:", e)
            }
            root.loaded = true
        }
    }
}
