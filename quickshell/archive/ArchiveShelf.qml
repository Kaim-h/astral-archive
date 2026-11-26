import QtQuick
import QtQuick.Shapes
import "ArchiveView.mjs" as View
// Empty general-purpose support board. Future B7 delegates use supportY,
// not arbitrary per-object offsets. Not the desktop application shelf.
Item {
    id: board
    required property var module
    required property var colors
    property bool spatialStyle:false
    property bool selected: false
    property bool browse: true
    signal activated(string moduleId)
    objectName: "shelf-"+module.id
    x:module.x;y:module.y;width:module.w;height:module.h
    readonly property real supportY: 0
    Rectangle {
        visible:!board.spatialStyle
        anchors.fill:parent
        color:View.shelfColor(board.module,board.colors)
        border.color:board.selected?board.colors.engraving:board.colors.metal
        border.width:board.selected?2:1
        Rectangle {x:1;y:1;width:Math.max(0,parent.width-2);height:1;color:board.colors.engraving;opacity:.7}
        Rectangle {x:4;y:parent.height-4;width:Math.max(0,parent.width-8);height:1;color:board.colors.metal;opacity:.65}
    }
    // S18r3 recovered flat Lighting Lab lip. Keep the contact datum at
    // y=0, all paint inside the existing support envelope; no added depth.
    Item {
        id:flatFace
        objectName:"flat-board-face"
        anchors.fill:parent;visible:board.spatialStyle
        readonly property color fillColor:View.shelfColor(board.module,board.colors)
        readonly property real cornerTop:Math.min(2,height/3,width/4)
        readonly property real cornerBottom:Math.min(5,height/3,width/4)
        Shape {
            anchors.fill:parent
            ShapePath {
                strokeColor:board.selected?board.colors.engraving:board.colors.metal
                strokeWidth:1;fillColor:flatFace.fillColor
                startX:flatFace.cornerTop+.5;startY:.5
                PathLine {x:flatFace.width-flatFace.cornerTop-.5;y:.5}
                PathQuad {x:flatFace.width-.5;y:flatFace.cornerTop+.5;controlX:flatFace.width-.5;controlY:.5}
                PathLine {x:flatFace.width-.5;y:flatFace.height-flatFace.cornerBottom-.5}
                PathQuad {x:flatFace.width-flatFace.cornerBottom-.5;y:flatFace.height-.5;controlX:flatFace.width-.5;controlY:flatFace.height-.5}
                PathLine {x:flatFace.cornerBottom+.5;y:flatFace.height-.5}
                PathQuad {x:.5;y:flatFace.height-flatFace.cornerBottom-.5;controlX:.5;controlY:flatFace.height-.5}
                PathLine {x:.5;y:flatFace.cornerTop+.5}
                PathQuad {x:flatFace.cornerTop+.5;y:.5;controlX:.5;controlY:.5}
            }
        }
        readonly property real emblemHalf:Math.min(26,width*.25)
        Rectangle {x:6;y:Math.min(5,parent.height/3);width:Math.max(0,parent.width/2-flatFace.emblemHalf-6);height:1;color:board.colors.engraving;opacity:.55}
        Rectangle {x:parent.width/2+flatFace.emblemHalf;y:Math.min(5,parent.height/3);width:Math.max(0,parent.width-x-6);height:1;color:board.colors.engraving;opacity:.55}
        Text {
            anchors.horizontalCenter:parent.horizontalCenter
            y:Math.max(0,Math.min(3,(parent.height-height)/2))
            text:"◇ · ✧ · ◇";font.family:"monospace";font.pixelSize:7
            color:board.colors.metal
        }
    }
    MouseArea {
        anchors.fill:parent
        enabled:!board.browse
        cursorShape:Qt.PointingHandCursor
        onClicked:board.activated(board.module.id)
    }
}
