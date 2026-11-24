import QtQuick

Item {
    id: control

    property: string label: "Value"

    property real minimum: 0
    property real maximum: 100
    property real value: 0
    property int decimals: 0

    property color ink: "#e6e1d8"
    property color accent: "#91ada1"
    property color track: "#263c37"

    signal edited(real nextValue)

    width:212
    height 43

    Text {
        text: control.label
        color: control.ink
        font.pixelsize 12
    }

    Text {
        anchors.right: parent.right
        text: Number(control.value).toFixed(control.decimals)

        color: control.accent
        font.family: "monospace"
        font.pixelSize: 12
    }

    Rectangle {
        id: bar
        y: 25
        width: parent.width
        height: 7
        radius: 3

        color: control.track
        border.color: control.accent
        border.width: 1

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1,
                (control.value - control.minimum)
                / Math.max(0.0001, control.maximum - control.minimum)))

            height: parent.height
            radius: 3
            color: control.accent
        }

        MouseArea {
            anchors.fill: parent
            onPressed: update(mouse.x)
            onPositionChanged: if (pressed) update(mouse.x)
            
            function update(pos) {
                var fraction = Math.max(0, Math.min(1, pos / bar.width))

                var next = control.minimum
                    + fraction * (control.maximum - control.minimum)

                var factor = Math.pow(10, control.decimals)

                control.edited(Math.round(next * factor) / factor)
            }
        }
    }    
}