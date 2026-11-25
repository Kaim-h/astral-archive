import QtQuick
import QtQuick.Window
import "ArchiveB7MixedFixture.mjs" as Mixed

Window {
    width:1366;height:900;minimumWidth:640;minimumHeight:420
    visible:true;title:"Astral Archive — B7-N2 mixed cubby study"
    // Dedicated explicit slot avoids overwriting the legacy B6 study.
    ArchiveStudyStorage {id:mixedStorage;databaseName:"AstralArchive.NativeStudy.Checkpoint.Mixed"}
    ArchiveNativeN2Study {anchors.fill:parent;initialSnapshot:Mixed.fixture();checkpointStore:mixedStorage}
}
