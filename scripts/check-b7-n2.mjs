import assert from 'node:assert/strict';
import * as Core from '../quickshell/archive/ArchiveCore.mjs';
import * as Mixed from '../quickshell/archive/representation/B7Ownership.mjs';
import * as Motion from '../quickshell/archive/ArchiveMotion.mjs';
import * as CP from '../quickshell/archive/ArchiveCheckpoint.mjs';
import * as Fixture from '../quickshell/tests/ArchiveB7MixedFixture.mjs';

const initial=Core.fixture();
const root=initial.cubbies.root;root.w=1400;root.h=800;
root.mods.push({id:'board-a',type:'shelf',x:540,y:400,w:800,h:15,items:[
 {kind:'holder',id:'holder-a',x:400,w:130,scale:.86,slots:[null,null,null]}
]},{id:'board-b',type:'shelf',x:540,y:700,w:800,h:15,items:[]},
 {id:'mount-a',type:'artwork',x:550,y:30,w:120,h:120,profile:'stone',record:null},
 {id:'child-module',type:'cubby',x:0,y:450,w:160,h:120,childId:'child'});
initial.cubbies.child={id:'child',w:500,h:500,mods:[{id:'child-board',type:'shelf',x:20,y:300,w:420,h:15,items:[]}]};
const jar={id:'jar-file',name:'Vessel.stl',r:23,representation:'sculpture',variant:'sculpture/jar',seal:'retained',note:'metadata'};
const parcel={id:'parcel-file',name:'Bundle.zip',r:23,representation:'parcel',variant:'parcel/satchel'};
const art={id:'art-file',name:'Drawing.svg',r:23,representation:'artwork',variant:'artwork/estuary'};
const audio={id:'audio-file',name:'Music.flac',r:23,representation:'record',variant:'record/v1'};
const ledger={id:'ledger-file',name:'Table.csv',r:23,representation:'ledger',variant:'ledger/v2'};
const compact={id:'compact-file',name:'Image.png',r:23,representation:'artwork',variant:'artwork/arcade',compact:true};
initial.caseItems.push(jar,parcel,art,audio,ledger,compact);
const original=Core.session(initial);
const ids=s=>Core.owners(s.snapshot).map(e=>e.id).sort();
const owner=(s,id)=>Core.owners(s.snapshot).find(e=>e.id===id);
function move(s,id,destination){
 const next=Core.transfer(s,[id],destination);
 assert.equal(next.error,'',next.error);assert.deepEqual(ids(next),ids(original));return next;
}
function fail(s,id,destination){
 const next=Core.transfer(s,[id],destination);assert.ok(next.error);
 assert.equal(next.snapshot,s.snapshot);assert.equal(next.history,s.history);assert.equal(next.revision,s.revision);
}
const shelf=(moduleId,x,support='shelf',cubbyId='root')=>({kind:'shelf',cubbyId,moduleId,x,scale:.86,support});
let s=move(original,jar.id,shelf('board-a',100,'plinth'));
s=move(s,parcel.id,shelf('board-a',300,'tray'));
s=move(s,art.id,{kind:'artwork',cubbyId:'root',moduleId:'mount-a'});
s=move(s,audio.id,{kind:'holder',cubbyId:'root',moduleId:'board-a',holderId:'holder-a',slot:0});
s=move(s,ledger.id,{kind:'holder',cubbyId:'root',moduleId:'board-a',holderId:'holder-a',slot:1});
assert.equal(Core.validate(s.snapshot),null);
assert.equal(owner(s,jar.id).where,'shelf');assert.equal(owner(s,audio.id).where,'holder');assert.equal(owner(s,art.id).where,'artwork');
assert.deepEqual(Mixed.currentAppearance(owner(s,jar.id)),{family:'sculpture',variant:'sculpture/jar'});
assert.deepEqual(Mixed.currentAppearance(owner(s,compact.id)),{family:'scroll',variant:null});
assert.throws(()=>Motion.begin(s,[jar.id]),/rack or Case/);
fail(s,jar.id,shelf('board-a',300)); // occupied
fail(s,jar.id,shelf('board-a',1)); // overhang
fail(s,jar.id,shelf('child-board',100,'shelf','child')); // direct cross-cubby
fail(s,jar.id,{kind:'holder',cubbyId:'root',moduleId:'board-a',holderId:'holder-a',slot:2});
fail(s,audio.id,shelf('board-b',120));
fail(s,compact.id,{kind:'shelf',cubbyId:'root',moduleId:'board-b',x:120,scale:.86,support:'shelf',frame:{w:120,h:100,profile:'bronze'}});
fail(s,audio.id,{kind:'holder',cubbyId:'root',moduleId:'board-a',holderId:'holder-a',slot:1});
const duplicate=Core.clone(s.snapshot);duplicate.caseItems.push(Core.clone(jar));assert.ok(Core.validate(duplicate));
const invalid=Core.clone(s.snapshot);invalid.cubbies.root.mods.find(m=>m.id==='board-a').items[1].record.variant='parcel/satchel';assert.ok(Core.validate(invalid));
const obstructed=Core.previewStructure(s,{kind:'shelf',cubbyId:'root',moduleId:'board-a',patch:{x:0}});
assert.equal(obstructed.ok,false);assert.equal(obstructed.snapshot,null);
const shrink=Core.previewStructure(s,{kind:'shelf',cubbyId:'root',moduleId:'board-a',patch:{w:400}});assert.equal(shrink.ok,false);
const before=Core.clone(s.snapshot);
let t=move(s,jar.id,'case');
assert.equal(owner(t,jar.id).scroll.originModuleId,'board-a');assert.equal(owner(t,jar.id).scroll.originStale,false);
assert.deepEqual(Mixed.currentAppearance(owner(t,jar.id)),{family:'scroll',variant:null});
assert.deepEqual(Core.undo(t).snapshot,before);
t=move(t,jar.id,shelf('child-board',100,'shelf','child'));
assert.deepEqual(Mixed.currentAppearance(owner(t,jar.id)),{family:'sculpture',variant:'sculpture/jar'});
assert.equal(owner(t,jar.id).scroll.note,'metadata');
let carried=move(s,parcel.id,'case');
const rack=Core.rackAt(carried.snapshot,'root','rack-1');
const cell=Core.geometry(rack).cells.find(c=>!rack.scrollCells[c.key]?.length&&Core.interiorDistance({x:c.cx,y:c.cy},Core.wall(c))>=parcel.r);
assert.ok(cell);
const stored=move(carried,parcel.id,{cubbyId:'root',rackId:rack.id,key:cell.key,local:{x:cell.cx,y:cell.cy}});
assert.deepEqual(Mixed.currentAppearance(owner(stored,parcel.id)),{family:'scroll',variant:null});
assert.equal(owner(stored,parcel.id).scroll.compact,undefined);
const restored=move(stored,parcel.id,shelf('board-b',200,'tray'));
assert.deepEqual(Mixed.currentAppearance(owner(restored,parcel.id)),{family:'parcel',variant:'parcel/satchel'});
const del=Core.previewStructure(s,{kind:'delete',cubbyId:'root',moduleId:'board-a'});
assert.ok(del.ok,del.error);assert.equal(del.caseTransferCount,4);assert.deepEqual(s.snapshot,before);
const deleted=Core.applyStructure(s,del);assert.equal(deleted.error,'');assert.deepEqual(ids(deleted),ids(original));
for(const id of [jar.id,parcel.id,audio.id,ledger.id]){const e=owner(deleted,id);assert.equal(e.where,'case');assert.equal(e.scroll.originStale,true);assert.equal(e.scroll.originModuleId,'board-a');}
assert.deepEqual(Core.undo(deleted).snapshot,before);
assert.ok(Core.applyStructure(deleted,del).error);
const childDel=Core.previewStructure(t,{kind:'delete',cubbyId:'root',moduleId:'child-module'});
assert.ok(childDel.ok);assert.equal(childDel.caseTransferCount,1);const childGone=Core.applyStructure(t,childDel);
assert.equal(childGone.error,'');assert.equal(owner(childGone,jar.id).scroll.originStale,true);assert.deepEqual(Core.undo(childGone).snapshot,t.snapshot);
// V2 persists exact mixed placements, slot vacancies and preferred metadata.
const mixedView={path:['root'],theme:1,cameras:{},snapEnabled:true,showGrid:true,snapDistance:25};
const mixedSaved=CP.encode(s,mixedView);
assert.equal(JSON.parse(mixedSaved).version,2);
assert.deepEqual(CP.decode(mixedSaved),{snapshot:s.snapshot,view:mixedView});
const legacyMixed=JSON.parse(mixedSaved);legacyMixed.version=1;
assert.throws(()=>CP.decode(JSON.stringify(legacyMixed)),/Version 1/);
const legacy=JSON.parse(CP.encode(Core.session(Core.fixture()),mixedView));legacy.version=1;
assert.deepEqual(CP.decode(JSON.stringify(legacy)),{snapshot:legacy.snapshot,view:mixedView});
console.log('B7-N2: mixed owners, compatibility, occupied bounds, automatic scroll form, Case provenance, atomic evacuation and Undo passed');

