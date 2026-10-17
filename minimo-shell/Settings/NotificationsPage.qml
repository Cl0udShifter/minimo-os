// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import "../Common"

// Página de Gerenciamento e Filtro de Notificações por Aplicativo nas Configurações.
// Permite ativar Não Perturbe global e silenciar ou permitir notificações app por app.
Column {
    id: root

    width: parent ? parent.width : 500
    spacing: 20

    property string searchText: ""
    property string activeTab: "all" // "all" | "muted" | "allowed"

    // Constrói a lista consolidada de aplicativos conhecidos (instalados + histórico)
    readonly property var allAppsList: {
        const map = new Map()

        // 1. Aplicativos com arquivos .desktop no sistema
        try {
            const list = DesktopEntries.list || []
            for (let i = 0; i < list.length; ++i) {
                const e = list[i]
                if (!e || !e.id || e.noDisplay) continue
                const cleanId = (e.id || "").replace(".desktop", "").toLowerCase().trim()
                if (!cleanId) continue

                map.set(cleanId, {
                    id: cleanId,
                    name: e.name || cleanId,
                    icon: e.icon || cleanId,
                    comment: e.comment || ""
                })
            }
        } catch (err) {
            console.warn("Erro ao carregar DesktopEntries:", err)
        }

        // 2. Aplicativos adicionais do histórico ou conhecidos
        const known = NotificationFilterState.knownApps || {}
        const keys = Object.keys(known)
        for (let i = 0; i < keys.length; ++i) {
            const k = keys[i].toLowerCase().trim()
            if (!k) continue
            if (!map.has(k)) {
                map.set(k, {
                    id: k,
                    name: known[k].name || k,
                    icon: known[k].icon || k,
                    comment: "Aplicativo detectado"
                })
            }
        }

        // 3. Aplicativos que já estão silenciados
        const muted = NotificationFilterState.mutedApps || []
        for (let i = 0; i < muted.length; ++i) {
            const m = muted[i].toLowerCase().trim()
            if (!m) continue
            if (!map.has(m)) {
                const title = m.charAt(0).toUpperCase() + m.slice(1)
                map.set(m, {
                    id: m,
                    name: title,
                    icon: m,
                    comment: "Aplicativo silenciado"
                })
            }
        }

        // Converter para array e ordenar alfabeticamente pelo nome
        const arr = Array.from(map.values())
        arr.sort((a, b) => a.name.localeCompare(b.name, "pt-BR", { sensitivity: "base" }))
        return arr
    }

    // Lista filtrada por busca e aba ativa
    readonly property var filteredApps: {
        const query = root.searchText.trim().toLowerCase()
        const tab = root.activeTab
        const list = root.allAppsList

        return list.filter(item => {
            const isMuted = NotificationFilterState.isMuted(item.id, item.name)

            // Filtro de aba
            if (tab === "muted" && !isMuted) return false
            if (tab === "allowed" && isMuted) return false

            // Filtro de busca
            if (query !== "") {
                const matchName = (item.name || "").toLowerCase().includes(query)
                const matchId = (item.id || "").toLowerCase().includes(query)
                const matchComment = (item.comment || "").toLowerCase().includes(query)
                if (!matchName && !matchId && !matchComment) return false
            }

            return true
        })
    }

    readonly property int totalMutedCount: {
        let count = 0
        const list = root.allAppsList
        for (let i = 0; i < list.length; ++i) {
            if (NotificationFilterState.isMuted(list[i].id, list[i].name)) {
                count++
            }
        }
        return count
    }

    // =========================================================================
    // SEÇÃO 1: NÃO PERTURBE GLOBAL
    // =========================================================================
    Column {
        width: parent.width
        spacing: 8

        SectionTitle { text: "Modo Foco" }

        Rectangle {
            width: parent.width
            height: dndRow.implicitHeight + 24
            radius: Theme.radiusField
            color: Theme.field

            Row {
                id: dndRow
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14

                Rectangle {
                    width: 36; height: 36; radius: 18
                    anchors.verticalCenter: parent.verticalCenter
                    color: NotificationFilterState.dnd ? Theme.fill : Theme.card
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }

                    Icon {
                        anchors.centerIn: parent
                        name: "bell"
                        size: 18
                        tone: NotificationFilterState.dnd ? "white" : "dark"
                    }
                }

                Column {
                    width: parent.width - 36 - 14 - dndSwitch.width - 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: "Não Perturbe"
                        color: Theme.textPrimary
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.weight: Font.Medium
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Silencia todas as notificações na tela temporariamente, exceto avisos críticos do sistema."
                        color: Theme.textSecondary
                        font.family: Theme.font
                        font.pixelSize: 12
                    }
                }

                MSwitch {
                    id: dndSwitch
                    anchors.verticalCenter: parent.verticalCenter
                    checked: NotificationFilterState.dnd
                    onToggled: v => NotificationFilterState.setDnd(v)
                }
            }
        }
    }

    // =========================================================================
    // SEÇÃO 2: REGRAS POR APLICATIVO
    // =========================================================================
    Column {
        width: parent.width
        spacing: 12

        Item {
            width: parent.width
            height: 32

            SectionTitle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Notificações por Aplicativo"
            }

            // Contador de apps silenciados
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: badgeText.implicitWidth + 20
                height: 26
                radius: 13
                color: root.totalMutedCount > 0 ? Theme.hover : Theme.field
                border.width: 1
                border.color: Theme.track

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.totalMutedCount === 0 ? "Todas ativas"
                        : root.totalMutedCount === 1 ? "1 silenciado"
                        : root.totalMutedCount + " silenciados"
                    color: root.totalMutedCount > 0 ? Theme.textPrimary : Theme.textSecondary
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Escolha individualmente quais aplicativos podem exibir avisos na ilha e gerar alertas visuais."
            color: Theme.textSecondary
            font.family: Theme.font
            font.pixelSize: 12
        }

        // Barra de ferramentas: Busca + Filtros de visualização
        Row {
            width: parent.width
            spacing: 10

            // Campo de busca
            Rectangle {
                width: parent.width - tabsRow.implicitWidth - 10
                height: 36
                radius: 18
                color: Theme.field
                border.width: searchInput.activeFocus ? 1.5 : 1
                border.color: searchInput.activeFocus ? Theme.fill : Theme.track

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "search"
                        size: 15
                        tone: "gray"
                    }

                    TextInput {
                        id: searchInput
                        width: parent.width - 24 - (clearBtn.visible ? 20 : 0)
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.searchText
                        font.family: Theme.font
                        font.pixelSize: 12
                        color: Theme.textPrimary
                        clip: true
                        onTextChanged: root.searchText = text

                        Text {
                            anchors.fill: parent
                            visible: parent.text === "" && !parent.activeFocus
                            text: "Buscar aplicativo..."
                            color: Theme.textSecondary
                            font.family: Theme.font
                            font.pixelSize: 12
                        }
                    }

                    Rectangle {
                        id: clearBtn
                        visible: root.searchText !== ""
                        width: 18; height: 18; radius: 9
                        anchors.verticalCenter: parent.verticalCenter
                        color: clearMouse.containsMouse ? Theme.hover : Theme.track

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: Theme.textPrimary
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = ""
                                root.searchText = ""
                            }
                        }
                    }
                }
            }

            // Abas de filtro (Todos / Ativos / Silenciados)
            Row {
                id: tabsRow
                spacing: 6

                component FilterTab: Rectangle {
                    id: tabItem
                    property string tabId
                    property string label
                    readonly property bool active: root.activeTab === tabId

                    height: 36
                    width: tabTxt.implicitWidth + 20
                    radius: 18
                    color: active ? Theme.fill : (tabMouse.containsMouse ? Theme.hover : Theme.field)
                    border.width: active ? 0 : 1
                    border.color: Theme.track

                    Text {
                        id: tabTxt
                        anchors.centerIn: parent
                        text: tabItem.label
                        color: tabItem.active ? Theme.onFill : Theme.textPrimary
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.weight: tabItem.active ? Font.DemiBold : Font.Normal
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = tabItem.tabId
                    }
                }

                FilterTab { tabId: "all"; label: "Todos" }
                FilterTab { tabId: "allowed"; label: "Permitidos" }
                FilterTab { tabId: "muted"; label: "Silenciados" }
            }
        }

        // Lista de Aplicativos
        Column {
            width: parent.width
            spacing: 6

            Repeater {
                model: root.filteredApps

                Rectangle {
                    id: appCard
                    width: parent.width
                    height: 56
                    radius: Theme.radiusField
                    color: itemMouse.containsMouse ? Theme.hover : Theme.field

                    readonly property bool isMuted: NotificationFilterState.isMuted(modelData.id, modelData.name)

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        // Ícone do aplicativo
                        Rectangle {
                            width: 36; height: 36; radius: 8
                            color: Theme.card
                            anchors.verticalCenter: parent.verticalCenter
                            clip: true

                            Image {
                                anchors.centerIn: parent
                                width: 26; height: 26
                                sourceSize: Qt.size(52, 52)
                                source: {
                                    const p = Quickshell.iconPath(modelData.icon || modelData.id, true)
                                    return p !== "" ? p : Qt.resolvedUrl("../assets/icons/dark/apps.svg")
                                }
                                smooth: true
                            }
                        }

                        // Nome e status
                        Column {
                            width: parent.width - 36 - 12 - swItem.width - 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: modelData.name
                                color: Theme.textPrimary
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: appCard.isMuted ? "Silenciado · Notificações bloqueadas"
                                                      : "Ativo · Notificações permitidas"
                                color: appCard.isMuted ? Theme.textSecondary : Theme.textSecondary
                                font.family: Theme.font
                                font.pixelSize: 11
                            }
                        }

                        // Chave seletora (Ativado = permite notificações; Desativado = silenciado)
                        MSwitch {
                            id: swItem
                            anchors.verticalCenter: parent.verticalCenter
                            checked: !appCard.isMuted
                            onToggled: allowed => {
                                NotificationFilterState.setMuted(
                                    modelData.id,
                                    !allowed,
                                    modelData.name,
                                    modelData.icon
                                )
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.rightMargin: 56 // Deixa a área do switch independente
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NotificationFilterState.toggleMute(
                                modelData.id,
                                modelData.name,
                                modelData.icon
                            )
                        }
                    }
                }
            }

            // Estado vazio quando nada bate com a busca ou filtro
            Rectangle {
                visible: root.filteredApps.length === 0
                width: parent.width
                height: 120
                radius: Theme.radiusField
                color: Theme.field

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "bell"
                        size: 26
                        tone: "gray"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.searchText !== "" ? "Nenhum aplicativo encontrado para '" + root.searchText + "'"
                            : root.activeTab === "muted" ? "Nenhum aplicativo está silenciado no momento"
                            : "Nenhum aplicativo disponível"
                        color: Theme.textSecondary
                        font.family: Theme.font
                        font.pixelSize: 13
                    }
                }
            }
        }
    }
}
