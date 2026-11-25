import QtQuick
// Theme-native integer slider, no Qt Quick Controls dependency.
// Value remains caller-owned; user movement emits a proposed value.
Item {
    id:control
    required property var colors
    property int minimum:38
    property int maximum:76
    property int value:64
    property string label:"Cell radius"
    signal moved(int nextValue)
    implicitWidth:220;implicitHeight:36
    height:implicitHeight
    activeFocusOnTab:true
    Accessible.role:Accessible.Slider
    Accessible.name:label
    Accessible.description:String(value)
    function setValue(v){var n=Math.max(minimum,Math.min(maximum,Math.round(v)));if(n!==value)moved(n)}
    function at(x){setValue(minimum+(maximum-minimum)*(x-9)/Math.max(1,width-18))}
    Keys.onLeftPressed:setValue(value-1)
    Keys.onRightPressed:setValue(value+1)
    Keys.onPressed:function(event){
        if(event.key===Qt.Key_Home){setValue(minimum);event.accepted=true}
        else if(event.key===Qt.Key_End){setValue(maximum);event.accepted=true}
    }
    Rectangle {
        x:9;width:parent.width-18;height:4;radius:2
        anchors.verticalCenter:parent.verticalCenter
        color:control.colors.metal;opacity:.65
    }
    Rectangle {
        x:9;width:Math.max(0,knob.x);height:4;radius:2
        anchors.verticalCenter:parent.verticalCenter
        color:control.colors.engraving
    }
    Rectangle {
        id:knob
        x:(parent.width-18)*(control.value-control.minimum)/Math.max(1,control.maximum-control.minimum)
        anchors.verticalCenter:parent.verticalCenter
        width:18;height:22;radius:5
        color:control.colors.panel
        border.color:control.activeFocus?control.colors.text:control.colors.engraving
        border.width:control.activeFocus?2:1
    }
    MouseArea {
        anchors.fill:parent;preventStealing:true
        onPressed:function(mouse){control.forceActiveFocus();control.at(mouse.x)}
        onPositionChanged:function(mouse){if(pressed)control.at(mouse.x)}
    }
}
