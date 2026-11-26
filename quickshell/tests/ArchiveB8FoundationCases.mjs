// Shared executable contract: run unchanged in Node and Qt Quick.
import * as Core from "../archive/ArchiveCore.mjs";
import * as Spatial from "../archive/ArchiveSpatial.mjs";
import * as Checkpoint from "../archive/ArchiveCheckpoint.mjs";
import * as MixedFixture from "./ArchiveB7MixedFixture.mjs";
export function run(){
 let checks=0;
 function eq(a,b,label){checks++;if(JSON.stringify(a)!==JSON.stringify(b))throw Error(label+': '+JSON.stringify(a)+' != '+JSON.stringify(b));}
 function yes(v,label){eq(Boolean(v),true,label);}
 function apply(s,cmd){
  const before=JSON.stringify(s.snapshot),p=Core.previewStructure(s,cmd);
  yes(p.ok,p.error||cmd.kind);eq(JSON.stringify(s.snapshot),before,'preview isolated');
  const n=Core.applyStructure(s,p);eq(n.error,'','apply '+cmd.kind);eq(n.history.length,Math.min(30,s.history.length+1),'one undo entry');return n;
 }
 function refuse(s,cmd){
  const before=JSON.stringify(s.snapshot),p=Core.previewStructure(s,cmd);
  eq(p.ok,false,'invalid '+cmd.kind);yes(p.error,'reason');eq(JSON.stringify(s.snapshot),before,'no mutation');
 }
 function invalid(s,label){yes(Core.validate(s),label);}
 const legacy=Core.session(Core.fixture()),view={path:['root'],theme:1,cameras:{root:{zoom:1.2,x:5,y:-7}}};
 const encoded=Checkpoint.encode(legacy,view);eq(JSON.parse(encoded).version,2,'legacy writer');
 const v1=JSON.parse(encoded);v1.version=1;
 eq(Checkpoint.decode(JSON.stringify(v1)).snapshot,legacy.snapshot,'v1 decode unchanged');
 eq(Checkpoint.decode(encoded).snapshot,legacy.snapshot,'v2 decode unchanged');
 let s=apply(legacy,{kind:'spatialPromote'});
 const r=Object.keys(s.snapshot.spatial.rooms)[0],initial=Core.clone(s.snapshot);
 eq(Core.owners(s.snapshot),Core.owners(legacy.snapshot),'all legacy owners preserved');
 eq(s.snapshot.cubbies,legacy.snapshot.cubbies,'no hidden container or geometry change');
 eq(Spatial.kind(s.snapshot,'root'),'shelf','explicit architectural root');
 eq(Spatial.footprint(s.snapshot,'root').w,722,'width includes frame');
 eq(Core.undo(s).snapshot,legacy.snapshot,'promotion undo');
 const before=Core.clone(s.snapshot);
 s=apply(s,{kind:'spatialShelfEdit',containerId:'root',patch:{h:520}});
 eq(Spatial.footprint(s.snapshot,'root'),Spatial.footprint(before,'root'),'height independent');
 eq(Core.owners(s.snapshot),Core.owners(before),'growth retains positions');
 s=apply(s,{kind:'spatialShelfEdit',containerId:'root',patch:{depth:170}});
 eq(s.snapshot.cubbies.root.h,520,'depth independent');
 refuse(s,{kind:'spatialShelfEdit',containerId:'root',patch:{w:200}});
 refuse(s,{kind:'spatialShelfEdit',containerId:'root',patch:{orientation:90}});
 refuse(s,{kind:'spatialRoomEdit',roomId:r,patch:{w:200}});
 s=apply(s,{kind:'spatialRoomCreate',patch:{name:'Observatory',x:2000,y:0,w:1400,h:1000}});
 const room=Object.keys(s.snapshot.spatial.rooms).find(k=>k!==r);
 refuse(s,{kind:'spatialRoomEdit',roomId:room,patch:{x:0}});
 s=apply(s,{kind:'spatialShelfCreate',roomId:room,patch:{x:20,y:20,w:650,h:500,depth:180,orientation:90}});
 const shelf=Object.keys(s.snapshot.spatial.shelves).find(k=>k!=='root');
 eq(Spatial.footprint(s.snapshot,shelf),{x:20,y:20,w:180,h:672},'rotated footprint');
 refuse(s,{kind:'spatialShelfCreate',roomId:room,patch:{x:20,y:20}});
 s=apply(s,{kind:'create',type:'shelf',cubbyId:shelf,patch:{x:0,y:400,w:600,h:15}});
 s=apply(s,{kind:'create',type:'rack',cubbyId:shelf,patch:{x:0,y:0,w:320,h:260,r:64}});
 s=apply(s,{kind:'create',type:'cubby',cubbyId:shelf,patch:{x:350,y:0,w:200,h:180}});
 const child=s.snapshot.cubbies[shelf].mods.find(m=>m.type==='cubby').childId;
 eq(Spatial.kind(s.snapshot,child),'cubby','real nested cubby');
 s=apply(s,{kind:'spatialAppearance',containerId:shelf,patch:{family:'Observatory',palette:2}});
 eq(Spatial.resolveAppearance(s.snapshot,child,0),{family:'Observatory',palette:0},'family inherited; palette local');
 s=apply(s,{kind:'spatialAppearance',containerId:child,patch:{family:'None',palette:1}});
 eq(Spatial.resolveAppearance(s.snapshot,child,0),{family:'None',palette:1},'explicit None');
 const rack=s.snapshot.cubbies[shelf].mods.find(m=>m.type==='rack'),cell=Core.geometry(rack).cells.find(c=>c.area>5000);
 yes(cell,'cell exists');
 const direct=Core.transfer(s,['test-a'],{cubbyId:shelf,rackId:rack.id,key:cell.key,local:{x:cell.cx,y:cell.cy}});
 yes(direct.error,'cross-container requires Case');eq(direct.snapshot,s.snapshot,'direct move rejected');
 let carried=Core.transfer(s,['test-a'],'case');eq(carried.error,'','Case cut');
 let placed=Core.transfer(carried,['test-a'],{cubbyId:shelf,rackId:rack.id,key:cell.key,local:{x:cell.cx,y:cell.cy}});
 eq(placed.error,'','Case insertion into direct Shelf rack');
 eq(Core.owners(placed.snapshot).find(e=>e.id==='test-a').cubbyId,shelf,'no intermediary Cubby');
 // A populated descendant and a pre-existing Case entry must survive
 // whole architectural Shelf deletion without extra published transactions.
 placed=apply(placed,{kind:'create',type:'rack',cubbyId:child,patch:{x:0,y:0,w:320,h:260,r:64}});
 const childRack=placed.snapshot.cubbies[child].mods[0],childCell=Core.geometry(childRack).cells.find(c=>c.area>5000);
 carried=Core.transfer(placed,['test-b'],'case');eq(carried.error,'','second Case cut');
 placed=Core.transfer(carried,['test-b'],{cubbyId:child,rackId:childRack.id,key:childCell.key,local:{x:childCell.cx,y:childCell.cy}});
 eq(placed.error,'','nested Case insertion');
 placed=Core.transfer(placed,['test-c'],'case');eq(placed.error,'','pre-existing Case entry');
 const prior=Core.clone(placed.snapshot.caseItems[0]);
 const bad=Core.clone(placed.snapshot);bad.spatial.shelves[child]={roomId:room,x:900,y:20,depth:100,orientation:0};invalid(bad,'nested shelf rejected');
 const unattached=Core.clone(placed.snapshot);delete unattached.spatial.shelves[shelf];invalid(unattached,'unattached physical container');
 const duplicate=Core.clone(placed.snapshot);duplicate.spatial.rooms[shelf]={id:shelf,name:'Duplicate',x:4000,y:0,w:500,h:500};invalid(duplicate,'duplicate identity');
 const removal=Core.previewStructure(placed,{kind:'spatialShelfDelete',containerId:shelf});
 yes(removal.ok,removal.error);eq(removal.caseTransferCount,2,'recursive evacuation preview');eq(placed.snapshot.caseItems,[prior],'preview no evacuation');
 const removed=Core.applyStructure(placed,removal);eq(removed.error,'','Shelf removed');
 eq(removed.snapshot.caseItems[0],prior,'existing Case entry preserved');
 eq(removed.snapshot.caseItems.slice(1).map(r=>r.id).sort(),['test-a','test-b'],'both files evacuated');
 yes(removed.snapshot.caseItems.slice(1).every(r=>r.originStale),'removed origins stale');
 eq(Spatial.kind(removed.snapshot,child),null,'descendant removed');
 eq(removed.history.length,placed.history.length+1,'atomic removal');eq(Core.undo(removed).snapshot,placed.snapshot,'exact undo');
 const stale=Core.applyStructure(removed,removal);yes(stale.error,'stale proposal');eq(stale.snapshot,removed.snapshot,'stale nonmutating');
 const spatialView={path:[shelf,child],theme:1,cameras:{root:view.cameras.root,[child]:{zoom:1,x:0,y:0}}};
 const saved=Checkpoint.encode(placed,spatialView);eq(JSON.parse(saved).version,3,'spatial envelope');
 eq(Checkpoint.decode(saved),{snapshot:placed.snapshot,view:spatialView},'v3 exact roundtrip');
 const mislabeled=JSON.parse(saved);mislabeled.version=2;
 let rejected=false;try{Checkpoint.decode(JSON.stringify(mislabeled));}catch(e){rejected=true;}yes(rejected,'cannot mislabel spatial snapshot v2');
 const badPath=JSON.parse(saved);badPath.view.path=['root',child];rejected=false;try{Checkpoint.decode(JSON.stringify(badPath));}catch(e){rejected=true;}yes(rejected,'reject disconnected path');
 eq(Core.validate(initial),null,'initial valid');
 const roomMove=apply(placed,{kind:'spatialRoomEdit',roomId:room,patch:{x:3000,y:80}});
 eq(roomMove.snapshot.cubbies,placed.snapshot.cubbies,'Room movement preserves all interior positions');
 eq(roomMove.snapshot.spatial.shelves,placed.snapshot.spatial.shelves,'Room movement preserves Shelf-local placements');
 refuse(placed,{kind:'spatialShelfEdit',containerId:shelf,patch:{name:''}});
 refuse(placed,{kind:'spatialRoomDelete',roomId:room});
 const populated=Core.clone(placed.snapshot);populated.path=[shelf,child];
 const selected=Core.session(populated);
 const removedSelected=apply(selected,{kind:'spatialShelfDelete',containerId:shelf});
 eq(removedSelected.snapshot.path,['root'],'deleted active path repaired');
 eq(Core.undo(removedSelected).snapshot,populated,'active path exact Undo');
 // Existing mixed checkpoint and support-local coordinates survive promotion.
 const mixed=Core.session(MixedFixture.fixture()),mixedView={path:['root'],theme:2,cameras:{root:{zoom:1.3,x:17,y:-9}}};
 const mixedV2=Checkpoint.encode(mixed,mixedView);
 eq(Checkpoint.decode(mixedV2),{snapshot:mixed.snapshot,view:mixedView},'populated v2 unchanged');
 const promoted=apply(mixed,{kind:'spatialPromote'});
 eq(promoted.snapshot.cubbies,mixed.snapshot.cubbies,'mixed physical geometry unchanged');
 eq(Core.owners(promoted.snapshot),Core.owners(mixed.snapshot),'mixed owner/record/provenance unchanged');
 const promotedSaved=Checkpoint.encode(promoted,mixedView);
 eq(Checkpoint.decode(promotedSaved),{snapshot:promoted.snapshot,view:mixedView},'populated v3 unchanged');
 const board=promoted.snapshot.cubbies.root.mods.find(m=>m.id==='mixed-board');
 const moved=apply(promoted,{kind:'shelf',cubbyId:'root',moduleId:board.id,patch:{x:board.x+5}});
 eq(moved.snapshot.cubbies.root.mods.find(m=>m.id===board.id).items,board.items,'support movement carries dependent entries without scaling');
 eq(Core.undo(moved).snapshot,promoted.snapshot,'support movement exact Undo');
 const mislabeledLegacy=JSON.parse(mixedV2);mislabeledLegacy.version=3;
 rejected=false;try{Checkpoint.decode(JSON.stringify(mislabeledLegacy));}catch(e){rejected=true;}yes(rejected,'v3 requires spatial envelope');
 return checks;
}
