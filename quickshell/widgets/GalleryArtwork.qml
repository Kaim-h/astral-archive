import QtQuick
import "../config/GalleryGeometry.js" as Geometry

// Only the painted crop moves; the masonry is another static Image layer.
// The QML Canvas keeps the approved 60%-source crop and continuous, slow
// non-repeating-feeling pan with rests. No user drag or wallpaper changes.
Item {
    id: galleryArt
    width: 456; height: 721
    property url source: ""
    property bool active: true
    property bool focused: false
    property var palette: ({background:"#121e23",panel:"#263c37",metal:"#8c6e5a",engraving:"#91ada1",text:"#e6e1d8"})
    property real sourceFraction: .60
    property int travelSeconds: 45
    property real edgeWidth: 15
    property real edgeStrength: .82
    property real panClockMs: 0
    property real u: .5
    property real v: .5
    property double lastTick: 0
    signal selected()

    readonly property real artLeft: Geometry.aperture.left
    readonly property real artTop: Geometry.aperture.top
    readonly property real artWidth: Geometry.aperture.right-Geometry.aperture.left
    readonly property real artHeight: Geometry.aperture.bottom-Geometry.aperture.top

    onSourceChanged: {
        if (String(source).length) paint.loadImage(String(source));
        paint.requestPaint();
    }
    onPaletteChanged: paint.requestPaint()
    onEdgeWidthChanged: paint.requestPaint()
    onEdgeStrengthChanged: paint.requestPaint()
    onUChanged: paint.requestPaint()
    onVChanged: paint.requestPaint()

    Image {
        id: nativeSize
        visible: false
        asynchronous: true
        cache: false
        source: galleryArt.source
        onStatusChanged: paint.requestPaint()
    }
    Canvas {
        id: paint
        anchors.fill: parent
        renderTarget: Canvas.Image
        antialiasing: true
        onImageLoaded: requestPaint()
        function openingPath(ctx) {
            var p=Geometry.aperture.innerCurve;
            ctx.beginPath();
            ctx.moveTo(p[0][0],Geometry.aperture.bottom);
            ctx.lineTo(p[0][0],p[0][1]);
            for(var i=1;i<p.length;i++)ctx.lineTo(p[i][0],p[i][1]);
            ctx.lineTo(p[p.length-1][0],Geometry.aperture.bottom);
            ctx.closePath();
        }
        onPaint: {
            var ctx=getContext('2d');ctx.reset();ctx.clearRect(0,0,width,height);
            openingPath(ctx);ctx.save();ctx.clip();
            ctx.fillStyle=galleryArt.palette.background;
            ctx.fillRect(artLeft,artTop,artWidth,artHeight);
            if(String(galleryArt.source).length && paint.isImageLoaded(String(galleryArt.source)) && nativeSize.status===Image.Ready){
                var iw=nativeSize.implicitWidth,ih=nativeSize.implicitHeight;
                if(iw>0&&ih>0){
                    var frac=Math.max(.18,Math.min(.94,galleryArt.sourceFraction));
                    var scale=Math.max(artWidth/(iw*frac),artHeight/(ih*frac));
                    var w=iw*scale,h=ih*scale;
                    var x=artLeft-(w-artWidth)*galleryArt.u;
                    var y=artTop-(h-artHeight)*galleryArt.v;
                    ctx.drawImage(String(galleryArt.source),x,y,w,h);
                }
            } else {
                ctx.fillStyle=galleryArt.palette.engraving;
                ctx.font='11px serif';ctx.textAlign='center';
                ctx.fillText('SELECT A GALLERY ARTWORK',228,484);
            }
            // The light grey / stone mist is applied in curved bands of
            // progressively declining alpha toward the interior, following
            // the exact clip and arch profile. Width/strength are independent.
            if(galleryArt.edgeWidth>0&&galleryArt.edgeStrength>0){
                var color=galleryArt.palette.engraving;
                for(var j=0;j<9;j++){
                    var f=j/9;
                    ctx.globalAlpha=galleryArt.edgeStrength*(.21*(1-f)*(1-f));
                    openingPath(ctx);
                    ctx.lineWidth=galleryArt.edgeWidth*(1-f)*2;
                    ctx.strokeStyle=color;ctx.stroke();
                }
                ctx.globalAlpha=1;
            }
            ctx.restore();
        }
    }
    Timer {
        id: animationClock
        interval: 55 // independent from dome's 10 fps search
        repeat: true
        running: galleryArt.active && !galleryArt.focused &&
                 nativeSize.status===Image.Ready && String(galleryArt.source).length>0
        onRunningChanged: galleryArt.lastTick = 0
        onTriggered: {
            var t=Date.now();
            if(!galleryArt.lastTick){galleryArt.lastTick=t;return;}
            var dt=Math.min(110,t-galleryArt.lastTick);
            galleryArt.lastTick=t;
            galleryArt.panClockMs+=dt;
            var cycle=galleryArt.panClockMs/(galleryArt.travelSeconds*1000);
            var leg=Math.floor(cycle),f=(cycle-leg)/.80;
            // Exact rest: last 20% of the travel duration produces no repaint.
            if(f>=1)return;
            f=Math.max(0,f);
            var ease=f*f*f*(f*(f*6-15)+10);
            var phase=(leg+ease)*.60,k=Math.PI*phase;
            galleryArt.u=Math.max(.04,Math.min(.96,.5+.34*Math.sin(k+.25)+.08*Math.sin(.57*k+1.2)));
            galleryArt.v=Math.max(.04,Math.min(.96,.5+.35*Math.sin(.78*k+1.47)+.07*Math.sin(1.31*k-.6)));
        }
    }
    MouseArea {
        x: galleryArt.artLeft; y: galleryArt.artTop
        width: galleryArt.artWidth; height: galleryArt.artHeight
        cursorShape: Qt.PointingHandCursor
        onClicked: galleryArt.selected()
    }
}
