import QtQuick
import "ArchiveView.mjs" as View

// N4a isolated functional atlas. No arrangement writes, contour or final
// zoom-LOD treatment yet. Camera and selection are transient view state.
Item {
    id:map
    required property var snapshot
    required property var colors
    property bool atlasEnabled:false
    property string selectedRoom:""
    property real zoom:1
    property var center:null
    property var press:null
    property bool moved:false
    readonly property bool panning:!!press&&moved
    readonly property var dataModel:atlasEnabled?View.mapPlan(snapshot):null
    readonly property var camera:View.mapFrame(dataModel,width,height,zoom,center)
    signal enterRoom(string id)
    function pointFor(x,y){return camera?Qt.point(camera.x+x*camera.scale,camera.y+y*camera.scale):Qt.point(-1,-1)}
    function hit(x,y){var p=View.mapAt(camera,x,y);return p?View.mapRoomHit(dataModel,p.x,p.y):""}
    function fit(){press=null;center=null;zoom=1}
    function resetView(){fit();selectedRoom=""}
    function zoomAt(value,x,y){
        if(!camera||!Number.isFinite(value))return
        var anchor=View.mapAt(camera,x,y),next=Math.max(.25,Math.min(8,value))
        var frame=View.mapFrame(dataModel,width,height,next,center)
        if(!frame)return
        center={x:anchor.x-(x-width/2)/frame.scale,y:anchor.y-(y-height/2)/frame.scale}
        zoom=next
    }
    onDataModelChanged:{press=null;if(!dataModel||!dataModel.rooms.some(r=>r.id===selectedRoom))selectedRoom=""}
    onVisibleChanged:if(!visible)press=null
    onWidthChanged:press=null
    onHeightChanged:press=null
    onEnabledChanged:if(!enabled)press=null
    Rectangle {anchors.fill:parent;color:map.colors.background}
    Canvas {
        id:art
        objectName:"map-room-art"
        anchors.fill:parent
        function refresh(){if(visible&&available)requestPaint()}
        Connections {
            target:map
            function onDataModelChanged(){art.refresh()}
            function onCameraChanged(){art.refresh()}
            function onColorsChanged(){art.refresh()}
            function onSelectedRoomChanged(){art.refresh()}
        }
        onAvailableChanged:refresh()
        onVisibleChanged:refresh()
        onPaint:{
            if(!visible)return
            var ctx=getContext("2d");ctx.reset();ctx.clearRect(0,0,width,height)
            var m=map.dataModel,f=map.camera;if(!m||!f)return
            var k=f.scale
            ctx.save();ctx.translate(f.x,f.y);ctx.scale(k,k)
            for(var r of m.rooms){
                ctx.fillStyle=map.colors.panel;ctx.fillRect(r.x,r.y,r.w,r.h)
                ctx.strokeStyle=map.selectedRoom===r.id?map.colors.text:map.colors.metal
                ctx.lineWidth=(map.selectedRoom===r.id?2:1.5)/k;ctx.strokeRect(r.x,r.y,r.w,r.h)
                for(var s of r.shelves){
                    var b=s.box
                    ctx.fillStyle=map.colors.background;ctx.fillRect(b.x,b.y,b.w,b.h)
                    ctx.strokeStyle=map.colors.engraving;ctx.lineWidth=.8/k;ctx.strokeRect(b.x,b.y,b.w,b.h)
                }
            }
            // Openings use the exact shared world interval, not an inferred
            // proximity or separate copy for each Room.
            for(var door of m.doors){
                ctx.beginPath()
                if(door.vertical){ctx.moveTo(door.line,door.start);ctx.lineTo(door.line,door.end)}
                else{ctx.moveTo(door.start,door.line);ctx.lineTo(door.end,door.line)}
                ctx.strokeStyle=map.colors.panel;ctx.lineWidth=4/k;ctx.stroke()
                ctx.strokeStyle=map.colors.engraving;ctx.lineWidth=1/k;ctx.stroke()
            }
            ctx.restore()
        }
    }
    Repeater {
        model:map.visible&&map.dataModel?map.dataModel.rooms:[]
        Text {
            required property var modelData
            readonly property point origin:map.pointFor(modelData.x,modelData.y)
            x:origin.x;y:origin.y
            width:map.camera?modelData.w*map.camera.scale:0
            height:map.camera?modelData.h*map.camera.scale:0
            visible:width>=44&&height>=16
            color:map.colors.text;text:modelData.name
            font.pixelSize:Math.max(1,Math.min(14,height*.28))
            horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter
            elide:Text.ElideRight;clip:true
        }
    }
    MouseArea {
        anchors.fill:parent;acceptedButtons:Qt.LeftButton|Qt.MiddleButton
        onPressed:function(mouse){
            if(!map.camera)return
            map.forceActiveFocus();map.moved=false
            map.press={x:mouse.x,y:mouse.y,cx:map.camera.cx,cy:map.camera.cy,scale:map.camera.scale}
        }
        onPositionChanged:function(mouse){
            if(!pressed||!map.press)return
            var p=map.press,dx=mouse.x-p.x,dy=mouse.y-p.y
            if(!map.moved&&Math.hypot(dx,dy)<4)return
            map.moved=true;map.center={x:p.cx-dx/p.scale,y:p.cy-dy/p.scale}
        }
        onReleased:map.press=null
        onCanceled:{map.press=null;map.moved=false}
        onClicked:function(mouse){if(mouse.button===Qt.LeftButton&&!map.moved)map.selectedRoom=map.hit(mouse.x,mouse.y)}
        onDoubleClicked:function(mouse){
            if(mouse.button!==Qt.LeftButton||map.moved)return
            var id=map.hit(mouse.x,mouse.y)
            if(id){map.selectedRoom=id;map.enterRoom(id)}
        }
        onWheel:function(wheel){if(!map.press){map.zoomAt(map.zoom*Math.pow(1.15,wheel.angleDelta.y/120),wheel.x,wheel.y)}wheel.accepted=true}
    }
    Text {
        anchors.top:parent.top;anchors.topMargin:8;anchors.horizontalCenter:parent.horizontalCenter
        text:"The Map Room";color:map.colors.text;font.pixelSize:16
    }
    Row {
        anchors.bottom:parent.bottom;anchors.bottomMargin:8;anchors.horizontalCenter:parent.horizontalCenter;spacing:6
        ArchiveButton {objectName:"map-fit";colors:map.colors;label:"Fit map";onClicked:map.fit()}
        ArchiveButton {objectName:"map-zoom-out";colors:map.colors;label:"−";onClicked:map.zoomAt(map.zoom/1.15,map.width/2,map.height/2)}
        ArchiveButton {objectName:"map-zoom-in";colors:map.colors;label:"+";onClicked:map.zoomAt(map.zoom*1.15,map.width/2,map.height/2)}
        ArchiveButton {objectName:"map-enter-room";colors:map.colors;label:"Enter selected Room";enabled:!!map.selectedRoom;onClicked:map.enterRoom(map.selectedRoom)}
    }
}
