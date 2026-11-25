import QtQuick

Rectangle {
    id: desktop
    property int themeIndex: 1
    property bool menuOpen: false
    property int activeWorkspace: 1
    property string clockText: ""
    property bool colonVisible: true
    
    property var themes: [ 
        {
            name: "Evening",
            symbol: "☀",
            background: "#343c43",
            panel: "#3f524f",
            accent: "#b7a2c8",
            gold: "#d1b886",
            text: "#F0F0e8"
        },
        {
            name: "Twilight",
            symbol: "✦",
            background: "#121e23",
            panel: "#263c37",
            accent: "#9882b4",
            gold: "#C6a86c",
            text: "#e6e1d8"
        },
        {
            name: "Midnight",
            symbol: "☾", 
            background: "#080f10",
            panel: "#101c1b",
            accent: "#8876b0",
            gold: "#AE956b",
            text: "#dadfd9"
        },
    ]

    width: 500
    height: 300
    color: themes[themeIndex].background

    Behavior on color {
        ColorAnimation { duration: 350 }
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            desktop.colonVisible = !desktop.colonVisible
            desktop.clockText = 
                Qt.formatTime(new Date(), "hh:mm")
        }
    }
    Rectangle {
        id: displayPanel
        
        width: 350
        height: 150
        anchors.centerIn: parent
        radius: 12

        color: desktop.themes[desktop.themeIndex].panel
        border.color: desktop.themes[desktop.themeIndex].accent
        border.width: 2
        
        Behavior on color {
            ColorAnimation { duration: 350 }
        }
        
        Behavior on border.color {
            ColorAnimation { duration: 350 }
        }

        Text {
            anchors.centerIn: parent

            text: "Astral Archive\n" + desktop.themes[desktop.themeIndex].name
            color: desktop.themes[desktop.themeIndex].gold
            font.pixelSize: 25
            horizontalAlignment: Text.AlignHCenter

            Behavior on color {
                ColorAnimation { duration: 350 }
            }
        }
    }
    Rectangle {
        id: archiveBar

        height: 54
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        color: desktop.themes[desktop.themeIndex].panel
        border.color: desktop.themes[desktop.themeIndex].accent
        border.width: 1

        Text {
            id: clockDisplay

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: themeButton.left
            anchors.rightMargin: 15

            text: desktop.clockText.replace(":", desktop.colonVisible ? ":" : " ")
            color: desktop.themes[desktop.themeIndex].gold
            font.family: "monospace"
            font.pixelSize: 15
        }

        Row {
            id: workspaceRow

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 15

            spacing: 8

            Repeater {
                model: 5

                Rectangle {
                    id: workspaceButton

                    property int workspaceNumber: index + 1

                    width: 30
                    height: 30
                    radius: 6

                    color: desktop.activeWorkspace === workspaceNumber
                        ? desktop.themes[desktop.themeIndex].accent
                        : desktop.themes[desktop.themeIndex].background

                    border.color: desktop.themes[desktop.themeIndex].gold
                    border.width: desktop.activeWorkspace === workspaceNumber
                        ? 1
                        : 0

                    Text {
                        anchors.centerIn: parent
                        text: workspaceButton.workspaceNumber

                        color: desktop.activeWorkspace ===
                               workspaceButton.workspaceNumber
                            ? desktop.themes[desktop.themeIndex].background
                            : desktop.themes[desktop.themeIndex].text
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            desktop.activeWorkspace =
                                workspaceButton.workspaceNumber
                        }
                    }
                }
            }
        }
        Text {
            anchors.centerIn: parent
            text: "✦ Archive"
            color: desktop.themes[desktop.themeIndex].gold
            font.pixelSize: 15
        }

        Rectangle {
            id: themeButton

            width: 36
            height: 36
            radius: 8

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.margins: 12

            color: desktop.themes[desktop.themeIndex].panel
            border.color: desktop.themes[desktop.themeIndex].accent
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: desktop.themes[desktop.themeIndex].symbol
                color: desktop.themes[desktop.themeIndex].gold
                font.pixelSize: 20
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    desktop.menuOpen = !desktop.menuOpen
                }
            }
        }
    }
    Rectangle {
        id: themeMenu

        width: 125
        height: 126
        radius: 9
        z: 10

        anchors.top: archiveBar.bottom
        anchors.right: archiveBar.right
        anchors.topMargin: 6
        anchors.rightMargin: 12

        color: "#d9" + desktop.themes[desktop.themeIndex].panel.substring(1)
        border.color: desktop.themes[desktop.themeIndex].accent
        border.width: 1

        visible: opacity > 0
        opacity: desktop.menuOpen ? 1 : 0
        enabled: desktop.menuOpen
    

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        property real slideOffset: desktop.menuOpen ? 0 : -7

        transform: Translate {
            y: themeMenu.slideOffset
        }

        Behavior on slideOffset {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 3

            
            Repeater {
                model: desktop.themes.length

                Rectangle {
                    id: themeOption

                    property int themeNumber: index

                    width: parent.width
                    height: 40
                    radius: 6

                    color: desktop.themeIndex === themeNumber
                        ? desktop.themes[themeNumber].accent
                        : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: desktop.themes[themeOption.themeNumber].symbol
                            + "   "
                            + desktop.themes[themeOption.themeNumber].name

                        color: desktop.themeIndex === themeNumber
                            ? desktop.themes[desktop.themeIndex].background
                            : desktop.themes[desktop.themeIndex].text

                        font.pixelSize: 16
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            desktop.themeIndex = themeOption.themeNumber
                            desktop.menuOpen = false
                        }
                    }
                }
            }
        }
    } 
}