// Holder swaps are model transactions, not a second local inventory.
const swapped=Core.editStructure(s,{kind:'holderMove',cubbyId:'root',moduleId:'board-a',holderId:'holder-a',from:0,to:1,recordId:audio.id});
assert.equal(swapped.error,'');assert.equal(owner(swapped,audio.id).slot,1);assert.equal(owner(swapped,ledger.id).slot,0);
assert.deepEqual(Core.undo(swapped).snapshot,s.snapshot);
assert.ok(Core.editStructure(swapped,{kind:'holderMove',cubbyId:'root',moduleId:'board-a',holderId:'holder-a',from:0,to:2,recordId:audio.id}).error);
const single=Core.clone(original.snapshot),board=single.cubbies.root.mods.find(m=>m.id==='board-b');
board.items=[{kind:'object',record:single.caseItems.splice(single.caseItems.findIndex(r=>r.id===jar.id),1)[0],x:680,scale:.86,support:'plinth'}];
const shrinkBase=Core.session(single),cmd={kind:'shelf',cubbyId:'root',moduleId:'board-b',patch:{w:600}};
assert.equal(Core.previewStructure(shrinkBase,cmd).ok,false);
const suggested=Core.previewStructure(shrinkBase,{...cmd,rearrange:true});assert.ok(suggested.ok,suggested.error);
assert.deepEqual(shrinkBase.snapshot,single);const applied=Core.applyStructure(shrinkBase,suggested);assert.equal(applied.error,'');
assert.deepEqual(owner(applied,jar.id).scroll,jar);assert.deepEqual(Core.undo(applied).snapshot,single);
console.log('B7-N2 holder ownership swaps and conservative shelf shrink preview passed');

