// N3e: bounded, reversible visual bridge from Room to the live Shelf.
// All geometry is captured from the adopted contract. No model edits.
import * as Spatial from "./ArchiveSpatial.mjs";
import * as Architecture from "./ArchiveArchitecture.mjs";
import * as Projection from "./ArchiveRoomProjection.mjs";
const clamp=x=>Math.max(0,Math.min(1,x));
const mix=(a,b,t)=>a+(b-a)*t;
export function smooth(x){const t=clamp(x);return t*t*(3-2*t);}
function sourcePoint(g,p,m,q){
 const xy=Architecture.planPoint(g,p,q[0],q[1]);
 return m.frame?Projection.project([xy[0],xy[1],q[2]],m.frame).slice(0,2):
  [m.x+xy[0]*m.scale,m.y+xy[1]*m.scale];
}
export function capture(s,id,mapping,destination){
 if(!Spatial.physicalProfiles(s)||Spatial.kind(s,id)!=='shelf'||!mapping||!destination||
    ![destination.x,destination.y,destination.scale].every(Number.isFinite)||destination.scale<=0)return null;
 const g=Spatial.shelfGeometry(s,id),p=Object.assign({},s.spatial.shelves[id]),m=mapping;
 const center=sourcePoint(g,p,m,[g.w/2,g.depth/2,0]),right=sourcePoint(g,p,m,[g.w/2+1,g.depth/2,0]);
 const scale=Math.hypot(right[0]-center[0],right[1]-center[1]);
 if(!(scale>0)||!center.every(Number.isFinite))return null;
 return {id,g,p,mapping:m,destination:Object.assign({},destination),center,scale,
   faces:Projection.shelfSurfaces(g,{x:0,y:0,orientation:0},id)};
}
// Progress is shared in both directions. First exact source, then a uniform
// turn/focus; the final front lies exactly in the live scene's camera rect.
export function point(n,q,progress){
 const p=clamp(progress),g=n.g,d=n.destination,fromPerspective=!!n.mapping.frame;
 if(p===0)return sourcePoint(g,n.p,n.mapping,q).concat(0);
 if(p===1)return [d.x+q[0]*d.scale,d.y+(g.h-q[2])*d.scale,q[1]];
 const turn=smooth((p-(fromPerspective?.10:.02))/(fromPerspective?.48:.58)),
       focus=smooth((p-(fromPerspective?0:.08))/(fromPerspective?.70:.62)),
       yaw=(n.p.orientation>180?n.p.orientation-360:n.p.orientation)*Math.PI/180*(1-turn),
       tilt=mix(fromPerspective?Math.atan2(n.mapping.frame.sin,n.mapping.frame.cos):0,Math.PI/2,turn),
       c=Math.cos(yaw),s=Math.sin(yaw),ct=Math.cos(tilt),st=Math.sin(tilt);
 const x=q[0]-g.w/2,y=q[1]-g.depth/2,z=q[2],X=x*c-y*s,Y=x*s+y*c;
 const k=mix(n.scale,d.scale,focus),cx=mix(n.center[0],d.x+g.w*d.scale/2,focus),cy=mix(n.center[1],d.y+g.h*d.scale,focus);
 let a=cx+X*k,b=cy+(Y*ct-z*st)*k;
 if(p<.24){const exact=sourcePoint(g,n.p,n.mapping,q),f=smooth(p/.24);a=mix(exact[0],a,f);b=mix(exact[1],b,f);}
 return [a,b,Y*st+z*ct];
}
export function layers(progress){
 const p=clamp(progress);
 return {room:1-smooth(p/.30),detail:smooth((p-.70)/.23),
         shell:smooth(p/.16)*(1-smooth((p-.70)/.23))};
}
export function surfaces(n,progress){
 if(!n)return [];
 const out=[];
 for(let i=0;i<n.faces.length;i++){
  const face=n.faces[i],points=face.points.map(q=>point(n,q,progress));
  let area=0;for(let j=0;j<points.length;j++){const a=points[j],b=points[(j+1)%points.length];area+=a[0]*b[1]-b[0]*a[1];}
  if(area<=1e-8)continue;
  const depth=points.reduce((sum,q)=>sum+q[2],0)/points.length;
  out.push({index:i,role:face.role,side:face.side,points,depth});
 }
 return out.sort((a,b)=>a.depth-b.depth||a.index-b.index);
}
