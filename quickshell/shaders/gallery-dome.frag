// Celestial Gallery dome — Patch 5. Orthographic, depth-aware port of the
// approved 770x480 HTML/WebGL telescope geometry (local origin 200,210 here).
// Unlike the Batch 10 Canvas paint order, every surface competes by projected Z.
// This is original Astral Archive code; GLSL for Qt 6 ShaderEffect/qsb.
#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float yaw;
    float pitch;
    float renderWidth;
    float renderHeight;
    vec4 domeBackground;
    vec4 domePanel;
    vec4 domeMetal;
    vec4 domeEngraving;
    vec4 domeInk;
};

const float PI=3.14159265358979;
const float DEG=PI/180.0;
const float R=164.0;
const float HALF_CUT=20.0;
const float HLOW=34.4;      // approved 350 - 315.6
const float HHIGH=155.8;    // approved 350 - 194.2
const vec3 PIVOT=vec3(0.0,20.0,0.0);
const vec3 L=vec3(-0.20722,0.53878,0.82919); // normalize(-.25,.65,1)

struct Hit { float z; vec3 color; vec3 normal; };
float aaLine(float distancePixels,float halfWidth) {
    return 1.0-smoothstep(max(0.0,halfWidth-0.75),halfWidth+0.75,distancePixels);
}
float lit(vec3 n){return 0.87+0.13*max(dot(normalize(n),L),0.0);}
void offer(inout Hit h,float z,vec3 c,vec3 n){
    if(z>h.z){h.z=z;h.color=c;h.normal=n;}
}
float sphereX(float height,float theta){return sqrt(max(0.0,R*R-height*height))*cos(theta);}
vec3 axisDirection(float a,float p){return vec3(cos(p)*cos(a),sin(p),cos(p)*sin(a));}

// Two analytic ray intersections with a finite tapered, axis-aligned-in-3D
// cylinder. The ray is (screenX,screenY,z); keep the closest visible fragment
// (greatest z), exactly as WebGL's depth test did for the triangle mesh.
void hitTube(inout Hit hit,vec2 pixel,vec3 dir,float t0,float t1,
             float r0,float r1,vec3 material,float rearExpo,bool rear,
             vec3 rearDark,vec3 rearMetal) {
    // Cheap conservative orthographic projection bounds: the 470x220 shader
    // covers much more than the telescope; avoid quadratic work for empty px.
    vec2 a2=PIVOT.xy+dir.xy*t0, b2=PIVOT.xy+dir.xy*t1;
    float pad=max(r0,r1)+1.5;
    if(pixel.x<min(a2.x,b2.x)-pad || pixel.x>max(a2.x,b2.x)+pad ||
       pixel.y<min(a2.y,b2.y)-pad || pixel.y>max(a2.y,b2.y)+pad)return;
    float k=pixel.x*dir.x+(pixel.y-PIVOT.y)*dir.y;
    float s=(r1-r0)/(t1-t0);
    float u=r0+s*(k-t0);
    float v=s*dir.z;
    float A=1.0-dir.z*dir.z-v*v;
    float B=-2.0*(k*dir.z+u*v);
    float C=dot(pixel-vec2(0.0,PIVOT.y),pixel-vec2(0.0,PIVOT.y))-k*k-u*u;
    float disc=B*B-4.0*A*C;
    if(disc<0.0||abs(A)<0.000001)return;
    float root=sqrt(max(disc,0.0));
    for(int i=0;i<2;i++) {
        float z=(-B+(i==0?root:-root))/(2.0*A);
        float t=k+dir.z*z;
        if(t<t0-0.0002||t>t1+0.0002||z<=hit.z)continue;
        vec3 rel=vec3(pixel,z)-PIVOT-dir*t;
        vec3 n=normalize(rel-s*dir*length(rel));
        float fraction=clamp((t-t0)/(t1-t0),0.0,1.0);
        vec3 paint=rear?mix(rearDark,rearMetal,pow(fraction,rearExpo)):material;
        offer(hit,z,paint,n);
    }
}
void hitDisk(inout Hit hit,vec2 pixel,vec3 dir,float t,float radius,
             vec3 paint,vec3 centerPaint) {
    if(dir.z<=0.001)return; // no front face visible at negative yaw
    float k=pixel.x*dir.x+(pixel.y-PIVOT.y)*dir.y;
    float z=(t-k)/dir.z;
    vec3 radial=vec3(pixel,z)-PIVOT-dir*t;
    float dist=length(radial);
    if(dist<=radius && z>hit.z)
        offer(hit,z,mix(centerPaint,paint,clamp(dist/radius,0.0,1.0)),dir);
}

