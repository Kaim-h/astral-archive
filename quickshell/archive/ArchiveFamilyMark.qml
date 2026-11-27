import QtQuick
import "ArchiveView.mjs" as View

// Non-owning, noninteractive engraving. Static local SVG source; no timers,
// Canvas loop, input handler or dependency on physical arrangement.
Image {
    id:mark
    property string family:"None"
    required property var colors
    property bool exterior:false
    property string emblemKey:""
    readonly property string asset:View.emblemSource(family,emblemKey,colors)
    objectName:"archive-family-mark"
    source:visible&&asset!==""?(asset.indexOf("data:")===0?asset:Qt.resolvedUrl(asset)):""
    visible:family!=="None"&&asset!==""&&width>0&&height>0
    width:parent?View.familyMarkSize(parent.width,parent.height,exterior):0
    height:width
    anchors.centerIn:parent
    fillMode:Image.PreserveAspectFit
    sourceSize.width:110;sourceSize.height:110
    cache:true;smooth:true
    opacity:exterior?.38:.58
}
