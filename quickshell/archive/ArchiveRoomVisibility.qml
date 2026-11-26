import QtQuick
import "ArchiveRoomProjection.mjs" as Projection
import "ArchiveView.mjs" as View

// Native logical pixel buffer. Raster geometry invalidates only when the
// committed projection changes. Selection outlines use a separate Canvas.
Canvas {
    id:surface
    required property var raster
    required property var snapshot
    required property var colors
    required property var palettes
    required property int desktopPalette
    property int paintCount:0
    width:raster?raster.w:1
    height:raster?raster.h:1
    smooth:false
    function refresh(){if(visible&&available&&raster)requestPaint()}
    onRasterChanged:refresh()
    onWidthChanged:refresh()
    onHeightChanged:refresh()
    onSnapshotChanged:refresh()
    onColorsChanged:refresh()
    onPalettesChanged:refresh()
    onDesktopPaletteChanged:refresh()
    onAvailableChanged:refresh()
    onVisibleChanged:refresh()
    onPaint:{
        if(!visible||!raster)return
        var r=raster,ctx=getContext("2d")
        ctx.reset();ctx.clearRect(0,0,width,height)
        var colorsByFace=r.faces.map(f=>View.roomPerspectiveColor(snapshot,f,palettes,desktopPalette,colors))
        var floor=View.roomFloorColor(colors),last=""
        var edgeColors=r.faces.map((f,i)=>View.roomEdgeColor(colorsByFace[i],f.shelfId?View.spatialPalette(snapshot,f.shelfId,palettes,desktopPalette):colors))
        // QML Canvas ImageData mutation is not assumed to behave like a
        // browser's typed array. Use the already proven integer fillRect
        // path; all runs are disjoint and derive from the visible IDs.
        Projection.visibilityRuns(r,function(x,y,w,key){
            var c=key>=0?colorsByFace[key]:floor
            if(c!==last){ctx.fillStyle=c;last=c}
            ctx.fillRect(x,y,w,1)
            // In-owner edge pixels only: never draw across a nearer face or
            // doorway. Keep narrow runs and frontal color samples untouched.
            if(key>=0&&r.faces[key].side!=="front"&&w>=8){
                ctx.fillStyle=edgeColors[key];last=edgeColors[key]
                ctx.fillRect(x,y,1,1);ctx.fillRect(x+w-1,y,1,1)
            }
        })
        paintCount++
    }
}
