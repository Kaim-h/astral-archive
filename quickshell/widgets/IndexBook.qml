import QtQuick

// The Index is a fixed reference book, never a folder or ordinary app.
// It receives a selection indicator; the actual keyboard target is in
// LauncherPanel.qml, so keyboard focus need not jump between book objects.
Rectangle {
    id: reference
    property bool selected: true
    property bool searching: false
    property color metalColor: "#8c6e5a"
    property color accentColor: "#91ada1"
    property color textColor: "#e6e1d8"
    signal requested()

    width: 62
    height: 91
    radius: 3
    color: "#4e6159"
    border.color: selected ? accentColor : metalColor
    border.width: selected ? 2 : 1

    Rectangle {
        x: 6; y: 6; width: parent.width - 12; height: 1
        color: reference.metalColor
    }
    Rectangle {
        x: 6; y: parent.height - 8; width: parent.width - 12; height: 1
        color: reference.metalColor
    }
    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -5
        text: "INDEX"
        color: reference.textColor
        font.family: "serif"
        font.pixelSize: 12
        font.bold: true
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 15
        text: searching ? "✧ ✦" : "✧"
        color: reference.accentColor
        font.pixelSize: 12
    }
    HoverHandler { id: hover }
    TapHandler { onTapped: reference.requested() }
    Rectangle {
        anchors.fill: parent
        radius: 3
        color: "transparent"
        border.color: reference.accentColor
        border.width: 1
        visible: hover.hovered && !reference.selected
    }
}
