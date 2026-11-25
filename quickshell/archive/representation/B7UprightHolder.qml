import QtQuick
import "B7Layout.mjs" as Layout

// U3-inspired holder: visual arrangement only, no ArchiveCore ownership.
Item {
    id:holder
    required property var colors
    required property var initialSlots
    property var slots:initialSlots.slice()
    // Standalone N1 keeps local synthetic slots; the integrated cubby uses
    // revision-bound model commits and never independently changes ownership.
    property bool controlled:false
    property Item gestureHost:null
    signal moveRequested(int from,int to,string recordId)
    signal presented(string recordId)
    onInitialSlotsChanged:if(controlled){cancelGesture();slots=initialSlots.slice();if(selectedId&&!slots.some(r=>r&&r.id===selectedId))selectedId=""}
    property string selectedId:""
    readonly property var selectedRecord:slots.find(r=>r&&r.id===selectedId)||null
    property real artScale:.95
    readonly property real floor:height-22
    readonly property real hitTop:Math.max(0,floor-205*artScale-8)
    readonly property var layout:Layout.uprightGeometry(slots,artScale,Math.max(1,width-24),floor)
    readonly property real slotOrigin:(width-layout.span)/2
    property int keyboardSource:-1
    property int pressSlot:-1
    property int dropSlot:-1
    property bool dragActive:false
    property point startLocal:Qt.point(0,0)
    property point startScreen:Qt.point(0,0)
    property point dragPoint:Qt.point(0,0)
    readonly property var dragRecord:pressSlot>=0?slots[pressSlot]:null
    property string notice:"Select an edge to present it; drag to move or swap."
    function resetSlots(){
        cancelGesture();keyboardSource=-1;selectedId="";slots=initialSlots.slice()
        notice="Select an edge to present it; drag to move or swap."
    }
    function returnItem(){
        selectedId="";notice="Returned to its reserved slot."
    }
    function focusSlot(i){var item=slotRepeater.itemAt(i);if(item)item.forceActiveFocus()}
    function present(i){
        if(!slots[i])return
        keyboardSource=-1;selectedId=slots[i].id
        notice=slots[i].name+" · presented in cradle"
        presented(selectedId)
    }
    function slotAt(p){
        if(p.y<hitTop||p.y>height)return -1
        for(var i=0;i<layout.slots.length;i++){
            var s=layout.slots[i]
            if(p.x>=slotOrigin+s.left&&p.x<slotOrigin+s.left+s.width)return i
        }
        return -1
    }
    function move(from,to){
        if(from<0||to<0||from===to||!slots[from]){
            notice="Arrangement unchanged.";return false
        }
        var moved=slots[from],other=slots[to]
        var next=Layout.moveSlot(slots,from,to)
        if(next===slots)return false
        if(controlled){moveRequested(from,to,moved.id);return true}
        if(selectedId===moved.id)selectedId=""
        slots=next
        notice=other?"Swapped "+moved.name+" with "+other.name:"Moved "+moved.name+" to slot "+(to+1)
        return true
    }
    function cancelGesture(){
        dragActive=false;pressSlot=-1;dropSlot=-1
    }
    function cancelInput(){
        if(pressSlot>=0){cancelGesture();notice="Move canceled."}
        else if(keyboardSource>=0){keyboardSource=-1;notice="Move canceled."}
        else returnItem()
    }
    function begin(i,p,screen){
        if(!slots[i])return
        keyboardSource=-1;pressSlot=i;startLocal=p;startScreen=screen
        dragPoint=p;dropSlot=-1;dragActive=false
    }
    function updateDrag(p,screen){
        if(pressSlot<0)return
        if(!dragActive&&Math.hypot(screen.x-startScreen.x,screen.y-startScreen.y)<5)return
        dragActive=true;dragPoint=p;dropSlot=slotAt(p)
    }
    function finish(p,screen){
        if(pressSlot<0)return
        updateDrag(p,screen)
        var from=pressSlot,target=slotAt(p),moved=dragActive
        cancelGesture()
        if(moved){
            if(target<0&&gestureHost&&slots[from]){
                var id=slots[from].id,drop=mapToItem(gestureHost,p.x,p.y)
                gestureHost.transferMixedDrop(id,drop.x,drop.y)
            }else{
                // Commit may replace the whole controlled delegate. Do not
                // invoke a focus method on it after publishing the snapshot.
                focusSlot(target>=0?target:from);move(from,target)
            }
        }else if(target===from)present(from)
    }
    onVisibleChanged:if(!visible){cancelGesture();keyboardSource=-1;selectedId=""}

    // U3 rear rail ends line up with both cheeks, all pieces on common floor.
    Rectangle {
        x:holder.slotOrigin-3;y:holder.floor-13;width:holder.layout.span+6;height:13
        color:holder.colors.background;border.color:holder.colors.metal;radius:1
    }
    Rectangle {
        x:holder.slotOrigin-3;y:holder.floor-46;width:holder.layout.span+6;height:6
        color:holder.colors.metal;opacity:.65;radius:1
    }
    Repeater {
        model:[-1,1]
        Rectangle {
            required property int modelData
            x:modelData<0?holder.slotOrigin-3:holder.slotOrigin+holder.layout.span-2
            y:holder.floor-46;width:5;height:46;color:holder.colors.metal;radius:1
        }
    }
    Repeater {
        id:slotRepeater
        // A fixed count keeps actual pointer/focus targets alive when slot
        // contents and widths change; geometry is a value binding.
        model:holder.slots.length
        Item {
            id:slot
            required property int index
            readonly property var slotGeometry:holder.layout.slots[index]
            objectName:"b7-slot-"+index
            x:holder.slotOrigin+slotGeometry.left;y:holder.hitTop;width:slotGeometry.width;height:holder.height-y
            property var record:holder.slots[index]
            readonly property bool presented:!!record&&record.id===holder.selectedId
            readonly property var edgePlacement:record?Layout.uprightEdge(record,slotGeometry,holder.artScale,holder.layout.fit,holder.slotOrigin):null
            activeFocusOnTab:true
            Accessible.role:Accessible.Button
            Accessible.name:record?record.name+(presented?", in cradle":""):"Open slot "+(index+1)
            Accessible.onPressAction:holder.present(index)
            Rectangle {
                anchors.fill:parent;anchors.margins:1;radius:2;color:"transparent"
                border.color:holder.colors.engraving
                border.width:1
                visible:slot.activeFocus||holder.keyboardSource===slot.index||holder.dropSlot===slot.index
                opacity:holder.dropSlot===slot.index?1:.6
            }
            Loader {
                active:!!slot.record
                visible:!slot.presented
                opacity:holder.dragActive&&holder.pressSlot===slot.index?.35:1
                sourceComponent:B7AssetImage {
                    assetId:slot.record?slot.record.variant:"record/v1";edge:true;fillMode:Image.Stretch
                    x:slot.edgePlacement?slot.edgePlacement.x-slot.x:0
                    y:slot.edgePlacement?slot.edgePlacement.y-slot.y:0
                    width:slot.edgePlacement?slot.edgePlacement.width:0
                    height:slot.edgePlacement?slot.edgePlacement.height:0
                }
            }
            Rectangle {
                x:slot.slotGeometry.cx-slot.slotGeometry.left-slot.slotGeometry.w/2
                y:slot.slotGeometry.y-slot.y;width:slot.slotGeometry.w;height:slot.slotGeometry.h
                radius:2;color:"transparent";border.color:holder.colors.engraving;opacity:.45
                visible:slot.presented
            }
            Text {
                visible:!slot.record
                x:0;y:holder.floor-slot.y-20;width:slot.width
                text:"+";color:holder.colors.engraving;opacity:.65
                horizontalAlignment:Text.AlignHCenter;font.pixelSize:14
            }
            Keys.onPressed:function(event){
                if(event.key===Qt.Key_Escape){holder.cancelInput();event.accepted=true}
                else if(event.key===Qt.Key_Left||event.key===Qt.Key_Right){
                    holder.focusSlot((index+holder.slots.length+(event.key===Qt.Key_Right?1:-1))%holder.slots.length)
                    event.accepted=true
                }else if(event.key===Qt.Key_Return||event.key===Qt.Key_Enter||event.key===Qt.Key_Space){
                    if(holder.keyboardSource>=0){
                        var from=holder.keyboardSource;holder.keyboardSource=-1;holder.focusSlot(index);holder.move(from,index)
                    }else if(event.key===Qt.Key_Space){
                        if(slot.record){holder.keyboardSource=index;holder.notice="Choose a destination slot."}
                    }else holder.present(index)
                    event.accepted=true
                }
            }
            MouseArea {
                anchors.fill:parent;acceptedButtons:Qt.LeftButton;preventStealing:true
                cursorShape:slot.record?Qt.PointingHandCursor:Qt.ArrowCursor
                onPressed:function(mouse){
                    slot.forceActiveFocus()
                    holder.begin(slot.index,mapToItem(holder,mouse.x,mouse.y),mapToItem(null,mouse.x,mouse.y))
                }
                onPositionChanged:function(mouse){
                    if(pressed)holder.updateDrag(mapToItem(holder,mouse.x,mouse.y),mapToItem(null,mouse.x,mouse.y))
                }
                onReleased:function(mouse){holder.finish(mapToItem(holder,mouse.x,mouse.y),mapToItem(null,mouse.x,mouse.y))}
                onCanceled:holder.cancelGesture()
            }
        }
    }
    // Front fascia overlays the stored edges' lower supports, not hit testing.
    Rectangle {
        x:holder.slotOrigin-12;y:holder.floor;width:holder.layout.span+24;height:22
        color:holder.colors.background;border.color:holder.colors.metal;radius:2
        Rectangle {x:2;y:2;width:parent.width-4;height:1;color:holder.colors.engraving;opacity:.45}
    }
    Repeater {
        model:holder.layout.slots
        Item {
            required property int index
            required property var modelData
            x:holder.slotOrigin+modelData.left;y:holder.floor-17;width:modelData.width;height:39
            Rectangle {
                visible:index>0;x:-2;y:0;width:4;height:19;radius:1.6
                color:holder.colors.background;border.color:holder.colors.metal
            }
            Rectangle {
                x:parent.width/2-2.6;y:29;width:5.2;height:5.2;radius:2.6
                color:holder.slots[index]?Layout.assetFor(holder.slots[index].variant).geometry.accent:"transparent"
                border.color:holder.slots[index]?color:holder.colors.engraving
                opacity:.7
            }
        }
    }
    Repeater {
        model:[-1,1]
        Rectangle {
            required property int modelData
            x:modelData<0?holder.slotOrigin-12:holder.slotOrigin+holder.layout.span+3
            y:holder.floor-65;width:9;height:65;radius:2
            color:holder.colors.background;border.color:holder.colors.metal
        }
    }
    Loader {
        z:10;active:holder.dragActive&&!!holder.dragRecord
        sourceComponent:B7AssetImage {
            assetId:holder.dragRecord?holder.dragRecord.variant:"record/v1";edge:true;fillMode:Image.Stretch;opacity:.85
            readonly property var edgeBox:holder.dragRecord?Layout.uprightEdge(holder.dragRecord,holder.layout.slots[holder.pressSlot],holder.artScale,holder.layout.fit,holder.slotOrigin):null
            x:edgeBox?edgeBox.x+holder.dragPoint.x-holder.startLocal.x:0
            y:edgeBox?edgeBox.y+holder.dragPoint.y-holder.startLocal.y:0
            width:edgeBox?edgeBox.width:0;height:edgeBox?edgeBox.height:0
        }
    }
}
