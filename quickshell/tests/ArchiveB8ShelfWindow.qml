import QtQuick
import QtQuick.Window
import "ArchiveB8ShelfFixture.mjs" as Sample

Window {
    width:1366;height:900;minimumWidth:640;minimumHeight:420
    visible:true;title:"Astral Archive — B8-N2 native Shelf study"
    ArchiveStudyStorage {id:storage;databaseName:"AstralArchive.NativeStudy.Checkpoint.Spatial"}
    ArchiveNativeN2Study {anchors.fill:parent;spatialEnabled:true;initialSnapshot:Sample.fixture();checkpointStore:storage}
}
