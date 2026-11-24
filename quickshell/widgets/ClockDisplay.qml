import QtQuick

Row {
    id: clockDisplay

    property color clockColor: "#c6a86c"
    property string currentTime: ""
    property bool colonVisible: true

    property bool useElfish: false
    property int latinSize: 15
    property int elfishSize: 22
    property string elfishFamily: "Elf-ish"

    readonly property int currentFontSize:
        useElfish ? elfishSize : latinSize

    readonly property string currentFontFamily:
        useElfish ? elfishFamily : "monospace"

    spacing: 0

    function updateClock() {
        currentTime = Qt.formatTime(new Date(), "hh:mm")
    }

    Component.onCompleted: updateClock()

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            clockDisplay.updateClock()
            clockDisplay.colonVisible = ! clockDisplay.colonVisible
        }
    }

    Text {
        text: clockDisplay.currentTime.slice(0,2)
        color: clockDisplay.clockColor
        font.family: clockDisplay.currentFontFamily
        font.pixelSize: clockDisplay.currentFontSize
    }

    Text {
        text: ":"
        color: clockDisplay.clockColor
        font.family: clockDisplay.currentFontFamily
        font.pixelSize: clockDisplay.currentFontSize

        opacity: clockDisplay.colonVisible ? 1 : 0

        Behavior on opacity {
            NumberAnimation{
                duration: 300
                easing.type: Easing.InOutSine
            }
        }
    }

    Text {
        text: clockDisplay.currentTime.slice(3,5)
        color: clockDisplay.clockColor
        font.family: clockDisplay.currentFontFamily
        font.pixelSize: clockDisplay.currentFontSize
    }
}