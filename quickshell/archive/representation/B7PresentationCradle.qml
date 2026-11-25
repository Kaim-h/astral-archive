import QtQuick
import "B7Layout.mjs" as Layout

// Side display for the very same stored record; shelf supports the cradle.
Item {
    id:cradle
    required property var colors
    property var record:null
    property Item plaqueHost:parent
    property real artScale:.95
    readonly property real floor:height-36
    readonly property var facePlacement:record?Layout.supportedLayout(record.variant,width/2,floor,artScale):null
    readonly property int imageStatus:faceLoader.item?faceLoader.item.status:Image.Null
    Canvas {
        id:backing
        x:cradle.width/2-72;y:cradle.floor-54;width:144;height:54
        onPaint:{
            var c=getContext("2d");c.clearRect(0,0,width,height)
            c.fillStyle=cradle.colors.background;c.strokeStyle=cradle.colors.metal;c.lineWidth=1.2
            c.beginPath();c.moveTo(0,height);c.lineTo(20,0);c.lineTo(width-20,0);c.lineTo(width,height);c.closePath();c.fill();c.stroke()
        }
        Connections {target:cradle;function onColorsChanged(){backing.requestPaint()}}
    }
    Loader {
        id:faceLoader
        active:!!cradle.record
        sourceComponent:B7AssetImage {
            assetId:cradle.record?cradle.record.variant:"record/v1";fillMode:Image.Stretch
            x:cradle.facePlacement?cradle.facePlacement.image.x:0
            y:cradle.facePlacement?cradle.facePlacement.image.y:0
            width:cradle.facePlacement?cradle.facePlacement.image.width:0
            height:cradle.facePlacement?cradle.facePlacement.image.height:0
        }
    }
    Rectangle {
        x:cradle.width/2-112;y:cradle.floor;width:224;height:36;radius:3
        color:cradle.colors.background;border.color:cradle.colors.metal
        Rectangle {x:3;y:3;width:parent.width-6;height:1;color:cradle.colors.engraving;opacity:.45}
        B7MetadataPlaque {
            anchors.horizontalCenter:parent.horizontalCenter
            y:7;width:124;height:25
            visible:!!cradle.record
            record:cradle.record;colors:cradle.colors;overlayHost:cradle.plaqueHost
        }
    }
    Repeater {
        model:cradle.record?[-1,1]:[]
        Rectangle {
            required property int modelData
            readonly property real lipWidth:cradle.facePlacement?Math.min(cradle.facePlacement.box.width*.18,25):0
            x:cradle.width/2+(modelData<0?-lipWidth-9:9);y:cradle.floor-9
            width:lipWidth;height:10;radius:2
            color:cradle.colors.background;border.color:cradle.colors.metal
        }
    }
    Text {
        visible:!cradle.record;anchors.centerIn:parent
        text:"Select a stored edge";color:cradle.colors.engraving;font.pixelSize:12
    }
}
