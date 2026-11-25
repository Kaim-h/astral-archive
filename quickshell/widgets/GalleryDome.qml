import QtQuick
import Quickshell.Io

// 328 x 164 hemisphere, in the same design coordinates as the approved HTML.
// Patch 5: the preferred path is a DEPTH-AWARE Qt ShaderEffect: the shader
// compares the positive-Z hemisphere, slit and physical telescope cylinders
// per pixel, instead of drawing flat 2-D shapes in a predetermined order.
// The previous Canvas remains ONLY as a safe fallback while the qsb is absent
// or rejected by Qt. See docs/celestial-gallery-patch4.md.
// Geometry is unchanged: original 20px mount lift and 40° slit.
Item {
    id: dome
    width: 470
    height: 220
    property real yaw: 20
    property real pitch: 33
    property var palette: ({background:"#121e23",panel:"#263c37",metal:"#8c6e5a",engraving:"#91ada1",text:"#e6e1d8"})
    readonly property real lensX: 200 + 248 * Math.cos(pitch * Math.PI/180) * Math.cos(yaw * Math.PI/180)
    readonly property real lensY: 210 - 20 - 248 * Math.sin(pitch * Math.PI/180)
    readonly property real lensFacing: Math.max(0, Math.cos(pitch*Math.PI/180)*Math.sin(yaw*Math.PI/180))
    signal selected()

    readonly property string compiledDomeShader: String(Qt.resolvedUrl("../shaders/gallery-dome.frag.qsb"))
    readonly property string domeShaderPath: compiledDomeShader.indexOf("file://")===0
        ? decodeURIComponent(compiledDomeShader.substring(7)) : ""
    property bool shaderPrepared: false
    readonly property bool shaderReady: !!(depthLayer.item &&
        depthLayer.item.status===ShaderEffect.Compiled)
    Process {
        id: shaderAvailability
        command: ["test","-s",dome.domeShaderPath]
        onExited: function(code,status) { dome.shaderPrepared=(code===0); }
    }
    Component.onCompleted: shaderAvailability.running=true
    onYawChanged: shape.requestPaint()
    onPitchChanged: shape.requestPaint()
    onPaletteChanged: shape.requestPaint()

    Canvas {
        id: shape
        anchors.fill: parent
        antialiasing: true
        renderTarget: Canvas.Image
        visible: !dome.shaderReady // Paint-order approximation only when shader is unavailable.
        function deg(v) { return v*Math.PI/180; }
        function mix(hex,other,t) {
            function c(s,i){return parseInt(s.substring(i,i+2),16)}
            var r=Math.round(c(hex,1)*(1-t)+c(other,1)*t);
            var g=Math.round(c(hex,3)*(1-t)+c(other,3)*t);
            var b=Math.round(c(hex,5)*(1-t)+c(other,5)*t);
            return 'rgb('+r+','+g+','+b+')';
        }
        function surfacePath(ctx) {
            ctx.beginPath();ctx.moveTo(36,210);ctx.arc(200,210,164,Math.PI,2*Math.PI,false);ctx.lineTo(36,210);ctx.closePath();
        }
        function spherePoint(h,t) {
            var rr=Math.sqrt(Math.max(0,164*164-h*h));
            return {x:200+rr*Math.cos(t),y:210-h};
        }
        function slitEdges() {
            var lo=deg(dome.yaw-20),hi=deg(dome.yaw+20);
            return {lo:Math.max(0,lo),hi:Math.min(Math.PI,hi)};
        }
        function slitPath(ctx) {
            var e=slitEdges();if(e.hi<=e.lo)return false;
            var i,steps=32, hLow=34.4,hHigh=155.8,p;
            ctx.beginPath();
            for(i=0;i<=steps;i++){
                p=spherePoint(hHigh,e.lo+(e.hi-e.lo)*i/steps);
                if(!i)ctx.moveTo(p.x,p.y);else ctx.lineTo(p.x,p.y);
            }
            for(i=steps;i>=0;i--){p=spherePoint(hLow,e.lo+(e.hi-e.lo)*i/steps);ctx.lineTo(p.x,p.y)}
            ctx.closePath();return true;
        }
        function axis(t) {
            var a=deg(dome.yaw),p=deg(dome.pitch);
            return {x:200+t*Math.cos(p)*Math.cos(a),y:190-t*Math.sin(p)};
        }
        function strokeSegment(ctx,from,to,sz,color) {
            ctx.lineWidth=sz;ctx.strokeStyle=color;ctx.beginPath();ctx.moveTo(from.x,from.y);ctx.lineTo(to.x,to.y);ctx.stroke();
        }
        function tube(ctx,t0,t1,w0,w1,c) {
            var a=axis(t0),b=axis(t1),nx=-(b.y-a.y),ny=b.x-a.x;
            var len=Math.hypot(nx,ny)||1;nx/=len;ny/=len;
            // A lightly tapered, opaque cylindrical barrel; rear stage fades
            // into the dome interior, while the two forward stages stay solid.
            var g=ctx.createLinearGradient(a.x,a.y,b.x,b.y);
            g.addColorStop(0,shape.mix(dome.palette.background,c,.12));
            g.addColorStop(.38,shape.mix(dome.palette.panel,c,.45));
            g.addColorStop(.95,c);
            ctx.fillStyle=g;ctx.strokeStyle=shape.mix(c,dome.palette.text,.38);ctx.lineWidth=.8;
            ctx.beginPath();ctx.moveTo(a.x+nx*w0,a.y+ny*w0);
            ctx.lineTo(b.x+nx*w1,b.y+ny*w1);ctx.lineTo(b.x-nx*w1,b.y-ny*w1);
            ctx.lineTo(a.x-nx*w0,a.y-ny*w0);ctx.closePath();ctx.fill();ctx.stroke();
            strokeSegment(ctx,{x:a.x+nx*w0*.64,y:a.y+ny*w0*.64},{x:b.x+nx*w1*.64,y:b.y+ny*w1*.64},.85,shape.mix(c,dome.palette.text,.26));
        }
        function ring(ctx,t,w) {
            var b=axis(t),n=deg(dome.yaw),p=deg(dome.pitch);
            // Projection of a cylinder collar. Unlike an opaque disc, only
            // the thin peripheral curved line is painted.
            var vx=Math.max(2,Math.abs(Math.sin(n))*w+Math.abs(Math.sin(p)*Math.cos(n))*w*.4);
            ctx.save();ctx.translate(b.x,b.y);ctx.rotate(-p*.58);ctx.scale(vx/w,1);
            ctx.strokeStyle=dome.palette.metal;ctx.lineWidth=2.2;
            ctx.beginPath();ctx.arc(0,0,w,Math.PI*.06,Math.PI*1.94,false);ctx.stroke();
            ctx.strokeStyle=shape.mix(dome.palette.metal,dome.palette.text,.52);ctx.lineWidth=.7;
            ctx.beginPath();ctx.arc(0,0,w+1,Math.PI*.08,Math.PI*.92,false);ctx.stroke();
            ctx.restore();
        }
        function drawLens(ctx) {
            // Lens is a face-on-ish ellipse only at positive yaw. Its centre
            // is stable and exported for the fixed twinkle overlay.
            var fx=dome.lensX,fy=dome.lensY,front=dome.lensFacing;
            if(front<.02)return;
            ctx.save();ctx.translate(fx,fy);ctx.rotate(-deg(dome.pitch)*.58);
            ctx.scale(Math.max(.15,front),1);
            ctx.fillStyle=dome.palette.metal;ctx.beginPath();ctx.arc(0,0,24.5,0,2*Math.PI);ctx.fill();
            var g=ctx.createRadialGradient(-4,-6,1,0,0,20);
            g.addColorStop(0,shape.mix(dome.palette.engraving,'#eafcf5',.52));
            g.addColorStop(.65,dome.palette.engraving);g.addColorStop(1,dome.palette.panel);
            ctx.fillStyle=g;ctx.beginPath();ctx.arc(0,0,20.2,0,2*Math.PI);ctx.fill();
            ctx.strokeStyle=dome.palette.text;ctx.lineWidth=.8;ctx.stroke();ctx.restore();
        }
        function domeEngravings(ctx) {
            var yaw=deg(dome.yaw),a0=yaw-deg(20),a1=yaw+deg(20);
            var seam=shape.mix(dome.palette.panel,dome.palette.engraving,.73);
            var cross=shape.mix(dome.palette.panel,dome.palette.engraving,.50);
            // Approved v20: the entire longitude lattice rotates rigidly.
            // No static meridians with an independently moving near-slit pair.
            // Body-local nearest seam = slit edge + 11°, spacing = 29°.
            var angles=[];
            for(var k=0;k<7;k++){
                angles.push(yaw+deg(20+11+k*29));
                angles.push(yaw-deg(20+11+k*29));
            }
            for(var i=0;i<angles.length;i++){
                var t=angles[i];if(t<=.035||t>=Math.PI-.035)continue;
                ctx.strokeStyle=seam;ctx.lineWidth=.79;ctx.beginPath();
                var pen=false;
                for(var h=6;h<=154;h+=1.8){
                    var p=spherePoint(h,t),inside=h>=34.4&&h<=155.8&&t>=a0&&t<=a1;
                    if(inside){pen=false;continue;}
                    if(!pen){ctx.moveTo(p.x,p.y);pen=true;}else ctx.lineTo(p.x,p.y);
                }
                ctx.stroke();
            }
            // Complete latitude circles are rotationally symmetric: they
            // have no separate movement because they ARE part of the shell.
            for(var k=0;k<3;k++){
                var h2=[44,95,144][k],started=false;
                ctx.lineWidth=.70;ctx.strokeStyle=cross;ctx.beginPath();
                for(var z=.045;z<Math.PI-.045;z+=deg(1.2)){
                    if(z>=a0&&z<=a1){started=false;continue;}
                    var p2=spherePoint(h2,z);
                    if(!started){ctx.moveTo(p2.x,p2.y);started=true;}else ctx.lineTo(p2.x,p2.y);
                }
                ctx.stroke();
            }
        }
        onPaint: {
            var ctx=getContext('2d');ctx.reset();ctx.clearRect(0,0,width,height);
            // Interior telescope first, so the solid hemisphere can occlude it.
            tube(ctx,0,169,12.8,15.4,shape.mix(dome.palette.panel,dome.palette.metal,.5));
            surfacePath(ctx);
            var shell=ctx.createLinearGradient(40,48,360,205);
            shell.addColorStop(0,shape.mix(dome.palette.panel,dome.palette.engraving,.32));
            shell.addColorStop(.57,shape.mix(dome.palette.panel,dome.palette.engraving,.2));
            shell.addColorStop(1,dome.palette.panel);
            ctx.fillStyle=shell;ctx.fill();
            // Preserve cutout opening and both longitudinal boundaries.
            var open=slitPath(ctx);
            if(open){
                ctx.fillStyle=dome.palette.background;ctx.fill();
                ctx.save();slitPath(ctx);ctx.clip();
                tube(ctx,0,169,12.8,15.4,shape.mix(dome.palette.panel,dome.palette.metal,.5));
                tube(ctx,162,203,16.5,18.7,shape.mix(dome.palette.metal,dome.palette.panel,.18));
                ctx.restore();
                ctx.strokeStyle=shape.mix(dome.palette.text,dome.palette.metal,.32);ctx.lineWidth=1.9;
                slitPath(ctx);ctx.stroke();
            }
            domeEngravings(ctx);
            // The outer telescope stages emerge from the dome shell.
            tube(ctx,164,203,16.5,18.7,shape.mix(dome.palette.metal,dome.palette.panel,.24));
            tube(ctx,197,247,20,23,shape.mix(dome.palette.metal,dome.palette.text,.12));
            ring(ctx,166,18.5);ring(ctx,201,21.1);ring(ctx,246,24.7);
            drawLens(ctx);
            // Base silhouette: preserve cutaway interruption on the near rim.
            ctx.strokeStyle=dome.palette.metal;ctx.lineWidth=1.9;
            ctx.beginPath();ctx.arc(200,210,164,Math.PI,2*Math.PI);ctx.stroke();
            ctx.beginPath();ctx.moveTo(36,210);ctx.lineTo(364,210);ctx.stroke();
        }
    }
    // Shader geometry lives in a single physical 3-D coordinate system. The
    // output is alpha-transparent outside the globe and telescope, so nothing
    // here introduces a square background over the tower or music player.
    Loader {
        id: depthLayer
        anchors.fill: parent
        active: dome.shaderPrepared
        sourceComponent: Component {
            ShaderEffect {
                anchors.fill: parent
                property real yaw: dome.yaw
                property real pitch: dome.pitch
                property real renderWidth: width
                property real renderHeight: height
                property color domeBackground: dome.palette.background
                property color domePanel: dome.palette.panel
                property color domeMetal: dome.palette.metal
                property color domeEngraving: dome.palette.engraving
                property color domeInk: dome.palette.text
                fragmentShader: Qt.resolvedUrl("../shaders/gallery-dome.frag.qsb")
            }
        }
    }
    MouseArea {
        // Lens and protruding barrel remain selectable outside the hemisphere.
        x: dome.lensX-36; y: dome.lensY-34
        width:72; height:68
        onClicked: dome.selected()
        cursorShape:Qt.PointingHandCursor
    }
    MouseArea {
        id: domeHit
        x: 36; y: 44; width: 328; height: 167
        // The panel's real player controls are above this input region.
        onClicked: dome.selected()
        cursorShape: Qt.PointingHandCursor
    }
}
