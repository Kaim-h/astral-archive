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
        name:"ArchiveB8RestartWrite"
        function test_write_spatial_checkpoint(){
            compare(store.read(),null)
            var ctl=study.controller,scene=study.scene,expected=N6.restartFixture()
            ctl.reset(expected)
            scene.viewPath=["root","child"]
            scene.cameras={root:{zoom:1.2,x:7,y:-9},child:{zoom:.85,x:13,y:17}}
            scene.restoreCamera()
            Themes.Theme.index=2
            scene.cubbyPreviewMode="inventory";scene.snapEnabled=true;scene.showGrid=false;scene.snapDistance=35
            study.setRoomPerspective(true)
            clickNamed("open-map-room")
            var map=findChild(study,"archive-map-room"),hall=expected.spatial.shelves.root.roomId
            tryVerify(function(){return map.visible&&map.activeFocus})
            var door=Object.values(expected.spatial.doors).find(d=>d.a.roomId===hall&&d.a.side==="south")
            verify(map.selectDoor(door.id))
            map.setCameraState({zoom:1.2,center:{x:800,y:1000}})
            clickNamed("map-focus");verify(map.focusState&&map.focusState.id===door.id)
            clickNamed("checkpoint-save");tryCompare(scene,"message","Study checkpoint saved")
            var saved=store.read(),envelope=CP.decode(saved)
            compare(JSON.parse(saved).version,6)
            compare(JSON.stringify(envelope.snapshot),JSON.stringify(expected))
            compare(JSON.stringify(envelope.view.path),JSON.stringify(["root","child"]))
            compare(envelope.view.mapView.layer,"map");compare(envelope.view.mapView.selectedDoor,door.id)
            compare(envelope.view.theme,2);compare(envelope.view.roomPerspective,true)
            compare(JSON.stringify(envelope.view.mapView.focus.base),JSON.stringify({zoom:1.2,center:{x:800,y:1000}}))
        }
    }
}
