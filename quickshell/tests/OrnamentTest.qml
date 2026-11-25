import QtQuick
import "../ornaments" as Ornaments

Rectangle {
    id: test
    width: 1000
    height: 875
    color: "#121e23"

    property int themeIndex: 1
    readonly property var palettes: [
        { background: "#343c43", panel: "#3f524f", metal: "#c2aa78", engraving: "#b7a2c8", text: "#f0f0e8" },
        { background: "#121e23", panel: "#263c37", metal: "#8c6e5a", engraving: "#91ada1", text: "#e6e1d8" },
        { background: "#080f10", panel: "#101c1b", metal: "#869c9c", engraving: "#568f80", text: "#dadfd9" }
    ]
    property string lastApplied: "Nothing applied yet"

    Ornaments.EngravingWorkshop {
        id: editor
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        palette: test.palettes[test.themeIndex]
        onApplyRequested: function(design, target) {
            test.lastApplied = target + ": " + JSON.stringify(design)
        }
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 9
        spacing: 15
        Text {
            text: "Theme: " + ["Evening", "Twilight", "Midnight"][test.themeIndex]
            color: test.palettes[test.themeIndex].text
            font.pixelSize: 12
        }
        Rectangle {
            width: 112; height: 22
            color: test.palettes[test.themeIndex].panel
            border.color: test.palettes[test.themeIndex].metal
            Text { anchors.centerIn: parent; text: "NEXT THEME"; color: test.palettes[test.themeIndex].text; font.pixelSize: 11 }
            MouseArea { anchors.fill: parent; onClicked: test.themeIndex = (test.themeIndex + 1) % 3 }
        }
        Text {
            width: 570
            elide: Text.ElideRight
            text: test.lastApplied
            color: test.palettes[test.themeIndex].text
            font.pixelSize: 10
        }
    }
}