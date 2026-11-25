import QtQuick
import "../RepresentationCatalog.mjs" as Catalog
import "../ArchiveView.mjs" as View

// R3-derived frame and aperture; face art stays independent of profile.
// The metadata overlay is separate from the physical frame bounds.
Item {
    id:frame
    required property var record
    required property string assetId
    required property var colors
    property string profile:"bronze"
    property bool selected:false
    property Item gestureHost:null
    property Item plaqueHost:parent
    readonly property var geometry:Catalog.frameGeometry(width,height,profile)
    readonly property alias imageStatus:motif.status
    readonly property alias apertureItem:aperture
    signal activated(string recordId)
    Canvas {
        id:sideShadow
        x:frame.width;y:0;width:frame.geometry.shadow.width;height:frame.height
        onPaint:{
            var ctx=getContext("2d");ctx.clearRect(0,0,width,height)
            ctx.fillStyle="#50000000";ctx.beginPath();ctx.moveTo(0,0)
            ctx.lineTo(width,frame.geometry.shadow.slope);ctx.lineTo(width,height)
            ctx.lineTo(0,height);ctx.closePath();ctx.fill()
        }
        onWidthChanged:requestPaint()
        onHeightChanged:requestPaint()
        Connections {target:frame;function onGeometryChanged(){sideShadow.requestPaint()}}
    }
    Rectangle {
        anchors.fill:parent
        color:frame.geometry.materialRole==="background"?frame.colors.background:frame.colors.metal
        border.color:frame.selected?frame.colors.engraving:View.mix(frame.colors.panel,frame.colors.metal,.55)
        border.width:frame.selected?2:1
    }
    Rectangle {
        anchors.fill:parent;anchors.margins:frame.geometry.frameThickness
        color:frame.geometry.reveal
    }
    Item {
        id:aperture
        x:frame.geometry.aperture[0];y:frame.geometry.aperture[1]
        width:frame.geometry.aperture[2];height:frame.geometry.aperture[3];clip:true
        B7AssetImage {
            id:motif
            anchors.fill:parent;assetId:frame.assetId
            fillMode:Image.PreserveAspectCrop
        }
    }
    B7MetadataPlaque {
        x:frame.geometry.plaque[0];y:frame.geometry.plaque[1]
        width:frame.geometry.plaque[2];height:frame.geometry.plaque[3]
        record:frame.record;colors:frame.colors;overlayHost:frame.plaqueHost
        onActivated:function(id){frame.activated(id)}
        z:2
    }
    activeFocusOnTab:true
    Accessible.role:Accessible.Button
    Accessible.name:record.name
    Accessible.onPressAction:frame.activated(frame.record.id)
    Keys.onReturnPressed:frame.activated(frame.record.id)
    Keys.onSpacePressed:frame.activated(frame.record.id)
    B7ObjectGesture {
        anchors.fill:parent;gestureHost:frame.gestureHost;recordId:frame.record.id
        onActivated:{frame.forceActiveFocus();frame.activated(frame.record.id)}
    }
}
