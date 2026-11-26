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
    onColorsChanged:refresh()
    onPalettesChanged:refresh()
    onDesktopPaletteChanged:refresh()
    onAvailableChanged:refresh()
    onVisibleChanged:refresh()
    onPaint:{
        if(!visible||!raster)return
        var r=raster,ctx=getContext("2d")
        ctx.reset();ctx.clearRect(0,0,width,height)
        function rgb(v){var s=String(v);return [parseInt(s.slice(1,3),16),parseInt(s.slice(3,5),16),parseInt(s.slice(5,7),16)]}
        var colorsByFace=r.faces.map(f=>rgb(View.roomPerspectiveColor(snapshot,f,palettes,desktopPalette,colors)))
        var floor=rgb(View.roomFloorColor(colors))
        var im=ctx.createImageData(r.w,r.h),data=im.data
        for(var i=0;i<r.winners.length;i++){
            var k=r.winners[i],c=k>=0?colorsByFace[k]:r.floor[i]?floor:null
            if(!c)continue
            var j=i*4
            data[j]=c[0];data[j+1]=c[1];data[j+2]=c[2];data[j+3]=255
        }
        ctx.putImageData(im,0,0)
        paintCount++
    }
}
