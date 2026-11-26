// Shared executable contract: run unchanged in Node and Qt Quick.
import * as Core from "../archive/ArchiveCore.mjs";
import * as Spatial from "../archive/ArchiveSpatial.mjs";
import * as Checkpoint from "../archive/ArchiveCheckpoint.mjs";
import * as MixedFixture from "./ArchiveB7MixedFixture.mjs";
import * as Mixed from "../archive/representation/B7Ownership.mjs";
import * as Motion from "../archive/ArchiveMotion.mjs";
import * as Capacity from "../archive/ArchiveCapacity.mjs";
import * as Doors from "../archive/ArchiveDoors.mjs";
import * as View from "../archive/ArchiveView.mjs";
import * as Architecture from "../archive/ArchiveArchitecture.mjs";
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
 return checks;
}
