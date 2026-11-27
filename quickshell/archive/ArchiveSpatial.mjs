// B8-N1a: opt-in spatial hierarchy on the existing physical-container registry.
// No renderer, file I/O, automatic migration, or second ownership inventory.
import * as Doors from "./ArchiveDoors.mjs";
import * as Architecture from "./ArchiveArchitecture.mjs";
import * as Mixed from "./representation/B7Ownership.mjs";
const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
const plain=v=>!!v&&typeof v==='object'&&!Array.isArray(v);
const id=v=>typeof v==='string'&&v.length>0&&v.length<=128&&!['__proto__','constructor','prototype'].includes(v);
const integer=(v,min,max)=>Number.isInteger(v)&&v>=min&&v<=max;
const need=(v,msg)=>{if(!v)throw Error(msg);};
const name=v=>typeof v==='string'&&v.trim().length>0&&v.length<=80;
export const spatialLimits=Object.freeze({rooms:64,roomSize:10000,mapCoordinate:100000,shelfDepth:1800,applications:512});
export function enabled(s){return !!s&&own(s,'spatial');}
export function roots(s){return enabled(s)?Object.keys(s.spatial.shelves):['root'];}
export function kind(s,containerId){return !own(s.cubbies,containerId)?null:enabled(s)&&own(s.spatial.shelves,containerId)?'shelf':'cubby';}
export function exterior(c){
 const b=c.b===undefined?11:c.b;
 return {w:c.w+2*b,h:c.h+2*b};
}
// Snapshot-wide activation; absent policy retains the legacy envelope.
export const profilePolicy='profile-v1';
export const independentProfilePolicy='profile-v2';
// Provisional reference-relative seed, persisted once; no reactive resize.
export const defaultWallHeight=1339.2;
export function frameSeed(c){return Math.max(4,Math.min(40,24*Math.min(c.w/1400,c.h/1050)));}
export function independentProfiles(s){return enabled(s)&&s.spatial.geometryPolicy===independentProfilePolicy;}
export function physicalProfiles(s){return enabled(s)&&(s.spatial.geometryPolicy===profilePolicy||independentProfiles(s));}
export function checkpointVersion(s){return independentProfiles(s)?5:physicalProfiles(s)?4:enabled(s)?3:2;}
function frameValid(v){return Number.isFinite(v)&&v>=4&&v<=40;}
function wallValid(v){return Number.isFinite(v)&&v>=1&&v<=20000;}
export function shelfGeometry(s,shelfId){
 const p=s.spatial.shelves[shelfId],c=s.cubbies[shelfId];
 return Architecture.shelfGeometry(c,shelfProfile(s,shelfId),p.depth,independentProfiles(s)?p.frameBasis:undefined);
}
export function footprint(s,shelfId){
 if(physicalProfiles(s))return Architecture.profileFootprint(shelfGeometry(s,shelfId),s.spatial.shelves[shelfId]);
 const p=s.spatial.shelves[shelfId],c=s.cubbies[shelfId],e=exterior(c);
 const sideways=p.orientation===90||p.orientation===270;
 return {x:p.x,y:p.y,w:sideways?p.depth:e.w,h:sideways?e.w:p.depth};
}
// Both envelopes and all conflicts, including invalid adoption proposals.
export function profileAdoptionReport(s,v2=false){
 const report=Architecture.inspectProfileLayout(s,v2?frameSeed:()=>undefined);
 for(const k of Object.keys(report.shelves)){
  const c=s.cubbies[k],b=c.b===undefined?11:c.b,e=exterior(c),old=physicalProfiles(s)?shelfGeometry(s,k):{w:e.w,h:e.h,aperture:{x:b,y:b,w:c.w,h:c.h}};
  report.shelves[k].previous={box:footprint(s,k),w:old.w,h:old.h,aperture:old.aperture};
  if(v2)report.shelves[k].frameBasis=frameSeed(c);
 }
 if(v2)report.rooms=Object.keys(s.spatial.rooms).map(id=>({id,wallHeight:defaultWallHeight}));
 return report;
}
function overlap(a,b){return a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y;}
function inside(a,w,h){return a.x>=0&&a.y>=0&&a.x+a.w<=w&&a.y+a.h<=h;}
function keysOnly(o,keys){return plain(o)&&Object.keys(o).every(k=>keys.includes(k));}
export const shelfProfiles=Object.freeze(['cornice','crest','pilaster']);
function appearance(v,shelf=false){
 return v===undefined||keysOnly(v,shelf?['family','palette','profile']:['family','palette'])&&
  (v.profile===undefined||v.profile===null||shelf&&shelfProfiles.includes(v.profile))&&
  (v.family===undefined||v.family===null||name(v.family))&&
  (v.palette===undefined||v.palette===null||integer(v.palette,0,2));
}
export function validate(s){
 if(!enabled(s))return null;
 try{
  const a=s.spatial;
  need(keysOnly(a,['rooms','shelves','appearance','apps','doors','geometryPolicy'])&&(a.geometryPolicy===undefined||a.geometryPolicy===profilePolicy||a.geometryPolicy===independentProfilePolicy)&&plain(a.rooms)&&plain(a.shelves)&&appearance(a.appearance),'Invalid spatial envelope');
  const rooms=Object.keys(a.rooms),shelves=Object.keys(a.shelves),roomBoxes=[],shelfBoxes=new Map();
  need(rooms.length>0&&rooms.length<=spatialLimits.rooms&&shelves.length>0&&shelves.length<=128,'Spatial room/shelf budget');
  for(const k of rooms){
   const r=a.rooms[k];
   need(id(k)&&!own(s.cubbies,k)&&keysOnly(r,independentProfiles(s)?['id','name','x','y','w','h','appearance','wallHeight']:['id','name','x','y','w','h','appearance'])&&r.id===k&&name(r.name)&&appearance(r.appearance),'Invalid Room identity or metadata');
   if(independentProfiles(s))need(wallValid(r.wallHeight),'Invalid independent Room wall height');
   need(integer(r.x,-spatialLimits.mapCoordinate,spatialLimits.mapCoordinate)&&integer(r.y,-spatialLimits.mapCoordinate,spatialLimits.mapCoordinate)&&integer(r.w,130,spatialLimits.roomSize)&&integer(r.h,100,spatialLimits.roomSize),'Invalid Room dimensions');
   need(!roomBoxes.some(b=>overlap(b,r)),'Rooms overlap');roomBoxes.push(r);shelfBoxes.set(k,[]);
  }
  for(const k of shelves){
   const p=a.shelves[k];
   need(id(k)&&own(s.cubbies,k)&&keysOnly(p,independentProfiles(s)?['roomId','x','y','depth','orientation','frameBasis']:['roomId','x','y','depth','orientation'])&&id(p.roomId)&&own(a.rooms,p.roomId),'Invalid architectural Shelf attachment');
   if(independentProfiles(s))need(frameValid(p.frameBasis),'Invalid independent Shelf frame basis');
   need(integer(p.x,0,spatialLimits.roomSize)&&integer(p.y,0,spatialLimits.roomSize)&&integer(p.depth,40,spatialLimits.shelfDepth)&&[0,90,180,270].includes(p.orientation),'Invalid Shelf footprint');
   const b=footprint(s,k),r=a.rooms[p.roomId],boxes=shelfBoxes.get(p.roomId);
   need(inside(b,r.w,r.h)&&!boxes.some(q=>overlap(q,b)),'Shelf overlaps or exceeds Room');boxes.push(b);
  }
  const parents=new Map(),structuralIds=new Set(rooms.concat(Object.keys(s.cubbies))),placedApps=new Set();
  const apps=a.apps===undefined?{}:a.apps;
  need(plain(apps)&&Object.keys(apps).length<=spatialLimits.applications,'Application catalogue budget');
  for(const [k,v] of Object.entries(apps))need(id(k)&&keysOnly(v,['appId','title'])&&v.appId===k&&name(v.title),'Invalid application identity');
  for(const c of Object.values(s.cubbies)){
   need((c.name===undefined||name(c.name))&&appearance(c.appearance,own(a.shelves,c.id)),'Invalid container name or appearance reference');
   for(const m of c.mods){
    need(!structuralIds.has(m.id),'Duplicate spatial structural identity');structuralIds.add(m.id);
    for(const meta of Object.values(m.cellMeta||{})){need(!structuralIds.has(meta.id),'Duplicate spatial structural identity');structuralIds.add(meta.id);}
    for(const entry of m.items||[]){
     if(entry.kind==='holder'){need(!structuralIds.has(entry.id),'Duplicate spatial structural identity');structuralIds.add(entry.id);}
     if(entry.kind==='app'){
      need(own(apps,entry.appId)&&!placedApps.has(entry.appId),'Missing or multiply placed application');placedApps.add(entry.appId);
     }
    }
    if(m.type==='cubby'){
     need(!own(a.shelves,m.childId)&&!parents.has(m.childId),'Architectural Shelf cannot be nested; Cubby has one parent');
     parents.set(m.childId,c.id);
    }
   }
  }
  for(const k of Object.keys(s.cubbies)){
   const seen=new Set();let cursor=k;
   while(parents.has(cursor)){need(!seen.has(cursor),'Cyclic spatial hierarchy');seen.add(cursor);cursor=parents.get(cursor);}
   need(own(a.shelves,cursor),'Container is not attached to an architectural Shelf');
  }
  Doors.validate(s,footprint,structuralIds);
  return null;
 }catch(e){return String(e.message||e);}
}
// Family follows the nearest explicit ancestor (including explicit None).
// Palette is deliberately local; an ancestor's override never recolours children.
export function resolveAppearance(s,containerId,globalPalette){
 need(enabled(s)&&own(s.cubbies,containerId)&&integer(globalPalette,0,2),'Invalid appearance target');
 let cursor=containerId,chain=[],seen=new Set();
 while(!own(s.spatial.shelves,cursor)){
  need(!seen.has(cursor),'Cyclic spatial hierarchy');seen.add(cursor);
  const parent=Object.values(s.cubbies).find(c=>c.mods.some(m=>m.type==='cubby'&&m.childId===cursor));
  need(parent,'Unattached container');chain.push(s.cubbies[cursor].appearance);cursor=parent.id;
 }
 chain.push(s.cubbies[cursor].appearance,s.spatial.rooms[s.spatial.shelves[cursor].roomId].appearance,s.spatial.appearance);
 const chosen=chain.find(a=>a&&a.family!==undefined&&a.family!==null);
 const local=s.cubbies[containerId].appearance;
 return {family:chosen?chosen.family:'Architectural',palette:local&&local.palette!==undefined&&local.palette!==null?local.palette:globalPalette};
}
// Profiles are explicit per architectural Shelf, never inherited by Cubbies.
export function shelfProfile(s,id){
 need(enabled(s)&&own(s.spatial.shelves,id),'Invalid Shelf profile target');
 const a=s.cubbies[id].appearance;
 return a&&a.profile||'cornice';
}
// Application catalogue and placements are separate from file owners/Case.
export function appPlacements(s){
 const out=[];
 if(enabled(s))for(const c of Object.values(s.cubbies))for(const m of c.mods)
  for(const item of m.items||[])if(item.kind==='app')out.push({appId:item.appId,containerId:c.id,moduleId:m.id,x:item.x});
 return out;
}
export function doorGeometry(s,doorId){
 need(enabled(s)&&s.spatial.doors&&own(s.spatial.doors,doorId),'Door no longer exists');
 return Doors.geometry(s,s.spatial.doors[doorId],footprint);
}
function patch(target,p,allowed){
 need(keysOnly(p,allowed),'Unknown spatial property');
 for(const k of Object.keys(p))target[k]=p[k];
}
// Only called on an unpublished Core clone. Core validates the complete
// snapshot, preserves file IDs and publishes exactly one Undo entry.
export function edit(s,cmd,allocate){
 const p=cmd.patch===undefined?{}:cmd.patch;
 need(plain(p),'Invalid spatial patch');
 for(const key of ['roomId','containerId','moduleId','appId','doorId'])
  if(own(cmd,key))need(id(cmd[key]),'Invalid spatial target identity');
 if(cmd.kind==='spatialPromote'){
  need(!enabled(s)&&own(s.cubbies,'root'),'Expected legacy study');
  need(keysOnly(p,['depth','roomName']),'Unknown promotion property');
  const roomId=allocate('room-'),c=s.cubbies.root,e=exterior(c),depth=p.depth===undefined?160:p.depth;
  s.spatial={rooms:{},shelves:{}};
  s.spatial.rooms[roomId]={id:roomId,name:p.roomName===undefined?'Main Hall':p.roomName,x:0,y:0,w:Math.max(130,Math.ceil(e.w+100)),h:Math.max(100,depth+100)};
  s.spatial.shelves.root={roomId,x:50,y:50,depth,orientation:0};
  return;
 }
 need(enabled(s),'Enable spatial study explicitly');
 const a=s.spatial;
 if(cmd.kind==='spatialAdoptProfiles'){
  need(!physicalProfiles(s)&&keysOnly(p,[]),'Profiles already adopted or unexpected adoption properties');
  // Core validates the complete clone. Never auto-relocate to fit.
  a.geometryPolicy=profilePolicy;
 }else if(cmd.kind==='spatialAdoptIndependentProfiles'){
  need(!independentProfiles(s)&&keysOnly(p,[]),'Independent profiles already adopted or unexpected adoption properties');
  for(const [k,v] of Object.entries(a.shelves))v.frameBasis=frameSeed(s.cubbies[k]);
  for(const r of Object.values(a.rooms))r.wallHeight=defaultWallHeight;
  a.geometryPolicy=independentProfilePolicy;
 }else if(cmd.kind==='spatialShelfTurn'){
  const k=cmd.containerId;
  need(physicalProfiles(s)&&own(a.shelves,k)&&keysOnly(p,['orientation']),'Turn requires adopted architectural Shelf');
  const v=a.shelves[k],r=a.rooms[v.roomId],old=footprint(s,k);
  need([0,90,180,270].includes(p.orientation)&&Math.abs(p.orientation-v.orientation)%180===90,'Choose a quarter turn');
  v.orientation=p.orientation;
  const next=footprint(s,k);
  need(next.w<=r.w&&next.h<=r.h,'Turn cannot fit inside Room');
  // Center to nearest whole stored unit; only selected Shelf moves inward.
  v.x=Math.max(0,Math.min(Math.floor(r.w-next.w),Math.round(old.x+(old.w-next.w)/2)));
  v.y=Math.max(0,Math.min(Math.floor(r.h-next.h),Math.round(old.y+(old.h-next.h)/2)));
 }else if(cmd.kind==='spatialRoomCreate'){
  const k=allocate('room-'),r={id:k,name:'New Room',x:0,y:0,w:1000,h:800};
  if(independentProfiles(s))r.wallHeight=defaultWallHeight;
  patch(r,p,independentProfiles(s)?['name','x','y','w','h','appearance','wallHeight']:['name','x','y','w','h','appearance']);a.rooms[k]=r;
 }else if(cmd.kind==='spatialRoomEdit'){
  need(own(a.rooms,cmd.roomId),'Room no longer exists');
  patch(a.rooms[cmd.roomId],p,independentProfiles(s)?['name','x','y','w','h','appearance','wallHeight']:['name','x','y','w','h','appearance']);
  Doors.resolveLost(s,cmd.removeDoors,footprint);
 }else if(cmd.kind==='spatialRoomDelete'){
  need(own(a.rooms,cmd.roomId)&&Object.keys(a.rooms).length>1,'Keep at least one Room');
  need(!Object.values(a.shelves).some(v=>v.roomId===cmd.roomId),'Remove or relocate Shelves first');
  need(!Object.keys(p).length,'Unexpected delete properties');delete a.rooms[cmd.roomId];
  Doors.resolveLost(s,cmd.removeDoors,footprint);
 }else if(cmd.kind==='spatialShelfCreate'){
  const k=allocate('architectural-shelf-'),c={id:k,name:'New Shelf',w:700,h:500,b:11,mods:[]},v={roomId:cmd.roomId,x:0,y:0,depth:160,orientation:0};
  for(const key of ['w','h','b'])if(own(p,key))need(Number.isInteger(p[key]),'Enter whole-number Shelf dimensions');
  need(keysOnly(p,independentProfiles(s)?['name','w','h','b','appearance','x','y','depth','orientation','frameBasis']:['name','w','h','b','appearance','x','y','depth','orientation']),'Unknown Shelf property');
  for(const key of ['name','w','h','b','appearance'])if(own(p,key))c[key]=p[key];
  for(const key of ['x','y','depth','orientation'])if(own(p,key))v[key]=p[key];
  if(independentProfiles(s))v.frameBasis=own(p,'frameBasis')?p.frameBasis:frameSeed(c);
  need(name(c.name),'Invalid Shelf name');s.cubbies[k]=c;a.shelves[k]=v;
 }else if(cmd.kind==='spatialShelfEdit'){
  const k=cmd.containerId;need(own(a.shelves,k),'Architectural Shelf no longer exists');
  need(keysOnly(p,independentProfiles(s)?['name','w','h','b','appearance','roomId','x','y','depth','orientation','frameBasis']:['name','w','h','b','appearance','roomId','x','y','depth','orientation']),'Unknown Shelf property');
  const c=s.cubbies[k],v=a.shelves[k];
  for(const key of ['w','h','b'])if(own(p,key))need(Number.isInteger(p[key]),'Enter whole-number Shelf dimensions');
  for(const key of ['name','w','h','b','appearance'])if(own(p,key))c[key]=p[key];
  for(const key of ['roomId','x','y','depth','orientation'])if(own(p,key))v[key]=p[key];
  if(independentProfiles(s)&&own(p,'frameBasis'))v.frameBasis=p.frameBasis;
  need(c.name===undefined||name(c.name),'Invalid Shelf name');
 }else if(cmd.kind==='spatialShelfDelete'){
  const k=cmd.containerId;
  need(own(a.shelves,k)&&Object.keys(a.shelves).length>1,'Keep at least one architectural Shelf');
  need(s.cubbies[k].mods.length===0,'Resolve Shelf contents before removal');
  need(!Object.keys(p).length,'Unexpected delete properties');
  delete a.shelves[k];delete s.cubbies[k];
  for(const record of s.caseItems)if(record.originCubbyId===k)record.originStale=true;
  if(s.path[0]===k)s.path=[Object.keys(a.shelves)[0]];
 }else if(cmd.kind==='spatialAppRegister'){
  need(keysOnly(p,['appId','title'])&&id(p.appId)&&name(p.title),'Invalid synthetic application metadata');
  const apps=a.apps||(a.apps={});
  need(!own(apps,p.appId),'Application already registered');apps[p.appId]={appId:p.appId,title:p.title};
 }else if(cmd.kind==='spatialAppPlace'||cmd.kind==='spatialAppUnplace'){
  need(a.apps&&own(a.apps,cmd.appId),'Unknown application identity');
  const previous=appPlacements(s).find(v=>v.appId===cmd.appId);
  if(cmd.kind==='spatialAppUnplace')need(previous&&keysOnly(p,[]),'Application is not placed');
  else need(keysOnly(p,['x'])&&Number.isFinite(p.x)&&own(s.cubbies,cmd.containerId),'Invalid book placement');
  if(previous){
   const old=s.cubbies[previous.containerId].mods.find(m=>m.id===previous.moduleId);
   old.items=old.items.filter(v=>v.kind!=='app'||v.appId!==cmd.appId);
  }
  if(cmd.kind==='spatialAppPlace'){
   const m=s.cubbies[cmd.containerId].mods.find(v=>v.id===cmd.moduleId);
   need(Mixed.supportsTop(m),'Choose an eligible book support');
   if(!m.items)m.items=[];m.items.push({kind:'app',appId:cmd.appId,x:p.x});
  }
 }else if(typeof cmd.kind==='string'&&cmd.kind.indexOf('spatialDoor')===0){
  Doors.edit(s,cmd,p,allocate,footprint);
 }else if(cmd.kind==='spatialSupport'){
  need(own(s.cubbies,cmd.containerId),'Container no longer exists');
  const m=s.cubbies[cmd.containerId].mods.find(v=>v.id===cmd.moduleId);
  need(m&&(m.type==='rack'||m.type==='cubby'),'Only rack and Cubby tops may be enabled');
  need(keysOnly(p,['enabled'])&&typeof p.enabled==='boolean','Choose support eligibility explicitly');
  if(p.enabled)m.flatTop=true;
  else{
   need(!(m.items||[]).length,'Resolve supported objects and holders before disabling the surface');
   delete m.flatTop;delete m.items;
   for(const record of s.caseItems)if(record.originCubbyId===cmd.containerId&&record.originModuleId===m.id)record.originStale=true;
  }
 }else if(cmd.kind==='spatialAppearance'){
  const isShelf=cmd.containerId!==undefined&&own(a.shelves,cmd.containerId);
  need(appearance(p,isShelf),'Invalid appearance reference');
  const target=cmd.containerId===undefined?s.spatial:s.cubbies[cmd.containerId];
  need(cmd.containerId===undefined||own(s.cubbies,cmd.containerId),'Container no longer exists');
  // An untouched appearance editor must not create metadata.
  if(Object.keys(p).length)target.appearance=Object.assign({},target.appearance||{},p);
 }else throw Error('Unknown spatial command');
}
