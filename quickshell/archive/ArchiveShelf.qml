import QtQuick
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
    // Observable paint passes for bounded offscreen idle regression.
    property int paintPasses:0
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
        Loader {
            anchors.fill:parent;active:board.spatialStyle
            sourceComponent:Component {
        Canvas {
            id:lip
            anchors.fill:parent
            readonly property color strokeColor:board.selected?board.colors.engraving:board.colors.metal
            // Software-compatible, event-driven paint. No animation, timer or
            // recurring work while idle. Legacy invisible faces do not paint.
            onWidthChanged:if(flatFace.visible)requestPaint()
            onHeightChanged:if(flatFace.visible)requestPaint()
            onStrokeColorChanged:if(flatFace.visible)requestPaint()
            onAvailableChanged:if(available&&flatFace.visible)requestPaint()
            Connections {
                target:flatFace
                function onFillColorChanged(){if(flatFace.visible)lip.requestPaint()}
                function onVisibleChanged(){if(flatFace.visible)lip.requestPaint()}
            }
            onPaint:{
                if(!flatFace.visible||width<2||height<2)return
                board.paintPasses++
                var ctx=getContext("2d"),w=width,h=height,t=flatFace.cornerTop,b=flatFace.cornerBottom
                ctx.clearRect(0,0,w,h)
                ctx.beginPath();ctx.moveTo(t+.5,.5)
                ctx.lineTo(w-t-.5,.5);ctx.quadraticCurveTo(w-.5,.5,w-.5,t+.5)
                ctx.lineTo(w-.5,h-b-.5);ctx.quadraticCurveTo(w-.5,h-.5,w-b-.5,h-.5)
                ctx.lineTo(b+.5,h-.5);ctx.quadraticCurveTo(.5,h-.5,.5,h-b-.5)
                ctx.lineTo(.5,t+.5);ctx.quadraticCurveTo(.5,.5,t+.5,.5)
                ctx.closePath();ctx.fillStyle=flatFace.fillColor;ctx.fill()
                ctx.strokeStyle=strokeColor;ctx.lineWidth=1;ctx.stroke()
            }
        }
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
