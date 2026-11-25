import QtQuick

// Standalone B7-N1 retains click-only semantics. Integrated scene owns
// the provisional transaction and its mouse capture until release/cancel.
MouseArea {
    id:gesture
    property Item gestureHost:null
    required property string recordId
    property bool tracking:false
    property bool moved:false
    property point startPoint:Qt.point(0,0)
    signal activated()
    acceptedButtons:Qt.LeftButton
    preventStealing:true
    cursorShape:Qt.PointingHandCursor
    onPressed:function(mouse){
        moved=false;tracking=false
        if(gestureHost){
            var p=mapToItem(gestureHost,mouse.x,mouse.y)
            startPoint=p;tracking=gestureHost.beginMixedGesture(recordId,p.x,p.y)
        }
    }
    onPositionChanged:function(mouse){
        if(!pressed||!tracking||!gestureHost)return
        var p=mapToItem(gestureHost,mouse.x,mouse.y)
        if(Math.hypot(p.x-startPoint.x,p.y-startPoint.y)>=4)moved=true
        gestureHost.moveGesture(p.x,p.y)
    }
    onReleased:function(mouse){
        if(!tracking||!gestureHost)return
        var p=mapToItem(gestureHost,mouse.x,mouse.y)
        if(Math.hypot(p.x-startPoint.x,p.y-startPoint.y)>=4)moved=true
        tracking=false
        gestureHost.endGesture(p.x,p.y)
    }
    onCanceled:{
        if(tracking&&gestureHost&&gestureHost.pointer)gestureHost.abortGesture()
        tracking=false;moved=false
    }
    onClicked:if(!moved)activated()
}
