import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";
import * as C from "../quickshell/archive/ArchiveCore.mjs";
import * as V from "../quickshell/archive/ArchiveView.mjs";
const html=fs.readFileSync("docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r12b3.html","utf8");
const names=["cellName","cellPoly","clipPolygon","areaPoly","latticeForBox","insetConvex","geomForRack","wallPoly","interiorDistance","projectIntoCell","scrollFit","staticScrollSpot","hashStr","seeded01","parseReflowNumbers","b12bBodies","b12bEdges","b12bStep","b12bContained","b12bSupported","b12bPack","b12bPlan","b12bTraceVoid","b12bVoidAtlas","b12bRegionAt","b12bTopEntrance"];
function extract(name){
 const start=html.indexOf("\nfunction "+name+"(")+1;assert(start,name);
 const header=html.slice(start).match(/^function [^(]+\([^\n]*?\)\s*\{/);assert(header,name);
 let depth=1,quote=null,esc=false,lineComment=false,blockComment=false;
 for(let i=start+header[0].length;i<html.length;i++){
  const c=html[i],n=html[i+1];
  if(lineComment){if(c==="\n")lineComment=false;continue;}
  if(blockComment){if(c==="*"&&n==="/"){blockComment=false;i++;}continue;}
  if(quote){if(esc){esc=false;continue;}if(c==="\\"){esc=true;continue;}if(c===quote)quote=null;continue;}
  if(c==="/"&&n==="/"){lineComment=true;i++;continue;}
  if(c==="/"&&n==="*"){blockComment=true;i++;continue;}
  if(c==="'"||c==='"'||c.charCodeAt(0)===96){quote=c;continue;}
  if(c==="{")depth++;if(c==="}"&&!--depth)return html.slice(start,i+1);
 }
 throw Error("Unclosed "+name);
}
const ctx=vm.createContext({structuredClone});
vm.runInContext("const RACK_PAD=11,B6_WALL=3.2,clamp=(x,a,b)=>Math.max(a,Math.min(b,x));\n"+names.map(extract).join("\n")+"\nthis.api={"+names.join(",")+"};",ctx);
const B=ctx.api,plain=x=>JSON.parse(JSON.stringify(x)),eq=(a,b,label)=>assert.deepEqual(plain(a),plain(b),label);
let geom=0,plans=0;
for(const snapshot of [C.fixture(),V.fixture()])for(const c of Object.values(snapshot.cubbies))for(const m of c.mods.filter(q=>q.type==="rack")){
 for(const r of [38,48,52,56,57,59,60,64,74,75,76])for(const dims of [[m.w,m.h],[m.w-19,m.h-17]]){
  const p={x:m.x,y:m.y,w:dims[0],h:dims[1],r};const rack=Object.assign({},m,p);
  eq(C.geometry(rack),B.geomForRack(rack),"Geometry "+m.id+" r"+r);geom++;
  if([38,52,56,60,75,76].includes(r)&&dims[0]===m.w){eq(C.plan(m,p,{}),B.b12bPlan(m,p,{}),"Plan "+m.id+" r"+r);plans++;}
 }
 const cell=C.geometry(m).cells.find(c=>c.area>8000),records=m.scrollCells[cell.key]||[];
 const native=C.clone(records),browser=C.clone(records),a=C.bodies(native),b=B.b12bBodies(browser),ae=C.edges(cell),be=B.b12bEdges(cell);
 for(let i=0;i<240;i++)assert.equal(C.step(cell,a,ae),B.b12bStep(cell,b,be));
 eq(native,browser,"Fixed-step positions");eq(C.voidAtlas(cell,records),B.b12bVoidAtlas(cell,records),"Connected void atlas");
 eq(C.topEntrance(cell,records,9),B.b12bTopEntrance(cell,records,9),"Top entrance");
}
const m=C.fixture().cubbies.root.mods[0],p=Object.assign({},m,{r:38});
const dest=C.geometry(p).cells.find(q=>q.key!=="1:1"&&q.area>3600).key,choices={"test-b":"case","test-c":dest};
eq(C.plan(m,p,choices),B.b12bPlan(m,p,choices),"Explicit split");plans++;
console.log("PASS B6-N3 browser/native numerical parity: "+geom+" geometry comparisons, "+plans+" complete plans, fixed-step bodies, void contours and top entrances.");
