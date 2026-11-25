import QtQuick
import "ArchiveView.mjs" as View

// Single Case record list drives both the cradle art and the complete
// register. Expansion never changes the stored ownership or pill position.
Item {
    id: dock
    required property var colors
    property var records: []
    property var pendingIds: []
    property string selectedId: ""
    property var selectedIds: []
    property var hiddenIds: []
    property int countOverride: -1
    property bool dragNear: false
    property bool motionPending: false
    property bool carryingFromCase: false
    property bool dismissed: false
    property bool locked: false
    signal gestureStarted(var record,real lx,real ly,int modifiers)
    signal gestureMoved(real lx,real ly)
    signal gestureReleased(real lx,real ly)
    signal gestureCanceled()
    function containsDrop(point){
        var p=mapToItem(pill,point.x,point.y)
        if(p.x>=0&&p.y>=0&&p.x<=pill.width&&p.y<=pill.height)return true
        if(!panel.visible||carryingFromCase)return false
        p=mapToItem(panel,point.x,point.y)
        return p.x>=0&&p.y>=0&&p.x<=panel.width&&p.y<=panel.height
    }
    function nearPill(point){
        var p=mapToItem(pill,point.x,point.y)
        return p.x>=-24&&p.x<=pill.width+24&&p.y>=-38&&p.y<=pill.height+20
    }
    function openHover(){closeDelay.stop();if(!dismissed)hoverOpen=true}
    function closeHover(){closeDelay.restart()}
    property bool pinned: false
    property bool hoverOpen: false
    readonly property bool expanded: pinned||hoverOpen||dragNear
    readonly property int recordCount: countOverride>=0?countOverride:records.length
    signal recordPressed(var record)
    objectName: "scroll-case"
    width: Math.min(410,parent.width-16)
    height: expanded?Math.min(262,parent.height-12):34
    z: 12

    function isPending(id) { return pendingIds.indexOf(id)>=0 }
    Timer { id:closeDelay; interval:220; onTriggered:if(!pillHover.hovered&&!panelHover.hovered){dock.hoverOpen=false;dock.dismissed=false} }
    Rectangle {
        id: panel
        HoverHandler {id:panelHover;onHoveredChanged:if(hovered)dock.openHover();else dock.closeHover()}
        visible: dock.expanded
        opacity:dock.carryingFromCase?0:1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: pill.top
        anchors.bottomMargin: 4
        radius: 8
        color: View.mix(dock.colors.background,dock.colors.panel,.32)
        border.color: dock.colors.metal
        clip: true
        Text {
            x: 8; y: 5
            width:parent.width-46
            elide:Text.ElideRight
            color: dock.colors.engraving
            font.pixelSize: 10
            text: "Scroll Case · "+dock.recordCount+" files"+(dock.motionPending||dock.pendingIds.length?" · provisional":"")
        }
        ArchiveButton {
            colors:dock.colors
            label:"×";hint:"Close Scroll Case"
            anchors.right:parent.right;anchors.rightMargin:5;y:3
            width:24;height:19
            onClicked:{dock.dismissed=true;dock.pinned=false;dock.hoverOpen=false}
        }
        Item {
            id:cradle
            x:8;y:24;width:parent.width-16
            height:Math.min(122,width*122/346)
            clip:true
            Item {
                id:rail
                width:346;height:122
                scale:Math.min(cradle.width/width,cradle.height/height)
                x:(cradle.width-width*scale)/2
                transformOrigin:Item.TopLeft
                Rectangle {
                    x:9;y:98.2;width:321;height:14.4
                    radius:3.6
                    color:View.mix(dock.colors.panel,dock.colors.metal,.3)
                    border.color:dock.colors.metal
                    border.width:1
                }
                Rectangle {x:21.6;y:98.2;width:295.8;height:1.3;color:dock.colors.engraving;opacity:.8}
                Rectangle {x:9;y:85.6;width:9;height:25.2;radius:2;color:dock.colors.metal}
                Rectangle {x:321;y:85.6;width:9;height:25.2;radius:2;color:dock.colors.metal}
                Repeater {
                    model:dock.records.slice(0,4)
                    Item {
                        required property var modelData
                        required property int index
                        readonly property real r:[25,27,24,26][index]
                        width:2*r;height:width
                        x:51+index*77-r;y:98.2-height
                        ArchiveScrollEnd {
                            id:glyph
                            record:parent.modelData;colors:dock.colors
                            visualRadius:parent.r
                            anchors.centerIn:parent
                            selected:dock.selectedId===record.id||dock.selectedIds.indexOf(record.id)>=0
                            provisional:dock.isPending(record.id)
                            opacity:dock.hiddenIds.indexOf(record.id)>=0?0:provisional ? .85 : 1
                        }
                        MouseArea {
                            anchors.fill:parent
                            preventStealing:true
                            enabled:!dock.locked
                            onPressed:function(mouse){var p=mapToItem(dock,mouse.x,mouse.y);dock.gestureStarted(parent.modelData,p.x,p.y,mouse.modifiers)}
                            onPositionChanged:function(mouse){if(pressed){var p=mapToItem(dock,mouse.x,mouse.y);dock.gestureMoved(p.x,p.y)}}
                            onReleased:function(mouse){var p=mapToItem(dock,mouse.x,mouse.y);dock.gestureReleased(p.x,p.y)}
                            onCanceled:dock.gestureCanceled()
                        }
                    }
                }
            }
        }
        Flickable {
            x:8; y:cradle.y+cradle.height+4; width:parent.width-16
            height: Math.max(0,parent.height-y-5)
            contentHeight: register.height
            contentWidth: width
            clip:true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: register
                width: parent.width
                spacing: 2
                Text {
                    visible: dock.recordCount===0
                    text:"Nothing carried"
                    color:dock.colors.engraving
                    font.pixelSize:11
                }
                Repeater {
                    model: dock.records
                    Rectangle {
                        required property var modelData
                        width:register.width; height:20
                        radius:3
                        color:dock.selectedId===modelData.id||dock.selectedIds.indexOf(modelData.id)>=0?View.mix(dock.colors.panel,dock.colors.engraving,.24):"transparent"
                        opacity:dock.hiddenIds.indexOf(modelData.id)>=0?0:1
                        Text {
                            anchors.fill:parent; anchors.leftMargin:5; anchors.rightMargin:5
                            verticalAlignment:Text.AlignVCenter
                            text:parent.modelData.name+(dock.isPending(parent.modelData.id)?" · pending":"")
                            textFormat:Text.PlainText
                            elide:Text.ElideRight
                            font.pixelSize:11
                            color:dock.colors.text
                        }
                        MouseArea {
                            anchors.fill:parent
                            preventStealing:true
                            enabled:!dock.locked
                            onPressed:function(mouse){var p=mapToItem(dock,mouse.x,mouse.y);dock.gestureStarted(parent.modelData,p.x,p.y,mouse.modifiers)}
                            onPositionChanged:function(mouse){if(pressed){var p=mapToItem(dock,mouse.x,mouse.y);dock.gestureMoved(p.x,p.y)}}
                            onReleased:function(mouse){var p=mapToItem(dock,mouse.x,mouse.y);dock.gestureReleased(p.x,p.y)}
                            onCanceled:dock.gestureCanceled()
                        }
                    }
                }
            }
        }
    }
    Rectangle {
        id: pill
        HoverHandler {id:pillHover;onHoveredChanged:if(hovered)dock.openHover();else dock.closeHover()}
        objectName: "case-pill"
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: 164; height: 34; radius: 17
        color: View.mix(dock.colors.background,dock.colors.panel,.65)
        border.color:dock.colors.metal
        Row {
            anchors.centerIn:parent; spacing:5
            ArchiveCaseIcon { ink:dock.colors.metal; anchors.verticalCenter:parent.verticalCenter }
            Text {color:dock.colors.text;font.pixelSize:11;font.bold:true;text:"Scroll Case";anchors.verticalCenter:parent.verticalCenter}
            Rectangle {
                width:Math.max(20,count.implicitWidth+8);height:20;radius:10
                anchors.verticalCenter:parent.verticalCenter
                color:View.mix(dock.colors.background,dock.colors.panel,.4)
                border.color:dock.colors.metal
                Text {id:count;anchors.centerIn:parent;color:dock.colors.text;font.pixelSize:10;text:dock.recordCount+(dock.motionPending||dock.pendingIds.length?"*":"")}
            }
            Text {color:dock.colors.engraving;text:dock.expanded?"⌄":"⌃";font.pixelSize:10;anchors.verticalCenter:parent.verticalCenter}
        }
        MouseArea {
            anchors.fill:parent
            onClicked: {dock.pinned=!dock.pinned;dock.dismissed=!dock.pinned;if(!dock.pinned)dock.hoverOpen=false}
        }
    }
}
