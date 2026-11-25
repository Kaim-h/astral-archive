import QtQuick
import "ArchiveView.mjs" as View

// Exact B6r12b3 circular endpoint illustration at a bounded 2x resolution.
// The physical item remains exactly 2r wide. The small margin only allows
// the SVG-equivalent hairline and antialiasing to reach outside the radius.
Item {
    id:end
    required property var record
    required property var colors
    property real visualRadius:record.r
    property bool selected:false
    property bool provisional:false
    readonly property color ink:View.mix("#826d55",colors.engraving,.16)
    width:2*visualRadius;height:width
    objectName:"scroll-"+record.id
    opacity:provisional ? .85 : 1
    Canvas {
        id:art
        x:-1;y:-1
        width:(end.width+2)*2;height:width
        scale:.5;transformOrigin:Item.TopLeft
        antialiasing:true;smooth:true
        function circle(ctx,c,r,fill,stroke,line,alpha){
            ctx.globalAlpha=alpha
            ctx.beginPath();ctx.arc(c,c,r,0,2*Math.PI)
            if(fill){ctx.fillStyle=fill;ctx.fill()}
            if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=line;ctx.stroke()}
            ctx.globalAlpha=1
        }
        onAvailableChanged:if(available)requestPaint()
        onWidthChanged:requestPaint()
        onPaint:{
            var ctx=getContext("2d"),r=end.visualRadius,c=r+1
            ctx.save();ctx.clearRect(0,0,width,height);ctx.scale(2,2)
            circle(ctx,c,r,View.parchment(end.record),"#8d7659",1,1)
            circle(ctx,c,r*.76,null,end.ink,.7,.6)
            circle(ctx,c,r*.32,null,end.ink,.65,.32)
            circle(ctx,c,Math.max(1.4,r*.12),end.ink,null,0,.65)
            if(r>=10){
                ctx.beginPath();ctx.moveTo(c-r*.5,c-r*.48)
                ctx.quadraticCurveTo(c-r*.93,c,c-r*.44,c+r*.51)
                ctx.lineWidth=.65;ctx.strokeStyle=end.ink;ctx.globalAlpha=.4;ctx.stroke();ctx.globalAlpha=1
            }
            ctx.restore()
        }
        Connections {target:end;function onInkChanged(){art.requestPaint()}function onRecordChanged(){art.requestPaint()}}
    }
    Rectangle {
        visible:end.selected
        anchors.centerIn:parent
        width:parent.width+4;height:width;radius:width/2
        color:"transparent";border.color:end.colors.metal;border.width:1.5
        antialiasing:true
    }
}
