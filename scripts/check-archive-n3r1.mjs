import assert from 'node:assert/strict';
import * as Core from '../quickshell/archive/ArchiveCore.mjs';
import * as CP from '../quickshell/archive/ArchiveCheckpoint.mjs';
import * as View from '../quickshell/archive/ArchiveView.mjs';
let s=Core.session(Core.fixture()),before=JSON.stringify(s.snapshot);
const command={kind:'create',type:'cubby',cubbyId:'root',patch:{x:520,y:0,w:160,h:120}};
const q=Core.previewStructure(s,command);assert.ok(q.ok,q.error);assert.equal(JSON.stringify(s.snapshot),before);assert.equal(s.history.length,0);
const t=Core.applyStructure(s,q);assert.equal(t.error,'');assert.equal(t.history.length,1);assert.equal(Core.validate(t.snapshot),null);
const child=t.snapshot.cubbies.root.mods.find(m=>m.type==='cubby');assert.ok(child);assert.equal(t.snapshot.cubbies[child.childId].w,470);
assert.equal(JSON.stringify(Core.undo(t).snapshot),before);assert.ok(Core.applyStructure(t,q).error);
const overlap=Core.previewStructure(t,{kind:'create',type:'rack',cubbyId:'root',patch:{x:0,y:0,w:200,h:180,r:64}});assert.equal(overlap.ok,false);
let u=Core.editStructure(t,{kind:'child',cubbyId:'root',moduleId:child.id,patch:{x:530,w:150}});assert.equal(u.error,'');assert.equal(u.snapshot.cubbies[child.childId].w,470);
u=Core.editStructure(u,{kind:'cubby',cubbyId:child.childId,patch:{name:'Field room',w:480,h:350,color:'#827466',innerColor:'#303b3a'}});assert.equal(u.error,'');
u=Core.editStructure(u,{kind:'create',type:'rack',cubbyId:child.childId,patch:{x:10,y:10,w:210,h:180,r:64}});assert.equal(u.error,'');assert.equal(Core.validate(u.snapshot),null);
const removed=Core.previewStructure(u,{kind:'delete',cubbyId:'root',moduleId:'rack-1'});assert.ok(removed.ok,removed.error);assert.equal(removed.caseTransferCount,3);assert.equal(u.snapshot.caseItems.length,0);
const evacuated=Core.applyStructure(u,removed);assert.equal(evacuated.error,'');assert.equal(evacuated.snapshot.caseItems.length,3);
assert.deepEqual(evacuated.snapshot.caseItems.map(v=>v.id).sort(),['test-a','test-b','test-c']);assert.ok(evacuated.snapshot.caseItems.every(v=>v.originStale&&v.originRackId==='rack-1'));
assert.deepEqual(Core.undo(evacuated).snapshot,u.snapshot);
const shelf=Core.applyStructure(u,Core.previewStructure(u,{kind:'create',type:'shelf',cubbyId:'root',patch:{x:0,y:430,w:280,h:15}}));assert.equal(shelf.error,'');
const board=shelf.snapshot.cubbies.root.mods.find(m=>m.type==='shelf');assert.equal(board.h,15);
const resized=Core.editStructure(shelf,{kind:'shelf',cubbyId:'root',moduleId:board.id,patch:{x:20,y:440,w:300,color:'#778899'}});assert.equal(resized.error,'');
assert.equal(resized.snapshot.cubbies.root.mods.find(m=>m.id===board.id).w,300);
assert.ok(Core.editStructure(resized,{kind:'shelf',cubbyId:'root',moduleId:board.id,patch:{y:30}}).error);
assert.deepEqual(CP.decode(CP.encode(resized,{path:['root'],theme:0,cameras:{}})).snapshot,resized.snapshot);
assert.deepEqual(Core.undo(Core.editStructure(resized,{kind:'delete',cubbyId:'root',moduleId:board.id})).snapshot,resized.snapshot);
const populated=Core.clone(u.snapshot),nested=populated.cubbies[child.childId].mods[0],cell=Core.geometry(nested).cells.find(c=>c.area>4000);
const spot=Core.staticScrollSpot(cell,[],10,.2);assert.ok(spot);
nested.scrollCells[cell.key]=[Object.assign({id:'nested-file',name:'drawing.svg',r:10,cellKey:cell.key,representation:'artwork',variant:'artwork/estuary'},spot)];
const populatedSession=Core.session(populated),nestedDelete=Core.previewStructure(populatedSession,{kind:'delete',cubbyId:'root',moduleId:child.id});
assert.equal(nestedDelete.caseTransferCount,1);const nestedResult=Core.applyStructure(populatedSession,nestedDelete);assert.equal(nestedResult.error,'');assert.equal(nestedResult.snapshot.caseItems[0].variant,'artwork/estuary');assert.equal(nestedResult.snapshot.caseItems[0].representation,'artwork');assert.deepEqual(Core.undo(nestedResult).snapshot,populated);
const shrink=Core.editStructure(u,{kind:'cubby',cubbyId:'root',patch:{w:300}});assert.ok(shrink.error);assert.equal(shrink.snapshot,u.snapshot);
const del=Core.editStructure(u,{kind:'delete',cubbyId:'root',moduleId:child.id});assert.equal(del.error,'');assert.ok(!del.snapshot.cubbies[child.childId]);assert.deepEqual(Core.undo(del).snapshot,u.snapshot);
const view={path:['root',child.childId],theme:1,cameras:{root:{zoom:1,x:12,y:-9}}};
const saved=CP.encode(u,view),loaded=CP.decode(saved);assert.deepEqual(loaded.snapshot,u.snapshot);assert.deepEqual(loaded.view,view);
for(const edit of [v=>v.version=9,v=>v.snapshot.next=0,v=>v.view.path=['root','missing'],v=>v.snapshot.cubbies.root.mods[0].scrollCells['1:1'][0].x=1e99,v=>v.snapshot.cubbies.root.mods[0].cellMeta['1:1'].color='not a color']){
 const v=JSON.parse(saved);edit(v);assert.throws(()=>CP.decode(JSON.stringify(v)));
}
assert.throws(()=>CP.decode('not json'));assert.throws(()=>CP.encode(Core.stage(s,'root','rack-1',{r:64}),{path:['root'],theme:0,cameras:{}}));
console.log('N3r1 structural transactions and versioned checkpoint codec passed');

