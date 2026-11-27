// Shared executable contract: run unchanged in Node and Qt Quick.
import * as Core from "../archive/ArchiveCore.mjs";
import * as Spatial from "../archive/ArchiveSpatial.mjs";
import * as Checkpoint from "../archive/ArchiveCheckpoint.mjs";
import * as Appearance from "../archive/ArchiveAppearance.mjs";
import * as MixedFixture from "./ArchiveB7MixedFixture.mjs";
import * as Mixed from "../archive/representation/B7Ownership.mjs";
import * as Motion from "../archive/ArchiveMotion.mjs";
import * as Capacity from "../archive/ArchiveCapacity.mjs";
import * as Doors from "../archive/ArchiveDoors.mjs";
import * as View from "../archive/ArchiveView.mjs";
import * as Terrain from "../archive/ArchiveMapTerrain.mjs";
import * as Architecture from "../archive/ArchiveArchitecture.mjs";
import * as Projection from "../archive/ArchiveRoomProjection.mjs";
import * as Transition from "../archive/ArchiveRoomTransition.mjs";
import * as ShelfSample from "./ArchiveB8ShelfFixture.mjs";
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
 // Applications retain identity independently from file owners.
 let books=apply(tops,{kind:'spatialAppRegister',patch:{appId:'org.example.Reader',title:'Reader'}});
 const fileIds=Core.owners(books.snapshot).map(e=>e.id).sort();
 books=apply(books,{kind:'spatialAppPlace',appId:'org.example.Reader',containerId:'root',moduleId:topRack.id,patch:{x:350}});
 eq(Spatial.appPlacements(books.snapshot),[{appId:'org.example.Reader',containerId:'root',moduleId:topRack.id,x:350}],'book independently placed');
 eq(Core.owners(books.snapshot).map(e=>e.id).sort(),fileIds,'no app file owner');
 refuse(books,{kind:'spatialAppPlace',appId:'org.example.Reader',containerId:'root',moduleId:topRack.id,patch:{x:100}});
 refuse(books,{kind:'spatialAppPlace',appId:'org.example.Reader',containerId:'root',moduleId:topRack.id,patch:{x:350,w:20}});
 refuse(books,{kind:'spatialAppRegister',patch:{appId:'org.example.Reader',title:'Duplicate'}});
 const bookRemoval=Core.previewStructure(books,{kind:'delete',cubbyId:'root',moduleId:topRack.id});
 yes(bookRemoval.ok,bookRemoval.error);eq(bookRemoval.appUnplacementCount,1,'book unplacement separately previewed');eq(bookRemoval.caseTransferCount,4,'only files evacuated');
 const bookGone=Core.applyStructure(books,bookRemoval);
 eq(bookGone.error,'','remove occupied rack');eq(Spatial.appPlacements(bookGone.snapshot),[],'book unplaced');
 eq(bookGone.snapshot.spatial.apps,books.snapshot.spatial.apps,'application identity retained');
 eq(Core.undo(bookGone).snapshot,books.snapshot,'book removal exact Undo');
 const unplaced=apply(books,{kind:'spatialAppUnplace',appId:'org.example.Reader'});
 eq(unplaced.snapshot.caseItems,books.snapshot.caseItems,'no Case record for app');
 eq(unplaced.snapshot.spatial.apps,books.snapshot.spatial.apps,'unplacement preserves catalogue');
 const duplicateBook=Core.clone(books.snapshot);duplicateBook.cubbies.root.mods.find(m=>m.id===topRack.id).items.push({kind:'app',appId:'org.example.Reader',x:450});invalid(duplicateBook,'duplicate app placement');
 const unknownBook=Core.clone(books.snapshot);delete unknownBook.spatial.apps['org.example.Reader'];invalid(unknownBook,'dangling app ref');
 eq(Checkpoint.decode(Checkpoint.encode(books,{path:['root'],theme:1,cameras:{}})).snapshot,books.snapshot,'app v3 checkpoint');
 const bookShift=Core.stage(books,'root',topRack.id,{x:130,y:375});
 const bookShifted=Core.apply(Core.accept(bookShift,Core.solve(Core.request(bookShift))));
 eq(bookShifted.error,'','book support movement commits');
 eq(Spatial.appPlacements(bookShifted.snapshot),Spatial.appPlacements(books.snapshot),'book placement remains support local');
 eq(Core.undo(bookShifted).snapshot,books.snapshot,'book support movement Undo');
 let placedElsewhere=apply(books,{kind:'create',type:'shelf',cubbyId:'root',patch:{x:50,y:950,w:400,h:15}});
 const secondBoard=placedElsewhere.snapshot.cubbies.root.mods.find(m=>m.type==='shelf');
 // The board above would collide with the rack? Its y=950 is clear;
 // its book reservation extends upward only to 790, below the rack.
 placedElsewhere=apply(placedElsewhere,{kind:'spatialAppPlace',appId:'org.example.Reader',containerId:'root',moduleId:secondBoard.id,patch:{x:100}});
 eq(Spatial.appPlacements(placedElsewhere.snapshot),[{appId:'org.example.Reader',containerId:'root',moduleId:secondBoard.id,x:100}],'reposition exactly one book');
 eq(Core.owners(placedElsewhere.snapshot).map(e=>e.id).sort(),fileIds,'reposition preserves file owners');
 const malformedApp=Core.clone(books.snapshot);malformedApp.cubbies.root.mods[0].items.find(e=>e.kind==='app').scale=.5;invalid(malformedApp,'checkpoint cannot resize book');
 // Door intervals are anchored on an actual stable Room edge.
 let halls=apply(Core.session(Core.fixture()),{kind:'spatialPromote'});
 const hall=Object.keys(halls.snapshot.spatial.rooms)[0],right=halls.snapshot.spatial.rooms[hall].w;
 halls=apply(halls,{kind:'spatialRoomCreate',patch:{name:'East Room',x:right,y:20,w:900,h:400}});
 const east=Object.keys(halls.snapshot.spatial.rooms).find(k=>k!==hall);
 const ea={roomId:hall,side:'east'},eb={roomId:east,side:'west'};
 const createDoor=(a,b,start,end)=>({kind:'spatialDoorCreate',patch:{a,b,start,end}});
 halls=apply(halls,createDoor(ea,eb,40,90));
 const d1=Object.keys(halls.snapshot.spatial.doors)[0];
 eq(Spatial.doorGeometry(halls.snapshot,d1),{vertical:true,line:right,start:40,end:90,openings:[{roomId:hall,side:'east',start:40,end:90},{roomId:east,side:'west',start:20,end:70}]},'two views one interval');
 refuse(halls,createDoor(ea,eb,10,30));
 refuse(halls,createDoor(ea,eb,80,100));
 refuse(halls,createDoor(ea,{roomId:east,side:'east'},100,130));
 halls=apply(halls,createDoor(eb,ea,70,100));
 const d2=Object.keys(halls.snapshot.spatial.doors).find(k=>k!==d1);
 const merged=apply(halls,{kind:'spatialDoorMerge',doorId:d1,patch:{otherId:d2}});
 eq(Object.keys(merged.snapshot.spatial.doors),[d1],'merge retains first identity');
 eq(Spatial.doorGeometry(merged.snapshot,d1).end,120,'merged interval');
 eq(Core.undo(merged).snapshot,halls.snapshot,'door merge exact Undo');
 refuse(merged,{kind:'spatialDoorEdit',doorId:d1,patch:{end:270}});
 const shorter=apply(merged,{kind:'spatialDoorEdit',doorId:d1,patch:{end:100}});
 const moveDoor=apply(shorter,{kind:'spatialDoorEdit',doorId:d1,patch:{start:60,end:120}});
 eq(Spatial.doorGeometry(moveDoor.snapshot,d1).start,60,'door center movement');
 refuse(moveDoor,{kind:'spatialRoomEdit',roomId:east,patch:{x:right+1}});
 refuse(moveDoor,{kind:'spatialRoomEdit',roomId:east,patch:{x:right+1},removeDoors:[d1,'unknown']});
 refuse(moveDoor,{kind:'spatialRoomEdit',roomId:east,patch:{y:30},removeDoors:[d1]});
 const separation=Core.previewStructure(moveDoor,{kind:'spatialRoomEdit',roomId:east,patch:{x:right+1},removeDoors:[d1]});
 yes(separation.ok,separation.error);eq(separation.removedDoorIds,[d1],'explicit separation preview');
 const separated=Core.applyStructure(moveDoor,separation);eq(separated.error,'','separation accepted');
 eq(Core.undo(separated).snapshot,moveDoor.snapshot,'separation Undo');
 const preserved=apply(moveDoor,{kind:'spatialRoomEdit',roomId:east,patch:{y:30}});
 eq(Spatial.doorGeometry(preserved.snapshot,d1).start,60,'shared world opening preserved when second room slides');
 const noDoor=apply(preserved,{kind:'spatialDoorDelete',doorId:d1});
 eq(noDoor.snapshot.cubbies,preserved.snapshot.cubbies,'door removal leaves contents');
 eq(Core.undo(noDoor).snapshot,preserved.snapshot,'door delete Undo');
 const blockedShelf=Core.previewStructure(moveDoor,{kind:'spatialShelfCreate',roomId:east,patch:{x:0,y:30,w:150,h:140,depth:100,orientation:0}});
 eq(blockedShelf.ok,false,'Shelf cannot obstruct opening');
 const doorSaved=Checkpoint.encode(preserved,{path:['root'],theme:1,cameras:{}});
 eq(Checkpoint.decode(doorSaved).snapshot,preserved.snapshot,'doors v3 roundtrip');
 const badEdge=Core.clone(preserved.snapshot);badEdge.spatial.doors[d1].a.roomId=[hall];invalid(badEdge,'edge identity not coercible');
 const badInterval=Core.clone(preserved.snapshot);badInterval.spatial.doors[d1].end=badInterval.spatial.doors[d1].start;invalid(badInterval,'zero-width door');
 const duplicateDoor=Core.clone(preserved.snapshot);duplicateDoor.spatial.doors[hall]=Object.assign({},duplicateDoor.spatial.doors[d1],{id:hall});invalid(duplicateDoor,'door identity collides with Room');
 const removeRoom=Core.previewStructure(preserved,{kind:'spatialRoomDelete',roomId:east,removeDoors:[d1]});
 yes(removeRoom.ok,removeRoom.error);eq(removeRoom.removedDoorIds,[d1],'room removal reports door loss');
 const roomGone=Core.applyStructure(preserved,removeRoom);eq(roomGone.error,'','empty Room removal after door resolution');
 eq(Core.undo(roomGone).snapshot,preserved.snapshot,'room/door removal exact Undo');
 // Horizontal shared edge with touching corner and third-room pair.
 let south=apply(Core.session(Core.fixture()),{kind:'spatialPromote'});
 const northId=Object.keys(south.snapshot.spatial.rooms)[0],rh=south.snapshot.spatial.rooms[northId].h;
 south=apply(south,{kind:'spatialRoomCreate',patch:{x:0,y:rh,w:400,h:300,name:'South'}});
 const southId=Object.keys(south.snapshot.spatial.rooms).find(k=>k!==northId);
 south=apply(south,createDoor({roomId:northId,side:'south'},{roomId:southId,side:'north'},20,80));
 const southDoor=Object.keys(south.snapshot.spatial.doors)[0];
 eq(Spatial.doorGeometry(south.snapshot,southDoor).vertical,false,'horizontal doorway');
 south=apply(south,{kind:'spatialRoomCreate',patch:{x:400,y:rh,w:400,h:300,name:'South East'}});
 const se=Object.keys(south.snapshot.spatial.rooms).find(k=>k!==northId&&k!==southId);
 south=apply(south,createDoor({roomId:northId,side:'south'},{roomId:se,side:'north'},410,460));
 const second=Object.keys(south.snapshot.spatial.doors).find(k=>k!==southDoor);
 refuse(south,{kind:'spatialDoorMerge',doorId:southDoor,patch:{otherId:second}});
 // N1d: boundary budgets, isolated proposals and cross-domain transactions.
 const appBefore=Core.clone(books.snapshot);
 const mutable={kind:'spatialAppearance',containerId:'root',patch:{family:'Lighting Lab',palette:2}};
 const appearanceProposal=Core.previewStructure(books,mutable);
 yes(appearanceProposal.ok,'appearance preview ready');
 mutable.patch.family='Changed';
 const appearanceApplied=Core.applyStructure(books,appearanceProposal);
 eq(appearanceApplied.error,'','caller mutation cannot change preview');
 eq(appearanceApplied.snapshot.cubbies.root.appearance.family,'Lighting Lab','original appearance retained');
 eq(books.snapshot,appBefore,'original unchanged');
 const nestedCommand={kind:'spatialRoomEdit',roomId:hall,patch:{appearance:{family:'Observatory',palette:1}}};
 const roomPreview=Core.previewStructure(halls,nestedCommand);
 yes(roomPreview.ok,'nested metadata preview');
 nestedCommand.patch.appearance.family='Changed';
 eq(roomPreview.snapshot.spatial.rooms[hall].appearance.family,'Observatory','nested input copied');
 const altered=Core.previewStructure(books,{kind:'spatialAppUnplace',appId:'org.example.Reader'});
 altered.command={kind:'spatialAppPlace',appId:'org.example.Reader',containerId:'root',moduleId:topRack.id,patch:{x:450}};
 const alteredResult=Core.applyStructure(books,altered);
 yes(alteredResult.error,'changed command cannot publish different preview');eq(alteredResult.snapshot,books.snapshot,'changed preview nonmutating');
 refuse(books,{kind:'spatialAppUnplace',appId:['org.example.Reader']});
 refuse(books,{kind:'spatialShelfEdit',containerId:'root',patch:{w:1399.5}});
 const fakeMotion=Motion.begin(books,['top-parcel'],true);
 Motion.lift(fakeMotion);Motion.insert(fakeMotion,'case',{});Motion.release(fakeMotion,false);
 delete fakeMotion.draft.spatial.apps['org.example.Reader'];
 fakeMotion.draft.cubbies.root.mods.find(m=>m.id===topRack.id).items=fakeMotion.draft.cubbies.root.mods.find(m=>m.id===topRack.id).items.filter(e=>e.kind!=='app');
 const foreign=Core.commitMotion(books,fakeMotion);
 yes(foreign.error,'file motion cannot remove app identity');eq(foreign.snapshot,books.snapshot,'foreign motion rejected atomically');
 const validMotion=Motion.begin(books,['top-parcel'],true);
 Motion.lift(validMotion);Motion.insert(validMotion,'case',{});Motion.release(validMotion,false);
 const actual=Core.commitMotion(books,validMotion);eq(actual.error,'','legitimate file-only motion commits');
 eq(Spatial.appPlacements(actual.snapshot),Spatial.appPlacements(books.snapshot),'legitimate motion preserves app placements');
 // Independent review: finite legacy dimensions must not round physical data.
 for(const dims of [{w:700.5},{b:11.25},{h:500.5},{w:700.5,b:11.25,h:500.5},{}]){
  const fractional=Core.fixture();Object.assign(fractional.cubbies.root,dims);
  const source=Core.session(fractional),v2=Checkpoint.encode(source,view);
  eq(JSON.parse(v2).version,2,'fractional legacy writer v2');
  eq(Checkpoint.decode(v2).snapshot,fractional,'fractional v2 exact');
  const promotedFractional=apply(source,{kind:'spatialPromote'});
  eq(promotedFractional.snapshot.cubbies,fractional.cubbies,'physical dimensions unchanged');
  eq(Core.owners(promotedFractional.snapshot),Core.owners(fractional),'fractional owners unchanged');
  const room=Object.values(promotedFractional.snapshot.spatial.rooms)[0],fp=Spatial.footprint(promotedFractional.snapshot,'root');
  eq(room.w,Math.ceil(Spatial.exterior(fractional.cubbies.root).w+100),'only enclosure rounds upward');
  yes(fp.x+fp.w<=room.w&&fp.y+fp.h<=room.h,'footprint enclosed');
  const v3=Checkpoint.encode(promotedFractional,view);
  eq(JSON.parse(v3).version,3,'fractional promoted writer v3');
  eq(Checkpoint.decode(v3).snapshot,promotedFractional.snapshot,'fractional v3 exact');
  eq(Core.undo(promotedFractional).snapshot,fractional,'fractional promotion exact Undo');
 }
 // Valid mixed-file movement is the positive control for each foreign edit.
 const makeMotion=()=>{const q=Motion.begin(books,['top-parcel'],true);Motion.lift(q);Motion.insert(q,'case',{});Motion.release(q,false);return q;};
 const pristine=JSON.stringify(books.snapshot);
 for(const mutate of [
  v=>{v.cubbies.root.appearance={family:'Observatory',palette:2};},
  v=>{v.cubbies.root.h+=10;},
  v=>{v.cubbies.root.mods[0].x+=1;},
  v=>{v.cubbies.root.mods[0].color='#123456';},
  v=>{v.cubbies.root.mods[0].cellMeta[Object.keys(v.cubbies.root.mods[0].cellMeta)[0]].color='#123456';},
  v=>{v.cubbies.root.mods.find(m=>m.id===childModule.id).items[0].x+=1;},
  v=>{v.cubbies.root.mods.find(m=>m.id===childModule.id).items[0].slots.push(null);},
  v=>{v.cubbies.root.mods[0].items.find(e=>e.kind==='app').x+=1;},
  v=>{v.materials={scheme:'quiet',roleEdits:{}};},
  v=>{v.next+=1;}
 ]){
  const q=makeMotion();mutate(q.draft);
  const rejected=Core.commitMotion(books,q);
  yes(rejected.error.indexOf('non-file structural')>=0,'foreign structural edit rejected by isolation guard');
  eq(rejected.snapshot,books.snapshot,'foreign motion rollback');
  eq(rejected.revision,books.revision,'foreign motion revision unchanged');
  eq(rejected.history,books.history,'foreign motion history unchanged');
 }
 eq(JSON.stringify(books.snapshot),pristine,'no source mutation');
 const control=Core.commitMotion(books,makeMotion());eq(control.error,'','file cut remains valid');
 // Holder slots may change occupancy, but not capacity or holder geometry.
 const holderMotion=Motion.begin(books,['top-audio'],true);
 Motion.lift(holderMotion);Motion.insert(holderMotion,'case',{});Motion.release(holderMotion,false);
 const holderCut=Core.commitMotion(books,holderMotion);eq(holderCut.error,'','holder slot cut allowed');
 const holderReturn=Motion.begin(holderCut,['top-audio'],true);
 Motion.lift(holderReturn);Motion.insert(holderReturn,{kind:'holder',cubbyId:'root',moduleId:childModule.id,holderId:h.id,slot:0},{});Motion.release(holderReturn,false);
 const restoredHolder=Core.commitMotion(holderCut,holderReturn);eq(restoredHolder.error,'','holder slot return allowed');
 // First placement creates an items array on a previously empty eligible top.
 const empty=apply(Core.session(supportBase),{kind:'spatialPromote'});
 const emptyTop=apply(empty,{kind:'spatialSupport',containerId:'root',moduleId:topRack.id,patch:{enabled:true}});
 const first=Motion.begin(emptyTop,['top-parcel'],true);
 Motion.lift(first);Motion.insert(first,dest,{});Motion.release(first,false);
 const firstPlaced=Core.commitMotion(emptyTop,first);eq(firstPlaced.error,'','absent-to-present support items allowed');
 const alloc=Core.clone(initial);alloc.next=100000;
 const oldRoom=Object.keys(alloc.spatial.rooms)[0],collision='hc100000';
 alloc.spatial.rooms[collision]=Object.assign({},alloc.spatial.rooms[oldRoom],{id:collision});
 delete alloc.spatial.rooms[oldRoom];alloc.spatial.shelves.root.roomId=collision;
 const allocRack=alloc.cubbies.root.mods[0];allocRack.scrollCells={};
 const allocSession=Core.session(alloc),resize=Core.stage(allocSession,'root',allocRack.id,{r:60});
 const ready=Core.accept(resize,Core.solve(Core.request(resize)));
 eq(ready.draft.phase,'ready','new cell allocation ready');
 yes(Object.values(ready.draft.result.meta).some(m=>m.id.indexOf('~new-')===0),'new cell required');
 const allocated=Core.apply(ready);eq(allocated.error,'','reflow skips structural identity collision');
 yes(!Object.values(allocated.snapshot.cubbies.root.mods[0].cellMeta).some(m=>m.id===collision),'no collision');
 const exhausted=Core.clone(alloc);exhausted.next=Number.MAX_SAFE_INTEGER;
 const es=Core.session(exhausted),er=Core.stage(es,'root',allocRack.id,{r:60});
 const eReady=Core.accept(er,Core.solve(Core.request(er))),eResult=Core.apply(eReady);
 yes(eResult.error,'identity exhaustion fails safely');eq(eResult.snapshot,es.snapshot,'exhaustion nonmutating');
 // Compact deterministic capacity specimens, without a large physics solve.
 const budget=Core.clone(initial),rid=Object.keys(budget.spatial.rooms)[0];
 budget.spatial.rooms[rid].w=10000;budget.spatial.rooms[rid].h=10000;
 for(let i=1;i<Spatial.spatialLimits.rooms;i++){
  const k='budget-room-'+i;budget.spatial.rooms[k]={id:k,name:'Room '+i,x:11000+i*200,y:0,w:130,h:100};
 }
 for(let i=1;i<Capacity.limits.cubbies;i++){
  const k='budget-shelf-'+i;budget.cubbies[k]={id:k,w:130,h:100,b:4,mods:[]};
  budget.spatial.shelves[k]={roomId:rid,x:1000+(i%20)*150,y:400+Math.floor(i/20)*50,depth:40,orientation:0};
 }
 budget.spatial.apps={};
 for(let i=0;i<Spatial.spatialLimits.applications;i++){const k='synthetic.app.'+i;budget.spatial.apps[k]={appId:k,title:'App '+i};}
 eq(Core.validate(budget),null,'room, container and app exact budgets');
 const tooRoom=Core.clone(budget);tooRoom.spatial.rooms.extra={id:'extra',name:'Extra',x:-1000,y:0,w:130,h:100};invalid(tooRoom,'room budget +1');
 const tooShelf=Core.clone(budget);tooShelf.cubbies.extra={id:'extra',w:130,h:100,b:4,mods:[]};tooShelf.spatial.shelves.extra={roomId:rid,x:9000,y:9000,depth:40,orientation:0};invalid(tooShelf,'container budget +1');
 const tooApp=Core.clone(budget);tooApp.spatial.apps.extra={appId:'extra',title:'Extra'};invalid(tooApp,'app budget +1');
 const recordBudget=Core.clone(initial);
 for(let i=3;i<Capacity.limits.records;i++)recordBudget.caseItems.push({id:'budget-file-'+i,name:'sample.md',r:13});
 eq(Core.validate(recordBudget),null,'file budget exact');
 recordBudget.caseItems.push({id:'extra-file',name:'extra.md',r:13});invalid(recordBudget,'file budget +1');
 const doorBudget=Core.clone(halls.snapshot);
 doorBudget.spatial.rooms[hall].h=600;doorBudget.spatial.rooms[east].h=600;doorBudget.spatial.doors={};
 for(let i=0;i<Doors.doorLimit;i++){const k='budget-door-'+i;doorBudget.spatial.doors[k]={id:k,a:ea,b:eb,start:20+i,end:21+i};}
 eq(Core.validate(doorBudget),null,'door budget exact');
 doorBudget.spatial.doors.extra={id:'extra',a:ea,b:eb,start:500,end:501};invalid(doorBudget,'door budget +1');
 // V3 malformed references/format fail without touching a live session.
 const corrupt=JSON.parse(Checkpoint.encode(books,{path:['root'],theme:1,cameras:{}}));
 for(const mutate of [
  v=>{v.snapshot.spatial=null;},
  v=>{v.snapshot.spatial.shelves.root.roomId='missing';},
  v=>{v.snapshot.spatial.apps=JSON.parse('{"__proto__":{"appId":"__proto__","title":"Invalid"}}');},
  v=>{v.view.cameras=JSON.parse('{"constructor":{"zoom":1,"x":0,"y":0}}');},
  v=>{v.snapshot.next=Number.MAX_SAFE_INTEGER+1;}
 ]){
  const value=Core.clone(corrupt);mutate(value);let failed=false;
  try{Checkpoint.decode(JSON.stringify(value));}catch(e){failed=true;}yes(failed,'malformed v3 rejected');
 }
 const sample=ShelfSample.fixture();
 eq(Core.validate(sample),null,'N2 sample valid');
 const otherRoot=Spatial.roots(sample).find(k=>k!=='root');
 eq(View.reachablePath(sample,[otherRoot]),[otherRoot],'second Shelf reachable');
 eq(View.reachablePath(sample,[otherRoot,'child']),[otherRoot],'unrelated Cubby refused');
 eq(View.reachablePath(sample,['root','child']),['root','child'],'recursive Cubby reachable');
 const noRoot=Core.clone(sample);noRoot.path=[otherRoot];
 delete noRoot.spatial.shelves.root;delete noRoot.cubbies.root;delete noRoot.cubbies.child;
 eq(View.reachablePath(noRoot,['root','child']),[otherRoot],'removed root fallback');
 eq(View.reachablePath(legacy.snapshot,['not-root']),['root'],'legacy path unchanged');
 const sampleRack=sample.cubbies.root.mods.find(m=>m.id==='rack-1');
 const suggested=Mixed.suggestBookX(sample.cubbies.root,sampleRack,'org.example.Atlas');
 yes(suggested!==null,'book hint exists');
 const sampleState=Core.session(sample);
 const bookCommand={kind:'spatialAppPlace',appId:'org.example.Atlas',containerId:'root',moduleId:sampleRack.id,patch:{x:suggested}};
 const withBook=apply(sampleState,bookCommand);
 eq(Core.owners(withBook.snapshot),Core.owners(sample),'picker preserves file owners');
 eq(Spatial.appPlacements(withBook.snapshot).filter(v=>v.appId==='org.example.Atlas').length,1,'exactly one placement');
 eq(Core.undo(withBook).snapshot,sample,'picker placement Undo');
 eq(Mixed.suggestBookX(sample.cubbies.root,Object.assign({},sampleRack,{y:0}),'org.example.Atlas'),null,'insufficient ceiling refuses hint');
 const firstBookProposal=Core.previewStructure(sampleState,bookCommand);
 yes(firstBookProposal.ok,'first book proposal');
 const repeatBookProposal=Core.previewStructure(sampleState,bookCommand);
 yes(repeatBookProposal.ok,'repeat after discarded preview');
 function reordered(v){
  if(!v||typeof v!=='object')return v;
  if(Array.isArray(v))return v.map(reordered);
  const out={};for(const k of Object.keys(v).reverse())out[k]=reordered(v[k]);return out;
 }
 const reorderedProposal=Object.assign({},repeatBookProposal,{snapshot:reordered(repeatBookProposal.snapshot)});
 const repeatApplied=Core.applyStructure(sampleState,reorderedProposal);
 eq(repeatApplied.error,'','property order is not a changed preview');
 eq(repeatApplied.snapshot,withBook.snapshot,'repeated placement exact');
 const different=Core.clone(repeatBookProposal);different.snapshot.cubbies.root.h++;
 yes(Core.applyStructure(sampleState,different).error,'changed value remains rejected');
 refuse(sampleState,Object.assign({},bookCommand,{patch:{x:null}}));
 refuse(sampleState,Object.assign({},bookCommand,{patch:{x:-1}}));
 eq(Core.bookDragPosition(100.5,39,20,true),140.5,'relative snap retains fractional anchor');
 eq(Core.bookDragPosition(100.5,-31,20,true),60.5,'relative negative displacement');
 eq(Core.bookDragPosition(100.5,12.6,20,false),113.5,'unsnapped integer movement retains anchor');
 eq(Core.bookDragPosition(100.5,2,20,true),100.5,'sub-grid motion no displacement');
 const movedBook=apply(sampleState,{kind:'spatialAppPlace',appId:'org.example.Reader',containerId:'root',moduleId:sampleRack.id,patch:{x:160}});
 eq(Core.owners(movedBook.snapshot),Core.owners(sample),'drag preserves file identity and location');
 eq(Spatial.appPlacements(movedBook.snapshot).find(a=>a.appId==='org.example.Reader').x,160,'support-local drag destination');
 eq(Core.undo(movedBook).snapshot,sample,'drag Undo exact');
 refuse(sampleState,{kind:'spatialAppPlace',appId:'org.example.Reader',containerId:'root',moduleId:sampleRack.id,patch:{x:0}});
 refuse(sampleState,{kind:'spatialAppPlace',appId:'org.example.Reader',containerId:'root',moduleId:sampleRack.id,patch:{x:300}});
 const palettes=[
 {name:'Evening',background:'#343c43',panel:'#3f524f',metal:'#c2aa78',engraving:'#b7a2c8',text:'#f0f0e8'},
 {name:'Twilight',background:'#121e23',panel:'#263c37',metal:'#8c6e5a',engraving:'#91ada1',text:'#e6e1d8'},
 {name:'Midnight',background:'#080f10',panel:'#101c1b',metal:'#869c9c',engraving:'#568f80',text:'#dadfd9'}];
 const themed=apply(sampleState,{kind:'spatialAppearance',containerId:'root',patch:{palette:0}});
 eq(View.spatialPalette(themed.snapshot,'root',palettes,1).name,'Evening','local Shelf palette resolved');
 eq(View.spatialPalette(themed.snapshot,'child',palettes,1).name,'Twilight','parent palette not propagated');
 eq(View.spatialPalette(themed.snapshot,otherRoot,palettes,2).name,'Midnight','unrelated Shelf global palette');
 eq(Core.owners(themed.snapshot),Core.owners(sample),'appearance preserves file owners');
 eq(Core.undo(themed).snapshot,sample,'appearance exact Undo');
 const swatches=palettes.map(p=>View.bookColors('#526f63',p));
 eq(new Set(swatches.map(v=>v.cover)).size,3,'three coordinated covers');
 eq(View.bookColors('#526f63',palettes[1]),swatches[1],'deterministic cover identity');
 yes(View.bookColors('#526f63',palettes[1]).cover!==View.bookColors('#836b54',palettes[1]).cover,'base identity hue retained');
 eq(Spatial.shelfProfile(sample,'root'),'cornice','default Shelf profile');
 const profile=apply(sampleState,{kind:'spatialAppearance',containerId:'root',patch:{profile:'pilaster',palette:2}});
 eq(Spatial.shelfProfile(profile.snapshot,'root'),'pilaster','local profile stored');
 eq(Spatial.shelfProfile(profile.snapshot,otherRoot),'cornice','other Shelf unaffected');
 eq(Spatial.footprint(profile.snapshot,'root'),Spatial.footprint(sample,'root'),'trim does not change footprint');
 eq(profile.snapshot.cubbies.root.mods,sample.cubbies.root.mods,'trim retains all furniture and placements');
 eq(Core.undo(profile).snapshot,sample,'profile exact Undo');
 eq(Checkpoint.decode(Checkpoint.encode(profile,{path:['root'],theme:1,cameras:{}})).snapshot,profile.snapshot,'profile checkpoint exact');
 refuse(sampleState,{kind:'spatialAppearance',containerId:'root',patch:{profile:'unknown'}});
 refuse(sampleState,{kind:'spatialAppearance',containerId:'child',patch:{profile:'crest'}});
 refuse(sampleState,{kind:'spatialAppearance',patch:{profile:'crest'}});
 const trims=Spatial.shelfProfiles.map(p=>View.shelfTrim(sample.cubbies.root,p));
 eq(new Set(trims.map(t=>JSON.stringify(t))).size,3,'distinct trim geometry');
 for(const c of [{w:130,h:100,b:4},{w:700.5,h:500,b:11.25},sample.cubbies.root]){
  const e=Spatial.exterior(c);
  for(const p of Spatial.shelfProfiles)for(const r of View.shelfTrim(c,p)){
   yes(r.x>=0&&r.y>=0&&r.x+r.w<=e.w+.001&&r.y+r.h<=e.h+.001,'trim inside envelope');
   yes(r.x+r.w<=c.b+.001||r.x>=e.w-c.b-.001||r.y+r.h<=c.b+.001||r.y>=e.h-c.b-.001,'trim outside aperture');
  }
 }
 eq(View.ornamentFamilies.length,11,'nine families plus inherit and None');
 const familyAssets=View.ornamentFamilies.filter(f=>f.key!==null&&f.key!=='None').map(f=>View.ornamentAsset(f.key,'Evening'));
 eq(new Set(familyAssets).size,9,'distinct family art');
 eq(View.ornamentAsset('None','Midnight'),'','explicit None has no asset');
 eq(View.ornamentAsset('unrecognized legacy name','Twilight'),'ornaments/plain-twilight.svg','unknown name visual fallback only');
 for(const family of View.ornamentFamilies.filter(f=>f.key!==null&&f.key!=='None')){
  const variants=palettes.map(p=>View.ornamentAsset(family.key,p.name));
  eq(new Set(variants).size,3,'three theme assets');
 }
 const familyState=apply(sampleState,{kind:'spatialAppearance',containerId:'root',patch:{family:'Astral',palette:0}});
 eq(Spatial.resolveAppearance(familyState.snapshot,'child',1),{family:'Astral',palette:1},'child inherits family not palette');
 const noFamily=apply(familyState,{kind:'spatialAppearance',containerId:'child',patch:{family:'None'}});
 eq(View.ornamentAsset(Spatial.resolveAppearance(noFamily.snapshot,'child',1).family,'Twilight'),'','child None overrides family');
 const inherited=apply(noFamily,{kind:'spatialAppearance',containerId:'child',patch:{family:null}});
 eq(Spatial.resolveAppearance(inherited.snapshot,'child',1).family,'Astral','child reset restores inheritance');
 eq(Core.owners(inherited.snapshot),Core.owners(sample),'family changes preserve owners');
 eq(Core.undo(familyState).snapshot,sample,'family exact Undo');
 eq(Checkpoint.decode(Checkpoint.encode(familyState,{path:['root'],theme:1,cameras:{}})).snapshot,familyState.snapshot,'family checkpoint exact');
 yes(View.familyMarkSize(100,80,true)<=40&&View.familyMarkSize(1000,1000,false)<=112,'bounded display size');
 const population=ShelfSample.populatedFixture(3);
 eq(Core.validate(population),null,'mixed population valid');
 eq(Core.owners(population).length,Core.owners(sample).length*3,'population retains each mixed file');
 eq(Spatial.appPlacements(population).length,Spatial.appPlacements(sample).length*3,'population retains independent books');
 eq(new Set(Core.owners(population).map(o=>o.id)).size,Core.owners(population).length,'population unique file IDs');
 eq(View.reachablePath(population,['sample-2-root','sample-2-child']),['sample-2-root','sample-2-child'],'populated hierarchy reachable');
 // Adapter-only specimen: count occupied slots, not holders or empty slots.
 const immediate={mods:[
  {type:'rack',flatTop:true,scrollCells:{a:[{id:'a'}]},items:[{kind:'object'},{kind:'app'},{kind:'holder',slots:[{},null,{}]}]},
  {type:'cubby',flatTop:true,childId:'descendant',items:[{kind:'object'},{kind:'app'},{kind:'holder',slots:[null,{}]}]},
  {type:'shelf',items:[{kind:'object'},{kind:'app'},{kind:'holder',slots:[null,{},null]}]},
  {type:'rack',scrollCells:{b:[{}]}},
  {type:'artwork',record:{}},{type:'cubby',childId:'another'}
 ]};
 eq(View.cubbyPreviewSummary(immediate),{rack:2,shelf:1,cubby:2,items:13},'immediate support inventory all fixture types');
 const nestedInventory=ShelfSample.inventoryFixture();
 eq(Core.validate(nestedInventory),null,'nested inventory specimen valid');
 eq(View.cubbyPreviewSummary(nestedInventory.cubbies.root).items,20,'actual furnished child includes top books and files');
 eq(View.cubbyPreviewSummary(nestedInventory.cubbies.child).items,1,'descendant counted only in its own inventory');
 eq(Core.owners(nestedInventory).length,20,'inventory not ownership mutation');
 // N3a shared physical-profile candidate: no persisted migration.
 const originalSample=JSON.stringify(sample),geometryCases=[{w:130,h:100,b:4},{w:700.5,h:500.5,b:11.25},{w:1800,h:1500,b:40},sample.cubbies.root];
 for(const c of geometryCases){
  const profiles=Spatial.shelfProfiles.map(p=>Architecture.shelfGeometry(c,p,160));
  yes(profiles[1].h>profiles[0].h,'crest has real additive height');
  yes(profiles[2].w>profiles[0].w,'pilaster has real additive width');
  for(const g of profiles){
   eq([g.aperture.w,g.aperture.h],[c.w,c.h],'unaltered interior');
   eq(g.depth,160,'independent depth');
   for(const part of g.parts)for(const p of part.points)
    yes(p[0]>=-.00001&&p[1]>=-.00001&&p[0]<=g.w+.00001&&p[1]<=g.h+.00001,'profile vertex within occupied front');
   const fit=Architecture.fitFront(g,1000,700);
   yes(fit.scale>0&&fit.x>=16-.00001&&fit.y>=16-.00001,'uniform front fit');
   for(const orientation of [0,90,180,270]){
    const p={x:10,y:20,orientation},box=Architecture.profileFootprint(g,p);
    eq([box.w,box.h],orientation%180?[g.depth,g.w]:[g.w,g.depth],'rotated occupied dimensions');
    const glyph=Architecture.planGlyph(g,p);
    for(const layer of glyph.layers)for(const q of layer.points)yes(q[0]>=box.x-.00001&&q[1]>=box.y-.00001&&q[0]<=box.x+box.w+.00001&&q[1]<=box.y+box.h+.00001,'H glyph in real footprint');
    const a=Architecture.frontPoint(g,p,0,g.h),b=Architecture.frontPoint(g,p,g.w,g.h);
    eq(a[2],0,'floor datum');eq(b[2],0,'floor datum far end');
    yes(Math.abs(Math.hypot(a[0]-b[0],a[1]-b[1])-g.w)<.00001,'front width preserved in Room');
    eq(Architecture.frontPoint(g,p,0,0)[2],g.h,'front height preserved');
   }
   const changedDepth=Architecture.shelfGeometry(c,g.profile,300);
   eq([changedDepth.w,changedDepth.h,changedDepth.aperture],[g.w,g.h,g.aperture],'depth does not stretch front');
  }
 }
 const profileReport=Architecture.inspectProfileLayout(sample);
 yes(profileReport.ok,'existing furnished specimen can accommodate candidate profiles');
 eq(JSON.stringify(sample),originalSample,'profile inspection never mutates');
 const tight=Core.clone(sample),rootAttachment=tight.spatial.shelves.root,oldBox=Spatial.footprint(tight,'root');
 tight.spatial.rooms[rootAttachment.roomId].w=Math.ceil(oldBox.x+oldBox.w);
 eq(Core.validate(tight),null,'old envelope can fit snugly');
 const tightBefore=JSON.stringify(tight),blocked=Architecture.inspectProfileLayout(tight);
 yes(!blocked.ok&&blocked.conflicts.some(x=>x.kind==='wall'&&x.shelfId==='root'),'physical expansion detects wall collision');
 eq(JSON.stringify(tight),tightBefore,'invalid candidate never migrates');
 const adjacent=Core.clone(sample),nextShelf=Object.keys(adjacent.spatial.shelves).find(k=>k!=='root'),adjacentRoom=adjacent.spatial.shelves.root.roomId;
 adjacent.spatial.rooms[adjacent.spatial.shelves[nextShelf].roomId].x=4000;
 adjacent.spatial.rooms[adjacentRoom].w=3000;
 Object.assign(adjacent.spatial.shelves[nextShelf],{roomId:adjacentRoom,x:Math.ceil(oldBox.x+oldBox.w)+1,y:oldBox.y});
 eq(Core.validate(adjacent),null,'old envelopes fit side by side');
 const adjacentBefore=JSON.stringify(adjacent),overlapReport=Architecture.inspectProfileLayout(adjacent);
 yes(!overlapReport.ok&&overlapReport.conflicts.some(x=>x.kind==='shelf'&&x.shelfId===nextShelf&&x.otherId==='root'),'additive width detects neighboring Shelf overlap');
 eq(JSON.stringify(adjacent),adjacentBefore,'neighbor collision does not move Shelf');
 const doorway=Core.clone(preserved.snapshot),attachment=doorway.spatial.shelves.root;
 doorway.cubbies.root.b=16;
 const doorProfile=Architecture.shelfGeometry(doorway.cubbies.root,'cornice',attachment.depth);
 attachment.x=doorway.spatial.rooms[attachment.roomId].w-doorProfile.w;
 eq(Core.validate(doorway),null,'old envelope clears opening');
 const doorwayBefore=JSON.stringify(doorway),doorReport=Architecture.inspectProfileLayout(doorway);
 yes(!doorReport.ok&&doorReport.conflicts.some(x=>x.kind==='door'&&x.doorId===d1),'new envelope touches shared doorway');
 eq(JSON.stringify(doorway),doorwayBefore,'obstructed opening retained');
 // N3b explicit whole-snapshot adoption.
 {
 const adoption={kind:'spatialAdoptProfiles'},oldSave=Checkpoint.encode(sampleState,view);
 eq(JSON.parse(oldSave).version,3,'unadopted v3');
 const proposal=Core.previewStructure(sampleState,adoption);
 yes(proposal.ok,proposal.error);yes(proposal.profileAdoption.ok,'adoption report ready');
 eq(proposal.profileAdoption.shelves.root.previous.box,Spatial.footprint(sample,'root'),'previous footprint shown');
 const active=apply(sampleState,adoption);
 yes(Spatial.physicalProfiles(active.snapshot),'explicit policy');
 eq(active.snapshot.cubbies,sample.cubbies,'all interiors and supported positions unchanged');
 eq(active.snapshot.spatial.shelves,sample.spatial.shelves,'adoption anchors unchanged');
 eq(Core.owners(active.snapshot),Core.owners(sample),'owners unchanged');
 eq(Spatial.appPlacements(active.snapshot),Spatial.appPlacements(sample),'app placement unchanged');
 eq(Spatial.footprint(active.snapshot,'root'),proposal.profileAdoption.shelves.root.box,'preview and active footprint agree');
 eq(Core.undo(active).snapshot,sample,'exact adoption Undo');
 eq(Checkpoint.encode(Core.undo(active),view),oldSave,'Undo returns exact v3');
 const activeSave=Checkpoint.encode(active,view);
 eq(JSON.parse(activeSave).version,4,'active writer v4');
 eq(Checkpoint.decode(activeSave),{snapshot:active.snapshot,view},'v4 exact checkpoint');
 eq(Checkpoint.decode(oldSave).snapshot,sample,'old v3 never expands');
 for(const v of [2,3]){
  const mislabeled=JSON.parse(activeSave);mislabeled.version=v;
  let failed=false;try{Checkpoint.decode(JSON.stringify(mislabeled));}catch(e){failed=true;}yes(failed,'reject mislabeled active checkpoint');
 }
 const unmarked=JSON.parse(activeSave);delete unmarked.snapshot.spatial.geometryPolicy;
 let failed=false;try{Checkpoint.decode(JSON.stringify(unmarked));}catch(e){failed=true;}yes(failed,'reject unmarked v4');
 const unknown=Core.clone(active.snapshot);unknown.spatial.geometryPolicy='unknown';invalid(unknown,'unknown geometry policy');
 refuse(active,adoption);
 for(const specimen of [tight,adjacent,doorway]){
  const state=Core.session(specimen),preview=Core.previewStructure(state,adoption);
  refuse(state,adoption);yes(!preview.profileAdoption.ok,'adoption conflict report');
  const rejected=Core.applyStructure(state,preview);eq(rejected.snapshot,specimen,'invalid adoption Apply isolated');eq(rejected.history,state.history,'invalid adoption no Undo');
 }
 const crossing=Core.clone(doorway);crossing.spatial.shelves.root.x++;
 const crossReport=Architecture.inspectProfileLayout(crossing);
 yes(crossReport.conflicts.some(x=>x.kind==='wall')&&crossReport.conflicts.some(x=>x.kind==='door'),'crossed wall and door both reported');
 const near=Core.clone(doorway);near.spatial.shelves.root.x--;
 const nearState=apply(Core.session(near),adoption);
 refuse(nearState,{kind:'spatialShelfEdit',containerId:'root',patch:{x:doorway.spatial.shelves.root.x}});
 refuse(nearState,{kind:'spatialAppearance',containerId:'root',patch:{profile:'pilaster'}});
 for(const profile of Spatial.shelfProfiles){
  const changed=apply(active,{kind:'spatialAppearance',containerId:'root',patch:{profile}});
  const g=Spatial.shelfGeometry(changed.snapshot,'root');
  eq(Spatial.footprint(changed.snapshot,'root').w,g.w,'profile authoritative width');
  eq(changed.snapshot.cubbies.root.mods,sample.cubbies.root.mods,'profile keeps fixtures');
  eq(Core.undo(changed).snapshot,active.snapshot,'profile exact Undo');
 }
 const tall=apply(active,{kind:'spatialShelfEdit',containerId:'root',patch:{h:1060,depth:170}});
 eq(tall.snapshot.cubbies.root.mods,sample.cubbies.root.mods,'height edit retains interior-local coordinates');
 eq(Spatial.footprint(tall.snapshot,'root').h,170,'depth independently updates footprint');
 const turnRoom=active.snapshot.spatial.shelves.root.roomId;
 const roomy=apply(active,{kind:'spatialRoomEdit',roomId:turnRoom,patch:{h:2000}});
 const centered=apply(roomy,{kind:'spatialShelfEdit',containerId:'root',patch:{y:900}});
 for(const start of [roomy,centered]){
  const beforeBox=Spatial.footprint(start.snapshot,'root');
  const turned=apply(start,{kind:'spatialShelfTurn',containerId:'root',patch:{orientation:90}});
  const afterBox=Spatial.footprint(turned.snapshot,'root');
  eq(afterBox.w,beforeBox.h,'turn exchanges depth and width');
  yes(Math.abs(afterBox.x+afterBox.w/2-beforeBox.x-beforeBox.w/2)<=.5,'turn keeps x center to whole unit');
  if(start===roomy)eq(afterBox.y,0,'near-wall minimal inward translation');
  else yes(Math.abs(afterBox.y+afterBox.h/2-beforeBox.y-beforeBox.h/2)<=.5,'turn keeps y center to whole unit');
  eq(Core.undo(turned).snapshot,start.snapshot,'turn exact Undo');
  eq(turned.snapshot.cubbies,start.snapshot.cubbies,'turn does not move contents');
 }
 const fraction=Core.clone(sample);fraction.cubbies.root.b=12.25;
 eq(Core.validate(fraction),null,'fractional base valid');
 const fractional=apply(Core.session(fraction),adoption);
 eq(fractional.snapshot.cubbies,fraction.cubbies,'fractional adoption exact');
 eq(Checkpoint.decode(Checkpoint.encode(fractional,view)).snapshot,fractional.snapshot,'fractional v4 roundtrip');
 }
 {
 const state=apply(sampleState,{kind:'spatialAdoptProfiles'}),s=state.snapshot;
 const roomId=s.spatial.shelves.root.roomId;
 const plan=View.roomPlan(s,roomId),item=plan.shelves.find(v=>v.id==='root');
 eq(View.roomPlan(sample,roomId),null,'legacy snapshot does not pretend to have active plan');
 eq(item.box,Spatial.footprint(s,'root'),'plan uses authoritative footprint');
 const b=item.box;
 eq(View.roomPlanHit(plan,b.x+b.w/2,b.y+b.h/2),'root','plan hit actual footprint');
 eq(View.roomPlanHit(plan,b.x+b.w,b.y+b.h/2),'','exclusive far edge');
 const envelope=View.frontEnvelope(s,'root',s.cubbies.root);
 eq(envelope,Spatial.shelfGeometry(s,'root'),'front uses actual shared profile');
 const camera=View.fitEnvelope(envelope,1200,700,1,{x:0,y:0});
 yes(camera.x>=15.999&&camera.y>=15.999,'shared front fits actual envelope');
 eq(View.frontEnvelope(sample,'root',sample.cubbies.root).w,Spatial.exterior(sample.cubbies.root).w,'legacy front unchanged');
 const roomy=apply(state,{kind:'spatialRoomEdit',roomId,patch:{h:2000}});
 const rotated=apply(roomy,{kind:'spatialShelfTurn',containerId:'root',patch:{orientation:90}});
 const rp=View.roomPlan(rotated.snapshot,roomId),rb=rp.shelves.find(v=>v.id==='root').box;
 eq(rb,Spatial.footprint(rotated.snapshot,'root'),'rotated plan authoritative');
 eq(View.roomPlanHit(rp,rb.x+rb.w/2,rb.y+rb.h/2),'root','rotated glyph hit');
 const nearDoor=Core.clone(doorway);nearDoor.spatial.shelves.root.x--;
 const doorsActive=apply(Core.session(nearDoor),{kind:'spatialAdoptProfiles'}).snapshot;
 for(const opening of Spatial.doorGeometry(doorsActive,d1).openings){
  const actual=View.roomPlan(doorsActive,opening.roomId).openings.find(o=>o.id===d1);
  eq(actual,Object.assign({id:d1},opening),'two-sided plan opening shared record');
 }
 }
 {
 const active=apply(sampleState,{kind:'spatialAdoptProfiles'}),s=active.snapshot,roomId=s.spatial.shelves.root.roomId;
 const before=JSON.stringify(s),plan=View.roomPlan(s,roomId),mesh=Projection.roomMesh(s,roomId,plan.openings);
 const scene=Projection.projectedScene(mesh,1200,750),fr=scene.frame;
 for(const q of [[0,0],[plan.room.w,0],[0,plan.room.h],[plan.room.w,plan.room.h],[plan.room.w*.37,plan.room.h*.64]]){
  const pt=Projection.project([q[0],q[1],0],fr),inv=Projection.floorInverse(pt[0],pt[1],fr);
  yes(Math.abs(inv.x-q[0])<1e-7&&Math.abs(inv.y-q[1])<1e-7,'floor inverse roundtrip');
 }
 for(const face of scene.faces)for(const q of face.points)
  yes(q.every(Number.isFinite)&&q[0]>=31.99&&q[0]<=1168.01&&q[1]>=49.99&&q[1]<=700.01,'actual volume fits perspective viewport');
 for(const profile of Spatial.shelfProfiles)for(const orientation of [0,90,180,270]){
  const g=Architecture.shelfGeometry({w:700.5,h:1500,b:11.25},profile,75),p={x:0,y:0,orientation};
  const surfaces=Projection.shelfSurfaces(g,p,'synthetic'),box=Architecture.profileFootprint(g,p);
  for(const part of g.parts){
   const actual=surfaces.find(f=>f.side==='front'&&f.role===part.role&&JSON.stringify(f.points)===JSON.stringify(part.points.map(q=>Architecture.frontPoint(g,p,q[0],q[1]))));
   yes(actual,'exact shared frontal polygon');
  }
  const fr=Projection.frame({w:box.w,h:box.h},g.h,900,700);
  for(const surface of surfaces)for(const q of surface.points){
   yes(q[0]>=-1e-8&&q[0]<=box.w+1e-8&&q[1]>=-1e-8&&q[1]<=box.h+1e-8&&q[2]>=-1e-8&&q[2]<=g.h+1e-8,'volume bounded by actual envelope');
   const pt=Projection.project(q,fr);yes(pt&&pt.every(Number.isFinite),'tall shallow case before near plane');
  }
 }
 const visible=scene.faces.find(f=>{
  if(!f.shelfId)return false;
  const x=f.points.reduce((n,p)=>n+p[0],0)/f.points.length,y=f.points.reduce((n,p)=>n+p[1],0)/f.points.length;
  return Projection.faceAt(scene,x,y)===f;
 });
 yes(visible,'visible surface pickable');
 const x=visible.points.reduce((n,p)=>n+p[0],0)/visible.points.length,y=visible.points.reduce((n,p)=>n+p[1],0)/visible.points.length;
 eq(View.roomPerspectiveHit(scene,x,y),visible.shelfId,'hit matches painted surface');
 const nearDoor=Core.clone(doorway);nearDoor.spatial.shelves.root.x--;
 const ds=apply(Core.session(nearDoor),{kind:'spatialAdoptProfiles'}).snapshot;
 for(const o of Spatial.doorGeometry(ds,d1).openings){
  const dp=View.roomPlan(ds,o.roomId),dm=Projection.roomMesh(ds,o.roomId,dp.openings);
  yes(!dm.segments.some(v=>v.side===o.side&&v.start<o.end&&v.end>o.start),'actual shared opening omitted from wall mesh');
 }
 eq(JSON.stringify(s),before,'perspective view never mutates snapshot');
 }
 {
 const active=apply(sampleState,{kind:'spatialAdoptProfiles'}),s=active.snapshot,roomId=s.spatial.shelves.root.roomId;
 const roomy=apply(active,{kind:'spatialRoomEdit',roomId,patch:{w:1800,h:2000}}),ss=roomy.snapshot,orig=Core.clone(ss);
 for(const orientation of [0,90,180,270]){
  const st=orientation===0?roomy:apply(roomy,{kind:'spatialShelfEdit',containerId:'root',patch:{orientation}}),v=st.snapshot;
  const plan=View.roomPlan(v,roomId),scene=View.roomPerspective(v,plan,1200,700);
  for(const mapping of [{x:30,y:45,scale:.5},{frame:scene.frame}]){
   const proj=(x,y)=>mapping.frame?Projection.project([x,y,0],mapping.frame):[mapping.x+x*mapping.scale,mapping.y+y*mapping.scale];
   const q=proj(100,100),r=proj(137,163),start=View.roomFloorAt(mapping,q[0],q[1]),end=View.roomFloorAt(mapping,r[0],r[1]);
   const move=View.roomGesture(v,'root','move',start,mapping),patch=View.roomGesturePatch(move,end,true,20);
   eq(patch,{x:move.attachment.x+40,y:move.attachment.y+60},'relative snapped move in both projections');
   const moved=apply(st,{kind:'spatialShelfEdit',containerId:'root',patch});
   eq(moved.snapshot.cubbies,v.cubbies,'move retains every interior');
   eq(Core.undo(moved).snapshot,v,'move exact Undo');
   const resize=View.roomGesture(v,'root','resize',start,mapping),edit=View.roomGesturePatch(resize,end,false,20);
   eq(edit,{w:resize.w+(orientation%180?63:37),depth:resize.attachment.depth+(orientation%180?37:63)},'cardinal independent resize axes');
   const sized=apply(st,{kind:'spatialShelfEdit',containerId:'root',patch:edit});
   eq(View.roomEditOutline(v,'root',edit),Spatial.footprint(sized.snapshot,'root'),'outline matches validated envelope');
   eq(sized.snapshot.cubbies.root.mods,v.cubbies.root.mods,'resize preserves fixtures');
   eq(Core.undo(sized).snapshot,v,'resize exact Undo');
   eq(View.roomGesturePatch(resize,start,false,20),{},'no motion no edit');
  }
 }
 refuse(roomy,{kind:'spatialShelfEdit',containerId:'root',patch:{x:-1}});
 refuse(roomy,{kind:'spatialShelfEdit',containerId:'root',patch:{h:100}});
 refuse(roomy,{kind:'spatialShelfEdit',containerId:'root',patch:{w:null}});
 eq(View.roomEditOutline(ss,'root',{w:null}),null,'invalid numeric outline withheld');
 eq(ss,orig,'gesture adapters never mutate committed model');
 }
 {
 const active=apply(sampleState,{kind:'spatialAdoptProfiles'}),roomId=active.snapshot.spatial.shelves.root.roomId;
 const roomy=apply(active,{kind:'spatialRoomEdit',roomId,patch:{w:1800,h:2000}});
 for(const profile of Spatial.shelfProfiles)for(const orientation of [0,90,180,270]){
  const styled=apply(roomy,{kind:'spatialAppearance',containerId:'root',patch:{profile}});
  const resized=apply(styled,{kind:'spatialShelfEdit',containerId:'root',patch:{w:1450,h:1100,depth:185,orientation}});
  const s=resized.snapshot,before=Core.clone(s),g=Spatial.shelfGeometry(s,'root'),p=s.spatial.shelves.root;
  const plan=View.roomPlan(s,roomId),scene=View.roomPerspective(s,plan,1200,720),dest=View.fitEnvelope(g,1200,678,1.15,{x:12,y:-9});
  for(const mapping of [{x:30,y:40,scale:.35},{frame:scene.frame}]){
   const n=Transition.capture(s,'root',mapping,dest);
   yes(n&&n.id==='root','capture actual selected Shelf');
   for(const q of [[0,g.depth,0],[g.w,g.depth,g.h],[g.aperture.x,g.depth,g.h-g.aperture.y]]){
    const world=Architecture.planPoint(g,p,q[0],q[1]),start=Transition.point(n,q,0),end=Transition.point(n,q,1);
    const expected=mapping.frame?Projection.project([world[0],world[1],q[2]],mapping.frame):[mapping.x+world[0]*mapping.scale,mapping.y+world[1]*mapping.scale];
    eq(start.slice(0,2),expected.slice(0,2),'exact initial projection');
    eq(end.slice(0,2),[dest.x+q[0]*dest.scale,dest.y+(g.h-q[2])*dest.scale],'exact live frontal endpoint');
    for(const time of [.1,.3,.5,.7,.9])yes(Transition.point(n,q,time).every(Number.isFinite),'finite transition intermediate');
   }
   for(const time of [.25,.5,.75])yes(Transition.surfaces(n,time).length>0,'visible transition shell');
   for(const time of [.60,.65,.699]){
    const a=Transition.point(n,[0,g.depth,g.h],time),b=Transition.point(n,[g.w,g.depth,g.h],time),c=Transition.point(n,[0,g.depth,0],time);
    yes(Math.abs(a[1]-b[1])<1e-7&&Math.abs(a[0]-c[0])<1e-7,'flat carrier front aligned');
    yes(Math.abs((b[0]-a[0])/g.w-(c[1]-a[1])/g.h)<1e-7,'flat carrier uniform fit');
   }
   for(const time of [.70,.75,.90,1])for(const q of [[0,g.depth,g.h],[g.w,g.depth,0],[g.aperture.x,g.depth,g.h-g.aperture.y]])
    eq(Transition.point(n,q,time),Transition.point(n,q,1),'live reveal endpoint already exact');
  }
  eq(s,before,'navigation never changes contents or geometry');
 }
 eq(Transition.layers(0),{room:1,detail:0,shell:0,flat:false,live:false},'Room endpoint');
 eq(Transition.layers(1),{room:0,detail:1,shell:0,flat:false,live:true},'Shelf endpoint');
 for(let i=16;i<=100;i++){
  const p=i/100,l=Transition.layers(p);
  eq(l.shell+(l.flat?1:0)+(l.live?1:0),1,'exactly one opaque carrier after origin dissolve');
  if(!l.live)eq(l.detail,0,'no interior reveal before exact live endpoint');
 }
 }
 {
 // C03: synthetic crossing planes, coplanar accents and concave polygon.
 const flat=(index,shelfId,role,points)=>({index,shelfId,role,side:'front',points,plane:Projection.depthPlane(points)});
 const square=z=>[[0,0,z(0)],[16,0,z(16)],[16,16,z(16)],[0,16,z(0)]];
 const floor=[[0,0,0],[16,0,0],[16,16,0],[0,16,0]];
 const faces=[flat(0,'a','left-post',square(x=>.001+x*.0001)),flat(1,'b','backing',square(x=>.002-x*.0001))];
 const scene={faces,floor},r=Projection.visibility(scene,16,16);
 eq(Projection.rasterFaceAt(r,2,2).shelfId,'b','crossing planes near left');
 eq(Projection.rasterFaceAt(r,13,2).shelfId,'a','crossing planes near right');
 for(let y=0;y<16;y++)for(let x=0;x<16;x++)eq(Projection.rasterFaceAt(r,x+.5,y+.5),Projection.faceAt(scene,x+.5,y+.5),'raster and analytic half-open coverage');
 const accent=flat(2,'a','capital',square(x=>.001+x*.0001));
 const tied={faces:[faces[0],accent],floor},tieRaster=Projection.visibility(tied,16,16);
 eq(Projection.rasterFaceAt(tieRaster,7,7).role,'capital','coplanar accent wins');
 const concave=flat(0,'a','crest',[[0,0,1],[16,0,1],[16,16,1],[8,8,1],[0,16,1]]);
 const cr=Projection.visibility({faces:[concave],floor},16,16);
 yes(!Projection.rasterFaceAt(cr,8,14),'concave notch not filled');
 yes(Projection.rasterFaceAt(cr,3,4),'concave interior covered');
 // Canvas spans must reproduce every winning face/floor/empty pixel
 // exactly, without overlap or independent depth interpretation.
 for(const raster of [r,cr,tieRaster,Projection.visibility({faces:[],floor:[[2,2,0],[13,2,0],[13,13,0],[2,13,0]]},16,16)]){
  const rebuilt=new Int32Array(raster.w*raster.h);rebuilt.fill(-2);
  let count=0;
  eq(Projection.visibilityRuns(raster,(x,y,w,key)=>{
   count++;yes(Number.isInteger(x)&&Number.isInteger(y)&&Number.isInteger(w)&&w>0&&x>=0&&x+w<=raster.w&&y>=0&&y<raster.h,'valid draw span');
   for(let i=x;i<x+w;i++){eq(rebuilt[y*raster.w+i],-2,'draw span no overlap');rebuilt[y*raster.w+i]=key;}
  }),count,'draw span count');
  for(let i=0;i<rebuilt.length;i++)eq(rebuilt[i],raster.winners[i]>=0?raster.winners[i]:raster.floor[i]?-1:-2,'draw span exact raster ownership');
 }
 const tiny=Projection.visibility(scene,2000,1000,20000);
 yes(tiny.w*tiny.h<=20000,'bounded raster pixel allocation');
 const active=apply(sampleState,{kind:'spatialAdoptProfiles'}),roomId=active.snapshot.spatial.shelves.root.roomId;
 const roomy=apply(active,{kind:'spatialRoomEdit',roomId,patch:{w:1800,h:2000}});
 const other=Object.keys(roomy.snapshot.spatial.shelves).find(k=>k!=='root');
 for(const [x,y,points] of [[600,850,[[647.5,102.5],[292.5,132.5],[297.5,152.5]]],[1000,250,[[708,252],[708,260]]]]){
  const moved=apply(roomy,{kind:'spatialShelfEdit',containerId:other,patch:{roomId,x,y,depth:250,orientation:0}});
  const styled=apply(moved,{kind:'spatialAppearance',containerId:other,patch:{profile:'pilaster'}});
  const s=styled.snapshot,plan=View.roomPlan(s,roomId),sc=View.roomPerspective(s,plan,1000,700),r=Projection.visibility(sc,1000,700);
  for(const q of points){
   const nearest=Projection.faceAt(sc,q[0],q[1]);
   eq(nearest.shelfId,x===600?'root':other,'reproduced C03 nearest shelf');
   eq(nearest.role,x===600?'backing':'right-post','reproduced C03 nearest role');
   // Native logical pixels use half-open center sampling; the continuous
   // second wall sample is on a pixel whose center belongs to the wall.
   const center=Projection.faceAt(sc,Math.floor(q[0])+.5,Math.floor(q[1])+.5);
   eq(Projection.rasterFaceAt(r,q[0],q[1]),center,'C03 raster agrees with independently sampled center');
  }
  if(x===1000){
   eq(Projection.rasterFaceAt(r,708,252).shelfId,other,'first reported wall mismatch fixed in displayed pixel');
   eq(Projection.rasterFaceAt(r,707.5,260.5).shelfId,other,'second adjacent post pixel remains pickable');
  }
  eq(Core.validate(s),null,'depth correction preserves valid model');
 }
 }
 {
 const s=ShelfSample.roomFixture(),roomId=s.spatial.shelves.root.roomId,other=Object.keys(s.spatial.shelves).find(k=>k!=='root'&&k!=='sample-1-root');
 eq(Core.validate(s),null,'representative furnished Room valid');
 const plan=View.roomPlan(s,roomId),mesh=Projection.roomMesh(s,roomId,plan.openings);
 eq(plan.shelves.length,3,'three actual shelves');
 eq(plan.openings.length,1,'one actual shared opening');
 yes(!mesh.segments.some(v=>v.side==='east'&&v.start<650&&v.end>300),'opening no wall coverage');
 const b=Spatial.footprint(s,other);
 eq(b.w,250,'turned depth exact');
 for(const patch of [{x:1600},{y:100},{x:1550,y:400}]){
  const state=Core.session(s),before=Core.clone(s),preview=Core.previewStructure(state,{kind:'spatialShelfEdit',containerId:other,patch});
  yes(!preview.ok,'invalid wall/neighbor/door specimen');
  eq(state.snapshot,before,'invalid representative transaction isolated');
 }
 for(const orientation of [0,90,180,270]){
  const g=Spatial.shelfGeometry(s,other),surfaces=Projection.shelfSurfaces(g,{x:0,y:0,orientation},other);
  yes(surfaces.some(v=>v.surface==='top')&&surfaces.some(v=>v.surface==='side')&&surfaces.some(v=>v.surface==='bottom'),'actual solid face roles across cardinals');
 }
 }
 {
 const s=ShelfSample.roomFixture(),before=Core.clone(s),id=s.spatial.shelves.root.roomId,plan=View.roomPlan(s,id),g=Spatial.shelfGeometry(s,'root');
 const base=Projection.roomMesh(s,id,plan.openings),baseline=Projection.projectedScene(base,1366,756);
 const plainFit=Projection.projectedScene(Projection.roomMesh(s,id,plan.openings,{occupiedFit:true}),1366,756);
 yes(plainFit.frame.scale>=baseline.frame.scale-1e-9,'occupied fit never smaller at same geometry');
 for(const ratio of [1.2,1.6]){
  const far=g.h*ratio,opts={farWall:far,occupiedFit:true,wallBands:true};
  const mesh=Projection.roomMesh(s,id,plan.openings,opts);
  eq(mesh.maxHeight,base.maxHeight,'Shelf heights unchanged');
  eq(mesh.wallTop,far,'independent absolute wall height');
  eq(mesh.faces.filter(f=>f.shelfId),base.faces.filter(f=>f.shelfId),'all Shelf faces unchanged');
  eq(mesh.segments,base.segments,'shared openings unchanged');
  for(const face of mesh.faces.filter(f=>!f.shelfId)){
   const z=Math.max(...face.points.map(p=>p[2]));
   yes(z<=(face.side==='north'||face.side==='east'?far:far*12/125)+1e-7,'wall band within chosen height');
   if(face.side==='east')yes(!(Math.min(...face.points.map(p=>p[1]))<650&&Math.max(...face.points.map(p=>p[1]))>300),'bands do not span doorway');
  }
  for(const [w,h] of [[1366,756],[740,725]]){
   const sc=Projection.projectedScene(mesh,w,h),f=sc.frame;
   for(const q of sc.floor.concat(...sc.faces.map(v=>v.points)))yes(q.every(Number.isFinite)&&q[2]>0&&q[0]>=32-1e-6&&q[0]<=w-32+1e-6&&q[1]>=50-1e-6&&q[1]<=h-50+1e-6,'visible occupied vertex fits and positive depth');
   const q=Projection.project([900,1000,0],f),round=Projection.floorInverse(q[0],q[1],f);
   yes(Math.abs(round.x-900)<1e-7&&Math.abs(round.y-1000)<1e-7,'comparison floor inverse exact');
  }
 }
 // Synthetic projection-only empty/outlier variants, not checkpoint edits.
 const empty=Core.clone(s);for(const k of Object.keys(empty.spatial.shelves))if(empty.spatial.shelves[k].roomId===id)delete empty.spatial.shelves[k];
 const opts={farWall:1300,occupiedFit:true,wallBands:true};
 const emptyMesh=Projection.roomMesh(empty,id,plan.openings,opts);
 eq(emptyMesh.maxHeight,0,'empty comparison room');
 eq(emptyMesh.wallTop,1300,'empty comparison independent wall');
 yes(Projection.projectedScene(emptyMesh,740,725).faces.length>0,'empty wall and floor fit');
 const tall=Core.clone(s);tall.cubbies.root.h=2500;
 const tallMesh=Projection.roomMesh(tall,id,plan.openings,opts);
 eq(tallMesh.wallTop,1300,'taller outlier leaves independent wall unchanged');
 yes(tallMesh.maxHeight>2500&&Projection.projectedScene(tallMesh,740,725).faces.every(f=>f.points.every(q=>q[2]>0)),'tall outlier near plane protected');
 eq(s,before,'comparison never mutates snapshot');
 }
 {
 const s=ShelfSample.roomFixture(),state=Core.session(s),view={path:['root'],theme:1,cameras:{},roomPerspective:true},cmd={kind:'spatialAdoptIndependentProfiles'};
 const before=Core.clone(s),old=Checkpoint.encode(state,view),proposal=Core.previewStructure(state,cmd);
 yes(proposal.ok,proposal.error);yes(proposal.profileAdoption.ok,'independent adoption report');
 const active=apply(state,cmd),v=active.snapshot,id=v.spatial.shelves.root.roomId;
 eq(v.spatial.geometryPolicy,'profile-v2','new policy');
 eq(v.spatial.shelves.root.frameBasis,24,'reference basis');eq(v.spatial.rooms[id].wallHeight,1339.2,'absolute height');
 eq(v.cubbies,s.cubbies,'unchanged interior and contents');eq(v.caseItems,s.caseItems,'unchanged Case');
 eq(v.spatial.doors,s.spatial.doors,'unchanged doors');eq(v.spatial.apps,s.spatial.apps,'unchanged apps');
 eq(Spatial.shelfGeometry(v,'root').h,1182,'combined crest full height');
 eq(View.frontEnvelope(v,'root',v.cubbies.root),Spatial.shelfGeometry(v,'root'),'same front geometry');
 eq(Spatial.footprint(v,'root'),proposal.profileAdoption.shelves.root.box,'same preview envelope');
 const save=Checkpoint.encode(active,view);eq(JSON.parse(save).version,5,'v5 writer');eq(Checkpoint.decode(save),{snapshot:v,view},'v5 roundtrip');
 eq(JSON.parse(old).version,4,'v4 unchanged');eq(Checkpoint.decode(old).snapshot,s,'v4 preserved');
 eq(Core.undo(active).snapshot,before,'exact v4 Undo');
 const altered=Core.clone(proposal);altered.snapshot.spatial.shelves.root.frameBasis=25;
 yes(!!Core.applyStructure(state,altered).error,'altered adoption refused');
 const bad=JSON.parse(save);
 for(const version of [1,2,3,4]){bad.version=version;let refused=false;try{Checkpoint.decode(JSON.stringify(bad))}catch(e){refused=true}yes(refused,'wrong version refused');}
 for(const field of ['frameBasis','wallHeight']){
  const b=Core.clone(v);if(field==='frameBasis')delete b.spatial.shelves.root[field];else delete b.spatial.rooms[id][field];
  yes(!!Core.validate(b),'missing v2 required field refused');
 }
 const b=Core.clone(s);b.spatial.shelves.root.frameBasis=24;yes(!!Core.validate(b),'v4 unexpected v2 field refused');
 const enlarged=apply(active,{kind:'spatialShelfEdit',containerId:'root',patch:{h:1100}});
 eq(enlarged.snapshot.spatial.shelves.root.frameBasis,24,'resize retains seed');
 eq(enlarged.snapshot.spatial.rooms[id].wallHeight,1339.2,'resize never changes wall');
 const changed=apply(active,{kind:'spatialRoomEdit',roomId:id,patch:{wallHeight:1500}});
 eq(Spatial.shelfGeometry(changed.snapshot,'root'),Spatial.shelfGeometry(v,'root'),'wall height independent');
 refuse(active,{kind:'spatialRoomEdit',roomId:id,patch:{wallHeight:0}});
 refuse(active,{kind:'spatialShelfEdit',containerId:'root',patch:{frameBasis:41}});
 const plan=View.roomPlan(v,id),mesh=Projection.roomMesh(v,id,plan.openings);
 eq(mesh.wallTop,1339.2,'selected live wall height');yes(mesh.occupiedFit,'selected live occupied fit');
 for(const [w,h] of [[1366,756],[740,725]]){
  const sc=View.roomPerspective(v,plan,w,h);
  for(const q of sc.floor.concat(...sc.faces.map(f=>f.points)))yes(q[2]>0&&q[0]>=32-1e-6&&q[0]<=w-32+1e-6&&q[1]>=50-1e-6&&q[1]<=h-50+1e-6,'selected live fit bounds');
 }
 eq(s,before,'old state unchanged');
 }
 {
 const cmd={kind:'spatialAdoptIndependentProfiles'},s=ShelfSample.roomFixture(),id=s.spatial.shelves.root.roomId;
 // Valid v4 near-wall fixture becomes invalid only under the wider frame.
 const tight=Core.clone(s);
 const rootBox=Spatial.footprint(s,'root'),door=Object.values(s.spatial.doors)[0],east=door.b.roomId;
 const newWidth=Math.ceil(rootBox.x+rootBox.w);
 tight.spatial.rooms[id].w=newWidth;tight.spatial.rooms[east].x=newWidth;
 eq(Core.validate(tight),null,'v4 tight room valid');
 const ts=Core.session(tight),tp=Core.previewStructure(ts,cmd);
 yes(!tp.ok&&tp.profileAdoption.conflicts.some(c=>c.kind==='wall'&&c.shelfId==='root'),'v5 migration wall conflict');
 eq(Core.applyStructure(ts,tp).snapshot,tight,'wall refusal exact');
 eq(Core.applyStructure(ts,tp).history,ts.history,'wall refusal history exact');
 // Candidate crest reaches east boundary but old crest is clear.
 const blocked=Core.clone(s),g=Architecture.shelfGeometry(s.cubbies.root,'crest',s.spatial.shelves.root.depth,24);
 blocked.spatial.rooms[id].w=rootBox.x+g.w;
 blocked.spatial.rooms[east].x=blocked.spatial.rooms[id].w;
 blocked.spatial.doors[door.id].start=60;blocked.spatial.doors[door.id].end=120;
 eq(Core.validate(blocked),null,'v4 shared door clear');
 const bs=Core.session(blocked),bp=Core.previewStructure(bs,cmd);
 yes(!bp.ok&&bp.profileAdoption.conflicts.some(c=>c.kind==='door'&&c.doorId===door.id),'v5 migration door conflict');
 eq(Core.applyStructure(bs,bp).snapshot,blocked,'door refusal retains identities');
 eq(Core.applyStructure(bs,bp).revision,bs.revision,'door refusal revision unchanged');
 // Valid v3 direct adoption and old-version roundtrip.
 const legacySpatial=Core.clone(s);delete legacySpatial.spatial.geometryPolicy;
 eq(Core.validate(legacySpatial),null,'legacy furnished spatial valid');
 const ls=Core.session(legacySpatial),adopted=apply(ls,cmd);
 eq(Core.undo(adopted).snapshot,legacySpatial,'direct v3 to v5 exact undo');
 eq(Checkpoint.encode(Core.undo(adopted),view),Checkpoint.encode(ls,view),'direct undo exact v3 bytes');
 // Actual valid empty Room (already exists in furnished fixture), not a
 // projection-only clone with orphaned Cubby owners.
 const active=apply(Core.session(s),cmd),v=active.snapshot;
 const empty=Object.keys(v.spatial.rooms).find(k=>!Object.values(v.spatial.shelves).some(p=>p.roomId===k));
 yes(empty,'valid empty room present');
 const ep=View.roomPlan(v,empty),em=Projection.roomMesh(v,empty,ep.openings);
 eq(em.maxHeight,0,'empty live v5 room');eq(em.wallTop,1339.2,'empty independent height');
 const esc=View.roomPerspective(v,ep,740,725);
 yes(esc.faces.every(f=>!f.shelfId)&&esc.faces.length>0,'empty live room wall faces only');
 const tall=apply(active,{kind:'spatialShelfEdit',containerId:'root',patch:{h:1500}}),tv=tall.snapshot;
 const tallPlan=View.roomPlan(tv,id),tm=Projection.roomMesh(tv,id,tallPlan.openings);
 yes(tm.maxHeight>1500,'valid tall outlier not compressed');eq(tm.wallTop,1339.2,'tall wall independent');
 for(const [w,h] of [[740,725],[1366,756]]){
  const sc=View.roomPerspective(tv,tallPlan,w,h);
  for(const q of sc.floor.concat(...sc.faces.map(f=>f.points)))yes(q[2]>0&&q[0]>=32-1e-6&&q[0]<=w-32+1e-6&&q[1]>=50-1e-6&&q[1]<=h-50+1e-6,'live tall outlier fits');
  const q=Projection.project([900,1000,0],sc.frame),inverse=Projection.floorInverse(q[0],q[1],sc.frame);
  yes(Math.abs(inverse.x-900)<1e-7&&Math.abs(inverse.y-1000)<1e-7,'live inverse roundtrip');
 }
 const roomNew=apply(active,{kind:'spatialRoomCreate',patch:{name:'Empty new Room',x:8000,y:0,w:1000,h:1000}});
 const newId=Object.keys(roomNew.snapshot.spatial.rooms).find(k=>!v.spatial.rooms[k]);
 eq(roomNew.snapshot.spatial.rooms[newId].wallHeight,1339.2,'new v2 Room default absolute');
 const shelfNew=apply(roomNew,{kind:'spatialShelfCreate',roomId:newId,patch:{x:50,y:50,w:700,h:500}});
 const newShelf=Object.keys(shelfNew.snapshot.spatial.shelves).find(k=>!v.spatial.shelves[k]);
 eq(shelfNew.snapshot.spatial.shelves[newShelf].frameBasis,Spatial.frameSeed(shelfNew.snapshot.cubbies[newShelf]),'new Shelf seeded once');
 for(const c of [{w:1400,h:1050},{w:300,h:1500},{w:1800,h:300},{w:1800,h:1500},{w:130,h:100}]){
  const basis=Spatial.frameSeed(c);yes(basis>=4&&basis<=40,'bounded seed across aspect ratios');
  const g=Architecture.shelfGeometry(Object.assign({b:12},c),'crest',160,basis);
  eq([g.aperture.w,g.aperture.h],[c.w,c.h],'seed preserves interior');
 }
 }
 {
 // N4a: one atlas projection, exact shared openings and occupied footprints.
 const state=apply(Core.session(ShelfSample.roomFixture()),{kind:'spatialAdoptIndependentProfiles'}),s=state.snapshot,before=Core.clone(s);
 const map=View.mapPlan(s),id=s.spatial.shelves.root.roomId,room=s.spatial.rooms[id],root=Spatial.footprint(s,'root');
 const item=map.rooms.find(r=>r.id===id).shelves.find(v=>v.id==='root');
 eq(item.box,{x:room.x+root.x,y:room.y+root.y,w:root.w,h:root.h},'atlas uses authoritative occupied footprint');
 for(const d of map.doors)eq(d,Object.assign({id:d.id},Spatial.doorGeometry(s,d.id)),'atlas same shared opening');
 const empty=map.rooms.find(r=>!r.shelves.length);yes(empty,'empty atlas Room selectable');
 for(const [w,h] of [[1366,756],[740,725]])for(const z of [1,.5,4]){
  const f=View.mapFrame(map,w,h,z),x=empty.x+empty.w/2,y=empty.y+empty.h/2;
  const world=View.mapAt(f,f.x+x*f.scale,f.y+y*f.scale);
  yes(Math.abs(world.x-x)<1e-7&&Math.abs(world.y-y)<1e-7,'atlas mapping roundtrip');
  eq(View.mapRoomHit(map,world.x,world.y),empty.id,'empty room hit');
 }
 eq(View.mapRoomHit(map,room.x+room.w,room.y+10),empty.id,'shared boundary half-open selection');
 eq(s,before,'atlas never mutates arrangement');
 // Owner requirement: both wall faces block creation and editing; the
 // actual architectural footprint (not aperture or miniature glyph) counts.
 const door=Object.values(s.spatial.doors)[0],east=door.b.roomId;
 const onA=apply(state,{kind:'spatialShelfEdit',containerId:'root',patch:{x:room.w-root.w}});
 refuse(onA,{kind:'spatialDoorCreate',patch:{a:door.a,b:door.b,start:60,end:120}});
 refuse(onA,{kind:'spatialDoorEdit',doorId:door.id,patch:{start:60,end:120}});
 const onB=apply(state,{kind:'spatialShelfCreate',roomId:east,patch:{x:0,y:50,w:700,h:500,depth:160,orientation:0}});
 refuse(onB,{kind:'spatialDoorCreate',patch:{a:door.b,b:door.a,start:60,end:120}});
 refuse(onB,{kind:'spatialDoorEdit',doorId:door.id,patch:{start:60,end:120}});
 eq(Core.validate(onA.snapshot),null,'wall Shelf with unobstructed original doorway remains valid');
 eq(Core.validate(onB.snapshot),null,'opposite wall Shelf with unobstructed original doorway remains valid');
 }
 {
  // N4b: direct and exact Room changes share the authoritative transaction.
  const state=apply(Core.session(ShelfSample.roomFixture()),{kind:'spatialAdoptIndependentProfiles'}),s=state.snapshot;
  const data=View.mapPlan(s),empty=data.rooms.find(r=>!r.shelves.length),filled=data.rooms.find(r=>r.shelves.length),door=Object.keys(s.spatial.doors)[0];
  const draft=View.mapRoomDraft(data),create=apply(state,{kind:'spatialRoomCreate',patch:draft});
  const id=Object.keys(create.snapshot.spatial.rooms).find(k=>!s.spatial.rooms[k]);
  eq(Core.undo(create).snapshot,s,'room creation exact Undo');
  const rename=apply(create,{kind:'spatialRoomEdit',roomId:id,patch:{name:'Reading Room'}});
  eq(rename.snapshot.spatial.rooms[id].name,'Reading Room','exact rename');
  eq(rename.snapshot.cubbies,s.cubbies,'no contents change');
  const del=apply(rename,{kind:'spatialRoomDelete',roomId:id});
  eq(Core.undo(del).snapshot,rename.snapshot,'empty deletion exact Undo');
  refuse(state,{kind:'spatialRoomDelete',roomId:filled.id});
  refuse(state,{kind:'spatialRoomEdit',roomId:filled.id,patch:{w:130,h:100}});
  const cmd={kind:'spatialRoomEdit',roomId:empty.id,patch:{x:empty.x+200}};
  eq(View.mapRoomLostDoors(s,cmd),[door],'exact lost doorway list');
  refuse(state,cmd);
  const separated=apply(state,Object.assign({},cmd,{removeDoors:[door]}));
  eq(separated.snapshot.cubbies,s.cubbies,'separation keeps contents');
  eq(separated.snapshot.spatial.shelves,s.spatial.shelves,'separation keeps local attachments');
  eq(Core.undo(separated).snapshot,s,'separation exact Undo');
  eq(View.mapRoomLostDoors(s,{kind:'spatialRoomDelete',roomId:empty.id}),[door],'empty deletion reports openings');
  refuse(state,{kind:'spatialRoomDelete',roomId:empty.id});
  const deleted=apply(state,{kind:'spatialRoomDelete',roomId:empty.id,removeDoors:[door]});
  eq(Core.undo(deleted).snapshot,s,'door removal and Room deletion one Undo');
  const f=View.mapFrame(data,1366,756,1),x=f.x+(empty.x+50)*f.scale,y=f.y+(empty.y+50)*f.scale;
  const g=View.mapRoomGesture(data,empty.id,'move',f,x,y);
  eq(View.mapRoomGesturePatch(g,x+37*f.scale,y+11*f.scale,true,20,false),{x:empty.x+40,y:empty.y+20},'relative snap');
  eq(View.mapRoomGesturePatch(g,x+37*f.scale,y+11*f.scale,false,20,false),{x:empty.x+37,y:empty.y+11},'free whole units');
  const resize=View.mapRoomGesture(data,empty.id,'resize',f,x,y);
  eq(View.mapRoomGesturePatch(resize,x+37*f.scale,y+11*f.scale,true,20,false),{w:empty.w+40,h:empty.h+20},'relative resize');
  eq(View.mapRoomGesturePatch(g,x,y,true,20,true),{},'no displacement does not magnetically move');
  eq(View.mapRoomGesturePatch(g,x+6*f.scale,y,false,20,true),{x:empty.x,y:empty.y},'near wall magnet');
  eq(View.mapRoomOutline(s,cmd),{x:empty.x+200,y:empty.y,w:empty.w,h:empty.h},'uncommitted outline');
  refuse(state,{kind:'spatialRoomEdit',roomId:empty.id,patch:{x:100001}});
  refuse(state,{kind:'spatialRoomEdit',roomId:empty.id,patch:{w:10001}});
  refuse(state,{kind:'spatialRoomEdit',roomId:empty.id,patch:{x:filled.x,y:filled.y},removeDoors:[door]});
  eq(View.mapRoomOutline(s,{kind:'spatialRoomEdit',roomId:empty.id,patch:{x:100001}}),null,'bounded outline');
  eq(View.mapRoomOutline(s,{kind:'spatialRoomEdit',roomId:empty.id,patch:{w:0}}),null,'no negative outline');
 }
 {
  // N4c: exact integer spans on both wall faces, all orientations and
  // fractional occupied extents. No duplicated geometry/ownership solver.
  const a={id:'a',x:0,y:0,w:1000,h:1000};
  for(const side of ['north','east','south','west']){
   const vertical=side==='east'||side==='west',op={north:'south',south:'north',east:'west',west:'east'}[side];
   const b={id:'b',x:side==='east'?1000:side==='west'?-1000:0,y:side==='south'?1000:side==='north'?-1000:0,w:1000,h:1000};
   const ar={roomId:'a',side},br={roomId:'b',side:op};
   function box(side,lo,len){
    return side==='north'?{x:lo,y:0,w:len,h:80}:side==='south'?{x:lo,y:920,w:len,h:80}:side==='west'?{x:0,y:lo,w:80,h:len}:{x:920,y:lo,w:80,h:len};
   }
   const boxes={p:box(side,200.25,99.5),q:box(op,500,100),interior:{x:400,y:400,w:50,h:50}};
   const s={spatial:{rooms:{a,b},shelves:{p:{roomId:'a'},q:{roomId:'b'},interior:{roomId:'a'}},doors:{}}};
   const fp=(_,id)=>boxes[id];
   const d={id:'d',a:ar,b:br,start:320,end:420};s.spatial.doors.d=d;
   eq(Doors.clearSpans(s,ar,br,fp),[{start:0,end:200},{start:300,end:320},{start:420,end:500},{start:600,end:1000}],'both faces, rounded outward '+side);
   eq(Doors.clearSpans(s,ar,br,fp,'d'),[{start:0,end:200},{start:300,end:500},{start:600,end:1000}],'exclude current '+side);
   const g=Doors.geometry(s,d,fp),span=Doors.doorEditSpan(s,d,fp);
   eq(span,{start:300,end:500},'contiguous selected '+side);
   eq(Doors.gesturePatch(g,span,0,'move',1000),{start:400,end:500},'no jump forward '+side);
   eq(Doors.gesturePatch(g,span,0,'move',-1000),{start:300,end:400},'no jump backward '+side);
   eq(Doors.gesturePatch(g,span,0,'start',1000),{start:419,end:420},'positive interval '+side);
   eq(Doors.gesturePatch(g,span,0,'end',1000),{start:320,end:500},'end clamps '+side);
   eq(Doors.geometry(s,{id:'touch',a:ar,b:br,start:100,end:200},fp).vertical,vertical,'exact boundary allowed '+side);
   let blocked=false;try{Doors.geometry(s,{id:'bad',a:ar,b:br,start:199,end:201},fp)}catch(e){blocked=true}
   yes(blocked,'fractional footprint blocked '+side);
   const adjacent=Doors.adjacentPairs(s,'a',fp);
   eq(adjacent.length,1,'only opposing real neighbor '+side);
  }
  const state=apply(Core.session(ShelfSample.roomFixture()),{kind:'spatialAdoptIndependentProfiles'}),s=state.snapshot;
  const d=Object.values(s.spatial.doors)[0],root=s.spatial.rooms[d.a.roomId],b=Spatial.footprint(s,'root');
  const blocked=apply(state,{kind:'spatialShelfEdit',containerId:'root',patch:{x:root.w-b.w}});
  const spans=Doors.clearSpans(blocked.snapshot,d.a,d.b,Spatial.footprint,d.id);
  const geom=Spatial.doorGeometry(blocked.snapshot,d.id),span=Doors.doorEditSpan(blocked.snapshot,d,Spatial.footprint);
  yes(spans.length&&span.start<=geom.start&&span.end>=geom.end,'actual profile span');
  const suggestions=View.mapDoorSuggestions(blocked.snapshot,d.a.roomId);
  yes(suggestions.length,'actual profile suggestions');
  for(const q of suggestions)yes(Core.previewStructure(blocked,{kind:'spatialDoorCreate',patch:q.patch}).ok,'suggestion uses real validator');
  const data=View.mapPlan(blocked.snapshot),f=View.mapFrame(data,1366,756),mid=(geom.start+geom.end)/2;
  const x=f.x+geom.line*f.scale,y=f.y+mid*f.scale;
  eq(View.mapDoorHit(data,f,x,y),d.id,'actual map doorway hit');
  const gesture=View.mapDoorGesture(blocked.snapshot,d.id,'move',f,x,y);
  const patch=View.mapDoorGesturePatch(gesture,x,y+10000*f.scale,false,20);
  const preview=Core.previewStructure(blocked,{kind:'spatialDoorEdit',doorId:d.id,patch});
  yes(preview.ok||!preview.error,'clamped actual gesture remains valid or no-op');
  // A different existing opening is a blocker, even if a destination beyond
  // it is clear. The authoritative edit rejects jumping, not only the UI.
  const other=apply(state,{kind:'spatialDoorCreate',patch:{a:d.a,b:d.b,start:700,end:800}});
  refuse(other,{kind:'spatialDoorEdit',doorId:d.id,patch:{start:850,end:950}});
  const contact=apply(other,{kind:'spatialDoorEdit',doorId:d.id,patch:{end:700}});
  const otherId=Object.keys(contact.snapshot.spatial.doors).find(k=>k!==d.id);
  eq(View.mapDoorMergeChoices(contact.snapshot,d.id),[otherId],'only contacting same pair');
  const merge=apply(contact,{kind:'spatialDoorMerge',doorId:d.id,patch:{otherId}});
  eq(Core.undo(merge).snapshot,contact.snapshot,'shared merge exact Undo');
 }
 {
  // N4d: fixed world field, bounded cached tile, exact decorative wall gaps.
  const state=apply(Core.session(ShelfSample.roomFixture()),{kind:'spatialAdoptIndependentProfiles'}),s=state.snapshot,data=View.mapPlan(s);
  const f=View.mapFrame(data,1366,745,1),spec=Terrain.contourSpec(f,1366,745,55);
  yes(spec&&spec.nx<=116&&spec.ny<=116,'bounded terrain tile');
  eq(Terrain.terrainHeight(-1200,800),Terrain.terrainHeight(-1200,800),'world field deterministic');
  const paths=Terrain.contourSegments(spec);
  yes(paths.segments>0&&paths.segments<=Terrain.contourBudget,'bounded contour segments');
  eq(Terrain.contourSegments(spec),paths,'deterministic contour geometry');
  eq(Terrain.contourSpec(f,1366,745,0),null,'density zero no work');
  const close=View.mapFrame(data,1366,745,4),fine=Terrain.contourSpec(close,1366,745,100);
  yes(fine.step<=spec.step&&fine.stride<=spec.stride,'closer contour LOD');
  const pan=Object.assign({},f,{x:f.x+.01});
  eq(Terrain.contourSpec(pan,1366,745,55).key,spec.key,'small pan cached tile');
  for(const r of data.rooms){
   for(const d of data.doors)for(const opening of d.openings.filter(o=>o.roomId===r.id)){
    const runs=View.mapWallRuns(data,r),line=r[opening.side==='north'||opening.side==='south'?'y':'x']+(opening.side==='south'?r.h:opening.side==='east'?r.w:0);
    yes(!runs.some(q=>q.vertical===d.vertical&&q.line===line&&q.start<d.end&&q.end>d.start),'no wall across shared opening');
   }
   for(const shelf of r.shelves){
    const original=Architecture.planGlyph(Spatial.shelfGeometry(s,shelf.id),s.spatial.shelves[shelf.id]);
    eq(shelf.glyph.front,original.front.map(q=>[q[0]+r.x,q[1]+r.y]),'map uses actual H glyph');
   }
  }
  eq(View.mapRoomDetail(data.rooms[0],f,1),false,'overview suppresses detail');
  yes(View.mapRoomDetail(data.rooms[0],close,4),'close detail');
 }
 {
  // N4e: compatible optional upper-layer view, exact validated identities,
  // bounded camera/focus state and unchanged structural format.
  const state=apply(Core.session(ShelfSample.roomFixture()),{kind:'spatialAdoptIndependentProfiles'}),s=state.snapshot,data=View.mapPlan(s);
  const r=data.rooms.find(r=>!r.shelves.length),door=data.doors[0];
  const base={zoom:1,center:null},target=View.mapFocusCamera(data,1366,745,'room',r.id),dTarget=View.mapFocusCamera(data,1366,745,'door',door.id);
  eq(target.center,{x:r.x+r.w/2,y:r.y+r.h/2},'room focus center');
  eq(dTarget.center,door.vertical?{x:door.line,y:(door.start+door.end)/2}:{x:(door.start+door.end)/2,y:door.line},'door focus center');
  eq(View.mapCameraCenter(1e12,-1e12),{x:1000000,y:-1000000},'bounded camera pan');
  const f=View.mapFrame(data,1366,745,1),to=View.mapFrame(data,1366,745,target.zoom,target.center);
  eq(View.mapTransitionFrame(f,to,0),f,'flight source');eq(View.mapTransitionFrame(f,to,1),to,'flight destination');
  const view={path:s.path.slice(),theme:1,cameras:{},mapView:{layer:'room',roomId:r.id,roomShelf:'',camera:target,selectedRoom:r.id,selectedDoor:'',focus:{kind:'door',id:door.id,base}}};
  const encoded=Checkpoint.encode(state,view);eq(JSON.parse(encoded).version,5,'no structural version bump');
  eq(Checkpoint.decode(encoded).view,view,'map layer/camera/focus exact roundtrip');
  eq(Checkpoint.decode(encoded).snapshot,s,'map metadata never arrangement');
  for(const mutate of [v=>v.mapView.roomId='missing',v=>v.mapView.camera.zoom=99,v=>v.mapView.camera.center={x:1e7,y:0},v=>v.mapView.focus.id='missing',v=>v.mapView.roomShelf='root',v=>v.mapView.selectedDoor='missing',v=>v.mapView.layer='unknown']){
   const bad=Core.clone(view);mutate(bad);let refused=false;try{Checkpoint.encode(state,bad)}catch(e){refused=true}yes(refused,'invalid upper view refused');
  }
  const legacyView=Core.clone(view);delete legacyView.mapView;eq(Checkpoint.decode(Checkpoint.encode(state,legacyView)).view,legacyView,'older upper field absent remains compatible');
 }
 {
  // N4f: multi-neighbor actual rotated profile footprints, exact gaps and
  // cross-domain transactions in the same committed synthetic snapshot.
  const state=Core.session(ShelfSample.mapFixture()),s=state.snapshot,hall=s.spatial.shelves.root.roomId;
  const south=Object.values(s.spatial.rooms).find(r=>r.name==='South Reading Room').id;
  const horizontal=Object.values(s.spatial.doors).filter(d=>d.a.roomId===hall&&d.a.side==='south'&&d.b.roomId===south);
  const d=horizontal[0],other=horizontal[1];
  eq(horizontal.length,2,'multiple openings same wall');
  eq(Doors.clearSpans(s,d.a,d.b,Spatial.footprint),[{start:0,end:100},{start:250,end:300},{start:450,end:500},{start:660,end:700},{start:860,end:900}],'rotated profiles obstruct both horizontal faces');
  for(const [start,end] of [[520,600],[730,800]])refuse(state,{kind:'spatialDoorCreate',patch:{a:d.a,b:d.b,start,end}});
  refuse(state,{kind:'spatialDoorEdit',doorId:other.id,patch:{start:670,end:695}});
  const boundary=apply(state,{kind:'spatialDoorCreate',patch:{a:d.a,b:d.b,start:450,end:500}});
  eq(Core.undo(boundary).snapshot,s,'exact occupied boundary and undo');
  const data=View.mapPlan(s),p=View.roomPlan(s,hall),q=View.roomPlan(s,south),geo=Spatial.doorGeometry(s,d.id);
  eq(p.openings.find(o=>o.id===d.id),Object.assign({id:d.id},geo.openings[0]),'first Room exact opening');
  eq(q.openings.find(o=>o.id===d.id),Object.assign({id:d.id},geo.openings[1]),'second Room exact opening');
  eq(Doors.adjacentPairs(s,hall,Spatial.footprint).filter(q=>q.a.side==='south').length,2,'two adjacent neighbors');
  const f=View.mapFrame(data,1366,745),r=data.rooms.find(q=>q.id===south),x=f.x+r.x*f.scale,y=f.y+r.y*f.scale;
  const nw=View.mapRoomGesture(data,south,'resize-nw',f,x,y);
  eq(View.mapRoomGesturePatch(nw,x+37*f.scale,y+11*f.scale,true,20,false),{x:r.x+40,w:r.w-40,y:r.y+20,h:r.h-20},'northwest relative resize');
  const east=View.mapRoomGesture(data,south,'resize-e',f,x,y);
  eq(View.mapRoomGesturePatch(east,x+37*f.scale,y+11*f.scale,true,20,false),{w:r.w+40},'edge resize preserves perpendicular dimension');
  const magnet=View.mapRoomGesture(data,south,'move',f,x,y);
  eq(View.mapRoomGesturePatch(magnet,x,y+6*f.scale,false,20,true),{x:r.x,y:r.y},'opposing wall magnet');
  eq(Core.validate(s),null,'multi-Room fixture valid');
 }
 {
  // N5a: same proposal/history; no publication of intermediate choices.
  const state=Core.session(ShelfSample.fixture()),s=state.snapshot,before=Core.clone(state),id='root';
  const opened=Core.beginAppearance(state,id);
  yes(opened.appearanceSession,'session marker');eq(opened.ok,false,'empty session no change');
  eq(opened.error,'','empty session valid');eq(opened.snapshot,s,'no seeded metadata');
  eq(Core.finishAppearance(state,opened),state,'unchanged dismissal exact');
  eq(Core.beginAppearance(state,'missing'),null,'missing target refused');
  let q=Core.updateAppearance(state,opened,'family','Astral');
  yes(q.ok,'live family preview');eq(q.revision,state.revision,'frozen revision');
  q=Core.updateAppearance(state,q,'palette',2);
  eq(Spatial.resolveAppearance(q.snapshot,id,1),{family:'Astral',palette:2},'combined preview');
  eq(Spatial.resolveAppearance(q.snapshot,'child',1),{family:'Astral',palette:1},'inherited family local palette');
  eq(Core.owners(q.snapshot),Core.owners(s),'owners unchanged');eq(q.snapshot.cubbies[id].mods,s.cubbies[id].mods,'fixtures unchanged');
  eq(Spatial.footprint(q.snapshot,id),Spatial.footprint(s,id),'decorative footprint unchanged');
  eq(state,before,'complete committed state unchanged by preview');
  const bad=Core.updateAppearance(state,q,'palette',9),rejected=Core.finishAppearance(state,bad);
  yes(bad.error,'invalid reference');eq(bad.command.patch.palette,9,'invalid choice retained');
  yes(rejected.error,'invalid commit refused');eq(rejected.snapshot,s,'invalid snapshot exact');eq(rejected.history,state.history,'invalid history exact');eq(rejected.revision,state.revision,'invalid revision exact');
  eq(Core.updateAppearance(state,q,'w',900),null,'unrelated field refused');
  const committed=Core.finishAppearance(state,q);
  eq(committed.error,'','session commit');eq(committed.history.length,1,'one Undo entry');eq(committed.revision,1,'one revision');eq(committed.snapshot,q.snapshot,'exact preview committed');
  const changed=apply(committed,{kind:'spatialRoomCreate',patch:{name:'Session specimen',x:10000,y:0,w:800,h:600}});
  eq(Core.undo(changed).snapshot,committed.snapshot,'structural Undo first');
  eq(Core.undo(Core.undo(changed)).snapshot,s,'appearance Undo second');
  eq(Core.updateAppearance(changed,q,'palette',1),null,'stale edit refused');
  const stale=Core.finishAppearance(changed,q);yes(stale.error,'stale finish refused');eq(stale.snapshot,changed.snapshot,'stale unchanged');
  const tampered=Core.clone(q);tampered.ok=false;yes(Core.finishAppearance(state,tampered).error,'changed preview cannot masquerade as no-op');
  let cleared=Core.updateAppearance(state,q,'family',(s.cubbies[id].appearance||{}).family||null);
  const basePalette=(s.cubbies[id].appearance||{}).palette;
  cleared=Core.updateAppearance(state,cleared,'palette',basePalette===undefined?null:basePalette);
  eq(cleared.ok,false,'return to original policies no-op');eq(Core.finishAppearance(state,cleared),state,'returned session no history');
  const none=Core.updateAppearance(state,opened,'family','None');
  eq(Spatial.resolveAppearance(none.snapshot,'child',1).family,'None','explicit None not inherit');
  eq(Checkpoint.decode(Checkpoint.encode(committed,{path:s.path,theme:1,cameras:{}})).snapshot,committed.snapshot,'existing format roundtrip');
  const physical=Core.session(ShelfSample.roomFixture()),room=physical.snapshot.spatial.shelves.root.roomId;
  const v={path:physical.snapshot.path,theme:1,cameras:{},mapView:{layer:'room',roomId:room,roomShelf:'',camera:{zoom:1,center:null},selectedRoom:room,selectedDoor:'',focus:null}};
  const encoded=Checkpoint.encode(physical,v);
  eq(JSON.parse(encoded).version,4,'optional map view v4 writer');eq(Checkpoint.decode(encoded).view,v,'v4 map view exact');
  for(const mutate of [m=>m.camera.zoom=99,m=>m.roomId='missing',m=>m.layer='invalid',m=>m.extra=true]){
   const envelope=JSON.parse(encoded);mutate(envelope.view.mapView);let refused=false;
   try{Checkpoint.decode(JSON.stringify(envelope))}catch(e){refused=true}
   yes(refused,'malformed valid-JSON map view decode refused');
  }
 }
 {
  // N5b.1: implicit Browse is a narrow ordinary-edit policy; explicit
  // destructive/physical resolution remains on the existing Apply path.
  const state=Core.session(ShelfSample.mapFixture()),s=state.snapshot;
  const room=s.spatial.shelves.root.roomId,empty=Object.keys(s.spatial.rooms).find(id=>!Object.values(s.spatial.shelves).some(p=>p.roomId===id));
  function denied(q,label){
   const n=Core.finishBrowseStructure(state,q);yes(n.error,label);
   eq(n.snapshot,s,label+' snapshot');eq(n.history,state.history,label+' history');eq(n.revision,state.revision,label+' revision');
  }
  const q=Core.previewStructure(state,{kind:'spatialRoomEdit',roomId:room,patch:{name:'Renamed Room'}});
  yes(q.ok,'ordinary room edit valid');
  const n=Core.finishBrowseStructure(state,q);eq(n.error,'','Browse commits');eq(n.snapshot,q.snapshot,'exact reviewed preview');
  eq(n.history.length,1,'one Undo');eq(n.revision,1,'one revision');eq(Core.undo(n).snapshot,s,'exact Undo');
  const unchanged=Core.previewStructure(state,{kind:'spatialRoomEdit',roomId:room,patch:{}});
  eq(unchanged.ok,false,'unchanged proposal');eq(Core.finishBrowseStructure(state,unchanged),state,'unchanged Browse no history');
  denied(Core.previewStructure(state,{kind:'spatialRoomEdit',roomId:room,patch:{w:10}}),'invalid size');
  const stale=Core.clone(q);stale.revision--;denied(stale,'stale');
  const tampered=Core.clone(q);tampered.snapshot.spatial.rooms[room].name='Different';denied(tampered,'altered preview');
  const deletion=Core.previewStructure(state,{kind:'spatialRoomDelete',roomId:empty,removeDoors:Object.keys(s.spatial.doors).filter(id=>[s.spatial.doors[id].a.roomId,s.spatial.doors[id].b.roomId].includes(empty))});
  denied(deletion,'Room removal explicit');
  denied(Core.previewStructure(state,{kind:'spatialRoomEdit',roomId:room,patch:{name:'Change'},removeDoors:[]}),'door resolution explicit');
  denied(Core.previewStructure(state,{kind:'cubby',cubbyId:'root',patch:{name:'Change'},rearrange:true}),'suggested rearrangement explicit');
  denied(Core.previewStructure(state,{kind:'spatialAppUnplace',appId:'org.example.Reader'}),'app unplacement explicit');
  const a=Core.beginAppearance(state,'root'),b=Core.updateAppearance(state,a,'palette',2),c=Core.finishBrowseStructure(state,b);
  eq(c.error,'','appearance uses same Browse boundary');eq(c.snapshot,b.snapshot,'appearance exact');
  const material=Core.previewStructure(state,{kind:'materialBatch',edits:[]});
  eq(Core.finishBrowseStructure(state,material),state,'unchanged material session');
 }
 {
  // Review specimen: an adopted independent crest exactly touches the
  // right wall. A wider profile cannot be kept by an implicit dismissal.
  let state=Core.session(ShelfSample.roomFixture());
  state=apply(state,{kind:'spatialAdoptIndependentProfiles'});
  const id='root',room=state.snapshot.spatial.rooms[state.snapshot.spatial.shelves[id].roomId];
  const edge=room.w-Spatial.footprint(state.snapshot,id).w;
  state=apply(state,{kind:'spatialShelfEdit',containerId:id,patch:{x:edge}});
  eq(Spatial.footprint(state.snapshot,id).x+Spatial.footprint(state.snapshot,id).w,room.w,'tight wall contact');
  const before=Core.clone(state),opened=Core.beginAppearance(state,id),bad=Core.updateAppearance(state,opened,'profile','pilaster');
  yes(bad.error,'blocked profile rejected');eq(bad.command.patch.profile,'pilaster','blocked choice retained');
  const refused=Core.finishAppearance(state,bad);yes(refused.error,'blocked profile cannot finish');
  eq(refused.snapshot,before.snapshot,'blocked profile snapshot exact');eq(refused.history,before.history,'blocked profile history exact');eq(refused.revision,before.revision,'blocked profile revision exact');
  const corrected=Core.updateAppearance(state,bad,'profile','crest');eq(Core.finishAppearance(state,corrected),state,'original profile closes unchanged');
 }
 {
  const state=Core.session(ShelfSample.fixture()),m=Core.rackAt(state.snapshot,'root','rack-1');
  function ready(s){return Core.accept(s,Core.solve(Core.request(s)));}
  function refuse(s,label){const q=Core.finishRackSelection(s);yes(q.error,label);eq(q.snapshot,s.snapshot,label+' snapshot');eq(q.history,s.history,label+' history');eq(q.draft,s.draft,label+' draft');eq(q.revision,s.revision,label+' revision');}
  const pending=Core.stage(state,'root',m.id,{y:m.y+10});
  refuse(pending,'pending worker cannot implicitly finish');
  const reviewed=ready(pending);eq(reviewed.draft.phase,'ready','rigid move ready');
  const moved=Core.finishRackSelection(reviewed);eq(moved.error,'','rigid move implicit');eq(moved,Core.apply(reviewed),'same validated explicit result');
  eq(moved.history.length,1,'rigid move one Undo');eq(Core.undo(moved).snapshot,state.snapshot,'rigid move Undo exact');
  const unchanged=ready(Core.stage(state,'root',m.id,{})),closed=Core.finishRackSelection(unchanged);
  eq(closed.error,'','no-op closes');eq(closed.draft,null,'no-op clears draft');eq(closed.snapshot,state.snapshot,'no-op exact');eq(closed.history,state.history,'no-op no Undo');
  refuse(Core.stage(state,'root',m.id,{x:null}),'incomplete number');
  const other=Object.keys(state.snapshot.spatial.shelves).find(k=>k!=='root'),emptyRack=state.snapshot.cubbies[other].mods.find(q=>q.type==='rack');
  const reflow=ready(Core.stage(state,other,emptyRack.id,{r:emptyRack.r-1}));
  eq(reflow.draft.phase,'ready','shape change ready but explicit');refuse(reflow,'ready shape change still explicit');
  const altered=Core.clone(reviewed);altered.draft.result.meta[Object.keys(altered.draft.result.meta)[0]].color='#ffffff';refuse(altered,'altered cell metadata');
 }
 {
  // All target switches use the reviewed ordinary-edit replay policy.
  const state=Core.session(ShelfSample.fixture()),s=state.snapshot,board=s.cubbies.root.mods.find(m=>m.id==='mixed-board');
  for(const cmd of [
   {kind:'shelf',cubbyId:'root',moduleId:board.id,patch:{x:board.x+10}},
   {kind:'child',cubbyId:'root',moduleId:'cubby-child',patch:{}},
   {kind:'artwork',cubbyId:'root',moduleId:'mixed-art',patch:{profile:'slim'}},
   {kind:'holderEdit',cubbyId:'root',moduleId:board.id,holderId:'mixed-upright',patch:{count:4}}
  ]){
   const q=Core.previewStructure(state,cmd);
   eq(q.error,'','ordinary fixture preview '+cmd.kind);
   const n=Core.finishBrowseStructure(state,q);eq(n.error,'','ordinary fixture resolution '+cmd.kind);
   eq(n.snapshot,q.snapshot,'exact fixture preview '+cmd.kind);
   eq(Core.owners(n.snapshot).map(e=>e.id).sort(),Core.owners(s).map(e=>e.id).sort(),'fixture owners retained '+cmd.kind);
   eq(n.history.length,q.ok?1:0,'fixture Undo count '+cmd.kind);
   if(q.ok)eq(Core.undo(n).snapshot,s,'exact fixture Undo '+cmd.kind);
  }
  for(const cmd of [
   {kind:'shelf',cubbyId:'root',moduleId:board.id,patch:{x:null}},
   {kind:'holderEdit',cubbyId:'root',moduleId:board.id,holderId:'mixed-upright',patch:{count:1}}
  ]){
   const q=Core.previewStructure(state,cmd),n=Core.finishBrowseStructure(state,q);
   yes(q.error,'invalid fixture preview '+cmd.kind);yes(n.error,'invalid fixture resolution refused '+cmd.kind);
   eq(n.snapshot,s,'invalid fixture snapshot exact');eq(n.history,state.history,'invalid fixture history exact');eq(n.revision,state.revision,'invalid fixture revision exact');
  }
 }
 {
  const state=Core.session(ShelfSample.fixture()),s=state.snapshot,view={path:s.path,theme:1,cameras:{}};
  eq(Object.values(Appearance.catalogue).reduce((n,entries)=>n+entries.length,0),76,'exact recovered catalogue count');
  for(const [family,entries] of Object.entries(Appearance.catalogue)){
   eq(new Set(entries.map(e=>e.id)).size,entries.length,'unique catalogue IDs '+family);
   for(const e of entries)if(!e.legacy)yes(e.core.length>0,'static emblem path data '+e.id);
  }
  let q=Core.beginAppearance(state,'root');
  q=Core.updateAppearance(state,q,'family','Astral');q=Core.updateAppearance(state,q,'emblem','armillary');
  q=Core.updateAppearance(state,q,'frame','metal');q=Core.updateAppearance(state,q,'backing','background');
  const f={id:'field-1',x:20,y:20,w:180,h:180,opacity:.7,family:'Astral',emblem:'eclipse',border:'rails',center:'axis'};
  q=Core.updateAppearance(state,q,'fields',[f]);
  yes(q.ok,'extended appearance valid');eq(state.snapshot,s,'unpublished appearance');
  const next=Core.finishAppearance(state,q);eq(next.error,'','expanded appearance commit');eq(next.history.length,1,'one appearance Undo');
  eq(Core.owners(next.snapshot),Core.owners(s),'appearance owners unchanged');eq(Spatial.footprint(next.snapshot,'root'),Spatial.footprint(s,'root'),'appearance footprint unchanged');
  const saved=Checkpoint.encode(next,view);eq(JSON.parse(saved).version,6,'extended appearance v6 writer');eq(Checkpoint.decode(saved).snapshot,next.snapshot,'v6 exact roundtrip');
  eq(Checkpoint.encode(Core.undo(next),view),Checkpoint.encode(state,view),'Undo restores old writer bytes');
  const bad=JSON.parse(saved);bad.version=3;let refused=false;try{Checkpoint.decode(JSON.stringify(bad))}catch(e){refused=true}yes(refused,'cannot mislabel expanded metadata v3');
  bad.version=6;bad.snapshot.cubbies.root.appearance.fields.push(Object.assign({},f,{id:'field-2',x:100}));refused=false;try{Checkpoint.decode(JSON.stringify(bad))}catch(e){refused=true}yes(refused,'overlapping fields rejected on decode');
  const invalid=Core.updateAppearance(state,q,'fields',[f,Object.assign({},f,{id:'field-2'})]);yes(invalid.error,'overlap refused');eq(Core.finishAppearance(state,invalid).snapshot,s,'overlap cannot publish');
  const corrected=Core.updateAppearance(state,invalid,'fields',[f]);eq(corrected.snapshot,q.snapshot,'corrected fields exact');
  const suggested=Appearance.suggestField([f],s.cubbies.root.w,s.cubbies.root.h);yes(!!suggested,'free field suggestion');
  yes(!Appearance.containerError({fields:[f,suggested]},s.cubbies.root,true),'suggestion nonoverlap');
  const glass=Core.updateAppearance(state,Core.beginAppearance(state,'child'),'glazing','combined');
  yes(glass.ok,'local child glazing');const glazed=Core.finishAppearance(state,glass);eq(glazed.snapshot.cubbies.root,s.cubbies.root,'glazing local not inherited');
  yes(Core.updateAppearance(state,Core.beginAppearance(state,'root'),'glazing','combined').error,'Shelf is not a glazed child door');
  yes(Appearance.emblemSvg('Astral','armillary','#91ada1').includes('<path'),'static recovered emblem SVG');
  eq(Appearance.emblemSvg('Astral','armillary','bad'),'','reject non-theme ink');
  eq(Appearance.emblem('Botanical','armillary').id,'vine-seal','unmatched inherited family safe fallback');
 }
 return checks;
}
