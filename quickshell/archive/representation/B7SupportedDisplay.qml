import QtQuick
import "B7Layout.mjs" as Layout

// Secondary support with independent contact datum and front/back ordering.
Item {
    id:fixture
    required property var record
    required property var colors
    required property real contactX
    required property real shelfY
    required property Item plaqueHost
    property real artScale:1
    property string mode:"shelf"
    property bool selected:false
    property Item gestureHost:null
    readonly property var geometry:Layout.supportFixture(record.variant,contactX,shelfY,artScale,mode)
    readonly property alias lipItem:lip
    signal activated(string recordId)
    x:geometry.x;y:geometry.y;width:geometry.w;height:geometry.h
    Rectangle {
        anchors.fill:parent;visible:fixture.mode!=="shelf"
        color:fixture.colors.background;border.color:fixture.colors.metal;radius:2
        Rectangle {x:2;y:3;width:parent.width-4;height:1;color:fixture.colors.engraving;opacity:.45}
    }
    Rectangle {
        visible:fixture.mode==="tray"
        x:0;y:-13;width:parent.width;height:8;radius:2
        color:fixture.colors.background;border.color:fixture.colors.metal;opacity:.85
    }
    B7SupportedSymbol {
        id:symbol
        objectName:fixture.record.id
        record:fixture.record;assetId:record.variant;colors:fixture.colors
        contactX:fixture.width/2;supportY:0;artScale:fixture.artScale
        selected:fixture.selected;gestureHost:fixture.gestureHost
        onActivated:function(id){fixture.activated(id)}
    }
    Rectangle {
        id:lip
        visible:fixture.mode==="tray"
        x:0;y:-fixture.geometry.lipHeight;width:parent.width;height:fixture.geometry.lipHeight+2
        z:1;radius:2
        color:fixture.colors.background;border.color:fixture.colors.metal
    }
    B7MetadataPlaque {
        anchors.horizontalCenter:parent.horizontalCenter
        y:fixture.mode==="plinth"?5:fixture.mode==="tray"?3:1
        width:fixture.mode==="shelf"?116:104
        height:fixture.mode==="plinth"?22:fixture.mode==="tray"?15:13
        record:fixture.record;colors:fixture.colors;overlayHost:fixture.plaqueHost
        z:2
        onActivated:function(id){fixture.activated(id)}
    }
}
