import QtQuick
import "../shelves" as Shelves

// Open with a QML runner from the quickshell/tests directory, or insert the
// component into a Quickshell PanelWindow for live integration testing.
Rectangle {
    id: test
    width: 900
    height: 430
    color: "#121e23"

    property string selectedApp: "None"
    property bool useHorizontalTitles: false

    readonly property var demoBooks: [
        { appId: "test.browser", title: "Browser", spineLabel: "WEB",
          titleOrientation: useHorizontalTitles ? "horizontal" : "vertical",
          coverColor: "#415d56", running: true, focused: false,
          ribbonEnd: "notch", ornamentStyle: "etched", bandCount: 2 },
        { appId: "test.editor", title: "Editor", spineLabel: "EDIT",
          titleOrientation: useHorizontalTitles ? "horizontal" : "vertical",
          coverColor: "#a79d7e", running: false, focused: false,
          ornamentStyle: "etched", bandCount: 3 },
        { appId: "test.files", title: "Files",
          titleOrientation: useHorizontalTitles ? "horizontal" : "vertical",
          coverColor: "#805d47", running: false, focused: false,
          ornamentStyle: "glyph", ornamentPattern: "✧", bandCount: 2 },
        { appId: "test.terminal", title: "Terminal", spineLabel: "TERM",
          secondaryLabel: "I", titleOrientation: useHorizontalTitles ? "horizontal" : "vertical",
          coverColor: "#49645a", running: true, focused: true,
          ribbonEnd: "point", ornamentStyle: "etched", bandCount: 3 },
        { appId: "test.music", title: "Music",
          titleOrientation: useHorizontalTitles ? "horizontal" : "vertical",
          coverColor: "#344b50", running: false, focused: false,
          ornamentStyle: "etched", bandCount: 3 },
        { appId: "test.notes", title: "Notes",
          titleOrientation: useHorizontalTitles ? "horizontal" : "vertical",
          coverColor: "#aa9b80", running: true, focused: false,
          ribbonEnd: "notch", ornamentStyle: "etched", bandCount: 2 },
        { appId: "test.tools", title: "Tools",
          titleOrientation: useHorizontalTitles ? "horizontal" : "vertical",
          coverColor: "#51695d", running: false, focused: false,
          ornamentStyle: "plain", bandCount: 0 }
    ]

    Text {
        anchors.top: parent.top
        anchors.topMargin: 38
        anchors.horizontalCenter: parent.horizontalCenter
        text: "THE ASTRAL ARCHIVE"
        font.family: "serif"
        font.pixelSize: 22
        color: "#c2aa78"
    }

    Shelves.Shelf {
        id: demoShelf
        anchors.centerIn: parent
        entries: test.demoBooks
        bookSpacing: 2
        ornamentPattern: "◇   ✦   ◇"
        surfaceColor: "#263c37"
        metalColor: "#8c6e5a"
        engravingColor: "#91ada1"
        onBookActivated: function(appId) { test.selectedApp = appId }
    }

    Rectangle {
        id: titleModeButton
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: demoShelf.bottom
        anchors.topMargin: 18
        width: 190
        height: 29
        radius: 5
        color: "#263c37"
        border.width: 1
        border.color: "#8c6e5a"

        Text {
            anchors.centerIn: parent
            color: "#e6e1d8"
            font.pixelSize: 11
            text: test.useHorizontalTitles ? "Use vertical titles" : "Use horizontal titles"
        }
        MouseArea {
            anchors.fill: parent
            onClicked: test.useHorizontalTitles = !test.useHorizontalTitles
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: titleModeButton.bottom
        anchors.topMargin: 10
        text: "Selected: " + test.selectedApp + "  ·  Hover a bookmark to uncover its spine"
        font.pixelSize: 12
        color: "#91ada1"
    }
}
