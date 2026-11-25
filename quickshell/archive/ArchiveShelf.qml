import QtQuick
import "ArchiveView.mjs" as View
// Empty general-purpose support board. Future B7 delegates use supportY,
// not arbitrary per-object offsets. Not the desktop application shelf.
Item {
    id: board
    required property var module
    required property var colors
    property bool selected: false
    property bool browse: true
    signal activated(string moduleId)
    objectName: "shelf-"+module.id
    x:module.x;y:module.y;width:module.w;height:module.h
    readonly property real supportY: 0
    Rectangle {
        anchors.fill:parent
        color:View.shelfColor(board.module,board.colors)
        border.color:board.selected?board.colors.engraving:board.colors.metal
        border.width:board.selected?2:1
        Rectangle {x:1;y:1;width:Math.max(0,parent.width-2);height:1;color:board.colors.engraving;opacity:.7}
        Rectangle {x:4;y:parent.height-4;width:Math.max(0,parent.width-8);height:1;color:board.colors.metal;opacity:.65}
    }
    MouseArea {
        anchors.fill:parent
        enabled:!board.browse
        cursorShape:Qt.PointingHandCursor
        onClicked:board.activated(board.module.id)
    }
}
