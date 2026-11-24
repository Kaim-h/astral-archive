import QtQuick
import "../widgets" as Widgets

Item {
    id: shelf
    property var entries: []
    property int bookSpacing: 2
    property int selectedIndex: -1  // Relative to this shelf; -1 selects none.
    property color selectionColor: metalColor

    property color surfaceColor: "#263c37"
    property color metalColor: "#8c6e5a"
    property color engravingColor: "#91ada1"
    property string ornamentPattern: "✧"
    property string ornamentFont: "monospace"
    property int ornamentSize: 10

    signal bookActivated(string appId)
    signal bookContextRequested(string appId)

    width: board.width
    height: 185

    Row {
        id: bookRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: board.top
        height: 168
        spacing: shelf.bookSpacing

        Repeater {
            model: shelf.entries
            Item {
                required property var modelData
                required property int index
                width: bookVisual.width
                height: bookRow.height
                z: bookVisual.hovered ? 2 : (bookVisual.keyboardSelected ? 1 : 0)

                Widgets.Book {
                    id: bookVisual
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    activeFocusOnTab: false // Keyboard stays at the Index's TextInput.
                    keyboardSelected: shelf.selectedIndex === index
                    selectionColor: shelf.selectionColor

                    appId: modelData.appId || ""
                    title: modelData.title
                    width: modelData.spineWidth !== undefined ? modelData.spineWidth : 42
                    coverColor: modelData.coverColor
                    windowCount: modelData.windowCount || 0
                    running: modelData.running
                    focused: modelData.focused
                    ribbonEnd: modelData.ribbonEnd
                    showRibbon: modelData.showRibbon !== false
                    titleOrientation: modelData.titleOrientation || "vertical"
                    spineLabel: modelData.spineLabel || ""
                    secondaryLabel: modelData.secondaryLabel || ""
                    bandCount: modelData.bandCount !== undefined ? modelData.bandCount : 2
                    titleFont: modelData.titleFont || "Elf-ish"
                    ornamentStyle: modelData.ornamentStyle
                    ornamentPattern: modelData.ornamentPattern || "✧"
                    ornamentColor: modelData.ornamentColor || shelf.metalColor
                    ornamentFont: modelData.ornamentFont || shelf.ornamentFont
                    metalColor: shelf.metalColor
                    runningColor: shelf.engravingColor
                    focusedColor: shelf.metalColor
                    inscriptionColor: shelf.engravingColor

                    onActivated: function(appId) { shelf.bookActivated(appId) }
                    onContextRequested: function(appId) { shelf.bookContextRequested(appId) }
                }
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: board.top
        width: bookRow.implicitWidth
        height: 2
        color: "#081010"
        opacity: 0.28
    }

    Rectangle {
        id: board
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(100, bookRow.implicitWidth + 28)
        height: 10
        radius: 3
        color: shelf.surfaceColor
        border.width: 1
        border.color: shelf.metalColor

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, (parent.width - 68) / 2)
            height: 1
            color: shelf.engravingColor
            opacity: 0.55
        }
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, (parent.width - 68) / 2)
            height: 1
            color: shelf.engravingColor
            opacity: 0.55
        }
        Widgets.GlyphOrnament {
            anchors.centerIn: parent
            pattern: shelf.ornamentPattern
            glyphFont: shelf.ornamentFont
            glyphSize: shelf.ornamentSize
            color: shelf.engravingColor
        }
    }
}
