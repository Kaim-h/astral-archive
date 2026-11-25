import QtQuick
// Compact swatch/hex/reset row. Only one visual editor is expanded at a time.
// The enclosing inspector owns the transaction and the final Apply/Cancel.
Column {
    id:control
    required property var colors
    required property string label
    required property string currentColor
    property bool expanded:false
    signal togglePicker()
    signal applyColor(var value)
    spacing:4
    Text {text:control.label;color:control.colors.text;font.pixelSize:11}
    Row {
        spacing:4
        ArchiveButton {
            objectName:control.objectName+"-swatch"
            colors:control.colors;width:32
            hint:"Choose "+control.label+" color"
            active:control.expanded
            onClicked:control.togglePicker()
            Rectangle {
                anchors.centerIn:parent;width:18;height:16;radius:2
                color:control.currentColor;border.color:control.colors.engraving
            }
        }
        Rectangle {
            width:83;height:26;radius:4;color:control.colors.background
            border.color:field.acceptableSwatch?control.colors.metal:"#c58a82"
            TextInput {
                id:field;objectName:control.objectName+"-input"
                anchors.fill:parent;anchors.margins:5
                text:control.currentColor;maximumLength:7;selectByMouse:true
                color:control.colors.text;font.pixelSize:11
                readonly property bool acceptableSwatch:/^#[0-9a-fA-F]{6}$/.test(text)
                Accessible.name:control.label+" hex color"
                onTextEdited:if(acceptableSwatch)control.applyColor(text)
                onAccepted:if(acceptableSwatch)control.applyColor(text)
                onEditingFinished:if(!acceptableSwatch)text=control.currentColor
            }
        }
        ArchiveButton {objectName:control.objectName+"-apply";colors:control.colors;label:"Preview";enabled:field.acceptableSwatch;onClicked:control.applyColor(field.text)}
        ArchiveButton {objectName:control.objectName+"-reset";colors:control.colors;label:"Reset";hint:"Reset to inherited "+control.label+" color";onClicked:{control.applyColor(null);field.text=control.currentColor}}
    }
    Loader {
        active:control.expanded
        visible:active
        width:control.width
        sourceComponent:ArchiveColorPicker {
            objectName:control.objectName+"-picker"
            colors:control.colors
            currentColor:control.currentColor
            onColorPicked:function(hex){control.applyColor(hex)}
        }
    }
    onCurrentColorChanged:field.text=currentColor
}
