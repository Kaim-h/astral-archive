import QtQuick
import QtTest
import "../themes" as Themes
import "../archive/ArchiveCore.mjs" as Core
import "../archive/ArchiveCheckpoint.mjs" as CP
import "ArchiveB8ShelfFixture.mjs" as Sample
import "ArchiveB8N6Cases.mjs" as N6

Item {
    width:1366;height:900
    ArchiveStudyStorage {id:store;databaseName:"AstralArchive.B8.N6.RestartTest"}
    ArchiveNativeN2Study {id:study;anchors.fill:parent;spatialEnabled:true;physicalProfilesEnabled:true;mapEnabled:true;reducedRoomMotion:true;checkpointStore:store;initialSnapshot:Sample.fixture()}
    TestCase {
        when:windowShown
        function clickNamed(name){
            var item=findChild(study,name),last=""
            verify(!!item,name)
            tryVerify(function(){
                if(!item.visible||!item.enabled||item.width<=0||item.height<=0){last="";return false}
                var p=item.mapToItem(study,item.width/2,item.height/2),next=[p.x,p.y,item.width,item.height].join(",")
                var stable=next===last;last=next
                return stable&&p.x>=0&&p.x<study.width&&p.y>=0&&p.y<study.height
            },3000,"Unstable click "+name)
            mouseClick(item,item.width/2,item.height/2)
        }
        name:"ArchiveB8RestartRead"
        function test_read_spatial_checkpoint(){
            var ctl=study.controller,scene=study.scene,map=findChild(study,"archive-map-room")
            var saved=store.read(),envelope=CP.decode(saved),expected=N6.restartFixture()
            verify(!!saved);compare(JSON.parse(saved).version,6)
            compare(JSON.stringify(envelope.snapshot),JSON.stringify(expected))
            compare(JSON.stringify(ctl.snapshot),JSON.stringify(Sample.fixture()))
            clickNamed("checkpoint-load");tryVerify(function(){return study.checkpointLoadPending})
            clickNamed("checkpoint-cancel");compare(JSON.stringify(ctl.snapshot),JSON.stringify(Sample.fixture()))
            clickNamed("checkpoint-load");clickNamed("checkpoint-confirm")
            tryVerify(function(){return map.visible&&map.activeFocus})
            compare(JSON.stringify(ctl.snapshot),JSON.stringify(expected))
            compare(JSON.stringify(scene.viewPath),JSON.stringify(["root","child"]))
            compare(ctl.archiveState.history.length,0);compare(scene.mode,"browse")
            compare(Themes.Theme.index,2);compare(study.roomPerspective,true)
            compare(scene.zoom,.85);compare(scene.pan,Qt.point(13,17))
            compare(scene.cameras.root.zoom,1.2);compare(scene.cubbyPreviewMode,"inventory")
            compare(scene.snapEnabled,true);compare(scene.showGrid,false);compare(scene.snapDistance,35)
            var m=envelope.view.mapView
            compare(map.selectedRoom,m.selectedRoom);compare(map.selectedDoor,m.selectedDoor)
            compare(JSON.stringify(map.cameraState()),JSON.stringify(m.camera))
            compare(JSON.stringify(map.focusState),JSON.stringify(m.focus))
            compare(JSON.stringify(Core.owners(ctl.snapshot)),JSON.stringify(Core.owners(expected)))
            // Fault injection only in this isolated synthetic database.
            var before=JSON.stringify(ctl.snapshot),view=JSON.stringify(study.checkpointView()),rev=ctl.archiveState.revision
            var malformed=JSON.parse(saved);malformed.view.mapView.selectedDoor="missing"
            store.database().transaction(function(tx){tx.executeSql("UPDATE checkpoint SET payload=? WHERE slot=1",[JSON.stringify(malformed)])})
            try{
                verify(study.requestCheckpointLoad());verify(!study.loadCheckpoint())
                verify(map.visible&&map.activeFocus)
                compare(JSON.stringify(ctl.snapshot),before);compare(JSON.stringify(study.checkpointView()),view)
                compare(ctl.archiveState.revision,rev);compare(ctl.archiveState.history.length,0)
            }finally{store.write(saved)}
            clickNamed("checkpoint-save");var resaved=CP.decode(store.read())
            compare(JSON.stringify(resaved.snapshot),before);compare(JSON.stringify(resaved.view),view)
        }
    }
}
