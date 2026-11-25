import QtQuick
import QtQuick.Shapes

// Standalone geometry experiment. Does NOT change widgets/Book.qml.
// Click the book to pull it forward; hover it to see a shallow preview.
// The spine remains a flat illustration at rest. As it tips, we show the
// cover boards and an exposed paper block, with all shapes driven by one tip.
Rectangle {
    id: scene
    width: 760
    height: 450
    color: "#121e23"

    property color metal: "#a99070"
    property color paper: "#dfcfaa"
    property color cover: "#516c65"
    property color ink: "#e6e1d8"

    Text {
        anchors.top: parent.top
        anchors.topMargin: 30
        anchors.horizontalCenter: parent.horizontalCenter
        text: "FORWARD-TIP EXPERIMENT"
        font.family: "serif"
        font.pixelSize: 21
        color: scene.metal
    }

    Text {
        anchors.top: parent.top
        anchors.topMargin: 66
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Hover for a small tip · Click to extract · Click again to return"
        font.pixelSize: 12
        color: "#91ada1"
    }

    Rectangle {
        id: shelf
        x: 115
        y: 340
        width: 530
        height: 15
        radius: 3
        color: "#263c37"
        border.color: scene.metal
        border.width: 1
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 28
            height: 1
            color: "#91ada1"
            opacity: 0.5
        }
    }

    // Two stationary neighbours make the change in the animated book clearer.
    Repeater {
        model: [
            { x: 292, h: 153, c: "#615a71", text: "EDIT" },
            { x: 404, h: 136, c: "#79614d", text: "FILES" }
        ]
        Rectangle {
            required property var modelData
            x: modelData.x
            y: shelf.y - modelData.h
            width: 53
            height: modelData.h
            radius: 3
            color: modelData.c
            border.color: scene.metal
            border.width: 1
            Text {
                anchors.centerIn: parent
                rotation: 90
                text: modelData.text
                color: "#dfd3bd"
                font.pixelSize: 11
            }
        }
    }

    Item {
        id: tippedBook
        x: 347
        y: shelf.y - 185
        width: 55
        height: 185
        z: 4
        focus: true
        activeFocusOnTab: true

        property bool pulled: false
        property real hoverPreview: mouse.containsMouse ? 0.17 : 0
        property real tip: pulled ? 1 : hoverPreview

        // A direct read-only projection of the tip state. At 0, the volume is
        // completely hidden and the result is an ordinary flat book spine.
        readonly property real frontHeight: 185 * (1 - tip * 0.135)
        readonly property real frontTopY: height - frontHeight
        readonly property real projectedTopDepth: tip * 31
        readonly property real projectedSide: tip * 9
        readonly property real lift: pulled ? 4 : 0

        Behavior on tip {
            NumberAnimation { duration: 350; easing.type: Easing.InOutCubic }
        }

        // Full-width page block: it remains open at its back/fore-edge.
        // It is drawn BEFORE the spine so the top has a clear near edge.
        Shape {
            anchors.fill: parent
            visible: tippedBook.tip > 0.004

            ShapePath {
                fillColor: Qt.darker(scene.paper, 1.04)
                strokeColor: Qt.darker(scene.paper, 1.28)
                strokeWidth: 0.8
                startX: 5
                startY: tippedBook.frontTopY - tippedBook.projectedSide
                PathLine { x: tippedBook.width - 5; y: tippedBook.frontTopY - tippedBook.projectedSide }
                PathLine { x: tippedBook.width - 5; y: tippedBook.frontTopY - tippedBook.projectedTopDepth }
                PathLine { x: 5; y: tippedBook.frontTopY - tippedBook.projectedTopDepth }
                PathLine { x: 5; y: tippedBook.frontTopY - tippedBook.projectedSide }
            }

            // Left cover board: colored strip to one side of the paper.
            ShapePath {
                fillColor: Qt.lighter(scene.cover, 1.12)
                strokeColor: Qt.darker(scene.cover, 1.25)
                strokeWidth: 0.65
                startX: 0
                startY: tippedBook.frontTopY
                PathLine { x: 5; y: tippedBook.frontTopY }
                PathLine { x: 5; y: tippedBook.frontTopY - tippedBook.projectedTopDepth }
                PathLine { x: 0; y: tippedBook.frontTopY - tippedBook.projectedTopDepth }
                PathLine { x: 0; y: tippedBook.frontTopY }
            }

            // Right cover board: the far end is intentionally not capped.
            ShapePath {
                fillColor: Qt.darker(scene.cover, 1.09)
                strokeColor: Qt.darker(scene.cover, 1.25)
                strokeWidth: 0.65
                startX: tippedBook.width - 5
                startY: tippedBook.frontTopY
                PathLine { x: tippedBook.width; y: tippedBook.frontTopY }
                PathLine { x: tippedBook.width; y: tippedBook.frontTopY - tippedBook.projectedTopDepth }
                PathLine { x: tippedBook.width - 5; y: tippedBook.frontTopY - tippedBook.projectedTopDepth }
                PathLine { x: tippedBook.width - 5; y: tippedBook.frontTopY }
            }
        }

        Rectangle {
            id: spine
            x: 0
            y: tippedBook.frontTopY
            width: tippedBook.width
            height: tippedBook.frontHeight
            radius: 3
            color: scene.cover
            border.color: scene.metal
            border.width: 1

            Rectangle { x: 5; y: 14; width: parent.width - 10; height: 2; color: scene.metal }
            Rectangle { x: 5; y: parent.height - 17; width: parent.width - 10; height: 2; color: scene.metal }
            Text {
                anchors.centerIn: parent
                rotation: 90
                text: "ARCHIVE"
                color: scene.ink
                font.family: "serif"
                font.pixelSize: 13
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tippedBook.pulled = !tippedBook.pulled
        }
        Keys.onReturnPressed: tippedBook.pulled = !tippedBook.pulled
        Keys.onSpacePressed: tippedBook.pulled = !tippedBook.pulled
    }

    Text {
        x: 120
        y: 381
        width: 520
        horizontalAlignment: Text.AlignHCenter
        text: "Tip: " + tippedBook.tip.toFixed(2) + "  ·  projected top depth: "
              + tippedBook.projectedTopDepth.toFixed(1) + " px"
        color: "#91ada1"
        font.pixelSize: 12
    }
}
