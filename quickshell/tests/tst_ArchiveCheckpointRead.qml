import QtQuick
import QtTest
import "../themes" as Themes
import "../archive/ArchiveCore.mjs" as Core
import "../archive/ArchiveView.mjs" as View
import "../archive/ArchiveCheckpoint.mjs" as CP
import "ArchiveCheckpointTestData.mjs" as Data

Item {
    width:1100;height:720
    ArchiveStudyStorage {id:store;databaseName:"AstralArchive.NativeStudy.Checkpoint.RestartTest"}
    ArchiveNativeN2Study {id:study;anchors.fill:parent;checkpointStore:store}
    TestCase {
        name:"ArchiveCheckpointRead"
        when:windowShown
        function click(name){
            var item=findChild(study,name)
            verify(!!item)
            var last=""
            tryVerify(function(){
                if(!item.visible||!item.enabled||item.width<=0||item.height<=0){last="";return false}
                var p=item.mapToItem(study,item.width/2,item.height/2)
                var next=[p.x,p.y,item.width,item.height].join(",")
                var stable=next===last
                last=next
                return stable&&p.x>=0&&p.y>=0&&p.x<study.width&&p.y<study.height
            },2000,"Unstable checkpoint click target: "+name)
            mouseClick(item,item.width/2,item.height/2)
        }
        function test_read_after_restart(){
            var expected=Data.fixture(),saved=store.read()
            verify(saved!==null,"Writer process did not persist a checkpoint")
            compare(JSON.parse(saved).version,2)
            var envelope=CP.decode(saved)
            compare(JSON.stringify(envelope.snapshot),JSON.stringify(expected.snapshot))
            // A fresh process starts with its default fixture, not auto-load.
            compare(JSON.stringify(study.controller.snapshot),JSON.stringify(View.fixture()))
            click("checkpoint-load")
            verify(study.checkpointLoadPending)
            click("checkpoint-cancel")
            tryCompare(study,"checkpointLoadPending",false)
            compare(study.scene.message,"Checkpoint load canceled")
            compare(JSON.stringify(study.controller.snapshot),JSON.stringify(View.fixture()))
            click("checkpoint-load")
            tryCompare(study,"checkpointLoadPending",true)
            keyClick(Qt.Key_Escape)
            tryCompare(study,"checkpointLoadPending",false)
            compare(JSON.stringify(study.controller.snapshot),JSON.stringify(View.fixture()))
            verify(study.controller.proposeStructure({kind:"cubby",cubbyId:"root",patch:{w:study.controller.snapshot.cubbies.root.w+50}}))
            verify(study.controller.applyStructure())
            compare(study.controller.archiveState.history.length,1)
            click("checkpoint-load")
            tryCompare(study,"checkpointLoadPending",true)
            var confirm=findChild(study,"checkpoint-confirm"),cancel=findChild(study,"checkpoint-cancel")
            verify(confirm.visible&&cancel.visible)
            var p=confirm.mapToItem(cancel,confirm.width/2,confirm.height/2)
            verify(p.x<0||p.x>=cancel.width||p.y<0||p.y>=cancel.height,"Confirm overlaps Cancel")
            click("checkpoint-confirm")
            tryCompare(study.scene,"message","Study checkpoint loaded")
            compare(JSON.stringify(study.controller.snapshot),JSON.stringify(expected.snapshot))
            compare(JSON.stringify(study.scene.viewPath),JSON.stringify(expected.view.path))
            compare(Themes.Theme.index,2)
            compare(study.scene.zoom,.85);compare(study.scene.pan,Qt.point(13,17))
            compare(study.scene.cameras.root.zoom,1.2)
            compare(study.scene.cubbyPreviewMode,"inventory")
            compare(study.scene.snapEnabled,true);compare(study.scene.showGrid,false);compare(study.scene.snapDistance,35)
            compare(study.scene.mode,"browse")
            compare(study.controller.archiveState.history.length,0)
            var owners=Core.owners(study.controller.snapshot)
            compare(owners.find(e=>e.id==="restart-parcel").where,"shelf")
            compare(owners.find(e=>e.id==="restart-tablet").slot,2)
            compare(owners.find(e=>e.id==="restart-picture").where,"artwork")
            var carried=owners.find(e=>e.id==="restart-carried")
            compare(carried.where,"case");compare(carried.scroll.variant,"sculpture/jar");verify(carried.scroll.originStale)
            tryVerify(function(){return !!study.scene.moduleItem(owners.find(e=>e.id==="restart-parcel").moduleId)})
            var board=study.scene.moduleItem(owners.find(e=>e.id==="restart-parcel").moduleId)
            var parcel=findChild(board,"restart-parcel")
            verify(!!parcel);tryCompare(parcel,"imageStatus",Image.Ready)
            // Deliberately corrupt ONLY the temporary test database.
            var original=JSON.stringify(study.controller.snapshot),view=JSON.stringify(study.checkpointView())
            for(var i=0;i<2;i++){
                var bad=JSON.parse(saved);bad.version=999
                var payload=i===0?"not json":JSON.stringify(bad)
                store.database().transaction(function(tx){tx.executeSql("UPDATE checkpoint SET payload=? WHERE slot=1",[payload])})
                verify(study.requestCheckpointLoad())
                verify(!study.loadCheckpoint())
                verify(study.scene.message.indexOf("Checkpoint not loaded")===0)
                compare(JSON.stringify(study.controller.snapshot),original)
                compare(JSON.stringify(study.checkpointView()),view)
            }
            // Missing slot is also nonmutating, and must not auto-create data.
            store.database().transaction(function(tx){tx.executeSql("DELETE FROM checkpoint WHERE slot=1")})
            verify(study.requestCheckpointLoad())
            verify(!study.loadCheckpoint())
            compare(study.scene.message,"No saved study checkpoint")
            compare(JSON.stringify(study.controller.snapshot),original)
            compare(JSON.stringify(study.checkpointView()),view)
            store.write(saved)
        }
    }
}
