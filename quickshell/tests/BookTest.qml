import QtQuick
import "../widgets" as Widgets

Rectangle {
    id: test

    width: 800
    height: 400
    color: "#121e23"

    property string lastActivated: "None"

    Row {
        anchors.centerIn: parent
        spacing: 24

        Repeater {
            model: [
                { title: "Web", running: false, focused: false },
                { title: "Browser", running: true, focused: false },
                { title: "Navigator", running: true, focused: true },
                { title: "Editor", running: true, focused: false }
            ]

            Item {
                required property var modelData

                width: 60
                height: 175

                Widgets.Book {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom

                    title: modelData.title
                    running: modelData.running
                    focused: modelData.focused

                    ribbonEnd: "notch"

                    onActivated: {
                        test.lastActivated = title
                    }
                }
            }
        }
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20

        text: "Last selected: " + test.lastActivated
        color: "#e6e1d8"
        font.pixelSize: 16
    }
}
