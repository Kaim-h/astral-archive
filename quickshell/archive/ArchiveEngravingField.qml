import QtQuick
import "ArchiveAppearance.mjs" as Appearance

// Decorative only. No ownership, pointer handler or geometry writes.
Item {
    id:field
    required property var colors
    property string family:"None"
    property string emblemKey:""
    property string borderStyle:"none"
    property string centerStyle:"seal"
    property bool primaryField:false
    clip:true
    Image {
        anchors.fill:parent
        visible:field.borderStyle!=="none"&&field.family!=="None"
        readonly property string svg:visible?Appearance.borderSvg(field.family,field.borderStyle,field.width,field.height,field.colors.engraving):""
        source:visible&&svg?"data:image/svg+xml,"+encodeURIComponent(svg):""
        sourceSize.width:Math.min(1024,Math.ceil(width));sourceSize.height:Math.min(1024,Math.ceil(height))
        opacity:.58;cache:true
    }
    ArchiveFamilyMark {
        objectName:field.primaryField?"archive-backing-ornament":"archive-field-emblem"
        family:field.centerStyle==="none"?"None":field.family
        emblemKey:field.emblemKey;colors:field.colors
    }
    Repeater {
        model:field.family==="None"?[]:field.centerStyle==="axis"?[0,1]:field.centerStyle==="span"?[0,1,2,3]:[]
        Image {
            required property int modelData
            readonly property string svg:Appearance.secondarySvg(field.family,field.colors.engraving)
            source:svg?"data:image/svg+xml,"+encodeURIComponent(svg):""
            width:Math.min(34,field.width*.12,field.height*.12);height:width
            x:field.width/2-width/2+(modelData>=2?(modelData===2?-1:1)*field.width*.36:0)
            y:field.height/2-height/2+(modelData<2?(modelData===0?-1:1)*field.height*(field.centerStyle==="span"?.23:.29):0)
            opacity:.52;cache:true
        }
    }
}
