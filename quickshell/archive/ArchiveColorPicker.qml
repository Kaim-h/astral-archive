import QtQuick
import "ArchiveView.mjs" as View

// Dependency-free visual color control. No native dialog, no independent
// commit or stored HSV metadata. Hex remains the precise, accessible input.
Column {
    id:picker
    required property var colors
    required property string currentColor
    signal colorPicked(string hex)
    property real hue:0
    property real saturation:0
    property real value:0
    spacing:6
    function syncColor(){
        if(!/^#[0-9a-fA-F]{6}$/.test(currentColor))return
        if(View.hsvColor(hue,saturation,value)===currentColor.toLowerCase())return
        var hsv=View.colorHSV(currentColor,hue)
        hue=hsv.h;saturation=hsv.s;value=hsv.v
    }
    function choose(h,s,v){
        hue=Math.max(0,Math.min(360,h))
        saturation=Math.max(0,Math.min(1,s))
        value=Math.max(0,Math.min(1,v))
        var hex=View.hsvColor(hue,saturation,value)
        if(hex!==currentColor.toLowerCase())colorPicked(hex)
    }
    Component.onCompleted:syncColor()
    onCurrentColorChanged:syncColor()

    Rectangle {
        id:plane
        objectName:picker.objectName+"-sv"
        width:picker.width;height:100;radius:3;clip:true
        activeFocusOnTab:true
        Accessible.name:"Saturation and brightness"
        Accessible.description:Math.round(picker.saturation*100)+" percent saturation, "+Math.round(picker.value*100)+" percent brightness"
        Keys.onLeftPressed:picker.choose(picker.hue,picker.saturation-.025,picker.value)
        Keys.onRightPressed:picker.choose(picker.hue,picker.saturation+.025,picker.value)
        Keys.onUpPressed:picker.choose(picker.hue,picker.saturation,picker.value+.025)
        Keys.onDownPressed:picker.choose(picker.hue,picker.saturation,picker.value-.025)
        gradient:Gradient {
            orientation:Gradient.Horizontal
            GradientStop {position:0;color:"#ffffff"}
            GradientStop {position:1;color:View.hsvColor(picker.hue,1,1)}
        }
        Rectangle {
            anchors.fill:parent
            gradient:Gradient {
                GradientStop {position:0;color:"#00000000"}
                GradientStop {position:1;color:"#ff000000"}
            }
        }
        Rectangle {
            width:12;height:12;radius:6;color:"transparent"
            x:Math.max(0,Math.min(plane.width-width,picker.saturation*plane.width-width/2))
            y:Math.max(0,Math.min(plane.height-height,(1-picker.value)*plane.height-height/2))
            border.color:"white";border.width:2
            Rectangle {anchors.fill:parent;anchors.margins:2;radius:4;color:"transparent";border.color:"black"}
        }
        Rectangle {anchors.fill:parent;color:"transparent";border.color:plane.activeFocus?picker.colors.text:picker.colors.metal;radius:3}
        MouseArea {
            anchors.fill:parent;preventStealing:true
            function sample(x,y){picker.choose(picker.hue,x/Math.max(1,width),1-y/Math.max(1,height))}
            onPressed:function(mouse){plane.forceActiveFocus();sample(mouse.x,mouse.y)}
            onPositionChanged:function(mouse){if(pressed)sample(mouse.x,mouse.y)}
        }
    }
    Rectangle {
        id:hueBar
        objectName:picker.objectName+"-hue"
        width:picker.width;height:20;radius:3;clip:true
        activeFocusOnTab:true
        Accessible.role:Accessible.Slider
        Accessible.name:"Color hue"
        Accessible.description:Math.round(picker.hue)+" degrees"
        Keys.onLeftPressed:picker.choose(picker.hue-5,picker.saturation,picker.value)
        Keys.onRightPressed:picker.choose(picker.hue+5,picker.saturation,picker.value)
        gradient:Gradient {
            orientation:Gradient.Horizontal
            GradientStop {position:0;color:"#ff0000"}
            GradientStop {position:1/6;color:"#ffff00"}
            GradientStop {position:2/6;color:"#00ff00"}
            GradientStop {position:3/6;color:"#00ffff"}
            GradientStop {position:4/6;color:"#0000ff"}
            GradientStop {position:5/6;color:"#ff00ff"}
            GradientStop {position:1;color:"#ff0000"}
        }
        Rectangle {
            width:8;height:parent.height;radius:3
            x:Math.max(0,Math.min(hueBar.width-width,picker.hue/360*hueBar.width-width/2))
            color:"transparent";border.color:"white";border.width:2
            Rectangle {anchors.fill:parent;anchors.margins:2;radius:2;color:"transparent";border.color:"black"}
        }
        Rectangle {anchors.fill:parent;color:"transparent";border.color:hueBar.activeFocus?picker.colors.text:picker.colors.metal;radius:3}
        MouseArea {
            anchors.fill:parent;preventStealing:true
            function sample(x){picker.choose(360*x/Math.max(1,width),picker.saturation,picker.value)}
            onPressed:function(mouse){hueBar.forceActiveFocus();sample(mouse.x)}
            onPositionChanged:function(mouse){if(pressed)sample(mouse.x)}
        }
    }
}
