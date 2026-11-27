import QtQuick
// Deliberate selection: hovering never changes a document property.
Column {
    id:choice
    required property var colors
    required property var options
    property var value:null
    property string prefix:"choice"
    property string title:""
    property bool expanded:false
    signal selected(var value)
    function selectValue(v){expanded=false;selected(v)}
    spacing:3
    function labelFor(){
        var item=options.find(e=>e.key===value)
        return item?item.label:"Default"
    }
    Text {visible:choice.title!=="";text:choice.title;color:choice.colors.engraving;font.pixelSize:11}
    ArchiveButton {
        objectName:choice.prefix+"-choice"
        width:choice.width;colors:choice.colors
        label:choice.labelFor()+(choice.expanded?"  ▴":"  ▾")
        onClicked:choice.expanded=!choice.expanded
        Keys.onEscapePressed:function(event){if(choice.expanded){choice.expanded=false;event.accepted=true}else event.accepted=false}
    }
    Repeater {
        model:choice.expanded?choice.options:[]
        ArchiveButton {
            required property var modelData
            objectName:choice.prefix+"-"+(modelData.key===null?"default":String(modelData.key))
            width:choice.width;colors:choice.colors;label:modelData.label
            active:choice.value===modelData.key
            onClicked:choice.selectValue(modelData.key)
        }
    }
}
