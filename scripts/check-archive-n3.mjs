import assert from "node:assert/strict";
import * as C from "../quickshell/archive/ArchiveCore.mjs";
import * as V from "../quickshell/archive/ArchiveView.mjs";
import * as M from "../quickshell/archive/ArchiveMotion.mjs";
const original=V.fixture(),s=C.session(original),m=C.rackAt(original,"root","rack-1");
const ids=["test-a","test-b"],entries=C.owners(original),source=entries.find(e=>e.id===ids[0]);
const cell=C.geometry(m).cells.find(c=>c.key===source.key);
const empty=C.geometry(m).cells.find(c=>c.area>14000&&!(m.scrollCells[c.key]||[]).length);
assert(empty,"Need complete empty hex");
let choice=M.select(original,"root","rack",[],null,ids[0],false,false);
choice=M.select(original,"root","rack",choice.ids,choice.anchor,ids[1],true,false);assert.deepEqual(choice.ids,ids);
choice=M.select(original,"root","rack",[ids[0]],{kind:"rack",id:ids[0]},ids[1],false,true);assert.deepEqual(choice.ids,ids);
const sorted=s=>C.owners(s).map(e=>e.id).sort();
function settle(q,hz=60){
 for(let i=0;i<12*hz&&q.cells.size&&!q.error;i++)M.advance(q,1/hz);
 assert.equal(q.error,"");assert.equal(q.cells.size,0);
}
let q=M.begin(s,ids),p={cubbyId:"root",rackId:m.id,key:cell.key,local:{x:cell.cx,y:cell.cy-12}};
M.tether(q,p,{"test-a":{x:-24,y:0},"test-b":{x:24,y:0}});
assert.equal(q.cells.size,1);M.advance(q,1/30);assert(q.steps>0&&q.steps<=6);
assert.deepEqual(s.snapshot,original);assert.deepEqual(C.commitMotion(s,q).snapshot,original);
assert(Object.keys(M.positions(q)).length>=2);
M.release(q,true);settle(q);let rearranged=C.commitMotion(s,q);assert.equal(rearranged.error,"");assert.deepEqual(sorted(rearranged.snapshot),sorted(original));assert.deepEqual(C.undo(rearranged).snapshot,original);
q=M.begin(s,ids);M.lift(q);assert.equal(q.carried.length,2);assert.deepEqual(sorted(q.draft).concat(q.carried.map(x=>x.id)).sort(),sorted(original));assert.deepEqual(s.snapshot,original);
M.insert(q,"case",{});M.release(q,false);settle(q);let moved=C.commitMotion(s,q);assert.equal(moved.error,"");assert(ids.every(id=>moved.snapshot.caseItems.some(x=>x.id===id)));assert.deepEqual(sorted(moved.snapshot),sorted(original));
q=M.begin(moved,ids);M.lift(q);M.insert(q,{cubbyId:"root",rackId:m.id,key:empty.key,local:{x:empty.cx,y:empty.cy}},{});M.release(q,false);settle(q);
const back=C.commitMotion(moved,q);assert.equal(back.error,"");assert.deepEqual(sorted(back.snapshot),sorted(original));assert(C.supported(empty,C.rackAt(back.snapshot,"root",m.id).scrollCells[empty.key]));assert.deepEqual(C.undo(back).snapshot,moved.snapshot);assert.deepEqual(C.undo(C.undo(back)).snapshot,original);
assert(C.commitMotion(C.cancel(moved),q).error);
q=M.begin(s,ids);M.lift(q);assert.throws(()=>M.insert(q,{cubbyId:"root",rackId:m.id,key:"missing",local:{x:0,y:0}},{}));assert.deepEqual(s.snapshot,original);
const result=[];
for(const hz of [30,60,120]){
 const t=M.begin(s,["case-note"]);M.lift(t);M.insert(t,{cubbyId:"root",rackId:m.id,key:empty.key,local:C.topEntrance(empty,[],10),top:true},{});M.release(t,false);settle(t,hz);
 const end=C.commitMotion(s,t);assert.equal(end.error,"");const item=C.owners(end.snapshot).find(e=>e.id==="case-note").scroll;
 assert(C.supported(empty,[item]));result.push(item);
}
for(const x of result)assert(Math.hypot(x.x-result[0].x,x.y-result[0].y)<.15,"Fixed-step frame cadence drift");
const painted=C.paintCell(s,"root",m.id,"1:1","#9a7e61",12);
assert.equal(painted.error,"");assert.equal(C.rackAt(painted.snapshot,"root",m.id).cellMeta["1:1"].id,m.cellMeta["1:1"].id);
assert.deepEqual(sorted(painted.snapshot),sorted(original));assert.deepEqual(C.undo(painted).snapshot,original);
assert(C.paintCell(s,"root",m.id,"1:1","invalid",0).error);
console.log("PASS B6-N3: selection, active-only tethers, carried partition, atomic group transfers, stale/incomplete rejection, exact Undo, 30/60/120 Hz top-entry.");

