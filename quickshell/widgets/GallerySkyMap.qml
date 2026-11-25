import QtQuick
import "../services/GalleryPolicy.js" as Policy

// Constellation lines for the full-screen sky, from the same catalogue points
// as GalleryDrum. Painted once when the artwork, size or theme changes, not
// repainted for each pixel-colony transition frame.
Item {
    id:sky
    property var constellations: []
    property color strokeColor: '#b9d6c9'
    property color starColor: '#f0eadd'
    onConstellationsChanged: chart.requestPaint()
    onStrokeColorChanged: chart.requestPaint()
    onStarColorChanged: chart.requestPaint()
    Canvas {
        id:chart;anchors.fill:parent
        antialiasing:true;renderTarget:Canvas.Image
        onWidthChanged:requestPaint()
        onHeightChanged:requestPaint()
        onPaint: {
            var ctx=getContext('2d');ctx.reset();ctx.clearRect(0,0,width,height);
            var cells=Policy.skyCells(sky.constellations||[],width,height);
            if(!cells.length)return;
            ctx.lineCap='round';ctx.lineJoin='round';
            for (var i=0;i<cells.length;i++){
                var cell=cells[i],d=cell.definition,points=Object.create(null),stars=d.stars||[];
                // Preserve the canonical figure while fitting its screen slot.
                for(var s=0;s<stars.length;s++){
                    var p=stars[s];points[p.id]=Policy.figurePoint(cell.fit,p);
                }
                ctx.beginPath();ctx.lineWidth=.8;ctx.strokeStyle=sky.strokeColor;
                ctx.globalAlpha=.48;
                var edges=d.edges||[];
                for(var e=0;e<edges.length;e++){
                    var a=points[edges[e][0]],b=points[edges[e][1]];
                    if(!a||!b)continue;ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);
                }
                ctx.stroke();ctx.globalAlpha=1;
                for(var j=0;j<stars.length;j++){
                    var st=stars[j],xy=points[st.id];if(!xy)continue;
                    ctx.globalAlpha=.63+Math.min(1,Number(st.brightness||.6))*.34;
                    ctx.fillStyle=sky.starColor;ctx.beginPath();
                    ctx.arc(xy.x,xy.y,Number(st.brightness)>.85?2.1:1.35,0,2*Math.PI);ctx.fill();
                }
                ctx.globalAlpha=.5;ctx.textAlign='center';ctx.font='11px Georgia';
                ctx.fillStyle=sky.strokeColor;ctx.fillText(String(d.name),cell.labelX,cell.labelY);
                ctx.globalAlpha=1;
            }
        }
    }
}
