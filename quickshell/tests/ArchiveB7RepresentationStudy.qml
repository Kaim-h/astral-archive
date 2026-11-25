import QtQuick
import "../archive" as Archive
import "../archive/representation" as B7
import "../themes" as Themes

// Isolated B7-N1 visual/component study. Synthetic identities only.
Rectangle {
    id:study
    width:1100;height:650
    property var colors:Themes.Theme.current
    property string selectedId:""
    property string frameProfile:"bronze"
    property string studyPage:"objects"
    property bool artworkLedge:false
    property bool secondarySupports:false
    readonly property var uprightRecords:[
        {id:"b7-record-a",name:"Nocturne.flac",variant:"record/v1",kind:"Audio",size:"18 MiB"},
        {id:"b7-ledger-a",name:"Field notes.csv",variant:"ledger/v2",kind:"Spreadsheet",size:"28 KiB"},
        null,
        {id:"b7-tablet-a",name:"Astral.otf",variant:"tablet/v1",kind:"Typeface",size:"96 KiB"},
        {id:"b7-record-b",name:"Observatory.ogg",variant:"record/v3",kind:"Audio",size:"9 MiB"},
        {id:"b7-ledger-b",name:"Catalogue.xlsx",variant:"ledger/v4",kind:"Spreadsheet",size:"143 KiB"}
    ]
    readonly property var sampleRecords:[
        {id:"b7-artwork",name:"Moonlit.png",variant:"artwork/moonlit-mountains",kind:"Image",size:"2.4 MiB"},
        {id:"b7-jar",name:"Vessel.stl",variant:"sculpture/jar",kind:"3D model",size:"740 KiB"},
        {id:"b7-owl",name:"Owl.obj",variant:"sculpture/owl",kind:"3D model",size:"1.8 MiB"},
        {id:"b7-satchel",name:"Manuscripts.zip",variant:"parcel/satchel",kind:"Compressed archive",size:"12 MiB"}
    ]
    color:colors.background
    Text {
        anchors.top:parent.top;anchors.horizontalCenter:parent.horizontalCenter;anchors.topMargin:12
        text:"Astral Archive · B7 native representation study"
        color:study.colors.text;font.pixelSize:15
    }
    Item {
        id:display
        visible:study.studyPage==="objects"
        width:900;height:520
        anchors.centerIn:parent
        scale:Math.min(1,(study.width-24)/width,(study.height-72)/height)
        Rectangle {
            anchors.fill:parent;radius:4
            color:study.colors.panel;border.color:study.colors.metal
            Rectangle {anchors.fill:parent;anchors.margins:12;color:study.colors.background}
        }
        Archive.ArchiveShelf {
            id:ledge
            objectName:"b7-artwork-ledge"
            visible:study.artworkLedge
            module:({id:"b7-art-ledger",x:64,y:220,w:206,h:15,type:"shelf"})
            colors:study.colors
        }
        B7.B7ArtworkFrame {
            objectName:"b7-mounted-artwork"
            x:80;y:study.artworkLedge?ledge.y+ledge.supportY-height:48;width:174;height:146
            record:study.sampleRecords[0];assetId:record.variant;colors:study.colors
            profile:study.frameProfile;selected:study.selectedId===record.id;plaqueHost:display
            onActivated:function(id){study.selectedId=id}
        }
        Archive.ArchiveShelf {
            id:board
            objectName:"b7-board"
            module:({id:"b7-display-board",x:74,y:396,w:752,h:15,type:"shelf"})
            colors:study.colors
        }
        Repeater {
            model:study.sampleRecords.slice(1)
            B7.B7SupportedDisplay {
                required property var modelData
                required property int index
                objectName:"support-"+modelData.id
                record:modelData;colors:study.colors;plaqueHost:display
                contactX:212+index*238;shelfY:board.y+board.supportY
                artScale:.86
                mode:!study.secondarySupports?"shelf":index===2?"tray":"plinth"
                selected:study.selectedId===record.id
                onActivated:function(id){study.selectedId=id}
            }
        }
    }
    Item {
        id:uprightDisplay
        visible:study.studyPage==="upright"
        width:900;height:520
        anchors.centerIn:parent
        scale:Math.min(1,(study.width-24)/width,(study.height-72)/height)
        Rectangle {
            anchors.fill:parent;radius:4
            color:study.colors.panel;border.color:study.colors.metal
            Rectangle {anchors.fill:parent;anchors.margins:12;color:study.colors.background}
        }
        Text {x:56;y:45;text:"Upright holder";font.pixelSize:16;color:study.colors.text}
        Text {x:600;y:45;text:"Presentation cradle";font.pixelSize:16;color:study.colors.text}
        Archive.ArchiveShelf {
            id:uprightBoard
            objectName:"b7-upright-board"
            module:({id:"b7-upright-shelf",x:44,y:408,w:812,h:15,type:"shelf"})
            colors:study.colors
        }
        B7.B7UprightHolder {
            id:holder
            objectName:"b7-upright-holder"
            x:56;y:98;width:510;height:uprightBoard.y+uprightBoard.supportY-y
            colors:study.colors;initialSlots:study.uprightRecords
        }
        B7.B7PresentationCradle {
            id:cradle
            objectName:"b7-presentation-cradle"
            x:594;y:98;width:244;height:uprightBoard.y+uprightBoard.supportY-y
            colors:study.colors;record:holder.selectedRecord;artScale:holder.artScale;plaqueHost:uprightDisplay
        }
        Text {
            x:56;y:445;width:510
            text:holder.notice
            color:study.colors.engraving;font.pixelSize:12;elide:Text.ElideRight
        }
        Archive.ArchiveButton {
            objectName:"b7-return-presentation"
            x:594;y:436;colors:study.colors;label:"Return to slot"
            enabled:!!holder.selectedRecord
            onClicked:{
                // Return focus to the reserved slot before disabling this button
                // or hiding the focused metadata plaque.
                var i=holder.slots.findIndex(r=>r&&r.id===holder.selectedId)
                if(i>=0)holder.focusSlot(i)
                holder.returnItem()
            }
        }
    }
    Row {
        anchors.bottom:parent.bottom;anchors.horizontalCenter:parent.horizontalCenter;anchors.bottomMargin:12;spacing:7
        Archive.ArchiveButton {objectName:"b7-show-objects";colors:study.colors;label:"Objects";active:study.studyPage==="objects";onClicked:study.studyPage="objects"}
        Archive.ArchiveButton {objectName:"b7-show-upright";colors:study.colors;label:"Upright";active:study.studyPage==="upright";onClicked:study.studyPage="upright"}
        Archive.ArchiveButton {colors:study.colors;label:study.colors.name;onClicked:Themes.Theme.index=(Themes.Theme.index+1)%3}
        Repeater {
            model:study.studyPage==="objects"?["bronze","stone","slim"]:[]
            Archive.ArchiveButton {
                required property string modelData
                colors:study.colors;label:modelData;active:study.frameProfile===modelData
                onClicked:study.frameProfile=modelData
            }
        }
        Archive.ArchiveButton {
            objectName:"b7-toggle-ledge";visible:study.studyPage==="objects"
            colors:study.colors;label:study.artworkLedge?"Ledge":"Wall";active:study.artworkLedge
            onClicked:study.artworkLedge=!study.artworkLedge
        }
        Archive.ArchiveButton {
            objectName:"b7-toggle-supports";visible:study.studyPage==="objects"
            colors:study.colors;label:study.secondarySupports?"Plinth / tray":"Shelf";active:study.secondarySupports
            onClicked:study.secondarySupports=!study.secondarySupports
        }
        Text {
            anchors.verticalCenter:parent.verticalCenter
            color:study.colors.engraving;font.pixelSize:11
            visible:study.studyPage==="objects"&&study.width>850
            text:study.selectedId?study.sampleRecords.find(r=>r.id===study.selectedId).name:"Select an object"
        }
    }
}
