import QtQuick
import QtQuick.Window
import "ArchiveView.mjs" as View
import "ArchiveMapTerrain.mjs" as Terrain
import "ArchiveAppearance.mjs" as Appearance

// Isolated atlas. Room edits emit proposals; no arrangement writes here.
// Camera and gesture previews are transient; final cartography follows.
Item {
    id:map
    required property var snapshot
    required property var colors
    property bool atlasEnabled:false
    property var palettes:[]
    property int desktopPalette:0
    property var appearanceProposal:null
    readonly property bool appearanceOpen:!!appearanceProposal
    readonly property bool localAppearance:appearanceOpen&&appearanceProposal.command.kind==="spatialMapRoomAppearance"
    readonly property var chartPolicy:Appearance.mapPolicy(snapshot)
    readonly property var localRoom:localAppearance?snapshot.spatial.rooms[appearanceProposal.command.roomId]:null
    readonly property string chartTitle:chartValue("title")
    readonly property string chartSubtitle:chartValue("subtitle")
    readonly property string chartOrnament:chartValue("ornament")
    readonly property string chartFamily:chartValue("family")
    readonly property string mapFrameStyle:chartValue("frame")
    readonly property string contourMode:chartValue("contours")
    readonly property int contourDensity:chartValue("density")
    signal appearanceRequested(string roomId)
    signal appearanceChanged(string key,var value)
    signal appearanceCloseRequested(bool cancel)
    function chartValue(key){
        var p=appearanceOpen&&!localAppearance?appearanceProposal.command.patch:null
        return p&&Object.prototype.hasOwnProperty.call(p,key)?p[key]:chartPolicy[key]
    }
    function localValue(key){
        if(!localRoom)return null
        var p=appearanceProposal.command.patch
        if(Object.prototype.hasOwnProperty.call(p,key))return p[key]
        var a=key==="name"?localRoom:key==="palette"||key==="family"?localRoom.appearance:localRoom.mapAppearance
        return a&&a[key]!==undefined?a[key]:null
    }
    function choiceItems(values,labels){return values.map((v,i)=>({key:v,label:labels?labels[i]:String(v)}))}
    readonly property int contourBuilds:art.contourBuilds
    readonly property int mapPaints:art.paintCount
    readonly property int contourSegmentCount:art.contourCache?art.contourCache.data.segments:0
    readonly property int contourLastBuildMs:art.lastBuildMs
    readonly property int contourMaxBuildMs:art.maxBuildMs
    readonly property int mapLastPaintMs:art.lastPaintMs
    function roomColors(room){return room.palette!==null&&palettes[room.palette]?palettes[room.palette]:colors}
    function openAppearance(roomId){if(!enabled||!visible||appearanceOpen)return;cancelGesture();appearanceRequested(roomId||"")}
    function closeAppearance(cancel){appearanceCloseRequested(cancel===true);if(!appearanceOpen&&enabled&&visible)forceActiveFocus()}
    onAppearanceOpenChanged:if(appearanceOpen){cancelGesture();chartPanel.forceActiveFocus()}
    property string selectedRoom:""
    property string selectedDoor:""
    property int suggestionIndex:0
    readonly property var selectedOpening:dataModel&&selectedDoor?dataModel.doors.find(d=>d.id===selectedDoor)||null:null
    readonly property var suggestions:visible&&arranging&&!proposalCommand?View.mapDoorSuggestions(snapshot,selectedRoom):[]
    readonly property var suggestedOpening:suggestions.length?suggestions[Math.max(0,Math.min(suggestionIndex,suggestions.length-1))]:null
    readonly property var mergeChoices:visible&&arranging&&selectedDoor?View.mapDoorMergeChoices(snapshot,selectedDoor):[]
    onSelectedRoomChanged:suggestionIndex=0
    onSuggestionsChanged:if(suggestionIndex>=suggestions.length)suggestionIndex=0
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
    property var doorProposalCommand:null
    property var gesture:null
    property var dragPatch:null
    readonly property bool dragging:!!gesture
    readonly property bool panning:!!press&&moved
    readonly property var dataModel:atlasEnabled?View.mapPlan(snapshot):null
    property var creationBounds:null
    property var presentationFrame:null
    property var focusState:null
    readonly property var camera:presentationFrame|| (creationBounds?View.mapFrame({bounds:creationBounds},width,height,1):View.mapFrame(dataModel,width,height,zoom,center))
    onProposalCommandChanged:{
        if(!proposalCommand||proposalCommand.kind!=="spatialRoomCreate"){creationBounds=null;return}
        if(!creationBounds&&dataModel){
            var r=View.mapRoomOutline(snapshot,proposalCommand),b=dataModel.bounds
            if(r){var x=Math.min(b.x,r.x),y=Math.min(b.y,r.y);creationBounds={x:x,y:y,w:Math.max(b.x+b.w,r.x+r.w)-x,h:Math.max(b.y+b.h,r.y+r.h)-y}}
        }
    }
    signal enterRoom(string id)
    signal contextRequested(real mapX,real mapY)
    signal addRoom()
    signal editRoom(string id,var patch)
    signal deleteRoom(string id)
    signal addDoor(var patch)
    signal editDoor(string id,var patch)
    signal directRoomEdit(string id,var patch)
    signal directDoorEdit(string id,var patch,string mergeId)
    signal directDoorCreate(var patch)
    signal mergeDoor(string id,string otherId)
    signal deleteDoor(string id)
    signal toggleGrid()
    signal toggleSnap()
    signal cycleSnapDistance()
    readonly property string contactMerge:gesture&&gesture.door&&dragPatch?View.mapDoorGestureMerge(snapshot,gesture.data.id,dragPatch):""
    readonly property var selectedBox:dataModel&&selectedRoom?dataModel.rooms.find(r=>r.id===selectedRoom)||null:null
    readonly property var outline:gesture&&!gesture.door&&dragPatch?View.mapRoomOutline(snapshot,{kind:"spatialRoomEdit",roomId:gesture.data.id,patch:dragPatch}):View.mapRoomOutline(snapshot,proposalCommand)
    readonly property var doorOutline:gesture&&gesture.door&&dragPatch?View.mapDoorOutline(snapshot,gesture.data.id,dragPatch):View.mapDoorCommandOutline(snapshot,doorProposalCommand)
    function selectDoor(id){
        var d=snapshot.spatial&&snapshot.spatial.doors?snapshot.spatial.doors[id]:null
        if(!d)return false
        selectedDoor=id;if(selectedRoom!==d.a.roomId&&selectedRoom!==d.b.roomId)selectedRoom=d.a.roomId
        return true
    }
    function startDoorGesture(id,kind,x,y){
        if(appearanceOpen||!arranging||!enabled||gesture)return false
        var g=View.mapDoorGesture(snapshot,id,kind,camera,x,y);if(!g)return false
        selectDoor(id);forceActiveFocus();gesture={door:true,data:g,x:x,y:y,snap:snapEnabled,interval:snapDistance};dragPatch=null;return true
    }
    function removeSelectedDoor(){if(!appearanceOpen&&arranging&&enabled&&!dragging&&selectedOpening){var id=selectedDoor;deleteDoor(id);return true}return false}
    function cancelGesture(){gesture=null;dragPatch=null;press=null;moved=false}
    function startGesture(id,kind,x,y){
        if(appearanceOpen||!arranging||!enabled||gesture)return false
        var g=View.mapRoomGesture(dataModel,id,kind,camera,x,y);if(!g)return false
        selectedDoor="";selectedRoom=id;forceActiveFocus();gesture={door:false,data:g,x:x,y:y,snap:snapEnabled,interval:snapDistance,magnet:magnetic};dragPatch=null;return true
    }
    function updateGesture(x,y){
        if(appearanceOpen){cancelGesture();return}
        if(!gesture)return
        var g=gesture;if(!dragPatch&&Math.hypot(x-g.x,y-g.y)<4)return
        dragPatch=g.door?View.mapDoorGesturePatch(g.data,x,y,g.snap,g.interval):View.mapRoomGesturePatch(g.data,x,y,g.snap,g.interval,g.magnet)
    }
    function finishGesture(x,y){
        if(appearanceOpen){cancelGesture();return}
        if(!gesture)return
        updateGesture(x,y);var g=gesture,p=dragPatch,mergeId=contactMerge;cancelGesture()
        if(p&&Object.keys(p).length){
            if(g.door){var d=snapshot.spatial.doors[g.data.id];if(d&&(p.start!==d.start||p.end!==d.end))directDoorEdit(g.data.id,p,mergeId)}
            else {var r=snapshot.spatial.rooms[g.data.id];if(r&&Object.keys(p).some(k=>p[k]!==r[k]))directRoomEdit(g.data.id,p)}
        }else if(Math.hypot(x-g.x,y-g.y)<4)focusSelection()
    }
    function pointFor(x,y){return camera?Qt.point(camera.x+x*camera.scale,camera.y+y*camera.scale):Qt.point(-1,-1)}
    function hit(x,y){var p=View.mapAt(camera,x,y);return p?View.mapRoomHit(dataModel,p.x,p.y):""}
    function suggestionHit(x,y){
        var d=suggestedOpening
        if(!d||selectedDoor||!camera)return false
        var a=pointFor(d.vertical?d.line:d.start,d.vertical?d.start:d.line),b=pointFor(d.vertical?d.line:d.end,d.vertical?d.end:d.line)
        var along=d.vertical?y:x,cross=d.vertical?x:y,start=d.vertical?a.y:a.x,end=d.vertical?b.y:b.x,line=d.vertical?a.x:a.y
        return Math.hypot(cross-line,Math.max(start-along,0,along-end))<=10
    }
    // Used only by the host's numeric-editor selection handoff. Header
    // and controls are not atlas targets, and doorway hit precedes Room.
    function editTargetAt(x,y){
        if(!visible||appearanceOpen||!camera||x<0||x>=width||y<64||y>=height)return null
        if(x>=mapControls.x&&x<mapControls.x+mapControls.width&&y>=mapControls.y)return null
        var door=View.mapDoorHit(dataModel,camera,x,y)
        if(door)return {kind:"door",id:door}
        var room=hit(x,y)
        return room?{kind:"room",id:room}:null
    }
    function cameraState(){return {zoom:zoom,center:center?{x:center.x,y:center.y}:null}}
    function setCameraState(c){zoom=c.zoom;center=c.center?{x:c.center.x,y:c.center.y}:null}
    function focusSelection(){
        if(!enabled||dragging||panning||appearanceOpen)return false
        var kind=selectedDoor?"door":"room",id=selectedDoor||selectedRoom,target=View.mapFocusCamera(dataModel,width,height,kind,id)
        if(!target)return false
        var base=focusState?focusState.base:cameraState();focusState={kind:kind,id:id,base:base};setCameraState(target);forceActiveFocus();return true
    }
    function restoreOverview(){
        if(!focusState||dragging||panning)return false
        var base=focusState.base;focusState=null;setCameraState(base);forceActiveFocus();return true
    }
    function reconcileFocus(){
        if(!focusState)return
        var f=focusState,target=View.mapFocusCamera(dataModel,width,height,f.kind,f.id)
        if(target)setCameraState(target);else {focusState=null;setCameraState(f.base)}
    }
    function savedView(){return {camera:cameraState(),selectedRoom:selectedRoom,selectedDoor:selectedDoor,focus:focusState?{kind:focusState.kind,id:focusState.id,base:focusState.base}:null}}
    function restoreView(v){resetView();if(!v)return;setCameraState(v.camera);selectedRoom=v.selectedRoom;selectedDoor=v.selectedDoor;focusState=v.focus}
    function fit(){if(dragging)return;press=null;focusState=null;center=null;zoom=1}
    function resetView(){cancelGesture();creationBounds=null;fit();selectedRoom="";selectedDoor="";suggestionIndex=0}
    function zoomAt(value,x,y){
        if(dragging||!camera||!Number.isFinite(value))return
        var anchor=View.mapAt(camera,x,y),next=Math.max(.25,Math.min(8,value))
        var frame=View.mapFrame(dataModel,width,height,next,center)
        if(!frame)return
        center=View.mapCameraCenter(anchor.x-(x-width/2)/frame.scale,anchor.y-(y-height/2)/frame.scale)
        zoom=next
    }
    onDataModelChanged:{cancelGesture();if(!dataModel||!dataModel.rooms.some(r=>r.id===selectedRoom))selectedRoom="";if(!dataModel||!dataModel.doors.some(d=>d.id===selectedDoor))selectedDoor="";reconcileFocus()}
    onVisibleChanged:if(!visible){cancelGesture();if(appearanceOpen)closeAppearance(true)}
    onWidthChanged:cancelGesture()
    onHeightChanged:cancelGesture()
    onEnabledChanged:if(!enabled){cancelGesture();if(appearanceOpen)closeAppearance(true)}else if(visible&&!appearanceOpen)forceActiveFocus()
    onArrangingChanged:cancelGesture()
    onActiveFocusChanged:if(!activeFocus)cancelGesture()
    Connections {target:map.Window.window;function onActiveChanged(){if(map.Window.window&&!map.Window.window.active)map.cancelGesture()}}
    Keys.onEscapePressed:function(event){if(appearanceOpen){closeAppearance(true);event.accepted=true}else if(gesture||press){cancelGesture();event.accepted=true}else if(focusState){restoreOverview();event.accepted=true}else if(selectedDoor){selectedDoor="";event.accepted=true}}
    Keys.onDeletePressed:function(event){if(appearanceOpen||activeFocus&&removeSelectedDoor())event.accepted=true}
    Keys.onPressed:function(event){
        if(event.key===Qt.Key_Backspace&&(appearanceOpen||activeFocus&&removeSelectedDoor()))event.accepted=true
        else if((event.key===Qt.Key_Menu||event.key===Qt.Key_F10&&(event.modifiers&Qt.ShiftModifier))&&!appearanceOpen&&!press&&!dragging){
            contextRequested(width/2,height/2);event.accepted=true
        }
    }
    Rectangle {anchors.fill:parent;color:map.colors.background}
    Canvas {
        id:art
        objectName:"map-room-art"
        anchors.fill:parent
        property var contourCache:null
        property int contourBuilds:0
        property int paintCount:0
        property int lastBuildMs:0
        property int maxBuildMs:0
        property int lastPaintMs:0
        function refresh(){if(visible&&available)requestPaint()}
        Connections {
            target:map
            function onDataModelChanged(){art.refresh()}
            function onCameraChanged(){art.refresh()}
            function onColorsChanged(){art.refresh()}
            function onPalettesChanged(){art.refresh()}
            function onDesktopPaletteChanged(){art.refresh()}
            function onContourModeChanged(){art.refresh()}
            function onContourDensityChanged(){art.refresh()}
            function onMapFrameStyleChanged(){art.refresh()}
            function onSelectedRoomChanged(){art.refresh()}
            function onOutlineChanged(){art.refresh()}
            function onDoorOutlineChanged(){art.refresh()}
            function onSelectedDoorChanged(){art.refresh()}
            function onSuggestedOpeningChanged(){art.refresh()}
            function onProposalValidChanged(){art.refresh()}
            function onShowGridChanged(){art.refresh()}
            function onSnapDistanceChanged(){art.refresh()}
        }
        onAvailableChanged:refresh()
        onVisibleChanged:refresh()
        onPaint:{
            if(!visible)return
            paintCount++;var paintStart=Date.now()
            var ctx=getContext("2d");ctx.reset();ctx.clearRect(0,0,width,height)
            var m=map.dataModel,f=map.camera;if(!m||!f)return
            var k=f.scale
            ctx.save();ctx.translate(f.x,f.y);ctx.scale(k,k)
            if(map.contourMode!=="none"&&map.contourDensity>0){
                var spec=Terrain.contourSpec(f,width,height,map.contourDensity)
                if(spec){
                    if(!map.presentationFrame&&(!contourCache||contourCache.key!==spec.key)){var buildStart=Date.now();contourCache={key:spec.key,data:Terrain.contourSegments(spec)};contourBuilds++;lastBuildMs=Date.now()-buildStart;maxBuildMs=Math.max(maxBuildMs,lastBuildMs)}
                    if(contourCache){ctx.save();ctx.globalAlpha=(map.contourMode==="engraved"?.28:.16)*spec.alpha;ctx.strokeStyle=map.colors.engraving;ctx.lineCap="round"
                    for(var level of contourCache.data.levels){ctx.lineWidth=(level.n%8===0?1.15:.65)/k;ctx.beginPath();for(var seg of level.segments){ctx.moveTo(seg[0],seg[1]);ctx.lineTo(seg[2],seg[3])}ctx.stroke()}
                    ctx.restore()}
                }
            }
            // Grid is drawn over Room fills, under labels and openings.
            for(var room of m.rooms){var palette=map.roomColors(room);ctx.fillStyle=View.mapRoomDetail(room,f,map.zoom)?palette.background:palette.panel;ctx.fillRect(room.x,room.y,room.w,room.h)}
            if(map.showGrid){
                var step=Math.max(5,map.snapDistance)
                while(step*k<12)step*=2
                var left=-f.x/k,top=-f.y/k,right=left+width/k,bottom=top+height/k
                ctx.beginPath();for(var gx=Math.ceil(left/step)*step;gx<=right;gx+=step){ctx.moveTo(gx,top);ctx.lineTo(gx,bottom)}
                for(var gy=Math.ceil(top/step)*step;gy<=bottom;gy+=step){ctx.moveTo(left,gy);ctx.lineTo(right,gy)}
                ctx.strokeStyle=map.colors.metal;ctx.lineWidth=.5/k;ctx.stroke()
            }
            function wall(r,inset,color,weight,alpha){
                ctx.save();ctx.globalAlpha=alpha;ctx.strokeStyle=color;ctx.lineWidth=weight/k;ctx.beginPath()
                for(var line of View.mapWallRuns(m,r,inset)){
                    if(line.vertical){ctx.moveTo(line.line,line.start);ctx.lineTo(line.line,line.end)}
                    else{ctx.moveTo(line.start,line.line);ctx.lineTo(line.end,line.line)}
                }
                ctx.stroke();ctx.restore()
            }
            for(var r of m.rooms){
                var palette=map.roomColors(r),detail=View.mapRoomDetail(r,f,map.zoom),selected=map.selectedRoom===r.id
                wall(r,0,selected?palette.text:palette.metal,selected?2:1.5,1)
                var inset=Math.min(8/k,r.w*.06,r.h*.06)
                if(r.mapStyle.frame!=="plain")wall(r,inset,palette.engraving,.75,.55)
                if(r.mapStyle.frame==="engraved"&&Math.min(r.w,r.h)*k>76){
                    var d=Math.min(14/k,r.w*.1,r.h*.1),pad=inset*1.6
                    ctx.save();ctx.globalAlpha=.65;ctx.strokeStyle=palette.engraving;ctx.lineWidth=.8/k
                    for(var corner of [[r.x+pad,r.y+pad,1,1],[r.x+r.w-pad,r.y+pad,-1,1],[r.x+pad,r.y+r.h-pad,1,-1],[r.x+r.w-pad,r.y+r.h-pad,-1,-1]]){
                        ctx.beginPath();ctx.moveTo(corner[0]+corner[2]*d,corner[1]);ctx.lineTo(corner[0],corner[1]);ctx.lineTo(corner[0],corner[1]+corner[3]*d);ctx.stroke()
                    }
                    ctx.restore()
                }
                if(detail)for(var shelf of r.shelves){
                    var sp=map.palettes.length?View.spatialPalette(map.snapshot,shelf.id,map.palettes,map.desktopPalette):palette
                    for(var layer of shelf.glyph.layers){
                        var q=layer.points;ctx.beginPath();ctx.moveTo(q[0][0],q[0][1]);for(var i=1;i<q.length;i++)ctx.lineTo(q[i][0],q[i][1]);ctx.closePath()
                        ctx.fillStyle=View.planGlyphColor(map.snapshot,shelf.id,layer.role,sp);ctx.fill()
                    }
                    var lip=shelf.glyph.front;ctx.beginPath();ctx.moveTo(lip[0][0],lip[0][1]);ctx.lineTo(lip[1][0],lip[1][1]);ctx.strokeStyle=sp.engraving;ctx.lineWidth=1.2/k;ctx.stroke()
                }
            }
            // Openings use the exact shared world interval, not an inferred
            // proximity or separate copy for each Room.
            for(var door of m.doors){
                ctx.beginPath()
                if(door.vertical){ctx.moveTo(door.line,door.start);ctx.lineTo(door.line,door.end)}
                else{ctx.moveTo(door.start,door.line);ctx.lineTo(door.end,door.line)}
                ctx.strokeStyle=map.selectedDoor===door.id?map.colors.text:map.colors.engraving;ctx.lineWidth=(map.selectedDoor===door.id?3:1)/k;ctx.stroke()
                // Short jamb marks, not a second wall across the opening.
                ctx.beginPath();for(var endpoint of [door.start,door.end]){if(door.vertical){ctx.moveTo(door.line-4/k,endpoint);ctx.lineTo(door.line+4/k,endpoint)}else{ctx.moveTo(endpoint,door.line-4/k);ctx.lineTo(endpoint,door.line+4/k)}}ctx.lineWidth=1/k;ctx.stroke()
            }
            function drawOpening(d,color,lineWidth){
                if(!d)return;ctx.beginPath()
                if(d.vertical){ctx.moveTo(d.line,d.start);ctx.lineTo(d.line,d.end)}else{ctx.moveTo(d.start,d.line);ctx.lineTo(d.end,d.line)}
                ctx.strokeStyle=color;ctx.lineWidth=lineWidth/k;ctx.stroke()
            }
            if(map.arranging&&!map.selectedDoor&&!map.doorProposalCommand)drawOpening(map.suggestedOpening,map.colors.text,3)
            drawOpening(map.doorOutline,map.dragging||map.proposalValid?map.colors.text:"#df8585",5)
            var ghost=map.outline
            if(ghost){ctx.strokeStyle=map.dragging||map.proposalValid?map.colors.engraving:"#df8585";ctx.lineWidth=2/k;ctx.strokeRect(ghost.x,ghost.y,ghost.w,ghost.h)}
            ctx.restore();lastPaintMs=Date.now()-paintStart
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
            color:map.roomColors(modelData).text;text:modelData.name+(modelData.mapStyle.labels==="both"&&modelData.mapStyle.subtitle&&height>=48?"\n"+modelData.mapStyle.subtitle:"")
            font.family:"serif";font.pixelSize:Math.max(1,Math.min(19,height*.20))
            horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter
            elide:Text.ElideRight;clip:true
        }
    }
    Repeater {
        model:map.visible&&map.dataModel?map.dataModel.rooms:[]
        Image {
            required property var modelData
            readonly property point origin:map.pointFor(modelData.x,modelData.y)
            x:origin.x+12;y:origin.y+12;width:22;height:22;opacity:.62
            visible:!!source.toString()&&map.camera&&modelData.mapStyle.marks!=="none"&&Math.min(modelData.w,modelData.h)*map.camera.scale>=100&&(modelData.mapStyle.marks==="all"||View.mapRoomDetail(modelData,map.camera,map.zoom))
            source:map.camera&&Math.min(modelData.w,modelData.h)*map.camera.scale>=100?View.ornamentAsset(modelData.family,map.roomColors(modelData).name):""
            fillMode:Image.PreserveAspectFit;asynchronous:false
        }
    }
    MouseArea {
        anchors.fill:parent;acceptedButtons:Qt.RightButton
        enabled:!map.appearanceOpen&&!map.press&&!map.dragging
        onClicked:function(mouse){var id=map.hit(mouse.x,mouse.y);if(id){map.selectedRoom=id;map.selectedDoor="";map.openAppearance(id)}else map.contextRequested(mouse.x,mouse.y)}
    }
    MouseArea {
        anchors.fill:parent;acceptedButtons:Qt.LeftButton|Qt.MiddleButton
        onPressed:function(mouse){
            if(!map.camera||map.appearanceOpen)return
            map.forceActiveFocus();map.moved=false
            if(map.arranging&&mouse.button===Qt.LeftButton){
                var doorId=View.mapDoorHit(map.dataModel,map.camera,mouse.x,mouse.y)
                if(doorId){map.startDoorGesture(doorId,"move",mouse.x,mouse.y);return}
                if(map.suggestionHit(mouse.x,mouse.y)){map.press={x:mouse.x,y:mouse.y,suggestion:map.suggestedOpening.patch};return}
                var id=map.hit(mouse.x,mouse.y);if(id){map.startGesture(id,"move",mouse.x,mouse.y);return}
                map.press={x:mouse.x,y:mouse.y,cx:map.camera.cx,cy:map.camera.cy,scale:map.camera.scale,blankArrange:true};return
            }
            map.press={x:mouse.x,y:mouse.y,cx:map.camera.cx,cy:map.camera.cy,scale:map.camera.scale}
        }
        onPositionChanged:function(mouse){
            if(map.gesture){map.updateGesture(mouse.x,mouse.y);return}
            if(!pressed||!map.press)return
            var p=map.press,dx=mouse.x-p.x,dy=mouse.y-p.y
            if(!map.moved&&Math.hypot(dx,dy)<4)return
            if(p.suggestion){map.moved=true;return}
            map.moved=true;map.center=View.mapCameraCenter(p.cx-dx/p.scale,p.cy-dy/p.scale)
        }
        onReleased:function(mouse){
            if(map.gesture){map.finishGesture(mouse.x,mouse.y);return}
            var p=map.press;map.press=null
            if(!p||map.appearanceOpen||map.moved||Math.hypot(mouse.x-p.x,mouse.y-p.y)>=4)return
            if(p.suggestion){map.directDoorCreate(p.suggestion);return}
            if(p.blankArrange){map.selectedRoom="";map.selectedDoor="";map.restoreOverview()}
        }
        onCanceled:map.cancelGesture()
        onClicked:function(mouse){if(!map.appearanceOpen&&!map.arranging&&mouse.button===Qt.LeftButton&&!map.moved){var d=View.mapDoorHit(map.dataModel,map.camera,mouse.x,mouse.y);if(!d||!map.selectDoor(d)){map.selectedDoor="";map.selectedRoom=map.hit(mouse.x,mouse.y)}}}
        onDoubleClicked:function(mouse){
            if(map.appearanceOpen||map.arranging||mouse.button!==Qt.LeftButton||map.moved)return
            var id=map.hit(mouse.x,mouse.y)
            if(id){map.press=null;map.selectedRoom=id;map.enterRoom(id)}
        }
        onWheel:function(wheel){if(!map.appearanceOpen&&!map.press&&!map.dragging){map.zoomAt(map.zoom*Math.pow(1.15,wheel.angleDelta.y/120),wheel.x,wheel.y)}wheel.accepted=true}
    }
    Repeater {
        model:[{key:"nw",x:0,y:0},{key:"n",x:.5,y:0},{key:"ne",x:1,y:0},{key:"e",x:1,y:.5},{key:"se",x:1,y:1},{key:"s",x:.5,y:1},{key:"sw",x:0,y:1},{key:"w",x:0,y:.5}]
        Rectangle {
            id:resizeHandle
            required property var modelData
            objectName:modelData.key==="se"?"map-room-resize-handle":"map-room-resize-"+modelData.key
            width:22;height:22;radius:3
            enabled:!map.appearanceOpen
            visible:!map.appearanceOpen&&map.arranging&&!!map.selectedBox&&!map.selectedDoor&&!map.proposalCommand&&!map.doorProposalCommand&&
                (modelData.key==="se"||map.camera&&Math.min(map.selectedBox.w,map.selectedBox.h)*map.camera.scale>=70)
            readonly property point corner:map.selectedBox?map.pointFor(map.selectedBox.x+map.selectedBox.w*modelData.x,map.selectedBox.y+map.selectedBox.h*modelData.y):Qt.point(0,0)
            x:corner.x-width/2;y:corner.y-height/2;color:map.colors.background;border.color:map.colors.engraving;border.width:2
            MouseArea {
                anchors.fill:parent
                cursorShape:resizeHandle.modelData.key==="n"||resizeHandle.modelData.key==="s"?Qt.SizeVerCursor:resizeHandle.modelData.key==="e"||resizeHandle.modelData.key==="w"?Qt.SizeHorCursor:resizeHandle.modelData.key==="nw"||resizeHandle.modelData.key==="se"?Qt.SizeFDiagCursor:Qt.SizeBDiagCursor
                function local(mouse){return resizeHandle.mapToItem(map,mouse.x,mouse.y)}
                onPressed:function(mouse){var p=local(mouse);if(View.mapDoorHit(map.dataModel,map.camera,p.x,p.y)){mouse.accepted=false;return}map.startGesture(map.selectedRoom,"resize-"+resizeHandle.modelData.key,p.x,p.y)}
                onPositionChanged:function(mouse){if(pressed){var p=local(mouse);map.updateGesture(p.x,p.y)}}
                onReleased:function(mouse){var p=local(mouse);map.finishGesture(p.x,p.y)}
                onCanceled:map.cancelGesture()
            }
        }
    }
    Rectangle {
        objectName:"map-door-center-grip"
        visible:map.arranging&&!map.appearanceOpen&&!!map.selectedOpening&&!map.doorProposalCommand
        width:14;height:14;radius:7;color:map.colors.panel;border.color:map.colors.engraving;border.width:2
        readonly property var opening:map.selectedOpening
        readonly property point center:opening?map.pointFor(opening.vertical?opening.line:(opening.start+opening.end)/2,opening.vertical?(opening.start+opening.end)/2:opening.line):Qt.point(0,0)
        x:center.x-width/2;y:center.y-height/2
    }
    Text {
        visible:!!map.contactMerge;anchors.horizontalCenter:parent.horizontalCenter;anchors.bottom:mapControls.top;anchors.bottomMargin:8
        text:"Contact · release to merge";color:map.colors.text;font.pixelSize:12
    }
    Repeater {
        model:["start","end"]
        Rectangle {
            id:doorHandle
            required property string modelData
            objectName:"map-door-"+modelData+"-handle"
            enabled:!map.appearanceOpen
            visible:!map.appearanceOpen&&map.arranging&&!!map.selectedOpening&&!map.doorProposalCommand
            width:20;height:20;radius:3
            readonly property var opening:map.selectedOpening
            readonly property point endpoint:opening?map.pointFor(opening.vertical?opening.line:opening[modelData],opening.vertical?opening[modelData]:opening.line):Qt.point(0,0)
            readonly property int offset:modelData==="start"?-16:16
            x:endpoint.x-width/2+(opening&&opening.vertical?offset:0)
            y:endpoint.y-height/2+(opening&&!opening.vertical?offset:0)
            color:map.colors.panel;border.color:map.colors.engraving;border.width:2
            Text {anchors.centerIn:parent;color:map.colors.text;font.pixelSize:10;text:doorHandle.modelData==="start"?"A":"B"}
            MouseArea {
                anchors.fill:parent;cursorShape:doorHandle.opening&&doorHandle.opening.vertical?Qt.SizeVerCursor:Qt.SizeHorCursor
                function local(mouse){return doorHandle.mapToItem(map,mouse.x,mouse.y)}
                onPressed:function(mouse){var p=local(mouse);map.startDoorGesture(map.selectedDoor,doorHandle.modelData,p.x,p.y)}
                onPositionChanged:function(mouse){if(pressed){var p=local(mouse);map.updateGesture(p.x,p.y)}}
                onReleased:function(mouse){var p=local(mouse);map.finishGesture(p.x,p.y)}
                onCanceled:map.cancelGesture()
            }
        }
    }
    Rectangle {anchors.top:parent.top;anchors.horizontalCenter:parent.horizontalCenter;width:Math.max(60,parent.width-220);height:map.chartSubtitle?56:34;color:map.colors.background;opacity:.96;z:2}
    Column {
        z:3
        anchors.top:parent.top;anchors.topMargin:8;anchors.horizontalCenter:parent.horizontalCenter
        width:Math.max(60,parent.width-220);spacing:2
        Text {width:parent.width;text:map.chartTitle.trim()||"The Map Room";horizontalAlignment:Text.AlignHCenter;elide:Text.ElideRight;color:map.colors.text;font.family:"serif";font.pixelSize:20}
        Text {width:parent.width;text:map.chartSubtitle;visible:!!text;horizontalAlignment:Text.AlignHCenter;elide:Text.ElideRight;color:map.colors.engraving;font.family:"serif";font.pixelSize:12}
    }
    Item {
        x:12;y:12;width:48;height:48;visible:map.chartOrnament!=="none"
        Canvas {
            id:compassArt;anchors.fill:parent;visible:map.chartOrnament==="compass"
            function refresh(){if(visible&&available)requestPaint()}
            onVisibleChanged:refresh();onAvailableChanged:refresh()
            Connections {target:map;function onColorsChanged(){compassArt.refresh()}}
            onPaint:{var c=getContext("2d");c.reset();c.clearRect(0,0,width,height);c.strokeStyle=map.colors.engraving;c.lineWidth=1;c.beginPath();c.arc(24,26,14,0,Math.PI*2);c.stroke();c.beginPath();c.moveTo(24,7);c.lineTo(28,22);c.lineTo(43,26);c.lineTo(28,30);c.lineTo(24,45);c.lineTo(20,30);c.lineTo(5,26);c.lineTo(20,22);c.closePath();c.stroke();c.fillStyle=map.colors.engraving;c.beginPath();c.moveTo(24,7);c.lineTo(28,22);c.lineTo(24,26);c.closePath();c.fill()}
        }
        Text {x:20;y:0;text:"N";color:map.colors.engraving;font.pixelSize:9;visible:map.chartOrnament==="compass"}
        Image {anchors.fill:parent;anchors.margins:5;visible:map.chartOrnament==="family";source:visible?View.ornamentAsset(map.chartFamily,map.colors.name):"";fillMode:Image.PreserveAspectFit}
    }
    MouseArea {
        anchors.fill:parent;z:4;visible:map.appearanceOpen
        acceptedButtons:Qt.AllButtons
        property point at:Qt.point(0,0)
        onPressed:function(mouse){at=Qt.point(mouse.x,mouse.y)}
        onWheel:function(wheel){wheel.accepted=true}
        onClicked:function(mouse){if(Math.hypot(mouse.x-at.x,mouse.y-at.y)>6)return
            if(mouse.button===Qt.RightButton){var id=map.hit(mouse.x,mouse.y);map.closeAppearance(false);if(!map.appearanceOpen)map.openAppearance(id)}
            else if(mouse.button===Qt.LeftButton)map.closeAppearance(false)
        }
    }
    ArchiveButton {objectName:"map-chart";z:5;anchors.top:parent.top;anchors.right:parent.right;anchors.margins:8;colors:map.colors;label:"Chart…";enabled:!map.dragging&&!map.panning;onClicked:if(map.appearanceOpen)map.closeAppearance(false);else map.openAppearance()}
    Rectangle {
        id:chartPanel;objectName:"map-chart-panel";z:6
        anchors.top:parent.top;anchors.right:parent.right;anchors.margins:8;anchors.topMargin:42
        width:238;height:Math.min(map.height-52,425);radius:5;color:map.colors.panel;border.color:map.colors.metal
        visible:map.appearanceOpen
        Keys.onEscapePressed:function(event){map.closeAppearance(true);event.accepted=true}
        MouseArea {anchors.fill:parent;acceptedButtons:Qt.AllButtons;onWheel:function(wheel){wheel.accepted=true}}
        Flickable {
            anchors.fill:parent;anchors.margins:8;anchors.bottomMargin:44;clip:true;contentWidth:width;contentHeight:chartFields.height
            Column {
                id:chartFields;width:parent.width;spacing:4
                Text {text:map.localAppearance?"Room inscription":"Chart inscription";color:map.colors.engraving;font.pixelSize:11}
                Rectangle {width:parent.width;height:26;radius:3;color:map.colors.background;border.color:map.colors.metal;TextInput {objectName:"map-chart-title";anchors.fill:parent;anchors.margins:4;clip:true;text:map.localAppearance?map.localValue("name")||"":map.chartTitle;color:map.colors.text;maximumLength:80;onTextEdited:map.appearanceChanged(map.localAppearance?"name":"title",text);Keys.onEscapePressed:map.closeAppearance(true)}}
                Rectangle {width:parent.width;height:26;radius:3;color:map.colors.background;border.color:map.colors.metal;TextInput {objectName:"map-chart-subtitle";anchors.fill:parent;anchors.margins:4;clip:true;text:map.localAppearance?map.localValue("subtitle")||"":map.chartSubtitle;color:map.colors.text;maximumLength:120;onTextEdited:map.appearanceChanged("subtitle",text);Keys.onEscapePressed:map.closeAppearance(true)}}
                Row {visible:!map.localAppearance;spacing:4;Repeater {model:["none","subtle","engraved"];ArchiveButton {required property string modelData;objectName:"map-contour-"+modelData;colors:map.colors;label:modelData;active:map.contourMode===modelData;onClicked:map.appearanceChanged("contours",modelData)}}}
                Row {visible:!map.localAppearance;spacing:5;ArchiveButton {objectName:"map-contour-less";colors:map.colors;label:"−";enabled:map.contourDensity>0;onClicked:map.appearanceChanged("density",Math.max(0,map.contourDensity-20))}Text {text:"Density "+map.contourDensity;color:map.colors.text;anchors.verticalCenter:parent.verticalCenter;font.pixelSize:11}ArchiveButton {objectName:"map-contour-more";colors:map.colors;label:"+";enabled:map.contourDensity<100;onClicked:map.appearanceChanged("density",Math.min(100,map.contourDensity+20))}}
                Row {spacing:4;Repeater {model:map.localAppearance?[null,"plain","inset","engraved"]:["plain","inset","engraved"];ArchiveButton {required property var modelData;objectName:"map-frame-"+modelData;colors:map.colors;label:modelData===null?"Inherit":modelData;active:(map.localAppearance?map.localValue("frame"):map.mapFrameStyle)===modelData;onClicked:map.appearanceChanged("frame",modelData)}}}
                Row {visible:!map.localAppearance;spacing:4;Repeater {model:["none","family","compass"];ArchiveButton {required property string modelData;objectName:"map-mark-"+modelData;colors:map.colors;label:modelData;active:map.chartOrnament===modelData;onClicked:map.appearanceChanged("ornament",modelData)}}}
                ArchiveChoice {width:parent.width;colors:map.colors;title:"Family";prefix:"map-family";value:map.localAppearance?map.localValue("family"):map.chartFamily;options:map.choiceItems((map.localAppearance?[null]:[]).concat(["None","Architectural","Astral","Botanical","Bestiary","Elemental · Water","Elemental · Air","Elemental · Earth","Elemental · Fire","Horological"]));onSelected:function(v){map.appearanceChanged("family",v)}}
                ArchiveChoice {visible:map.localAppearance;width:parent.width;colors:map.colors;title:"Palette";prefix:"map-room-palette";value:map.localValue("palette");options:map.choiceItems([null,0,1,2],["Desktop","Evening","Twilight","Midnight"]);onSelected:function(v){map.appearanceChanged("palette",v)}}
                ArchiveChoice {width:parent.width;colors:map.colors;title:"Inscriptions";prefix:"map-labels";value:map.localAppearance?map.localValue("labels"):map.chartValue("labels");options:map.choiceItems(map.localAppearance?[null,"title","both"]:["title","both"]);onSelected:function(v){map.appearanceChanged("labels",v)}}
                ArchiveChoice {width:parent.width;colors:map.colors;title:"Room marks";prefix:"map-room-marks";value:map.localAppearance?map.localValue("marks"):map.chartValue("marks");options:map.choiceItems(map.localAppearance?[null,"none","detail","all"]:["none","detail","all"]);onSelected:function(v){map.appearanceChanged("marks",v)}}
                Text {width:parent.width;wrapMode:Text.WordWrap;color:map.colors.engraving;font.pixelSize:11;text:map.appearanceProposal&&map.appearanceProposal.error||"";visible:!!text}
            }
        }
        Row {anchors.bottom:parent.bottom;anchors.left:parent.left;anchors.margins:8;spacing:6
            ArchiveButton {objectName:"map-chart-close";colors:map.colors;label:"Done";enabled:!!map.appearanceProposal&&!map.appearanceProposal.error;onClicked:map.closeAppearance(false)}
            ArchiveButton {objectName:"map-chart-cancel";colors:map.colors;label:"Cancel";onClicked:map.closeAppearance(true)}
        }
    }
    // Explicit, non-overlapping hit rectangles. Do not reposition the
    // navigation row when Arrange reveals its additional controls.
    Item {
        id:mapControls
        objectName:"map-controls"
        anchors.bottom:parent.bottom;anchors.bottomMargin:8
        anchors.horizontalCenter:parent.horizontalCenter
        width:458;height:116
        enabled:!map.dragging&&!map.panning&&!map.appearanceOpen
        Item {
            objectName:"map-door-actions"
            width:336;x:61;height:26;y:0;visible:map.arranging;enabled:map.arranging
            ArchiveButton {objectName:"map-door-add";colors:map.colors;label:"Add opening";x:0;width:80;enabled:!!map.suggestedOpening;onClicked:map.addDoor(map.suggestedOpening.patch)}
            ArchiveButton {objectName:"map-door-next";colors:map.colors;label:map.suggestions.length?String(map.suggestionIndex+1)+"/"+map.suggestions.length:"No gap";hint:"Next clear opening suggestion";x:86;width:58;enabled:map.suggestions.length>1;onClicked:{map.selectedDoor="";map.suggestionIndex=(map.suggestionIndex+1)%map.suggestions.length}}
            ArchiveButton {objectName:"map-door-edit";colors:map.colors;label:"Size";x:150;width:52;enabled:!!map.selectedOpening;onClicked:map.editDoor(map.selectedDoor,{})}
            ArchiveButton {objectName:"map-door-merge";colors:map.colors;label:"Merge";x:208;width:60;enabled:map.mergeChoices.length>0;onClicked:map.mergeDoor(map.selectedDoor,map.mergeChoices[0])}
            ArchiveButton {objectName:"map-door-delete";colors:map.colors;label:"Delete";x:274;width:62;enabled:!!map.selectedOpening;onClicked:map.removeSelectedDoor()}
        }
        Item {
            objectName:"map-arrange-actions"
            width:336;x:61;height:26;y:30;visible:map.arranging;enabled:map.arranging
            ArchiveButton {objectName:"map-add-room";colors:map.colors;label:"Add Room";x:0;width:108;onClicked:map.addRoom()}
            ArchiveButton {objectName:"map-edit-room";colors:map.colors;label:"Dimensions…";x:114;width:108;enabled:!!map.selectedBox;onClicked:map.editRoom(map.selectedRoom,{})}
            ArchiveButton {objectName:"map-delete-room";colors:map.colors;label:"Remove Room";x:228;width:108;enabled:!!map.selectedBox&&!map.selectedBox.shelves.length;onClicked:map.deleteRoom(map.selectedRoom)}
        }
        Item {
            objectName:"map-arrange-grid-actions"
            width:336;x:61;height:26;y:60;visible:map.arranging;enabled:map.arranging
            ArchiveButton {objectName:"map-grid";colors:map.colors;label:"Grid";x:0;width:108;active:map.showGrid;onClicked:map.toggleGrid()}
            ArchiveButton {objectName:"map-snap";colors:map.colors;label:"Snap";x:114;width:55;active:map.snapEnabled;onClicked:map.toggleSnap()}
            ArchiveButton {objectName:"map-snap-interval";colors:map.colors;label:String(map.snapDistance);hint:"Cycle snap and grid interval";x:175;width:47;onClicked:map.cycleSnapDistance()}
            ArchiveButton {objectName:"map-magnetic";colors:map.colors;label:"Wall magnet";x:228;width:108;active:map.magnetic;onClicked:map.magnetic=!map.magnetic}
        }
        Item {
            objectName:"map-navigation-actions"
            width:parent.width;height:26;y:90
            ArchiveButton {objectName:"map-fit";colors:map.colors;label:"Fit map";x:0;width:74;onClicked:map.fit()}
            ArchiveButton {objectName:"map-zoom-out";colors:map.colors;label:"−";x:80;width:36;onClicked:map.zoomAt(map.zoom/1.15,map.width/2,map.height/2)}
            ArchiveButton {objectName:"map-zoom-in";colors:map.colors;label:"+";x:122;width:36;onClicked:map.zoomAt(map.zoom*1.15,map.width/2,map.height/2)}
            ArchiveButton {objectName:"map-enter-room";colors:map.colors;label:"Enter Room";x:164;width:106;enabled:!!map.selectedRoom&&!map.arranging;onClicked:map.enterRoom(map.selectedRoom)}
            ArchiveButton {objectName:"map-focus";colors:map.colors;label:"Focus";x:276;width:76;enabled:!!map.selectedRoom||!!map.selectedDoor;onClicked:map.focusSelection()}
            ArchiveButton {objectName:"map-overview";colors:map.colors;label:"Overview";x:358;width:100;enabled:!!map.focusState;onClicked:map.restoreOverview()}
        }
    }
}
