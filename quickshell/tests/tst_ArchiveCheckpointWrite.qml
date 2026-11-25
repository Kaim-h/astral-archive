import QtQuick
import QtTest
import "../themes" as Themes
import "ArchiveCheckpointTestData.mjs" as Data

Item {
    width:1100;height:720
    ArchiveStudyStorage {id:store;databaseName:"AstralArchive.NativeStudy.Checkpoint.RestartTest"}
    ArchiveNativeN2Study {id:study;anchors.fill:parent;checkpointStore:store}
    TestCase {
        name:"ArchiveCheckpointWrite"
        when:windowShown
        function click(name){
            var item=findChild(study,name)
            verify(!!item)
            tryVerify(function(){return item.visible&&item.enabled&&item.width>0&&item.height>0})
            mouseClick(item,item.width/2,item.height/2)
        }
        function test_write(){
            compare(store.read(),null)
            var expected=Data.fixture()
            // First save and replacement use the same explicit UI slot.
            click("checkpoint-save")
            verify(store.read().length>0)
            study.controller.reset(expected.snapshot)
            study.scene.viewPath=expected.view.path.slice()
            study.scene.cameras=expected.view.cameras
            study.scene.restoreCamera()
            Themes.Theme.index=expected.view.theme
            study.scene.cubbyPreviewMode="inventory"
            study.scene.snapEnabled=true;study.scene.showGrid=false;study.scene.snapDistance=35
            click("checkpoint-save")
            tryCompare(study.scene,"message","Study checkpoint saved")
            var saved=store.read()
            verify(saved.length>0)
            verify(study.controller.proposeStructure({kind:"cubby",cubbyId:expected.child,patch:{w:700}}))
            verify(!study.checkpointReady)
            verify(!study.saveCheckpoint())
            verify(!study.requestCheckpointLoad())
            compare(store.read(),saved)
            study.controller.cancelStructure()
            var invalid=JSON.parse(saved);invalid.version=999
            var refused=false
            try{store.write(JSON.stringify(invalid))}catch(e){refused=true}
            verify(refused)
            compare(store.read(),saved)
        }
    }
}
