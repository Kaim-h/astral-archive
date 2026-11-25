import QtQuick
import "B7Layout.mjs" as Layout

// Geometry and hit envelope use manifest coordinates, not image padding.
// Selection is view-only; no record ownership or solver mutation.
Item {
    id: symbol
    required property var record
    required property string assetId
    required property var colors
    required property real contactX
    required property real supportY
    property real artScale: 1
    property bool edge: false
    property bool selected: false
    // Opacity, not visibility/enabled: preserve active MouseArea capture.
    property bool suppressed:false
    opacity:suppressed?0:1
    property Item gestureHost:null
    readonly property var placement: Layout.supportedLayout(assetId,contactX,supportY,artScale,edge)
    readonly property alias imageStatus: art.status
    readonly property alias imageItem: art
    signal activated(string recordId)
    x: placement.box.x; y: placement.box.y
    width: placement.box.width; height: placement.box.height
    B7AssetImage {
        id: art
        assetId:symbol.assetId;edge:symbol.edge
        x:symbol.placement.image.x-symbol.x
        y:symbol.placement.image.y-symbol.y
        width:symbol.placement.image.width;height:symbol.placement.image.height
        fillMode:Image.Stretch
    }
    Rectangle {
        anchors.fill:parent;color:"transparent";border.color:symbol.colors.engraving
        border.width:1;radius:3;visible:symbol.selected
    }
    activeFocusOnTab: true
    Accessible.role:Accessible.Button
    Accessible.name:record.name
    Accessible.onPressAction:symbol.activated(symbol.record.id)
    Keys.onReturnPressed:symbol.activated(symbol.record.id)
    Keys.onSpacePressed:symbol.activated(symbol.record.id)
    B7ObjectGesture {
        anchors.fill:parent;gestureHost:symbol.gestureHost;recordId:symbol.record.id
        onActivated:{symbol.forceActiveFocus();symbol.activated(symbol.record.id)}
    }
}
