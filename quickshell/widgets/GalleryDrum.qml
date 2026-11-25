import QtQuick
import "../services/GalleryPolicy.js" as Policy

// Single authored rotating material. Every constellation, star, inscription,
// ordinal mark and seam is painted into the SAME Canvas texture. No independent
// static constellation ornaments. Its light/shadow overlay is fixed lighting.
Item {
    id: drum
    width:282; height:167
    clip:true
    property var palette: ({background:'#121e23',panel:'#263c37',metal:'#8c6e5a',engraving:'#91ada1',text:'#e6e1d8'})
    property var constellations: []
    property real rotationFraction: 0 // 0..1 over exactly 900 seconds
    onPaletteChanged: material.requestPaint()
    onConstellationsChanged: material.requestPaint()
    Rectangle { anchors.fill:parent;color:drum.palette.panel }
    Canvas {
        id:material
        x:-drum.rotationFraction * 282
        y:0;width:564;height:167
        renderTarget: Canvas.Image
        antialiasing:true
        onPaint: {
            var ctx=getContext('2d');ctx.reset();ctx.clearRect(0,0,width,height);
            var defs=drum.constellations || [];
            var N=defs.length;
            var gold=drum.palette.metal,soft=drum.palette.engraving,ink=drum.palette.text;
            for (var copy=0; copy<2; copy++) {
                var x0=copy*282;
                // Entire rotating cylinder skin: grain, seams and star charts.
                ctx.fillStyle=drum.palette.panel;
                ctx.fillRect(x0,0,282,167);
                var grain=ctx.createLinearGradient(x0,0,x0+282,0);
                grain.addColorStop(0,drum.palette.background);
                grain.addColorStop(.3,drum.palette.panel);
                grain.addColorStop(.75,drum.palette.panel);
                grain.addColorStop(1,drum.palette.background);
                ctx.globalAlpha=.34;ctx.fillStyle=grain;ctx.fillRect(x0,0,282,167);ctx.globalAlpha=1;
                ctx.lineWidth=.7;ctx.strokeStyle=gold;ctx.globalAlpha=.35;
                ctx.beginPath();ctx.moveTo(x0,7);ctx.lineTo(x0+282,7);
                ctx.moveTo(x0,160);ctx.lineTo(x0+282,160);ctx.stroke();ctx.globalAlpha=1;
                if (!N) continue;
                var slot=282/N;
                for (var i=0;i<N;i++) {
                    var d=defs[i],cx=x0+slot*(i+.5),left=x0+i*slot;
                    ctx.strokeStyle=soft;ctx.lineWidth=.7;ctx.globalAlpha=.23;
                    ctx.setLineDash([2,5]);ctx.beginPath();ctx.moveTo(left,10);ctx.lineTo(left,158);ctx.stroke();ctx.setLineDash([]);
                    ctx.globalAlpha=.4;ctx.beginPath();ctx.moveTo(cx-slot*.30,153);ctx.lineTo(cx+slot*.30,153);ctx.stroke();ctx.globalAlpha=1;
                    // Same normalized [0,1] points/edges the fullscreen sky uses.
                    var points=Object.create(null), stars=d.stars||[];
                    var fit=Policy.fitFigure(left+slot*.07,18,slot*.86,99);
                    for (var s=0;s<stars.length;s++){
                        var star=stars[s];
                        points[star.id]=Policy.figurePoint(fit,star);
                    }
                    ctx.strokeStyle=soft;ctx.lineWidth=1.05;ctx.globalAlpha=.87;
                    ctx.beginPath();var edges=d.edges||[];
                    for (var e=0;e<edges.length;e++){
                        var a=points[edges[e][0]],b=points[edges[e][1]];
                        if (!a||!b)continue;
                        ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);
                    }
                    ctx.stroke();ctx.globalAlpha=1;
                    for (var t=0;t<stars.length;t++){
                        var st=stars[t],p=points[st.id];if(!p)continue;
                        ctx.beginPath();ctx.arc(p.x,p.y,st.brightness>.85?1.9:1.2,0,2*Math.PI);
                        ctx.fillStyle=ink;ctx.globalAlpha=.7+st.brightness*.26;ctx.fill();
                        if(st.brightness>.85){ctx.strokeStyle=gold;ctx.lineWidth=.5;ctx.globalAlpha=.6;
                          ctx.beginPath();ctx.moveTo(p.x-3,p.y);ctx.lineTo(p.x+3,p.y);
                          ctx.moveTo(p.x,p.y-3);ctx.lineTo(p.x,p.y+3);ctx.stroke();}
                        ctx.globalAlpha=1;
                    }
                    ctx.fillStyle=gold;ctx.font='9px Georgia';ctx.textAlign='center';
                    ctx.fillText(['I','II','III','IV','V','VI','VII','VIII'][i]||String(i+1),cx,131);
                    ctx.fillStyle=soft;ctx.font='6.8px monospace';ctx.globalAlpha=.85;
                    ctx.fillText(String(d.name||d.id).substring(0,16),cx,143,slot*.92);ctx.globalAlpha=1;
                }
            }
        }
    }
    Rectangle {
        anchors.fill:parent
        gradient:Gradient {
            orientation:Gradient.Horizontal
            GradientStop {position:0;color:'#8a000000'}
            GradientStop {position:.18;color:'#12000000'}
            GradientStop {position:.50;color:'#00000000'}
            GradientStop {position:.83;color:'#12000000'}
            GradientStop {position:1;color:'#8a000000'}
        }
    }
}