// Exercise the exact fixture used by the QML scene in the offline job too.
const visual=Fixture.fixture();assert.equal(Core.validate(visual),null);
const visualSession=Core.session(visual);
assert.ok(Core.owners(visual).some(e=>e.where==='holder'));
assert.ok(Core.previewStructure(visualSession,{kind:'shelf',cubbyId:'root',moduleId:'mixed-lower',patch:{w:600},rearrange:true}).ok);
console.log('B7-N2 actual mixed study fixture and shrink candidate validated');

// Mixed transfers through the same private frame-driven motion transaction.
function motionMove(s,id,d){
 const q=Motion.begin(s,[id],true);Motion.lift(q);Motion.insert(q,d,{});Motion.release(q,false);
 for(let i=0;i<1000&&q.cells.size&&!q.error;i++)Motion.advance(q,1/60);
 assert.equal(q.error,'');assert.equal(q.cells.size,0);
 const n=Core.commitMotion(s,q);assert.equal(n.error,'',n.error);
 assert.deepEqual(ids(n),ids(s));return n;
}
const dest=Mixed.destinationAt(visual,'root',{x:750,y:760},owner(visualSession,'mixed-jar').scroll,owner(visualSession,'mixed-jar'));
assert.equal(dest.kind,'shelf');assert.equal(dest.moduleId,'mixed-lower');assert.equal(dest.support,'plinth');
const movedVisual=motionMove(visualSession,'mixed-jar',dest);
assert.equal(owner(movedVisual,'mixed-jar').moduleId,'mixed-lower');
assert.deepEqual(Core.undo(movedVisual).snapshot,visual);
const motionRack=Core.rackAt(movedVisual.snapshot,'root','rack-1');
const free=Core.geometry(motionRack).cells.find(c=>!motionRack.scrollCells[c.key]?.length&&Core.interiorDistance({x:c.cx,y:c.cy},Core.wall(c))>=13);
assert.ok(free);
const packed=motionMove(movedVisual,'mixed-jar',{cubbyId:'root',rackId:motionRack.id,key:free.key,local:{x:free.cx,y:free.cy}});
assert.deepEqual(Mixed.currentAppearance(owner(packed,'mixed-jar')),{family:'scroll',variant:null});
const unpacked=motionMove(packed,'mixed-jar',dest);
assert.deepEqual(Mixed.currentAppearance(owner(unpacked,'mixed-jar')),{family:'sculpture',variant:'sculpture/jar'});
const mixedCase=motionMove(unpacked,'mixed-audio','case');
assert.equal(owner(mixedCase,'mixed-audio').where,'case');
const returned=motionMove(mixedCase,'mixed-audio',{kind:'holder',cubbyId:'root',moduleId:'mixed-board',holderId:'mixed-upright',slot:1});
assert.equal(owner(returned,'mixed-audio').slot,1);
const invalidMotion=Motion.begin(visualSession,['mixed-jar'],true);Motion.lift(invalidMotion);
assert.throws(()=>Motion.insert(invalidMotion,{kind:'shelf',cubbyId:'root',moduleId:'mixed-board',x:285,scale:.86,support:'plinth'},{}));
assert.deepEqual(visualSession.snapshot,visual);
console.log('B7-N2 live mixed transfers, rack compaction, holder transport, invalid rollback passed');

 // Contextual fixture commands, including occupied holder removal and exact Undo.