assert.equal(Core.snapCoordinate(77,20,true),80);assert.equal(Core.snapCoordinate(77,20,false),77);assert.equal(Core.snapCoordinate(77,15,true),75);assert.throws(()=>Core.snapCoordinate(77,0,true));

const palette={name:'Twilight',panel:'#263c37',background:'#121e23',metal:'#8c6e5a',engraving:'#91ada1',text:'#e6e1d8'};
assert.deepEqual(View.materialRoles(palette),{rack:'#39504a',shelf:'#263c37',cubby:'#3e483f'});
const materialCommand=patch=>({kind:'materials',cubbyId:'root',patch});
let mat=Core.applyStructure(s,Core.previewStructure(s,materialCommand({scheme:'quiet'})));
assert.equal(mat.error,'');assert.equal(View.materialRoles(palette,mat.snapshot.materials).rack,'#243935');
mat=Core.editStructure(mat,materialCommand({theme:'Twilight',role:'rack',color:'#aabbcc'}));assert.equal(mat.error,'');
assert.equal(View.rackColor({},View.appearancePalette(palette,mat.snapshot.materials)),'#aabbcc');
assert.equal(View.rackColor({color:'#123456'},View.appearancePalette(palette,mat.snapshot.materials)),'#123456');
assert.notEqual(View.materialRoles(Object.assign({},palette,{name:'Evening'}),mat.snapshot.materials).rack,'#aabbcc');
const switched=Core.editStructure(mat,materialCommand({scheme:'balanced'}));assert.equal(View.materialRoles(palette,switched.snapshot.materials).rack,'#39504a');
assert.equal(View.materialRoles(palette,Core.editStructure(switched,materialCommand({scheme:'quiet'})).snapshot.materials).rack,'#aabbcc');
assert.equal(View.materialRoles(palette,Core.editStructure(mat,materialCommand({theme:'Twilight',reset:true})).snapshot.materials).rack,'#243935');
assert.ok(Core.editStructure(mat,materialCommand({theme:'Twilight',role:'rack',color:'red'})).error);
assert.deepEqual(CP.decode(CP.encode(mat,{path:['root'],theme:1,cameras:{}})).snapshot,mat.snapshot);
assert.deepEqual(Core.undo(mat).snapshot.materials,{scheme:'quiet',roleEdits:{}});

