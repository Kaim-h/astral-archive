// Synthetic gradient terrain adapted from S19r4, itself adapted from Morn,
// Perlin noise with more contours.svg (2023-12-02), CC0 1.0:
// https://commons.wikimedia.org/wiki/File:Perlin_noise_with_more_contours.svg
// Not surveyed geography. Stable world coordinates; bounded tiles and LOD.
function gradientNoise(x,y,scale,seed){
 const gx=x/scale,gy=y/scale,i=Math.floor(gx),j=Math.floor(gy),u=gx-i,v=gy-j;
 const fade=t=>t*t*t*(t*(6*t-15)+10);
 const dot=(a,b,dx,dy)=>{let h=Math.imul(a,374761393)^Math.imul(b,668265263)^seed;h=Math.imul(h^(h>>>13),1274126177);const theta=((h^(h>>>16))>>>0)/4294967296*2*Math.PI;return Math.cos(theta)*dx+Math.sin(theta)*dy;};
 const mix=(a,b,t)=>a+(b-a)*t;
 return mix(mix(dot(i,j,u,v),dot(i+1,j,u-1,v),fade(u)),mix(dot(i,j+1,u,v-1),dot(i+1,j+1,u-1,v-1),fade(u)),fade(v));
}
export function terrainHeight(x,y){
 return 1.35*gradientNoise(x+620,y-850,1800,1729)+.48*gradientNoise(x-410,y+210,3600,931)+.18*gradientNoise(x,y,700,73);
}
export const contourBudget=50000;
export function contourSpec(frame,w,h,density){
 if(!frame||![frame.scale,frame.x,frame.y,w,h,density].every(Number.isFinite)||frame.scale<=0||w<=0||h<=0||density<=0)return null;
 const ww=w/frame.scale,hh=h/frame.scale,left=-frame.x/frame.scale,top=-frame.y/frame.scale,extent=Math.max(ww,hh);
 if(extent>1e9||Math.abs(left)>1e9||Math.abs(top)>1e9)return null;
 const step=12.5*2**Math.max(0,Math.ceil(Math.log2(extent/104/12.5))),tile=step*8,
 x0=Math.floor(left/tile)*tile-step*2,y0=Math.floor(top/tile)*tile-step*2,
 nx=Math.ceil(ww/step)+12,ny=Math.ceil(hh/step)+12;
 const stride=Math.max(density>=80?1:density>=35?2:4,extent>12000?4:extent>4000?2:1);
 return {key:[x0,y0,nx,ny,step,stride].join(','),x0,y0,nx,ny,step,stride,alpha:extent>12000?.55:extent>6000?.75:1};
}
export function contourSegments(spec){
 if(!spec||!Number.isInteger(spec.nx)||!Number.isInteger(spec.ny)||spec.nx<1||spec.ny<1||spec.nx>116||spec.ny>116||![spec.x0,spec.y0,spec.step].every(Number.isFinite)||spec.step<=0||![1,2,4,8,16,32,64].includes(spec.stride))return {levels:[],segments:0,stride:0};
 const {x0,y0,nx,ny,step}=spec,values=Array.from({length:ny+1},(_,j)=>Array.from({length:nx+1},(_,i)=>terrainHeight(x0+i*step,y0+j*step)));
 // Work per cell only for levels it actually crosses. Saddle connectivity
 // uses the original smooth field at the cell center, not random diagonals.
 function build(stride){
  const levels={},corners=[[0,0],[1,0],[1,1],[0,1]];let segments=0;
  for(let j=0;j<ny;j++)for(let i=0;i<nx;i++){
   const v=[values[j][i],values[j][i+1],values[j+1][i+1],values[j+1][i]],lo=Math.min(...v),hi=Math.max(...v);
   for(let n=Math.max(-40,Math.ceil(lo/.055/stride)*stride);n<=Math.min(40,Math.floor(hi/.055/stride)*stride);n+=stride){
    const level=n*.055,hits=[];
    for(let k=0;k<4;k++){
     const a=v[k],b=v[(k+1)%4];if((a<level)===(b<level))continue;
     const t=(level-a)/(b-a),q=corners[k],r=corners[(k+1)%4];
     hits.push([Math.round((x0+(i+q[0]+(r[0]-q[0])*t)*step)*100)/100,Math.round((y0+(j+q[1]+(r[1]-q[1])*t)*step)*100)/100]);
    }
    if(hits.length===4&&(terrainHeight(x0+(i+.5)*step,y0+(j+.5)*step)<level)===(v[0]<level))hits.push(hits.shift());
    for(let k=0;k+1<hits.length;k+=2){if(++segments>contourBudget)return null;(levels[n]||(levels[n]=[])).push(hits[k].concat(hits[k+1]));}
   }
  }
  return {levels:Object.keys(levels).map(n=>({n:Number(n),segments:levels[n]})).sort((a,b)=>a.n-b.n),segments,stride};
 }
 for(let stride=spec.stride;stride<=64;stride*=2){const result=build(stride);if(result)return result;}
 return {levels:[],segments:0,stride:64};
}
