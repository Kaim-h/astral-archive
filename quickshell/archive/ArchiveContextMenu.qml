import QtQuick
import "ArchiveView.mjs" as View

// One transient root and at most one lateral child. No arrangement writes;
// the study host owns action dispatch, transaction guards and focus return.
FocusScope {
    id:menu
    required property var colors
    required property var entries
    property string heading:""
    property point anchorPoint:Qt.point(0,0)
    property int childIndex:-1
    readonly property var childEntries:childIndex>=0&&entries[childIndex]?entries[childIndex].items||[]:[]
    readonly property string childSide:rootBox.x+rootBox.width+childBox.width+6<=width-4?"right":
        rootBox.x-childBox.width-6>=4?"left":"stack"
    readonly property var rootIds:entries.map(e=>e.id)
    readonly property real rowStride:30
    readonly property real rootHeaderHeight:20
    // Root rows have explicit hit geometry, independent of Column polish.
    // Reopening at a different edge must not briefly expose old row bounds.
    function prepareOpen(){
        rootScroll.resetPosition()
        childScroll.resetPosition()
        forceActiveFocus()
        focusRow(rootRepeater,0,1)
    }
    function hoverRoot(index){
        var item=rootRepeater.itemAt(index)
        if(!visible||!item||!item.enabled)return
        if(entries[index].items){if(childIndex!==index)openChild(index,false)}
        else if(childIndex>=0)closeChild(false)
    }
    signal chosen(string action)
    signal dismissed()
    function closeChild(restore){
        var old=childIndex
        childIndex=-1
        if(restore&&old>=0&&rootRepeater.itemAt(old))rootRepeater.itemAt(old).forceActiveFocus()
    }
    function focusRow(repeater,start,step){
        for(var i=0;i<repeater.count;i++){
            var at=((start+i*step)%repeater.count+repeater.count)%repeater.count,item=repeater.itemAt(at)
            if(item&&item.enabled){
                item.forceActiveFocus();var scroll=repeater===rootRepeater?rootScroll:childScroll
                if(item.y<scroll.contentY)scroll.contentY=item.y
                else if(item.y+item.height>scroll.contentY+scroll.height)scroll.contentY=Math.max(0,item.y+item.height-scroll.height)
                return true
            }
        }
        return false
    }
    function openChild(index,focusIt){
        var item=rootRepeater.itemAt(index)
        if(!visible||!entries[index]||!entries[index].items||!item||!item.enabled)return
        if(childIndex!==index){childIndex=index;childScroll.resetPosition()}
        if(focusIt)Qt.callLater(function(){if(menu.visible&&menu.childIndex===index)menu.focusRow(childRepeater,0,1)})
    }
    function activate(entry,index){
        if(entry.enabled===false)return
        if(entry.items){openChild(index,true);return}
        chosen(entry.id)
    }
    function handleKey(event){
        if(event.key===Qt.Key_Escape){if(childIndex>=0)closeChild(true);else dismissed();event.accepted=true;return}
        var inChild=childIndex>=0&&childBox.activeFocus
        var rep=inChild?childRepeater:rootRepeater,index=-1
        for(var i=0;i<rep.count;i++)if(rep.itemAt(i)&&rep.itemAt(i).activeFocus)index=i
        if(event.key===Qt.Key_Up||event.key===Qt.Key_Down||event.key===Qt.Key_Tab||event.key===Qt.Key_Backtab){
            var step=event.key===Qt.Key_Up||event.key===Qt.Key_Backtab||(event.key===Qt.Key_Tab&&(event.modifiers&Qt.ShiftModifier))?-1:1
            focusRow(rep,index+step,step);event.accepted=true
        }else if(event.key===Qt.Key_Home||event.key===Qt.Key_End){
            focusRow(rep,event.key===Qt.Key_Home?0:rep.count-1,event.key===Qt.Key_Home?1:-1);event.accepted=true
        }else if(event.key===Qt.Key_Left||event.key===Qt.Key_Right){
            if(inChild)closeChild(true)
            else if(index>=0&&entries[index].items)openChild(index,true)
            event.accepted=true
        }
    }
    Keys.onPressed:function(event){menu.handleKey(event)}
    onVisibleChanged:{
        childIndex=-1
        if(visible){
            // Own the very first keyboard event, even before the repeater
            // or positioner has completed its deferred layout.
            prepareOpen()
            if(!rootRepeater.itemAt(0))Qt.callLater(function(){if(menu.visible&&menu.activeFocus&&!childBox.activeFocus)menu.focusRow(rootRepeater,0,1)})
        }
    }
    MouseArea {
        anchors.fill:parent
        acceptedButtons:Qt.AllButtons
        onWheel:function(wheel){wheel.accepted=true}
        onClicked:menu.dismissed()
    }
    Rectangle {
        id:rootBox
        objectName:"root-context-panel"
        width:Math.max(0,Math.min(218,menu.width-8))
        height:Math.max(0,Math.min(menu.height-8,rootRows.height+12))
        x:Math.max(4,Math.min(menu.width-width-4,menu.anchorPoint.x))
        y:Math.max(4,Math.min(menu.height-height-4,menu.anchorPoint.y))
        radius:6;color:View.mix(menu.colors.background,menu.colors.panel,.94);border.color:menu.colors.metal
        MouseArea {anchors.fill:parent;acceptedButtons:Qt.AllButtons;onWheel:function(wheel){wheel.accepted=true}}
        ArchiveInspectorScroll {
            id:rootScroll
            anchors.fill:parent;anchors.margins:6;contentHeight:rootRows.height
            Item {
                id:rootRows
                width:rootScroll.width;height:menu.rootHeaderHeight+menu.entries.length*menu.rowStride-4
                Text {text:menu.heading;color:menu.colors.engraving;font.pixelSize:11;height:16;verticalAlignment:Text.AlignVCenter}
                Repeater {
                    id:rootRepeater
                    model:menu.entries
                    ArchiveButton {
                        required property var modelData
                        required property int index
                        objectName:modelData.id
                        x:0;y:menu.rootHeaderHeight+index*menu.rowStride
                        width:rootRows.width;height:26;colors:menu.colors
                        label:modelData.label+(modelData.items?(menu.childSide==="left"?"  ‹":menu.childSide==="right"?"  ›":"  ⌄"):"")
                        hint:modelData.label
                        enabled:modelData.enabled!==false
                        active:activeFocus||menu.childIndex===index
                        onClicked:menu.activate(modelData,index)
                        readonly property bool pointerHovered:rootHover.hovered
                        HoverHandler {
                            id:rootHover
                            enabled:menu.visible&&parent.enabled
                            onHoveredChanged:if(hovered)menu.hoverRoot(parent.index)
                            // A translated/reopened menu can keep a pointer
                            // inside a delegate without a fresh enter edge.
                            // A real subsequent pointer movement still opens it.
                            property point lastScenePoint:Qt.point(-1,-1)
                            onPointChanged:{
                                var at=point.scenePosition
                                if(hovered&&(at.x!==lastScenePoint.x||at.y!==lastScenePoint.y))menu.hoverRoot(parent.index)
                                lastScenePoint=at
                            }
                        }
                    }
                }
            }
        }
    }
    FocusScope {
        id:childBox
        objectName:"root-context-flyout"
        visible:menu.childIndex>=0
        width:Math.max(0,Math.min(206,menu.width-8))
        height:Math.max(0,Math.min(menu.height-8,childRows.height+12))
        x:Math.max(4,Math.min(menu.width-width-4,menu.childSide==="right"?rootBox.x+rootBox.width+6:menu.childSide==="left"?rootBox.x-width-6:rootBox.x))
        readonly property var anchorRow:menu.childIndex>=0?rootRepeater.itemAt(menu.childIndex):null
        readonly property real rowY:anchorRow?anchorRow.mapToItem(menu,0,0).y:rootBox.y
        y:Math.max(4,Math.min(menu.height-height-4,menu.childSide==="stack"?rowY+30:rowY))
        Rectangle {
            anchors.fill:parent;radius:6;color:View.mix(menu.colors.background,menu.colors.panel,.96);border.color:menu.colors.metal
            MouseArea {anchors.fill:parent;acceptedButtons:Qt.AllButtons;onWheel:function(wheel){wheel.accepted=true}}
        }
        ArchiveInspectorScroll {
            id:childScroll
            anchors.fill:parent;anchors.margins:6;contentHeight:childRows.height
            Item {
                id:childRows;width:childScroll.width;height:Math.max(0,menu.childEntries.length*menu.rowStride-4)
                Repeater {
                    id:childRepeater;model:menu.childEntries
                    ArchiveButton {
                        required property var modelData
                        required property int index
                        objectName:modelData.id
                        x:0;y:index*menu.rowStride
                        width:childRows.width;height:26;colors:menu.colors
                        label:modelData.label;hint:modelData.label;enabled:modelData.enabled!==false
                        active:activeFocus
                        onClicked:menu.chosen(modelData.id)
                    }
                }
            }
        }
    }
}
