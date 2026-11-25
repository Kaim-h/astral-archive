import QtQuick
import Quickshell
import "../services" as Services
import "../shelves" as Shelves

// Run inside Hyprland with:
//   qs -p quickshell/tests/LiveLauncherTest.qml
//
// Deliberately independent of shell.qml. It can be deleted after integration.
ShellRoot {
    PanelWindow {
        id: window
        anchors {
            top: true
            left: true
        }
        implicitWidth: 840
        implicitHeight: 370
        exclusiveZone: 0
        focusable: true
        color: "#121e23"

        Services.ApplicationService {
            id: apps
            maxVisible: 12
        }

        Text {
            anchors.top: parent.top
            anchors.topMargin: 18
            anchors.horizontalCenter: parent.horizontalCenter
            text: "THE ASTRAL ARCHIVE · LIVE APPLICATIONS"
            color: "#c2aa78"
            font.family: "serif"
            font.pixelSize: 19
        }

        Rectangle {
            id: searchBox
            anchors.top: parent.top
            anchors.topMargin: 57
            anchors.horizontalCenter: parent.horizontalCenter
            width: 440
            height: 31
            radius: 5
            color: "#1e302d"
            border.color: "#8c6e5a"
            border.width: 1

            TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: "#e6e1d8"
                font.pixelSize: 12
                selectByMouse: true
                clip: true
                onTextChanged: apps.searchText = text
            }

            Text {
                visible: searchInput.text.length === 0
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Filter installed applications (test field)"
                color: "#819b92"
                font.pixelSize: 11
            }
        }

        Shelves.Shelf {
            id: liveShelf
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: searchBox.bottom
            anchors.topMargin: 19

            entries: apps.bookEntries
            bookSpacing: 2
            surfaceColor: "#263c37"
            metalColor: "#8c6e5a"
            engravingColor: "#91ada1"
            ornamentPattern: "✧"

            onBookActivated: function(appId) {
                apps.activate(appId);
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            text: apps.filtered.length + " matches / "
                  + apps.catalogue.length + " installed · Page "
                  + (Math.min(apps.page, apps.pageCount - 1) + 1)
                  + " of " + apps.pageCount
            color: "#91ada1"
            font.pixelSize: 11
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 45
            width: parent.width - 24
            horizontalAlignment: Text.AlignHCenter
            text: apps.lastMessage
            color: "#e6e1d8"
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        Rectangle {
            id: previousButton
            x: parent.width - 122
            y: parent.height - 29
            width: 43
            height: 23
            radius: 4
            color: "#304640"
            border.color: "#8c6e5a"
            opacity: apps.page > 0 ? 1 : 0.35

            Text {
                anchors.centerIn: parent
                text: "←"
                color: "#e6e1d8"
                font.pixelSize: 16
            }
            MouseArea {
                anchors.fill: parent
                enabled: apps.page > 0
                onClicked: apps.previousPage()
            }
        }

        Rectangle {
            x: parent.width - 72
            y: parent.height - 29
            width: 43
            height: 23
            radius: 4
            color: "#304640"
            border.color: "#8c6e5a"
            opacity: apps.page + 1 < apps.pageCount ? 1 : 0.35

            Text {
                anchors.centerIn: parent
                text: "→"
                color: "#e6e1d8"
                font.pixelSize: 16
            }
            MouseArea {
                anchors.fill: parent
                enabled: apps.page + 1 < apps.pageCount
                onClicked: apps.nextPage()
            }
        }
    }
}
