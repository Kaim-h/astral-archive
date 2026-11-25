import QtQuick
import "ArchiveCore.mjs" as Core
import "ArchiveMotion.mjs" as Motion

// Frame-driven, bounded physics. No timer is active when the cell set is
// empty. The renderer receives membership only on lift/drop and lightweight
// position changes per tick, never a rebuilt furniture scene.
Item {
    id: motion
    required property var controller
    property var transaction: null
    readonly property bool busy: transaction!==null
    property bool released: false
    property var membership: ({})
    property var positions: ({})
    property var carried: []
    property var caseRecords: []
    property int activeCells: 0
    property int stepCount: 0
    property real lastTime: 0
    property string notice: ""
    signal completed(bool committed)
    function syncMembers() {
        membership=Motion.members(transaction)
        carried=Core.clone(transaction.carried)
        caseRecords=Core.clone(transaction.draft.caseItems)
        positions=Motion.positions(transaction)
    }
    function wake() {
        activeCells=transaction?transaction.cells.size:0
        if(activeCells&&!clock.running){lastTime=Date.now();clock.start()}
        else if(!activeCells)clock.stop()
    }
    function start(ids,allowMixed) {
        if(busy||controller.structuralProposal)return false
        try{transaction=Motion.begin(controller.archiveState,ids,allowMixed===true);released=false;stepCount=0;notice="";syncMembers();return true}
        catch(e){notice=String(e);return false}
    }
    function hold(loc,offsets) {
        if(!busy)return
        try{Motion.tether(transaction,loc,offsets);wake()}
        catch(e){abort(String(e))}
    }
    function lift() {
        if(!busy)return false
        try{Motion.lift(transaction);syncMembers();wake();return true}
        catch(e){abort(String(e));return false}
    }
    function drop(destination,offsets) {
        if(!busy)return false
        try{Motion.insert(transaction,destination,offsets);syncMembers();release(false);return true}
        catch(e){abort(String(e));return false}
    }
    function transfer(ids,destination,offsets,allowMixed) {
        if(!start(ids,allowMixed))return false
        return lift()&&drop(destination,offsets||{})
    }
    function release(follow) {
        if(!busy)return
        Motion.release(transaction,follow);released=true;notice="Settling · Escape cancels";wake()
        if(!activeCells)finish()
    }
    function clear() {
        clock.stop();transaction=null;released=false;membership=({});positions=({});carried=[];caseRecords=[];activeCells=0
    }
    function abort(message) {
        clear();notice=message||"Canceled · arrangement unchanged";completed(false)
    }
    function finish() {
        var next=Core.commitMotion(controller.archiveState,transaction)
        var ok=!next.error
        clear()
        if(ok){controller.archiveState=next;notice="Placement committed to study · Undo available"}else notice=next.error
        completed(ok)
    }
    function frame() {
        if(!busy){clock.stop();return}
        var now=Date.now()
        Motion.advance(transaction,(now-lastTime)/1000)
        lastTime=now;stepCount=transaction.steps
        if(transaction.error){abort(transaction.error);return}
        positions=Motion.positions(transaction)
        activeCells=transaction.cells.size
        if(!activeCells){clock.stop();if(released)finish()}
    }
    Timer { id:clock; interval:16; repeat:true; onTriggered:motion.frame() }
}
