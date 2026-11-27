import QtQuick
// Deliberate selection: hovering never changes a document property.
// Explicit row geometry avoids overlapping hit areas before positioner polish.
Item {
    id:choice
    required property var colors
    required property var options
    property var value:null
    property string prefix:"choice"
    property string title:""
    property bool expanded:false
    readonly property real titleHeight:title!==""?16:0
    readonly property real triggerY:titleHeight?titleHeight+3:0
    readonly property real firstRow:triggerY+29
    implicitHeight:triggerY+26+(expanded?options.length*29:0)
    height:implicitHeight
    signal selected(var value)
    function selectValue(v){expanded=false;selected(v)}
    function labelFor(){
        var item=options.find(e=>e.key===value)
        return item?item.label:"Default"
    }
    Text {visible:choice.title!=="";text:choice.title;color:choice.colors.engraving;font.pixelSize:11;height:choice.titleHeight}
    ArchiveButton {
        objectName:choice.prefix+"-choice"
        y:choice.triggerY;width:choice.width;height:26;colors:choice.colors
        label:choice.labelFor()+(choice.expanded?"  ▴":"  ▾")
        onClicked:choice.expanded=!choice.expanded
        Keys.onEscapePressed:function(event){if(choice.expanded){choice.expanded=false;event.accepted=true}else event.accepted=false}
    }
    Repeater {
        model:choice.expanded?choice.options:[]
        ArchiveButton {
            required property var modelData
            required property int index
            objectName:choice.prefix+"-"+(modelData.key===null?"default":String(modelData.key))
            y:choice.firstRow+index*29;width:choice.width;height:26;colors:choice.colors;label:modelData.label
            active:choice.value===modelData.key
            onClicked:choice.selectValue(modelData.key)
        }
    }
}
