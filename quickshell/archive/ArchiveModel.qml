import QtQuick
import QtQml.WorkerScript
import "ArchiveCore.mjs" as Core
import "ArchiveCheckpoint.mjs" as Checkpoint
import "ArchiveSpatial.mjs" as Spatial

// Research-only N1 controller. Replace whole values to notify QML bindings.
// At most one worker request runs; queued edits coalesce to the latest draft.
Item {
    id: model
    // Existing B6/B7 study windows do not render the architectural hierarchy.
    // Only explicitly opted-in test/controllers may import spatial checkpoints.
    property bool spatialEnabled: false
    // Existing N2 renderer cannot display v4; isolated contract tests opt in.
    property bool physicalProfilesEnabled: false
    property bool independentProfilesEnabled: false
    property var archiveState: Core.session(Core.fixture())
    readonly property var snapshot: archiveState.snapshot
    readonly property var draft: archiveState.draft
    readonly property var preview: Core.projection(archiveState)
    readonly property string phase: draft ? draft.phase : "idle"
    readonly property bool radiusApprovalRequired: Core.needsRadiusApproval(archiveState)
    readonly property string errorText: archiveState.error
    property int runningRevision: -1
    property var queued: null
    property int plannerTimeoutMs: 6000
    // Structural proposals are independent of the rack planner. Callers must
    // refuse live pointer/solver activity before entering a structural edit.
    property var structuralProposal: null
    readonly property bool appearanceSessionOpen:!!structuralProposal&&structuralProposal.appearanceSession===true
    property string checkpointError: ""
    // Synchronous publication markers for view-only lifecycle consumers.
    property bool resetting:false
    property bool restoringUndo:false
    function proposeStructure(command) {
        if(appearanceSessionOpen||draft||(!spatialEnabled&&command&&String(command.kind).indexOf("spatial")===0))return false
        if(command&&command.kind==="spatialAdoptProfiles"&&!physicalProfilesEnabled)return false
        if(command&&command.kind==="spatialAdoptIndependentProfiles"&&(!physicalProfilesEnabled||!independentProfilesEnabled))return false
        structuralProposal=Core.previewStructure(archiveState,command)
        return structuralProposal.ok
    }
    function beginAppearance(containerId) {
        if(!spatialEnabled||structuralProposal||draft||queued||runningRevision!==-1)return false
        var p=Core.beginAppearance(archiveState,containerId)
        if(!p)return false
        structuralProposal=p
        return true
    }
    function updateAppearance(key,value) {
        if(!appearanceSessionOpen)return false
        var next=Core.updateAppearance(archiveState,structuralProposal,key,value)
        if(!next)return false
        structuralProposal=next
        return !next.error
    }
    function cancelStructure() { structuralProposal=null }
    function editMixed(command) {
        if(draft||structuralProposal||!command||command.kind!=="holderMove")return false
        archiveState=Core.editStructure(archiveState,command)
        return !archiveState.error
    }
    function applyStructure(implicitBrowse) {
        if(!structuralProposal||(!spatialEnabled&&String(structuralProposal.command.kind).indexOf("spatial")===0))return false
        if(!physicalProfilesEnabled&&(structuralProposal.command.kind==="spatialAdoptProfiles"||Spatial.physicalProfiles(structuralProposal.snapshot)))return false
        if(!independentProfilesEnabled&&(structuralProposal.command.kind==="spatialAdoptIndependentProfiles"||Spatial.independentProfiles(structuralProposal.snapshot)))return false
        if(implicitBrowse===true&&!spatialEnabled)return false
        archiveState=implicitBrowse===true?Core.finishBrowseStructure(archiveState,structuralProposal):
            appearanceSessionOpen?Core.finishAppearance(archiveState,structuralProposal):Core.applyStructure(archiveState,structuralProposal)
        if(!archiveState.error)structuralProposal=null
        return !archiveState.error
    }
    function exportCheckpoint(view) {
        try {
            if(structuralProposal)throw Error("Finish structural proposal")
            checkpointError=""
            return Checkpoint.encode(archiveState,view)
        }catch(e){checkpointError=String(e);return ""}
    }
    function importCheckpoint(text) {
        try {
            if(draft||structuralProposal)throw Error("Finish pending proposal")
            var value=Checkpoint.decode(text)
            reset(value.snapshot)
            checkpointError=""
            return value.view
        }catch(e){checkpointError=String(e);return null}
    }

    function reset(value) {
        // Do not reuse revision numbers across resets while a worker may reply.
        if(Spatial.enabled(value)&&!spatialEnabled)throw Error("Spatial checkpoint requires an opted-in controller")
        if(Spatial.physicalProfiles(value)&&!physicalProfilesEnabled)throw Error("Physical profile checkpoint requires compatible renderer or isolated geometry controller")
        if(Spatial.independentProfiles(value)&&!independentProfilesEnabled)throw Error("Independent profile checkpoint requires compatible controller")
        var fresh = Core.session(value)
        fresh.revision = archiveState.revision + 1
        queued = null
        debounce.stop()
        structuralProposal=null
        resetting=true
        try{archiveState=fresh}finally{resetting=false}
    }
    function stage(cubbyId, rackId, patch, decisions) {
        if(structuralProposal)return
        archiveState = Core.stage(archiveState, cubbyId, rackId, patch, decisions)
        queued = Core.request(archiveState)
        if (queued) debounce.restart()
        else debounce.stop()
    }
    function choose(id, destination) {
        if (!draft) return
        var choices = Core.clone(draft.decisions)
        if (destination) choices[id] = destination
        else delete choices[id]
        stage(draft.cubbyId, draft.rackId, {}, choices)
    }
    function approveRadius(approved) { archiveState = Core.approveRadius(archiveState, approved) }
    function apply() { if(appearanceSessionOpen)return false;archiveState = Core.apply(archiveState); return !archiveState.error }
    function cancel() {
        structuralProposal=null
        queued = null
        debounce.stop()
        archiveState = Core.cancel(archiveState)
    }
    function undo() {
        if(structuralProposal)return false
        var next=Core.undo(archiveState)
        if(next.error){archiveState=next;return false}
        restoringUndo=true
        try{archiveState=next}finally{restoringUndo=false}
        return true
    }
    function paintCell(cubbyId,rackId,key,color,depth) { if(structuralProposal)return false;archiveState=Core.paintCell(archiveState,cubbyId,rackId,key,color,depth);return !archiveState.error }
    function dispatchLatest() {
        if (runningRevision !== -1 || !queued || !plannerLoader.item) return
        var message = queued
        queued = null
        runningRevision = message.revision
        watchdog.restart()
        plannerLoader.item.sendMessage(message)
    }

    Timer {
        id: debounce
        interval: 40
        repeat: false
        onTriggered: model.dispatchLatest()
    }
    // Retire a timed-out worker; never publish its obsolete revision.
    Timer {
        id:watchdog
        interval:model.plannerTimeoutMs
        onTriggered:{
            var revision=model.runningRevision
            model.runningRevision=-1
            model.archiveState=Core.accept(model.archiveState,{revision:revision,result:{ok:false,reason:"Planner timed out · retry or cancel"}})
            plannerLoader.active=false
            restartWorker.start()
        }
    }
    Timer {id:restartWorker;interval:1;onTriggered:plannerLoader.active=true}
    Loader {
        id:plannerLoader
        active:true
        onLoaded:model.dispatchLatest()
        sourceComponent: Component {
            WorkerScript {
                source:"ArchivePlanner.mjs"
                onMessage:function(messageObject){
                    if(messageObject.revision!==model.runningRevision)return
                    watchdog.stop();model.runningRevision=-1
                    model.archiveState=Core.accept(model.archiveState,messageObject)
                    if(!debounce.running)model.dispatchLatest()
                }
            }
        }
    }
}