// Color-only sessions preview without publishing and commit as one Undo.
const batch={kind:'materialBatch',cubbyId:'root',edits:[materialCommand({scheme:'quiet'}),materialCommand({theme:'Twilight',role:'rack',color:'#aabbcc'}),{kind:'rackColor',cubbyId:'root',moduleId:'rack-1',patch:{color:'#123456'}}]};
const materialPreview=Core.previewStructure(s,batch);assert.ok(materialPreview.ok,materialPreview.error);assert.equal(JSON.stringify(s.snapshot),before);assert.equal(s.history.length,0);
assert.equal(materialPreview.snapshot.cubbies.root.mods[0].color,'#123456');assert.equal(View.materialRoles(palette,materialPreview.snapshot.materials).rack,'#aabbcc');
const materialApplied=Core.applyStructure(s,materialPreview);assert.equal(materialApplied.error,'');assert.equal(materialApplied.history.length,1);assert.equal(materialApplied.revision,s.revision+1);assert.deepEqual(Core.undo(materialApplied).snapshot,s.snapshot);
assert.deepEqual(Core.owners(materialApplied.snapshot),Core.owners(s.snapshot));assert.ok(Core.applyStructure(materialApplied,materialPreview).error);
assert.deepEqual(CP.decode(CP.encode(materialApplied,{path:['root'],theme:1,cameras:{}})).snapshot,materialApplied.snapshot);
for(const invalid of [{kind:'delete',cubbyId:'root',moduleId:'rack-1'},{kind:'cubby',cubbyId:'root',patch:{w:900}},{kind:'rackColor',cubbyId:'root',moduleId:'rack-1',patch:{color:'invalid'}}]){
 const rejected=Core.previewStructure(s,{...batch,edits:[...batch.edits,invalid]});assert.equal(rejected.ok,false);assert.ok(rejected.error);assert.equal(JSON.stringify(s.snapshot),before);
}
const emptyBatch=Core.previewStructure(s,{...batch,edits:[]});assert.equal(emptyBatch.ok,false);assert.equal(emptyBatch.error,'');
console.log('N3r1 atomic material session preview, validation, ownership and Undo passed');

// Picker math is visual only; RGB remains the canonical stored color.
for(const hex of ['#000000','#ffffff','#808080','#ff0000','#00ff00','#0000ff','#ffff00','#00ffff','#ff00ff','#123456','#aabbcc','#39504a']){
 const hsv=View.colorHSV(hex,217);assert.equal(View.hsvColor(hsv.h,hsv.s,hsv.v),hex);
}
assert.equal(View.colorHSV('#808080',217).h,217);assert.equal(View.hsvColor(360,1,1),'#ff0000');assert.equal(View.hsvColor(180,.5,.6),'#4d9999');assert.throws(()=>View.colorHSV('red'));assert.throws(()=>View.hsvColor(NaN,0,0));
console.log('N3r1 visual color picker RGB/HSV round trips passed');

// Growth preserves the parent footprint and all internal geometry/records.
const growthBase=Core.session(populated),growthChild=growthBase.snapshot.cubbies[child.childId],growthCommand={kind:'cubby',cubbyId:child.childId,patch:{name:'Expanded study',w:growthChild.w+200,h:growthChild.h+100}};
const growth=Core.previewStructure(growthBase,growthCommand);assert.ok(growth.ok,growth.error);assert.deepEqual(growth.snapshot.cubbies.root,growthBase.snapshot.cubbies.root);assert.deepEqual(growth.snapshot.cubbies[child.childId].mods,growthChild.mods);assert.deepEqual(Core.owners(growth.snapshot),Core.owners(growthBase.snapshot));
const grown=Core.applyStructure(growthBase,growth);assert.equal(grown.error,'');assert.equal(grown.history.length,1);assert.deepEqual(Core.undo(grown).snapshot,growthBase.snapshot);
const min=Core.cubbyMinimum(growthChild);assert.ok(min.w>=210&&min.h>=180);const tooSmall=Core.previewStructure(growthBase,{kind:'cubby',cubbyId:child.childId,patch:{w:130,h:100}});assert.equal(tooSmall.ok,false);assert.match(tooSmall.error,/Furniture needs at least/);
assert.deepEqual(Core.cubbyDimensionPatch({w:400,h:200,b:11},'w',500,2),{w:500,h:250,b:11});assert.deepEqual(Core.cubbyDimensionPatch({w:400,h:200,b:11},'h',300,null),{w:400,h:300,b:11});assert.deepEqual(Core.cubbyDimensionPatch({w:400,h:200,b:11},'b',12,2),{w:400,h:200,b:12});
assert.deepEqual(CP.decode(CP.encode(grown,{path:['root',child.childId],theme:1,cameras:{}})).snapshot,grown.snapshot);
console.log('N3r1 independent cubby growth, proportions, ownership, minimum extent and checkpoint passed');

