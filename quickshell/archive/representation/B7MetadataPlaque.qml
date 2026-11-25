import QtQuick
import "B7Layout.mjs" as Layout
import "../ArchiveView.mjs" as View

// The register is reparented to a common view layer and contains the compact
// plaque's hit area. It never affects layout, contact or stored metadata.
Item {
    id:plaque
    property var record:null
    required property var colors
    required property Item overlayHost
    property bool expanded:false
    readonly property alias panelItem:panel
    readonly property string variantLabel:record?Layout.assetFor(record.variant).label:""
    signal activated(string recordId)
    objectName:record?"metadata-"+record.id:"metadata-empty"
    function open(){
        if(!record||!visible||!overlayHost)return
        var p=mapToItem(overlayHost,0,0),q=mapToItem(overlayHost,width,height)
        var w=Math.min(244,overlayHost.width-16),h=78
        if(w<=0||overlayHost.height<h+16)return
        panel.width=w;panel.height=h
        panel.x=Math.max(8,Math.min(overlayHost.width-w-8,q.x-w))
        panel.y=Math.max(8,Math.min(overlayHost.height-h-8,q.y-h))
        closeDelay.stop();expanded=true
    }
    function close(){closeDelay.stop();expanded=false}
    onVisibleChanged:if(!visible){close();if(activeFocus)focus=false}
    onRecordChanged:{close();if(!record&&activeFocus)focus=false}
    onXChanged:if(expanded)close()
    onYChanged:if(expanded)close()
    onWidthChanged:if(expanded)close()
    onHeightChanged:if(expanded)close()
    // Qt skips hidden/disabled items in tab traversal. Do not toggle
    // activeFocusOnTab while this item itself owns active focus.
    activeFocusOnTab:true
    onActiveFocusChanged:if(activeFocus)open();else if(!compactMouse.containsMouse&&!panelMouse.containsMouse)close()
    Accessible.role:Accessible.Button
    Accessible.name:record?"File information for "+record.name:""
    Accessible.onPressAction:if(record){open();activated(record.id)}
    Keys.onEscapePressed:close()
    Keys.onReturnPressed:if(record){open();activated(record.id)}
    Keys.onSpacePressed:if(record){open();activated(record.id)}
    Rectangle {
        anchors.fill:parent;radius:2
        color:View.mix(plaque.colors.panel,plaque.colors.background,.35)
        border.color:plaque.activeFocus?plaque.colors.engraving:plaque.colors.metal
        Text {
            anchors.fill:parent;anchors.margins:2
            text:plaque.record?plaque.record.name:""
            color:plaque.colors.text;font.pixelSize:9;elide:Text.ElideRight
            horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter
        }
    }
    MouseArea {
        id:compactMouse
        anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor
        onEntered:plaque.open()
        onExited:if(plaque.expanded)closeDelay.restart()
        onClicked:if(plaque.record){plaque.forceActiveFocus();plaque.activated(plaque.record.id)}
    }
    Timer {
        id:closeDelay;interval:120;repeat:false
        onTriggered:if(!compactMouse.containsMouse&&!panelMouse.containsMouse)plaque.close()
    }
    Rectangle {
        id:panel
        parent:plaque.overlayHost
        z:100;visible:plaque.expanded&&plaque.visible&&!!plaque.record
        radius:3;color:View.mix(plaque.colors.panel,plaque.colors.background,.25)
        border.color:plaque.colors.metal
        readonly property string recordId:plaque.record?plaque.record.id:""
        readonly property string recordName:plaque.record?plaque.record.name:""
        Column {
            anchors.fill:parent;anchors.margins:8;spacing:3
            Text {
                width:parent.width;text:panel.recordName
                font.pixelSize:12;font.bold:true;color:plaque.colors.text;elide:Text.ElideRight
            }
            Rectangle {width:parent.width;height:1;color:plaque.colors.metal;opacity:.5}
            Text {
                width:parent.width
                text:plaque.record?(plaque.record.kind||"File")+" · "+(plaque.record.size||"Size unavailable"):""
                color:plaque.colors.text;font.pixelSize:10;elide:Text.ElideRight
            }
            Text {
                width:parent.width;text:plaque.variantLabel
                color:plaque.colors.engraving;font.pixelSize:10;elide:Text.ElideRight
            }
            Text {text:"Synthetic study entry";color:plaque.colors.engraving;font.pixelSize:10}
        }
        MouseArea {
            id:panelMouse
            anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor
            onEntered:closeDelay.stop()
            onExited:closeDelay.restart()
            onClicked:if(plaque.record){plaque.forceActiveFocus();plaque.activated(plaque.record.id)}
        }
    }
}
