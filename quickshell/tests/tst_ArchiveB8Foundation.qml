import QtQuick
import QtTest
import "../archive" as Archive
import "../archive/ArchiveCore.mjs" as Core
import "../archive/ArchiveCheckpoint.mjs" as Checkpoint
import "ArchiveB8FoundationCases.mjs" as Cases

Item {
    Archive.ArchiveModel { id: legacy }
    Archive.ArchiveModel { id: spatial; spatialEnabled: true }
    Archive.ArchiveModel { id: profiles; spatialEnabled: true; physicalProfilesEnabled: true }
    TestCase {
        name: "ArchiveB8Foundation"
        function test_shared_contract() { verify(Cases.run()>50) }
        function test_profile_controller_gate() {
            profiles.reset(Core.fixture())
            verify(profiles.proposeStructure({kind:"spatialPromote"}))
            verify(profiles.applyStructure())
            spatial.reset(profiles.snapshot)
            verify(!spatial.proposeStructure({kind:"spatialAdoptProfiles"}))
            verify(profiles.proposeStructure({kind:"spatialAdoptProfiles"}))
            verify(profiles.applyStructure())
            var saved=profiles.exportCheckpoint({path:["root"],theme:1,cameras:{}})
            verify(saved.length>0,profiles.checkpointError)
            compare(JSON.parse(saved).version,4)
            var prior=JSON.stringify(spatial.snapshot)
            verify(spatial.importCheckpoint(saved)===null)
            compare(JSON.stringify(spatial.snapshot),prior)
            verify(profiles.undo())
            compare(JSON.stringify(profiles.snapshot),prior)
            verify(!!profiles.importCheckpoint(saved),profiles.checkpointError)
            compare(JSON.stringify(profiles.snapshot),JSON.stringify(Checkpoint.decode(saved).snapshot))
        }
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