// Optional conservative shrink suggestions move whole fixtures only.
const shrinkFixture=Core.fixture();shrinkFixture.cubbies.root.mods[0].x=180;
const shrinkSession=Core.session(shrinkFixture),shrinkBefore=JSON.stringify(shrinkSession.snapshot);
const shrinkCommand={kind:'cubby',cubbyId:'root',patch:{w:600,h:500}};
assert.equal(Core.previewStructure(shrinkSession,shrinkCommand).ok,false);
const shrinkSuggestion=Core.previewStructure(shrinkSession,{...shrinkCommand,rearrange:true});assert.ok(shrinkSuggestion.ok,shrinkSuggestion.error);
assert.equal(shrinkSuggestion.snapshot.cubbies.root.mods[0].x,100);
assert.deepEqual(shrinkSuggestion.snapshot.cubbies.root.mods[0],{...shrinkFixture.cubbies.root.mods[0],x:100});
assert.deepEqual(Core.owners(shrinkSuggestion.snapshot),Core.owners(shrinkFixture));assert.equal(JSON.stringify(shrinkSession.snapshot),shrinkBefore);
const shrinkApplied=Core.applyStructure(shrinkSession,shrinkSuggestion);assert.equal(shrinkApplied.error,'');assert.equal(shrinkApplied.history.length,1);assert.deepEqual(Core.undo(shrinkApplied).snapshot,shrinkSession.snapshot);
assert.ok(Core.applyStructure(shrinkApplied,shrinkSuggestion).error);
const impossible=Core.previewStructure(shrinkSession,{...shrinkCommand,rearrange:true,patch:{w:400,h:500}});assert.equal(impossible.ok,false);assert.match(impossible.error,/No safe suggestion/);
const multi={mods:[{id:'fixed',x:0,y:0,w:200,h:200},{id:'move',x:410,y:0,w:150,h:150}]};
assert.deepEqual(Core.suggestCubbyPositions(multi,350,350),[{id:'move',x:200,y:0}]);
assert.equal(Core.suggestCubbyPositions(multi,200,200),null);
assert.equal(Core.previewStructure(shrinkSession,{kind:'materialBatch',cubbyId:'root',edits:[{kind:'cubby',cubbyId:'root',rearrange:true,patch:{color:'#123456'}}]}).ok,false);
console.log('N3r1 explicit shrink suggestion, collision, metadata, atomic Undo passed');

// Exterior inventory is immediate only and independent of ownership state.
assert.deepEqual(View.cubbyPreviewSummary(Core.fixture().cubbies.root),{rack:1,shelf:0,cubby:0,items:3});
assert.deepEqual(View.cubbyPreviewSummary(growthBase.snapshot.cubbies.root),{rack:1,shelf:0,cubby:1,items:3});
assert.deepEqual(View.cubbyPreviewSummary(growthChild),{rack:1,shelf:0,cubby:0,items:1});
const previewView={path:['root'],theme:1,cameras:{}};
for(const mode of ['veiled','inventory','closed']){
 const v={...previewView,cubbyPreviewMode:mode};const restored=CP.decode(CP.encode(growthBase,v));assert.deepEqual(restored.view,v);assert.deepEqual(restored.snapshot,growthBase.snapshot);
}
assert.deepEqual(CP.decode(CP.encode(growthBase,previewView)).view,previewView);
assert.throws(()=>CP.encode(growthBase,{...previewView,cubbyPreviewMode:'detailed'}),/Invalid cubby preview mode/);
const badMode=JSON.parse(CP.encode(growthBase,previewView));badMode.view.cubbyPreviewMode=null;assert.throws(()=>CP.decode(JSON.stringify(badMode)),/Invalid cubby preview mode/);
console.log('N3r1 exterior inventory scope and backward-compatible preview view metadata passed');

