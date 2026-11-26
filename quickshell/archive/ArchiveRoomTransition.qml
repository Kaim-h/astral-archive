import QtQuick
import "ArchiveRoomTransition.mjs" as Transition
import "ArchiveView.mjs" as View

// A single opaque carrier after the origin dissolve: projected shell, shared
// flat front while focus finishes, then the live front at the same transform.
// The live scene reveals its interior separately. No whole-front crossfade.
Item {
    id:bridge
    required property var navigation
    required property real progress
    readonly property var layers:Transition.layers(progress)
    clip:true
    Canvas {
        id:projected
        anchors.fill:parent
        visible:bridge.visible&&!!bridge.navigation&&bridge.layers.shell>0
        opacity:bridge.layers.shell
        property int paintCount:0
        property real lastPaintMs:0
        function refresh(){if(visible&&available)requestPaint()}
        Connections {
            target:bridge
            function onNavigationChanged(){projected.refresh()}
            function onProgressChanged(){projected.refresh()}
        }
        onWidthChanged:refresh()
        onHeightChanged:refresh()
        onAvailableChanged:refresh()
        onVisibleChanged:refresh()
        onPaint:{
            if(!visible||!bridge.navigation)return
            var start=Date.now(),ctx=getContext("2d");ctx.reset();ctx.clearRect(0,0,width,height)
            var n=bridge.navigation,p=n.palette
            for(var f of Transition.surfaces(n.geometry,bridge.progress)){
                var fill=View.architectureSurfaceColor(f,n.frameColor,n.backing,p)
                var q=f.points
                ctx.beginPath();ctx.moveTo(q[0][0],q[0][1])
                for(var i=1;i<q.length;i++)ctx.lineTo(q[i][0],q[i][1])
                ctx.closePath();ctx.fillStyle=fill;ctx.fill()
            }
            paintCount++;lastPaintMs=Date.now()-start
        }
    }
    readonly property alias projectedPaintCount:projected.paintCount
    readonly property alias projectedPaintMs:projected.lastPaintMs
    Item {
        id:flatFront
        objectName:"room-navigation-flat-carrier"
        visible:!!bridge.navigation&&bridge.layers.flat
        readonly property var n:bridge.navigation
        readonly property var g:n?n.geometry.g:null
        readonly property var a:g?Transition.point(n.geometry,[0,g.depth,g.h],bridge.progress):[0,0]
        readonly property var b:g?Transition.point(n.geometry,[g.w,g.depth,g.h],bridge.progress):[1,0]
        x:a[0];y:a[1];width:g?g.w:1;height:g?g.h:1
        scale:g?Math.max(.0001,(b[0]-a[0])/g.w):1
        transformOrigin:Item.TopLeft
        ArchiveProfileFront {
            anchors.fill:parent
            visible:flatFront.visible
            profileGeometry:flatFront.g
            colors:flatFront.n?flatFront.n.palette:({})
            frameColor:flatFront.n?flatFront.n.frameColor:"transparent"
        }
        Rectangle {
            visible:flatFront.visible
            x:flatFront.g?flatFront.g.aperture.x:0;y:flatFront.g?flatFront.g.aperture.y:0
            width:flatFront.g?flatFront.g.aperture.w:0;height:flatFront.g?flatFront.g.aperture.h:0
            color:flatFront.n?flatFront.n.backing:"transparent"
            border.color:flatFront.n?View.mix(flatFront.n.palette.metal,flatFront.n.palette.panel,.32):"transparent"
        }
        ArchiveShelfInscription {
            visible:flatFront.visible
            inscription:flatFront.g?flatFront.g.inscription:{x:0,y:0,w:0,h:0}
            shelfName:flatFront.n?flatFront.n.name:""
            colors:flatFront.n?flatFront.n.palette:{text:"transparent"}
        }
    }
}
