import QtQuick
import "../archive" as Archive
import "../archive/ArchiveView.mjs" as View
import "../archive/ArchiveCore.mjs" as Core
import "../archive/ArchiveSpatial.mjs" as Spatial
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
    // Optional isolated study adapter, injected by the standalone window.
    // No filesystem dependency in the shared scene or model.
    property var checkpointStore:null
    property bool checkpointLoadPending:false
    readonly property bool checkpointReady:!!checkpointStore&&!archive.draft&&!archive.structuralProposal&&
        !sceneView.busy&&!sceneView.pointer&&!sceneView.furnitureDrag&&!sceneView.bookDrag&&!sceneView.prepared&&!study.contextOpen&&!study.bookPicker
    onCheckpointReadyChanged:if(!checkpointReady)checkpointLoadPending=false
    function checkpointView(){
        // Prune deleted cubby cameras and capture the currently open camera
        // without modifying the live view or creating an Undo entry.
        var cameras=View.copyCameras({})
        for(var id of Object.keys(sceneView.cameras))if(Object.prototype.hasOwnProperty.call(archive.snapshot.cubbies,id))cameras[id]=Core.clone(sceneView.cameras[id])
        cameras[sceneView.cubbyId]={zoom:sceneView.zoom,x:sceneView.pan.x,y:sceneView.pan.y}
        return {path:sceneView.reachableViewPath.slice(),theme:Themes.Theme.index,cameras:cameras,
            cubbyPreviewMode:sceneView.cubbyPreviewMode,snapEnabled:sceneView.snapEnabled,
            showGrid:sceneView.showGrid,snapDistance:sceneView.snapDistance}
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
        sceneView.forceActiveFocus()
        sceneView.message="Checkpoint load canceled"
    }
    function loadCheckpoint(){
        if(!checkpointReady||!checkpointLoadPending)return false
        checkpointLoadPending=false
        try{
            var payload=checkpointStore.read()
            if(payload===null){sceneView.message="No saved study checkpoint";return false}
            // Import validates the complete envelope before replacing anything.
            var view=archive.importCheckpoint(payload)
            if(!view){sceneView.message="Checkpoint not loaded · "+archive.checkpointError;return false}
            closeContext();closeMaterials();rackInspector=false;pickId=""
            sceneView.mode="browse"
            sceneView.viewPath=view.path.slice()
            sceneView.cameras=View.copyCameras(view.cameras)
            sceneView.restoreCamera()
            Themes.Theme.index=view.theme
            sceneView.cubbyPreviewMode=view.cubbyPreviewMode||"veiled"
            sceneView.snapEnabled=view.snapEnabled===true
            sceneView.showGrid=view.showGrid===true
            sceneView.snapDistance=view.snapDistance===undefined?20:view.snapDistance
            sceneView.clearSelection()
            sceneView.message="Study checkpoint loaded"
            return true
        }catch(e){sceneView.message="Checkpoint not loaded · "+String(e);return false}
    }
    // Resolved material roles are separate from semantic theme colors.
    readonly property var materialProposal:archive.structuralProposal&&archive.structuralProposal.command.kind==="materialBatch"?archive.structuralProposal:null
    readonly property var materialSnapshot:materialProposal&&materialProposal.snapshot?materialProposal.snapshot:archive.snapshot
    readonly property var appearanceColors: View.appearancePalette(colors,materialSnapshot.materials)
    function paletteFor(id){
        return spatialEnabled&&Spatial.enabled(materialSnapshot)?View.spatialPalette(materialSnapshot,id,Themes.Theme.palettes,Themes.Theme.index):appearanceColors
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

    Archive.ArchiveModel { id:archive; spatialEnabled:study.spatialEnabled; Component.onCompleted: reset(study.initialSnapshot||View.fixture()) }
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
        if(sceneView.busy)return
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
        if(archive.applyStructure()){
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
        enabled:study.materialPanel===""&&!archive.structuralProposal&&!study.checkpointLoadPending&&!study.bookPicker&&!sceneView.bookDrag
        anchors.top:parent.top
        anchors.left:parent.left
        anchors.right:parent.right
        anchors.margins:10
        spacing:6
        Text {
            color:study.colors.text; font.pixelSize:15
            text:study.spatialEnabled?"Astral Archive · Native Shelf study":"Astral Archive · Native cubby study"
        }
        Flow {
            width:parent.width; spacing:5
            Archive.ArchiveButton { colors:study.colors; label:"Browse"; active:sceneView.mode==="browse"; onClicked:study.switchMode("browse") }
            Archive.ArchiveButton { colors:study.colors; label:"Arrange"; active:sceneView.mode==="arrange"; onClicked:study.switchMode("arrange") }
            Archive.ArchiveButton { colors:study.colors; label:"Back"; enabled:sceneView.viewPath.length>1&&!archive.draft; onClicked:sceneView.back() }
            Archive.ArchiveButton { colors:study.colors; label:"Enter"; enabled:!archive.draft&&sceneView.cubby.mods.some(function(m){return m.id===sceneView.selectedModuleId&&m.type==="cubby"}); onClicked:sceneView.enterSelected() }
            Archive.ArchiveButton { colors:study.colors; label:"−"; hint:"Zoom out"; onClicked:sceneView.setZoom(sceneView.zoom/1.15) }
            Archive.ArchiveButton { colors:study.colors; label:Math.round(sceneView.zoom*100)+"%"; hint:"Reset camera"; onClicked:{sceneView.setZoom(1);sceneView.pan=Qt.point(0,0)} }
            Archive.ArchiveButton { colors:study.colors; label:"+"; hint:"Zoom in"; onClicked:sceneView.setZoom(sceneView.zoom*1.15) }
            Archive.ArchiveButton { colors:study.colors; label:study.colors.name; onClicked:Themes.Theme.index=(Themes.Theme.index+1)%3 }
            Archive.ArchiveButton { colors:study.colors; label:"Undo"; enabled:!sceneView.busy&&!archive.draft&&!archive.structuralProposal&&archive.archiveState.history.length>0; onClicked:archive.undo() }
            Archive.ArchiveButton {objectName:"arrange-menu";colors:study.colors;label:"Arrange menu";visible:sceneView.mode==="arrange";enabled:study.structureReady;onClicked:study.openContext(12,12)}
            Archive.ArchiveButton {objectName:"checkpoint-save";colors:study.colors;label:"Save checkpoint";visible:!!study.checkpointStore;enabled:study.checkpointReady&&!study.checkpointLoadPending;onClicked:study.saveCheckpoint()}
            Archive.ArchiveButton {objectName:"checkpoint-load";colors:study.colors;label:"Load checkpoint";visible:!!study.checkpointStore;enabled:study.checkpointReady;onClicked:study.requestCheckpointLoad()}
        }
        Flow {
            visible:study.spatialEnabled
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
                    onClicked:sceneView.openShelf(modelData)
                }
            }
        }
        Flow {
            width:parent.width;spacing:5
            height:26
            property bool caseSelected:sceneView.mode==="browse"&&archive.snapshot.caseItems.some(function(s){return s.id===sceneView.selectedScrollId})
            Text {
                height:26
                width:Math.min(300,implicitWidth+8)
                verticalAlignment:Text.AlignVCenter
                color:study.colors.engraving;font.pixelSize:11
                text:sceneView.reachableViewPath.map(function(id){var c=archive.snapshot.cubbies[id];return c?c.name||id:id}).join(" / ")
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
        controller:archive
        colors:study.sceneColors
        paletteOptions:Themes.Theme.palettes
        desktopPaletteIndex:Themes.Theme.index
        appearanceSnapshot:study.materialProposal?study.materialSnapshot:null
        anchors.top:heading.bottom
        anchors.bottom:footer.top
        anchors.left:parent.left
        anchors.right:parent.right
        eligibleKeys:study.pickId&&study.activeIssue?study.activeIssue.options:[]
        onFurnitureContext:function(x,y){study.openContext(x,y)}
        onBookPlacementProposed:function(position){study.bookPositionText=String(position);structurePanel.forceActiveFocus()}
        onDestinationPressed:function(rackId,key){if(archive.draft&&rackId===archive.draft.rackId)study.chooseCell(key)}
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
        preferredHeight:spatialConfirmation?260:structureHeader.implicitHeight+contentStructure.implicitHeight+structureFooter.implicitHeight+28
        panelMix:.60
        property var proposal:study.materialProposal?null:archive.structuralProposal
        property var cmd:proposal?proposal.command:null
        readonly property bool cubbyEdit:!!cmd&&cmd.kind==="cubby"
        readonly property bool holderEdit:!!cmd&&["holderCreate","holderEdit"].includes(cmd.kind)
        readonly property bool removing:!!cmd&&["delete","holderDelete","spatialShelfDelete"].includes(cmd.kind)
        readonly property bool bookEdit:!!cmd&&cmd.kind==="spatialAppPlace"
        readonly property bool bookRemove:!!cmd&&cmd.kind==="spatialAppUnplace"
        readonly property bool supportEdit:!!cmd&&cmd.kind==="spatialSupport"
        readonly property bool spatialConfirmation:!!cmd&&[ "spatialAppPlace","spatialAppUnplace","spatialSupport","spatialShelfDelete" ].includes(cmd.kind)
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
                text:structurePanel.bookEdit?"Place application book":structurePanel.bookRemove?"Unplace application book":structurePanel.supportEdit?"Top support":structurePanel.removing?(structurePanel.cmd.kind==="spatialShelfDelete"?"Remove architectural Shelf":"Remove fixture"):structurePanel.cubbyEdit?"Cubby interior":structurePanel.holderEdit?"Upright holder":structurePanel.artworkEdit?"Artwork mount":"Fixture placement"
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
                    text:!structurePanel.proposal?"":structurePanel.removing?
                        (structurePanel.cmd.kind==="spatialShelfDelete"?"Remove this architectural Shelf and its contents? ":"Remove this fixture and its contents? ")+structurePanel.proposal.caseTransferCount+" file(s) will move to the Scroll Case."+
                        (study.spatialEnabled&&structurePanel.proposal.appUnplacementCount?" "+structurePanel.proposal.appUnplacementCount+" application book(s) will be unplaced; application identities retained.":"")+" No disk files are deleted.":
                        structurePanel.bookEdit?"Place "+structurePanel.cmd.appId+" · choose support-local position. The book retains its size and identity.":structurePanel.bookRemove?"Unplace "+structurePanel.cmd.appId+"? Its application identity is retained.":structurePanel.supportEdit?"Change explicit top support eligibility. Occupied supports cannot be disabled.":structurePanel.holderEdit?"Position along the shelf, holder width and slot capacity. The presentation cradle remains reserved. Apply when valid.":
                        structurePanel.cubbyEdit?"Grow the interior without changing furniture or its outer footprint. Apply when ready.":"Drag the preview to move; drag its lower-right handle to resize. Apply when valid."
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
                    model:contentStructure.cmd&&!structurePanel.removing&&!structurePanel.cubbyEdit&&!structurePanel.bookEdit&&!structurePanel.bookRemove&&!structurePanel.supportEdit?(structurePanel.holderEdit?["x","w","count"]:contentStructure.cmd.type==="shelf"||contentStructure.cmd.kind==="shelf"?["x","y","w"]:["x","y","w","h"]):[]
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
