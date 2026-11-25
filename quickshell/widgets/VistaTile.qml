import QtQuick
import QtQuick.Shapes
import QtQuick.Effects

// Parallelogram MASK, never a skew transform: the painting is undistorted.
// The Shape is a source of alpha for MultiEffect, not a perspective mesh.
Item {
    id: tile
    property var art: null
    property var service: null
    property var palette: ({panel:"#263c37", metal:"#8c6e5a", engraving:"#91ada1", text:"#e6e1d8"})
    property bool selected: false
    property real slantFraction: 0.075
    property bool tryThumbnail: true
    signal chosen()

    readonly property real cut: width * slantFraction
    onArtChanged: tryThumbnail = true

    Image {
        id: painting
        anchors.fill: parent
        visible: false
        asynchronous: true
        cache: true
        sourceSize.width: tile.selected ? 650 : 430
        fillMode: Image.PreserveAspectCrop
        smooth: true
        source: tile.art && tile.service
            ? (tile.tryThumbnail ? tile.service.thumbnailUrl(tile.art)
                                 : tile.service.imageUrl(tile.art)) : ""
        onStatusChanged: {
            // Optional thumbnails; missing cache falls back to the original.
            if (status === Image.Error && tile.tryThumbnail) tile.tryThumbnail=false;
        }
    }
    Shape {
        id: alphaShape
        anchors.fill: parent
        visible: false
        layer.enabled: true
        layer.smooth: true
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: "white"
            startX: tile.cut; startY: 0
            PathLine { x: tile.width; y: 0 }
            PathLine { x: tile.width-tile.cut; y: tile.height }
            PathLine { x: 0; y: tile.height }
            PathLine { x: tile.cut; y: 0 }
        }
    }
    MultiEffect {
        anchors.fill: parent
        source: painting
        maskEnabled: true
        maskSource: alphaShape
        maskThresholdMin: 0.45
        maskSpreadAtMin: 0.06
        maskThresholdMax: 1.0
        maskSpreadAtMax: 0.0
    }
    Shape {
        anchors.fill: parent
        ShapePath {
            strokeWidth: tile.selected ? 3 : 1.5
            strokeColor: tile.selected ? tile.palette.metal : tile.palette.engraving
            fillColor: "transparent"
            startX: tile.cut; startY: 1
            PathLine { x: tile.width-1; y: 1 }
            PathLine { x: tile.width-tile.cut-1; y: tile.height-1 }
            PathLine { x: 1; y: tile.height-1 }
            PathLine { x: tile.cut; y: 1 }
        }
    }
    Text {
        anchors.centerIn: parent
        visible: !tile.art || painting.status===Image.Error
        text: tile.art ? "Image missing\nSee BATCH9_IMPORT.md" : "No wallpaper"
        color: tile.palette.text
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 11
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.chosen()
    }
}