// ALL seam longitudes are mounted to a single rotating dome shell.
// Match the approved dome v20: seven meridians on EACH side of the slit,
// with the nearest 11 degrees outside its edge, then a 29-degree pitch.
// There are no separately animated near-slit meridians and no static anchors.
// Projected to the actual hemisphere so depth is shared with the telescope.
vec3 surfaceDetails(vec3 base,vec2 pos,float shellZ,float az,float lo,float hi,
                    vec3 seam,vec3 cross,vec3 border,vec3 light) {
    float h=pos.y,rr=sqrt(max(0.0,R*R-h*h));
    vec3 outColor=base;
    // Body-local offset is constant. Yaw rotates the entire engraving
    // lattice, including the nearest marks, in exactly the same way.
    for(int side=0;side<2;side++) {
        float direction=side==0?1.0:-1.0;
        for(int k=0;k<7;k++) {
            float bodyAngle=(HALF_CUT+11.0+float(k)*29.0)*DEG;
            float theta=az+direction*bodyAngle;
            if(theta<0.035||theta>PI-0.035||h<6.0||h>154.0)continue;
            if(h>=HLOW&&h<=HHIGH&&theta>=lo&&theta<=hi)continue;
            // Screen-normal distance to the longitude arc on the sphere.
            float dx=pos.x-rr*cos(theta);
            float slope=(h/max(rr,0.001))*cos(theta);
            float d=abs(dx)/sqrt(1.0+slope*slope);
            outColor=mix(outColor,seam,aaLine(d,0.395));
        }
    }
    // Latitude rings turn WITH the shell. Since the axis of rotation is
    // vertical, rotating a complete latitude circle leaves its projected
    // geometry unchanged: this is correct physical motion, not a fixed paint
    // layer. The longitude grid crosses these rings and clearly rotates.
    for(int i=0;i<3;i++) {
        float latitude=i==0?44.0:(i==1?95.0:144.0);
        if(h>=HLOW&&h<=HHIGH&&atan(shellZ,pos.x)>=lo&&atan(shellZ,pos.x)<=hi)
            continue;
        outColor=mix(outColor,cross,aaLine(abs(h-latitude),0.35));
    }
    // Slit's two meridian edges, including yaw 0°–20° crossover; restrict to
    // actual visible front-side endpoints, not a bogus closed rectangle.
    if(h>=HLOW-1.1&&h<=HHIGH+1.1){
        for(int i=0;i<2;i++){
            float angle=i==0?lo:hi;
            if(angle>=0.0&&angle<=PI){
                float dx=pos.x-rr*cos(angle);
                float slope=(h/max(rr,0.001))*cos(angle);
                float d=abs(dx)/sqrt(1.0+slope*slope);
                outColor=mix(outColor,light,aaLine(d,1.0));
            }
        }
    }
    if(abs(h-HLOW)<1.1||abs(h-HHIGH)<1.1){
        // These lines exist only over the slit wedge, not the whole dome.
        if(atan(shellZ,pos.x)>=max(0.0,lo)-0.015&&atan(shellZ,pos.x)<=min(PI,hi)+0.015)
            outColor=mix(outColor,light,max(aaLine(abs(h-HLOW),1.0),aaLine(abs(h-HHIGH),1.0)));
    }
    // Silhouette meridian follows left/right dome limb; the right edge is
    // intentionally interrupted when yaw<20° and the slit cuts the horizon.
    float silhouette=R*R-h*h;
    if(silhouette>=0.0){
        float rim=abs(abs(pos.x)-sqrt(max(0.0,silhouette)));
        bool rightRim=pos.x>=0.0;
        bool rightCut=(lo<0.0&&hi>0.0&&h>HLOW&&h<HHIGH);
        if(!rightRim||!rightCut)outColor=mix(outColor,border,aaLine(rim,0.875));
    }
    return outColor;
}
void main(){
    vec2 pixel=vec2(qt_TexCoord0.x*renderWidth-200.0,
                    210.0-qt_TexCoord0.y*renderHeight);
    float a=yaw*DEG,p=pitch*DEG;
    float lo=(yaw-HALF_CUT)*DEG,hi=(yaw+HALF_CUT)*DEG;
    vec3 domeCol=mix(domePanel.rgb,domeEngraving.rgb,0.24);
    vec3 rearMetal=mix(domeMetal.rgb,domeBackground.rgb,0.45);
    vec3 middle=mix(domeMetal.rgb,domePanel.rgb,0.23);
    vec3 front=mix(domeMetal.rgb,domeInk.rgb,0.26);
    vec3 collar=mix(domeMetal.rgb,domeInk.rgb,0.36);
    vec3 light=mix(domeInk.rgb,domeMetal.rgb,0.15);
    vec3 glass=mix(domeEngraving.rgb,domeInk.rgb,0.15);
    vec3 centerGlass=mix(domeEngraving.rgb,domeInk.rgb,0.60);
    vec3 rearDark=mix(domePanel.rgb,domeBackground.rgb,0.70);
    vec3 seam=mix(domeCol,light,0.40),cross=mix(domeCol,light,0.24);
    Hit hit;hit.z=-100000.0;hit.color=vec3(0.0);hit.normal=vec3(0.,0.,1.);

    // Dome: exactly the positive-Z hemisphere used by the approved WebGL mesh.
    float r2=dot(pixel,pixel);
    float hemisphereZ=-1.0;
    if(pixel.y>=0.0&&r2<=R*R){
        hemisphereZ=sqrt(max(0.0,R*R-r2));
        float theta=atan(hemisphereZ,pixel.x);
        bool missing=(pixel.y>=HLOW&&pixel.y<=HHIGH&&theta>=lo&&theta<=hi);
        if(!missing){
            vec3 surfaceColor=surfaceDetails(domeCol,pixel,hemisphereZ,a,lo,hi,seam,cross,collar,light);
            offer(hit,hemisphereZ,surfaceColor,vec3(pixel,hemisphereZ)/R);
        }
    }

    vec3 dir=axisDirection(a,p);
    // Same three 3D barrel segments and three raised metal collars as HTML.
    float projection=length(vec2(cos(p)*cos(a),sin(p)));
    float fadeExponent=1.2+3.0*clamp((projection-.56)/.44,0.0,1.0);
    hitTube(hit,pixel,dir,0.0,169.0,13.0,15.3,rearMetal,fadeExponent,true,rearDark,rearMetal);
    hitTube(hit,pixel,dir,162.0,203.0,16.5,18.7,middle,fadeExponent,false,rearDark,rearMetal);
    hitTube(hit,pixel,dir,196.0,246.0,20.0,23.0,front,fadeExponent,false,rearDark,rearMetal);
    hitTube(hit,pixel,dir,162.0,167.0,18.3,18.3,collar,fadeExponent,false,rearDark,rearMetal);
    hitTube(hit,pixel,dir,197.0,202.0,21.3,21.3,collar,fadeExponent,false,rearDark,rearMetal);
    hitTube(hit,pixel,dir,243.5,247.0,24.7,24.7,collar,fadeExponent,false,rearDark,rearMetal);
    // Slim raised cylinder strips are an analytic substitute for the HTML
    // collar's 0.65px tubular torus rim; no filled, face-on oval shortcuts.
    hitTube(hit,pixel,dir,162.0,162.85,18.85,18.85,light,fadeExponent,false,rearDark,rearMetal);
    hitTube(hit,pixel,dir,166.3,167.0,18.85,18.85,light,fadeExponent,false,rearDark,rearMetal);
    hitTube(hit,pixel,dir,197.0,197.85,21.85,21.85,light,fadeExponent,false,rearDark,rearMetal);
    hitTube(hit,pixel,dir,201.3,202.0,21.85,21.85,light,fadeExponent,false,rearDark,rearMetal);
    hitTube(hit,pixel,dir,243.5,244.35,25.25,25.25,light,fadeExponent,false,rearDark,rearMetal);
    hitTube(hit,pixel,dir,246.3,247.0,25.25,25.25,light,fadeExponent,false,rearDark,rearMetal);
    // A real circular objective in its own tilted plane; the lens is shown
    // only when the optical front faces the viewer (dir.z>0).
    hitDisk(hit,pixel,dir,248.1,24.5,collar,collar);
    hitDisk(hit,pixel,dir,248.4,20.2,glass,centerGlass);
    if(hit.z < -90000.0){fragColor=vec4(0.0);return;}
    fragColor=vec4(hit.color*lit(hit.normal),1.0)*qt_Opacity;
}
