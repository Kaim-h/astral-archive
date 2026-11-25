import QtQuick
import QtQuick.Shapes

Rectangle {
    id: book
    property string appId: ""

    property string title: "Browser"
    property color coverColor: "#415d56"
    property color metalColor: "#8c6e5a"

    property string ornamentStyle: "etched"
    property color ornamentColor: metalColor
    property string ornamentPattern: "✧"
    property string ornamentFont: "monospace"
    property int ornamentSize: 11
    property int minBookHeight: 90
    property int maxBookHeight: 160

    property int windowCount: 0  // Count of windows; a book still means one app.
    property bool running: false
    // Desktop application's focus; independent from selection in the launcher.
    property bool focused: false
    // Logical selection from arrow-key navigation, NOT Qt's activeFocus.
    property bool keyboardSelected: false
    property color selectionColor: "#c2aa78"
    property color runningColor: "#91ada1"
    property color focusedColor: "#c2aa78"
    property color inscriptionColor: "#b7a2c8"
    property color ribbonTextColor: "#213138"
    property string ribbonEnd: "notch"

    property string titleOrientation: "vertical"
    property string spineLabel: ""
    property string secondaryLabel: ""
    property string titleFont: "Elf-ish"
    property int bandCount: 2
    property bool showRibbon: true

    signal activated(string appId)

    readonly property int nameLength: Math.max(4, Math.min(title.length, 18))
    readonly property string visibleTitle: spineLabel.length > 0 ? spineLabel : title
    readonly property bool ribbonShown: showRibbon && (running || focused)
    readonly property bool hovered: hover.hovered
    readonly property color ribbonColor: focused ? focusedColor : runningColor
    readonly property real ribbonLength: nameLength <= 7 ? height * 0.70
                                        : nameLength <= 12 ? height * 0.80
                                        : height * 0.87
    property real ribbonBend: hover.hovered && ribbonShown ? 1 : 0

    width: 42
    height: Math.max(minBookHeight, Math.min(maxBookHeight, 65 + nameLength * 5))
    radius: 4
    color: coverColor
    border.color: keyboardSelected ? selectionColor
                : hovered ? Qt.lighter(selectionColor, 1.2) : metalColor
    border.width: keyboardSelected ? 2 : 1
    clip: false
    activeFocusOnTab: true

    Behavior on ribbonBend {
        NumberAnimation {
            duration: 320
            easing.type: Easing.InOutSine
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 3
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        width: 1
        color: book.ornamentColor
        opacity: 0.16
    }
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 3
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        width: 1
        color: book.ornamentColor
        opacity: 0.12
    }

    Repeater {
        model: book.ornamentStyle === "etched" ? Math.max(0, Math.min(5, book.bandCount)) : 0
        Rectangle {
            required property int index
            x: 5
            y: book.bandCount <= 1 ? book.height / 2 - 1
               : 10 + index * (book.height - 22) / (book.bandCount - 1)
            width: book.width - 10
            height: 2
            color: book.ornamentColor
            opacity: 0.85
        }
    }

    GlyphOrnament {
        visible: book.ornamentStyle === "glyph"
        anchors.top: parent.top
        anchors.topMargin: 7
        anchors.horizontalCenter: parent.horizontalCenter
        pattern: book.ornamentPattern
        glyphFont: book.ornamentFont
        glyphSize: book.ornamentSize
        color: book.ornamentColor
    }

    Text {
        visible: book.titleOrientation !== "horizontal"
        anchors.centerIn: parent
        width: book.height - 34
        height: 18
        rotation: 90
        text: book.visibleTitle
        textFormat: Text.PlainText
        color: book.inscriptionColor
        font.family: book.titleFont
        font.pixelSize: 12
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: 9
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        clip: true
    }

    Text {
        visible: book.titleOrientation === "horizontal"
        x: 5
        width: book.width - 10
        height: 18
        y: book.secondaryLabel.length > 0 ? book.height * 0.32 - height / 2
                                         : book.height * 0.49 - height / 2
        text: book.visibleTitle
        textFormat: Text.PlainText
        color: book.inscriptionColor
        font.family: book.titleFont
        font.pixelSize: 11
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: 7
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        clip: true
    }

    Text {
        visible: book.titleOrientation === "horizontal" && book.secondaryLabel.length > 0
        x: 5
        width: book.width - 10
        height: 17
        y: book.height * 0.70 - height / 2
        text: book.secondaryLabel
        textFormat: Text.PlainText
        color: book.inscriptionColor
        font.family: book.titleFont
        font.pixelSize: 10
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: 7
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        clip: true
    }

    Shape {
        id: ribbon
        visible: book.ribbonShown
        anchors.top: parent.top
        anchors.topMargin: -1
        anchors.horizontalCenter: parent.horizontalCenter
        width: book.width
        height: book.ribbonLength

        readonly property real stripWidth: 14
        readonly property real leftX: (width - stripWidth) / 2
        readonly property real rightX: leftX + stripWidth
        readonly property real bendX: book.ribbonBend * 18
        readonly property real cornerY: book.ribbonEnd === "point" ? height - 10 : height
        readonly property real middleY: book.ribbonEnd === "notch" ? height - 10 : height
        readonly property real elbowY: height * 0.64

        ShapePath {
            fillColor: book.ribbonColor
            strokeColor: "transparent"
            startX: ribbon.leftX
            startY: 0
            PathLine { x: ribbon.rightX; y: 0 }
            PathCubic {
                control1X: ribbon.rightX
                control1Y: ribbon.height * 0.12
                control2X: ribbon.rightX + ribbon.bendX
                control2Y: ribbon.height * 0.20
                x: ribbon.rightX + ribbon.bendX
                y: ribbon.elbowY
            }
            PathLine { x: ribbon.rightX + ribbon.bendX; y: ribbon.cornerY }
            PathLine { x: ribbon.leftX + ribbon.stripWidth / 2 + ribbon.bendX; y: ribbon.middleY }
            PathLine { x: ribbon.leftX + ribbon.bendX; y: ribbon.cornerY }
            PathLine { x: ribbon.leftX + ribbon.bendX; y: ribbon.elbowY }
            PathCubic {
                control1X: ribbon.leftX + ribbon.bendX
                control1Y: ribbon.height * 0.20
                control2X: ribbon.leftX
                control2Y: ribbon.height * 0.12
                x: ribbon.leftX
                y: 0
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(1, 1, 1, 0.21)
            strokeWidth: 1
            startX: ribbon.leftX + 2
            startY: 4
            PathCubic {
                control1X: ribbon.leftX + 2
                control1Y: ribbon.height * 0.12
                control2X: ribbon.leftX + ribbon.bendX + 2
                control2Y: ribbon.height * 0.20
                x: ribbon.leftX + ribbon.bendX + 2
                y: ribbon.elbowY
            }
            PathLine { x: ribbon.leftX + ribbon.bendX + 2; y: ribbon.cornerY - 6 }
        }

        Text {
            anchors.centerIn: parent
            text: book.title
            textFormat: Text.PlainText
            color: book.ribbonTextColor
            font.family: book.titleFont
            font.pixelSize: 11
            rotation: 90
            opacity: 1 - Math.min(1, book.ribbonBend * 3.5)
        }
    }

    // Small count mark only appears for apps with multiple windows.
    Text {
        visible: book.windowCount > 1
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        text: "×" + book.windowCount
        color: book.metalColor
        font.family: "monospace"
        font.pixelSize: 9
        z: 6
    }

    signal contextRequested(string appId)
    HoverHandler { id: hover }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: book.activated(book.appId)
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: book.contextRequested(book.appId)
    }
    Keys.onReturnPressed: book.activated(book.appId)
    Keys.onSpacePressed: book.activated(book.appId)
}
