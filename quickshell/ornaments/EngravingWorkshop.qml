import QtQuick
import "Presets.js" as Presets

Rectangle {
    id: workshop
    width: 1000
    height: 840
    color: palette.background

    property var palette: ({
        background: "#121e23", panel: "#263c37",
        metal: "#8c6e5a", engraving: "#91ada1", text: "#e6e1d8"
    })

    property string surfaceType: "book"
    property int surfaceWidth: 42
    property int surfaceHeight: 150
    property int fontSize: 5

    property real letterSpacing: 0
    property real lineHeight: 1.0
    property real ornamentOpacity
    property real ornamentRotation

    property int ornamentX: 4
    property int ornamentY: 4

    property string fontFamily: "monospace"
    property bool useThemeColor: true
    property color customColor: "#c2aa78"
    property int zoom: 3

    readonly property color ornamentColor:
        useThemeColor ? palette.engraving : customColor

    readonly property var design: ({
        pattern: patternEdit.text,
        fontFamily: fontFamily,
        fontSize: fontSize,
        letterSpacing: letterSpacing,
        lineHeight: lineHeight,
        useThemeColor: useThemeColor,
        color: ornamentColor.toString(),
        opacity: ornamentOpacity,
        rotation: ornamentRotation,
        x: ornamentX,
        y: ornamentY
    })

    signal applyRequested(var design, string target)

    function setTarget(target) {
        surfaceType = target
        if (target === "book") { surfaceWidth = 42; surfaceHeight = 150 }
        else if (target === "shelf") { surfaceWidth = 240; surfaceHeight = 28 }
        else { surfaceWidth = 210; surfaceHeight = 180 }
        ornamentX = 4
        ornamentY = 4
    }

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        Text {
            text: "Engraving Workshop"
            color: workshop.palette.engraving
            font.pixelSize: 22
            font.letterSpacing: 2
        }

        Row {
            spacing: 8

            Repeater {
                model: ["book", "shelf", "observatory"]

                Rectangle {
                    required property string modelData
                    width: 126
                    height: 30
                    radius: 4

                    color: workshop.surfaceType === modelData
                        ? workshop.palette.metal : workshop.palette.panel

                    border.color: workshop.palette.metal

                    Text {
                        anchors.centerIn: parent
                        text: modelData.toUpperCase()
                        color: workshop.surfaceType === modelData
                            ? workshop.palette.background : workshop.palette.text

                        font.pixelSize: 11
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: workshop.setTarget(modelData)
                    }
                }
            }
        }
    }

    Row {
        spacing: 20
        
        Column {
            spacing: 8
            width: 440

            Text {
                text: "Pattern: ASCII or Unicode"
                color: workshop.palette.text
                font.pixelSize: 12
            }

            Rectangle {
                width: 440
                height: 205
                clip: true

                color: workshop.palette.panel
                border.color: workshop.palette.metal
                radius: 6

                Flickable {
                    anchors.fill: parent
                    anchors.margins:12
                    clip: true

                    contentWidth: Math.max(width, patternEdit.contentWidth)
                    contentHeight: Math.max(height, patternEdit.contentHeight)

                    TextEdit {
                        id: patternEdit

                        width: Math.max(parent.width, contentWidth)
                        height: Math.max(parent.height, contentHeight)

                        text: " .-^-.-.\n(  *  )\n `---'"

                        color: workshop.palette.text
                        font.family: "monospace"
                        font.pixelSize: 15
                        wrapMode: TextEdit.NoWrap
                        selectByMouse: true
                        focus: true
                    }
                }
            }

            Text {
                text: "Presets"
                color: workshop.palette.text
                font.pixelSize: 12
            }

            Flow {
                width: 440
                spacing: 6

                Repeater {
                    model: Presets.motifs

                    Rectangle {
                        required property var modelData
                        width: 100
                        height: 30
                        radius: 4

                        color: workshop.palette.panel
                        border.color: workshop.palette.metal

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name
                            color: workshop.palette.text
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked {
                                patternEdit.text = modelData.pattern
                            }
                        }
                    }
                }
            }

            Row {
                spacing: 8

                Text {
                    text: "Font: "+ workshop.fontFamily
                    color: workshop.palette.text
                    font.pixelSize: 12
                }

                Rectangle {
                    width: 132
                    height: 26

                    color: workshop.palette.panel
                    border.color: workshop.palette.metal

                    Text {
                        anchors.centerIn: parent
                        text: "Toggle Font"
                        color: workshop.palette.text
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked{
                            workshop.fontFamily =
                            workshop.fontFamily === "monospace" ? "Elf-ish" : "monospace"
                        }
                    }
                }

                Row {
                    spacing: 8

                    Text {
                        text: "Ink"
                        color: workshop.palette.text
                        font.pixelSize: 12
                    }

                    Repeater {
                        model: ["theme", "#c2aa78", "#b7a2c8", "#e6e1d8", "#568f80"]

                        Rectangle {
                            required property string modelData

                            width: 42
                            height: 24
                            radius: 3
                            color: (modelData === "theme")
                                ? workshop.palette.engraving : modelData

                            border.width: 2
                            border.color: (modelData === "theme" && workshop.useThemeColor)
                                || (!workshop.useThemeColor && workshop.customColor.toString() === modelData)
                                ? "#ffffff" : workshop.palette.metal
                            
                            Text {
                                anchors.centerIn: parent
                                visible: modelData === "theme"
                                text: "T"
                                color: workshop.palette.background
                                font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData === "theme") workshop.useThemeColor = true
                                    else {
                                        workshop.useThemeColor = false
                                        workshop.customColor = modelData
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Column {
                width: 490
                spacing : 8

                Text {
                    text: "Magnified Surface"
                    color: workshop.palette.text
                    font.pixelSize: 12
                }

                Rectangle {
                    width: 490
                    height:244
                    radius: 6
                    clip: true

                    color: workshop.palette.panel
                    border.color: workshop.palette.metal

                    OrnamentCanvas {
                        anchors.centerIn: parent
                        scale: workshop.zoom

                        surfaceType: workshop.surfaceType
                        surfaceWidth: workshop.surfaceWidth
                        surfaceHeight: workshop.surfaceHeight

                        palette: workshop.palette
                        design: workshop.design
                    }
                }

                Text {
                    text: "Actual Size / 1:1"
                    color: workshop.palette.text
                    font.pixelSize: 12
                }

                Rectangle {
                    width: 490
                    height:205
                    clip: true

                    color: workshop.palette.panel
                    border.color: workshop.palette.metal

                    OrnamentCanvas {
                        anchors.centerIn: parent

                        surfaceType: workshop.surfaceType
                        surfaceWidth: workshop.surfaceWidth
                        surfaceHeight: workshop.surfaceHeight

                        palette: workshop.palette
                        design: workshop.design
                    }
                }
            }
        }

        Grid {
            columns: 4
            columnSpacing: 23
            rowSpacing: 4

            ValueSlider {
                label: "Font size (px)"
                minimum: 3
                maximum: 20
                value: workshop.fontSize
                accent: workshop.palette.engraving
                ink: workshop.palette.text
                onEdited: v => workshop.fontSize = v 
            }

            ValueSlider {
                label: "Letter spacing"
                minimum: -1
                maximum: 3
                decimals: 1
                value: workshop.letterSpacing
                accent: workshop.palette.engraving
                ink: workshop.palette.text
                onEdited: v => workshop.letterSpacing = v 
            }
            
            ValueSlider {
                label: "Line height"
                minimum: 0.7
                maximum: 1.6
                decimals: 2
                value: workshop.lineHeight
                accent: workshop.palette.engraving
                ink: workshop.palette.text
                onEdited: v => workshop.lineHeight = v
            }
            ValueSlider {
                label: "Opacity"
                minimum: 0; maximum: 1
                decimals: 2
                value: workshop.ornamentOpacity
                accent: workshop.palette.engraving
                ink: workshop.palette.text
                onEdited: v => workshop.ornamentOpacity = v
            }

            ValueSlider {
                label: "X offset"
                minimum: -40
                maximum: 240
                value: workshop.ornamentX
                accent: workshop.palette.engraving
                ink: workshop.palette.text
                onEdited: v => workshop.ornamentX = v
            }
            
            ValueSlider {
                label: "Y offset"
                minimum: -40
                maximum: 180
                value: workshop.ornamentY
                accent: workshop.palette.engraving
                ink: workshop.palette.text
                onEdited: v => workshop.ornamentY = v
            }

            ValueSlider {
                label: "Rotation"
                minimum: -180
                maximum: 180
                value: workshop.ornamentRotation
                accent: workshop.palette.engraving
                ink: workshop.palette.text
                onEdited: v => workshop.ornamentRotation = v
            }

            ValueSlider {
                label: "Preview zoom"\
                minimum: 1
                maximum: 5
                value: workshop.zoom
                accent: workshop.palette.engraving
                ink: workshop.palette.text
                onEdited: v => workshop.zoom = v
            }

            ValueSlider {
                label: "Object width"
                minimum: 30
                maximum: 400
                value: workshop.surfaceWidth
                accent: workshop.palette.engraving
                ink: workshop.palette.text
                onEdited: v => workshop.surfaceWidth = v
            }

            ValueSlider {
                label: "Object height"
                minimum: 12
                maximum: 280
                value: workshop.surfaceHeight
                accent: workshop.palette.engraving
                ink: workshop.palette.text
                onEdited: v => workshop.surfaceHeight = v
            }
        }

        Row {
            spacing: 12

            Rectangle {
                width: 154
                height: 31
                radius: 4
                color: workshop.palette.metal

                Text {
                    anchors.centerIn: parent
                    text: "Apply Design"
                    color: workshop.palette.background
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: workshop.applyRequested(workshop.design, workshop.surfaceType)
                }
            }

            Text {
                text: "Apply emits data; saving and system-wide changes come later."
                color: workshop.palette.text
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}

    