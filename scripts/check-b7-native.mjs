import assert from 'node:assert/strict';
import fs from 'node:fs';
import {assets} from '../quickshell/archive/representation/B7AssetData.mjs';
import * as L from '../quickshell/archive/representation/B7Layout.mjs';
import * as C from '../quickshell/archive/RepresentationCatalog.mjs';
const m=JSON.parse(fs.readFileSync(new URL('../quickshell/archive/representation-assets/manifest.json',import.meta.url),'utf8'));
assert.deepEqual(assets,m.assets,'Runtime asset data must exactly match pinned manifest');
assert.equal(L.assetEntries().length,64);
for(const {id,edge} of L.assetEntries()){
 const a=L.assetFor(id),g=a.geometry;
 if(!g.contact){assert.equal(a.family,'artwork');continue;}
 const anchor=edge?g.edgeContact:g.contact,box=edge?g.edgeViewport:g.viewport;
 for(const scale of [.4,.86,1.3]){
  const p=L.supportedLayout(id,120,250,scale,edge);
  assert.ok(Math.abs(p.image.x+(anchor[0]-box[0])*scale-120)<1e-8);
  assert.ok(Math.abs(p.image.y+(anchor[1]-box[1])*scale-250)<1e-8);
  assert.ok(Math.abs(p.box.y+p.box.height-250)<1e-8);
  assert.ok(p.box.width>0&&p.box.height>0);
 }
}
assert.throws(()=>L.assetFor('__proto__'));
assert.throws(()=>L.supportedLayout('artwork/moonlit-mountains',0,0,1));
assert.throws(()=>L.supportedLayout('parcel/satchel',0,0,1,true));
assert.throws(()=>L.supportedLayout('sculpture/jar',0,0,-1));
assert.equal(C.representation('experiment.hdf5'),'scroll');
assert.equal(C.representation('instrument.csv'),'ledger');
assert.ok(!Object.hasOwn(C.pools,'instrument'));
console.log('B7-N1: pinned runtime data, all support transforms, no automatic instrument family passed');

// Upright layout uses the accepted variable thickness, shared contact and
// stable slot identities, including reserved space during presentation.
const records=[{id:'audio-a',variant:'record/v1'},{id:'ledger-a',variant:'ledger/v2'},null,{id:'font-a',variant:'tablet/v1'}];
for(const width of [90,250,510]){
 const layout=L.uprightGeometry(records,.95,width,310);
 assert.ok(layout.span<=width+1e-8);
 for(let i=0;i<records.length;i++){
  const s=layout.slots[i];if(!records[i]){assert.equal(s.w,0);continue;}
  const e=L.uprightEdge(records[i],s,.95,layout.fit,12);
  const g=L.assetFor(records[i].variant).geometry;
  assert.ok(Math.abs(e.y+(g.edgeContact[1]-g.edgeViewport[1])*.95-310)<1e-8);
  assert.ok(Math.abs(e.x+(g.edgeContact[0]-g.edgeViewport[0])*.95*layout.fit-(12+s.cx))<1e-8);
  assert.ok(s.w<=s.width);
 }
}
const moved=L.moveSlot(records,0,2);assert.equal(moved[2],records[0]);assert.equal(moved[0],null);
const swapped=L.moveSlot(moved,2,1);assert.equal(swapped[1],records[0]);assert.equal(swapped[2],records[1]);
assert.equal(L.moveSlot(records,2,1),records);assert.equal(L.moveSlot(records,0,-1),records);
assert.equal(records[0].id,'audio-a');
assert.throws(()=>L.uprightGeometry([records[0],records[0]],1,200,310));
assert.throws(()=>L.uprightGeometry([{id:'bad',variant:'sculpture/jar'}],1,200,310));
console.log('B7-N1 upright edge support, vacant and occupied moves, identity and invalid guards passed');

// Secondary supports and objects preserve an explicit shared shelf datum.
for(const id of ['sculpture/jar','sculpture/owl','parcel/satchel'])for(const scale of [.4,.86,1.3]){
 const mode=id.startsWith('parcel')?'tray':'plinth';
 for(const choice of ['shelf',mode]){
  const s=L.supportFixture(id,200,400,scale,choice),p=L.supportedLayout(id,s.contactX,s.supportY,scale);
  assert.equal(s.y+s.h,400);assert.equal(s.supportY,s.y);
  assert.ok(Math.abs(p.box.y+p.box.height-s.y)<1e-8);
  assert.ok(p.box.x>=s.x-1e-8&&p.box.x+p.box.width<=s.x+s.w+1e-8);
  assert.equal(s.lipHeight,choice==='tray'?8:0);
 }
}
assert.throws(()=>L.supportFixture('sculpture/jar',0,0,1,'tray'));
assert.throws(()=>L.supportFixture('record/v1',0,0,1,'plinth'));
console.log('B7-N1 secondary support contact and compatibility passed');
