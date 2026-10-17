// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import QtQuick
import Quickshell
import "../../Common"

// Widget de Calendário interativo para o menu expansivo do Notch.
// Navegação completa por meses/anos, destaque do dia atual, seleção e atalhos.
Item {
    id: root
    signal back()
    signal picked(var date)

    implicitHeight: col.implicitHeight

    SystemClock { id: clock; precision: SystemClock.Minutes }

    readonly property var today: clock.date
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth() // 0-11
    property var selectedDate: new Date(today.getFullYear(), today.getMonth(), today.getDate())

    readonly property bool isCurrentMonthView: viewYear === today.getFullYear() && viewMonth === today.getMonth()

    readonly property var monthNames: [
        "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ]

    readonly property var weekDayNames: ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SÁB"]

    function prevMonth() {
        if (viewMonth === 0) {
            viewMonth = 11
            viewYear--
        } else {
            viewMonth--
        }
    }

    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0
            viewYear++
        } else {
            viewMonth++
        }
    }

    function goToToday() {
        viewYear = today.getFullYear()
        viewMonth = today.getMonth()
        selectedDate = new Date(today.getFullYear(), today.getMonth(), today.getDate())
    }

    // Gera lista de 42 dias (6 semanas completas de domingo a sábado)
    function generateDays(y, m) {
        const firstDayWeekIndex = new Date(y, m, 1).getDay() // 0 = Domingo
        const prevMonthTotalDays = new Date(y, m, 0).getDate()
        const currentMonthTotalDays = new Date(y, m + 1, 0).getDate()
        const list = []

        // Dias do mês anterior
        for (let i = firstDayWeekIndex - 1; i >= 0; i--) {
            const d = prevMonthTotalDays - i
            const pm = m === 0 ? 11 : m - 1
            const py = m === 0 ? y - 1 : y
            list.push({ day: d, month: pm, year: py, current: false })
        }

        // Dias do mês atual
        for (let d = 1; d <= currentMonthTotalDays; d++) {
            list.push({ day: d, month: m, year: y, current: true })
        }

        // Dias do próximo mês
        const remaining = 42 - list.length
        for (let d = 1; d <= remaining; d++) {
            const nm = m === 11 ? 0 : m + 1
            const ny = m === 11 ? y + 1 : y
            list.push({ day: d, month: nm, year: ny, current: false })
        }

        return list
    }

    property var daysList: generateDays(viewYear, viewMonth)
    onViewYearChanged: daysList = generateDays(viewYear, viewMonth)
    onViewMonthChanged: daysList = generateDays(viewYear, viewMonth)

    function isSameDay(d1, d2) {
        if (!d1 || !d2) return false
        return d1.getFullYear() === d2.getFullYear() &&
               d1.getMonth() === d2.getMonth() &&
               d1.getDate() === d2.getDate()
    }

    Column {
        id: col
        width: parent.width
        spacing: 14

        // 1. Barra de cabeçalho: Voltar, Mês/Ano e Navegação
        Item {
            width: parent.width
            height: 36

            // Botão Voltar
            Rectangle {
                id: backBtn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 32; height: 32; radius: 16
                color: backMouse.containsMouse ? Theme.hover : Theme.field
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
                Icon { anchors.centerIn: parent; name: "back"; size: 16 }
                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.back()
                }
            }

            // Mês e Ano Centralizados
            Row {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: root.monthNames[root.viewMonth] + " " + root.viewYear
                    color: Theme.textPrimary
                    font.family: Theme.font
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
            }

            // Controles de navegação à direita
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // Botão "Hoje" (aparece quando não estiver no mês atual)
                Rectangle {
                    visible: !root.isCurrentMonthView
                    anchors.verticalCenter: parent.verticalCenter
                    height: 28
                    width: todayTxt.implicitWidth + 14
                    radius: 14
                    color: todayMouse.containsMouse ? Theme.hover : Theme.field
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    Text {
                        id: todayTxt
                        anchors.centerIn: parent
                        text: "Hoje"
                        color: Theme.textPrimary
                        font.family: Theme.font
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                    MouseArea {
                        id: todayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.goToToday()
                    }
                }

                // Mês Anterior
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: prevMouse.containsMouse ? Theme.hover : Theme.field
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    Icon { anchors.centerIn: parent; name: "back"; size: 14 }
                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.prevMonth()
                    }
                }

                // Próximo Mês
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: nextMouse.containsMouse ? Theme.hover : Theme.field
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    Icon {
                        anchors.centerIn: parent
                        name: "back"
                        size: 14
                        rotation: 180
                    }
                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.nextMonth()
                    }
                }
            }
        }

        // 2. Dias da Semana (DOM, SEG, TER, QUA, QUI, SEX, SÁB)
        Row {
            width: parent.width
            Repeater {
                model: root.weekDayNames
                Item {
                    width: col.width / 7
                    height: 20
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: Theme.textSecondary
                        font.family: Theme.font
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        // 3. Grid dos Dias do Mês (42 células fixas, scroll para navegar)
        MouseArea {
            width: parent.width
            height: gridCol.implicitHeight
            onWheel: wheel => {
                if (wheel.angleDelta.y > 0) root.prevMonth()
                else if (wheel.angleDelta.y < 0) root.nextMonth()
            }

            Grid {
                id: gridCol
                width: parent.width
                columns: 7
                rowSpacing: 4
                columnSpacing: 0

                Repeater {
                    model: root.daysList
                    Item {
                        width: col.width / 7
                        height: 36

                        readonly property bool isTodayDay: root.isSameDay(root.today, new Date(modelData.year, modelData.month, modelData.day))
                        readonly property bool isSelectedDay: root.isSameDay(root.selectedDate, new Date(modelData.year, modelData.month, modelData.day))
                        readonly property bool isCurMonth: modelData.current

                        Rectangle {
                            id: dayCircle
                            anchors.centerIn: parent
                            width: 32; height: 32; radius: 16
                            scale: cellMouse.pressed ? 0.92 : 1
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            color: isTodayDay ? Theme.fill
                                 : isSelectedDay ? Theme.hover
                                 : (cellMouse.containsMouse ? Theme.hover : "transparent")

                            border.width: (isSelectedDay && !isTodayDay) ? 1.5 : 0
                            border.color: Theme.fill

                            Behavior on color { ColorAnimation { duration: Theme.durFast } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.day
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: (isTodayDay || isSelectedDay) ? Font.DemiBold : Font.Normal
                                font.features: { "tnum": 1 }
                                color: isTodayDay ? Theme.onFill
                                     : isCurMonth ? Theme.textPrimary
                                     : Theme.textSecondary
                                opacity: isCurMonth ? 1.0 : 0.35
                            }

                            MouseArea {
                                id: cellMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedDate = new Date(modelData.year, modelData.month, modelData.day)
                                    if (!modelData.current) {
                                        root.viewYear = modelData.year
                                        root.viewMonth = modelData.month
                                    }
                                    root.picked(root.selectedDate)
                                }
                            }
                        }
                    }
                }
            }
        }

        // 4. Cartão informativo do dia selecionado
        Rectangle {
            width: parent.width
            height: 52
            radius: Theme.radiusField
            color: Theme.field

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Theme.card
                    Icon { anchors.centerIn: parent; name: "calendar"; size: 16 }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        text: {
                            if (!root.selectedDate) return ""
                            const isTod = root.isSameDay(root.today, root.selectedDate)
                            const formatted = root.selectedDate.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM")
                            const cap = formatted.charAt(0).toUpperCase() + formatted.slice(1)
                            return isTod ? "Hoje · " + cap : cap
                        }
                        color: Theme.textPrimary
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                    Text {
                        text: {
                            if (!root.selectedDate) return ""
                            const diffDays = Math.round((root.selectedDate - new Date(root.today.getFullYear(), root.today.getMonth(), root.today.getDate())) / (1000 * 60 * 60 * 24))
                            if (diffDays === 0) return Qt.formatDateTime(clock.date, "HH:mm") + " · Horário local"
                            if (diffDays === 1) return "Amanhã"
                            if (diffDays === -1) return "Ontem"
                            if (diffDays > 0) return "Em " + diffDays + " dias"
                            return "Há " + Math.abs(diffDays) + " dias"
                        }
                        color: Theme.textSecondary
                        font.family: Theme.font
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
