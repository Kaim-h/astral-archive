import QtQuick
import "ArchiveView.mjs" as View

// Actual filled profile polygons from the shared physical model. No
// rectangle behind the crest or post overhang; no stroke outside bounds.
Canvas {
    id:front
    required property var profileGeometry
    required property var colors
    required property color frameColor
    property string family:"None"
    property string emblemKey:""
    readonly property var crestBounds:View.crestMarkBounds(profileGeometry)
    clip:true
    Item {
        x:front.crestBounds?front.crestBounds.x:0;y:front.crestBounds?front.crestBounds.y:0
        width:front.crestBounds?front.crestBounds.w:0;height:width
        visible:!!front.crestBounds
        ArchiveFamilyMark {
            objectName:"physical-crest-mark"
            family:front.family;emblemKey:front.emblemKey;colors:front.colors
            exterior:true;width:parent.width;height:width;opacity:.68
        }
    }
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
            ctx.fillStyle=View.profilePartColor(part.role,String(frameColor),colors)
            ctx.fill()
            // Fine edge entirely inside the existing polygon. Clip the
            // stroke to the supporting profile so overhang/aperture stay open.
            if(part.role!=="foot"&&part.role!=="capital"&&part.role!=="base"){
                ctx.save();ctx.clip()
                ctx.strokeStyle=View.mix(String(frameColor),colors.metal,.52)
                ctx.lineWidth=Math.min(2.4,profileGeometry.inscription.h*.10)
                ctx.stroke();ctx.restore()
            }
            if(part.role==="left-post"||part.role==="right-post"){
                var x=pts[0][0],y=pts[0][1],w=pts[1][0]-x,h=pts[2][1]-y
                var inset=w*.22,thin=Math.min(1.1,w*.09)
                ctx.fillStyle=View.mix(String(frameColor),colors.engraving,.42)
                ctx.fillRect(x+inset,y+inset,thin,Math.max(0,h-2*inset))
                ctx.fillRect(x+w-inset-thin,y+inset,thin,Math.max(0,h-2*inset))
            }
        }
        // Restrained in-envelope rules. These are fills, not outward strokes.
        var g=profileGeometry,band=Math.min(1.4,g.inscription.h*.08)
        ctx.fillStyle=colors.metal
        ctx.fillRect(g.inscription.x,g.inscription.y+band,g.inscription.w,band)
        ctx.fillRect(g.inscription.x,g.inscription.y+g.inscription.h-2*band,g.inscription.w,band)
        ctx.fillRect(g.aperture.x,g.aperture.y+g.aperture.h+band,g.aperture.w,band)
        // Subtle balanced lintel accents, well outside ordinary title center.
        if(g.inscription.w>g.inscription.h*16){
            var r=g.inscription.h*.13,cy=g.inscription.y+g.inscription.h/2
            ctx.fillStyle=View.mix(String(frameColor),colors.engraving,.60)
            for(var cx of [g.inscription.x+g.inscription.h*.8,g.inscription.x+g.inscription.w-g.inscription.h*.8]){
                ctx.beginPath();ctx.moveTo(cx-r,cy);ctx.lineTo(cx,cy-r)
                ctx.lineTo(cx+r,cy);ctx.lineTo(cx,cy+r);ctx.closePath();ctx.fill()
            }
        }
    }
}
