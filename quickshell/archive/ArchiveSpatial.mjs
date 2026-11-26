// B8-N1a: opt-in spatial hierarchy on the existing physical-container registry.
// No renderer, file I/O, automatic migration, or second ownership inventory.
const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
const plain=v=>!!v&&typeof v==='object'&&!Array.isArray(v);
const id=v=>typeof v==='string'&&v.length>0&&v.length<=128&&!['__proto__','constructor','prototype'].includes(v);
const integer=(v,min,max)=>Number.isInteger(v)&&v>=min&&v<=max;
const need=(v,msg)=>{if(!v)throw Error(msg);};
const name=v=>typeof v==='string'&&v.trim().length>0&&v.length<=80;
export const spatialLimits=Object.freeze({rooms:64,roomSize:10000,mapCoordinate:100000,shelfDepth:1800});
export function enabled(s){return !!s&&own(s,'spatial');}
export function roots(s){return enabled(s)?Object.keys(s.spatial.shelves):['root'];}
export function kind(s,containerId){return !own(s.cubbies,containerId)?null:enabled(s)&&own(s.spatial.shelves,containerId)?'shelf':'cubby';}
export function exterior(c){
 const b=c.b===undefined?11:c.b;
 return {w:c.w+2*b,h:c.h+2*b};
}
export function footprint(s,shelfId){
 const p=s.spatial.shelves[shelfId],c=s.cubbies[shelfId],e=exterior(c);
 const sideways=p.orientation===90||p.orientation===270;
 return {x:p.x,y:p.y,w:sideways?p.depth:e.w,h:sideways?e.w:p.depth};
}
function overlap(a,b){return a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y;}
function inside(a,w,h){return a.x>=0&&a.y>=0&&a.x+a.w<=w&&a.y+a.h<=h;}
function keysOnly(o,keys){return plain(o)&&Object.keys(o).every(k=>keys.includes(k));}
function appearance(v){
 return v===undefined||keysOnly(v,['family','palette'])&&
  (v.family===undefined||v.family===null||name(v.family))&&
  (v.palette===undefined||v.palette===null||integer(v.palette,0,2));
}
export function validate(s){
 if(!enabled(s))return null;
 try{
  const a=s.spatial;
  need(keysOnly(a,['rooms','shelves','appearance'])&&plain(a.rooms)&&plain(a.shelves)&&appearance(a.appearance),'Invalid spatial envelope');
  const rooms=Object.keys(a.rooms),shelves=Object.keys(a.shelves),roomBoxes=[],shelfBoxes=new Map();
  need(rooms.length>0&&rooms.length<=spatialLimits.rooms&&shelves.length>0&&shelves.length<=128,'Spatial room/shelf budget');
  for(const k of rooms){
   const r=a.rooms[k];
   need(id(k)&&!own(s.cubbies,k)&&keysOnly(r,['id','name','x','y','w','h','appearance'])&&r.id===k&&name(r.name)&&appearance(r.appearance),'Invalid Room identity or metadata');
   need(integer(r.x,-spatialLimits.mapCoordinate,spatialLimits.mapCoordinate)&&integer(r.y,-spatialLimits.mapCoordinate,spatialLimits.mapCoordinate)&&integer(r.w,130,spatialLimits.roomSize)&&integer(r.h,100,spatialLimits.roomSize),'Invalid Room dimensions');
   need(!roomBoxes.some(b=>overlap(b,r)),'Rooms overlap');roomBoxes.push(r);shelfBoxes.set(k,[]);
  }
  for(const k of shelves){
   const p=a.shelves[k];
   need(id(k)&&own(s.cubbies,k)&&keysOnly(p,['roomId','x','y','depth','orientation'])&&id(p.roomId)&&own(a.rooms,p.roomId),'Invalid architectural Shelf attachment');
   need(integer(p.x,0,spatialLimits.roomSize)&&integer(p.y,0,spatialLimits.roomSize)&&integer(p.depth,40,spatialLimits.shelfDepth)&&[0,90,180,270].includes(p.orientation),'Invalid Shelf footprint');
   const b=footprint(s,k),r=a.rooms[p.roomId],boxes=shelfBoxes.get(p.roomId);
   need(inside(b,r.w,r.h)&&!boxes.some(q=>overlap(q,b)),'Shelf overlaps or exceeds Room');boxes.push(b);
  }
  const parents=new Map(),structuralIds=new Set(rooms.concat(Object.keys(s.cubbies)));
  for(const c of Object.values(s.cubbies)){
   need((c.name===undefined||name(c.name))&&appearance(c.appearance),'Invalid container name or appearance reference');
   for(const m of c.mods){
    need(!structuralIds.has(m.id),'Duplicate spatial structural identity');structuralIds.add(m.id);
    for(const meta of Object.values(m.cellMeta||{})){need(!structuralIds.has(meta.id),'Duplicate spatial structural identity');structuralIds.add(meta.id);}
    for(const entry of m.items||[])if(entry.kind==='holder'){need(!structuralIds.has(entry.id),'Duplicate spatial structural identity');structuralIds.add(entry.id);}
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
function patch(target,p,allowed){
 need(keysOnly(p,allowed),'Unknown spatial property');
 for(const k of Object.keys(p))target[k]=p[k];
}
// Only called on an unpublished Core clone. Core validates the complete
// snapshot, preserves file IDs and publishes exactly one Undo entry.
export function edit(s,cmd,allocate){
 const p=cmd.patch===undefined?{}:cmd.patch;
 need(plain(p),'Invalid spatial patch');
 if(cmd.kind==='spatialPromote'){
  need(!enabled(s)&&own(s.cubbies,'root'),'Expected legacy study');
  need(keysOnly(p,['depth','roomName']),'Unknown promotion property');
  const roomId=allocate('room-'),c=s.cubbies.root,e=exterior(c),depth=p.depth===undefined?160:p.depth;
  s.spatial={rooms:{},shelves:{}};
  s.spatial.rooms[roomId]={id:roomId,name:p.roomName===undefined?'Main Hall':p.roomName,x:0,y:0,w:Math.max(130,e.w+100),h:Math.max(100,depth+100)};
  s.spatial.shelves.root={roomId,x:50,y:50,depth,orientation:0};
  return;
 }
 need(enabled(s),'Enable spatial study explicitly');
 const a=s.spatial;
 if(cmd.kind==='spatialRoomCreate'){
  const k=allocate('room-'),r={id:k,name:'New Room',x:0,y:0,w:1000,h:800};
  patch(r,p,['name','x','y','w','h','appearance']);a.rooms[k]=r;
 }else if(cmd.kind==='spatialRoomEdit'){
  need(own(a.rooms,cmd.roomId),'Room no longer exists');
  patch(a.rooms[cmd.roomId],p,['name','x','y','w','h','appearance']);
 }else if(cmd.kind==='spatialRoomDelete'){
  need(own(a.rooms,cmd.roomId)&&Object.keys(a.rooms).length>1,'Keep at least one Room');
  need(!Object.values(a.shelves).some(v=>v.roomId===cmd.roomId),'Remove or relocate Shelves first');
  need(!Object.keys(p).length,'Unexpected delete properties');delete a.rooms[cmd.roomId];
 }else if(cmd.kind==='spatialShelfCreate'){
  const k=allocate('architectural-shelf-'),c={id:k,name:'New Shelf',w:700,h:500,b:11,mods:[]},v={roomId:cmd.roomId,x:0,y:0,depth:160,orientation:0};
  need(keysOnly(p,['name','w','h','b','appearance','x','y','depth','orientation']),'Unknown Shelf property');
  for(const key of ['name','w','h','b','appearance'])if(own(p,key))c[key]=p[key];
  for(const key of ['x','y','depth','orientation'])if(own(p,key))v[key]=p[key];
  need(name(c.name),'Invalid Shelf name');s.cubbies[k]=c;a.shelves[k]=v;
 }else if(cmd.kind==='spatialShelfEdit'){
  const k=cmd.containerId;need(own(a.shelves,k),'Architectural Shelf no longer exists');
  need(keysOnly(p,['name','w','h','b','appearance','roomId','x','y','depth','orientation']),'Unknown Shelf property');
  const c=s.cubbies[k],v=a.shelves[k];
  for(const key of ['name','w','h','b','appearance'])if(own(p,key))c[key]=p[key];
  for(const key of ['roomId','x','y','depth','orientation'])if(own(p,key))v[key]=p[key];
  need(c.name===undefined||name(c.name),'Invalid Shelf name');
 }else if(cmd.kind==='spatialShelfDelete'){
  const k=cmd.containerId;
  need(own(a.shelves,k)&&Object.keys(a.shelves).length>1,'Keep at least one architectural Shelf');
  need(s.cubbies[k].mods.length===0,'Resolve Shelf contents before removal');
  need(!Object.keys(p).length,'Unexpected delete properties');
  delete a.shelves[k];delete s.cubbies[k];
  for(const record of s.caseItems)if(record.originCubbyId===k)record.originStale=true;
  if(s.path[0]===k)s.path=[Object.keys(a.shelves)[0]];
 }else if(cmd.kind==='spatialAppearance'){
  need(keysOnly(p,['family','palette'])&&appearance(p),'Invalid appearance reference');
  const target=cmd.containerId===undefined?s.spatial:s.cubbies[cmd.containerId];
  need(cmd.containerId===undefined||own(s.cubbies,cmd.containerId),'Container no longer exists');
  target.appearance=Object.assign({},target.appearance||{},p);
 }else throw Error('Unknown spatial command');
}
