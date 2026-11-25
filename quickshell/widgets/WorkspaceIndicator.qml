import QtQuick

// Compatible with existing BarTest.qml while accepting dynamic workspace IDs.
Row {
    id: strip
    property int activeWorkspace: 1
    property var workspaceIds: [1, 2, 3, 4, 5]
    property color activeColor: "#8c6e5a"
    property color inactiveColor: "#121e23"
    property color textColor: "#e6e1d8"
    signal workspaceRequested(int number)

    spacing: 6
    Repeater {
        model: strip.workspaceIds
        Rectangle {
            id: tile
            required property var modelData
            readonly property int workspaceNumber: Number(modelData)
            width: 28
            height: 28
            radius: 4
            color: strip.activeWorkspace === workspaceNumber
                ? strip.activeColor : strip.inactiveColor
            border.color: strip.activeColor
            border.width: strip.activeWorkspace === workspaceNumber ? 2 : 1
            Text {
                anchors.centerIn: parent
                text: tile.workspaceNumber
                font.family: "monospace"
                font.pixelSize: 12
                color: strip.activeWorkspace === tile.workspaceNumber
                    ? strip.inactiveColor : strip.textColor
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: strip.workspaceRequested(tile.workspaceNumber)
            }
        }
    }
}
