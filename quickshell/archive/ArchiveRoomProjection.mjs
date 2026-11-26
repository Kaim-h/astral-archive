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
 const add=(role,side,points)=>out.push({shelfId:id,role,side,points});
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
// Bounded first renderer: back-face culling and painter ordering.
// Selection consumes the same painted order, not an unrelated hit rectangle.
// Interpenetrating projected faces can defeat average-depth sorting; no
// claim of exact depth buffering or full occlusion acceptance at this stage.
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
  faces.push({index:i,shelfId:face.shelfId,role:face.role,side:face.side,points,depth});
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
 for(let i=scene.faces.length-1;i>=0;i--)if(polygonContains(scene.faces[i].points,x,y))return scene.faces[i];
 return null;
}
