// N6 integrated synthetic checks, unchanged Node and Qt Quick logic.
import * as Core from "../archive/ArchiveCore.mjs";
import * as Spatial from "../archive/ArchiveSpatial.mjs";
import * as CP from "../archive/ArchiveCheckpoint.mjs";
import * as View from "../archive/ArchiveView.mjs";
import * as Projection from "../archive/ArchiveRoomProjection.mjs";
import * as Appearance from "../archive/ArchiveAppearance.mjs";
import * as Sample from "./ArchiveB8ShelfFixture.mjs";

function edit(s,command){
 const n=Core.editStructure(s,command);if(n.error)throw Error(command.kind+": "+n.error);return n;
}
function decorate(s,begin,values){
 let p=begin(s);
 for(const [key,value] of values)p=Core.updateAppearance(s,p,key,value);
 if(!p||!p.ok)throw Error(p?p.error:"Missing appearance session");
 const n=Core.finishAppearance(s,p);if(n.error)throw Error(n.error);return n;
}
export function restartFixture(){
 let s=Core.session(Sample.mapFixture());
 const hall=s.snapshot.spatial.shelves.root.roomId;
 s=decorate(s,q=>Core.beginAppearance(q,"root"),[["family","Astral"],["emblem","armillary"],["glazingDefault","moderate"]]);
 s=decorate(s,q=>Core.beginAppearance(q,"child"),[["glazing","clearer"]]);
 s=decorate(s,q=>Core.beginRoomAppearance(q,hall),[["floor","bond"],["wall","masonry"],["wallMarks",true],["floorBorder",true]]);
 s=decorate(s,q=>Core.beginMapRoomAppearance(q,hall),[["subtitle","Integrated study"],["frame","inset"]]);
 return s.snapshot;
}
// Dense single Room with furnished roots, and all original atlas Rooms.
// Fixture setup only; normal model validation is mandatory. No runtime
// placement bypass or measurement of synthetic construction as user latency.
export function denseFixture(copies){
 const s=Core.clone(Sample.populatedFixture(copies));
 const id="n6-dense-room";
 s.spatial.rooms[id]={id,name:"Dense synthetic hall",x:-10000,y:0,w:10000,h:4000};
 const roots=Object.keys(s.spatial.shelves).filter(k=>k==="root"||/^sample-\d+-root$/.test(k));
 if(roots.length!==copies)throw Error("Unexpected dense population");
 roots.forEach((k,i)=>Object.assign(s.spatial.shelves[k],{roomId:id,x:50+(i%6)*1600,y:50+Math.floor(i/6)*800,orientation:0}));
 return {snapshot:edit(Core.session(s),{kind:"spatialAdoptIndependentProfiles"}).snapshot,roomId:id};
}
export function run(){
 let count=0;
 function eq(a,b,label){count++;if(JSON.stringify(a)!==JSON.stringify(b))throw Error("N6 "+label);}
 function yes(v,label){eq(!!v,true,label);}
 function rejects(fn,label){let rejected=false;try{fn()}catch(e){rejected=true}yes(rejected,label);}
 const basic={path:["root","child"],theme:2,cameras:{root:{zoom:1.2,x:7,y:-9},child:{zoom:.85,x:13,y:17}},roomPerspective:true};
 // Conditional v6 independent of v3/v4/v5 geometry. Each legacy writer
 // survives unmodified; a single extended field selects v6; Undo restores
 // the exact older envelope, even when extension value is explicit null.
 for(const version of [3,4,5]){
  const legacy=Core.session(version===3?Sample.fixture():version===4?Sample.roomFixture():Sample.mapFixture());
  const base=CP.encode(legacy,basic),decoded=CP.decode(base);
  eq(JSON.parse(base).version,version,"legacy writer "+version);
  eq(CP.encode(Core.session(decoded.snapshot),decoded.view),base,"legacy exact re-encode "+version);
  for(const value of ["metal",null]){
   const changed=value===null?edit(legacy,{kind:"spatialAppearance",containerId:"root",patch:{frame:null}}):decorate(legacy,q=>Core.beginAppearance(q,"root"),[["frame",value]]);
   const saved=CP.encode(changed,basic),envelope=JSON.parse(saved);
   eq(envelope.version,6,"conditional v6 "+version);
   eq(changed.snapshot.spatial.geometryPolicy,legacy.snapshot.spatial.geometryPolicy,"geometry policy independent "+version);
   eq(CP.decode(saved).snapshot,changed.snapshot,"v6 snapshot "+version);
   eq(CP.encode(Core.undo(changed),basic),base,"exact legacy writer Undo "+version);
   for(const wrong of [3,4,5]){
    const bad=Core.clone(envelope);bad.version=wrong;
    rejects(()=>CP.decode(JSON.stringify(bad)),"mislabel v6 as "+wrong);
   }
  }
 }
 // One chronological transaction chain across mixed ownership, two Rooms,
 // nested Cubby, shared openings, appearance, atlas and saved view.
 let s=Core.session(Sample.mapFixture()),original=Core.clone(s.snapshot);
 const prior=[],ids=Core.owners(original).map(o=>o.id).sort(),apps=Spatial.appPlacements(original);
 const hall=original.spatial.shelves.root.roomId;
 const south=Object.values(original.spatial.rooms).find(r=>r.name==="South Reading Room").id;
 const target=Object.keys(original.spatial.shelves).find(k=>original.spatial.shelves[k].roomId===south);
 const door=Object.values(original.spatial.doors).find(d=>d.a.roomId===hall&&d.b.roomId===south);
 function publish(next,label){
  eq(next.error,"",label);eq(next.history.length,s.history.length+1,label+" single history");
  eq(next.revision,s.revision+1,label+" revision");
  prior.push(s.snapshot);s=next;
  eq(Core.validate(s.snapshot),null,label+" valid");
  eq(Core.owners(s.snapshot).map(o=>o.id).sort(),ids,label+" file IDs conserved");
  eq(Spatial.appPlacements(s.snapshot),apps,label+" app placements conserved");
 }
 function refused(next,label){yes(next.error,label);eq(next.snapshot,s.snapshot,label+" snapshot");eq(next.history,s.history,label+" history");eq(next.revision,s.revision,label+" revision");}
 publish(edit(s,{kind:"create",type:"rack",cubbyId:target,patch:{x:20,y:20,w:320,h:260,r:64}}),"destination rack");
 publish(edit(s,{kind:"create",type:"shelf",cubbyId:target,patch:{x:20,y:400,w:650,h:15}}),"destination board");
 const rack=s.snapshot.cubbies[target].mods.find(m=>m.type==="rack"),board=s.snapshot.cubbies[target].mods.find(m=>m.type==="shelf");
 const cell=Core.geometry(rack).cells.find(c=>c.area>5000);
 yes(cell,"destination cell");
 const dest={cubbyId:target,rackId:rack.id,key:cell.key,local:{x:cell.cx,y:cell.cy}};
 refused(Core.transfer(s,["child-note"],dest),"direct cross-Room transfer refused");
 publish(Core.transfer(s,["child-note"],"case"),"nested note to Case");
 eq(Core.owners(s.snapshot).find(e=>e.id==="child-note").where,"case","note carried");
 publish(Core.transfer(s,["child-note"],dest),"Case to other Room");
 eq(Core.owners(s.snapshot).find(e=>e.id==="child-note").cubbyId,target,"note destination");
 publish(Core.transfer(s,["mixed-parcel"],"case"),"mixed parcel to Case");
 publish(Core.transfer(s,["mixed-parcel"],{kind:"shelf",cubbyId:target,moduleId:board.id,x:100,scale:.86,support:"tray"}),"parcel to other Room board");
 eq(Core.owners(s.snapshot).find(e=>e.id==="mixed-parcel").where,"shelf","parcel representation");
 const stale=Core.previewStructure(s,{kind:"spatialRoomEdit",roomId:hall,patch:{wallHeight:1000}});
 publish(edit(s,{kind:"spatialDoorEdit",doorId:door.id,patch:{start:120}}),"shared opening change");
 refused(Core.applyStructure(s,stale),"stale cross-layer proposal refused");
 publish(edit(s,{kind:"spatialRoomEdit",roomId:hall,patch:{wallHeight:1000}}),"independent Room height");
 publish(decorate(s,q=>Core.beginAppearance(q,"child"),[["glazing","combined"]]),"local child appearance");
 publish(decorate(s,q=>Core.beginRoomAppearance(q,hall),[["floor","bond"],["wall","masonry"]]),"Room surfaces");
 publish(decorate(s,q=>Core.beginMapRoomAppearance(q,hall),[["subtitle","Integrated review"],["frame","inset"]]),"atlas inscription");
 const atlas=View.mapPlan(s.snapshot),a=View.roomPlan(s.snapshot,hall),b=View.roomPlan(s.snapshot,south);
 const openingA=a.openings.find(o=>o.id===door.id),openingB=b.openings.find(o=>o.id===door.id);
 eq(openingA.start,120,"hall opening");eq(openingB.start,120,"south opening");
 eq(openingA.end,openingB.end,"shared end");yes(atlas.doors.some(d=>d.id===door.id),"atlas opening");
 eq(Appearance.mapRoomPolicy(s.snapshot,hall).subtitle,"Integrated review","atlas appearance");
 const focus={kind:"door",id:door.id,base:{zoom:1,center:null}};
 const view=Object.assign({},basic,{mapView:{layer:"map",roomId:hall,roomShelf:"",camera:{zoom:1.5,center:{x:500,y:1000}},selectedRoom:hall,selectedDoor:door.id,focus}});
 const saved=CP.encode(s,view),loaded=CP.decode(saved);
 eq(loaded.snapshot,s.snapshot,"integrated v6 snapshot");eq(loaded.view,view,"integrated view exact");
 eq(CP.encode(Core.session(loaded.snapshot),loaded.view),saved,"restart re-encode");
 // Explicit named mutations and serialization checks distinguish malformed
 // input construction from an actual decoder acceptance across JS engines.
 // Do not share a mutated envelope between cases.
 function corruptRefused(bad,label,expected){
  const payload=JSON.stringify(bad);
  yes(payload!==saved,label+" payload changed");
  let reason="";
  try{CP.decode(payload);}catch(e){reason=String(e.message||e);}
  yes(reason.length>0,label+" decoder unexpectedly accepted");
  yes(reason.indexOf(expected)!==-1,label+" wrong refusal: "+reason);
 }
 {
  const bad=JSON.parse(saved);
  bad.view.path=["root",target];
  eq(bad.view.path[1],target,"corrupt path target");
  corruptRefused(bad,"cross-Shelf navigation path","Invalid view metadata");
 }
 {
  const wrongRoom=Object.keys(original.spatial.rooms).find(k=>k!==hall&&k!==south);
  yes(wrongRoom&&wrongRoom!==door.a.roomId&&wrongRoom!==door.b.roomId,"unrelated Room specimen");
  const bad=JSON.parse(saved);
  bad.view.mapView.selectedRoom=wrongRoom;
  eq(bad.view.mapView.selectedRoom,wrongRoom,"corrupt selected Room");
  corruptRefused(bad,"unrelated selected opening Room","Invalid selected opening Room");
 }
 {
  const bad=JSON.parse(saved);
  bad.view.mapView.focus.id="missing";
  corruptRefused(bad,"missing focus identity","Invalid Map focus");
 }
 {
  const bad=JSON.parse(saved);
  bad.view.cameras.child.zoom=99;
  corruptRefused(bad,"out-of-range Cubby camera","Invalid camera");
 }
 {
  const bad=JSON.parse(saved);
  const duplicate=Core.owners(bad.snapshot).find(o=>o.id==="child-note");
  yes(duplicate&&duplicate.where==="rack","duplicate record specimen");
  const size=bad.snapshot.caseItems.length;
  bad.snapshot.caseItems.push(Core.clone(duplicate.scroll));
  eq(bad.snapshot.caseItems.length,size+1,"duplicate appended");
  eq(bad.snapshot.caseItems[size].id,"child-note","duplicate identity");
  corruptRefused(bad,"duplicate file in Case","Invalid or duplicate Case record");
 }
 {
  const bad=JSON.parse(saved);
  bad.snapshot.spatial.rooms[hall].appearance.wall="invalid";
  corruptRefused(bad,"unknown Room wall treatment","Invalid Room surface policy");
 }
 for(let i=prior.length-1;i>=0;i--){s=Core.undo(s);eq(s.error,"","Undo "+i);eq(s.snapshot,prior[i],"exact chronological Undo "+i);}
 eq(s.snapshot,original,"original restored");eq(s.history.length,0,"no history remains");
 // Dense projection invariants; actual performance timing lives in Node.
 const dense=denseFixture(8),data=View.roomPlan(dense.snapshot,dense.roomId);
 eq(data.shelves.length,8,"dense Room population");
 for(const [w,h] of [[740,560],[1366,900]]){
  const projected=View.roomPerspective(dense.snapshot,data,w,h),r=Projection.visibility(projected,w,h);
  yes(r&&r.w*r.h<=1200000,"raster budget");
  let n=0;Projection.visibilityRuns(r,(x,y,width,key)=>{n+=width;});
  yes(n>0&&n<=r.w*r.h,"bounded visible pixels");
 }
 return count;
}