const emptyMount=Core.previewStructure(visualSession,{kind:'create',type:'artwork',cubbyId:'root',patch:{x:1080,y:40,w:150,h:100,profile:'slim'}});
assert.ok(emptyMount.ok,emptyMount.error);
const mounted=Core.applyStructure(visualSession,emptyMount);assert.equal(mounted.error,'');
const newMount=mounted.snapshot.cubbies.root.mods.find(m=>m.type==='artwork'&&m.record===null);
assert.ok(newMount);assert.equal(newMount.profile,'slim');
const editedMount=Core.editStructure(mounted,{kind:'artwork',cubbyId:'root',moduleId:newMount.id,patch:{profile:'stone',w:160}});
assert.equal(editedMount.error,'');assert.deepEqual(Core.undo(editedMount).snapshot,mounted.snapshot);
const holderPatch=Mixed.newHolderPatch(visual.cubbies.root,visual.cubbies.root.mods.find(m=>m.id==='mixed-lower'),10);
const holderCreate=Core.previewStructure(visualSession,{kind:'holderCreate',cubbyId:'root',moduleId:'mixed-lower',patch:holderPatch});
assert.ok(holderCreate.ok,holderCreate.error);assert.deepEqual(visualSession.snapshot,visual);
const holderCreated=Core.applyStructure(visualSession,holderCreate);
assert.equal(holderCreated.error,'');const addedHolder=holderCreated.snapshot.cubbies.root.mods.find(m=>m.id==='mixed-lower').items.find(e=>e.kind==='holder');
assert.equal(addedHolder.slots.length,4);
assert.deepEqual(Core.undo(holderCreated).snapshot,visual);
const editHolder=Core.editStructure(visualSession,{kind:'holderEdit',cubbyId:'root',moduleId:'mixed-board',holderId:'mixed-upright',patch:{count:4}});
assert.equal(editHolder.error,'');assert.equal(editHolder.snapshot.cubbies.root.mods.find(m=>m.id==='mixed-board').items.find(e=>e.kind==='holder').slots.length,4);
assert.ok(Core.editStructure(visualSession,{kind:'holderEdit',cubbyId:'root',moduleId:'mixed-board',holderId:'mixed-upright',patch:{count:2}}).error);
const deleteHolder=Core.previewStructure(visualSession,{kind:'holderDelete',cubbyId:'root',moduleId:'mixed-board',holderId:'mixed-upright'});
assert.ok(deleteHolder.ok,deleteHolder.error);assert.equal(deleteHolder.caseTransferCount,2);
const holderGone=Core.applyStructure(visualSession,deleteHolder);
assert.equal(holderGone.error,'');for(const id of ['mixed-audio','mixed-font']){const e=owner(holderGone,id);assert.equal(e.where,'case');assert.equal(e.scroll.originStale,true);}
assert.deepEqual(Core.undo(holderGone).snapshot,visual);
const cubbyShrink=Core.previewStructure(visualSession,{kind:'cubby',cubbyId:'root',patch:{h:740},rearrange:true});
assert.ok(cubbyShrink.ok,cubbyShrink.error);assert.equal(Core.validate(cubbyShrink.snapshot),null);
assert.deepEqual(Core.undo(Core.applyStructure(visualSession,cubbyShrink)).snapshot,visual);
console.log('B7-N2 contextual creation, holder evacuation and occupied cubby suggestion passed');

 // AUD-09: reproduce exact aggregate rack-cell threshold from the audit.
