import QtQuick

// Illustrated, input-neutral percentage slider. Emits ONE change on release,
// so dragging doesn't spawn dozens of brightnessctl processes.
Item {
    id: slider
    property int value: 0
    property bool interactive: true
    property color trackColor: "#121e23"
    property color fillColor: "#8c6e5a"
    property color outlineColor: "#91ada1"
    property color textColor: "#e6e1d8"
    signal valueCommitted(int percent)

    property bool dragging: false
    property int draftValue: value
    readonly property int shownValue: dragging ? draftValue : value

    implicitWidth: 218
    implicitHeight: 34
    opacity: interactive ? 1 : 0.43

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 12
        radius: 3
        color: slider.trackColor
        border.color: slider.outlineColor
        border.width: 1
        Rectangle {
            x: 2; y: 2
            width: Math.max(0, (parent.width - 4) * slider.shownValue / 100)
            height: parent.height - 4
            radius: 2
            color: slider.fillColor
        }
        Repeater {
            model: 9
            Rectangle {
                required property int index
                x: (index + 1) * (parent.width / 10)
                y: 3
                width: 1
                height: 6
                color: slider.textColor
                opacity: 0.27
            }
        }
    }
    Rectangle {
        width: 11
        height: 22
        radius: 2
        x: Math.max(0, Math.min(parent.width - width,
            parent.width * slider.shownValue / 100 - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        color: slider.fillColor
        border.color: slider.textColor
        border.width: 1
    }
    MouseArea {
        anchors.fill: parent
        enabled: slider.interactive
        cursorShape: Qt.PointingHandCursor
        function positionToValue(x) {
            return Math.max(0, Math.min(100, Math.round(x / Math.max(1, width) * 100)));
        }
        onPressed: function(mouse) {
            slider.dragging = true;
            slider.draftValue = positionToValue(mouse.x);
        }
        onPositionChanged: function(mouse) {
            if (pressed) slider.draftValue = positionToValue(mouse.x);
        }
        onReleased: function(mouse) {
            if (!slider.dragging) return;
            slider.draftValue = positionToValue(mouse.x);
            slider.dragging = false;
            slider.valueCommitted(slider.draftValue);
        }
        onCanceled: slider.dragging = false
    }
}
