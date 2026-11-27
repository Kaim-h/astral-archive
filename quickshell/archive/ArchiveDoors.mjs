// Rectangular boundary contract; edge identity is the structured pair
// (roomId, side), not an array position or a coordinate. One shared door.
const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
const plain=v=>!!v&&typeof v==='object'&&!Array.isArray(v);
const keys=(o,allowed)=>plain(o)&&Object.keys(o).every(k=>allowed.includes(k));
const need=(v,msg)=>{if(!v)throw Error(msg);};
const sides=['north','east','south','west'];
const opposite={north:'south',south:'north',east:'west',west:'east'};
export const doorLimit=256;
export function edge(s,ref){
 need(keys(ref,['roomId','side'])&&typeof ref.roomId==='string'&&own(s.spatial.rooms,ref.roomId)&&sides.includes(ref.side),'Unknown Room boundary');
 const r=s.spatial.rooms[ref.roomId],vertical=ref.side==='east'||ref.side==='west';
 return {roomId:ref.roomId,side:ref.side,vertical,
  line:vertical?r.x+(ref.side==='east'?r.w:0):r.y+(ref.side==='south'?r.h:0),
  start:vertical?r.y:r.x,length:vertical?r.h:r.w};
}
function sameEdge(a,b){return a.roomId===b.roomId&&a.side===b.side;}
function samePair(a,b){return sameEdge(a.a,b.a)&&sameEdge(a.b,b.b)||sameEdge(a.a,b.b)&&sameEdge(a.b,b.a);}
function overlap(a,b,c,d){return a<d&&c<b;}
// Half-open projected occupied intervals, including fractional ornament.
function wallBlockers(s,edges,footprint){
 const blocked=[];
 for(const side of edges){
  const r=s.spatial.rooms[side.roomId];
  for(const k of Object.keys(s.spatial.shelves)){
   if(s.spatial.shelves[k].roomId!==side.roomId)continue;
   const p=footprint(s,k);
   const touches=side.side==='north'?p.y<=0&&p.y+p.h>=0:side.side==='south'?p.y<=r.h&&p.y+p.h>=r.h:side.side==='west'?p.x<=0&&p.x+p.w>=0:p.x<=r.w&&p.x+p.w>=r.w;
   const lo=side.start+(side.vertical?p.y:p.x),hi=lo+(side.vertical?p.h:p.w);
   if(touches)blocked.push({start:lo,end:hi});
  }
 }
 return blocked;
}
// Clear spans are inclusive endpoint bounds for positive-width half-open
// integer openings. Round obstacles outward, never grant fractional clearance.
export function clearSpans(s,aRef,bRef,footprint,excludeId){
 const a=edge(s,aRef),b=edge(s,bRef);
 need(a.roomId!==b.roomId&&opposite[a.side]===b.side&&a.line===b.line,'Door requires opposing shared Room boundaries');
 const start=Math.max(a.start,b.start),end=Math.min(a.start+a.length,b.start+b.length);
 if(end<=start)return [];
 const blocked=wallBlockers(s,[a,b],footprint);
 for(const d of Object.values(s.spatial.doors||{})){
  if(d.id===excludeId)continue;
  const g=geometry(s,d,footprint);
  if(g.vertical===a.vertical&&g.line===a.line)blocked.push({start:g.start,end:g.end});
 }
 const spans=[];let cursor=start;
 for(const q of blocked.sort((u,v)=>u.start-v.start||u.end-v.end)){
  const lo=Math.max(start,Math.floor(q.start)),hi=Math.min(end,Math.ceil(q.end));
  if(hi<=cursor||hi<=lo)continue;
  if(lo>cursor)spans.push({start:cursor,end:Math.min(end,lo)});
  cursor=Math.max(cursor,hi);if(cursor>=end)break;
 }
 if(cursor<end)spans.push({start:cursor,end});
 return spans;
}
export function adjacentPairs(s,roomId,footprint){
 if(!s.spatial||!own(s.spatial.rooms,roomId))return [];
 const pairs=[];
 for(const side of sides){
  const a={roomId,side},ea=edge(s,a);
  for(const id of Object.keys(s.spatial.rooms)){
   if(id===roomId)continue;
   const b={roomId:id,side:opposite[side]},eb=edge(s,b);
   if(ea.line!==eb.line||Math.max(ea.start,eb.start)>=Math.min(ea.start+ea.length,eb.start+eb.length))continue;
   const spans=clearSpans(s,a,b,footprint);
   if(spans.length)pairs.push({a,b,vertical:ea.vertical,line:ea.line,origin:ea.start,spans});
  }
 }
 return pairs;
}
export function doorEditSpan(s,d,footprint){
 const g=geometry(s,d,footprint);
 return clearSpans(s,d.a,d.b,footprint,d.id).find(v=>v.start<=g.start&&g.end<=v.end)||null;
}
export function gesturePatch(g,span,origin,kind,delta){
 if(!g||!span||!Number.isInteger(origin)||!Number.isInteger(delta)||!['move','start','end'].includes(kind))return null;
 if(span.start>g.start||span.end<g.end||g.start>=g.end)return null;
 const clamp=(v,lo,hi)=>Math.max(lo,Math.min(hi,v));
 let start=g.start,end=g.end;
 if(kind==='move'){const shift=clamp(delta,span.start-start,span.end-end);start+=shift;end+=shift;}
 else if(kind==='start')start=clamp(start+delta,span.start,end-1);
 else end=clamp(end+delta,start+1,span.end);
 return {start:start-origin,end:end-origin};
}
export function geometry(s,d,footprint){
 need(keys(d,['id','a','b','start','end'])&&typeof d.id==='string'&&d.id.length>0&&d.id.length<=128,'Invalid doorway record');
 const a=edge(s,d.a),b=edge(s,d.b);
 need(a.roomId!==b.roomId&&opposite[a.side]===b.side&&a.line===b.line,'Door requires opposing shared Room boundaries');
 need(Number.isInteger(d.start)&&Number.isInteger(d.end)&&d.start>=0&&d.end>d.start&&d.end<=a.length,'Invalid opening interval');
 const start=a.start+d.start,end=a.start+d.end;
 need(start>=b.start&&end<=b.start+b.length,'Door exceeds shared wall segment');
 // Shared footprint projection is also used by the interactive solver.
 for(const span of wallBlockers(s,[a,b],footprint))
  need(!overlap(start,end,span.start,span.end),'Door obstructed by Shelf footprint');
 return {vertical:a.vertical,line:a.line,start,end,openings:[
  {roomId:a.roomId,side:a.side,start:start-a.start,end:end-a.start},
  {roomId:b.roomId,side:b.side,start:start-b.start,end:end-b.start}]};
}
export function validate(s,footprint,structuralIds){
 const doors=s.spatial.doors;
 if(doors===undefined)return;
 need(plain(doors)&&Object.keys(doors).length<=doorLimit,'Door budget or metadata');
 const placed=[];
 for(const k of Object.keys(doors)){
  const d=doors[k];need(plain(d)&&k===d.id&&!['__proto__','constructor','prototype'].includes(k)&&!structuralIds.has(k),'Duplicate or invalid door identity');structuralIds.add(k);
  const g=geometry(s,d,footprint);
  need(!placed.some(q=>q.vertical===g.vertical&&q.line===g.line&&overlap(q.start,q.end,g.start,g.end)),'Door openings overlap');
  placed.push(g);
 }
}
export function invalidated(s,footprint){
 const lost=[];
 for(const d of Object.values(s.spatial.doors||{})){try{geometry(s,d,footprint)}catch(e){lost.push(d.id);}}
 return lost.sort();
}
// Capture authoritative world intervals before a Room edit. Keep openings
// at their old world position if possible, otherwise find the nearest clear
// interval of the same width. Only explicitly approved losses may disappear.
export function captureRoomDoors(s,roomId,footprint){
 return Object.values(s.spatial.doors||{}).filter(d=>d.a.roomId===roomId||d.b.roomId===roomId).map(d=>({door:d,geometry:geometry(s,d,footprint)}));
}
export function reconcileRoomDoors(s,captured,footprint){
 if(!captured.length)return [];
 const original=s.spatial.doors,affected=new Set(captured.map(v=>v.door.id)),working={};
 for(const id of Object.keys(original))if(!affected.has(id))working[id]=original[id];
 const work=Object.assign({},s,{spatial:Object.assign({},s.spatial,{doors:working})}),lost=[],pending=[];
 // Reserve every still-valid old world interval before relocating any
 // obstructed interval. A relocation must not displace a valid neighbor.
 for(const entry of captured){
  const d=entry.door,g=entry.geometry;
  try{
   const a=edge(work,d.a),next=Object.assign({},d,{start:g.start-a.start,end:g.end-a.start});
   geometry(work,next,footprint);
   need(clearSpans(work,d.a,d.b,footprint).some(q=>q.start<=g.start&&g.end<=q.end),'Old interval unavailable');
   working[d.id]=next;
  }catch(e){pending.push(entry);}
 }
 for(const entry of pending.sort((a,b)=>a.geometry.start-b.geometry.start||a.door.id.localeCompare(b.door.id))){
  const d=entry.door,g=entry.geometry,w=g.end-g.start;
  try{
   const a=edge(work,d.a),spans=clearSpans(work,d.a,d.b,footprint);
   const candidates=spans.filter(q=>q.end-q.start>=w).map(q=>Math.max(q.start,Math.min(q.end-w,g.start))).sort((a,b)=>Math.abs(a-g.start)-Math.abs(b-g.start)||a-b);
   if(!candidates.length){lost.push(d.id);continue;}
   const start=candidates[0]-a.start,next=Object.assign({},d,{start,end:start+w});
   geometry(work,next,footprint);working[d.id]=next;
  }catch(e){lost.push(d.id);}
 }
 // Preserve key order and unaffected records, including exact no-op edits.
 const next={};for(const id of Object.keys(original))if(own(working,id))next[id]=working[id];
 s.spatial.doors=next;return lost.sort();
}
export function resolveRoomChange(s,captured,ids,footprint){
 const lost=reconcileRoomDoors(s,captured,footprint);
 need(lost.length?Array.isArray(ids)&&JSON.stringify(ids.slice().sort())===JSON.stringify(lost):ids===undefined||Array.isArray(ids)&&!ids.length,lost.length?'Resolve separated or obstructed doors explicitly: '+lost.join(', '):'No openings require removal');
}
export function resolveLost(s,ids,footprint){
 const lost=invalidated(s,footprint);
 if(!lost.length){need(ids===undefined||Array.isArray(ids)&&!ids.length,'No openings require removal');return;}
 need(Array.isArray(ids)&&JSON.stringify(ids.slice().sort())===JSON.stringify(lost),'Resolve separated or obstructed doors explicitly: '+lost.join(', '));
 for(const k of lost)delete s.spatial.doors[k];
}
export function edit(s,cmd,p,allocate,footprint){
 const doors=s.spatial.doors||(s.spatial.doors={});
 if(cmd.kind==='spatialDoorCreate'){
  need(keys(p,['a','b','start','end']),'Invalid door properties');
  const k=allocate('door-');doors[k]=Object.assign({id:k},p);
 }else if(cmd.kind==='spatialDoorEdit'){
  need(own(doors,cmd.doorId)&&keys(p,['start','end']),'Unknown door or property');
  const d=doors[cmd.doorId],span=doorEditSpan(s,d,footprint),candidate=Object.assign({},d,p),origin=edge(s,d.a).start;
  // Exact entry and any future caller share the same no-teleport rule.
  need(span&&Number.isInteger(candidate.start)&&Number.isInteger(candidate.end)&&
   candidate.start+origin>=span.start&&candidate.end+origin<=span.end,'Door edit leaves its contiguous clear span');
  Object.assign(d,p);
 }else if(cmd.kind==='spatialDoorDelete'){
  need(own(doors,cmd.doorId)&&keys(p,[]),'Unknown door or property');delete doors[cmd.doorId];
 }else if(cmd.kind==='spatialDoorMerge'){
  need(own(doors,cmd.doorId)&&keys(p,['otherId','start','end'])&&typeof p.otherId==='string'&&own(doors,p.otherId)&&p.otherId!==cmd.doorId,'Choose two distinct doors');
  const a=doors[cmd.doorId],b=doors[p.otherId];
  need(samePair(a,b),'Only doors on the same pair of edges may merge');
  // A contact gesture can include its bounded move/resize in this same
  // transaction. It cannot jump a blocker or overlap the second opening.
  if(own(p,'start')||own(p,'end')){
   const span=doorEditSpan(s,a,footprint),origin=edge(s,a.a).start,start=own(p,'start')?p.start:a.start,end=own(p,'end')?p.end:a.end;
   need(span&&Number.isInteger(start)&&Number.isInteger(end)&&end>start&&start+origin>=span.start&&end+origin<=span.end,'Merge gesture leaves its contiguous clear span');
   a.start=start;a.end=end;
  }
  const ga=geometry(s,a,footprint),gb=geometry(s,b,footprint);
  need(ga.start<=gb.end&&gb.start<=ga.end,'Doors must touch or overlap');
  const origin=edge(s,a.a).start;
  a.start=Math.min(ga.start,gb.start)-origin;a.end=Math.max(ga.end,gb.end)-origin;delete doors[b.id];
 }else throw Error('Unknown doorway operation');
}
