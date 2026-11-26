import {run} from '../quickshell/tests/ArchiveB8FoundationCases.mjs';
import {populatedFixture} from '../quickshell/tests/ArchiveB8ShelfFixture.mjs';
import * as Core from '../quickshell/archive/ArchiveCore.mjs';
import * as Spatial from '../quickshell/archive/ArchiveSpatial.mjs';
import * as Checkpoint from '../quickshell/archive/ArchiveCheckpoint.mjs';
import {performance} from 'node:perf_hooks';
console.log('PASS B8-N1/N2 shared hierarchy, geometry, ownership, transaction, checkpoint and view contract: '+run()+' assertions.');
// Descriptive timings only: no absolute CI wall-time gate. Construct the
// fixture before measurement, alternate geometry and appearance edits,
// verify exact publication and Undo, and report retained serialized history.
function stats(a){
 const s=a.slice().sort((x,y)=>x-y);
 return {medianMs:+((s[4]+s[5])/2).toFixed(2),maxMs:+s[s.length-1].toFixed(2)};
}
for(const copies of [1,8,24]){
 const specimen=populatedFixture(copies),original=JSON.stringify(specimen);
 let state=Core.session(specimen),previews=[],commits=[],undos=[];
 const ownerIds=Core.owners(specimen).map(o=>o.id).sort().join('|');
 for(let i=0;i<13;i++){
  const cmd=i%2===0?{kind:'spatialShelfEdit',containerId:'root',patch:{h:1051+i}}:
     {kind:'spatialAppearance',containerId:'root',patch:{palette:(i%3),family:'Astral'}};
  const start=performance.now(),proposal=Core.previewStructure(state,cmd),mid=performance.now();
  if(!proposal.ok)throw Error(proposal.error||'No valid benchmark preview');
  const next=Core.applyStructure(state,proposal),end=performance.now();
  if(next.error||JSON.stringify(next.snapshot)!==JSON.stringify(proposal.snapshot))throw Error(next.error||'Preview mismatch');
  state=next;if(i>=3){previews.push(mid-start);commits.push(end-mid);}
 }
 const retained=Buffer.byteLength(JSON.stringify(state.history)),snapshotBytes=Buffer.byteLength(JSON.stringify(state.snapshot));
 const checkpoint=Checkpoint.encode(state,{path:['root'],theme:1,cameras:{}});
 if(JSON.stringify(Checkpoint.decode(checkpoint).snapshot)!==JSON.stringify(state.snapshot))throw Error('Benchmark roundtrip mismatch');
 if(Core.owners(state.snapshot).map(o=>o.id).sort().join('|')!==ownerIds)throw Error('Benchmark owner loss');
 for(let i=0;i<13;i++){
  const start=performance.now();state=Core.undo(state);const end=performance.now();
  if(state.error)throw Error(state.error);if(i<10)undos.push(end-start);
 }
 if(JSON.stringify(state.snapshot)!==original||state.history.length)throw Error('Benchmark Undo mismatch');
 const report={copies,rooms:Object.keys(specimen.spatial.rooms).length,containers:Object.keys(specimen.cubbies).length,
  files:Core.owners(specimen).length,apps:Spatial.appPlacements(specimen).length,snapshotBytes,
  retainedUndoEntries:13,serializedUndoBytes:retained,checkpointBytes:Buffer.byteLength(checkpoint),
  preview:stats(previews),apply:stats(commits),undo:stats(undos)};
 console.log('B8 N2d populated measurement '+JSON.stringify(report));
}
