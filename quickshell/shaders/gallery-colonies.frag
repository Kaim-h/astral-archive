// Celestial Gallery: full-viewport, one-render-target-pixel colonies.
// Batch 11: configurable sky catalogue + colonies seeded at the artwork's
// actual selected constellation coordinates (same library as the drum).
#version 440
layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;
layout(std140,binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float screenWidth;
    float screenHeight;
    float seed;
    float skyMode;
    float seedCount;
    vec4 accent;
    vec4 backdrop;
    vec4 secondary;
    vec4 seedsA;
    vec4 seedsB;
    vec4 seedsC;
    vec4 seedsD;
};
layout(binding=1) uniform sampler2D constellationTexture;
float hash21(vec2 p){return fract(sin(dot(p,vec2(12.9898,78.233)) + seed*.03)*43758.5453);}
vec2 seedPoint(int i){
    if(i==0)return seedsA.xy;
    if(i==1)return seedsA.zw;
    if(i==2)return seedsB.xy;
    if(i==3)return seedsB.zw;
    if(i==4)return seedsC.xy;
    if(i==5)return seedsC.zw;
    if(i==6)return seedsD.xy;
    return seedsD.zw;
}
vec3 colorAt(vec2 uv,vec2 px,vec2 dims){
    float h=hash21(floor(px/78.0));
    float cloud=.5+.5*sin(uv.x*8.0+sin(uv.y*5.2)*1.4)*cos(uv.y*6.0+uv.x*2.7);
    vec3 base=backdrop.rgb;
    vec3 mist=mix(base,secondary.rgb,clamp(cloud*.17+h*.08,0.0,.28));
    if(skyMode>1.5 && skyMode<2.5){ // Parchment chart
        vec2 grid=abs(fract(uv*vec2(12.0,8.0))-.5);
        float etched=1.0-smoothstep(.003,.007,min(grid.x,grid.y));
        mist=mix(mist,accent.rgb,etched*.13);
        float rings=abs(length((uv-vec2(.5)) * vec2(dims.x/max(dims.y,1.0),1.0))-.35);
        mist=mix(mist,accent.rgb,(1.0-smoothstep(.0015,.004,rings))*.22);
    } else if(skyMode>2.5 && skyMode<3.5){ // Aurora mist, non-animated at rest
        float curtain=sin(uv.x*11.0+sin(uv.y*7.0)*1.7);
        float band=pow(max(0.0,curtain),3.0) * (1.0-uv.y*.45);
        mist=mix(mist,accent.rgb,band*.17);
    } else if(skyMode>3.5){ // Celestial orrery
        vec2 p=(uv-vec2(.52,.48))*vec2(dims.x/max(dims.y,1.0),1.0);
        float dist=length(p);
        float ring=min(abs(dist-.22),min(abs(dist-.37),abs(dist-.57)));
        float lines=min(abs(p.x),abs(p.y));
        mist=mix(mist,accent.rgb,(1.0-smoothstep(.0015,.0035,ring))*.25);
        mist=mix(mist,accent.rgb,(1.0-smoothstep(.0007,.0025,lines))*.07);
    }
    float stars=step(.9964,hash21(px));
    float warm=hash21(px+vec2(132.0,11.0));
    mist+=stars*mix(accent.rgb,vec3(1.0,.92,.74),warm)*(.31+.42*hash21(px+9.7));
    return mist;
}
float arrival(vec2 pixel,vec2 dims){
    float nearest=2.0;
    for(int i=0;i<8;i++){
        float f=float(i);
        vec2 spot=vec2(hash21(vec2(f+1.0,27.0)),hash21(vec2(f+11.0,71.0)));
        if(float(i)<seedCount) spot=seedPoint(i);
        vec2 c=spot*dims;
        float dist=length((pixel-c)/max(dims.x,dims.y));
        float at=.035+hash21(vec2(f,83.0))*.22+dist*(.67+hash21(vec2(48.0,f))*.30);
        nearest=min(nearest,at);
    }
    // Each render-target pixel independently joins a colony.
    return clamp(nearest+(hash21(pixel)-.5)*.075,.015,.97);
}
void main(){
    vec2 uv=qt_TexCoord0;
    // Fullscreen axis-aligned quad: adjacent fragments differ by one
    // render-target pixel, regardless of the logical QML item dimensions.
    // Round to the integer raster extent to avoid derivative precision drift.
    vec2 uvStep=vec2(length(dFdx(uv)),length(dFdy(uv)));
    vec2 dims=max(vec2(screenWidth,screenHeight),vec2(1.0));
    if(uvStep.x>0.0000001 && uvStep.y>0.0000001)
        dims=max(floor(1.0/uvStep+0.5),vec2(1.0));
    vec2 pixel=floor(uv*dims);
    float at=arrival(pixel,dims);
    float p=clamp(progress,0.0,1.0);
    float a=step(at,p);
    if(p>=.998)a=1.0;
    float front=(1.0-smoothstep(0.0,.035,abs(p-at)))*sin(3.14159265*p)*.15;
    vec3 color=mix(colorAt(uv,pixel,dims),accent.rgb,front);
    // Same catalogue geometry as the single rotating drum texture. Sampling
    // it INSIDE this pixel-colony shader prevents disconnected early lines.
    vec4 chart=texture(constellationTexture,uv);
    // ShaderEffectSource samples are premultiplied. Composite chart RGB
    // once, then apply both colony coverage and Qt item opacity to RGBA.
    color=color*(1.0-chart.a*.85)+chart.rgb*.85;
    fragColor=vec4(color*a,a)*qt_Opacity;
}