// AUD-02: preserve empty depth-only cell metadata under the existing
// revision-scoped reflow protocol; no new geometry or physics behavior.
{
 const rack=t=>C.rackAt(t.snapshot,"root","rack-1"), solve=t=>C.accept(t,C.solve(C.request(t)));
 const shrink=(t,choices)=>solve(C.stage(t,"root","rack-1",{w:400,h:320},choices));
 const lost="-1:3",target="0:0",other="0:1",lost2="0:3";
 const initial=C.session(C.fixture());
 for(const [color,depth] of [[null,20],["#9a7e61",0],["#9a7e61",20]]){
  const edited=C.paintCell(initial,"root","rack-1",lost,color,depth),meta=rack(edited).cellMeta[lost],decision="paint:"+meta.id;
  const pending=shrink(edited),issue=pending.draft.result.review.find(x=>x.cellId===meta.id);
  assert.equal(pending.draft.phase,"attention");assert.equal(issue.type,"paint");assert(issue.options.includes(target));
  assert.deepEqual(pending.snapshot,edited.snapshot);assert.deepEqual(pending.history,edited.history);
  assert(C.apply(pending).error);assert.deepEqual(C.apply(pending).snapshot,edited.snapshot);
  assert.deepEqual(C.cancel(pending).snapshot,edited.snapshot);
  const relocated=shrink(edited,{[decision]:target});assert.equal(relocated.draft.phase,"ready");
  assert.deepEqual(C.projection(relocated).rack.cellMeta[target],meta);
  const committed=C.apply(relocated);assert.equal(committed.error,"");
  assert.deepEqual(rack(committed).cellMeta[target],meta);
  assert.equal(Object.values(rack(committed).cellMeta).filter(x=>x.id===meta.id).length,1);
  assert.deepEqual(sorted(committed.snapshot),sorted(edited.snapshot));assert.equal(C.validate(committed.snapshot),null);
  assert.deepEqual(C.undo(committed).snapshot,edited.snapshot);
  const discarded=C.apply(shrink(edited,{[decision]:"discard"}));assert.equal(discarded.error,"");
  assert(!Object.values(rack(discarded).cellMeta).some(x=>x.id===meta.id));
  assert.deepEqual(sorted(discarded.snapshot),sorted(edited.snapshot));
  assert.deepEqual(C.undo(discarded).snapshot,edited.snapshot);
 }
 // Default / reset depth must not create false reservations or reviews.
 for(const reset of [initial,C.paintCell(C.paintCell(initial,"root","rack-1",lost,null,20),"root","rack-1",lost,null,0)]){
  assert.equal(shrink(reset).draft.phase,"ready");assert.equal(shrink(reset).draft.result.review.length,0);
 }
 let edited=C.paintCell(initial,"root","rack-1",lost,null,20);
 edited=C.paintCell(edited,"root","rack-1",target,null,12);
 const first=rack(edited).cellMeta[lost],retained=rack(edited).cellMeta[target],key="paint:"+first.id;
 const reserved=shrink(edited,{[key]:target});
 assert.equal(reserved.draft.phase,"attention");assert(!reserved.draft.result.review.find(x=>x.cellId===first.id).options.includes(target));
 assert.deepEqual(reserved.draft.result.meta[target],retained);
 const groupConflict=shrink(edited,{"test-a":target,[key]:other});
 assert.equal(groupConflict.draft.phase,"attention");assert(!groupConflict.draft.result.review.find(x=>x.type==="group").options.includes(target));
 assert.deepEqual(groupConflict.draft.result.meta[target],retained);
 const groupWins=shrink(edited,{"test-a":other,[key]:other});
 assert.equal(groupWins.draft.phase,"attention");assert(!groupWins.draft.result.review.find(x=>x.cellId===first.id).options.includes(other));
 edited=C.paintCell(edited,"root","rack-1",lost2,null,16);
 const second=rack(edited).cellMeta[lost2],secondKey="paint:"+second.id;
 const double=shrink(edited,{[key]:other,[secondKey]:other});
 assert.equal(double.draft.phase,"attention");assert(!double.draft.result.review.find(x=>x.cellId===second.id).options.includes(other));
 assert.deepEqual(double.snapshot,edited.snapshot);
 const distinct=shrink(edited,{[key]:other,[secondKey]:"1:0"});
 const applied=C.apply(distinct);assert.equal(applied.error,"");
 assert.deepEqual(rack(applied).cellMeta[other],first);assert.deepEqual(rack(applied).cellMeta["1:0"],second);
 assert.deepEqual(rack(applied).cellMeta[target],retained);assert.deepEqual(sorted(applied.snapshot),sorted(edited.snapshot));
 assert.deepEqual(C.undo(applied).snapshot,edited.snapshot);
 // Shape changes invalidate prior decisions; stale worker replies cannot apply.
 const revised=C.stage(distinct,"root","rack-1",{w:410});
 assert.deepEqual(revised.draft.decisions,{});assert.equal(C.accept(revised,{revision:distinct.revision,result:distinct.draft.result}),revised);
}
console.log("PASS AUD-02: depth/pigment review, reservation, explicit relocate/discard, conflicts, reset, ownership, Cancel/Undo and stale proposal.");
