
import QtQuick
import "../shelves" as Shelves

Rectangle {
    id: test

    width: 850
    height: 430
    color: "#121e23"

    property string selectedBook: "None"

    property var books: [
        {
            appId: "demo.web",
            title: "Web",
            coverColor: "#415d56",
            running: false,
            focused: false,
            ribbonEnd: "notch",
            ornamentStyle: "etched"
        },
        {
            appId: "demo.browser",
            title: "Browser",
            coverColor: "#586d80",
            running: true,
            focused: false,
            ribbonEnd: "notch",
            ornamentStyle: "glyph",
            ornamentPattern: "✧"
        },
        {
            appId: "demo.navigator",
            title: "Navigator",
            coverColor: "#625774",
            running: true,
            focused: true,
            ribbonEnd: "point",
            ornamentStyle: "glyph",
            ornamentPattern "<{O}>"
        },
        {
            appId: "demo.editor",
            title: "Editor",
            coverColor: "#80634f",
            running: true,
            focused: false,
            ribbonEnd: "flat",
            ornamentStyle: "plain"
        }
    ]

    Text {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 35

        text: "THE ASTRAL ARCHIVE"
        color: "#91ada1"
        font.pixelSize: 22
    }

    Shelves.Shelf {
        ornamentPattern: "✧"
        ornamentFont: "monospace"
        ornamentSize: 10
        anchors.centerIn: parent

        entries: test.books

        surfaceColor: "#263c37"
        metalColor: "#8c6e5a"
        engravingColor: "#91ada1"

        onBookActivated: function(appId) {
            test.selectedBook = appId
        }
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 35

        text: "Selected book: " + test.selectedBook
        color: "#e6e1d8"
        font.pixelSize: 16
    }
}