import QtQuick
import ".." as Archive
import "../../widgets" as Widgets
import "../../services/AppMatching.js" as Matching
import "B7Ownership.mjs" as Mixed
import "B7Layout.mjs" as Layout
import "../ArchiveView.mjs" as View

// The wrapper covers the supported objects as well as the board. Each
// placement remains shelf-local; the model owns every record.
Item {
    id:shelf
    required property var module
    required property var colors
    required property Item plaqueHost
    property Item gestureHost:null
    property bool showBoard:true
    property bool spatialStyle:false
    property var apps: ({})
    signal appActivated(string appId)
    property bool browse:true
    property bool interactive:true
    property bool selected:false
    property string selectedRecordId:""
    property var hiddenIds:[]
    signal activated(string recordId)
    signal moveRequested(string holderId,int from,int to,string recordId)
    readonly property real rise:Mixed.validateShelf(module).reduce((h,b)=>Math.max(h,-b.y),0)
    readonly property real supportY:rise
    objectName:(showBoard?"mixed-shelf-":"mixed-top-")+module.id
    x:module.x;y:module.y-rise;width:module.w;height:rise+(showBoard?module.h:0)
    function displayRecord(r){
        if(!r)return null
        var p=Mixed.preferred(r)
        return Object.assign({},r,{variant:p.variant,kind:r.kind||r.fileType||p.family})
    }
    Archive.ArchiveShelf {
        module:Object.assign({},shelf.module,{x:0,y:shelf.supportY})
        colors:shelf.colors;browse:shelf.browse;selected:shelf.selected;spatialStyle:shelf.spatialStyle
        visible:shelf.showBoard;enabled:shelf.showBoard&&shelf.interactive
        onActivated:shelf.activated("")
    }
    Repeater {
        model:shelf.module.items||[]
        Loader {
            id:entry
            required property var modelData
            readonly property var value:modelData
            readonly property var record:value.kind==="object"?shelf.displayRecord(value.record):null
            sourceComponent:value.kind==="app"?bookComponent:value.kind==="holder"?holderComponent:record&&Mixed.preferred(record).family==="artwork"?frameComponent:objectComponent
            Component {
                id:bookComponent
                Widgets.Book {
                    objectName:"archive-book-"+entry.value.appId
                    appId:entry.value.appId
                    title:shelf.apps[appId]?shelf.apps[appId].title:appId
                    x:entry.value.x-width/2;y:shelf.supportY-height
                    readonly property var coordinated:View.bookColors(Matching.bindingColor(appId),shelf.colors)
                    coverColor:shelf.spatialStyle?coordinated.cover:Matching.bindingColor(appId)
                    metalColor:shelf.colors.metal
                    inscriptionColor:shelf.spatialStyle?coordinated.inscription:shelf.colors.engraving
                    ornamentColor:shelf.spatialStyle?coordinated.ornament:metalColor
                    spineLabel:shelf.spatialStyle?title.slice(0,7).toUpperCase():""
                    selectionColor:shelf.colors.engraving
                    runningColor:shelf.colors.engraving;focusedColor:shelf.colors.metal
                    running:false;focused:false;windowCount:0
                    enabled:shelf.interactive
                    onActivated:function(id){if(shelf.browse)shelf.appActivated(id);else if(!shelf.gestureHost||!shelf.gestureHost.bookDrag)shelf.appActivated(id)}
                    keyboardSelected:!!shelf.gestureHost&&shelf.gestureHost.selectedAppId===appId
                    // Keep the original delegate alive while dragging. The
                    // scene draws one outline; release creates the proposal.
                    MouseArea {
                        anchors.fill:parent;z:10
                        enabled:!shelf.browse&&shelf.interactive&&!!shelf.gestureHost
                        acceptedButtons:Qt.LeftButton
                        preventStealing:true
                        cursorShape:pressed?Qt.ClosedHandCursor:Qt.OpenHandCursor
                        onPressed:function(mouse){
                            var p=mapToItem(shelf.gestureHost,mouse.x,mouse.y)
                            mouse.accepted=shelf.gestureHost.beginBookDrag(shelf.module.id,entry.value.appId,p.x,p.y)
                        }
                        onPositionChanged:function(mouse){
                            if(pressed){var p=mapToItem(shelf.gestureHost,mouse.x,mouse.y);shelf.gestureHost.updateBookDrag(p.x,p.y)}
                        }
                        onReleased:function(mouse){
                            var p=mapToItem(shelf.gestureHost,mouse.x,mouse.y)
                            shelf.gestureHost.finishBookDrag(p.x,p.y)
                        }
                        onCanceled:if(shelf.gestureHost)shelf.gestureHost.cancelBookDrag()
                    }
                }
            }
            Component {
                id:objectComponent
                B7SupportedDisplay {
                    record:entry.record;colors:shelf.colors;plaqueHost:shelf.plaqueHost
                    contactX:entry.value.x;shelfY:shelf.supportY
                    artScale:entry.value.scale;mode:entry.value.support
                    selected:shelf.selectedRecordId===record.id
                    suppressed:shelf.hiddenIds.indexOf(record.id)>=0
                    enabled:shelf.interactive;gestureHost:shelf.browse?shelf.gestureHost:null
                    onActivated:function(id){shelf.activated(id)}
                }
            }
            Component {
                id:frameComponent
                B7ArtworkFrame {
                    objectName:"mixed-frame-"+record.id
                    record:entry.record;assetId:record.variant;colors:shelf.colors;plaqueHost:shelf.plaqueHost
                    x:entry.value.x-width/2;y:shelf.supportY-height
                    width:entry.value.frame.w;height:entry.value.frame.h;profile:entry.value.frame.profile
                    selected:shelf.selectedRecordId===record.id
                    suppressed:shelf.hiddenIds.indexOf(record.id)>=0
                    enabled:shelf.interactive;gestureHost:shelf.browse?shelf.gestureHost:null
                    onActivated:function(id){shelf.activated(id)}
                }
            }
            Component {
                id:holderComponent
                Item {
                    id:assembly
                    objectName:"mixed-holder-"+entry.value.id
                    readonly property var envelope:Layout.holderEnvelope(entry.value.scale,entry.value.w)
                    x:entry.value.x;y:0;width:envelope.width;height:shelf.supportY
                    B7UprightHolder {
                        id:holder
                        objectName:"holder-"+entry.value.id
                        width:entry.value.w;height:assembly.height
                        colors:shelf.colors;artScale:entry.value.scale
                        controlled:true;initialSlots:entry.value.slots.map(r=>shelf.displayRecord(r))
                        hiddenIds:shelf.hiddenIds
                        gestureHost:shelf.browse?shelf.gestureHost:null
                        enabled:shelf.browse&&shelf.interactive
                        onPresented:function(id){shelf.activated(id)}
                        onMoveRequested:function(from,to,id){shelf.moveRequested(entry.value.id,from,to,id)}
                    }
                    B7PresentationCradle {
                        objectName:"cradle-"+entry.value.id
                        x:holder.width+assembly.envelope.gap;width:assembly.envelope.cradleWidth;height:assembly.height
                        colors:shelf.colors;artScale:holder.artScale
                        record:holder.selectedRecord&&shelf.hiddenIds.indexOf(holder.selectedRecord.id)<0?holder.selectedRecord:null;plaqueHost:shelf.plaqueHost
                        enabled:shelf.browse&&shelf.interactive
                    }
                    MouseArea {
                        anchors.fill:parent;enabled:!shelf.browse&&shelf.interactive
                        onClicked:shelf.activated("")
                    }
                }
            }
        }
    }
}
