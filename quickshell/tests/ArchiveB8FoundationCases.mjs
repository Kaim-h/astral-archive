// Shared executable contract: run unchanged in Node and Qt Quick.
import * as Core from "../archive/ArchiveCore.mjs";
import * as Spatial from "../archive/ArchiveSpatial.mjs";
import * as Checkpoint from "../archive/ArchiveCheckpoint.mjs";
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
 const bad=Core.clone(placed.snapshot);bad.spatial.shelves[child]={roomId:room,x:900,y:20,depth:100,orientation:0};invalid(bad,'nested shelf rejected');
 const unattached=Core.clone(placed.snapshot);delete unattached.spatial.shelves[shelf];invalid(unattached,'unattached physical container');
 const duplicate=Core.clone(placed.snapshot);duplicate.spatial.rooms[shelf]={id:shelf,name:'Duplicate',x:4000,y:0,w:500,h:500};invalid(duplicate,'duplicate identity');
 const removal=Core.previewStructure(placed,{kind:'spatialShelfDelete',containerId:shelf});
 yes(removal.ok,removal.error);eq(removal.caseTransferCount,1,'recursive evacuation preview');eq(placed.snapshot.caseItems.length,0,'preview no evacuation');
 const removed=Core.applyStructure(placed,removal);eq(removed.error,'','Shelf removed');
 eq(removed.snapshot.caseItems[0].id,'test-a','file evacuated');eq(removed.snapshot.caseItems[0].originStale,true,'stale origin');
 eq(removed.history.length,placed.history.length+1,'atomic removal');eq(Core.undo(removed).snapshot,placed.snapshot,'exact undo');
 const stale=Core.applyStructure(removed,removal);yes(stale.error,'stale proposal');eq(stale.snapshot,removed.snapshot,'stale nonmutating');
 const spatialView={path:[shelf,child],theme:1,cameras:{root:view.cameras.root,[child]:{zoom:1,x:0,y:0}}};
 const saved=Checkpoint.encode(placed,spatialView);eq(JSON.parse(saved).version,3,'spatial envelope');
 eq(Checkpoint.decode(saved),{snapshot:placed.snapshot,view:spatialView},'v3 exact roundtrip');
 const mislabeled=JSON.parse(saved);mislabeled.version=2;
 let rejected=false;try{Checkpoint.decode(JSON.stringify(mislabeled));}catch(e){rejected=true;}yes(rejected,'cannot mislabel spatial snapshot v2');
 const badPath=JSON.parse(saved);badPath.view.path=['root',child];rejected=false;try{Checkpoint.decode(JSON.stringify(badPath));}catch(e){rejected=true;}yes(rejected,'reject disconnected path');
 eq(Core.validate(initial),null,'initial valid');
 return checks;
}
