import QtQuick

Rectangle {
    id: button
    property string label: ""
    property var palette: ({background:"#121e23",metal:"#8c6e5a",text:"#e6e1d8"})
    signal pressed()
    width: Math.max(84, words.implicitWidth+19)
    height: 29
    radius: 5
    color: hover.hovered ? palette.metal : palette.background
    border.color: palette.metal
    opacity: enabled ? 1 : .4
    Text {
        id: words
        anchors.centerIn: parent
        text: button.label
        font.family: "monospace"; font.pixelSize: 11
        color: hover.hovered ? palette.background : palette.text
    }
    HoverHandler { id: hover }
    MouseArea {
        anchors.fill: parent
        enabled: button.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: button.pressed()
    }
}
