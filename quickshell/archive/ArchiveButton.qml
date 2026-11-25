import QtQuick
import "ArchiveView.mjs" as View

Rectangle {
    id: control
    required property var colors
    property string label: ""
    property bool active: false
    property string hint: ""
    signal clicked()
    implicitWidth: Math.max(28,caption.implicitWidth+16)
    implicitHeight: 26
    width: implicitWidth
    height: implicitHeight
    radius: 5
    color: active?View.mix(colors.panel,colors.engraving,.24):View.mix(colors.background,colors.panel,.74)
    border.color: active?colors.engraving:View.mix(colors.panel,colors.metal,.55)
    opacity: enabled?1:.45
    activeFocusOnTab: enabled
    Accessible.role: Accessible.Button
    Accessible.name: hint||label
    Accessible.onPressAction: if (enabled) clicked()
    Keys.onSpacePressed: if (enabled) clicked()
    Keys.onReturnPressed: if (enabled) clicked()
    Text {
        id: caption
        anchors.centerIn: parent
        color: control.colors.text
        text: control.label
        font.pixelSize: 11
    }
    MouseArea {
        anchors.fill: parent
        enabled: control.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: control.clicked()
    }
}
