import QtQuick
import "B7Ownership.mjs" as Mixed

Item {
    id:mount
    required property var module
    required property var colors
    required property Item plaqueHost
    property Item gestureHost:null
    property bool browse:true
    property bool interactive:true
    property bool selected:false
    property var hiddenIds:[]
    readonly property bool suppressed:!!module.record&&hiddenIds.indexOf(module.record.id)>=0
    signal activated(string recordId)
    objectName:"mounted-"+module.id
    x:module.x;y:module.y;width:module.w;height:module.h
    Loader {
        anchors.fill:parent;active:!!mount.module.record
        sourceComponent:B7ArtworkFrame {
            record:mount.module.record?Object.assign({},mount.module.record,{variant:Mixed.preferred(mount.module.record).variant}):({id:"vacant",name:"",variant:"artwork/estuary"})
            assetId:record.variant;colors:mount.colors;plaqueHost:mount.plaqueHost
            objectName:"mixed-mount-frame-"+record.id
            profile:mount.module.profile;selected:mount.selected;enabled:mount.interactive
            suppressed:mount.suppressed
            gestureHost:mount.browse?mount.gestureHost:null
            onActivated:function(id){mount.activated(id)}
        }
    }
    Rectangle {
        anchors.fill:parent;visible:!mount.module.record||mount.suppressed
        color:mount.colors.background;border.color:mount.selected?mount.colors.engraving:mount.colors.metal;radius:3
        Text {anchors.centerIn:parent;text:"Vacant mount";font.pixelSize:11;color:mount.colors.engraving}
        MouseArea {anchors.fill:parent;enabled:mount.interactive&&!mount.suppressed;onClicked:mount.activated("")}
    }
}
