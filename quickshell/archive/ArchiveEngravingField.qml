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
        model:field.centerStyle==="axis"||field.centerStyle==="span"?[-1,1]:[]
        ArchiveFamilyMark {
            required property int modelData
            family:field.family;colors:field.colors
            exterior:true
            anchors.centerIn:undefined
            width:Math.min(34,field.width*.12,field.height*.12);height:width
            x:field.width/2-width/2+(field.centerStyle==="span"?modelData*field.width*.27:0)
            y:field.height/2-height/2+(field.centerStyle==="axis"?modelData*field.height*.29:0)
            opacity:.42
        }
    }
}