import * as Capacity from '../quickshell/archive/ArchiveCapacity.mjs';
import * as Restart from '../quickshell/tests/ArchiveCheckpointTestData.mjs';
const restart=Restart.fixture();
assert.deepEqual(CP.decode(CP.encode(Core.session(restart.snapshot),restart.view)),{snapshot:restart.snapshot,view:restart.view});
const boundary={cubbies:{root:{id:'root',w:1800,h:1500,mods:[]}},caseItems:[],next:100000,path:['root']};
const rackShape={id:'capacity-rack',type:'rack',shape:'hex',x:0,y:0,w:1800,h:1500,r:60,color:null,cellMeta:{},scrollCells:{}};
const largeCells=Core.geometry(rackShape).cells;
assert.equal(largeCells.length,333);
for(let i=0;i<37;i++){
 const id='capacity-child-'+i;
 boundary.cubbies.root.mods.push({id:'capacity-module-'+i,type:'cubby',x:(i%10)*160,y:Math.floor(i/10)*120,w:150,h:110,childId:id});
 const child={id,w:1800,h:1500,mods:[]};boundary.cubbies[id]=child;
 if(i<36){
  const rack=Core.clone(rackShape);rack.id='capacity-rack-'+i;
  for(const c of largeCells)rack.cellMeta[c.key]={id:'capacity-cell-'+i+'-'+c.key,color:null};
  child.mods.push(rack);
 }
}
const limitSession=Core.session(boundary);
assert.equal(largeCells.length*36,11988);
const limitSaved=CP.encode(limitSession,{path:['root'],theme:0,cameras:{}});
assert.deepEqual(CP.decode(limitSaved).snapshot,boundary);
const overflow={kind:'create',type:'rack',cubbyId:'capacity-child-36',patch:{x:0,y:0,w:1800,h:1500,r:60}};
const refused=Core.previewStructure(limitSession,overflow);
assert.equal(refused.ok,false);assert.match(refused.error,/Cell budget exceeded/);
assert.equal(largeCells.length*37,12321);
assert.equal(Core.applyStructure(limitSession,refused).snapshot,limitSession.snapshot);
assert.deepEqual(CP.decode(limitSaved).snapshot,boundary);
const tooMany=Core.clone(visual);tooMany.caseItems=Array.from({length:Capacity.limits.records},(_,i)=>({id:'too-many-'+i,name:'Sample.md',r:13}));
assert.match(Core.validate(tooMany),/Record budget/);
const oversized=Core.clone(visual);oversized.caseItems[0].note='x'.repeat(Capacity.limits.snapshotChars);
assert.match(Core.validate(oversized),/Snapshot size budget/);
const tooManyModules=Core.clone(visual);tooManyModules.cubbies.root.mods=Array(65).fill(tooManyModules.cubbies.root.mods[0]);
assert.ok(Core.validate(tooManyModules));
const oversizedView=Object.assign({},mixedView,{extra:'x'.repeat(Capacity.limits.viewChars)});
assert.throws(()=>CP.encode(visualSession,oversizedView),/View size budget/);
for(const state of [deleted,holderGone,packed,returned,restored]){
 assert.deepEqual(CP.decode(CP.encode(state,mixedView)).snapshot,state.snapshot);
}
console.log('B7-N2 v1 compatibility, exact v2 mixed roundtrip, shared capacity and AUD-09 11988/12321 regression passed');

 // Mixed return-to-origin and camera lifecycle regressions.
