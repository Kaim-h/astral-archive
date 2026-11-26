import QtQuick
import QtQuick.Window
import "ArchiveView.mjs" as View

// Isolated atlas. Room edits emit proposals; no arrangement writes here.
// Camera and gesture previews are transient; final cartography follows.
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
    property bool arranging:false
    property bool snapEnabled:false
    property bool showGrid:false
    property int snapDistance:20
    property bool magnetic:true
    property var proposalCommand:null
    property bool proposalValid:false
    property var gesture:null
    property var dragPatch:null
    readonly property bool dragging:!!gesture
    readonly property bool panning:!!press&&moved
    readonly property var dataModel:atlasEnabled?View.mapPlan(snapshot):null
    property var creationBounds:null
    readonly property var camera:creationBounds?View.mapFrame({bounds:creationBounds},width,height,1):View.mapFrame(dataModel,width,height,zoom,center)
    onProposalCommandChanged:{
        if(!proposalCommand||proposalCommand.kind!=="spatialRoomCreate"){creationBounds=null;return}
        if(!creationBounds&&dataModel){
            var r=View.mapRoomOutline(snapshot,proposalCommand),b=dataModel.bounds
            if(r){var x=Math.min(b.x,r.x),y=Math.min(b.y,r.y);creationBounds={x:x,y:y,w:Math.max(b.x+b.w,r.x+r.w)-x,h:Math.max(b.y+b.h,r.y+r.h)-y}}
        }
    }
    signal enterRoom(string id)
    signal addRoom()
    signal editRoom(string id,var patch)
    signal deleteRoom(string id)
    signal toggleGrid()
    signal toggleSnap()
    signal cycleSnapDistance()
    readonly property var selectedBox:dataModel&&selectedRoom?dataModel.rooms.find(r=>r.id===selectedRoom)||null:null
    readonly property var outline:gesture&&dragPatch?View.mapRoomOutline(snapshot,{kind:"spatialRoomEdit",roomId:gesture.data.id,patch:dragPatch}):View.mapRoomOutline(snapshot,proposalCommand)
    function cancelGesture(){gesture=null;dragPatch=null;press=null;moved=false}
    function startGesture(id,kind,x,y){
        if(!arranging||!enabled||gesture)return false
        var g=View.mapRoomGesture(dataModel,id,kind,camera,x,y);if(!g)return false
        selectedRoom=id;forceActiveFocus();gesture={data:g,x:x,y:y,snap:snapEnabled,interval:snapDistance,magnet:magnetic};dragPatch=null;return true
    }
    function updateGesture(x,y){
        if(!gesture)return
        var g=gesture;if(!dragPatch&&Math.hypot(x-g.x,y-g.y)<4)return
        dragPatch=View.mapRoomGesturePatch(g.data,x,y,g.snap,g.interval,g.magnet)
    }
    function finishGesture(x,y){
        if(!gesture)return
        updateGesture(x,y);var g=gesture,p=dragPatch;cancelGesture()
        if(p&&Object.keys(p).length)editRoom(g.data.id,p)
    }
    function pointFor(x,y){return camera?Qt.point(camera.x+x*camera.scale,camera.y+y*camera.scale):Qt.point(-1,-1)}
    function hit(x,y){var p=View.mapAt(camera,x,y);return p?View.mapRoomHit(dataModel,p.x,p.y):""}
    function fit(){if(dragging)return;press=null;center=null;zoom=1}
    function resetView(){cancelGesture();creationBounds=null;fit();selectedRoom=""}
    function zoomAt(value,x,y){
        if(dragging||!camera||!Number.isFinite(value))return
        var anchor=View.mapAt(camera,x,y),next=Math.max(.25,Math.min(8,value))
        var frame=View.mapFrame(dataModel,width,height,next,center)
        if(!frame)return
        center={x:anchor.x-(x-width/2)/frame.scale,y:anchor.y-(y-height/2)/frame.scale}
        zoom=next
    }
    onDataModelChanged:{cancelGesture();if(!dataModel||!dataModel.rooms.some(r=>r.id===selectedRoom))selectedRoom=""}
    onVisibleChanged:if(!visible)cancelGesture()
    onWidthChanged:cancelGesture()
    onHeightChanged:cancelGesture()
    onEnabledChanged:if(!enabled)cancelGesture()
    onArrangingChanged:cancelGesture()
    onActiveFocusChanged:if(!activeFocus)cancelGesture()
    Connections {target:map.Window.window;function onActiveChanged(){if(map.Window.window&&!map.Window.window.active)map.cancelGesture()}}
    Keys.onEscapePressed:function(event){if(gesture||press){cancelGesture();event.accepted=true}}
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
            function onOutlineChanged(){art.refresh()}
            function onProposalValidChanged(){art.refresh()}
            function onShowGridChanged(){art.refresh()}
            function onSnapDistanceChanged(){art.refresh()}
        }
        onAvailableChanged:refresh()
        onVisibleChanged:refresh()
        onPaint:{
            if(!visible)return
            var ctx=getContext("2d");ctx.reset();ctx.clearRect(0,0,width,height)
            var m=map.dataModel,f=map.camera;if(!m||!f)return
            var k=f.scale
            ctx.save();ctx.translate(f.x,f.y);ctx.scale(k,k)
            // Grid is drawn over Room fills, under labels and openings.
            for(var room of m.rooms){ctx.fillStyle=map.colors.panel;ctx.fillRect(room.x,room.y,room.w,room.h)}
            if(map.showGrid){
                var step=Math.max(5,map.snapDistance)
                while(step*k<12)step*=2
                var left=-f.x/k,top=-f.y/k,right=left+width/k,bottom=top+height/k
                ctx.beginPath();for(var gx=Math.ceil(left/step)*step;gx<=right;gx+=step){ctx.moveTo(gx,top);ctx.lineTo(gx,bottom)}
                for(var gy=Math.ceil(top/step)*step;gy<=bottom;gy+=step){ctx.moveTo(left,gy);ctx.lineTo(right,gy)}
                ctx.strokeStyle=map.colors.metal;ctx.lineWidth=.5/k;ctx.stroke()
            }
            for(var r of m.rooms){
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
            var ghost=map.outline
            if(ghost){ctx.strokeStyle=map.dragging||map.proposalValid?map.colors.engraving:"#df8585";ctx.lineWidth=2/k;ctx.strokeRect(ghost.x,ghost.y,ghost.w,ghost.h)}
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
            if(map.arranging&&mouse.button===Qt.LeftButton){var id=map.hit(mouse.x,mouse.y);map.selectedRoom=id;if(id)map.startGesture(id,"move",mouse.x,mouse.y);return}
            map.press={x:mouse.x,y:mouse.y,cx:map.camera.cx,cy:map.camera.cy,scale:map.camera.scale}
        }
        onPositionChanged:function(mouse){
            if(map.gesture){map.updateGesture(mouse.x,mouse.y);return}
            if(!pressed||!map.press)return
            var p=map.press,dx=mouse.x-p.x,dy=mouse.y-p.y
            if(!map.moved&&Math.hypot(dx,dy)<4)return
            map.moved=true;map.center={x:p.cx-dx/p.scale,y:p.cy-dy/p.scale}
        }
        onReleased:function(mouse){if(map.gesture)map.finishGesture(mouse.x,mouse.y);else map.press=null}
        onCanceled:map.cancelGesture()
        onClicked:function(mouse){if(!map.arranging&&mouse.button===Qt.LeftButton&&!map.moved)map.selectedRoom=map.hit(mouse.x,mouse.y)}
        onDoubleClicked:function(mouse){
            if(map.arranging||mouse.button!==Qt.LeftButton||map.moved)return
            var id=map.hit(mouse.x,mouse.y)
            if(id){map.selectedRoom=id;map.enterRoom(id)}
        }
        onWheel:function(wheel){if(!map.press&&!map.dragging){map.zoomAt(map.zoom*Math.pow(1.15,wheel.angleDelta.y/120),wheel.x,wheel.y)}wheel.accepted=true}
    }
    Rectangle {
        id:resizeHandle;objectName:"map-room-resize-handle";width:22;height:22;radius:3
        visible:map.arranging&&!!map.selectedBox&&!map.proposalCommand
        readonly property point corner:map.selectedBox?map.pointFor(map.selectedBox.x+map.selectedBox.w,map.selectedBox.y+map.selectedBox.h):Qt.point(0,0)
        x:corner.x-width/2;y:corner.y-height/2;color:map.colors.background;border.color:map.colors.engraving;border.width:2
        MouseArea {
            anchors.fill:parent;cursorShape:Qt.SizeFDiagCursor
            function local(mouse){return resizeHandle.mapToItem(map,mouse.x,mouse.y)}
            onPressed:function(mouse){var p=local(mouse);map.startGesture(map.selectedRoom,"resize",p.x,p.y)}
            onPositionChanged:function(mouse){if(pressed){var p=local(mouse);map.updateGesture(p.x,p.y)}}
            onReleased:function(mouse){var p=local(mouse);map.finishGesture(p.x,p.y)}
            onCanceled:map.cancelGesture()
        }
    }
    Text {
        anchors.top:parent.top;anchors.topMargin:8;anchors.horizontalCenter:parent.horizontalCenter
        text:"The Map Room";color:map.colors.text;font.pixelSize:16
    }
    // Explicit, non-overlapping hit rectangles. Do not reposition the
    // navigation row when Arrange reveals its additional controls.
    Item {
        id:mapControls
        objectName:"map-controls"
        anchors.bottom:parent.bottom;anchors.bottomMargin:8
        anchors.horizontalCenter:parent.horizontalCenter
        width:336;height:86
        enabled:!map.dragging&&!map.panning
        Item {
            objectName:"map-arrange-actions"
            width:parent.width;height:26;y:0;visible:map.arranging;enabled:map.arranging
            ArchiveButton {objectName:"map-add-room";colors:map.colors;label:"Add Room";x:0;width:108;onClicked:map.addRoom()}
            ArchiveButton {objectName:"map-edit-room";colors:map.colors;label:"Dimensions…";x:114;width:108;enabled:!!map.selectedBox;onClicked:map.editRoom(map.selectedRoom,{})}
            ArchiveButton {objectName:"map-delete-room";colors:map.colors;label:"Remove Room";x:228;width:108;enabled:!!map.selectedBox&&!map.selectedBox.shelves.length;onClicked:map.deleteRoom(map.selectedRoom)}
        }
        Item {
            objectName:"map-arrange-grid-actions"
            width:parent.width;height:26;y:30;visible:map.arranging;enabled:map.arranging
            ArchiveButton {objectName:"map-grid";colors:map.colors;label:"Grid";x:0;width:108;active:map.showGrid;onClicked:map.toggleGrid()}
            ArchiveButton {objectName:"map-snap";colors:map.colors;label:"Snap";x:114;width:55;active:map.snapEnabled;onClicked:map.toggleSnap()}
            ArchiveButton {objectName:"map-snap-interval";colors:map.colors;label:String(map.snapDistance);hint:"Cycle snap and grid interval";x:175;width:47;onClicked:map.cycleSnapDistance()}
            ArchiveButton {objectName:"map-magnetic";colors:map.colors;label:"Wall magnet";x:228;width:108;active:map.magnetic;onClicked:map.magnetic=!map.magnetic}
        }
        Item {
            objectName:"map-navigation-actions"
            width:parent.width;height:26;y:60
            ArchiveButton {objectName:"map-fit";colors:map.colors;label:"Fit map";x:0;width:74;onClicked:map.fit()}
            ArchiveButton {objectName:"map-zoom-out";colors:map.colors;label:"−";x:80;width:36;onClicked:map.zoomAt(map.zoom/1.15,map.width/2,map.height/2)}
            ArchiveButton {objectName:"map-zoom-in";colors:map.colors;label:"+";x:122;width:36;onClicked:map.zoomAt(map.zoom*1.15,map.width/2,map.height/2)}
            ArchiveButton {objectName:"map-enter-room";colors:map.colors;label:"Enter selected Room";x:164;width:172;enabled:!!map.selectedRoom&&!map.arranging;onClicked:map.enterRoom(map.selectedRoom)}
        }
    }
}
