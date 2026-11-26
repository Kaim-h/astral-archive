// B8-N3d: centered perspective and room-space surfaces. Pure model adapter.
// S16r3 camera equations; real dimensions, not the prototype's plate sizes.
import * as Architecture from "./ArchiveArchitecture.mjs";
import * as Spatial from "./ArchiveSpatial.mjs";
const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
const need=(v,m)=>{if(!v)throw Error(m);};
export function wallHeight(room,side){
 return side==='north'||side==='east'?Math.min(125,Math.max(room.w,room.h)*.2):Math.min(12,Math.min(room.w,room.h)*.1);
}
export function rawProject(p,c){
 const x=p[0]-c.w/2,y=p[1]-c.h/2,z=p[2],q=c.distance-c.sin*y-c.cos*z;
 if(!Number.isFinite(q)||q<=0)return null;
 return [x*c.distance/q,(c.cos*y-c.sin*z)*c.distance/q,1/q];
}
export function frame(room,maxHeight,width,height,tilt=22){
 need([room.w,room.h,maxHeight,width,height,tilt].every(Number.isFinite)&&room.w>0&&room.h>0&&maxHeight>=0&&width>0&&height>0&&tilt>=20&&tilt<=30,'Invalid perspective viewport');
 const angle=tilt*Math.PI/180,cos=Math.cos(angle),sin=Math.sin(angle);
 const top=Math.max(maxHeight,wallHeight(room,'north'));
 // Real tall cases in shallow rooms must never cross the camera near plane.
 const distance=Math.max(Math.max(room.w,room.h)*2.6,(sin*room.h/2+cos*top)*1.35+1);
 const c={w:room.w,h:room.h,cos,sin,distance},pts=[];
 for(const x of [0,room.w])for(const y of [0,room.h])for(const z of [0,top])pts.push(rawProject([x,y,z],c));
 const xs=pts.map(p=>p[0]),ys=pts.map(p=>p[1]),l=Math.min(...xs),r=Math.max(...xs),u=Math.min(...ys),b=Math.max(...ys);
 const scale=Math.min(Math.max(1,width-64)/(r-l),Math.max(1,height-100)/(b-u));
 return Object.assign(c,{scale,ox:width/2-(l+r)*scale/2,oy:height/2-(u+b)*scale/2});
}
export function project(p,f){
 const q=rawProject(p,f);return q?[q[0]*f.scale+f.ox,q[1]*f.scale+f.oy,q[2]]:null;
}
export function floorInverse(x,y,f){
 if(![x,y].every(Number.isFinite)||!f||!(f.scale>0))return null;
 const u=(x-f.ox)/f.scale,v=(y-f.oy)/f.scale,den=f.cos*f.distance+v*f.sin;
 if(den<=1e-9)return null;
 const Y=v*f.distance/den,q=f.distance-f.sin*Y;
 if(q<=0)return null;
 return {x:u*q/f.distance+f.w/2,y:Y+f.h/2};
}
function rectPoints(x,y,w,h){return [[x,y],[x+w,y],[x+w,y+h],[x,y+h]];}
function wallPoint(r,side,t,z){
 return side==='north'?[t,0,z]:side==='south'?[t,r.h,z]:side==='east'?[r.w,t,z]:[0,t,z];
}
export function wallSegments(room,openings){
 const out=[];
 for(const side of ['north','east','south','west']){
  const length=side==='north'||side==='south'?room.w:room.h;
  let at=0;
  for(const o of openings.filter(v=>v.side===side).sort((a,b)=>a.start-b.start)){
   if(o.start>at)out.push({side,start:at,end:o.start});
   at=Math.max(at,o.end);
  }
  if(at<length)out.push({side,start:at,end:length});
 }
 return out;
}
// Every front polygon is exactly the adopted profile. The return faces
// are a provisional shell: full-depth structural frame, thin front accents,
// and a recessed aperture backing. No invented interior file thumbnails.
export function shelfSurfaces(g,p,id){
 const out=[],point=(q,d)=>{const xy=Architecture.planPoint(g,p,q[0],d);return [xy[0],xy[1],g.floorY-q[1]];};
 const add=(role,side,points)=>{
  const n=normal(points),length=Math.hypot(...n);
  // Flat role classification derives from the actual solid face, not a
  // lighting gradient or a second geometry model.
  const surface=side!=='return'?side:length&&n[2]/length>.65?'top':length&&n[2]/length<-.65?'bottom':'side';
  out.push({shelfId:id,role,side,surface,points});
 };
 function prism(role,poly,back,front){
  const A=poly.map(q=>point(q,front)),B=poly.map(q=>point(q,back));
  add(role,'front',A);add(role,'back',B.slice().reverse());
  for(let i=0;i<A.length;i++){const j=(i+1)%A.length;add(role,'return',[A[j],A[i],B[i],B[j]]);}
 }
 const thin=Math.min(g.depth/4,g.inscription.h/2);
 for(const part of g.parts){
  const accent=['crest','capital','base'].includes(part.role);
  // Capitals/base occupy existing lintel/plinth volume, so keep their
  // front face as a color accent, not a second overlapping solid.
  if(part.role==='capital'||part.role==='base')add(part.role,'front',part.points.map(q=>point(q,g.depth)));
  else prism(part.role,part.points,accent?g.depth-thin:0,g.depth);
 }
 const aperture=g.aperture;
 // Thin backing panel, contained in the aperture and the independent depth.
 prism('backing',rectPoints(aperture.x,aperture.y,aperture.w,aperture.h),0,Math.min(thin,g.depth/8));
 return out;
}
function normal(points){
 // Newell normal, including non-triangular sampled crest.
 let x=0,y=0,z=0;
 for(let i=0;i<points.length;i++){
  const a=points[i],b=points[(i+1)%points.length];
  x+=(a[1]-b[1])*(a[2]+b[2]);y+=(a[2]-b[2])*(a[0]+b[0]);z+=(a[0]-b[0])*(a[1]+b[1]);
 }
 return [x,y,z];
}
function facesCamera(points,f){
 const n=normal(points),a=points[0],cam=[f.w/2,f.h/2+f.distance*f.sin,f.distance*f.cos];
 return n[0]*(cam[0]-a[0])+n[1]*(cam[1]-a[1])+n[2]*(cam[2]-a[2])>1e-8;
}
export function roomMesh(s,roomId,openings){
 if(!Spatial.physicalProfiles(s)||!own(s.spatial.rooms,roomId))return null;
 const room=s.spatial.rooms[roomId],faces=[],segments=wallSegments(room,openings);
 let maxHeight=0;
 for(const id of Object.keys(s.spatial.shelves)){
  const p=s.spatial.shelves[id];if(p.roomId!==roomId)continue;
  const g=Spatial.shelfGeometry(s,id);maxHeight=Math.max(maxHeight,g.h);
  for(const face of shelfSurfaces(g,p,id))faces.push(face);
 }
 for(const v of segments){
  const h=wallHeight(room,v.side);
  faces.push({shelfId:'',role:'wall',side:v.side,points:[wallPoint(room,v.side,v.start,0),wallPoint(room,v.side,v.end,0),wallPoint(room,v.side,v.end,h),wallPoint(room,v.side,v.start,h)]});
 }
 return {room,maxHeight,faces,segments};
}
// Back-face culling and projected planar faces. Average depth remains a
// stable iteration order for historical callers, NOT the visibility rule.
export function depthPlane(points){
 const a=points[0];
 for(let i=1;i<points.length-1;i++){
  const b=points[i+1],c=points[i],ux=b[0]-a[0],uy=b[1]-a[1],vx=c[0]-a[0],vy=c[1]-a[1],den=ux*vy-uy*vx;
  if(Math.abs(den)<=1e-8)continue;
  const m=((b[2]-a[2])*vy-uy*(c[2]-a[2]))/den,n=(ux*(c[2]-a[2])-(b[2]-a[2])*vx)/den;
  return {m,n,k:a[2]-m*a[0]-n*a[1]};
 }
 return null;
}
const depthEpsilon=1e-10;
// Accents are coplanar with the supporting front. Later stable face index
// wins ties, except that an accent wins over its own supporting face.
function priority(f){return f.role==='capital'||f.role==='base'?1:0;}
function nearer(z,f,oldZ,old){
 if(!old||z>oldZ+depthEpsilon)return true;
 if(z<oldZ-depthEpsilon)return false;
 return priority(f)>priority(old)||priority(f)===priority(old)&&f.index>old.index;
}
export function projectedScene(mesh,width,height,tilt=22){
 if(!mesh||width<=0||height<=0)return null;
 const f=frame(mesh.room,mesh.maxHeight,width,height,tilt);
 const floor=rectPoints(0,0,mesh.room.w,mesh.room.h).map(q=>project([q[0],q[1],0],f));
 const faces=[];
 for(let i=0;i<mesh.faces.length;i++){
  const face=mesh.faces[i];
  if(face.role!=='wall'&&!facesCamera(face.points,f))continue;
  const points=face.points.map(q=>project(q,f));
  if(points.some(q=>!q))continue;
  const depth=points.reduce((sum,q)=>sum+q[2],0)/points.length;
  const plane=depthPlane(points);if(plane)faces.push({index:i,shelfId:face.shelfId,role:face.role,side:face.side,surface:face.surface,points,depth,plane});
 }
 faces.sort((a,b)=>a.depth-b.depth||a.index-b.index);
 return {frame:f,floor,faces};
}
export function polygonContains(poly,x,y){
 let inside=false;
 for(let i=0,j=poly.length-1;i<poly.length;j=i++){
  const a=poly[i],b=poly[j];
  if((a[1]>y)!==(b[1]>y)&&x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])inside=!inside;
 }
 return inside;
}
export function faceAt(scene,x,y){
 if(!scene||![x,y].every(Number.isFinite))return null;
 let winner=null,z=-Infinity;
 for(const f of scene.faces){
  if(!polygonContains(f.points,x,y))continue;
  const p=f.plane||depthPlane(f.points);if(!p)continue;
  const q=p.m*x+p.n*y+p.k;
  if(nearer(q,f,z,winner)){winner=f;z=q;}
 }
 return winner;
}
// Bounded logical-pixel depth/identity buffer. Scanline even-odd spans retain
// concave crest polygons without fan triangulation. Half-open pixel centers
// agree with polygonContains; one deterministic face winner drives both
// displayed color and native pointer picking. No frame loop.
export function visibility(scene,width,height,budget=1200000){
 if(!scene||![width,height,budget].every(Number.isFinite)||width<=0||height<=0||budget<1)return null;
 const scale=Math.min(1,Math.sqrt(budget/(width*height)));
 const w=Math.max(1,Math.floor(width*scale)),h=Math.max(1,Math.floor(height*scale)),sx=width/w,sy=height/h;
 if(w*h>budget)return null;
 const winners=new Int32Array(w*h);winners.fill(-1);
 const depths=new Float64Array(w*h);depths.fill(-Infinity);
 const floor=new Uint8Array(w*h),faces=scene.faces;
 function spans(points,write){
  let lo=Infinity,hi=-Infinity;
  for(const p of points){lo=Math.min(lo,p[1]);hi=Math.max(hi,p[1]);}
  const first=Math.max(0,Math.ceil(lo/sy-.5)),last=Math.min(h,Math.ceil(hi/sy-.5));
  for(let row=first;row<last;row++){
   const y=(row+.5)*sy,cross=[];
   for(let i=0,j=points.length-1;i<points.length;j=i++){
    const a=points[i],b=points[j];
    if((a[1]>y)!==(b[1]>y))cross.push(a[0]+(b[0]-a[0])*(y-a[1])/(b[1]-a[1]));
   }
   cross.sort((a,b)=>a-b);
   for(let k=0;k+1<cross.length;k+=2){
    const left=Math.max(0,Math.ceil(cross[k]/sx-.5)),right=Math.min(w,Math.ceil(cross[k+1]/sx-.5));
    if(right>left)write(row,y,left,right);
   }
  }
 }
 spans(scene.floor,(row,y,l,r)=>floor.fill(1,row*w+l,row*w+r));
 for(let i=0;i<faces.length;i++){
  const f=faces[i],p=f.plane||depthPlane(f.points);if(!p)continue;
  spans(f.points,(row,y,l,r)=>{
   const off=row*w,constant=p.n*y+p.k;
   for(let x=l;x<r;x++){
    const k=off+x,z=p.m*((x+.5)*sx)+constant,previous=winners[k];
    if(nearer(z,f,depths[k],previous<0?null:faces[previous])){depths[k]=z;winners[k]=i;}
   }
  });
 }
 // Depth buffer is scratch; only compact identity and floor mask retained.
 return {w,h,sx,sy,winners,floor,faces};
}
export function rasterFaceAt(r,x,y){
 if(!r||![x,y].every(Number.isFinite)||x<0||y<0)return null;
 const i=Math.floor(x/r.sx),j=Math.floor(y/r.sy);
 if(i>=r.w||j>=r.h)return null;
 const k=r.winners[j*r.w+i];return k<0?null:r.faces[k];
}


// Convert the exact same ownership raster into nonoverlapping integer spans.
// The Qt Canvas path paints these spans directly, without relying on
// browser-style writable ImageData.data semantics. -1 = floor, -2 = empty.
export function visibilityRuns(r,emit){
 if(!r||typeof emit!=='function')return 0;
 let count=0;
 const at=i=>r.winners[i]>=0?r.winners[i]:r.floor[i]?-1:-2;
 for(let y=0;y<r.h;y++){
  const off=y*r.w;
  let start=0,key=at(off);
  for(let x=1;x<=r.w;x++){
   const next=x<r.w?at(off+x):-3;
   if(next===key)continue;
   if(key!==-2){emit(start,y,x-start,key);count++;}
   start=x;key=next;
  }
 }
 return count;
}