for(const id of ['mixed-jar','mixed-picture','mixed-audio']){
 const carried=motionMove(visualSession,id,'case');
 const record=owner(carried,id).scroll,d=Core.originDestination(carried.snapshot,record);
 const back=motionMove(carried,id,d),e=owner(back,id),old=owner(visualSession,id);
 assert.equal(e.where,old.where);assert.equal(e.moduleId,old.moduleId);assert.equal(e.slot,old.slot);
 assert.equal(e.scroll.variant,old.scroll.variant);
 assert.deepEqual(Core.undo(back).snapshot,carried.snapshot);
}
const blockedCase=motionMove(visualSession,'mixed-jar','case');
const otherJar=motionMove(blockedCase,'mixed-owl',{kind:'shelf',cubbyId:'root',moduleId:'mixed-board',x:90,scale:.86,support:'shelf'});
assert.throws(()=>Core.originDestination(otherJar.snapshot,owner(otherJar,'mixed-jar').scroll),/overlap|fit/i);
assert.throws(()=>Core.originDestination(holderGone.snapshot,owner(holderGone,'mixed-audio').scroll),/no longer available/);
const slotCarried=motionMove(visualSession,'mixed-font','case');
const shortened=Core.editStructure(slotCarried,{kind:'holderEdit',cubbyId:'root',moduleId:'mixed-board',holderId:'mixed-upright',patch:{count:2}});
assert.equal(shortened.error,'');assert.equal(owner(shortened,'mixed-font').scroll.originStale,true);
const expanded=Core.editStructure(shortened,{kind:'holderEdit',cubbyId:'root',moduleId:'mixed-board',holderId:'mixed-upright',patch:{count:3}});
assert.throws(()=>Core.originDestination(expanded.snapshot,owner(expanded,'mixed-font').scroll),/no longer available/);
assert.deepEqual(Core.undo(shortened).snapshot,slotCarried.snapshot);
import * as View from '../quickshell/archive/ArchiveView.mjs';
const ccmd={kind:'create',type:'cubby',cubbyId:'root',patch:{x:10,y:500,w:160,h:120}};
const made=Core.editStructure(visualSession,ccmd);assert.equal(made.error,'');
const existingIds=new Set(Object.keys(visualSession.snapshot.cubbies));
const nested=made.snapshot.cubbies.root.mods.find(m=>m.type==='cubby'&&!existingIds.has(m.childId));
assert.ok(nested,'Find newly created child, not pre-existing Field notes cubby');
const cid=nested.childId;
const cam={zoom:1.4,x:31,y:-17},cams={[cid]:cam};
const unmade=Core.undo(made);assert.deepEqual(unmade.snapshot,visualSession.snapshot);
const pruned=View.reconcileCameras(made.snapshot,unmade.snapshot,unmade.history,cams,true,cid,cam);
assert.equal(pruned[cid],undefined);
const remade=Core.editStructure(unmade,ccmd);assert.equal(remade.error,'');
assert.equal(remade.snapshot.cubbies.root.mods.find(m=>m.type==='cubby'&&!existingIds.has(m.childId)).childId,cid);
assert.equal(View.reconcileCameras(unmade.snapshot,remade.snapshot,remade.history,cams,false,'root',cam)[cid],undefined);
const gone=Core.editStructure(made,{kind:'delete',cubbyId:'root',moduleId:nested.id});
assert.equal(gone.error,'');const retained=View.reconcileCameras(made.snapshot,gone.snapshot,gone.history,{},false,cid,cam);
assert.deepEqual(retained[cid],cam);
const recovered=Core.undo(gone);assert.deepEqual(recovered.snapshot,made.snapshot);
assert.deepEqual(View.reconcileCameras(gone.snapshot,recovered.snapshot,recovered.history,retained,true,'root',cam)[cid],cam);
console.log('B7-N2 exact mixed origins, stale slot guard and AUD-14 camera lifecycle passed');


 // AUD-18: valid imported IDs must not inherit Object.prototype camera entries.
