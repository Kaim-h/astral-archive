// Native active-cell motion: B6r12b3's fixed-step contract, without a DOM.
// A mutable transaction is private to the controller; committed snapshots
// never change until every affected cell is settled and validated.
import * as C from "./ArchiveCore.mjs";
import * as Mixed from "./representation/B7Ownership.mjs";
export function same(a,b){return !!a&&!!b&&a.cubbyId===b.cubbyId&&a.rackId===b.rackId&&a.key===b.key;}
function key(loc){return [loc.cubbyId,loc.rackId,loc.key].join("|");}
export function select(snapshot,cubbyId,kind,ids,anchor,id,ctrl,shift){
 const order=C.owners(snapshot).filter(e=>e.where===kind&&(kind==="case"||e.cubbyId===cubbyId)).map(e=>e.id);
 if(order.indexOf(id)<0)return {ids:[],anchor:null};
 let selected=ids.filter(v=>order.indexOf(v)>=0),a=anchor&&anchor.kind===kind?anchor.id:null;
 if(ctrl){selected=selected.indexOf(id)>=0?selected.filter(v=>v!==id):selected.concat([id]);a=id;}
 else if(shift){const from=order.indexOf(a),to=order.indexOf(id);selected=Array.from(new Set(selected.concat(from>=0?order.slice(Math.min(from,to),Math.max(from,to)+1):[id])));if(from<0)a=id;}
 else{if(selected.indexOf(id)<0)selected=[id];a=id;}
 return {ids:selected,anchor:{id:a,kind}};
}
export function begin(s,ids,allowMixed=false){
 if(s.draft||!ids.length||ids.length>96||new Set(ids).size!==ids.length)throw Error("Busy or selection exceeds 96-scroll research budget");
 const entries=ids.map(id=>C.owners(s.snapshot).find(e=>e.id===id));
 if(entries.some(e=>!e||!allowMixed&&!["rack","case"].includes(e.where)))throw Error("Select rack or Case scrolls for live cell motion");
 if(entries.some(e=>!["rack","case"].includes(e.where))&&entries.length!==1)throw Error("Move one mixed object at a time");
 return {baseRevision:s.revision,draft:C.clone(s.snapshot),entries:C.clone(entries),cells:new Map(),touched:new Map(),carried:[],released:false,lifted:false,accum:0,error:"",steps:0};
}
function activate(q,loc){
 const rack=C.rackAt(q.draft,loc.cubbyId,loc.rackId),cell=rack&&C.geometry(rack).cells.find(c=>c.key===loc.key);
 if(!cell)throw Error("Cell no longer exists");
 const k=key(loc);
 if(!q.touched.has(k)&&q.touched.size>=24)throw Error("Selection spans more than 24 active cells; move a smaller group");
 const records=rack.scrollCells[loc.key]||(rack.scrollCells[loc.key]=[]);
 const a={loc:{cubbyId:loc.cubbyId,rackId:loc.rackId,key:loc.key},cell,records,bodies:C.bodies(records),edges:C.edges(cell),ticks:0,quiet:0,tether:null,releaseTicks:0};
 q.cells.set(k,a);q.touched.set(k,a.loc);return a;
}
export function tether(q,loc,offsets){
 if(q.lifted||q.released||!q.entries.every(e=>e.where==="rack"&&same(e,loc)))throw Error("Invalid in-cell tether");
 const a=q.cells.get(key(loc))||activate(q,loc),targets=new Map();
 for(const e of q.entries){const off=offsets[e.id]||{x:0,y:0};const pt=C.projectIntoCell(C.wall(a.cell),{x:loc.local.x+off.x,y:loc.local.y+off.y},e.scroll.r);if(pt)targets.set(e.id,pt);}
 a.tether=targets;a.quiet=0;
}
export function lift(q){
 if(q.lifted)return;
 for(const e of q.entries){
  const item=C.clone(e.scroll);
  if(e.where==="case")q.draft.caseItems=q.draft.caseItems.filter(s=>s.id!==e.id);
  else if(e.where==="rack"){
   const rack=C.rackAt(q.draft,e.cubbyId,e.rackId);
   rack.scrollCells[e.key]=rack.scrollCells[e.key].filter(s=>s.id!==e.id);
   // The latest origin is now a rack cell, not an earlier shelf slot.
   delete item.originModuleId;delete item.originHolderId;delete item.originSlot;delete item.originPlacement;
   Object.assign(item,{originCubbyId:e.cubbyId,originRackId:e.rackId,originKey:e.key,originCellId:rack.cellMeta[e.key].id,originStale:false});
   activate(q,e);
  }else Mixed.detach(q.draft,e,item,false);
  q.carried.push(item);
 }
 q.lifted=true;
}
export function insert(q,destination,offsets){
 if(!q.lifted||!q.carried.length)throw Error("No lifted scrolls");
 if(destination==="case"){for(const item of q.carried)q.draft.caseItems.push(Object.assign({},item,{moveMode:"cut"}));q.carried=[];return;}
 if(q.entries.some(e=>e.where!=="case"&&e.cubbyId!==destination.cubbyId))throw Error("Use the Scroll Case between cubbies");
 if(["shelf","holder","artwork"].includes(destination.kind)){
  if(q.carried.length!==1)throw Error("Choose one object for this placement");
  Mixed.place(q.draft,q.carried[0],destination);
  // Do not validate the entire snapshot yet: a source rack may be settling.
  // Validate destination geometry immediately and the full state at commit.
  const c=q.draft.cubbies[destination.cubbyId],m=c.mods.find(v=>v.id===destination.moduleId);
  const boxes=Mixed.fixtureRects(m);
  if(boxes.some(b=>b.x<-.001||b.y<-.001||b.x+b.w>c.w+.001||b.y+b.h>c.h+.001)||
     c.mods.some(v=>v.id!==m.id&&Mixed.fixtureRects(v).some(b=>boxes.some(a=>Mixed.overlap(a,b)))))
   throw Error("Destination overlaps furniture or exceeds cubby");
  q.carried=[];return;
 }
 const rack=C.rackAt(q.draft,destination.cubbyId,destination.rackId),cell=rack&&C.geometry(rack).cells.find(c=>c.key===destination.key);
 if(!cell||!destination.local)throw Error("Choose a valid destination");
 const list=rack.scrollCells[cell.key]||[],items=q.carried;
 if(list.length+items.length>96)throw Error("Cell contact budget exceeded");
 const offsetMap=new Map(Object.entries(offsets||{}));
 const pts=items.length===1?(C.interiorDistance(destination.local,C.wall(cell))>=items[0].r-.08?
 [{item:items[0],x:destination.local.x,y:destination.local.y}]:null):C.groupPoints(cell,list,items,destination,offsetMap);
 if(!pts)throw Error("Group cannot fit near drop point; nothing moved");
 rack.scrollCells[cell.key]=list.concat(pts.map(p=>Object.assign({},p.item,{x:p.x,y:p.y,cellKey:cell.key})));
 const a=activate(q,destination);
 if(destination.top)a.bodies[a.bodies.length-1].vy=10*cell.r/282;
 q.carried=[];
}
export function release(q,follow){
 q.released=true;
 for(const a of q.cells.values()){if(follow&&a.tether)a.releaseTicks=30;else a.tether=null;a.ticks=0;a.quiet=0;}
}
export function advance(q,elapsed){
 if(q.error||!q.cells.size)return;
 q.accum+=Math.min(.05,Math.max(0,elapsed));let steps=0;
 while(q.accum>=C.FIXED_STEP&&steps<6){
  q.accum-=C.FIXED_STEP;steps++;q.steps++;
  for(const [k,a] of q.cells){
   const movement=C.step(a.cell,a.bodies,a.edges,a.tether);a.ticks++;
   if(a.releaseTicks>0&&--a.releaseTicks===0)a.tether=null;
   a.quiet=!a.tether&&movement<.035?a.quiet+1:0;
   if(!a.tether&&a.ticks>=48&&a.quiet>=36&&C.contained(a.cell,a.records)&&C.supported(a.cell,a.records)){q.cells.delete(k);continue;}
   if(!a.tether&&a.ticks>960){q.error="Settling budget exhausted; original arrangement restored";return;}
  }
 }
 if(!q.cells.size)q.accum=0;
}
export function positions(q){
 const out={};if(!q)return out;
 for(const loc of q.touched.values()){
  const rack=C.rackAt(q.draft,loc.cubbyId,loc.rackId);
  for(const s of rack.scrollCells[loc.key]||[])out[s.id]={x:s.x,y:s.y};
 }
 return out;
}
export function members(q){
 const out={};if(!q)return out;
 const racks=new Map();for(const loc of q.touched.values())racks.set(loc.rackId,C.rackAt(q.draft,loc.cubbyId,loc.rackId));
 for(const [id,rack] of racks){const list=[];for(const cell of C.geometry(rack).cells)for(const s of rack.scrollCells[cell.key]||[])list.push(s);out[id]=C.clone(list);}
 return out;
}
