import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import * as C from '../quickshell/archive/RepresentationCatalog.mjs';
const dir=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../quickshell/archive/representation-assets');
const m=JSON.parse(fs.readFileSync(path.join(dir,'manifest.json'),'utf8'));
assert.equal(m.schema,1);assert.equal(Object.keys(m.assets).length,46);let files=0;
for(const [family,pool] of Object.entries(C.pools)){
 assert.equal(pool.length,family==='sculpture'?16:6);
 assert.equal(new Set(pool).size,pool.length);
 for(const id of pool){
  const a=m.assets[id];assert.equal(a.family,family);assert.equal(a.id,id);
  const g=a.geometry;
  assert.ok(g.viewport.every(Number.isFinite)&&g.bounds.every(Number.isFinite));
  assert.ok(g.bounds[2]>g.bounds[0]&&g.bounds[3]>g.bounds[1]);
  if(g.contact){
   assert.equal(g.contact[1],g.bounds[3]);
   const s=C.supportedImage(g,90,200,.75);
   assert.equal(s.y+(g.contact[1]-g.viewport[1])*.75,200);
   assert.equal(s.x+(g.contact[0]-g.viewport[0])*.75,90);
  }
  if(a.edge){
   assert.equal(g.edgeContact[1],g.contact[1]);assert.equal(g.edgeBounds[2],g.thickness);
   const s=C.supportedImage(g,90,200,.75,true);assert.equal(s.y+(g.edgeContact[1]-g.edgeViewport[1])*.75,200);
  }
  for(const file of [a.face,a.edge].filter(Boolean)){
   const svg=fs.readFileSync(path.join(dir,file),'utf8');
   assert.ok(svg.startsWith('<svg xmlns=')&&svg.endsWith('</svg>\n'));
   assert.ok(!/<script|<foreignObject|var\(--|(?:href|src)=/i.test(svg));
   for(const [,ref] of svg.matchAll(/url\(#([^)]+)\)/g))assert.ok(svg.includes('id="'+ref+'"'),file+' unresolved '+ref);
   files++;
  }
 }
}
assert.equal(files,64);
for(const [name,f] of [['a.TAR.GZ','parcel'],['notes.tar.zst','parcel'],['moon.webp','artwork'],['x.pptx','artwork'],['seal.stl','sculpture'],['sound.flac','record'],['lab.csv','ledger'],['x.woff2','tablet'],['study.pdf','scroll'],['data.hdf5','scroll'],['.config','scroll'],['noext','scroll'],['C:\\test\\x.PNG','artwork']])assert.equal(C.representation(name),f,name);
for(const family of Object.keys(C.pools)){
 const a=C.chooseVariant(family,'stable-123');
 assert.equal(a,C.chooseVariant(family,'stable-123'));
 assert.equal(C.chooseVariant(family,'stable-123',C.pools[family][0]),C.pools[family][0]);
 assert.throws(()=>C.chooseVariant(family,'stable-123','missing'));
 assert.throws(()=>C.chooseVariant(family,''));
 assert.throws(()=>C.chooseVariant(family,'',C.pools[family][0]));
}
assert.deepEqual(C.resolveAppearance({id:'abc',name:'x.zip',compact:true}),{family:'scroll',variant:null});
for(const profile of ['bronze','stone','slim']){
 const g=C.frameGeometry(120,160,profile);assert.ok(g.aperture[2]>0&&g.aperture[3]>0);
 assert.equal(g.contact[1],160);assert.equal(g.materialRole,profile==='stone'?'background':'metal');
}
assert.throws(()=>C.frameGeometry(200,11,'stone'));
const geos=['record/v1','ledger/v2','tablet/v1'].map(id=>m.assets[id].geometry);
for(const scale of [.64,1,1.3])for(const fixed of [false,true]){
 const l=C.uprightLayout([geos[0],null,geos[1],geos[2]],scale,120,322,{fixed,maxThickness:26});
 assert.ok(l.span<=120+1e-9);
 assert.equal(l.slots[1].w,0);
 for(let i=0;i<l.slots.length;i++){const s=l.slots[i];assert.equal(s.y+s.h,322);assert.ok(s.w<=s.width);if(i)assert.ok(Math.abs(s.left-l.slots[i-1].left-l.slots[i-1].width)<1e-9);}
}
console.log('B7-C: 46 variants, 64 SVG files, policy and support/slot geometry checks passed');