for(const name of ['toString','hasOwnProperty','valueOf','isPrototypeOf']){
 const sample=Core.fixture();
 sample.cubbies.root.mods.push({id:'import-child',type:'cubby',x:520,y:0,w:160,h:120,childId:name});
 sample.cubbies[name]={id:name,w:470,h:340,mods:[]};
 assert.equal(Core.validate(sample),null);
 const view={path:['root',name],theme:0,cameras:{}};
 const decoded=CP.decode(CP.encode(Core.session(sample),view));
 assert.deepEqual(decoded.snapshot,sample);
 assert.deepEqual(View.cameraFor(decoded.view.cameras,name),{zoom:1,x:0,y:0});
 const saved={zoom:1.4,x:31,y:-17};
 decoded.view.cameras[name]=saved;
 assert.deepEqual(View.cameraFor(View.copyCameras(decoded.view.cameras),name),saved);
 const round=CP.decode(CP.encode(Core.session(sample),decoded.view));
 assert.deepEqual(View.cameraFor(round.view.cameras,name),saved);
 const without=Core.clone(sample);delete without.cubbies[name];without.cubbies.root.mods.pop();
 const retained=View.reconcileCameras(sample,without,[sample],{},false,name,saved);
 assert.deepEqual(View.cameraFor(retained,name),saved);
 assert.deepEqual(View.cameraFor(View.reconcileCameras(without,sample,[],retained,false,'root',saved),name),{zoom:1,x:0,y:0});
 assert.deepEqual(View.cameraFor(View.reconcileCameras(without,sample,[],retained,true,'root',saved),name),saved);
}
 // AUD-19: every permitted upright scale and variant fits a shared reserved envelope.
import * as Layout from '../quickshell/archive/representation/B7Layout.mjs';
const uprightAssets=Layout.assetEntries().filter(e=>e.edge).map(e=>e.id);
assert.equal(uprightAssets.length,18);
for(const scale of [.4,.86,1,1.2,1.3]){
 const env=Layout.holderEnvelope(scale,130);
 for(const id of uprightAssets){
  const face=Layout.supportedLayout(id,env.cradleWidth/2,env.height-36,scale).box;
  assert.ok(face.x>=2-1e-7);assert.ok(face.x+face.width<=env.cradleWidth-2+1e-7);
  assert.ok(face.y>=2-1e-7);assert.ok(face.y+face.height<=env.height-36+1e-7);
 }
 const holder={kind:'holder',id:'test-holder',x:0,w:130,scale,slots:[null]};
 const board={type:'shelf',id:'test-board',x:540,y:400,w:env.width,h:15,items:[holder]};
 assert.equal(Mixed.validateShelf(board)[0].w,env.width);
 assert.throws(()=>Mixed.validateShelf({...board,w:env.width-1}),/exceeds shelf width/);
 for(const id of uprightAssets){
  const r={id:'upright-test',name:'Test',r:13,representation:id.split('/')[0],variant:id};
  assert.deepEqual(Mixed.validateShelf({...board,items:[{...holder,slots:[r]}]}),Mixed.validateShelf(board));
 }
}
assert.equal(Layout.holderEnvelope(.86,130).width,390);
assert.equal(Layout.holderEnvelope(.86,130).cradleWidth,244);
assert.equal(Layout.holderEnvelope(1.3,130).cradleWidth,251);
const large=Core.fixture();large.cubbies.root.w=1400;large.cubbies.root.h=800;
const env=Layout.holderEnvelope(1.3,130);
large.cubbies.root.mods.push({id:'max-scale-board',type:'shelf',x:540,y:400,w:env.width,h:15,items:[{kind:'holder',id:'max-holder',x:0,w:130,scale:1.3,slots:[null]}]});
assert.equal(Core.validate(large),null);
const wide=Core.session(large),small=Core.previewStructure(wide,{kind:'shelf',cubbyId:'root',moduleId:'max-scale-board',patch:{w:390}});
assert.equal(small.ok,false);assert.equal(Core.applyStructure(wide,small).snapshot,wide.snapshot);
const shifted=Core.editStructure(wide,{kind:'shelf',cubbyId:'root',moduleId:'max-scale-board',patch:{w:env.width+10}});
assert.equal(shifted.error,'');assert.deepEqual(Core.undo(shifted).snapshot,wide.snapshot);
assert.deepEqual(CP.decode(CP.encode(wide,{path:['root'],theme:0,cameras:{}})).snapshot,large);
console.log('PASS AUD-18/19: imported camera identities, full-face reservation, boundary refusal and exact Undo');