// One drag geometry contract for racks and provisional footprints.
const dragBase={x:13,y:27,w:180,h:160};
assert.deepEqual(Core.fixtureDragPatch(dragBase,24,13,false,false,20,true),{x:40,y:40});
assert.deepEqual(Core.fixtureDragPatch(dragBase,24,13,false,false,20,false),{x:37,y:40});
assert.deepEqual(Core.fixtureDragPatch(dragBase,25,12,true,false,20,true),{w:207,h:173});
assert.deepEqual(Core.fixtureDragPatch(dragBase,25,12,true,true,20,true),{w:207});
assert.deepEqual(Core.fixtureDragPatch(dragBase,25,12,true,false,20,false),{w:205,h:172});
assert.throws(()=>Core.fixtureDragPatch(dragBase,NaN,0,false,false,20,true));
for(const zoom of [.5,.8,1,1.05,1.5,2.5]){
 const c=View.camera(s.snapshot.cubbies.root,800,400,zoom,{x:19,y:-27});
 const start={x:c.x+31*c.scale,y:c.y+45*c.scale},end={x:c.x+70*c.scale,y:c.y+70*c.scale};
 const patch=Core.fixtureDragPatch(dragBase,(end.x-start.x)/c.scale,(end.y-start.y)/c.scale,false,false,20,true);
 assert.deepEqual(patch,{x:60,y:60});
}
console.log('N3r1 shared local-grid drag geometry and camera scale invariance passed');

// Nested footprint and bounds validation never mutate a rejected snapshot.
let collisionBase=Core.editStructure(Core.session(Core.fixture()),{kind:'create',type:'cubby',cubbyId:'root',patch:{x:520,y:0,w:160,h:120}});assert.equal(collisionBase.error,'');
const outerModule=collisionBase.snapshot.cubbies.root.mods[1],outerId=outerModule.childId;
collisionBase=Core.editStructure(collisionBase,{kind:'create',type:'cubby',cubbyId:outerId,patch:{x:20,y:20,w:160,h:120}});assert.equal(collisionBase.error,'');
collisionBase=Core.editStructure(collisionBase,{kind:'create',type:'shelf',cubbyId:outerId,patch:{x:20,y:160,w:200,h:15}});assert.equal(collisionBase.error,'');
const innerModule=collisionBase.snapshot.cubbies[outerId].mods[0],collisionOriginal=JSON.stringify(collisionBase.snapshot);
const footprintCommand={kind:'child',cubbyId:outerId,moduleId:innerModule.id};
for(const patch of [{x:20,y:160,w:160,h:120},{x:-20,y:20,w:160,h:120},{x:400,y:20,w:160,h:120},{x:20,y:20,w:100,h:120}]){
 const rejected=Core.previewStructure(collisionBase,{...footprintCommand,patch});assert.equal(rejected.ok,false);assert.ok(rejected.error);assert.equal(JSON.stringify(collisionBase.snapshot),collisionOriginal);
}
const legal=Core.previewStructure(collisionBase,{...footprintCommand,patch:{x:20,y:40,w:200,h:100}});assert.ok(legal.ok,legal.error);
const nestedApplied=Core.applyStructure(collisionBase,legal);assert.equal(nestedApplied.error,'');assert.deepEqual(nestedApplied.snapshot.cubbies.root,collisionBase.snapshot.cubbies.root);assert.deepEqual(nestedApplied.snapshot.cubbies[innerModule.childId],collisionBase.snapshot.cubbies[innerModule.childId]);assert.deepEqual(Core.undo(nestedApplied).snapshot,collisionBase.snapshot);
console.log('N3r1 nested collision, out-of-bounds and footprint independence passed');

// Optional view preferences are validated in v1 without changing the snapshot.
const persistedView={path:['root'],theme:2,cameras:{root:{zoom:1.2,x:7,y:-9}},cubbyPreviewMode:'inventory',snapEnabled:true,showGrid:false,snapDistance:35};
assert.deepEqual(CP.decode(CP.encode(s,persistedView)).view,persistedView);
for(const patch of [{snapEnabled:1},{showGrid:'false'},{snapDistance:0},{snapDistance:101},{snapDistance:20.5}])assert.throws(()=>CP.encode(s,{...persistedView,...patch}),/Invalid/);
console.log('N3r1 durable view preference validation passed');

// Reset/import can remove or relocate the open child. Retain only the reachable prefix.
assert.deepEqual(View.reachablePath(growthBase.snapshot,['root',child.childId]),['root',child.childId]);
assert.deepEqual(View.reachablePath(Core.fixture(),['root',child.childId]),['root']);
assert.deepEqual(View.reachablePath(growthBase.snapshot,['root','missing',child.childId]),['root']);
assert.deepEqual(View.reachablePath(growthBase.snapshot,[child.childId]),['root']);
