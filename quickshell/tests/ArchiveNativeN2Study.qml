import QtQuick
import "../archive" as Archive
import "../archive/ArchiveView.mjs" as View
import "../archive/ArchiveCore.mjs" as Core
import "../archive/ArchiveSpatial.mjs" as Spatial
import "../archive/ArchiveRoomTransition.mjs" as Transition
import "../archive/representation/B7Ownership.mjs" as Mixed
import "../themes" as Themes

// N3 isolated interactive study, retaining the N2 visual test entrypoint.
// Synthetic records only; no production shell or filesystem integration.
Rectangle {
    id: study
    width: 1100
    height: 720
    property var colors: Themes.Theme.current
    // Explicit opt-in for mixed study; retain the original B6 reference fixture.
    property var initialSnapshot:null
    property bool spatialEnabled:false
    property bool physicalProfilesEnabled:false
    property bool mapEnabled:false
    property bool mapOpen:false
    property string activeRoomId:""
    readonly property bool showMap:mapEnabled&&mapOpen&&Spatial.physicalProfiles(archive.snapshot)
    readonly property bool upperView:showMap||showRoomPlan
    readonly property string inspectedRoomId:Spatial.enabled(archive.snapshot)&&archive.snapshot.spatial.shelves[sceneView.reachableViewPath[0]]?archive.snapshot.spatial.shelves[sceneView.reachableViewPath[0]].roomId:""
    readonly property string currentRoomId:mapEnabled&&activeRoomId&&(showMap||roomPlanOpen||roomNavigating)?activeRoomId:inspectedRoomId
    // Opt-in synthetic test trace. No arrangement data or real environment details.
    property bool mapNavigationDiagnostics:false
    function traceMapNavigation(stage){
        if(!mapNavigationDiagnostics)return
        var buttons=[]
        for(var i=0;i<primaryTools.children.length;i++){
            var item=primaryTools.children[i]
            if(item&&item.objectName==="archive-layer-tool-slot")item=item.children[0]
            if(!item||!item.visible)continue
            var p=item.mapToItem(study,item.width/2,item.height/2)
            buttons.push({name:item.objectName,label:item.label,x:p.x,y:p.y,w:item.width,h:item.height,enabled:item.enabled})
        }
        console.log("B8 map navigation",stage,JSON.stringify({
            mapEnabled:mapEnabled,physical:Spatial.physicalProfiles(archive.snapshot),
            ready:viewSwitchReady,checkpointLoad:checkpointLoadPending,materialOpen:materialPanel!=="",
            planDrag:roomPlan.dragging,mapPan:(mapView.panning||mapView.dragging),headingEnabled:heading.enabled,
            navigating:roomNavigating,busy:sceneView.busy,pointer:!!sceneView.pointer,
            prepared:!!sceneView.prepared,furnitureDrag:!!sceneView.furnitureDrag,bookDrag:!!sceneView.bookDrag,
            draft:!!archive.draft,proposal:!!archive.structuralProposal,context:contextOpen,picker:bookPicker,
            mapOpen:mapOpen,roomPlanOpen:roomPlanOpen,mapVisible:mapView.visible,planVisible:roomPlan.visible,
            shelfVisible:sceneView.visible,sceneFocus:sceneView.activeFocus,planFocus:roomPlan.activeFocus,mapFocus:mapView.activeFocus,
            activeRoom:activeRoomId,currentRoom:currentRoomId,inspectedRoom:inspectedRoomId,selectedShelf:roomPlan.selectedShelf,
            perspective:roomPerspective,headingHeight:heading.height,sceneY:sceneView.y,toolbar:buttons
        }))
    }
    function openMap(){
        traceMapNavigation("openMap entered")
        if(!mapEnabled||!Spatial.physicalProfiles(archive.snapshot)||!viewSwitchReady||checkpointLoadPending||materialPanel!==""||roomPlan.dragging||(mapView.panning||mapView.dragging)){
            traceMapNavigation("openMap returned false")
            return false
        }
        if(currentRoomId){activeRoomId=currentRoomId;mapView.selectedRoom=currentRoomId;if(mapView.selectedDoor){var d=archive.snapshot.spatial.doors[mapView.selectedDoor];if(!d||![d.a.roomId,d.b.roomId].includes(currentRoomId))mapView.selectedDoor=""}}
        sceneView.clearSelection();roomPlanOpen=false;mapOpen=true;mapView.forceActiveFocus()
        traceMapNavigation("openMap returned true")
        return true
    }
    property var mapNavigation:null
    property real mapProgress:0
    readonly property bool mapNavigating:!!mapNavigation
    function focusActiveLayer(){if(showMap&&mapView)mapView.forceActiveFocus();else if(showRoomPlan&&roomPlan)roomPlan.forceActiveFocus();else if(sceneView)sceneView.forceActiveFocus()}
    function enterMapRoom(id){
        if(!showMap||!viewSwitchReady||checkpointLoadPending||materialPanel!==""||mapView.appearanceOpen||mapView.press||(mapView.panning||mapView.dragging)||sceneView.mode!=="browse"||!Object.prototype.hasOwnProperty.call(archive.snapshot.spatial.rooms,id))return false
        var target=View.mapFocusCamera(mapView.dataModel,mapView.width,mapView.height,"room",id)
        if(!target||!mapView.camera)return false
        var to=View.mapFrame(mapView.dataModel,mapView.width,mapView.height,target.zoom,target.center)
        mapView.selectedRoom=id
        if(mapView.selectedDoor){var door=archive.snapshot.spatial.doors[mapView.selectedDoor];if(!door||![door.a.roomId,door.b.roomId].includes(id))mapView.selectedDoor=""}
        mapProgress=0;mapNavigation={roomId:id,from:Core.clone(mapView.camera),to:to}
        if(reducedRoomMotion){finishMapNavigation();return true}
        mapNavigationOverlay.forceActiveFocus();mapAnimation.start();return true
    }
    function finishMapNavigation(){
        var n=mapNavigation;if(!n)return
        mapAnimation.stop();mapProgress=1
        if(mapEnabled&&Spatial.physicalProfiles(archive.snapshot)&&Object.prototype.hasOwnProperty.call(archive.snapshot.spatial.rooms,n.roomId)){
            activeRoomId=n.roomId;mapOpen=false;roomPlanOpen=true;sceneView.clearSelection()
        }
        mapNavigation=null;focusActiveLayer()
    }
    function abortMapNavigation(){if(mapNavigation){mapAnimation.stop();mapNavigation=null;mapProgress=0}}
    NumberAnimation {id:mapAnimation;objectName:"map-navigation-animation";target:study;property:"mapProgress";from:0;to:1;duration:240;easing.type:Easing.OutCubic;onFinished:study.finishMapNavigation()}
    function resetMapView(){abortMapNavigation();mapOpen=false;activeRoomId="";if(mapView)mapView.resetView()}
    onMapEnabledChanged:if(!mapEnabled){if(mapOpen||activeRoomId)roomPlanOpen=false;resetMapView();focusActiveLayer()}
    property bool roomPlanOpen:false
    property bool roomPerspective:false
    // Optional separate view-preference storage, never structural Undo.
    property var roomPreferenceStore:null
    function restoreRoomPreference(){
        if(!roomPreferenceStore)return
        try{roomPerspective=roomPreferenceStore.readRoomPerspective()===true}
        catch(e){sceneView.message="Room preference not restored · "+String(e)}
    }
    function setRoomPerspective(value){
        roomPerspective=value===true
        if(roomPreferenceStore)try{roomPreferenceStore.writeRoomPerspective(roomPerspective)}
        catch(e){
            var warning="Room preference not saved · "+String(e)
            sceneView.message=warning
            return warning
        }
        return ""
    }
    // View-only motion preference and transition state. Not arrangement data.
    property bool reducedRoomMotion:false
    property var roomNavigation:null
    property real roomProgress:0
    readonly property bool roomNavigating:!!roomNavigation
    readonly property var roomLayers:Transition.layers(roomProgress)
    // Reserve the union of Room and Shelf toolbar controls at any width.
    // Hidden controls still occupy the height calculation, never input.
    function reservedToolbarHeight(flow){
        var used=0,rows=1,children=flow.children
        // QQmlListProperty is indexable, but not an ES iterable on Qt 6.4.
        // Use the native list interface and never rely on for-of here.
        for(var i=0;i<children.length;i++){
            var item=children[i]
            if(!item)continue
            var w=item.width
            if(w<=0)continue
            if(used>0&&used+flow.spacing+w>flow.width){rows++;used=0}
            used+=(used>0?flow.spacing:0)+w
        }
        return rows*26+(rows-1)*flow.spacing
    }
    function roomMapping(id){
        var r=archive.snapshot.spatial.shelves[id].roomId,plan=View.roomPlan(archive.snapshot,r)
        if(!plan)return null
        if(roomPerspective){
            var projected=View.roomPerspective(archive.snapshot,plan,roomPlan.width,roomPlan.height)
            return projected?{frame:projected.frame}:null
        }
        var k=Math.max(.001,Math.min(Math.max(1,roomPlan.width-64)/plan.room.w,Math.max(1,roomPlan.height-100)/plan.room.h))
        return {x:(roomPlan.width-plan.room.w*k)/2,y:(roomPlan.height-plan.room.h*k)/2,scale:k}
    }
    function navigateRoom(id,entering){
        if(!viewSwitchReady||checkpointLoadPending||materialPanel!==""||roomPlan.dragging||!Spatial.physicalProfiles(archive.snapshot)||Spatial.kind(archive.snapshot,id)!=="shelf")return false
        if(showMap||entering&&!showRoomPlan||!entering&&showRoomPlan)return false
        var targetRoom=archive.snapshot.spatial.shelves[id].roomId
        if(entering&&roomPlan.roomId!==targetRoom)return false
        // Nested Cubby and Arrange remain explicit non-animated navigation.
        if(sceneView.mode!=="browse"||!entering&&sceneView.reachableViewPath.length!==1){
            if(entering&&!sceneView.openShelf(id))return false
            if(mapEnabled)activeRoomId=targetRoom
            roomPlanOpen=!entering;sceneView.clearSelection();return true
        }
        var s=archive.snapshot,p=s.spatial.shelves[id],mapping=roomMapping(id)
        if(entering&&roomPlan.roomId!==p.roomId)return false
        if(!mapping)return false
        if(entering&&!sceneView.openShelf(id))return false
        var g=Spatial.shelfGeometry(s,id),destination=View.fitEnvelope(g,sceneView.width,Math.max(1,sceneView.height-42),sceneView.zoom,sceneView.pan)
        var geometry=Transition.capture(s,id,mapping,destination)
        if(!geometry)return false
        if(mapEnabled)activeRoomId=targetRoom
        var palette=paletteFor(id),c=s.cubbies[id]
        roomPlan.selectedShelf=id
        sceneView.clearSelection()
        roomProgress=entering?0:1
        roomNavigation={id:id,name:c.name||id,entering:entering,geometry:geometry,palette:palette,
            frameColor:View.frameColor(c,palette,0),backing:View.backingColor(c,palette,0)}
        if(reducedRoomMotion){finishRoomNavigation();return true}
        navigationOverlay.forceActiveFocus()
        roomAnimation.from=roomProgress;roomAnimation.to=entering?1:0;roomAnimation.start()
        return true
    }
    function finishRoomNavigation(){
        var n=roomNavigation;if(!n)return
        roomAnimation.stop()
        roomProgress=n.entering?1:0
        roomNavigation=null
        roomPlanOpen=!n.entering
        if(roomPlanOpen){roomPlan.selectedShelf=n.id;roomPlan.forceActiveFocus()}
        else sceneView.forceActiveFocus()
    }
    function abortRoomNavigation(){
        if(!roomNavigation)return
        roomAnimation.stop();roomNavigation=null
        // Settle to the current reachable view if the model was reset.
        roomPlanOpen=false;roomProgress=1
    }
    function toggleRoom(){
        traceMapNavigation("toggleRoom entered")
        if(!viewSwitchReady)return
        if(showMap)return
        var id=sceneView.reachableViewPath[0]
        if(mapEnabled&&showRoomPlan){
            id=roomPlan.selectedShelf||(inspectedRoomId===currentRoomId?id:"")
            if(!id)return
        }
        if(!navigateRoom(id,showRoomPlan))return
    }
    onReducedRoomMotionChanged:if(reducedRoomMotion){if(roomNavigating)finishRoomNavigation();if(mapNavigating)finishMapNavigation()}
    NumberAnimation {
        id:roomAnimation;objectName:"room-navigation-animation";target:study;property:"roomProgress";duration:500
        onFinished:study.finishRoomNavigation()
    }
    property var mapDoorEditText:({})
    function startMapDoorEdit(kind,id,patch){
        if(!showMap||!viewSwitchReady||checkpointLoadPending||mapView.dragging||mapView.panning||sceneView.mode!=="arrange")return
        var d=kind==="spatialDoorCreate"?patch:archive.snapshot.spatial.doors[id];if(!d)return
        var cmd={kind:kind,patch:patch||{}};if(kind!=="spatialDoorCreate")cmd.doorId=id
        if(kind==="spatialDoorDelete"){
            if(archive.proposeStructure(cmd)&&archive.applyStructure()){sceneView.message="Opening removed · Undo available";mapView.forceActiveFocus()}
            else {sceneView.message=archive.errorText||"Opening not removed";archive.cancelStructure()}
            return
        }
        var raw={};for(var key of ["start","end"])raw[key]=String(cmd.patch[key]!==undefined?cmd.patch[key]:d[key])
        mapDoorEditText=raw;archive.proposeStructure(cmd);structurePanel.forceActiveFocus()
    }
    function setMapDoorValue(key,value){
        var q=archive.structuralProposal;if(!q||!["spatialDoorCreate","spatialDoorEdit"].includes(q.command.kind))return
        var raw=Object.assign({},mapDoorEditText);raw[key]=value;mapDoorEditText=raw
        var cmd=Core.clone(q.command),n=/^[0-9]+$/.test(value)?Number(value):null
        if(cmd.kind==="spatialDoorEdit"&&n===archive.snapshot.spatial.doors[cmd.doorId][key])delete cmd.patch[key];else cmd.patch[key]=n
        archive.proposeStructure(cmd)
    }
    function chooseMapDoorMerge(id){
        var q=archive.structuralProposal;if(!q||q.command.kind!=="spatialDoorMerge")return
        var cmd=Core.clone(q.command);cmd.patch.otherId=id;archive.proposeStructure(cmd)
    }
    property var mapRoomEditText:({})
    function startMapRoomEdit(kind,id,patch){
        if(mapNavigationDiagnostics)console.log("B8 map arrangement entered",JSON.stringify({kind:kind,id:id,patch:patch,showMap:showMap,ready:viewSwitchReady,checkpoint:checkpointLoadPending,pan:mapView.panning,drag:mapView.dragging,mode:sceneView.mode}))
        if(!showMap||!viewSwitchReady||checkpointLoadPending||(mapView.panning||mapView.dragging)||sceneView.mode!=="arrange")return
        var r=kind==="spatialRoomCreate"?View.mapRoomDraft(mapView.dataModel):archive.snapshot.spatial.rooms[id]
        if(!r)return
        var cmd={kind:kind,patch:kind==="spatialRoomCreate"?r:patch||{}}
        if(kind!=="spatialRoomCreate")cmd.roomId=id
        var raw={};for(var key of ["name","x","y","w","h"])raw[key]=String(cmd.patch[key]!==undefined?cmd.patch[key]:r[key])
        mapRoomEditText=raw;archive.proposeStructure(cmd);structurePanel.forceActiveFocus()
        if(mapNavigationDiagnostics)console.log("B8 map arrangement proposed",JSON.stringify({command:cmd,ok:!!archive.structuralProposal&&archive.structuralProposal.ok,error:archive.structuralProposal?archive.structuralProposal.error:"No proposal"}))
    }
    function setMapRoomValue(key,value){
        var q=archive.structuralProposal;if(!q||!["spatialRoomCreate","spatialRoomEdit"].includes(q.command.kind))return
        var raw=Object.assign({},mapRoomEditText);raw[key]=value;mapRoomEditText=raw
        var cmd=Core.clone(q.command);delete cmd.removeDoors
        var n=key==="name"?value:/^-?[0-9]+$/.test(value)?Number(value):null
        if(cmd.kind==="spatialRoomEdit"&&n===archive.snapshot.spatial.rooms[cmd.roomId][key])delete cmd.patch[key]
        else cmd.patch[key]=n
        archive.proposeStructure(cmd)
    }
    function acknowledgeMapRoomDoors(){
        var q=archive.structuralProposal;if(!q||!["spatialRoomEdit","spatialRoomDelete"].includes(q.command.kind))return
        var cmd=Core.clone(q.command),lost=View.mapRoomLostDoors(archive.snapshot,cmd);if(!lost.length)return
        if(cmd.removeDoors)delete cmd.removeDoors;else cmd.removeDoors=lost
        archive.proposeStructure(cmd)
    }
    property var roomEditText:({})
    function startRoomShelfEdit(id,patch){
        if(!viewSwitchReady||roomPlan.dragging||!roomPlan.arranging)return
        var p=archive.snapshot.spatial.shelves[id],c=archive.snapshot.cubbies[id],raw={}
        if(!p||!c)return
        for(var key of ["x","y","w","h","depth"])raw[key]=String(patch[key]!==undefined?patch[key]:key==="w"||key==="h"?c[key]:p[key])
        roomEditText=raw
        archive.proposeStructure({kind:"spatialShelfEdit",containerId:id,patch:patch})
        structurePanel.forceActiveFocus()
    }
    function setRoomShelfValue(key,value){
        var q=archive.structuralProposal
        if(!q||q.command.kind!=="spatialShelfEdit")return
        var raw=Object.assign({},roomEditText);raw[key]=value;roomEditText=raw
        var cmd=Core.clone(q.command),p=archive.snapshot.spatial.shelves[cmd.containerId],c=archive.snapshot.cubbies[cmd.containerId]
        var original=key==="w"||key==="h"?c[key]:p[key]
        var n=/^-?[0-9]+$/.test(value)?Number(value):null
        if(value===String(original)||n===original)delete cmd.patch[key]
        else cmd.patch[key]=n
        archive.proposeStructure(cmd)
    }
    readonly property bool showRoomPlan:!showMap&&roomPlanOpen&&Spatial.physicalProfiles(archive.snapshot)
    readonly property bool viewSwitchReady:!roomNavigating&&!mapNavigating&&!sceneView.busy&&!sceneView.pointer&&!sceneView.prepared&&!sceneView.furnitureDrag&&!sceneView.bookDrag&&!archive.draft&&!archive.structuralProposal&&!contextOpen&&!bookPicker
    // Optional isolated study adapter, injected by the standalone window.
    // No filesystem dependency in the shared scene or model.
    property var checkpointStore:null
    property bool checkpointLoadPending:false
    readonly property bool checkpointReady:!roomNavigating&&!mapNavigating&&!mapView.press&&!mapView.appearanceOpen&&!!checkpointStore&&!archive.draft&&!archive.structuralProposal&&
        !sceneView.busy&&!sceneView.pointer&&!sceneView.furnitureDrag&&!sceneView.bookDrag&&!sceneView.prepared&&!study.contextOpen&&!study.bookPicker&&!roomPlan.dragging&&!(mapView.panning||mapView.dragging)
    onCheckpointReadyChanged:if(!checkpointReady)checkpointLoadPending=false
    function checkpointView(){
        // Prune deleted cubby cameras and capture the currently open camera
        // without modifying the live view or creating an Undo entry.
        var cameras=View.copyCameras({})
        for(var id of Object.keys(sceneView.cameras))if(Object.prototype.hasOwnProperty.call(archive.snapshot.cubbies,id))cameras[id]=Core.clone(sceneView.cameras[id])
        cameras[sceneView.cubbyId]={zoom:sceneView.zoom,x:sceneView.pan.x,y:sceneView.pan.y}
        var view={path:sceneView.reachableViewPath.slice(),theme:Themes.Theme.index,cameras:cameras,
            cubbyPreviewMode:sceneView.cubbyPreviewMode,snapEnabled:sceneView.snapEnabled,
            showGrid:sceneView.showGrid,snapDistance:sceneView.snapDistance,roomPerspective:study.roomPerspective}
        if(mapEnabled&&Spatial.physicalProfiles(archive.snapshot)){
            var m=mapView.savedView();m.layer=showMap?"map":showRoomPlan?"room":"shelf";m.roomId=currentRoomId||"";m.roomShelf=showRoomPlan?roomPlan.selectedShelf:""
            if(m.selectedDoor){var d=archive.snapshot.spatial.doors[m.selectedDoor];if(!d||![d.a.roomId,d.b.roomId].includes(m.selectedRoom))m.selectedDoor=""}
            if(m.roomShelf&&(!archive.snapshot.spatial.shelves[m.roomShelf]||archive.snapshot.spatial.shelves[m.roomShelf].roomId!==m.roomId))m.roomShelf=""
            view.mapView=m
        }
        return view
    }
    function saveCheckpoint(){
        if(!checkpointReady)return false
        checkpointLoadPending=false
        var payload=archive.exportCheckpoint(checkpointView())
        if(!payload){sceneView.message="Checkpoint not saved · "+archive.checkpointError;return false}
        try{
            checkpointStore.write(payload)
            sceneView.message="Study checkpoint saved"
            return true
        }catch(e){sceneView.message="Checkpoint not saved · "+String(e);return false}
    }
    function requestCheckpointLoad(){
        if(!checkpointReady)return false
        checkpointLoadPending=true
        loadCancel.forceActiveFocus()
        sceneView.message="Load replaces the current arrangement and clears Undo history."
        return true
    }
    function cancelCheckpointLoad(){
        checkpointLoadPending=false
        focusActiveLayer()
        sceneView.message="Checkpoint load canceled"
    }
    function loadCheckpoint(){
        if(!checkpointReady||!checkpointLoadPending)return false
        checkpointLoadPending=false
        try{
            var payload=checkpointStore.read()
            if(payload===null){sceneView.message="No saved study checkpoint";focusActiveLayer();return false}
            // Import validates the complete envelope before replacing anything.
            var view=archive.importCheckpoint(payload)
            if(!view){sceneView.message="Checkpoint not loaded · "+archive.checkpointError;focusActiveLayer();return false}
            closeContext();closeMaterials();rackInspector=false;pickId=""
            sceneView.mode="browse"
            sceneView.viewPath=view.path.slice()
            sceneView.cameras=View.copyCameras(view.cameras)
            sceneView.restoreCamera()
            Themes.Theme.index=view.theme
            var preferenceWarning=study.setRoomPerspective(view.roomPerspective===true)
            sceneView.cubbyPreviewMode=view.cubbyPreviewMode||"veiled"
            sceneView.snapEnabled=view.snapEnabled===true
            sceneView.showGrid=view.showGrid===true
            sceneView.snapDistance=view.snapDistance===undefined?20:view.snapDistance
            sceneView.clearSelection()
            if(mapEnabled&&view.mapView){
                var m=view.mapView;mapView.restoreView(m);activeRoomId=m.layer==="shelf"?"":m.roomId;mapOpen=m.layer==="map";roomPlanOpen=m.layer==="room"
                if(roomPlanOpen)roomPlan.selectedShelf=m.roomShelf
            }
            focusActiveLayer()
            sceneView.message="Study checkpoint loaded"+(preferenceWarning?" · "+preferenceWarning:"")
            return true
        }catch(e){sceneView.message="Checkpoint not loaded · "+String(e);focusActiveLayer();return false}
    }
    // Resolved material roles are separate from semantic theme colors.
    readonly property var materialProposal:archive.structuralProposal&&archive.structuralProposal.command.kind==="materialBatch"?archive.structuralProposal:null
    readonly property var materialSnapshot:materialProposal&&materialProposal.snapshot?materialProposal.snapshot:archive.snapshot
    readonly property var shelfAppearanceProposal:archive.structuralProposal&&archive.structuralProposal.command.kind==="spatialAppearance"&&archive.structuralProposal.ok?archive.structuralProposal:null
    readonly property var sceneAppearanceSnapshot:shelfAppearanceProposal?shelfAppearanceProposal.snapshot:materialProposal?materialSnapshot:null
    readonly property var appearanceColors: View.appearancePalette(colors,materialSnapshot.materials)
    function paletteFor(id){
        var s=sceneAppearanceSnapshot||materialSnapshot
        return spatialEnabled&&Spatial.enabled(s)&&Object.prototype.hasOwnProperty.call(s.cubbies,id)?View.spatialPalette(s,id,Themes.Theme.palettes,Themes.Theme.index):appearanceColors
    }
    readonly property var sceneColors:paletteFor(sceneView.cubbyId)
    readonly property var localMaterialColors:materialCubby?paletteFor(materialCubby.id):sceneColors
    property string materialPanel: ""
    property string materialTarget: ""
    property string materialNotice: ""
    property string materialPickerRole:""
    function toggleMaterialPicker(role){
        materialPickerRole=materialPickerRole===role?"":role
        materialScroll.resetPosition()
    }
    readonly property var materialPreferences: materialSnapshot.materials||{scheme:"balanced",roleEdits:{}}
    function openMaterials(kind){
        if(!structureReady)return
        materialTarget=sceneView.selectedModuleId
        closeContext()
        materialNotice=""
        materialPickerRole=""
        // An empty proposal locks competing structural, motion, Undo and
        // checkpoint operations even before the first color choice.
        archive.proposeStructure({kind:"materialBatch",cubbyId:sceneView.cubbyId,edits:[]})
        materialPanel=kind
        materialScroll.resetPosition()
        materialInspector.forceActiveFocus()
    }
    function closeMaterials(){
        materialPanel="";materialTarget="";materialNotice="";materialPickerRole=""
        if(materialProposal)archive.cancelStructure()
        sceneView.forceActiveFocus()
    }
    function applyMaterials(){
        if(!materialProposal||!materialProposal.ok)return
        if(archive.applyStructure())closeMaterials()
        else materialNotice=archive.errorText
    }
    function materialEdit(command){
        if(sceneView.busy||archive.draft||!materialProposal||materialProposal.revision!==archive.archiveState.revision)return false
        var batch=Core.clone(materialProposal.command),edits=batch.edits,last=edits.length?edits[edits.length-1]:null
        // Coalesce consecutive adjustments of one swatch (including drag
        // samples), preserving preset-switch/reset ordering.
        if(last&&last.kind===command.kind&&last.cubbyId===command.cubbyId&&last.moduleId===command.moduleId&&
           Object.keys(last.patch).sort().join(",")===Object.keys(command.patch).sort().join(",")&&
           last.patch.theme===command.patch.theme&&last.patch.role===command.patch.role)
            edits[edits.length-1]=command
        else edits.push(command)
        var next=Core.previewStructure(archive.archiveState,batch)
        if(next.error){materialNotice=next.error;return false}
        archive.structuralProposal=next
        materialNotice=next.ok?"Preview · Apply to keep changes":"No changes"
        return true
    }
    function setMaterialScheme(s){materialEdit({kind:"materials",cubbyId:sceneView.cubbyId,patch:{scheme:s}})}
    function setRoleColor(role,color){materialEdit({kind:"materials",cubbyId:sceneView.cubbyId,patch:{theme:colors.name,role:role,color:color}})}
    function resetRoleColors(){materialEdit({kind:"materials",cubbyId:sceneView.cubbyId,patch:{theme:colors.name,reset:true}})}
    readonly property var materialFixture:materialSnapshot.cubbies[sceneView.cubbyId].mods.find(function(m){return m.id===materialTarget})||null
    readonly property var materialCubby:materialFixture&&materialFixture.type==="cubby"?materialSnapshot.cubbies[materialFixture.childId]:materialSnapshot.cubbies[sceneView.cubbyId]
    readonly property int materialDepth:Math.max(0,sceneView.viewPath.length-1)+(materialFixture&&materialFixture.type==="cubby"?1:0)
    function setLocalColor(role,color){
        var m=materialFixture,p={}
        if(materialPanel==="cubby"){p[role]=color;materialEdit({kind:"cubby",cubbyId:materialCubby.id,patch:p})}
        else if(m){materialEdit({kind:m.type==="rack"?"rackColor":"shelf",cubbyId:sceneView.cubbyId,moduleId:m.id,patch:{color:color}})}
    }
    color: colors.background
    readonly property alias controller: archive
    readonly property alias scene: sceneView
    property string pickId: ""
    property bool rackInspector:false
    function openRackInspector(){
        if(!selectedRack||!structureReady)return
        // Opening is a distinct action from dismissing the menu. Do not
        // transfer focus back through the scene between these two panels.
        contextOpen=false
        rackInspector=true
        rackHeader.forceLayout()
        rackScroll.resetPosition()
        radiusSlider.forceActiveFocus()
    }
    function closeRackInspector(){
        if(archive.draft)archive.cancel()
        rackInspector=false
        pickId=""
        sceneView.forceActiveFocus()
    }
    property bool contextOpen:false
    property point contextPoint:Qt.point(0,0)
    function closeContext(){contextOpen=false;bookPicker=false;bookTarget=null;sceneView.forceActiveFocus()}
    function openContext(x,y){
        closeMaterials();rackInspector=false;bookPicker=false;bookPage=0
        contextPoint=sceneView.mapToItem(study,x,y)
        contextOpen=true
        // Explicitly polish the positioner before exposing its hit targets.
        contextRows.forceLayout()
        contextScroll.resetPosition()
        contextMenu.forceActiveFocus()
    }
    property var retainedReview: []
    property string retainedShape: ""
    Connections {
        target:archive
        function onSnapshotChanged(){
            study.abortRoomNavigation();study.abortMapNavigation()
            if(archive.resetting){study.roomPlanOpen=false;study.roomPerspective=false;study.resetMapView()}
            if(!Spatial.physicalProfiles(archive.snapshot)){study.roomPlanOpen=false;study.resetMapView()}
            else if(study.activeRoomId&&!Object.prototype.hasOwnProperty.call(archive.snapshot.spatial.rooms,study.activeRoomId)){
                study.activeRoomId=""
                if(study.showRoomPlan){study.roomPlanOpen=false;study.mapOpen=study.mapEnabled}
            }
        }
        function onStructuralProposalChanged(){
            study.structureApplyError=""
            if(study.materialPanel!==""&&!study.materialProposal)study.closeMaterials()
        }
        function onDraftChanged(){
            if(!archive.draft){
                // Only a real pending rack edit ending closes its inspector.
                // An idle binding notification or obsolete worker reply must
                // not close a newly opened inspector before the first edit.
                var wasEditing=study.retainedShape!==""
                study.retainedReview=[];study.retainedShape=""
                if(wasEditing)study.rackInspector=false
                return
            }
            var d=archive.draft,p=d.proposed,shape=[d.rackId,p.w,p.h,p.r].join("|")
            if(shape!==study.retainedShape){study.retainedReview=[];study.retainedShape=shape}
            if(d.result)study.retainedReview=d.result.review||[]
        }
    }
    readonly property var selectedRack: Core.rackAt(archive.snapshot,sceneView.cubbyId,sceneView.selectedModuleId)
    readonly property var review: archive.draft&&archive.draft.result?archive.draft.result.review||[]:retainedReview
    property int reviewIndex: 0
    readonly property var selectedMeta:selectedRack&&sceneView.selectedCell?selectedRack.cellMeta[sceneView.selectedCell]:null
    readonly property var activeIssue: review.length?review[Math.min(reviewIndex,review.length-1)]:null

    Archive.ArchiveModel { id:archive; spatialEnabled:study.spatialEnabled; physicalProfilesEnabled:study.physicalProfilesEnabled; independentProfilesEnabled:study.physicalProfilesEnabled; Component.onCompleted: reset(study.initialSnapshot||View.fixture()) }
    function edit(patch) {
        if(!selectedRack||sceneView.busy)return
        pickId="";reviewIndex=0;retainedReview=[]
        archive.stage(sceneView.cubbyId,selectedRack.id,patch)
    }
    function chooseCell(key) {
        if(!pickId||!activeIssue)return
        if(activeIssue.options.indexOf(key)<0&&key!==activeIssue.key)return
        var old=archive.draft.decisions[pickId]
        archive.choose(pickId,key===activeIssue.key||old===key?"":key)
        pickId=""
    }
    function switchMode(value) {
        if(roomNavigating||mapNavigating||sceneView.busy||roomPlan.dragging||mapView.dragging||mapView.panning||mapView.appearanceOpen)return
        if(archive.draft||archive.structuralProposal)archive.cancel()
        closeContext();closeMaterials();rackInspector=false;pickId="";sceneView.mode=value
    }

    readonly property var selectedFixture: sceneView.cubby.mods.find(function(m){return m.id===sceneView.selectedModuleId})||null
    readonly property bool structureReady: sceneView.mode==="arrange"&&!sceneView.busy&&!sceneView.pointer&&!sceneView.furnitureDrag&&!sceneView.bookDrag&&!archive.draft&&!archive.structuralProposal
    readonly property bool selectedSupport:!!selectedFixture&&Mixed.supportsTop(selectedFixture)
    property bool bookPicker:false
    property int bookPage:0
    property var bookChoices:[]
    property var bookTarget:null
    function beginBookPicker(){
        if(!structureReady||!spatialEnabled||!selectedSupport)return
        // Freeze catalogue and target for this presentation. Never insert
        // transient rows into the scrolling furniture context.
        bookTarget={revision:archive.archiveState.revision,containerId:sceneView.cubbyId,moduleId:selectedFixture.id}
        bookChoices=Object.values(archive.snapshot.spatial.apps||{}).sort((a,b)=>a.title.localeCompare(b.title)||a.appId.localeCompare(b.appId))
        bookPage=0;contextOpen=false;bookPicker=true
        bookPickerPanel.forceActiveFocus()
    }
    function chooseBook(appId){
        if(!bookPicker||!bookTarget||!structureReady||!selectedSupport||
           bookTarget.revision!==archive.archiveState.revision||
           bookTarget.containerId!==sceneView.cubbyId||bookTarget.moduleId!==selectedFixture.id||
           !bookChoices.some(a=>a.appId===appId)){
            closeContext();sceneView.message="Book placement target changed; reopen the picker";return
        }
        startBook(appId,false)
    }
    property string bookPositionText:""
    property string structureApplyError:""
    property int structureApplyAttempts:0
    function startBook(appId,remove){
        if(!structureReady||!spatialEnabled||!selectedSupport)return
        var m=selectedFixture,c=sceneView.cubby,existing=(m.items||[]).find(e=>e.kind==="app"&&e.appId===appId)
        if(remove&&!existing)return
        var x=existing?existing.x:Mixed.suggestBookX(c,m,appId)
        bookPositionText=String(x===null?21:x)
        closeContext()
        archive.proposeStructure(remove?{kind:"spatialAppUnplace",appId:appId}:
            {kind:"spatialAppPlace",appId:appId,containerId:c.id,moduleId:m.id,patch:{x:x===null?21:x}})
        structurePanel.forceActiveFocus()
    }
    function setBookPosition(value){
        var q=archive.structuralProposal
        if(!q||q.command.kind!=="spatialAppPlace")return
        bookPositionText=value
        var cmd=Core.clone(q.command)
        // Preserve incomplete/invalid text. Model rejects null/out of bounds.
        cmd.patch.x=/^[0-9]+(?:\.[0-9]+)?$/.test(value)?Number(value):null
        archive.proposeStructure(cmd)
    }
    function stepBook(delta){
        var q=archive.structuralProposal
        if(!q||q.command.kind!=="spatialAppPlace")return
        setBookPosition(String((Number.isFinite(q.command.patch.x)?q.command.patch.x:21)+delta))
    }
    function confirmStructure(){
        structureApplyAttempts++
        structureApplyError=""
        var oldRooms=structurePanel.mapRoomCommand?Object.keys(archive.snapshot.spatial.rooms):[]
        var created=structurePanel.mapRoomCommand&&structurePanel.cmd.kind==="spatialRoomCreate"
        var doorCreated=structurePanel.mapDoorCommand&&structurePanel.cmd.kind==="spatialDoorCreate"
        var oldDoors=doorCreated?Object.keys(archive.snapshot.spatial.doors||{}):[]
        if(archive.applyStructure()){
            if(doorCreated){var doorId=Object.keys(archive.snapshot.spatial.doors||{}).find(id=>!oldDoors.includes(id));if(doorId)mapView.selectDoor(doorId)}
            if(created)mapView.selectedRoom=Object.keys(archive.snapshot.spatial.rooms).find(id=>!oldRooms.includes(id))||""
            sceneView.message="Arrangement updated · Undo available";sceneView.clearSelection()
            return true
        }
        structureApplyError=archive.errorText||"Unable to apply this preview"
        return false
    }
    function toggleTop(){
        if(!structureReady||!spatialEnabled||!selectedFixture||!["rack","cubby"].includes(selectedFixture.type))return
        var m=selectedFixture;closeContext()
        archive.proposeStructure({kind:"spatialSupport",containerId:sceneView.cubbyId,moduleId:m.id,patch:{enabled:m.flatTop!==true}})
        structurePanel.forceActiveFocus()
    }
    function startShelfAppearance(){
        if(!structureReady||!spatialEnabled||Spatial.kind(archive.snapshot,sceneView.cubbyId)!=="shelf")return
        var id=sceneView.cubbyId
        closeContext()
        archive.proposeStructure({kind:"spatialAppearance",containerId:id,patch:{profile:Spatial.shelfProfile(archive.snapshot,id)}})
        structurePanel.forceActiveFocus()
    }
    function setShelfAppearance(key,value){
        var q=archive.structuralProposal
        if(!q||q.command.kind!=="spatialAppearance")return
        var cmd=Core.clone(q.command);cmd.patch[key]=value
        archive.proposeStructure(cmd)
    }
    function startShelfRemoval(){
        if(!structureReady||!spatialEnabled||Spatial.kind(archive.snapshot,sceneView.cubbyId)!=="shelf")return
        closeContext()
        archive.proposeStructure({kind:"spatialShelfDelete",containerId:sceneView.cubbyId})
        structurePanel.forceActiveFocus()
    }
    function startFixture(type) {
        if(!structureReady)return
        var c=sceneView.cubby,sizes={shelf:{w:280,h:15},rack:{w:430,h:300},cubby:{w:210,h:150},artwork:{w:160,h:120}}
        var minimum={shelf:[120,15],rack:[180,160],cubby:[130,100],artwork:[80,60]}[type],size=sizes[type]
        var w=Math.min(size.w,c.w),h=Math.min(size.h,c.h)
        var step=sceneView.snapEnabled?sceneView.snapDistance:20
        var p={x:0,y:Math.max(0,c.h-h),w:w,h:h}
        if(type==="rack")p.r=64
        if(type==="artwork")p.profile="bronze"
        var found=false
        for(var attempt=0;attempt<2&&!found;attempt++){
            var ww=attempt?minimum[0]:w,hh=attempt?minimum[1]:h
            if(sceneView.snapEnabled){ww=Math.ceil(ww/step)*step;if(type!=="shelf")hh=Math.ceil(hh/step)*step}
            for(var y=Math.floor((c.h-hh)/step)*step;y>=0&&!found;y-=step)for(var x=0;x<=c.w-ww&&!found;x+=step){
                var box={x:x,y:y,w:ww+(type==="artwork"?Math.min(10,Math.max(3,ww*.055)):0),h:hh}
                if(box.x+box.w<=c.w&&!c.mods.some(m=>Mixed.fixtureRects(m).some(b=>Mixed.overlap(box,b)))){p.x=x;p.y=y;p.w=ww;p.h=hh;found=true}
            }
        }
        sceneView.clearSelection()
        archive.proposeStructure({kind:"create",type:type,cubbyId:c.id,patch:p})
    }
    function startShelf(){startFixture("shelf")}
    readonly property var selectedHolder:selectedSupport?(selectedFixture.items||[]).find(e=>e.kind==="holder"&&e.id===sceneView.selectedHolderId)||null:null
    function startHolder(kind){
        if(!structureReady||!selectedSupport)return
        var m=selectedFixture,h=selectedHolder
        if(kind!=="holderCreate"&&!h)return
        var p=kind==="holderCreate"?Mixed.newHolderPatch(sceneView.cubby,m,sceneView.snapEnabled?sceneView.snapDistance:10):{x:h.x,w:h.w,count:h.slots.length}
        closeContext()
        archive.proposeStructure({kind:kind,cubbyId:sceneView.cubbyId,moduleId:m.id,holderId:h?h.id:"",patch:p})
    }
    function startArtworkEdit(){
        if(!structureReady||!selectedFixture||selectedFixture.type!=="artwork")return
        var m=selectedFixture
        closeContext()
        archive.proposeStructure({kind:"artwork",cubbyId:sceneView.cubbyId,moduleId:m.id,patch:{x:m.x,y:m.y,w:m.w,h:m.h,profile:m.profile}})
    }
    function setFrameProfile(profile){
        var q=archive.structuralProposal
        if(!q)return
        var cmd=Core.clone(q.command);cmd.patch.profile=profile;archive.proposeStructure(cmd)
    }
    function startShelfEdit() {
        if(!structureReady||!selectedFixture||selectedFixture.type!=="shelf")return
        var m=selectedFixture
        archive.proposeStructure({kind:"shelf",cubbyId:sceneView.cubbyId,moduleId:m.id,patch:{x:m.x,y:m.y,w:m.w,color:m.color||null}})
    }
    function startChildEdit(){
        if(!structureReady||!selectedFixture||selectedFixture.type!=="cubby")return
        var m=selectedFixture
        archive.proposeStructure({kind:"child",cubbyId:sceneView.cubbyId,moduleId:m.id,patch:{x:m.x,y:m.y,w:m.w,h:m.h}})
    }
    property real cubbyRatio:0
    function startCubbyEdit(){
        if(!structureReady||selectedFixture&&selectedFixture.type!=="cubby")return
        var c=selectedFixture?archive.snapshot.cubbies[selectedFixture.childId]:sceneView.cubby
        cubbyRatio=0
        closeContext()
        archive.proposeStructure({kind:"cubby",cubbyId:c.id,patch:{name:c.name||c.id,w:c.w,h:c.h,b:c.b||11}})
        structurePanel.forceActiveFocus()
    }
    function toggleCubbyRatio(){
        if(cubbyRatio>0){cubbyRatio=0;return}
        var p=archive.structuralProposal.command.patch
        if(p.w>0&&p.h>0)cubbyRatio=p.w/p.h
    }
    function editCubbyValue(key,value){
        var q=archive.structuralProposal
        if(!q||q.command.kind!=="cubby")return
        var cmd=Core.clone(q.command)
        if(key==="name")cmd.patch.name=value
        else {
            cmd.patch=Core.cubbyDimensionPatch(cmd.patch,key,value,cubbyRatio>0?cubbyRatio:null)
            // A new size must receive a new explicit suggestion request.
            if(key==="w"||key==="h")delete cmd.rearrange
        }
        archive.proposeStructure(cmd)
    }
    function toggleCubbySuggestion(){
        var q=archive.structuralProposal
        if(!q||q.command.kind!=="cubby")return
        var cmd=Core.clone(q.command)
        if(cmd.rearrange===true)delete cmd.rearrange
        else cmd.rearrange=true
        archive.proposeStructure(cmd)
    }
    function toggleShelfSuggestion(){
        var q=archive.structuralProposal
        if(!q||q.command.kind!=="shelf")return
        var cmd=Core.clone(q.command)
        if(cmd.rearrange===true)delete cmd.rearrange;else cmd.rearrange=true
        archive.proposeStructure(cmd)
    }
    function startDelete() {
        if(!structureReady||!selectedFixture)return
        archive.proposeStructure({kind:"delete",cubbyId:sceneView.cubbyId,moduleId:selectedFixture.id})
    }
    function structuralStep(key,delta) {
        if(!archive.structuralProposal||!archive.structuralProposal.command.patch)return
        var q=Core.clone(archive.structuralProposal.command)
        var holder=["holderCreate","holderEdit"].includes(q.kind),art=q.kind==="artwork"||q.type==="artwork"
        var min=key==="count"?1:key==="w"?(holder?90:art?40:120):key==="h"?(art?40:15):0
        var next=q.patch[key]+(key==="count"?Math.sign(delta):delta)
        if(sceneView.snapEnabled&&key!=="count"){
            if(holder&&key==="w")next=sceneView.quantize(q.patch.x+next)-q.patch.x
            else
            if(key==="w"||key==="h"){var origin=q.patch[key==="w"?"x":"y"];next=sceneView.quantize(origin+next)-origin}
            else next=sceneView.quantize(next)
        }
        q.patch[key]=Math.max(min,key==="count"?Math.min(48,next):next)
        if(q.kind==="shelf")delete q.rearrange
        archive.proposeStructure(q)
    }

    Column {
        id:heading
        enabled:!study.roomNavigating&&!study.mapNavigating&&!roomPlan.dragging&&!(mapView.panning||mapView.dragging)&&study.materialPanel===""&&!archive.structuralProposal&&!study.checkpointLoadPending&&!study.bookPicker&&!sceneView.bookDrag
        anchors.top:parent.top
        anchors.left:parent.left
        anchors.right:parent.right
        anchors.margins:10
        spacing:6
        // A fixed explicit header extent in the physical study; do not let
        // a positioner's implicitHeight or delayed polish refit the camera.
        height:Spatial.physicalProfiles(archive.snapshot)?
            headingTitle.height+primarySlot.height+(rootTools.visible?rootTools.height:0)+pathTools.height+(rootTools.visible?3:2)*spacing:implicitHeight
        Text {
            id:headingTitle
            color:study.colors.text; font.pixelSize:15
            text:study.showMap?"Astral Archive · Map Room":study.spatialEnabled?"Astral Archive · Native Shelf study":"Astral Archive · Native cubby study"
        }
        Item {
            id:primarySlot
            objectName:"archive-primary-slot"
            width:parent.width
            height:Spatial.physicalProfiles(archive.snapshot)?study.reservedToolbarHeight(primaryTools):primaryTools.implicitHeight
            Flow {
            id:primaryTools
            // In the opt-in atlas, keep layer-dependent slots in the Flow.
            // A hidden button must not leave its old hit rectangle available
            // to a newly visible neighbor before the next positioner polish.
            objectName:"archive-primary-tools"
            width:parent.width; spacing:5
            height:primarySlot.height
            Archive.ArchiveButton { colors:study.colors; label:"Browse"; active:sceneView.mode==="browse"; onClicked:study.switchMode("browse") }
            Archive.ArchiveButton { colors:study.colors; label:"Arrange"; active:sceneView.mode==="arrange"; onClicked:study.switchMode("arrange") }
            Item {
                objectName:"archive-layer-tool-slot"
                readonly property bool layerShown:!study.upperView
                width:backTool.width;height:backTool.height
                visible:study.mapEnabled||layerShown
                enabled:layerShown
                Archive.ArchiveButton {id:backTool; colors:study.colors; label:"Back"; visible:parent.layerShown; enabled:!archive.draft&&(sceneView.viewPath.length>1||Spatial.physicalProfiles(archive.snapshot)&&study.viewSwitchReady); onClicked:if(sceneView.viewPath.length>1)sceneView.back();else study.toggleRoom() }
            }
            Item {
                objectName:"archive-layer-tool-slot"
                readonly property bool layerShown:!study.upperView
                width:enterTool.width;height:enterTool.height
                visible:study.mapEnabled||layerShown
                enabled:layerShown
                Archive.ArchiveButton {id:enterTool; colors:study.colors; label:"Enter"; visible:parent.layerShown; enabled:!archive.draft&&sceneView.cubby.mods.some(function(m){return m.id===sceneView.selectedModuleId&&m.type==="cubby"}); onClicked:sceneView.enterSelected() }
            }
            Item {
                objectName:"archive-layer-tool-slot"
                readonly property bool layerShown:!study.upperView
                width:zoomOutTool.width;height:zoomOutTool.height
                visible:study.mapEnabled||layerShown
                enabled:layerShown
                Archive.ArchiveButton {id:zoomOutTool; colors:study.colors; label:"−"; hint:"Zoom out"; visible:parent.layerShown; onClicked:sceneView.setZoom(sceneView.zoom/1.15) }
            }
            Item {
                objectName:"archive-layer-tool-slot"
                readonly property bool layerShown:!study.upperView
                width:zoomResetTool.width;height:zoomResetTool.height
                visible:study.mapEnabled||layerShown
                enabled:layerShown
                Archive.ArchiveButton {id:zoomResetTool; colors:study.colors; label:Math.round(sceneView.zoom*100)+"%"; width:58; visible:parent.layerShown; hint:"Reset camera"; onClicked:{sceneView.setZoom(1);sceneView.pan=Qt.point(0,0)} }
            }
            Item {
                objectName:"archive-layer-tool-slot"
                readonly property bool layerShown:!study.upperView
                width:zoomInTool.width;height:zoomInTool.height
                visible:study.mapEnabled||layerShown
                enabled:layerShown
                Archive.ArchiveButton {id:zoomInTool; colors:study.colors; label:"+"; hint:"Zoom in"; visible:parent.layerShown; onClicked:sceneView.setZoom(sceneView.zoom*1.15) }
            }
            Archive.ArchiveButton { colors:study.colors; label:study.colors.name; onClicked:Themes.Theme.index=(Themes.Theme.index+1)%3 }
            Archive.ArchiveButton { colors:study.colors; label:"Undo"; enabled:!sceneView.busy&&!archive.draft&&!archive.structuralProposal&&archive.archiveState.history.length>0; onClicked:archive.undo() }
            Archive.ArchiveButton {
                objectName:Spatial.physicalProfiles(archive.snapshot)?"adopt-independent-profiles":"adopt-physical-profiles"
                colors:study.colors;label:Spatial.physicalProfiles(archive.snapshot)?"Adopt refined profiles…":"Adopt physical profiles…";width:154
                visible:study.physicalProfilesEnabled&&!Spatial.independentProfiles(archive.snapshot);enabled:study.viewSwitchReady
                onClicked:archive.proposeStructure({kind:Spatial.physicalProfiles(archive.snapshot)?"spatialAdoptIndependentProfiles":"spatialAdoptProfiles"})
            }
            Item {
                objectName:"archive-layer-tool-slot"
                readonly property bool layerShown:Spatial.physicalProfiles(archive.snapshot)&&!study.showMap
                width:roomPlanTool.width;height:roomPlanTool.height
                visible:study.mapEnabled||layerShown
                enabled:layerShown
                Archive.ArchiveButton {id:roomPlanTool;objectName:"toggle-room-plan";colors:study.colors;label:study.showRoomPlan?"Return to Shelf":"Room plan";width:112;visible:parent.layerShown;enabled:study.viewSwitchReady&&(!study.mapEnabled||!study.showRoomPlan||!!roomPlan.selectedShelf||study.inspectedRoomId===study.currentRoomId);onClicked:study.toggleRoom()}
            }
            Item {
                objectName:"archive-layer-tool-slot"
                readonly property bool layerShown:study.mapEnabled&&Spatial.physicalProfiles(archive.snapshot)&&!study.showMap
                width:mapRoomTool.width;height:mapRoomTool.height
                visible:study.mapEnabled||layerShown
                enabled:layerShown
                Archive.ArchiveButton {id:mapRoomTool;objectName:"open-map-room";colors:study.colors;label:"Map Room";width:study.mapEnabled?96:0;visible:parent.layerShown;enabled:study.viewSwitchReady;onClicked:study.openMap()}
            }
            Archive.ArchiveButton {objectName:"room-reduced-motion";colors:study.colors;label:study.reducedRoomMotion?"Motion reduced":"Room motion";width:112;active:study.reducedRoomMotion;visible:Spatial.physicalProfiles(archive.snapshot);onClicked:study.reducedRoomMotion=!study.reducedRoomMotion}
            Item {
                objectName:"archive-layer-tool-slot"
                readonly property bool layerShown:study.showRoomPlan
                width:perspectiveTool.width;height:perspectiveTool.height
                visible:study.mapEnabled||layerShown
                enabled:layerShown
                Archive.ArchiveButton {id:perspectiveTool;objectName:"toggle-room-perspective";colors:study.colors;label:study.roomPerspective?"Plan":"Perspective";width:90;visible:parent.layerShown;enabled:study.viewSwitchReady;onClicked:study.setRoomPerspective(!study.roomPerspective)}
            }
            Item {
                objectName:"archive-layer-tool-slot"
                readonly property bool layerShown:sceneView.mode==="arrange"&&!study.upperView
                width:arrangeTool.width;height:arrangeTool.height
                visible:study.mapEnabled||layerShown
                enabled:layerShown
                Archive.ArchiveButton {id:arrangeTool;objectName:"arrange-menu";colors:study.colors;label:"Arrange menu";visible:parent.layerShown;enabled:study.structureReady;onClicked:study.openContext(12,12)}
            }
            Archive.ArchiveButton {objectName:"checkpoint-save";colors:study.colors;label:"Save checkpoint";visible:!!study.checkpointStore;enabled:study.checkpointReady&&!study.checkpointLoadPending;onClicked:study.saveCheckpoint()}
            Archive.ArchiveButton {objectName:"checkpoint-load";colors:study.colors;label:"Load checkpoint";visible:!!study.checkpointStore;enabled:study.checkpointReady;onClicked:study.requestCheckpointLoad()}
            }
        }
        Flow {
            id:rootTools
            visible:study.spatialEnabled
            opacity:study.mapEnabled&&study.upperView?0:1
            enabled:!study.mapEnabled||!study.upperView
            width:parent.width;spacing:5
            Repeater {
                model:study.spatialEnabled?sceneView.shelfRoots:[]
                Archive.ArchiveButton {
                    required property var modelData
                    objectName:"open-shelf-"+modelData
                    colors:study.colors
                    label:archive.snapshot.cubbies[modelData].name||modelData
                    active:sceneView.reachableViewPath[0]===modelData
                    enabled:!sceneView.busy&&!sceneView.pointer&&!sceneView.prepared&&!archive.draft&&!archive.structuralProposal
                    onClicked:{if(study.showRoomPlan&&roomPlan.roomId===archive.snapshot.spatial.shelves[modelData].roomId)study.navigateRoom(modelData,true);else if(sceneView.openShelf(modelData)){study.roomPlanOpen=false;if(study.mapEnabled)study.activeRoomId=archive.snapshot.spatial.shelves[modelData].roomId}}
                }
            }
        }
        Flow {
            id:pathTools
            width:parent.width;spacing:5
            height:26
            property bool caseSelected:!study.upperView&&sceneView.mode==="browse"&&archive.snapshot.caseItems.some(function(s){return s.id===sceneView.selectedScrollId})
            Text {
                height:26
                width:Math.min(300,implicitWidth+8)
                verticalAlignment:Text.AlignVCenter
                color:study.colors.engraving;font.pixelSize:11
                text:study.showMap?"Map Room":study.mapEnabled&&study.showRoomPlan&&study.currentRoomId?"Map Room / "+archive.snapshot.spatial.rooms[study.currentRoomId].name:sceneView.reachableViewPath.map(function(id){var c=archive.snapshot.cubbies[id];return c?c.name||id:id}).join(" / ")
                elide:Text.ElideRight
            }
            Archive.ArchiveButton {colors:study.colors;label:"Prepare insertion";visible:!sceneView.prepared&&parent.caseSelected;enabled:!sceneView.busy;onClicked:sceneView.prepareInsertion()}
            Archive.ArchiveButton {objectName:"case-return-origin";colors:study.colors;label:"Return to origin";visible:!sceneView.prepared&&parent.caseSelected;enabled:!sceneView.busy&&!sceneView.pointer&&!archive.draft&&!archive.structuralProposal;onClicked:sceneView.returnOrigin()}
            Archive.ArchiveButton {colors:study.colors;label:"Insert";visible:!!sceneView.prepared;enabled:!!sceneView.insertionMark;onClicked:sceneView.insertPrepared(false)}
            Archive.ArchiveButton {colors:study.colors;label:"Drop from top";visible:!!sceneView.prepared;enabled:!!sceneView.insertionContext;onClicked:sceneView.insertPrepared(true)}
            Archive.ArchiveButton {colors:study.colors;label:"Cancel insertion";visible:!!sceneView.prepared;onClicked:sceneView.cancelInsertion()}
        }
    }
    Archive.ArchiveScene {
        id:sceneView
        visible:!study.upperView||study.roomNavigating
        enabled:!study.upperView&&!study.roomNavigating
        roomDetailOpacity:study.roomNavigating?study.roomLayers.detail:1
        controller:archive
        colors:study.sceneColors
        paletteOptions:Themes.Theme.palettes
        desktopPaletteIndex:Themes.Theme.index
        appearanceSnapshot:study.sceneAppearanceSnapshot
        anchors.top:heading.bottom
        anchors.bottom:footer.top
        anchors.left:parent.left
        anchors.right:parent.right
        eligibleKeys:study.pickId&&study.activeIssue?study.activeIssue.options:[]
        onFurnitureContext:function(x,y){study.openContext(x,y)}
        onBookPlacementProposed:function(position){study.bookPositionText=String(position);structurePanel.forceActiveFocus()}
        onDestinationPressed:function(rackId,key){if(archive.draft&&rackId===archive.draft.rackId)study.chooseCell(key)}
    }
    Rectangle {
        anchors.fill:sceneView;visible:study.roomNavigating&&!study.roomLayers.live
        color:study.roomNavigating?study.roomNavigation.palette.background:study.colors.background
    }
    Archive.ArchiveRoomPlan {
        id:roomPlan
        objectName:"archive-room-plan"
        anchors.fill:sceneView
        visible:study.showRoomPlan||study.roomNavigating
        opacity:study.roomNavigating?study.roomLayers.room:1
        enabled:study.viewSwitchReady
        snapshot:archive.snapshot
        roomId:study.currentRoomId
        colors:study.colors;palettes:Themes.Theme.palettes;desktopPalette:Themes.Theme.index
        perspective:study.roomPerspective
        arranging:sceneView.mode==="arrange"
        snapEnabled:sceneView.snapEnabled;snapDistance:sceneView.snapDistance
        editPreview:archive.structuralProposal&&archive.structuralProposal.command.kind==="spatialShelfEdit"?View.roomEditOutline(archive.snapshot,archive.structuralProposal.command.containerId,archive.structuralProposal.command.patch):null
        editPreviewValid:!!archive.structuralProposal&&archive.structuralProposal.ok
        onEditShelf:function(id,patch){study.startRoomShelfEdit(id,patch)}
        onEditDimensions:function(id){study.startRoomShelfEdit(id,{})}
        rotationPreview:archive.structuralProposal&&archive.structuralProposal.ok&&archive.structuralProposal.command.kind==="spatialShelfTurn"?
            Spatial.footprint(archive.structuralProposal.snapshot,archive.structuralProposal.command.containerId):null
        onTurnShelf:function(id){
            if(!study.viewSwitchReady||roomPlan.dragging||!roomPlan.arranging)return
            var p=archive.snapshot.spatial.shelves[id]
            if(p){archive.proposeStructure({kind:"spatialShelfTurn",containerId:id,patch:{orientation:(p.orientation+90)%360}});structurePanel.forceActiveFocus()}
        }
        onInspectShelf:function(id){study.navigateRoom(id,true)}
    }
    Archive.ArchiveMapRoom {
        id:mapView
        objectName:"archive-map-room"
        anchors.fill:sceneView
        visible:study.showMap
        enabled:study.showMap&&study.viewSwitchReady&&!study.checkpointLoadPending
        presentationFrame:study.mapNavigation?View.mapTransitionFrame(study.mapNavigation.from,study.mapNavigation.to,study.mapProgress):null
        atlasEnabled:study.mapEnabled
        snapshot:archive.snapshot;colors:study.colors;palettes:Themes.Theme.palettes;desktopPalette:Themes.Theme.index
        arranging:sceneView.mode==="arrange"
        snapEnabled:sceneView.snapEnabled;showGrid:sceneView.showGrid;snapDistance:sceneView.snapDistance
        proposalCommand:structurePanel.mapRoomCommand?structurePanel.cmd:null
        doorProposalCommand:structurePanel.mapDoorCommand?structurePanel.cmd:null
        proposalValid:!!archive.structuralProposal&&archive.structuralProposal.ok
        onToggleGrid:sceneView.showGrid=!sceneView.showGrid
        onToggleSnap:sceneView.snapEnabled=!sceneView.snapEnabled
        onCycleSnapDistance:{var intervals=[5,10,20,25,50,100];sceneView.snapDistance=intervals[(intervals.indexOf(sceneView.snapDistance)+1)%intervals.length]}
        onAddRoom:study.startMapRoomEdit("spatialRoomCreate","",{})
        onEditRoom:function(id,patch){study.startMapRoomEdit("spatialRoomEdit",id,patch)}
        onDeleteRoom:function(id){study.startMapRoomEdit("spatialRoomDelete",id,{})}
        onAddDoor:function(patch){study.startMapDoorEdit("spatialDoorCreate","",patch)}
        onEditDoor:function(id,patch){study.startMapDoorEdit("spatialDoorEdit",id,patch)}
        onMergeDoor:function(id,otherId){study.startMapDoorEdit("spatialDoorMerge",id,{otherId:otherId})}
        onDeleteDoor:function(id){study.startMapDoorEdit("spatialDoorDelete",id,{})}
        onEnterRoom:function(id){study.enterMapRoom(id)}
    }
    Item {
        id:mapNavigationOverlay
        objectName:"map-navigation-overlay";anchors.fill:mapView;z:31;visible:study.mapNavigating
        onWidthChanged:if(study.mapNavigating)study.finishMapNavigation()
        onHeightChanged:if(study.mapNavigating)study.finishMapNavigation()
        Keys.onEscapePressed:function(event){study.finishMapNavigation();event.accepted=true}
        MouseArea {anchors.fill:parent;acceptedButtons:Qt.AllButtons;onWheel:function(wheel){wheel.accepted=true}}
        Archive.ArchiveButton {objectName:"map-navigation-skip";anchors.top:parent.top;anchors.right:parent.right;anchors.margins:8;colors:study.colors;label:"Skip";onClicked:study.finishMapNavigation()}
    }
    Item {
        id:navigationOverlay
        objectName:"room-navigation-overlay"
        anchors.fill:sceneView;z:30
        visible:study.roomNavigating
        clip:true
        onWidthChanged:if(study.roomNavigating)study.finishRoomNavigation()
        onHeightChanged:if(study.roomNavigating)study.finishRoomNavigation()
        Keys.onEscapePressed:function(event){study.finishRoomNavigation();event.accepted=true}
        Archive.ArchiveRoomTransition {
            objectName:"room-navigation-carrier"
            anchors.fill:parent
            navigation:study.roomNavigation
            progress:study.roomProgress
        }
        MouseArea {anchors.fill:parent;acceptedButtons:Qt.AllButtons;onWheel:function(wheel){wheel.accepted=true}}
        Archive.ArchiveButton {
            objectName:"room-navigation-skip"
            anchors.right:parent.right;anchors.top:parent.top;anchors.margins:8
            colors:study.colors;label:"Skip"
            onClicked:study.finishRoomNavigation()
        }
    }
    MouseArea {
        anchors.fill:parent;z:39;visible:study.contextOpen
        acceptedButtons:Qt.AllButtons
        // The backdrop consumes all unhandled presses. Never let a blank
        // menu click reach the underlying rack and clear its selection.
        onClicked:function(mouse){
            if(mouse.x<contextMenu.x||mouse.x>=contextMenu.x+contextMenu.width||mouse.y<contextMenu.y||mouse.y>=contextMenu.y+contextMenu.height)study.closeContext()
        }
    }
    Rectangle {
        id:contextMenu;objectName:"furniture-context"
        visible:study.contextOpen;z:40
        x:Math.max(4,Math.min(study.width-width-4,study.contextPoint.x))
        y:Math.max(4,Math.min(study.height-height-4,study.contextPoint.y))
        width:216;height:Math.min(study.height-8,contextRows.implicitHeight+12);radius:6
        color:View.mix(study.colors.background,study.colors.panel,.9)
        border.color:study.colors.metal
        focus:true
        Keys.onEscapePressed:study.closeContext()
        Archive.ArchiveInspectorScroll {
            id:contextScroll
            anchors.fill:parent;anchors.margins:6;contentHeight:contextRows.implicitHeight
        Column {
            id:contextRows;width:contextScroll.width;spacing:4
            Text {color:study.colors.engraving;font.pixelSize:11;text:study.selectedFixture?study.selectedFixture.type+" options":study.spatialEnabled&&Spatial.kind(archive.snapshot,sceneView.cubbyId)==="shelf"?"Shelf options":"Cubby options"}
            Archive.ArchiveButton {objectName:"toggle-flat-top";colors:study.colors;width:parent.width;visible:study.spatialEnabled&&!!study.selectedFixture&&["rack","cubby"].includes(study.selectedFixture.type);label:study.selectedFixture&&study.selectedFixture.flatTop?"Disable top support":"Enable top support";onClicked:study.toggleTop()}
            Archive.ArchiveButton {objectName:"place-book";colors:study.colors;width:parent.width;visible:study.spatialEnabled&&study.selectedSupport&&!study.bookPicker;label:"Place / move application book…";onClicked:study.beginBookPicker()}
            Archive.ArchiveButton {objectName:"unplace-selected-book";colors:study.colors;width:parent.width;visible:study.spatialEnabled&&study.selectedSupport&&!!sceneView.selectedAppId;label:"Unplace selected book";onClicked:study.startBook(sceneView.selectedAppId,true)}
            Archive.ArchiveButton {objectName:"shelf-appearance";colors:study.colors;width:parent.width;visible:study.spatialEnabled&&!study.selectedFixture&&Spatial.kind(archive.snapshot,sceneView.cubbyId)==="shelf";label:"Shelf appearance…";onClicked:study.startShelfAppearance()}
            Archive.ArchiveButton {objectName:"remove-architectural-shelf";colors:study.colors;width:parent.width;visible:study.spatialEnabled&&!study.selectedFixture&&Spatial.kind(archive.snapshot,sceneView.cubbyId)==="shelf"&&sceneView.shelfRoots.length>1;label:"Remove architectural Shelf";onClicked:study.startShelfRemoval()}
            Archive.ArchiveButton {objectName:"edit-rack";colors:study.colors;width:parent.width;label:"Rack size / cell pigment";visible:!!study.selectedRack;onClicked:study.openRackInspector()}
            Archive.ArchiveButton {objectName:"material-local";colors:study.colors;width:parent.width;label:!study.selectedFixture||study.selectedFixture.type==="cubby"?"Cubby colors":"Fixture color";visible:!study.selectedFixture||study.selectedFixture.type!=="artwork";onClicked:study.openMaterials(!study.selectedFixture||study.selectedFixture.type==="cubby"?"cubby":"fixture")}
            Archive.ArchiveButton {objectName:"material-presets";colors:study.colors;width:parent.width;label:"Furniture materials…";onClicked:study.openMaterials("roles")}
            Column {
                width:contextRows.width;spacing:3
                // Reference B6r12b3 uses one exterior viewing preference.
                // This control is offered on nested faces, not rack cells.
                visible:!!study.selectedFixture&&study.selectedFixture.type==="cubby"
                Text {text:"Cubby previews · view only";color:study.colors.engraving;font.pixelSize:11}
                Row {
                    spacing:4
                    Repeater {
                        model:[{id:"veiled",name:"Veiled"},{id:"inventory",name:"Inventory"},{id:"closed",name:"Closed"}]
                        Archive.ArchiveButton {
                            required property var modelData
                            objectName:"cubby-mode-"+modelData.id
                            colors:study.colors;label:modelData.name
                            active:sceneView.cubbyPreviewMode===modelData.id
                            onClicked:{sceneView.cubbyPreviewMode=modelData.id;study.closeContext()}
                        }
                    }
                }
            }
            Archive.ArchiveButton {objectName:"add-shelf";colors:study.colors;width:parent.width;label:"Add shelf";onClicked:{study.closeContext();study.startShelf()}}
            Archive.ArchiveButton {objectName:"add-rack";colors:study.colors;width:parent.width;label:"Add rack";onClicked:{study.closeContext();study.startFixture("rack")}}
            Archive.ArchiveButton {objectName:"add-cubby";colors:study.colors;width:parent.width;label:"Add nested cubby";onClicked:{study.closeContext();study.startFixture("cubby")}}
            Archive.ArchiveButton {objectName:"edit-child";colors:study.colors;width:parent.width;label:"Edit cubby footprint";visible:!!study.selectedFixture&&study.selectedFixture.type==="cubby";onClicked:{study.closeContext();study.startChildEdit()}}
            Archive.ArchiveButton {objectName:"edit-cubby-interior";colors:study.colors;width:parent.width;label:"Name / interior size";visible:!study.selectedFixture||study.selectedFixture.type==="cubby";onClicked:study.startCubbyEdit()}
            Archive.ArchiveButton {objectName:"edit-shelf";colors:study.colors;width:parent.width;label:"Edit shelf";visible:study.selectedFixture&&study.selectedFixture.type==="shelf";onClicked:{study.closeContext();study.startShelfEdit()}}
            Archive.ArchiveButton {objectName:"add-artwork";colors:study.colors;width:parent.width;label:"Add artwork mount";visible:!study.selectedFixture;onClicked:{study.closeContext();study.startFixture("artwork")}}
            Archive.ArchiveButton {objectName:"edit-artwork";colors:study.colors;width:parent.width;label:"Edit artwork mount";visible:!!study.selectedFixture&&study.selectedFixture.type==="artwork";onClicked:study.startArtworkEdit()}
            Archive.ArchiveButton {objectName:"add-holder";colors:study.colors;width:parent.width;label:"Add upright holder";visible:study.selectedSupport;onClicked:study.startHolder("holderCreate")}
            Archive.ArchiveButton {objectName:"edit-holder";colors:study.colors;width:parent.width;label:"Edit upright holder";visible:!!study.selectedHolder;onClicked:study.startHolder("holderEdit")}
            Archive.ArchiveButton {objectName:"delete-holder";colors:study.colors;width:parent.width;label:"Remove upright holder";visible:!!study.selectedHolder;onClicked:study.startHolder("holderDelete")}
            Archive.ArchiveButton {objectName:"delete-fixture";colors:study.colors;width:parent.width;label:"Remove fixture";visible:!!study.selectedFixture;onClicked:{study.closeContext();study.startDelete()}}
            Archive.ArchiveButton {objectName:"grid-snap-toggle";colors:study.colors;width:parent.width;label:sceneView.snapEnabled?"Snap: on":"Snap: off";onClicked:sceneView.snapEnabled=!sceneView.snapEnabled}
            Archive.ArchiveButton {objectName:"grid-guide-toggle";colors:study.colors;width:parent.width;label:sceneView.showGrid?"Grid: visible":"Grid: hidden";onClicked:sceneView.showGrid=!sceneView.showGrid}
            Text {color:study.colors.text;font.pixelSize:11;text:"Snap / grid interval: "+sceneView.snapDistance}
            Archive.ArchiveSlider {objectName:"grid-spacing-slider";colors:study.colors;width:parent.width;minimum:5;maximum:100;value:sceneView.snapDistance;label:"Grid interval";onMoved:function(n){sceneView.snapDistance=n}}
            Archive.ArchiveButton {colors:study.colors;width:parent.width;label:"Close";onClicked:study.closeContext()}
        }
        }
    }
    // Dedicated picker with six permanent, non-scrolling hit regions.
    // Reopening or paging changes only their contents, never row geometry.
    MouseArea {
        anchors.fill:parent;z:41;visible:study.bookPicker
        acceptedButtons:Qt.AllButtons
        onWheel:function(wheel){wheel.accepted=true}
    }
    Archive.ArchiveInspectorFrame {
        id:bookPickerPanel
        objectName:"application-picker"
        visible:study.bookPicker;z:42
        anchors.centerIn:parent
        colors:study.colors
        availableWidth:study.width-16;availableHeight:study.height-16
        preferredWidth:310;preferredHeight:294
        Keys.onEscapePressed:study.closeContext()
        Text {
            x:10;y:8;width:parent.width-20
            text:"Choose application book";color:study.colors.text;font.pixelSize:14;font.bold:true
        }
        Text {
            x:10;y:30;width:parent.width-20
            text:"Synthetic catalogue";color:study.colors.engraving;font.pixelSize:11
        }
        Repeater {
            model:6
            Archive.ArchiveButton {
                required property int index
                readonly property var choice:study.bookChoices[study.bookPage*6+index]||null
                objectName:choice?"pick-book-"+choice.appId:"empty-book-slot-"+index
                x:10;y:50+index*32;width:bookPickerPanel.width-20;height:28
                colors:study.colors;visible:!!choice
                enabled:study.bookPicker&&!!choice
                label:choice?choice.title:""
                hint:choice?choice.title+" · "+choice.appId:""
                onClicked:if(choice)study.chooseBook(choice.appId)
            }
        }
        Row {
            x:10;y:bookPickerPanel.height-38;spacing:5
            Archive.ArchiveButton {objectName:"book-page-prev";colors:study.colors;label:"‹";enabled:study.bookPage>0;onClicked:study.bookPage--}
            Text {width:68;anchors.verticalCenter:parent.verticalCenter;color:study.colors.text;text:(study.bookPage+1)+" / "+Math.max(1,Math.ceil(study.bookChoices.length/6))}
            Archive.ArchiveButton {objectName:"book-page-next";colors:study.colors;label:"›";enabled:(study.bookPage+1)*6<study.bookChoices.length;onClicked:study.bookPage++}
            Archive.ArchiveButton {objectName:"book-picker-cancel";colors:study.colors;label:"Cancel";onClicked:study.closeContext()}
        }
    }
    MouseArea {
        anchors.fill:parent;z:37;visible:study.materialPanel!==""
        acceptedButtons:Qt.AllButtons
        onPressed:function(mouse){
            if(mouse.x>=materialInspector.x&&mouse.x<materialInspector.x+materialInspector.width&&mouse.y>=materialInspector.y&&mouse.y<materialInspector.y+materialInspector.height)mouse.accepted=false
        }
        onClicked:{
            if(study.materialProposal&&study.materialProposal.ok)study.materialNotice="Apply or Cancel the preview first."
            else study.closeMaterials()
        }
    }
    // Temporary color inspector. All valid swatches and preset changes
    // are previews until one explicit Apply. Semantic theme roles stay intact.
    Archive.ArchiveInspectorFrame {
        id:materialInspector
        colors:study.colors
        availableWidth:study.width-16
        availableHeight:sceneView.height-16
        preferredWidth:280
        preferredHeight:materialHeader.implicitHeight+materialRows.implicitHeight+materialFooter.implicitHeight+28
        panelMix:.90
        objectName:"material-inspector"
        Keys.onEscapePressed:study.closeMaterials()
        visible:study.materialPanel!==""
        z:38
        anchors.top:sceneView.top;anchors.right:sceneView.right;anchors.margins:8
        Row {
            id:materialHeader
            anchors.top:parent.top;anchors.left:parent.left;anchors.right:parent.right;anchors.margins:8
            spacing:4
            Archive.ArchiveButton {
                id:materialBack
                objectName:"material-picker-back";visible:study.materialPickerRole!==""
                colors:study.colors;label:"‹";hint:"Return to all colors"
                onClicked:study.toggleMaterialPicker(study.materialPickerRole)
            }
            Text {
                width:Math.max(0,parent.width-34-(materialBack.visible?materialBack.width+parent.spacing:0))
                text:study.materialPickerRole!==""?"All colors / "+(study.materialPickerRole==="innerColor"?"Backing":study.materialPickerRole==="color"?"Material":study.materialPickerRole==="rack"?"Rack":study.materialPickerRole==="shelf"?"Shelf":"Nested cubby"):
                    study.materialPanel==="roles"?"Furniture materials":study.materialPanel==="cubby"?"Cubby colors":"Fixture color"
                font.bold:true;font.pixelSize:12;color:study.colors.text;elide:Text.ElideRight;anchors.verticalCenter:parent.verticalCenter
            }
            Archive.ArchiveButton {objectName:"material-close";colors:study.colors;label:"×";hint:"Cancel material preview";onClicked:study.closeMaterials()}
        }
        Archive.ArchiveInspectorScroll {
            id:materialScroll
            anchors.top:materialHeader.bottom;anchors.bottom:materialFooter.top
            anchors.left:parent.left;anchors.right:parent.right
            anchors.margins:8;anchors.topMargin:6;anchors.bottomMargin:6
            contentHeight:materialRows.implicitHeight
            Column {
                id:materialRows;width:materialScroll.width;spacing:6
                Text {visible:study.materialPickerRole==="";width:parent.width;wrapMode:Text.WordWrap;color:study.colors.engraving;font.pixelSize:11;text:study.materialPanel==="roles"?"Presets and swatches for "+study.colors.name+". Explicit fixture overrides take precedence.":"Reset previews the inherited material. Apply keeps the entire session."}
                Row {
                    visible:study.materialPanel==="roles"&&study.materialPickerRole==="";width:materialRows.width;spacing:4
                    Repeater {
                        model:[{id:"quiet",name:"Quiet"},{id:"balanced",name:"Balanced"},{id:"contrasted",name:"Accented"}]
                        Archive.ArchiveButton {
                            required property var modelData
                            objectName:"material-preset-"+modelData.id
                            colors:study.colors;label:modelData.name;active:study.materialPreferences.scheme===modelData.id
                            onClicked:study.setMaterialScheme(modelData.id)
                        }
                    }
                }
                Repeater {
                    model:study.materialPanel==="roles"?[{key:"rack",label:"Rack"},{key:"shelf",label:"Shelf"},{key:"cubby",label:"Nested cubby"}]:study.materialPanel==="cubby"?[{key:"color",label:"Outer frame"},{key:"innerColor",label:"Interior backing"}]:study.materialPanel==="fixture"?[{key:"color",label:"Material"}]:[]
                    Archive.ArchiveColorRow {
                        required property var modelData
                        objectName:"material-row-"+modelData.key
                        width:materialRows.width;colors:study.colors;label:modelData.label
                        visible:study.materialPickerRole===""||expanded
                        expanded:study.materialPickerRole===modelData.key
                        onTogglePicker:study.toggleMaterialPicker(modelData.key)
                        currentColor:study.materialPanel==="roles"?study.appearanceColors.materials[modelData.key]:
                            study.materialPanel==="cubby"?(modelData.key==="innerColor"?View.backingColor(study.materialCubby,study.localMaterialColors,study.materialDepth):View.frameColor(study.materialCubby,study.localMaterialColors,study.materialDepth)):
                            study.materialFixture?(study.materialFixture.type==="rack"?View.rackColor(study.materialFixture,study.sceneColors):View.shelfColor(study.materialFixture,study.sceneColors)):study.colors.panel
                        onApplyColor:function(value){if(study.materialPanel==="roles")study.setRoleColor(modelData.key,value);else study.setLocalColor(modelData.key,value)}
                    }
                }
                Archive.ArchiveButton {visible:study.materialPanel==="roles"&&study.materialPickerRole==="";colors:study.colors;label:"Reset this preset";onClicked:study.resetRoleColors()}
            }
        }
        Column {
            id:materialFooter
            anchors.bottom:parent.bottom;anchors.left:parent.left;anchors.right:parent.right;anchors.margins:8
            spacing:4
            Text {visible:study.materialNotice!=="";width:parent.width;wrapMode:Text.WordWrap;color:study.colors.engraving;font.pixelSize:11;text:study.materialNotice}
            Row {
                spacing:5
                Archive.ArchiveButton {objectName:"material-cancel";colors:study.colors;label:"Cancel";onClicked:study.closeMaterials()}
                Archive.ArchiveButton {objectName:"material-apply";colors:study.colors;label:"Apply";enabled:!!study.materialProposal&&study.materialProposal.ok;onClicked:study.applyMaterials()}
            }
        }
    }
    Archive.ArchiveInspectorFrame {
        id:adjust
        colors:study.colors
        availableWidth:study.width-16
        availableHeight:sceneView.height-16
        preferredWidth:268
        preferredHeight:Math.min(Math.max(rackHeader.implicitHeight+19,sceneView.height*.58),rackHeader.implicitHeight+content.implicitHeight+19)
        panelMix:.85
        objectName:"rack-inspector"
        visible:sceneView.mode==="arrange"&&!!study.selectedRack&&!archive.structuralProposal&&(study.rackInspector||!!archive.draft)
        z:30
        anchors.top:sceneView.top
        anchors.right:sceneView.right
        anchors.margins:8
        // Keep the rack-only radius control out of the scrollable review.
        // It must remain accessible while the asynchronous review grows.
        Column {
            id:rackHeader
            anchors.top:parent.top;anchors.left:parent.left;anchors.right:parent.right
            anchors.margins:7;spacing:5
            Row {
                width:rackHeader.width;spacing:5
                Text {width:parent.width-35;color:study.colors.text;font.pixelSize:12;font.bold:true;text:"Rack adjustment";anchors.verticalCenter:parent.verticalCenter}
                Archive.ArchiveButton {colors:study.colors;label:"×";hint:"Cancel rack adjustment";onClicked:study.closeRackInspector()}
            }
            Text {
                width:rackHeader.width;wrapMode:Text.WordWrap;color:study.colors.text;font.pixelSize:11
                text:"Cell size · "+(archive.draft?archive.draft.proposed.r:study.selectedRack?study.selectedRack.r:64)+" radius units"
            }
            Archive.ArchiveSlider {
                id:radiusSlider;objectName:"rack-radius-slider"
                colors:study.colors;width:rackHeader.width
                value:archive.draft?archive.draft.proposed.r:study.selectedRack?study.selectedRack.r:64
                onMoved:function(nextValue){study.edit({r:nextValue})}
                Keys.onEscapePressed:study.closeRackInspector()
            }
        }
        Archive.ArchiveInspectorScroll {
            id:rackScroll
            anchors.top:rackHeader.bottom;anchors.bottom:parent.bottom
            anchors.left:parent.left;anchors.right:parent.right
            anchors.margins:7;anchors.topMargin:5
            contentHeight:content.implicitHeight
            Column {
                id:content
                width:rackScroll.width;spacing:5
                Row {
                    width:content.width
                    Text {width:parent.width/2;text:"Smaller · more cells";font.pixelSize:10;color:study.colors.engraving}
                    Text {width:parent.width/2;text:"Larger · fewer cells";horizontalAlignment:Text.AlignRight;font.pixelSize:10;color:study.colors.engraving}
                }
                Text {
                    width:content.width;wrapMode:Text.WordWrap;font.pixelSize:10;color:study.colors.engraving
                    text:"Preview only. Resolve marked cells before applying."
                }
                Repeater {
                    model:[{key:"w",label:"Width",step:10},{key:"h",label:"Height",step:10}]
                    Row {
                        required property var modelData
                        width:content.width;spacing:4
                        Text { width:52; text:parent.modelData.label; color:study.colors.engraving; font.pixelSize:11; anchors.verticalCenter:parent.verticalCenter }
                        Archive.ArchiveButton {
                            colors:study.colors; label:"−"
                            onClicked:{var p={};var d=archive.draft?archive.draft.proposed:study.selectedRack;p[parent.modelData.key]=d[parent.modelData.key]-parent.modelData.step;study.edit(p)}
                        }
                        Text {
                            width:42; horizontalAlignment:Text.AlignHCenter; anchors.verticalCenter:parent.verticalCenter
                            text:study.selectedRack?String((archive.draft?archive.draft.proposed:study.selectedRack)[parent.modelData.key]):""
                            color:study.colors.text; font.pixelSize:12
                        }
                        Archive.ArchiveButton {
                            colors:study.colors; label:"+"
                            onClicked:{var p={};var d=archive.draft?archive.draft.proposed:study.selectedRack;p[parent.modelData.key]=d[parent.modelData.key]+parent.modelData.step;study.edit(p)}
                        }
                    }
                }
                Column {
                    visible:!!study.selectedMeta&&!archive.draft
                    width:content.width;spacing:3
                    Text {text:"Cell "+sceneView.selectedCell+" · pigment / recess";color:study.colors.engraving;font.pixelSize:10}
                    Row {
                        spacing:4
                        Rectangle {
                            width:84;height:24;radius:4;border.color:study.colors.metal;color:study.colors.background
                            TextInput {
                                id:pigment
                                anchors.fill:parent;anchors.margins:4
                                text:study.selectedMeta&&study.selectedMeta.color?study.selectedMeta.color:View.wallColor(null,study.colors)
                                color:study.colors.text;font.pixelSize:11;selectByMouse:true;maximumLength:7
                            }
                        }
                        Archive.ArchiveButton {colors:study.colors;label:"Paint";onClicked:archive.paintCell(sceneView.cubbyId,study.selectedRack.id,sceneView.selectedCell,pigment.text,undefined)}
                        Archive.ArchiveButton {colors:study.colors;label:"Reset";onClicked:archive.paintCell(sceneView.cubbyId,study.selectedRack.id,sceneView.selectedCell,null,0)}
                    }
                    Row {
                        spacing:4
                        Archive.ArchiveButton {colors:study.colors;label:"−";onClicked:archive.paintCell(sceneView.cubbyId,study.selectedRack.id,sceneView.selectedCell,undefined,Math.max(0,(study.selectedMeta.depth||0)-2))}
                        Text {text:"Recess "+(study.selectedMeta?study.selectedMeta.depth||0:0);color:study.colors.text;font.pixelSize:11;anchors.verticalCenter:parent.verticalCenter}
                        Archive.ArchiveButton {colors:study.colors;label:"+";onClicked:archive.paintCell(sceneView.cubbyId,study.selectedRack.id,sceneView.selectedCell,undefined,Math.min(24,(study.selectedMeta.depth||0)+2))}
                    }
                }
                Text {
                    width:parent.width; wrapMode:Text.WordWrap
                    font.pixelSize:10; color:study.colors.engraving
                    text:archive.draft?(archive.phase==="pending"?"Calculating layout…":archive.phase==="attention"?"Resolve highlighted cells":archive.phase==="invalid"?archive.draft.reason||"Invalid dimensions":"Ready to apply")+(archive.preview&&archive.preview.unresolved.length?" · "+archive.preview.unresolved.length+" waiting":""):"Change cell size or rack dimensions"
                }
                Archive.ArchiveButton {
                    visible:archive.radiusApprovalRequired
                    colors:study.colors; label:"Allow radius below 60"; onClicked:archive.approveRadius(true)
                }
                Row {
                    visible:!!study.activeIssue; spacing:5
                    Archive.ArchiveButton { colors:study.colors; label:"‹"; enabled:study.review.length>1; onClicked:{study.pickId="";study.reviewIndex=(study.reviewIndex+study.review.length-1)%study.review.length} }
                    Text { color:study.colors.text; font.pixelSize:11; text:study.activeIssue?"Cell "+study.activeIssue.key:""; anchors.verticalCenter:parent.verticalCenter }
                    Archive.ArchiveButton { colors:study.colors; label:"›"; enabled:study.review.length>1; onClicked:{study.pickId="";study.reviewIndex=(study.reviewIndex+1)%study.review.length} }
                }
                Repeater {
                    model:study.activeIssue&&study.activeIssue.records?study.activeIssue.records:[]
                    Row {
                        required property var modelData
                        spacing:4; width:content.width
                        Text { width:Math.max(60,parent.width-87); color:study.colors.text; font.pixelSize:11; text:parent.modelData.name; elide:Text.ElideRight; anchors.verticalCenter:parent.verticalCenter }
                        Archive.ArchiveButton {
                            objectName:"split-case-"+parent.modelData.id
                            width:28; colors:study.colors; label:""; hint:"Move to Case"
                            active:archive.draft&&archive.draft.decisions[parent.modelData.id]==="case"
                            Archive.ArchiveCaseIcon { anchors.centerIn:parent; ink:study.colors.text }
                            onClicked:{study.pickId="";archive.choose(parent.modelData.id,active?"":"case")}
                        }
                        Archive.ArchiveButton {
                            objectName:"split-hex-"+parent.modelData.id
                            colors:study.colors; label:"⬡"; hint:"Pick hex destination"
                            active:study.pickId===parent.modelData.id||(archive.draft&&!!archive.draft.decisions[parent.modelData.id]&&archive.draft.decisions[parent.modelData.id]!=="case")
                            onClicked:study.pickId=study.pickId===parent.modelData.id?"":parent.modelData.id
                        }
                    }
                }
                // Rare identity / pigment or recess conflicts remain explicitly represented.
                Repeater {
                    model:study.activeIssue&&study.activeIssue.homeOptions?study.activeIssue.homeOptions:[]
                    Archive.ArchiveButton {
                        required property var modelData
                        colors:study.colors; label:"Original identity → "+modelData
                        onClicked:archive.choose("home:"+study.activeIssue.cellId,modelData)
                    }
                }
                Text {
                    objectName:"cell-style-review-reason"
                    visible:!!study.activeIssue&&study.activeIssue.type==="paint"
                    width:parent.width; wrapMode:Text.WordWrap
                    font.pixelSize:10; color:study.colors.engraving
                    text:visible?study.activeIssue.reason:""
                }
                Row {
                    visible:!!study.activeIssue&&study.activeIssue.type==="paint"
                    spacing:4
                    Archive.ArchiveButton { objectName:"relocate-cell-style"; colors:study.colors; label:"⬡ Relocate"; hint:"Relocate cell pigment / recess"; onClicked:study.pickId="paint:"+study.activeIssue.cellId }
                    Archive.ArchiveButton { objectName:"discard-cell-style"; colors:study.colors; label:"Discard style"; hint:"Discard cell pigment / recess"; onClicked:archive.choose("paint:"+study.activeIssue.cellId,"discard") }
                }
                Row {
                    spacing:5
                    Archive.ArchiveButton { colors:study.colors; label:"Cancel"; enabled:!!archive.draft; onClicked:{study.pickId="";archive.cancel()} }
                    Archive.ArchiveButton { colors:study.colors; label:"Apply"; enabled:archive.phase==="ready"&&!archive.radiusApprovalRequired&&archive.draft&&!archive.draft.result.unchanged; onClicked:{study.pickId="";archive.apply()} }
                }
                Text {
                    width:parent.width; wrapMode:Text.WordWrap; font.pixelSize:10; color:study.colors.engraving
                    visible:!!archive.errorText
                    text:archive.errorText
                }
            }
        }
    }
    // A spatial confirmation owns its input. No click may reach a fixture,
    // case, or context backdrop behind it. Keep legacy drag ghosts interactive.
    MouseArea {
        anchors.fill:parent;z:34
        visible:structurePanel.spatialConfirmation
        acceptedButtons:Qt.AllButtons
        onWheel:function(wheel){wheel.accepted=true}
    }
    Archive.ArchiveInspectorFrame {
        id:structurePanel
        objectName:"structure-panel"
        colors:study.colors
        availableWidth:study.width-16
        availableHeight:sceneView.height-16
        preferredWidth:265
        preferredHeight:shelfAppearance?450:mapDoorCommand?300:mapRoomCommand?410:roomShelfEdit?350:spatialConfirmation?260:structureHeader.implicitHeight+contentStructure.implicitHeight+structureFooter.implicitHeight+28
        panelMix:.60
        property var proposal:study.materialProposal?null:archive.structuralProposal
        property var cmd:proposal?proposal.command:null
        readonly property bool cubbyEdit:!!cmd&&cmd.kind==="cubby"
        readonly property bool holderEdit:!!cmd&&["holderCreate","holderEdit"].includes(cmd.kind)
        readonly property bool removing:!!cmd&&["delete","holderDelete","spatialShelfDelete"].includes(cmd.kind)
        readonly property bool bookEdit:!!cmd&&cmd.kind==="spatialAppPlace"
        readonly property bool bookRemove:!!cmd&&cmd.kind==="spatialAppUnplace"
        readonly property bool supportEdit:!!cmd&&cmd.kind==="spatialSupport"
        readonly property bool shelfAppearance:!!cmd&&cmd.kind==="spatialAppearance"
        readonly property bool adopting:!!cmd&&["spatialAdoptProfiles","spatialAdoptIndependentProfiles"].includes(cmd.kind)
        readonly property bool shelfTurn:!!cmd&&cmd.kind==="spatialShelfTurn"
        readonly property bool roomShelfEdit:!!cmd&&cmd.kind==="spatialShelfEdit"
        readonly property bool mapRoomCommand:!!cmd&&["spatialRoomCreate","spatialRoomEdit","spatialRoomDelete"].includes(cmd.kind)
        readonly property bool mapRoomFields:mapRoomCommand&&cmd.kind!=="spatialRoomDelete"
        readonly property bool mapDoorCommand:!!cmd&&["spatialDoorCreate","spatialDoorEdit","spatialDoorMerge"].includes(cmd.kind)
        readonly property bool mapDoorFields:mapDoorCommand&&cmd.kind!=="spatialDoorMerge"
        readonly property var mapMergeChoices:mapDoorCommand&&cmd.kind==="spatialDoorMerge"?View.mapDoorMergeChoices(archive.snapshot,cmd.doorId):[]
        readonly property var lostMapDoors:mapRoomCommand?View.mapRoomLostDoors(archive.snapshot,cmd):[]
        readonly property bool spatialConfirmation:mapDoorCommand||mapRoomCommand||!!cmd&&[ "spatialShelfEdit","spatialShelfTurn","spatialAdoptProfiles","spatialAdoptIndependentProfiles","spatialAppPlace","spatialAppUnplace","spatialSupport","spatialShelfDelete","spatialAppearance" ].includes(cmd.kind)
        readonly property bool artworkEdit:!!cmd&&(cmd.kind==="artwork"||cmd.type==="artwork")
        readonly property bool suggested:cubbyEdit&&cmd.rearrange===true
        readonly property bool suggestionAvailable:cubbyEdit&&!!proposal&&
            (suggested||proposal.error.indexOf("Furniture needs at least ")===0)
        readonly property int movedCount:suggested&&proposal.ok?function(){
            var before=archive.snapshot.cubbies[cmd.cubbyId],after=proposal.snapshot.cubbies[cmd.cubbyId]
            return after.mods.filter(function(m){var old=before.mods.find(function(q){return q.id===m.id});return old.x!==m.x||old.y!==m.y}).length
        }():0
        visible:!!proposal
        z:35
        anchors.top:sceneView.top;anchors.right:sceneView.right;anchors.margins:8
        onVisibleChanged:if(visible&&structureScroll)structureScroll.resetPosition()
        Keys.onEscapePressed:archive.cancelStructure()
        Row {
            id:structureHeader
            anchors.top:parent.top;anchors.left:parent.left;anchors.right:parent.right;anchors.margins:8
            spacing:5
            Text {
                width:Math.max(0,parent.width-35);elide:Text.ElideRight
                color:study.colors.text;font.pixelSize:12;font.bold:true
                text:structurePanel.mapDoorCommand?(structurePanel.cmd.kind==="spatialDoorMerge"?"Merge touching openings":structurePanel.cmd.kind==="spatialDoorCreate"?"Add shared opening":"Opening dimensions"):structurePanel.mapRoomCommand?(structurePanel.cmd.kind==="spatialRoomDelete"?"Remove empty Room":structurePanel.cmd.kind==="spatialRoomCreate"?"Add Room":"Room dimensions"):structurePanel.roomShelfEdit?"Shelf dimensions":structurePanel.shelfTurn?"Rotate architectural Shelf":structurePanel.adopting?"Adopt physical profiles":structurePanel.shelfAppearance?"Shelf appearance":structurePanel.bookEdit?"Place application book":structurePanel.bookRemove?"Unplace application book":structurePanel.supportEdit?"Top support":structurePanel.removing?(structurePanel.cmd.kind==="spatialShelfDelete"?"Remove architectural Shelf":"Remove fixture"):structurePanel.cubbyEdit?"Cubby interior":structurePanel.holderEdit?"Upright holder":structurePanel.artworkEdit?"Artwork mount":"Fixture placement"
                anchors.verticalCenter:parent.verticalCenter
            }
            Archive.ArchiveButton {objectName:"structure-close";colors:study.colors;label:"×";hint:"Cancel fixture adjustment";onClicked:archive.cancelStructure()}
        }
        Archive.ArchiveInspectorScroll {
            id:structureScroll
            objectName:"structure-scroll"
            anchors.top:structureHeader.bottom;anchors.bottom:structureFooter.top
            anchors.left:parent.left;anchors.right:parent.right
            anchors.margins:8;anchors.topMargin:6;anchors.bottomMargin:6
            contentHeight:contentStructure.implicitHeight
            Column {
                id:contentStructure
                width:structureScroll.width;spacing:5
                readonly property var cmd:structurePanel.cmd
                Text {
                    width:parent.width;wrapMode:Text.WordWrap;color:study.colors.text;font.pixelSize:11
                    text:!structurePanel.proposal?"":structurePanel.mapDoorCommand?(structurePanel.cmd.kind==="spatialDoorMerge"?"Only contacting openings on the same pair of Room boundaries can merge. Review and Apply.":"Offsets along the first Room wall; positive width in one contiguous clear shared span. Neither Shelf nor Room moves."):structurePanel.mapRoomCommand?(structurePanel.cmd.kind==="spatialRoomDelete"?"Remove this empty Room only. Resolve any attached openings explicitly.":"Exact world X/Y, width and depth. Local Shelf geometry and identities stay unchanged. Apply when valid."):structurePanel.roomShelfEdit?
                        "Position uses occupied top-left. Width and height describe the interior; depth is independent. Invalid dimensions retain the original arrangement.":structurePanel.shelfTurn?
                        "Quarter-turn of selected Shelf only. Preview outline shows validated new footprint; wall correction is minimal. Apply or Cancel.":structurePanel.adopting?
                        "Adopt real outer profiles for every Shelf. Interior, positions and ownership remain unchanged. Review old/new bounds; unresolved conflicts prevent Apply.":structurePanel.removing?
                        (structurePanel.cmd.kind==="spatialShelfDelete"?"Remove this architectural Shelf and its contents? ":"Remove this fixture and its contents? ")+structurePanel.proposal.caseTransferCount+" file(s) will move to the Scroll Case."+
                        (study.spatialEnabled&&structurePanel.proposal.appUnplacementCount?" "+structurePanel.proposal.appUnplacementCount+" application book(s) will be unplaced; application identities retained.":"")+" No disk files are deleted.":
                        structurePanel.shelfAppearance?(Spatial.physicalProfiles(archive.snapshot)?"Choose local profile, palette and family. Profile may change the outer footprint; contents remain unchanged.":"Choose a local frame, palette and ornament family. Geometry and contents stay unchanged."):structurePanel.bookEdit?"Place "+structurePanel.cmd.appId+" · choose support-local position. The book retains its size and identity.":structurePanel.bookRemove?"Unplace "+structurePanel.cmd.appId+"? Its application identity is retained.":structurePanel.supportEdit?"Change explicit top support eligibility. Occupied supports cannot be disabled.":structurePanel.holderEdit?"Position along the shelf, holder width and slot capacity. The presentation cradle remains reserved. Apply when valid.":
                        structurePanel.cubbyEdit?"Grow the interior without changing furniture or its outer footprint. Apply when ready.":"Drag the preview to move; drag its lower-right handle to resize. Apply when valid."
                }
                Repeater {
                    model:structurePanel.adopting&&structurePanel.proposal.profileAdoption?Object.keys(structurePanel.proposal.profileAdoption.shelves):[]
                    Text {
                        required property string modelData
                        width:contentStructure.width;wrapMode:Text.WordWrap
                        color:study.colors.engraving;font.pixelSize:11
                        readonly property var entry:structurePanel.proposal.profileAdoption.shelves[modelData]
                        text:(archive.snapshot.cubbies[modelData].name||modelData)+": "+
                            entry.previous.w.toFixed(2)+" × "+entry.previous.h.toFixed(2)+" → "+entry.geometry.w.toFixed(2)+" × "+entry.geometry.h.toFixed(2)+(entry.frameBasis!==undefined?" · frame "+entry.frameBasis.toFixed(2)+" · aperture "+entry.previous.aperture.x.toFixed(2)+","+entry.previous.aperture.y.toFixed(2)+" → "+entry.geometry.aperture.x.toFixed(2)+","+entry.geometry.aperture.y.toFixed(2):"")
                    }
                }
                Repeater {
                    model:structurePanel.adopting&&structurePanel.proposal.profileAdoption?structurePanel.proposal.profileAdoption.rooms||[]:[]
                    Text {
                        required property var modelData
                        width:contentStructure.width;wrapMode:Text.WordWrap;color:study.colors.engraving;font.pixelSize:11
                        text:archive.snapshot.spatial.rooms[modelData.id].name+": wall "+modelData.wallHeight+" units (provisional target-native validation)"
                    }
                }
                Repeater {
                    model:structurePanel.adopting&&structurePanel.proposal.profileAdoption?structurePanel.proposal.profileAdoption.conflicts:[]
                    Text {
                        required property var modelData
                        width:contentStructure.width;wrapMode:Text.WordWrap;color:study.colors.text;font.pixelSize:11
                        text:"Conflict: "+modelData.kind+" · "+(modelData.shelfId||modelData.doorId||"")
                    }
                }
                Column {
                    visible:structurePanel.shelfAppearance
                    width:contentStructure.width;spacing:4
                    Repeater {
                        model:[{key:"cornice",label:"Straight cornice"},{key:"crest",label:"Crest trim"},{key:"pilaster",label:"Pilaster trim"}]
                        Archive.ArchiveButton {
                            required property var modelData
                            objectName:"shelf-profile-"+modelData.key
                            colors:study.colors;width:contentStructure.width;label:modelData.label
                            active:structurePanel.shelfAppearance&&structurePanel.cmd.patch.profile===modelData.key
                            onClicked:study.setShelfAppearance("profile",modelData.key)
                        }
                    }
                    Text {text:"Ornament family";color:study.colors.engraving;font.pixelSize:11}
                    Grid {
                        columns:3;spacing:3;width:contentStructure.width
                        Repeater {
                            model:View.ornamentFamilies
                            Archive.ArchiveButton {
                                required property var modelData
                                objectName:"shelf-family-"+(modelData.key===null?"inherit":View.ornamentKey(modelData.key)||"none")
                                colors:study.colors;width:(contentStructure.width-6)/3;label:modelData.label
                                active:structurePanel.shelfAppearance&&(
                                    structurePanel.cmd.patch.family!==undefined?structurePanel.cmd.patch.family:
                                    (archive.snapshot.cubbies[sceneView.cubbyId].appearance||{}).family===undefined?null:
                                    archive.snapshot.cubbies[sceneView.cubbyId].appearance.family)===modelData.key
                                onClicked:study.setShelfAppearance("family",modelData.key)
                            }
                        }
                    }
                    Text {text:"Local palette";color:study.colors.engraving;font.pixelSize:11}
                    Flow {
                        width:contentStructure.width;spacing:3
                        Repeater {
                            model:[{key:null,label:"Desktop"},{key:0,label:"Evening"},{key:1,label:"Twilight"},{key:2,label:"Midnight"}]
                            Archive.ArchiveButton {
                                required property var modelData
                                objectName:"shelf-palette-"+(modelData.key===null?"desktop":String(modelData.key))
                                colors:study.colors;label:modelData.label
                                active:structurePanel.shelfAppearance&&(
                                    structurePanel.cmd.patch.palette!==undefined?structurePanel.cmd.patch.palette:
                                    (archive.snapshot.cubbies[sceneView.cubbyId].appearance||{}).palette===undefined?null:
                                    archive.snapshot.cubbies[sceneView.cubbyId].appearance.palette)===modelData.key
                                onClicked:study.setShelfAppearance("palette",modelData.key)
                            }
                        }
                    }
                }
                Column {
                    visible:structurePanel.mapDoorCommand
                    width:contentStructure.width;spacing:5
                    Repeater {
                        model:structurePanel.mapDoorFields?["start","end"]:[]
                        Row {
                            required property string modelData
                            width:contentStructure.width;spacing:5
                            Text {width:55;text:parent.modelData==="start"?"Start":"End";color:study.colors.engraving;font.pixelSize:11;anchors.verticalCenter:parent.verticalCenter}
                            Rectangle {
                                width:100;height:26;radius:4;color:study.colors.background;border.color:study.colors.metal
                                TextInput {
                                    objectName:"map-door-input-"+parent.parent.modelData
                                    anchors.fill:parent;anchors.margins:4;clip:true
                                    text:study.mapDoorEditText[parent.parent.modelData]||""
                                    color:study.colors.text;font.pixelSize:11;maximumLength:12;selectByMouse:true
                                    Accessible.name:"Exact opening "+parent.parent.modelData
                                    onTextEdited:study.setMapDoorValue(parent.parent.modelData,text)
                                }
                            }
                        }
                    }
                    Repeater {
                        model:structurePanel.mapMergeChoices
                        Archive.ArchiveButton {
                            required property string modelData
                            objectName:"map-door-merge-choice-"+modelData
                            colors:study.colors;label:"Merge with "+modelData;active:structurePanel.mapDoorCommand&&structurePanel.cmd.patch.otherId===modelData
                            onClicked:study.chooseMapDoorMerge(modelData)
                        }
                    }
                }
                Column {
                    visible:structurePanel.mapRoomCommand
                    width:contentStructure.width;spacing:5
                    Repeater {
                        model:structurePanel.mapRoomFields?[{key:"name",name:"Name"},{key:"x",name:"X"},{key:"y",name:"Y"},{key:"w",name:"Width"},{key:"h",name:"Depth"}]:[]
                        Row {
                            required property var modelData
                            width:contentStructure.width;spacing:5
                            Text {width:55;text:parent.modelData.name;color:study.colors.engraving;font.pixelSize:11;anchors.verticalCenter:parent.verticalCenter}
                            Rectangle {
                                width:Math.max(50,contentStructure.width-60);height:26;radius:4;color:study.colors.background;border.color:study.colors.metal
                                TextInput {
                                    objectName:"map-room-input-"+parent.parent.modelData.key
                                    anchors.fill:parent;anchors.margins:4;clip:true
                                    text:study.mapRoomEditText[parent.parent.modelData.key]||""
                                    color:study.colors.text;font.pixelSize:11;maximumLength:parent.parent.modelData.key==="name"?80:12;selectByMouse:true
                                    Accessible.name:"Exact Room "+parent.parent.modelData.name
                                    onTextEdited:study.setMapRoomValue(parent.parent.modelData.key,text)
                                }
                            }
                        }
                    }
                    Text {width:parent.width;wrapMode:Text.WordWrap;color:study.colors.engraving;font.pixelSize:11;visible:structurePanel.lostMapDoors.length>0;text:"Affected openings: "+structurePanel.lostMapDoors.join(", ")}

                }
                Column {
                    visible:structurePanel.roomShelfEdit
                    width:contentStructure.width;spacing:5
                    Repeater {
                        model:structurePanel.roomShelfEdit?[{key:"x",name:"X"},{key:"y",name:"Y"},{key:"w",name:"Width"},{key:"h",name:"Height"},{key:"depth",name:"Depth"}]:[]
                        Row {
                            required property var modelData
                            width:contentStructure.width;spacing:6
                            Text {width:64;text:parent.modelData.name;color:study.colors.engraving;font.pixelSize:11;anchors.verticalCenter:parent.verticalCenter}
                            Rectangle {
                                width:100;height:26;radius:4;color:study.colors.background;border.color:study.colors.metal
                                TextInput {
                                    objectName:"room-shelf-input-"+parent.parent.modelData.key
                                    anchors.fill:parent;anchors.margins:4
                                    text:study.roomEditText[parent.parent.modelData.key]||""
                                    color:study.colors.text;font.pixelSize:11;maximumLength:12;selectByMouse:true
                                    Accessible.name:"Exact Shelf "+parent.parent.modelData.name
                                    onTextEdited:study.setRoomShelfValue(parent.parent.modelData.key,text)
                                }
                            }
                        }
                    }
                }
                Column {
                    visible:structurePanel.cubbyEdit
                    width:contentStructure.width;spacing:5
                    Text {text:"Name";color:study.colors.engraving;font.pixelSize:11}
                    Rectangle {
                        width:parent.width;height:26;radius:4;color:study.colors.background;border.color:study.colors.metal
                        TextInput {
                            id:cubbyNameInput
                            objectName:"cubby-name-input"
                            anchors.fill:parent;anchors.margins:5
                            text:structurePanel.cubbyEdit?(structurePanel.cmd.patch.name!==undefined?structurePanel.cmd.patch.name:archive.snapshot.cubbies[structurePanel.cmd.cubbyId].name||structurePanel.cmd.cubbyId):""
                            color:study.colors.text;font.pixelSize:11;maximumLength:80;selectByMouse:true
                            Accessible.name:"Cubby name"
                            onTextEdited:study.editCubbyValue("name",text)
                            onAccepted:study.editCubbyValue("name",text)
                        }
                    }
                    Archive.ArchiveButton {objectName:"cubby-ratio-lock";colors:study.colors;label:study.cubbyRatio>0?"Proportions locked":"Lock proportions";active:study.cubbyRatio>0;onClicked:study.toggleCubbyRatio()}
                    Repeater {
                        model:structurePanel.cubbyEdit?[{key:"w",name:"Width",step:50},{key:"h",name:"Height",step:50},{key:"b",name:"Frame",step:1}]:[]
                        Row {
                            required property var modelData
                            width:contentStructure.width;spacing:5
                            Text {width:55;text:parent.modelData.name;color:study.colors.engraving;font.pixelSize:11;anchors.verticalCenter:parent.verticalCenter}
                            Archive.ArchiveButton {
                                objectName:"cubby-minus-"+parent.modelData.key
                                colors:study.colors;label:"−"
                                onClicked:study.editCubbyValue(parent.modelData.key,structurePanel.cmd.patch[parent.modelData.key]-parent.modelData.step)
                            }
                            Rectangle {
                                width:64;height:26;radius:4;color:study.colors.background;border.color:study.colors.metal
                                TextInput {
                                    id:dimensionInput
                                    objectName:"cubby-input-"+parent.parent.modelData.key
                                    anchors.fill:parent;anchors.margins:5
                                    text:structurePanel.cubbyEdit?String(structurePanel.cmd.patch[parent.parent.modelData.key]!==undefined?structurePanel.cmd.patch[parent.parent.modelData.key]:archive.snapshot.cubbies[structurePanel.cmd.cubbyId][parent.parent.modelData.key]||11):""
                                    color:study.colors.text;font.pixelSize:11;maximumLength:4;selectByMouse:true
                                    validator:IntValidator {bottom:0;top:9999}
                                    Accessible.name:"Interior "+parent.parent.modelData.name
                                    onTextEdited:study.editCubbyValue(parent.parent.modelData.key,text.length?Number(text):0)
                                    onAccepted:study.editCubbyValue(parent.parent.modelData.key,text.length?Number(text):0)
                                }
                            }
                            Archive.ArchiveButton {
                                objectName:"cubby-plus-"+parent.modelData.key
                                colors:study.colors;label:"+"
                                onClicked:study.editCubbyValue(parent.modelData.key,structurePanel.cmd.patch[parent.modelData.key]+parent.modelData.step)
                            }
                        }
                    }
                    Text {
                        width:parent.width;wrapMode:Text.WordWrap;font.pixelSize:10;color:study.colors.engraving
                        text:structurePanel.cubbyEdit?function(){
                            var min=Core.cubbyMinimum(archive.snapshot.cubbies[structurePanel.cmd.cubbyId])
                            return "Current furniture needs at least "+min.w+" × "+min.h+"."
                        }():""
                    }
                }
                Row {
                    visible:structurePanel.bookEdit;spacing:5
                    Text {width:55;color:study.colors.engraving;text:"Position"}
                    Archive.ArchiveButton {objectName:"book-minus";colors:study.colors;label:"−";onClicked:study.stepBook(-10)}
                    Rectangle {
                        width:76;height:26;radius:4;color:study.colors.background;border.color:study.colors.metal
                        TextInput {
                            objectName:"book-position-input"
                            anchors.fill:parent;anchors.margins:4
                            color:study.colors.text;font.pixelSize:11;maximumLength:12;selectByMouse:true
                            text:study.bookPositionText
                            Accessible.name:"Exact support-local book position"
                            onTextEdited:study.setBookPosition(text)
                        }
                    }
                    Archive.ArchiveButton {objectName:"book-plus";colors:study.colors;label:"+";onClicked:study.stepBook(10)}
                }
                Repeater {
                    model:contentStructure.cmd&&!structurePanel.removing&&!structurePanel.cubbyEdit&&!structurePanel.bookEdit&&!structurePanel.bookRemove&&!structurePanel.supportEdit&&!structurePanel.shelfAppearance&&!structurePanel.roomShelfEdit&&!structurePanel.mapRoomCommand&&!structurePanel.mapDoorCommand&&!structurePanel.shelfTurn&&!structurePanel.adopting?(structurePanel.holderEdit?["x","w","count"]:contentStructure.cmd.type==="shelf"||contentStructure.cmd.kind==="shelf"?["x","y","w"]:["x","y","w","h"]):[]
                    Row {
                        required property string modelData
                        spacing:5
                        Text {width:55;color:study.colors.engraving;text:parent.modelData==="count"?"Slots":parent.modelData==="w"?"Width":parent.modelData==="h"?"Height":parent.modelData.toUpperCase();anchors.verticalCenter:parent.verticalCenter}
                        Archive.ArchiveButton {objectName:"structure-minus-"+parent.modelData;colors:study.colors;label:"−";onClicked:study.structuralStep(parent.modelData,sceneView.snapEnabled?-sceneView.snapDistance:-10)}
                        Text {width:45;color:study.colors.text;text:contentStructure.cmd&&contentStructure.cmd.patch&&contentStructure.cmd.patch[parent.modelData]!==undefined?String(contentStructure.cmd.patch[parent.modelData]):"";anchors.verticalCenter:parent.verticalCenter;horizontalAlignment:Text.AlignHCenter}
                        Archive.ArchiveButton {objectName:"structure-plus-"+parent.modelData;colors:study.colors;label:"+";onClicked:study.structuralStep(parent.modelData,sceneView.snapEnabled?sceneView.snapDistance:10)}
                    }
                }
                Row {
                    visible:structurePanel.artworkEdit;spacing:4
                    Repeater {
                        model:["bronze","stone","slim"]
                        Archive.ArchiveButton {
                            required property string modelData
                            objectName:"mount-profile-"+modelData
                            colors:study.colors;label:modelData
                            active:structurePanel.artworkEdit&&structurePanel.cmd.patch.profile===modelData
                            onClicked:study.setFrameProfile(modelData)
                        }
                    }
                }
            }
        }
        Column {
            id:structureFooter
            anchors.bottom:parent.bottom;anchors.left:parent.left;anchors.right:parent.right;anchors.margins:8
            spacing:5
            Text {
                width:parent.width;wrapMode:Text.WordWrap;color:study.colors.engraving;font.pixelSize:11
                text:structurePanel.proposal?study.structureApplyError||structurePanel.proposal.error||(structurePanel.movedCount?
                    "Preview moves "+structurePanel.movedCount+" fixture(s). Sizes and contents unchanged.":!structurePanel.proposal.ok?"No changes":"Ready to apply"):""
            }
            Archive.ArchiveButton {
                objectName:"map-room-resolve-doors";colors:study.colors
                visible:structurePanel.lostMapDoors.length>0
                label:structurePanel.mapRoomCommand&&structurePanel.cmd.removeDoors?"Keep openings":"Remove listed openings"
                onClicked:study.acknowledgeMapRoomDoors()
            }
            Archive.ArchiveButton {
                objectName:"shelf-suggest"
                visible:!!structurePanel.cmd&&structurePanel.cmd.kind==="shelf"&&!!archive.snapshot.cubbies[structurePanel.cmd.cubbyId].mods.find(m=>m.id===structurePanel.cmd.moduleId&&(m.items||[]).length)&&!!structurePanel.proposal&&(!structurePanel.proposal.ok||structurePanel.cmd.rearrange===true)
                colors:study.colors
                label:structurePanel.cmd&&structurePanel.cmd.rearrange===true?"Keep original positions":"Suggest shelf rearrangement"
                onClicked:study.toggleShelfSuggestion()
            }
            Archive.ArchiveButton {
                objectName:"cubby-suggest"
                visible:structurePanel.suggestionAvailable
                colors:study.colors
                label:structurePanel.suggested?"Keep original positions":"Suggest rearrangement"
                onClicked:study.toggleCubbySuggestion()
            }
            Row {
                spacing:5
                Archive.ArchiveButton {objectName:"structure-cancel";colors:study.colors;label:"Cancel";onClicked:archive.cancelStructure()}
                Archive.ArchiveButton {
                    objectName:"structure-apply";colors:study.colors
                    label:structurePanel.bookRemove?"Unplace":structurePanel.removing?(study.spatialEnabled?"Confirm removal":"Remove → Case"):"Apply"
                    enabled:!!structurePanel.proposal&&structurePanel.proposal.ok
                    onClicked:study.confirmStructure()
                }
            }
        }
    }
    // A load confirmation is modal, with stable button geometry; no Flow
    // replacement/reordering of hit targets after the opening click.
    MouseArea {
        anchors.fill:parent;z:49
        visible:study.checkpointLoadPending
        acceptedButtons:Qt.AllButtons
        onWheel:function(wheel){wheel.accepted=true}
    }
    Archive.ArchiveInspectorFrame {
        id:loadConfirmation
        objectName:"checkpoint-confirmation"
        z:50
        visible:study.checkpointLoadPending
        anchors.centerIn:parent
        colors:study.colors
        availableWidth:study.width-16
        availableHeight:study.height-16
        preferredWidth:330
        preferredHeight:loadDescription.implicitHeight+88
        Keys.onEscapePressed:study.cancelCheckpointLoad()
        Text {
            anchors.top:parent.top;anchors.left:parent.left;anchors.right:parent.right;anchors.margins:12
            text:"Load saved checkpoint?"
            color:study.colors.text;font.bold:true;font.pixelSize:13;elide:Text.ElideRight
        }
        Text {
            id:loadDescription
            anchors.top:parent.top;anchors.topMargin:36
            anchors.left:parent.left;anchors.right:parent.right;anchors.leftMargin:12;anchors.rightMargin:12
            text:"This replaces the current arrangement and clears Undo history. Unsaved changes will be lost."
            wrapMode:Text.WordWrap;font.pixelSize:11;color:study.colors.engraving
        }
        Archive.ArchiveButton {
            id:loadCancel
            objectName:"checkpoint-cancel"
            anchors.left:parent.left;anchors.bottom:parent.bottom;anchors.margins:12
            width:112
            colors:study.colors;label:"Cancel load"
            onClicked:study.cancelCheckpointLoad()
        }
        Archive.ArchiveButton {
            objectName:"checkpoint-confirm"
            anchors.right:parent.right;anchors.bottom:parent.bottom;anchors.margins:12
            width:112
            colors:study.colors;label:"Confirm load";enabled:study.checkpointReady
            onClicked:study.loadCheckpoint()
        }
    }
    Text {
        id:footer
        anchors.bottom:parent.bottom; anchors.left:parent.left; anchors.right:parent.right
        anchors.margins:8
        color:study.colors.engraving; font.pixelSize:10
        text:sceneView.busy?sceneView.motion.notice||"Live motion · Escape cancels":sceneView.message||sceneView.motion.notice||"N3 · Synthetic records · Ctrl/Shift select · drag · wheel / middle-drag camera"
        elide:Text.ElideRight
    }
}