// A camera entry must refer to a real cubby, not an inherited property.
// Earlier v2 checkpoints that only fit by the missing 7-unit reservation
// are refused atomically rather than silently resized or repositioned.
const ghostView={path:['root'],theme:0,cameras:{toString:{zoom:1,x:0,y:0}}};
assert.throws(()=>CP.encode(Core.session(Core.fixture()),ghostView),/Invalid camera/);
const tightLegacy=JSON.parse(CP.encode(wide,{path:['root'],theme:0,cameras:{}}));
const tightBoard=tightLegacy.snapshot.cubbies.root.mods.find(m=>m.id==='max-scale-board');
tightBoard.w=390;
// The shelf validator gives the precise cause. Core checks every fixture
// against every other fixture; an invalid shelf can fail the earlier rack's
// geometry check first. Preserve that existing validation/error contract.
assert.throws(()=>Mixed.validateShelf(tightBoard),/exceeds shelf width/);
const tightError=Core.validate(tightLegacy.snapshot);
assert.equal(tightError,'Invalid rack geometry');
assert.throws(()=>CP.decode(JSON.stringify(tightLegacy)),e=>e.message===tightError);
assert.equal(Core.validate(wide.snapshot),null);

 // AUD-17: visual projection reflects private ownership without publishing.
const visBase=Core.session(Fixture.fixture()),visBefore=JSON.stringify(visBase.snapshot);
const visRack=Core.rackAt(visBase.snapshot,'root','rack-1');
const visCell=Core.geometry(visRack).cells.find(c=>c.area>14000&&!(visRack.scrollCells[c.key]||[]).length);
const visDest={cubbyId:'root',rackId:visRack.id,key:visCell.key,local:{x:visCell.cx,y:visCell.cy}};
for(const id of ['mixed-jar','mixed-picture','mixed-audio']){
 const q=Motion.begin(visBase,[id],true);
 assert.deepEqual(Motion.mixedVisuals(q),{hidden:[],pending:[]});
 Motion.lift(q);assert.deepEqual(Motion.mixedVisuals(q),{hidden:[id],pending:[]});
 assert.equal(q.carried[0].id,id);
 Motion.insert(q,visDest,{});assert.deepEqual(Motion.mixedVisuals(q),{hidden:[id],pending:[]});
 assert.equal(q.carried.length,0);assert.ok(Motion.members(q)[visRack.id].some(r=>r.id===id));
 assert.equal(JSON.stringify(visBase.snapshot),visBefore);
}
const packedVis=motionMove(visBase,'mixed-jar',visDest);
const vq=Motion.begin(packedVis,['mixed-jar']);Motion.lift(vq);
assert.deepEqual(Motion.mixedVisuals(vq),{hidden:[],pending:[]});
Motion.insert(vq,{kind:'shelf',cubbyId:'root',moduleId:'mixed-lower',x:200,scale:.86,support:'plinth'},{});
const pendingVis=Motion.mixedVisuals(vq);
assert.equal(pendingVis.hidden.length,0);assert.equal(pendingVis.pending.length,1);
assert.equal(pendingVis.pending[0].record.id,'mixed-jar');
assert.equal(pendingVis.pending[0].moduleId,'mixed-lower');
assert.equal(pendingVis.pending[0].x,750);assert.ok(Number.isFinite(pendingVis.pending[0].y));
assert.equal(Core.owners(packedVis.snapshot).find(e=>e.id==='mixed-jar').where,'rack');
assert.deepEqual(Motion.mixedVisuals(null),{hidden:[],pending:[]});
assert.equal(Core.rackAt(Core.fixture(),'toString','rack-1'),null);
console.log('PASS AUD-17: private membership, mixed source suppression, pending destination and unchanged committed ownership');
