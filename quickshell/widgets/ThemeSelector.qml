//theme selection button and dropdown menu
import QtQuick

Item {
    id: themeSelector

    property int themeIndex: 1
    property var themes: []

    property bool menuOpen: false

    width: 30
    height: 30

    Rectangle {
        id: themeButton

        anchors.fill: parent
        radius: 7

        color: themeSelector.themes[themeSelector.themeIndex].panel
        border.color: themeSelector.themes[themeSelector.themeIndex].metal

        border.width: 1

        Text {
            anchors.centerIn: parent

            text: themeSelector.themes[themeSelector.themeIndex].symbol

            color: themeSelector.themes[themeSelector.themeIndex].metal

            font.pixelSize: 20
        }

        MouseArea {
            anchors.fill: parent

            onClicked: {
                themeSelector.menuOpen = !themeSelector.menuOpen
            }
        }
    }
    Rectangle {
        id: themeMenu

        width: 140
        height: 126
        radius: 9
        z: 10

        anchors.top: themeButton.bottom
        anchors.right: themeButton.right
        anchors.topMargin: 6
        
        color: themeSelector.themes[themeSelector.themeIndex].panel
        border.color: themeSelector.themes[themeSelector.themeIndex].metal

        border.width: 1

        visible: opacity > 0
        opacity: themeSelector.menuOpen ? 1 : 0
        enabled: themeSelector.menuOpen 

        property real slideOffset: themeSelector.menuOpen ? 0 : -7

        transform: Translate {
            y: themeMenu.slideOffset
        }

        Behavior on slideOffset {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 3

            Repeater {
                model: themeSelector.themes.length

                Rectangle {
                    id: themeOption

                    required property int index
                    readonly property int themeNumber: index

                    width: parent.width
                    height: 40
                    radius: 6

                    color: themeSelector.themeIndex === themeNumber
                        ? themeSelector.themes[themeNumber].metal
                        : "transparent"
                    
                    Text {
                        anchors.centerIn: parent

                        text: themeSelector.themes[themeOption.themeNumber].symbol + "   " + themeSelector.themes[themeOption.themeNumber].name

                        color: themeSelector.themeIndex === themeOption.themeNumber
                            ? themeSelector.themes[themeSelector.themeIndex].background
                            : themeSelector.themes[themeSelector.themeIndex].text

                        font.pixelSize: 16
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            themeSelector.themeRequested(themeOption.themeNumber)
                            themeSelector.menuOpen = false
                        }
                    }
                }
            }
        }
    }
    signal themeRequested(int index)
}