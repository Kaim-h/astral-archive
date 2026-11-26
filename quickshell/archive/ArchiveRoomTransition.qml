import QtQuick
import "ArchiveRoomTransition.mjs" as Transition
import "ArchiveView.mjs" as View

// Transition-only bridge; live Shelf remains the destination. No cached
// reference plate or screenshot, and no frame loop when inactive.
Canvas {
    id:bridge
    required property var navigation
    required property real progress
    clip:true
    function refresh(){if(visible&&available)requestPaint()}
    onNavigationChanged:refresh()
    onProgressChanged:refresh()
    onWidthChanged:refresh()
    onHeightChanged:refresh()
    onAvailableChanged:refresh()
    onVisibleChanged:refresh()
    onPaint:{
        if(!visible)return
        var ctx=getContext("2d");ctx.reset();ctx.clearRect(0,0,width,height)
        if(!navigation)return
        var n=navigation,p=n.palette,alpha=Transition.layers(progress).shell
        if(alpha<=0)return
        ctx.globalAlpha=alpha
        for(var f of Transition.surfaces(n.geometry,progress)){
            var fill=f.role==="backing"?n.backing:View.profilePartColor(f.role,n.frameColor,p)
            if(f.side!=="front")fill=View.mix(p.background,fill,f.side==="back"?.75:.85)
            var q=f.points
            ctx.beginPath();ctx.moveTo(q[0][0],q[0][1])
            for(var i=1;i<q.length;i++)ctx.lineTo(q[i][0],q[i][1])
            ctx.closePath();ctx.fillStyle=fill;ctx.fill()
        }
        ctx.globalAlpha=1
    }
}
