import QtQuick
import QtQuick.Window

Window {
    width:1100
    height:720
    minimumWidth:640
    minimumHeight:420
    visible:true
    title:"Astral Archive — B6-N3 native study"
    ArchiveStudyStorage { id:studyStorage }
    ArchiveNativeN2Study { anchors.fill:parent;checkpointStore:studyStorage }
}
