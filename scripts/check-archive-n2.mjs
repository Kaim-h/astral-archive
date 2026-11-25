import assert from "node:assert/strict";
import * as C from "../quickshell/archive/ArchiveCore.mjs";
import * as V from "../quickshell/archive/ArchiveView.mjs";
const s=V.fixture(),m=C.rackAt(s,"root","rack-1");
assert.equal(C.validate(s),null);
assert.equal(C.owners(s).length,new Set(C.owners(s).map(e=>e.id)).size);
for(const c of Object.values(s.cubbies))for(const r of c.mods.filter(m=>m.type==="rack"))for(const cell of C.geometry(r).cells){
 const list=r.scrollCells[cell.key]||[];
 assert(C.contained(cell,list));assert(C.supported(cell,list));
}
const cells=C.geometry(m).cells,edges=V.seams(cells);
assert(edges.length<cells.reduce((n,c)=>n+c.poly.length,0));
const r=V.records(m)[0];assert.equal(V.hitScroll([r],r.x,r.y),r);
assert.equal(V.hitScroll([r],r.x+r.r+1,r.y),null);
assert.equal(V.parchment({name:"a.py"}),"#c8b69b");
assert.equal(V.seal({name:"a.py"}),"#547b89");
assert.equal(V.purpose({name:"a.py",purpose:"documents"}),"documents");
assert.equal(V.mix("#000000","#ffffff",.5),"#808080");
const cam=V.camera(s.cubbies.root,1024,600,1,{x:0,y:0});
assert(cam.scale>0);assert(cam.x>=0&&cam.y>=0);
const missing=V.markers(cells,[{key:"1:1"},{key:"999:999"}]);assert.equal(missing.cells[0].count,1);assert.equal(missing.missing,1);
let bad=C.clone(s);bad.cubbies.root.mods[1].childId="root";assert(C.validate(bad));
bad=C.clone(s);bad.cubbies.child.mods.push({id:"cycle",type:"cubby",childId:"root",x:0,y:300,w:130,h:100});bad.cubbies.child.h=420;assert(C.validate(bad));
bad=C.clone(s);bad.cubbies.root.mods.push({id:"dup-parent",type:"cubby",childId:"child",x:550,y:250,w:220,h:180});assert(C.validate(bad));
console.log("PASS B6-N2: settled nested fixture, canonical visual geometry, shared seams, palette, hit testing, markers, camera and hierarchy guards.");
