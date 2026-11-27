// B8-N3a candidate geometry, shared by future front/plan/perspective views.
// Pure geometry; ArchiveSpatial owns activation and persistence.
// S18r4 profiles and S15r4 H glyph establish direction, not native constants.
import * as Doors from "./ArchiveDoors.mjs";

const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
const profiles=["cornice","crest","pilaster"];
function need(ok,message){if(!ok)throw Error(message);}
function rect(x,y,w,h){return {x,y,w,h};}
function corners(r){return [[r.x,r.y],[r.x+r.w,r.y],[r.x+r.w,r.y+r.h],[r.x,r.y+r.h]];}
function quad(points,control,end){
 const start=points[points.length-1];
 for(let i=1;i<=8;i++){
  const t=i/8,u=1-t;
  points.push([u*u*start[0]+2*u*t*control[0]+t*t*end[0],u*u*start[1]+2*u*t*control[1]+t*t*end[1]]);
 }
}

// All front-local coordinates use the outer occupied top-left origin.
// Usable interior remains its original rectangular w/h; module coordinates
// are relative to aperture.x/y, never scaled or translated in saved data.
// b is the existing base frame thickness; reference proportions are
// provisional, derived from S18r4's 16-unit base post.
export function shelfGeometry(c,profile,depth,frameBasis){
 const b=frameBasis===undefined?(c.b===undefined?11:c.b):frameBasis;
 need([c.w,c.h,b,depth].every(Number.isFinite)&&c.w>0&&c.h>0&&b>0&&depth>0&&profiles.includes(profile),"Invalid Shelf profile geometry");
 const unit=b/16,post=profile==="pilaster"?27*unit:b,overhang=9*unit;
 const lintel=25*unit,plinth=26*unit,rise=profile==="crest"?37*unit:0;
 const w=c.w+2*(post+overhang),h=c.h+lintel+plinth+rise;
 const aperture=rect(post+overhang,lintel+rise,c.w,c.h),parts=[];
 function add(role,r){parts.push({role,points:corners(r)});}
 add("left-post",rect(overhang,aperture.y,post,c.h));
 add("right-post",rect(aperture.x+c.w,aperture.y,post,c.h));
 add("lintel",rect(0,rise,w,lintel));
 add("plinth",rect(0,aperture.y+c.h,w,19*unit));
 add("foot",rect(5*unit,aperture.y+c.h+19*unit,w-10*unit,7*unit));
 if(profile==="crest"){
  // Sample the three quadratic segments of the archived crest. The
  // half-span is bounded by the aperture, so narrow cases retain clearance.
  const x=w/2,half=Math.min(c.w/2,110*unit),a=half*62/110,z=half*35/110;
  const p=[[x-half,rise]];
  quad(p,[x-a,rise-3*unit],[x-z,rise-23*unit]);
  quad(p,[x,rise-51*unit],[x+z,rise-23*unit]);
  quad(p,[x+a,rise-3*unit],[x+half,rise]);
  parts.push({role:"crest",points:p});
 }
 if(profile==="pilaster"){
  // Capitals and bases stay within the lintel/plinth, not the aperture.
  for(const x of [overhang,aperture.x+c.w]){
   add("capital",rect(x,aperture.y-10*unit,post,10*unit));
   add("base",rect(x,aperture.y+c.h,post,10*unit));
  }
 }
 return {profile,w,h,depth,aperture,parts,inscription:rect(aperture.x,rise,c.w,lintel),floorY:h};
}

// Cardinal transform from unrotated plan-local coordinates (front at
// y=depth) to Room-local coordinates. Attachment x/y is the occupied
// AABB top-left for every rotation, matching the existing spatial contract.
export function planPoint(g,p,x,y){
 need([0,90,180,270].includes(p.orientation)&&[p.x,p.y,x,y].every(Number.isFinite),"Invalid Shelf orientation or point");
 let a=x,b=y;
 if(p.orientation===90){a=g.depth-y;b=x;}
 if(p.orientation===180){a=g.w-x;b=g.depth-y;}
 if(p.orientation===270){a=y;b=g.w-x;}
 return [p.x+a,p.y+b];
}
export function profileFootprint(g,p){
 need([0,90,180,270].includes(p.orientation),"Invalid Shelf orientation");
 const turned=p.orientation===90||p.orientation===270;
 return rect(p.x,p.y,turned?g.depth:g.w,turned?g.w:g.depth);
}
// Map the exact same frontal points into Room coordinates for perspective
// rendering. No separate Room-side profile or artificial plate ratio.
export function frontPoint(g,p,x,y){
 const q=planPoint(g,p,x,g.depth);
 return [q[0],q[1],g.floorY-y];
}

// S15r4 accepted H glyph: three nested rectangular layers and front lip.
// The glyph always uses the real occupied plan dimensions and orientation.
export function planGlyph(g,p){
 const inset=Math.min(7,g.depth*.14,g.w*.08),lip=Math.min(7,g.depth*.16);
 const layer=(role,r)=>({role,points:corners(r).map(q=>planPoint(g,p,q[0],q[1]))});
 return {layers:[layer("frame",rect(0,0,g.w,g.depth)),
  layer("recess",rect(inset,inset,g.w-2*inset,g.depth-2*inset)),
  layer("panel",rect(2*inset,2*inset,g.w-4*inset,g.depth-4*inset))],
  front:[[inset,g.depth-lip],[g.w-inset,g.depth-lip]].map(q=>planPoint(g,p,q[0],q[1]))};
}
export function fitFront(g,w,h,margin=16){
 need([w,h,margin].every(Number.isFinite)&&margin>=0&&w>2*margin&&h>2*margin,"Invalid front viewport");
 const scale=Math.min((w-2*margin)/g.w,(h-2*margin)/g.h);
 return {scale,x:(w-g.w*scale)/2,y:(h-g.h*scale)/2};
}
function overlap(a,b){return a.x<b.x+b.w&&b.x<a.x+a.w&&a.y<b.y+b.h&&b.y<a.y+a.h;}

// Evaluate a hypothetical full-profile migration on a valid v3 snapshot.
// This is a report, NOT a structural proposal or an Apply path. No hidden
// expansion, room resizing, door removal, object displacement or mutation.
export function inspectProfileLayout(s,basisFor=()=>undefined){
 need(s&&s.spatial&&s.spatial.shelves,"Expected spatial study");
 const shelves={},conflicts=[],byRoom={};
 for(const id of Object.keys(s.spatial.shelves)){
  const p=s.spatial.shelves[id],c=s.cubbies[id],r=s.spatial.rooms[p.roomId];
  need(c&&r,"Invalid Shelf attachment");
  const g=shelfGeometry(c,c.appearance&&c.appearance.profile||"cornice",p.depth,basisFor(c,p));
  const box=profileFootprint(g,p);
  shelves[id]={geometry:g,box};
  if(box.x<0||box.y<0||box.x+box.w>r.w||box.y+box.h>r.h)conflicts.push({kind:"wall",shelfId:id,roomId:p.roomId});
  if(!own(byRoom,p.roomId))byRoom[p.roomId]=[];
  for(const other of byRoom[p.roomId])if(overlap(box,shelves[other].box))conflicts.push({kind:"shelf",shelfId:id,otherId:other,roomId:p.roomId});
  byRoom[p.roomId].push(id);
 }
 for(const doorId of Doors.invalidated(s,(_,id)=>shelves[id].box))conflicts.push({kind:"door",doorId});
 return {ok:conflicts.length===0,shelves,conflicts};
}
