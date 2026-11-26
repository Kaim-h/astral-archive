// Shared executable contract: run unchanged in Node and Qt Quick.
import * as Core from "../archive/ArchiveCore.mjs";
import * as Spatial from "../archive/ArchiveSpatial.mjs";
import * as Checkpoint from "../archive/ArchiveCheckpoint.mjs";
import * as MixedFixture from "./ArchiveB7MixedFixture.mjs";
import * as Mixed from "../archive/representation/B7Ownership.mjs";
import * as Motion from "../archive/ArchiveMotion.mjs";
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
 // Flat-top support is explicit, local and uses the same portable record.
 // Create a dedicated uncluttered fixture rather than altering the visual sample.
 const supportBase=Core.fixture();supportBase.cubbies.root.w=1400;supportBase.cubbies.root.h=1000;
 const topRack=supportBase.cubbies.root.mods[0];topRack.x=100;topRack.y=350;
 supportBase.caseItems.push({id:'top-parcel',name:'Parcel.zip',r:13,representation:'parcel',variant:'parcel/satchel'},
  {id:'top-audio',name:'Tone.flac',r:13,representation:'record',variant:'record/v1'},
  {id:'top-art',name:'Art.png',r:13,representation:'artwork',variant:'artwork/moonlit-mountains'});
 let tops=apply(Core.session(supportBase),{kind:'spatialPromote'});
 const dest={kind:'shelf',cubbyId:'root',moduleId:topRack.id,x:100,scale:.86,support:'tray'};
 let n=Core.transfer(tops,['top-parcel'],dest);yes(n.error,'ineligible top refuses file');eq(n.snapshot,tops.snapshot,'refusal atomic');
 tops=apply(tops,{kind:'spatialSupport',containerId:'root',moduleId:topRack.id,patch:{enabled:true}});
 n=Core.transfer(tops,['top-parcel'],dest);eq(n.error,'','direct rack-top placement');tops=n;
 const owned=Core.owners(tops.snapshot).find(e=>e.id==='top-parcel');
 eq(owned.moduleId,topRack.id,'support owner is rack module, not extra board');
 eq(Mixed.supportSurface(Core.rackAt(tops.snapshot,'root',topRack.id)),{moduleId:topRack.id,x:100,y:350,w:500},'explicit local datum');
 eq(Core.owners(tops.snapshot).filter(e=>e.where==='rack').length,3,'rack cells unchanged');
 const topItems=Core.clone(Core.rackAt(tops.snapshot,'root',topRack.id).items);
 const staged=Core.stage(tops,'root',topRack.id,{x:120,y:380});
 eq(staged.draft.phase,'pending','supported rack move stage');
 const solved=Core.accept(staged,Core.solve(Core.request(staged)));
 eq(solved.draft.phase,'ready','supported rack move solved');
 const shifted=Core.apply(solved);eq(shifted.error,'','supported rack move committed');
 eq(Core.rackAt(shifted.snapshot,'root',topRack.id).items,topItems,'dependent positions/sizes unchanged');
 eq(Core.undo(shifted).snapshot,tops.snapshot,'rack movement exact Undo');
 const tooHigh=Core.stage(tops,'root',topRack.id,{y:0});
 eq(tooHigh.draft.phase,'invalid','overhead boundary enforced');
 eq(Core.apply(tooHigh).snapshot,tops.snapshot,'invalid movement nonmutating');
 refuse(tops,{kind:'spatialSupport',containerId:'root',moduleId:topRack.id,patch:{enabled:false}});
 const carriedTop=Core.transfer(tops,['top-parcel'],'case');eq(carriedTop.error,'','cut direct top object');
 const topRecord=carriedTop.snapshot.caseItems.find(r=>r.id==='top-parcel');
 const origin=Core.originDestination(carriedTop.snapshot,topRecord);
 eq([origin.kind,origin.cubbyId,origin.moduleId,origin.x,origin.scale,origin.support],
    [dest.kind,dest.cubbyId,dest.moduleId,dest.x,dest.scale,dest.support],'return uses same support datum');
 const disabled=apply(carriedTop,{kind:'spatialSupport',containerId:'root',moduleId:topRack.id,patch:{enabled:false}});
 yes(disabled.snapshot.caseItems.find(r=>r.id==='top-parcel').originStale,'disabled surface origin stale');
 const reenabled=apply(disabled,{kind:'spatialSupport',containerId:'root',moduleId:topRack.id,patch:{enabled:true}});
 let lost=false;try{Core.originDestination(reenabled.snapshot,topRecord)}catch(e){lost=true}yes(lost,'reenabling does not revive old origin');
 eq(Core.undo(disabled).snapshot,carriedTop.snapshot,'undo surface disable restores exact provenance');
 // Live mixed transaction uses the same file owner and contact checks.
 const motion=Motion.begin(carriedTop,['top-parcel'],true);
 Motion.lift(motion);Motion.insert(motion,dest,{});Motion.release(motion,false);
 const returned=Core.commitMotion(carriedTop,motion);eq(returned.error,'','live top return');
 eq(Core.owners(returned.snapshot).find(e=>e.id==='top-parcel').moduleId,topRack.id,'live owner preserved');
 tops=returned;
 // Holder cradle and occupied slots consume the same width/height envelopes.
 tops=apply(tops,{kind:'create',type:'cubby',cubbyId:'root',patch:{x:700,y:400,w:500,h:300}});
 const childModule=tops.snapshot.cubbies.root.mods.find(m=>m.type==='cubby');
 tops=apply(tops,{kind:'spatialSupport',containerId:'root',moduleId:childModule.id,patch:{enabled:true}});
 tops=apply(tops,{kind:'holderCreate',cubbyId:'root',moduleId:childModule.id,patch:{x:0,w:130,count:2}});
 const h=tops.snapshot.cubbies.root.mods.find(m=>m.id===childModule.id).items[0];
 n=Core.transfer(tops,['top-audio'],{kind:'holder',cubbyId:'root',moduleId:childModule.id,holderId:h.id,slot:0});
 eq(n.error,'','upright on Cubby top');tops=n;
 refuse(tops,{kind:'child',cubbyId:'root',moduleId:childModule.id,patch:{w:150}});
 refuse(tops,{kind:'spatialSupport',containerId:'root',moduleId:childModule.id,patch:{enabled:false}});
 refuse(tops,{kind:'child',cubbyId:'root',moduleId:childModule.id,patch:{y:0}});
 const overlap=Core.transfer(tops,['top-art'],{kind:'shelf',cubbyId:'root',moduleId:childModule.id,x:65,scale:.86,support:'shelf',frame:{w:120,h:100,profile:'bronze'}});
 yes(overlap.error,'reserved holder blocks competing object');eq(overlap.snapshot,tops.snapshot,'collision nonmutating');
 const topSave=Checkpoint.encode(tops,{path:['root'],theme:1,cameras:{}});
 eq(Checkpoint.decode(topSave).snapshot,tops.snapshot,'supported tops v3 roundtrip');
 const malformed=Core.clone(tops.snapshot);delete malformed.cubbies.root.mods[0].flatTop;invalid(malformed,'unqualified top contents invalid');
 const duplicateTop=Core.clone(tops.snapshot);
 duplicateTop.caseItems.push(Core.clone(Core.owners(tops.snapshot).find(e=>e.id==='top-parcel').scroll));invalid(duplicateTop,'duplicate top owner invalid');
 const removeTop=Core.previewStructure(tops,{kind:'delete',cubbyId:'root',moduleId:childModule.id});
 yes(removeTop.ok,removeTop.error);eq(removeTop.caseTransferCount,1,'top holder file evacuated on Cubby deletion');
 const afterTop=Core.applyStructure(tops,removeTop);eq(afterTop.error,'','top support deletion');
 yes(afterTop.snapshot.caseItems.find(r=>r.id==='top-audio').originStale,'removed top origin stale');
 eq(Core.undo(afterTop).snapshot,tops.snapshot,'top removal exact Undo');
 const removedRack=Core.previewStructure(tops,{kind:'delete',cubbyId:'root',moduleId:topRack.id});
 yes(removedRack.ok,removedRack.error);eq(removedRack.caseTransferCount,4,'rack cells and supported file evacuated together');
 const afterRack=Core.applyStructure(tops,removedRack);eq(afterRack.error,'','rack support deletion');
 eq(Core.undo(afterRack).snapshot,tops.snapshot,'rack deletion exact Undo');
 const legacyTop=Core.clone(supportBase);legacyTop.cubbies.root.mods[0].flatTop=true;invalid(legacyTop,'legacy opt-out enforced');
 return checks;
}
