import QtQuick
import QtTest
import "../archive" as Archive
import "../archive/ArchiveCore.mjs" as Core
import "../archive/ArchiveCheckpoint.mjs" as Checkpoint
import "ArchiveB8FoundationCases.mjs" as Cases

Item {
    Archive.ArchiveModel { id: legacy }
    Archive.ArchiveModel { id: spatial; spatialEnabled: true }
    TestCase {
        name: "ArchiveB8Foundation"
        function test_shared_contract() { verify(Cases.run()>50) }
        function test_controller_opt_in() {
            legacy.reset(Core.fixture()); spatial.reset(Core.fixture())
            verify(!legacy.proposeStructure({kind:"spatialPromote"}))
            verify(spatial.proposeStructure({kind:"spatialPromote"}))
            verify(spatial.applyStructure())
            var view={path:["root"],theme:1,cameras:{}}
            var saved=spatial.exportCheckpoint(view)
            verify(saved.length>0,spatial.checkpointError)
            compare(JSON.parse(saved).version,3)
            var original=JSON.stringify(legacy.snapshot)
            verify(legacy.importCheckpoint(saved)===null)
            compare(JSON.stringify(legacy.snapshot),original)
            verify(spatial.undo());compare(JSON.stringify(spatial.snapshot),original)
            verify(!!spatial.importCheckpoint(saved),spatial.checkpointError)
            compare(JSON.stringify(spatial.snapshot),JSON.stringify(Checkpoint.decode(saved).snapshot))
        }
    }
}
