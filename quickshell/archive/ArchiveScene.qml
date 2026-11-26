import QtQuick
import QtQuick.Window
import "ArchiveMotion.mjs" as Motion
import "ArchiveCore.mjs" as Core
import "ArchiveView.mjs" as View
import "ArchiveSpatial.mjs" as Spatial
import "representation/B7Ownership.mjs" as Mixed
import "representation/B7Layout.mjs" as Layout
import "representation" as B7

Item {
    id: scene
    required property var controller
    required property var colors
    property var paletteOptions:[]
    property int desktopPaletteIndex:1
    readonly property bool spatialStyle:Spatial.enabled(controller.snapshot)
    readonly property bool architectural:spatialStyle&&Spatial.kind(controller.snapshot,cubbyId)==="shelf"
    function ornamentFamily(id){
        var s=appearanceSnapshot||controller.snapshot
        return spatialStyle&&Object.prototype.hasOwnProperty.call(s.cubbies,id)?Spatial.resolveAppearance(s,id,desktopPaletteIndex).family:"None"
    }
    function childColors(id){
        var s=appearanceSnapshot||controller.snapshot
        return spatialStyle&&paletteOptions.length===3&&Object.prototype.hasOwnProperty.call(s.cubbies,id)?View.spatialPalette(s,id,paletteOptions,desktopPaletteIndex):colors
    }
    property string mode: "browse"
    property var viewPath: ["root"]
    // Always render an existing reachable cubby, even during snapshot reset.
    readonly property var reachableViewPath:View.reachablePath(controller.snapshot,viewPath)
    readonly property string cubbyId: reachableViewPath[reachableViewPath.length-1]
    readonly property var cubby: controller.snapshot.cubbies[cubbyId]
    // Render only material attributes from the revision-bound preview.
    // The scene's geometry, identities, ownership and physics stay committed.
    property var appearanceSnapshot:null
    // Only validated cubby metadata/interior proposals alter the displayed
    // dimensions and explicitly suggested positions. Ownership, fixture
    // dimensions, cell metadata and physics stay committed.
    readonly property var interiorPreviewSnapshot:controller.structuralProposal&&controller.structuralProposal.ok&&controller.structuralProposal.command.kind==="cubby"?controller.structuralProposal.snapshot:null
    readonly property var displayCubby:interiorPreviewSnapshot&&interiorPreviewSnapshot.cubbies[cubbyId]||cubby
    readonly property var appearanceCubby:appearanceSnapshot&&appearanceSnapshot.cubbies[cubbyId]||cubby
    function materialModule(m){
        var proposal=controller.structuralProposal
        if(proposal&&proposal.ok&&["spatialAppPlace","spatialAppUnplace","spatialSupport"].includes(proposal.command.kind)){
            var updated=proposal.snapshot.cubbies[cubbyId].mods.find(q=>q.id===m.id)
            if(updated)return updated
        }
        if(proposal&&proposal.ok&&proposal.command.moduleId===m.id&&
           (proposal.command.kind==="shelf"&&(Spatial.enabled(controller.snapshot)||proposal.command.rearrange===true)||
            proposal.command.kind==="child"&&Spatial.enabled(controller.snapshot)||
            ["holderCreate","holderEdit","artwork"].includes(proposal.command.kind))){
            var candidate=proposal.snapshot.cubbies[cubbyId].mods.find(q=>q.id===m.id)
            if(candidate)return candidate
        }
        if(interiorPreviewSnapshot){
            var proposed=displayCubby.mods.find(function(q){return q.id===m.id})
            if(proposed&&(proposed.x!==m.x||proposed.y!==m.y))return Object.assign({},m,{x:proposed.x,y:proposed.y})
        }
        if(!appearanceSnapshot)return m
        var v=appearanceCubby.mods.find(function(q){return q.id===m.id})
        return v&&v.color!==m.color?Object.assign({},m,{color:v.color}):m
    }
    property string selectedModuleId: ""
    property string selectedHolderId:""
    property string selectedAppId:""
    property string selectedCell: ""
    property string selectedScrollId: ""
    property var selectedIds: []
    property var anchor: null
    property var pointer: null
    property bool pointerActive: false
    property point ghostPoint: Qt.point(0,0)
    property var furnitureDrag: null
    property var bookDrag:null
    signal bookPlacementProposed(real position)
    property var prepared: null
    property var insertionContext: null
    property var insertionHover: null
    property var insertionMark: null
    property string message: ""
    readonly property alias motion: live
    readonly property var committedCaseRecords: View.caseRecords(controller)
    readonly property bool busy: live.busy
    readonly property bool motionClockActive:live.clockActive
    readonly property int motionStepCount:live.stepCount
    focus:true
    ArchiveMotion {
        id:live
        controller:scene.controller
        onCompleted:function(ok){scene.pointer=null;scene.pointerActive=false;caseView.dragNear=false;if(ok){scene.clearSelection();caseView.pinned=false}}
    }
    property var eligibleKeys: []
    property real zoom: 1
    property point pan: Qt.point(0,0)
    property var cameras: View.copyCameras({})
    // Previous snapshot is used only for camera lifecycle comparison.
    property var cameraSnapshot:null
    Component.onCompleted:cameraSnapshot=controller.snapshot
    property var pinnedRecord: null
    property var hoveredRecord: null
    property point tipPoint: Qt.point(0,0)
    // Valid appearance and interior previews only; refused proposals retain
    // committed geometry. Legacy Cubby and unadopted Shelf remain unchanged.
    readonly property var frontSnapshot:interiorPreviewSnapshot||appearanceSnapshot||controller.snapshot
    readonly property var frontEnvelope:View.frontEnvelope(frontSnapshot,cubbyId,displayCubby)
    readonly property bool physicalFront:!!frontEnvelope.parts
    readonly property var camera: View.fitEnvelope(frontEnvelope,width,Math.max(1,height-42),zoom,pan)
    readonly property alias caseDock: caseView
    readonly property alias tooltip: tooltipView
    readonly property alias worldItem: world
    signal destinationPressed(string rackId,string key)
    signal furnitureContext(real sceneX,real sceneY)
    // View-only preference, independent of the arrangement/Undo history.
    property string cubbyPreviewMode:"veiled"
    property bool snapEnabled:false
    property bool showGrid:false
    property int snapDistance:20
    function quantize(v){return Core.snapCoordinate(v,snapDistance,snapEnabled)}
    function contextAt(x,y){
        if(mode!=="arrange"||live.busy||controller.draft||controller.structuralProposal||furnitureDrag||bookDrag)return
        var p=interior.mapFromItem(scene,x,y),m=cubby.mods.find(function(q){return Mixed.fixtureRects(q).some(b=>p.x>=b.x&&p.x<=b.x+b.w&&p.y>=b.y&&p.y<=b.y+b.h)})
        clearSelection()
        if(m){
            selectedModuleId=m.id
            if(m.type==="rack"){var item=moduleItem(m.id),c=item?item.hitCell(p.x-m.x,p.y-m.y):null;selectedCell=c?c.key:""}
            if(Mixed.supportsTop(m)){var h=Mixed.holderAt(m,{x:p.x-m.x,y:p.y-m.y});selectedHolderId=h?h.id:""}
        }
        furnitureContext(x,y)
    }
    objectName: "archive-scene"
    clip: true

    readonly property bool mixedInteractive:!controller.draft&&!controller.structuralProposal&&!prepared&&
        ((!live.busy&&!pointer)||(pointer&&pointer.kind==="mixed"))
    function beginMixedGesture(recordId,x,y){
        if(mode!=="browse"||!mixedInteractive||pointer||live.busy)return false
        var entry=Core.owners(controller.snapshot).find(q=>q.id===recordId&&q.cubbyId===cubbyId&&!["rack","case"].includes(q.where))
        if(!entry)return false
        selectMixed(entry.moduleId,recordId)
        forceActiveFocus()
        pointer={record:entry.scroll,kind:"mixed",entries:[entry],offsets:{},x:x,y:y}
        pointerActive=false
        return true
    }
    function mixedDestination(x,y,record,entry){
        if(x<0||y<0||x>width||y>height)return null
        var p=interior.mapFromItem(scene,x,y)
        if(p.x<0||p.y<0||p.x>interior.width||p.y>interior.height)return null
        return Mixed.destinationAt(controller.snapshot,cubbyId,p,record,entry)
    }
    function transferMixedDrop(recordId,x,y){
        if(mode!=="browse"||!mixedInteractive||pointer||live.busy)return false
        var e=Core.owners(controller.snapshot).find(q=>q.id===recordId&&q.cubbyId===cubbyId&&!["rack","case"].includes(q.where))
        if(!e)return false
        var inDock=caseView.containsDrop(caseView.mapFromItem(scene,x,y))
        var dest=inDock?"case":localAt(x,y)||mixedDestination(x,y,e.scroll,e)
        if(!dest){message="No compatible destination · arrangement unchanged";return false}
        message=""
        return live.transfer([recordId],dest,{},true)
    }
    function selectMixed(moduleId,recordId){
        if(!mixedInteractive)return
        clearSelection();selectedModuleId=moduleId
        if(mode==="browse"&&recordId){
            var e=Core.owners(controller.snapshot).find(q=>q.id===recordId)
            if(e){selectedScrollId=recordId;selectedIds=[recordId];message=e.scroll.name}
        }
    }
    function selectApp(moduleId,appId){
        if(!mixedInteractive)return
        selectMixed(moduleId,"");selectedAppId=appId
        var app=controller.snapshot.spatial.apps[appId]
        message="Application book · "+app.title+" (synthetic)"
    }
    function beginBookDrag(moduleId,appId,x,y){
        if(mode!=="arrange"||!Spatial.enabled(controller.snapshot)||!mixedInteractive||furnitureDrag||bookDrag)return false
        var m=cubby.mods.find(v=>v.id===moduleId),e=m&&(m.items||[]).find(v=>v.kind==="app"&&v.appId===appId)
        if(!e||!Mixed.supportsTop(m))return false
        selectApp(moduleId,appId)
        forceActiveFocus()
        bookDrag={revision:controller.archiveState.revision,containerId:cubbyId,moduleId:moduleId,appId:appId,
            startX:x,startY:y,baseX:e.x,worldX:m.x,worldY:m.y,scale:camera.scale,
            interval:snapDistance,snap:snapEnabled,active:false,targetX:e.x}
        return true
    }
    function updateBookDrag(x,y){
        if(!bookDrag)return
        var d=bookDrag,dx=x-d.startX,dy=y-d.startY
        if(!d.active&&Math.hypot(dx,dy)<6)return
        bookDrag=Object.assign({},d,{active:true,targetX:Core.bookDragPosition(d.baseX,dx/d.scale,d.interval,d.snap)})
    }
    function cancelBookDrag(){bookDrag=null}
    function finishBookDrag(x,y){
        if(!bookDrag)return
        updateBookDrag(x,y)
        var d=bookDrag;bookDrag=null
        if(!d.active||d.targetX===d.baseX)return
        if(d.revision!==controller.archiveState.revision||d.containerId!==cubbyId||mode!=="arrange"||controller.draft||controller.structuralProposal)return
        // Publish one validated proposal on release; never mutate while moving.
        controller.proposeStructure({kind:"spatialAppPlace",appId:d.appId,containerId:d.containerId,moduleId:d.moduleId,patch:{x:d.targetX}})
        bookPlacementProposed(d.targetX)
    }
    function topModule(m){
        var v=materialModule(m)
        // The solver's ready proposal has passed occupied rack bounds.
        // Invalid/unsettled proposals retain committed dependent positions.
        return m.type==="rack"&&controller.phase==="ready"?View.displayRack(controller,cubbyId,v):v
    }
    function moveHolder(moduleId,holderId,from,to,recordId){
        if(!mixedInteractive||mode!=="browse")return
        var command={kind:"holderMove",cubbyId:cubbyId,moduleId:moduleId,holderId:holderId,from:from,to:to,recordId:recordId}
        if(controller.editMixed(command)){message="Holder arrangement updated · Undo available";clearSelection()}
        else message=controller.errorText
    }
    function liveMembership(id){return live.busy&&Object.prototype.hasOwnProperty.call(live.membership,id)?live.membership[id]:null}
    function moduleItem(id) {
        for(var i=0;i<modules.count;i++){
            var item=modules.itemAt(i)
            if(item&&item.modelData.id===id)return item.item
        }
        return null
    }
    function clearSelection() {
        selectedModuleId="";selectedHolderId="";selectedAppId="";selectedCell="";selectedScrollId=""
        pinnedRecord=null;hoveredRecord=null;selectedIds=[];anchor=null;cancelInsertion()
    }
    function saveCamera() {
        var next=View.copyCameras(cameras)
        next[cubbyId]={zoom:zoom,x:pan.x,y:pan.y}
        cameras=next
    }
    function restoreCamera() {
        var c=View.cameraFor(cameras,cubbyId)
        zoom=c.zoom
        pan=Qt.point(c.x,c.y)
    }
    // N2a: explicit frontal Shelf selection; upper plan navigation follows N3/N4.
    readonly property var shelfRoots: Spatial.roots(controller.snapshot)
    function openShelf(id) {
        if(!Spatial.enabled(controller.snapshot)||!shelfRoots.includes(id)||live.busy||
           controller.draft||controller.structuralProposal||pointer||furnitureDrag||bookDrag||prepared)return false
        if(viewPath.length===1&&viewPath[0]===id)return true
        saveCamera();viewPath=[id];restoreCamera();clearSelection();return true
    }
    function openChild(id) {
        if(live.busy||controller.draft||controller.structuralProposal||bookDrag||!cubby.mods.some(function(m){return m.type==="cubby"&&m.childId===id}))return false
        saveCamera();viewPath=viewPath.concat([id]);restoreCamera();clearSelection();return true
    }
    function back() {
        if(live.busy||controller.draft||controller.structuralProposal||bookDrag||viewPath.length<=1)return false
        saveCamera();viewPath=viewPath.slice(0,-1);restoreCamera();clearSelection();return true
    }
    function enterSelected() {
        var m=cubby.mods.find(function(q){return q.id===selectedModuleId})
        return !!m&&m.type==="cubby"&&openChild(m.childId)
    }
    function setZoom(value) { if(bookDrag)return;zoom=Math.max(.5,Math.min(2.5,value));pinnedRecord=null;hoveredRecord=null }
    function showRecord(record,point,pin) {
        if(pin){pinnedRecord=pinnedRecord&&pinnedRecord.id===record.id?null:record;selectedScrollId=record.id}
        else hoveredRecord=record
        if(!pinnedRecord||pin)tipPoint=point
    }
    function localAt(x,y){
        if(x<0||y<0||x>width||y>height)return null
        var p=interior.mapFromItem(scene,x,y)
        if(p.x<0||p.y<0||p.x>interior.width||p.y>interior.height)return null
        for(var i=0;i<cubby.mods.length;i++){
            var m=cubby.mods[i];if(m.type!=="rack")continue
            var item=moduleItem(m.id),local={x:p.x-m.x,y:p.y-m.y}
            if(!item||local.x<0||local.y<0||local.x>m.w||local.y>m.h)continue
            var c=item.hitCell(local.x,local.y)
            if(c)return {cubbyId:cubbyId,rackId:m.id,key:c.key,local:local}
        }
        return null
    }
    function startGesture(record,x,y,modifiers,kind){
        if(mode!=="browse"||controller.draft||controller.structuralProposal||live.busy||prepared)return
        forceActiveFocus()
        message=""
        var choice=Motion.select(controller.snapshot,cubbyId,kind,selectedIds,anchor,record.id,!!(modifiers&(Qt.ControlModifier|Qt.MetaModifier)),!!(modifiers&Qt.ShiftModifier))
        selectedIds=choice.ids;anchor=choice.anchor;selectedScrollId=selectedIds.indexOf(record.id)>=0?record.id:selectedIds.length?selectedIds[selectedIds.length-1]:""
        if(kind==="rack"){caseView.pinned=false;caseView.hoverOpen=false;var entry=Core.owners(controller.snapshot).find(function(e){return e.id===record.id});selectedModuleId=entry.rackId;selectedCell=entry.key}
        else caseView.pinned=true
        if(modifiers&(Qt.ControlModifier|Qt.MetaModifier|Qt.ShiftModifier)){pinnedRecord=null;hoveredRecord=null;return}
        var entries=Core.owners(controller.snapshot).filter(function(e){return choice.ids.indexOf(e.id)>=0}),offsets={},p=interior.mapFromItem(scene,x,y)
        for(var i=0;i<entries.length;i++){
            var e=entries[i]
            if(e.where==="rack"){var rack=Core.rackAt(controller.snapshot,e.cubbyId,e.rackId);offsets[e.id]={x:e.scroll.x+rack.x-p.x,y:e.scroll.y+rack.y-p.y}}
        }
        pointer={record:record,kind:kind,entries:entries,offsets:offsets,x:x,y:y}
        pointerActive=false
    }
    function moveGesture(x,y){
        if(!pointer)return
        if(!pointerActive){
            if(Math.hypot(x-pointer.x,y-pointer.y)<4)return
            // Keep the source Case delegates stable during mouse capture.
            pointerActive=true
            if(!live.start(selectedIds,pointer.kind==="mixed")){pointer=null;pointerActive=false;return}
            pinnedRecord=null;hoveredRecord=null
        }
        ghostPoint=Qt.point(x,y)
        var loc=localAt(x,y),p=caseView.mapFromItem(scene,x,y),inDock=caseView.containsDrop(p)
        var same=pointer.kind==="rack"&&pointer.entries.every(function(e){return Motion.same(e,loc)})&&!inDock
        if(!live.transaction.lifted){
            if(same)live.hold(loc,pointer.offsets)
            else if(!live.lift())return
        }
        if(!pointer)return
        caseView.dragNear=pointer.kind!=="case"&&live.transaction.lifted&&caseView.nearPill(p)
    }
    function endGesture(x,y){
        if(!pointer)return
        if(!pointerActive&&Math.hypot(x-pointer.x,y-pointer.y)>=4)moveGesture(x,y)
        if(!pointer)return
        var p=pointer
        if(!pointerActive){pointer=null;if(p.kind!=="mixed"){selectedIds=[p.record.id];showRecord(p.record,Qt.point(x,y),true)}return}
        var loc=localAt(x,y),inDock=caseView.containsDrop(caseView.mapFromItem(scene,x,y))
        var same=p.kind==="rack"&&p.entries.every(function(e){return Motion.same(e,loc)})&&!inDock
        pointer=null;pointerActive=false;caseView.dragNear=false
        if(!live.busy)return
        if(!live.transaction.lifted&&same){live.hold(loc,p.offsets);if(live.busy)live.release(true);return}
        if(live.transaction.lifted&&same){live.abort("Returned to origin · exact rollback");return}
        if(inDock&&p.kind!=="case"){if(live.lift())live.drop("case",{});return}
        if(loc&&!inDock){if(live.lift())live.drop(loc,p.offsets);return}
        if(!inDock&&p.entries.length===1){
            var destination=mixedDestination(x,y,p.record,p.entries[0])
            if(destination){if(live.lift())live.drop(destination,{});return}
        }
        live.abort("Drop canceled · original arrangement restored")
    }
    function abortGesture(){
        cancelBookDrag()
        pointer=null;pointerActive=false;caseView.dragNear=false
        if(live.busy)live.abort()
        if(furnitureDrag){furnitureDrag=null;controller.cancel()}
    }
    function beginFurniture(id,action,x,y){
        if(bookDrag||live.busy||controller.structuralProposal||mode!=="arrange"||(controller.draft&&controller.draft.rackId!==id))return
        forceActiveFocus()
        var rack=controller.draft?controller.draft.proposed:Core.rackAt(controller.snapshot,cubbyId,id)
        if(!rack)return
        var point=interior.mapFromItem(scene,x,y)
        furnitureDrag={id:id,action:action,start:{x:point.x,y:point.y},base:{x:rack.x,y:rack.y,w:rack.w,h:rack.h}}
    }
    function moveFurniture(x,y){
        if(!furnitureDrag)return
        var d=furnitureDrag,p=interior.mapFromItem(scene,x,y),dx=p.x-d.start.x,dy=p.y-d.start.y
        var patch=Core.fixtureDragPatch(d.base,dx,dy,d.action!=="move",false,snapDistance,snapEnabled)
        controller.stage(cubbyId,d.id,patch)
    }
    function prepareInsertion(){
        if(live.busy||controller.draft||mode!=="browse")return false
        var s=controller.snapshot.caseItems.find(function(q){return q.id===selectedScrollId})
        if(!s)return false
        prepared=s;insertionContext=null;insertionHover=null;insertionMark=null;pinnedRecord=null;hoveredRecord=null;caseView.pinned=false
        message="Choose a cell · hover void · click to lock"
        return true
    }
    function cancelInsertion(){prepared=null;insertionContext=null;insertionHover=null;insertionMark=null}
    function insertionAt(rackId,key,x,y,modifiers){
        if(!prepared||!key)return
        var rack=Core.rackAt(controller.snapshot,cubbyId,rackId),cell=Core.geometry(rack).cells.find(function(c){return c.key===key})
        if(!cell)return
        var records=rack.scrollCells[key]||[]
        if(!insertionContext||insertionContext.rackId!==rackId||insertionContext.key!==key){
            insertionContext={rackId:rackId,key:key,cell:cell,records:records,atlas:Core.voidAtlas(cell,records)}
            insertionMark=null
        }
        var region=Core.regionAt(insertionContext.atlas,{x:x,y:y}),p=Core.projectIntoCell(Core.wall(cell),{x:x,y:y},prepared.r)
        insertionHover=region
        if(!p||(!region&&!(modifiers&Qt.ShiftModifier))){insertionMark=null;message="Choose a connected void or Shift-click a crowded point";return}
        insertionMark={rackId:rackId,key:key,x:p.x,y:p.y,r:prepared.r,region:region}
        message="Insertion locked · Insert or Drop from top"
    }
    function hoverInsertion(rackId,x,y){
        if(!prepared||!insertionContext||insertionContext.rackId!==rackId)return
        var next=Core.regionAt(insertionContext.atlas,{x:x,y:y})
        if((next?next.id:-1)!==(insertionHover?insertionHover.id:-1))insertionHover=next
    }
    function voidFor(rackId){
        if(!insertionContext||insertionContext.rackId!==rackId)return null
        var region=insertionHover||(insertionMark?insertionMark.region:null)
        return {region:region,cell:insertionContext.cell,records:insertionContext.records}
    }
    function insertPrepared(top){
        if(!prepared||!insertionContext||(!top&&!insertionMark))return false
        var c=insertionContext,s=prepared,p=top?Core.topEntrance(c.cell,c.records,s.r):insertionMark
        if(!p){message="No clear top entrance · choose a void";return false}
        var dest={cubbyId:cubbyId,rackId:c.rackId,key:c.key,local:{x:p.x,y:p.y},top:top}
        cancelInsertion();message="";return live.transfer([s.id],dest,{})
    }
    function returnOrigin(){
        if(mode!=="browse"||live.busy||controller.draft||controller.structuralProposal||pointer||prepared)return false
        var s=controller.snapshot.caseItems.find(q=>q.id===selectedScrollId)
        try{
            var destination=Core.originDestination(controller.snapshot,s)
            message=""
            return live.transfer([s.id],destination,{})
        }catch(e){message=String(e.message||e)+" · choose destination";return false}
    }
    function cutSelected(){
        if(mode!=="browse"||live.busy||controller.draft)return
        var entries=Core.owners(controller.snapshot).filter(function(e){return e.where!=="case"&&e.cubbyId===cubbyId&&selectedIds.indexOf(e.id)>=0})
        if(entries.length)live.transfer(entries.map(e=>e.id),"case",{},entries.some(e=>e.where!=="rack"))
    }
    function pasteSelected(){
        if(mode!=="browse"||live.busy||controller.draft)return
        var records=controller.snapshot.caseItems.filter(function(s){return selectedIds.indexOf(s.id)>=0})
        var rack=Core.rackAt(controller.snapshot,cubbyId,selectedModuleId),cell=rack&&Core.geometry(rack).cells.find(function(c){return c.key===selectedCell})
        if(!records.length||!cell)return
        var p=Core.staticScrollSpot(cell,rack.scrollCells[cell.key]||[],records[0].r,.2)
        if(p)live.transfer(records.map(function(s){return s.id}),{cubbyId:cubbyId,rackId:rack.id,key:cell.key,local:p},{})
        else message="No clear insertion point"
    }
    Keys.onPressed:function(event){
        if(event.key===Qt.Key_Escape){abortGesture();cancelInsertion();if(controller.draft||controller.structuralProposal)controller.cancel();clearSelection();event.accepted=true}
        else if(bookDrag){event.accepted=true}
        else if(event.key===Qt.Key_Menu||(event.key===Qt.Key_F10&&(event.modifiers&Qt.ShiftModifier))){
            var m=cubby.mods.find(function(q){return q.id===selectedModuleId})
            var p=m?interior.mapToItem(scene,m.x+m.w/2,m.y+m.h/2):interior.mapToItem(scene,interior.width/2,interior.height/2)
            if(mode==="arrange"&&!controller.draft&&!controller.structuralProposal&&!live.busy){furnitureContext(p.x,p.y);event.accepted=true}
        }
        else if(event.modifiers&Qt.ControlModifier){
            if(event.key===Qt.Key_X){cutSelected();event.accepted=true}
            else if(event.key===Qt.Key_V){pasteSelected();event.accepted=true}
            else if(event.key===Qt.Key_Z&&!live.busy){controller.undo();clearSelection();event.accepted=true}
        }
    }
    Connections {
        target:scene.Window.window
        function onActiveChanged(){if(scene.Window.window&&!scene.Window.window.active&&(scene.pointer||scene.bookDrag))scene.abortGesture()}
    }
    onModeChanged: {abortGesture();clearSelection()}
    Connections {
        target: scene.controller
        function onSnapshotChanged() {
            scene.cancelBookDrag()
            var next=scene.controller.snapshot,previous=scene.cameraSnapshot
            if(scene.controller.resetting){
                scene.cameras=View.copyCameras({});scene.viewPath=Spatial.enabled(next)?View.reachablePath(next,next.path):["root"];scene.restoreCamera();scene.clearSelection()
            }else if(previous){
                var activeId=scene.viewPath[scene.viewPath.length-1]
                scene.cameras=View.reconcileCameras(previous,next,scene.controller.archiveState.history,scene.cameras,
                    scene.controller.restoringUndo,activeId,{zoom:scene.zoom,x:scene.pan.x,y:scene.pan.y})
            }
            scene.cameraSnapshot=next
            var path=View.reachablePath(next,scene.viewPath)
            if(JSON.stringify(path)!==JSON.stringify(scene.viewPath)){
                scene.viewPath=path;scene.restoreCamera();scene.clearSelection()
            }
            if(scene.selectedModuleId&&!scene.cubby.mods.some(function(m){return m.id===scene.selectedModuleId}))scene.clearSelection()
            if(scene.selectedAppId&&!scene.cubby.mods.some(m=>(m.items||[]).some(e=>e.kind==="app"&&e.appId===scene.selectedAppId)))scene.selectedAppId=""
            scene.pinnedRecord=null;scene.hoveredRecord=null
        }
        function onDraftChanged(){if(scene.controller.draft){scene.cancelBookDrag();scene.pinnedRecord=null;scene.hoveredRecord=null}}
    }

    Rectangle { anchors.fill:parent; color:scene.colors.background }
    Item {
        id: world
        x:scene.camera.x; y:scene.camera.y
        width:scene.frontEnvelope.w
        height:scene.frontEnvelope.h
        scale:scene.camera.scale
        transformOrigin:Item.TopLeft
        Rectangle {
            anchors.fill:parent
            visible:!scene.physicalFront
            radius:2
            color:View.frameColor(scene.appearanceCubby,scene.colors,scene.viewPath.length-1)
            border.color:View.mix(scene.colors.metal,scene.colors.text,.20)
        }
        // Each Shelf keeps its own frame treatment, bounded to the
        // physical envelope. The same profile reference can be used in N3.
        Item {
            id:frameDetail
            objectName:"architectural-frame-detail"
            anchors.fill:parent;visible:scene.architectural&&!scene.physicalFront
            readonly property string profile:scene.architectural?Spatial.shelfProfile(scene.appearanceSnapshot||scene.controller.snapshot,scene.cubbyId):"cornice"
            Repeater {
                model:frameDetail.visible?View.shelfTrim(scene.displayCubby,frameDetail.profile):[]
                Rectangle {
                    required property var modelData
                    x:modelData.x;y:modelData.y;width:modelData.w;height:modelData.h
                    color:scene.colors[modelData.role]
                    opacity:modelData.role==="engraving"?.65:1
                }
            }
        }
        ArchiveProfileFront {
            objectName:"physical-shelf-frame"
            anchors.fill:parent
            visible:scene.physicalFront
            profileGeometry:scene.physicalFront?scene.frontEnvelope:null
            colors:scene.colors
            frameColor:View.frameColor(scene.appearanceCubby,scene.colors,scene.viewPath.length-1)
        }
        Item {
            id: interior
            objectName:"cubby-interior"
            x:scene.frontEnvelope.aperture.x
            y:scene.frontEnvelope.aperture.y
            width:scene.displayCubby.w
            height:scene.displayCubby.h
            clip:true
            Rectangle {
                anchors.fill:parent
                color:View.backingColor(scene.appearanceCubby,scene.colors,scene.viewPath.length-1)
                border.color:View.mix(scene.colors.metal,scene.colors.panel,.32)
            }
            ArchiveFamilyMark {
                objectName:"archive-backing-ornament"
                family:scene.ornamentFamily(scene.cubbyId)
                colors:scene.colors
            }
            Item {
                objectName:"cubby-guide-grid"
                anchors.fill:parent;visible:scene.mode==="arrange"&&scene.showGrid
                z:6
                Repeater {
                    model:Math.floor(interior.width/Math.max(5,scene.snapDistance))+1
                    Rectangle {
                        required property int index
                        objectName:"grid-x-"+index
                        x:index*scene.snapDistance;width:.7;height:interior.height
                        color:scene.colors.engraving;opacity:.24
                    }
                }
                Repeater {
                    model:Math.floor(interior.height/Math.max(5,scene.snapDistance))+1
                    Rectangle {
                        required property int index
                        objectName:"grid-y-"+index
                        y:index*scene.snapDistance;height:.7;width:interior.width
                        color:scene.colors.engraving;opacity:.24
                    }
                }
            }
            Repeater {
                id: modules
                model:scene.cubby.mods
                Loader {
                    id: moduleLoader
                    required property var modelData
                    sourceComponent:modelData.type==="rack"?rackComponent:modelData.type==="artwork"?artworkComponent:modelData.type==="shelf"?((scene.materialModule(modelData).items||[]).length?mixedShelfComponent:shelfComponent):childComponent
                    Component {
                        id:rackComponent
                        ArchiveRack {
                            rack:View.displayRack(scene.controller,scene.cubbyId,scene.materialModule(moduleLoader.modelData))
                            colors:scene.colors
                            browse:scene.mode==="browse"
                            selected:scene.selectedModuleId===rack.id
                            selectedCell:selected?scene.selectedCell:""
                            selectedScroll:scene.selectedScrollId
                            selectedIds:scene.selectedIds
                            motionRecords:scene.liveMembership(rack.id)
                            motionPositions:live.positions
                            insertionMode:!!scene.prepared
                            locked:live.busy&&!scene.pointerActive
                            voidData:scene.voidFor(rack.id)
                            lockedMark:scene.insertionMark&&scene.insertionMark.rackId===rack.id?scene.insertionMark:null
                            onGestureStarted:function(record,lx,ly,modifiers){var p=mapToItem(scene,lx,ly);scene.startGesture(record,p.x,p.y,modifiers,"rack")}
                            onGestureMoved:function(lx,ly){var p=mapToItem(scene,lx,ly);scene.moveGesture(p.x,p.y)}
                            onGestureReleased:function(lx,ly){var p=mapToItem(scene,lx,ly);scene.endGesture(p.x,p.y)}
                            onGestureCanceled:if(scene.pointer)scene.abortGesture()
                            onCellPoint:function(key,lx,ly,modifiers){scene.insertionAt(rack.id,key,lx,ly,modifiers)}
                            onPointerHover:function(lx,ly){scene.hoverInsertion(rack.id,lx,ly)}
                            onResizeStarted:function(action,lx,ly){var p=mapToItem(scene,lx,ly);scene.beginFurniture(rack.id,action,p.x,p.y)}
                            onResizeMoved:function(lx,ly){var p=mapToItem(scene,lx,ly);scene.moveFurniture(p.x,p.y)}
                            onResizeReleased:scene.furnitureDrag=null
                            onResizeCanceled:if(scene.furnitureDrag)scene.abortGesture()
                            phase:scene.controller.draft&&scene.controller.draft.rackId===rack.id?scene.controller.phase:"idle"
                            unresolved:phase!=="idle"&&scene.controller.preview?scene.controller.preview.unresolved:[]
                            eligibleKeys:phase!=="idle"?scene.eligibleKeys:[]
                            onRackPressed: function(id,key){
                                if(scene.controller.draft&&scene.controller.draft.rackId!==id)return
                                scene.selectedModuleId=id;scene.selectedCell=key
                                scene.pinnedRecord=null;scene.hoveredRecord=null
                                scene.destinationPressed(id,key)
                            }
                            onScrollPressed: function(record,lx,ly){
                                scene.selectedModuleId=rack.id;scene.selectedCell=record.cellKey
                                scene.showRecord(record,mapToItem(scene,lx,ly),true)
                            }
                            onScrollHovered: function(record,lx,ly){
                                scene.showRecord(record,mapToItem(scene,lx,ly),false)
                            }
                        }
                    }
                    Component {
                        id:shelfComponent
                        ArchiveShelf {
                            module:scene.materialModule(moduleLoader.modelData)
                            spatialStyle:scene.spatialStyle
                            colors:scene.colors
                            browse:scene.mode==="browse"
                            selected:scene.selectedModuleId===module.id
                            onActivated:function(id){
                                if(!scene.controller.draft&&!scene.controller.structuralProposal&&!live.busy){scene.clearSelection();scene.selectedModuleId=id}
                            }
                        }
                    }
                    Component {
                        id:mixedShelfComponent
                        B7.B7MixedShelf {
                            spatialStyle:scene.spatialStyle
                            module:scene.materialModule(moduleLoader.modelData)
                            colors:scene.colors;plaqueHost:interior;gestureHost:scene
                            apps:scene.controller.snapshot.spatial?scene.controller.snapshot.spatial.apps||({}):({})
                            browse:scene.mode==="browse";interactive:scene.mixedInteractive
                            selected:scene.selectedModuleId===module.id
                            selectedRecordId:scene.selectedScrollId
                            hiddenIds:live.mixedVisuals.hidden
                            onAppActivated:function(appId){scene.selectApp(module.id,appId)}
                            onActivated:function(recordId){scene.selectMixed(module.id,recordId)}
                            onMoveRequested:function(holderId,from,to,recordId){scene.moveHolder(module.id,holderId,from,to,recordId)}
                        }
                    }
                    Component {
                        id:artworkComponent
                        B7.B7MountedArtwork {
                            hiddenIds:live.mixedVisuals.hidden
                            module:scene.materialModule(moduleLoader.modelData)
                            colors:scene.colors;plaqueHost:interior;gestureHost:scene
                            browse:scene.mode==="browse";interactive:scene.mixedInteractive
                            selected:scene.selectedModuleId===module.id
                            onActivated:function(recordId){scene.selectMixed(module.id,recordId)}
                        }
                    }
                    Component {
                        id:childComponent
                        ArchiveCubbyFace {
                            module:scene.materialModule(moduleLoader.modelData)
                            child:(scene.appearanceSnapshot||scene.interiorPreviewSnapshot||scene.controller.snapshot).cubbies[module.childId]
                            colors:scene.childColors(module.childId)
                            ornamentFamily:scene.ornamentFamily(module.childId)
                            depth:scene.viewPath.length
                            previewMode:scene.cubbyPreviewMode
                            selected:scene.selectedModuleId===module.id
                            browse:scene.mode==="browse"
                            onActivated: function(id,childId){
                                if(scene.mode==="browse")scene.openChild(childId)
                                else if(!scene.controller.draft&&!live.busy) {scene.clearSelection();scene.selectedModuleId=id}
                            }
                        }
                    }
                }
            }
            // Render eligible module tops with the same supported-object/holder
            // delegates as boards, not an extra physical board or a second owner.
            Repeater {
                model:scene.cubby.mods.filter(m=>{var v=scene.materialModule(m);return v.type!=="shelf"&&Mixed.supportsTop(v)&&(v.items||[]).length})
                B7.B7MixedShelf {
                    required property var modelData
                    module:scene.topModule(modelData)
                    spatialStyle:scene.spatialStyle
                    showBoard:false
                    apps:scene.controller.snapshot.spatial?scene.controller.snapshot.spatial.apps||({}):({})
                    colors:scene.colors;plaqueHost:interior;gestureHost:scene
                    browse:scene.mode==="browse";interactive:scene.mixedInteractive
                    selected:scene.selectedModuleId===module.id
                    selectedRecordId:scene.selectedScrollId;hiddenIds:live.mixedVisuals.hidden
                    onActivated:function(recordId){scene.selectMixed(module.id,recordId)}
                    onAppActivated:function(appId){scene.selectApp(module.id,appId)}
                    onMoveRequested:function(holderId,from,to,recordId){scene.moveHolder(module.id,holderId,from,to,recordId)}
                }
            }
            Rectangle {
                objectName:"book-drag-outline"
                visible:!!scene.bookDrag&&scene.bookDrag.active
                x:scene.bookDrag?scene.bookDrag.worldX+scene.bookDrag.targetX-21:0
                y:scene.bookDrag?scene.bookDrag.worldY-160:0
                width:42;height:160
                color:"#3040788f";border.color:scene.colors.engraving;border.width:2
                z:9
            }
            // A mixed destination is already owned by the private draft, but
            // its final symbolic delegate is not published until settling ends.
            // Keep a single scroll cue at the destination, not a second object.
            Repeater {
                model:live.mixedVisuals.pending.filter(p=>p.cubbyId===scene.cubbyId)
                ArchiveScrollEnd {
                    required property var modelData
                    objectName:"pending-mixed-"+modelData.record.id
                    record:modelData.record;colors:scene.colors
                    visualRadius:Math.min(20,record.r);provisional:true;selected:true
                    x:modelData.x-width/2;y:modelData.y-height/2;z:9
                }
            }
            Rectangle {
                // Provisional fixture footprint; invalid overlaps are visible but cannot apply.
                id:structuralGhost
                objectName:"structural-ghost"
                property var q:scene.controller.structuralProposal
                property var cmd:q?q.command:null
                property var patch:cmd?cmd.patch||{}:{}
                property var original:cmd?scene.cubby.mods.find(function(m){return m.id===cmd.moduleId}):null
                visible:!!cmd&&cmd.cubbyId===scene.cubbyId&&(cmd.kind==="shelf"||cmd.kind==="child"||cmd.kind==="artwork"||cmd.kind==="create"||cmd.kind==="delete"&&!!original)
                x:patch.x!==undefined?patch.x:original?original.x:0
                y:patch.y!==undefined?patch.y:original?original.y:0
                width:Math.max(1,patch.w!==undefined?patch.w:original?original.w:120)
                height:Math.max(1,patch.h!==undefined?patch.h:original?original.h:15)
                color:q&&q.ok&&cmd&&cmd.kind!=="delete"?"#40568f80":"#40df8585"
                border.color:q&&q.ok&&cmd&&cmd.kind!=="delete"?"#78c4a7":"#df8585"
                border.width:2
                Rectangle {visible:!!structuralGhost.cmd&&structuralGhost.cmd.kind!=="delete";width:12;height:Math.min(12,parent.height);anchors.right:parent.right;anchors.bottom:parent.bottom;color:scene.colors.engraving;opacity:.9}
                z:8
            }
            Rectangle {
                objectName:"holder-structural-ghost"
                property var q:scene.controller.structuralProposal
                property var cmd:q?q.command:null
                property var board:cmd?scene.cubby.mods.find(m=>m.id===cmd.moduleId):null
                property var h:board&&cmd?(board.items||[]).find(e=>e.kind==="holder"&&e.id===cmd.holderId)||null:null
                visible:!!cmd&&cmd.cubbyId===scene.cubbyId&&!!board&&["holderCreate","holderEdit","holderDelete"].includes(cmd.kind)
                x:board?board.x+(cmd&&cmd.patch&&cmd.patch.x!==undefined?cmd.patch.x:h?h.x:0):0
                readonly property var envelope:Layout.holderEnvelope(h?h.scale:.86,cmd&&cmd.patch&&cmd.patch.w!==undefined?cmd.patch.w:h?h.w:160)
                height:envelope.height
                y:board?board.y-height:0
                width:Math.max(1,envelope.width)
                color:q&&q.ok&&cmd&&cmd.kind!=="holderDelete"?"#40568f80":"#40df8585"
                border.color:q&&q.ok&&cmd&&cmd.kind!=="holderDelete"?"#78c4a7":"#df8585";border.width:2;z:8
            }
        }
        Rectangle {
            objectName:"cubby-inscription"
            visible:!scene.physicalFront
            // Fit the actual font metrics, rather than capping every name
            // at 170 local units. Elide only when the frame really is narrow.
            width:Math.max(0,Math.min(parent.width-20,Math.max(88,cubbyLabel.implicitWidth+20)))
            height:18; radius:8
            anchors.bottom:parent.bottom
            anchors.bottomMargin:2
            anchors.horizontalCenter:parent.horizontalCenter
            color:View.mix(scene.colors.metal,scene.colors.panel,.38)
            border.color:View.mix(scene.colors.metal,scene.colors.text,.35)
            Text {
                id:cubbyLabel
                objectName:"cubby-inscription-label"
                anchors.centerIn:parent
                text:scene.displayCubby.name||scene.displayCubby.id
                width:Math.max(0,parent.width-10)
                horizontalAlignment:Text.AlignHCenter
                elide:Text.ElideRight
                color:scene.colors.text
                font.pixelSize:11
                font.bold:true
            }
        }
        Text {
            objectName:"physical-shelf-inscription"
            visible:scene.physicalFront
            readonly property var inscription:scene.frontEnvelope.inscription||{x:0,y:0,w:0,h:0}
            x:inscription.x+4;y:inscription.y
            width:Math.max(0,inscription.w-8);height:inscription.h
            text:(scene.displayCubby.name||scene.displayCubby.id).toUpperCase()
            color:scene.colors.text
            // Constrained to the actual lintel; no extra occupied geometry.
            font.family:"serif";font.pixelSize:Math.max(1,inscription.h*.78)
            fontSizeMode:Text.HorizontalFit;minimumPixelSize:1
            horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter
            elide:Text.ElideRight;clip:true
        }
    }
    MouseArea {
        anchors.fill:parent
        acceptedButtons:Qt.MiddleButton
        property point start:Qt.point(0,0)
        property point original:Qt.point(0,0)
        onPressed:function(mouse){start=Qt.point(mouse.x,mouse.y);original=scene.pan;scene.pinnedRecord=null;scene.hoveredRecord=null}
        onPositionChanged:function(mouse){if(pressed&&!scene.bookDrag)scene.pan=Qt.point(original.x+mouse.x-start.x,original.y+mouse.y-start.y)}
        onWheel:function(wheel){scene.setZoom(scene.zoom*(wheel.angleDelta.y>0?1.12:1/1.12));wheel.accepted=true}
    }
    ArchiveCase {
        id:caseView
        colors:scene.colors
        records:live.busy&&!scene.pointerActive?live.caseRecords:scene.committedCaseRecords
        hiddenIds:scene.pointerActive&&live.busy?live.carried.map(function(s){return s.id}):[]
        countOverride:live.busy?live.caseRecords.length:-1
        motionPending:live.busy
        carryingFromCase:scene.pointerActive&&scene.pointer&&scene.pointer.kind==="case"
        selectedIds:scene.selectedIds
        locked:!!scene.controller.draft||!!scene.controller.structuralProposal||live.busy&&!scene.pointerActive||!!scene.prepared
        onGestureStarted:function(record,lx,ly,modifiers){var p=mapToItem(scene,lx,ly);scene.startGesture(record,p.x,p.y,modifiers,"case")}
        onGestureMoved:function(lx,ly){var p=mapToItem(scene,lx,ly);scene.moveGesture(p.x,p.y)}
        onGestureReleased:function(lx,ly){var p=mapToItem(scene,lx,ly);scene.endGesture(p.x,p.y)}
        onGestureCanceled:if(scene.pointer)scene.abortGesture()
        pendingIds:live.busy?live.caseRecords.filter(function(s){return !scene.controller.snapshot.caseItems.some(function(q){return q.id===s.id})}).map(function(s){return s.id}):scene.controller.preview?scene.controller.preview.caseOverflow.map(function(s){return s.id}):[]
        selectedId:scene.selectedScrollId
        anchors.bottom:parent.bottom
        anchors.bottomMargin:7
        anchors.horizontalCenter:parent.horizontalCenter
        onRecordPressed:function(record){scene.showRecord(record,caseView.mapToItem(scene,0,0),true)}
    }
    Item {
        id:ghost
        objectName:"carry-ghost"
        z:18;visible:scene.pointerActive&&live.carried.length>0
        width:62;height:62
        x:scene.ghostPoint.x-width/2;y:scene.ghostPoint.y-height/2
        Repeater {
            model:live.carried.slice(0,4)
            ArchiveScrollEnd {
                required property var modelData
                required property int index
                record:modelData;colors:scene.colors
                visualRadius:live.carried.length===1?20:12
                x:live.carried.length===1?11:5+(index%2)*23
                y:live.carried.length===1?11:5+Math.floor(index/2)*23
                selected:true
            }
        }
        Rectangle {
            visible:live.carried.length>1
            width:25;height:18;radius:6
            anchors.bottom:parent.bottom;anchors.right:parent.right
            color:scene.colors.panel;border.color:scene.colors.metal
            Text {anchors.centerIn:parent;text:live.carried.length;color:scene.colors.text;font.pixelSize:11}
        }
    }
    MouseArea {
        anchors.fill:parent;z:24
        visible:scene.mode==="arrange"&&!scene.bookDrag&&!scene.controller.draft&&!scene.controller.structuralProposal&&!live.busy
        acceptedButtons:Qt.RightButton
        onClicked:function(mouse){scene.contextAt(mouse.x,mouse.y)}
        onWheel:function(wheel){wheel.accepted=false}
    }
    // While the inspector is proposing a structural edit, protect committed
    // furniture and Case from pointer input. The inspector is a sibling.
    MouseArea {
        id:structuralPointer
        anchors.fill:parent
        z:25
        visible:!!scene.controller.structuralProposal
        acceptedButtons:Qt.AllButtons
        property var dragCommand:null
        onVisibleChanged:if(!visible)dragCommand=null
        property point start:Qt.point(0,0)
        property bool resizing:false
        onPressed:function(mouse){
            var q=scene.controller.structuralProposal
            if(mouse.button!==Qt.LeftButton||!q||q.command.kind==="delete"||!structuralGhost.visible)return
            var p=interior.mapFromItem(scene,mouse.x,mouse.y),g=structuralGhost
            if(p.x<g.x||p.x>g.x+g.width||p.y<g.y||p.y>g.y+g.height)return
            dragCommand=Core.clone(q.command)
            dragCommand.patch=Object.assign({x:g.x,y:g.y,w:g.width,h:g.height},dragCommand.patch)
            start=p
            resizing=p.x>g.x+g.width-16&&(g.height<=20||p.y>g.y+g.height-16)
        }
        onPositionChanged:function(mouse){
            if(!pressed||!dragCommand||!scene.controller.structuralProposal)return
            var p=interior.mapFromItem(scene,mouse.x,mouse.y),d=Core.clone(dragCommand),b=dragCommand.patch
            var dx=p.x-start.x,dy=p.y-start.y,isShelf=d.type==="shelf"||d.kind==="shelf"
            d.patch=Object.assign({},b,Core.fixtureDragPatch(b,dx,dy,resizing,isShelf,scene.snapDistance,scene.snapEnabled))
            if(d.kind==="shelf")delete d.rearrange
            scene.controller.proposeStructure(d)
        }
        onReleased:dragCommand=null
        onCanceled:dragCommand=null
        onWheel:function(wheel){wheel.accepted=true}
    }
    ArchiveTooltip {
        id:tooltipView
        colors:scene.colors
        record:scene.pinnedRecord||scene.hoveredRecord
        expanded:!!scene.pinnedRecord
        anchorPoint:scene.tipPoint
    }
}
