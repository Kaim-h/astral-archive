import QtQuick
import "ArchiveView.mjs" as View

// Actual filled profile polygons from the shared physical model. No
// rectangle behind the crest or post overhang; no stroke outside bounds.
Canvas {
    id:front
    required property var profileGeometry
    required property var colors
    required property color frameColor
    clip:true
    onProfileGeometryChanged:if(visible)requestPaint()
    onColorsChanged:if(visible)requestPaint()
    onFrameColorChanged:if(visible)requestPaint()
    onVisibleChanged:if(visible)requestPaint()
    onAvailableChanged:if(available&&visible)requestPaint()
    onWidthChanged:if(visible)requestPaint()
    onHeightChanged:if(visible)requestPaint()
    onPaint:{
        if(!visible)return
        var ctx=getContext("2d")
        ctx.reset();ctx.clearRect(0,0,width,height)
        if(!profileGeometry)return
        for(var part of profileGeometry.parts){
            var pts=part.points
            ctx.beginPath();ctx.moveTo(pts[0][0],pts[0][1])
            for(var i=1;i<pts.length;i++)ctx.lineTo(pts[i][0],pts[i][1])
            ctx.closePath()
            ctx.fillStyle=part.role==="foot"||part.role==="capital"||part.role==="base"?
                View.mix(String(frameColor),colors.metal,.32):part.role==="crest"?
                View.mix(String(frameColor),colors.metal,.16):frameColor
            ctx.fill()
        }
        // Restrained in-envelope rules. These are fills, not outward strokes.
        var g=profileGeometry,band=Math.min(1.4,g.inscription.h*.08)
        ctx.fillStyle=colors.metal
        ctx.fillRect(g.inscription.x,g.inscription.y+band,g.inscription.w,band)
        ctx.fillRect(g.inscription.x,g.inscription.y+g.inscription.h-2*band,g.inscription.w,band)
        ctx.fillRect(g.aperture.x,g.aperture.y+g.aperture.h+band,g.aperture.w,band)
    }
}
