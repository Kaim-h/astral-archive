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
 need(keys(ref,['roomId','side'])&&own(s.spatial.rooms,ref.roomId)&&sides.includes(ref.side),'Unknown Room boundary');
 const r=s.spatial.rooms[ref.roomId],vertical=ref.side==='east'||ref.side==='west';
 return {roomId:ref.roomId,side:ref.side,vertical,
  line:vertical?r.x+(ref.side==='east'?r.w:0):r.y+(ref.side==='south'?r.h:0),
  start:vertical?r.y:r.x,length:vertical?r.h:r.w};
}
function sameEdge(a,b){return a.roomId===b.roomId&&a.side===b.side;}
function samePair(a,b){return sameEdge(a.a,b.a)&&sameEdge(a.b,b.b)||sameEdge(a.a,b.b)&&sameEdge(a.b,b.a);}
function overlap(a,b,c,d){return a<d&&c<b;}
export function geometry(s,d,footprint){
 need(keys(d,['id','a','b','start','end'])&&typeof d.id==='string'&&d.id.length>0&&d.id.length<=128,'Invalid doorway record');
 const a=edge(s,d.a),b=edge(s,d.b);
 need(a.roomId!==b.roomId&&opposite[a.side]===b.side&&a.line===b.line,'Door requires opposing shared Room boundaries');
 need(Number.isInteger(d.start)&&Number.isInteger(d.end)&&d.start>=0&&d.end>d.start&&d.end<=a.length,'Invalid opening interval');
 const start=a.start+d.start,end=a.start+d.end;
 need(start>=b.start&&end<=b.start+b.length,'Door exceeds shared wall segment');
 // Provisional conservative rectangular clearance: a footprint touching the
 // wall blocks its projected interval. No simulated wall thickness yet.
 for(const side of [a,b]){
  const r=s.spatial.rooms[side.roomId];
  for(const k of Object.keys(s.spatial.shelves)){
   if(s.spatial.shelves[k].roomId!==side.roomId)continue;
   const p=footprint(s,k);
   const touches=side.side==='north'?p.y===0:side.side==='south'?p.y+p.h===r.h:side.side==='west'?p.x===0:p.x+p.w===r.w;
   const lo=side.start+(side.vertical?p.y:p.x),hi=lo+(side.vertical?p.h:p.w);
   need(!touches||!overlap(start,end,lo,hi),'Door obstructed by Shelf footprint');
  }
 }
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
  const d=doors[k];need(k===d.id&&!['__proto__','constructor','prototype'].includes(k)&&!structuralIds.has(k),'Duplicate or invalid door identity');structuralIds.add(k);
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
  Object.assign(doors[cmd.doorId],p);
 }else if(cmd.kind==='spatialDoorDelete'){
  need(own(doors,cmd.doorId)&&keys(p,[]),'Unknown door or property');delete doors[cmd.doorId];
 }else if(cmd.kind==='spatialDoorMerge'){
  need(own(doors,cmd.doorId)&&keys(p,['otherId'])&&own(doors,p.otherId)&&p.otherId!==cmd.doorId,'Choose two distinct doors');
  const a=doors[cmd.doorId],b=doors[p.otherId];
  need(samePair(a,b),'Only doors on the same pair of edges may merge');
  const ga=geometry(s,a,footprint),gb=geometry(s,b,footprint);
  need(ga.start<=gb.end&&gb.start<=ga.end,'Doors must touch or overlap');
  const origin=edge(s,a.a).start;
  a.start=Math.min(ga.start,gb.start)-origin;a.end=Math.max(ga.end,gb.end)-origin;delete doors[b.id];
 }else throw Error('Unknown doorway operation');
}
