import QtQuick
import "../widgets" as Widgets

Item {
    id: canvas

    property string surfaceType: "book"
    property int surfaceWidth : 42
    property int surfaceHeight: 150

    property var design: ({})
    property var palette: ({ panel: "#263c37", metal: "#8c6e5a", engraving: "#91ada1" })

    width: surfaceWidth
    height: surfaceHeight

    Rectangle {
        anchors.fill: parent
        radius: canvas.surfaceType === "book" ? 4 : 3
        clip: true

        color: canvas.palette.panel
        border.color: canvas.palette.metal
        border.width: 1

        Rectangle {
            visible: canvas.surfaceType === "shelf"
            anchors.top: parent.top
            anchors.topMargin: 3
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 12
            height: 1
            color: canvas.palette.metal
            opacity: 0.45
        }

        Widgets.GlyphOrnament {
            x: canvas.design.x === undefined ? 4 : canvas.design.x
            y: canvas.design.y === undefined ? 4 : canvas.design.y
            pattern: canvas.design.pattern || ""
            glyphFont: canvas.design.fontFamily || "monospace"
            glyphSize: canvas.design.fontSize === undefined ? 5 : canvas.design.fontSize
            glyphSpacing: canvas.design.letterSpacing || 0
            glyphLineHeight: canvas.design.lineHeight || 1
            color: canvas.design.useThemeColor || !canvas.design.color
                ? canvas.palette.engraving : canvas.design.color
            opacity: canvas.design.opacity === undefined ? 1 : canvas.design.opacity
            rotation: canvas.design.rotation || 0
            transformOrigin: Item.Center
        }
    }
}