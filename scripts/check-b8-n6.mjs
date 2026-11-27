// N6 descriptive CPU-side synthetic measurements, no absolute time gate.
import {performance} from "node:perf_hooks";
import * as Core from "../quickshell/archive/ArchiveCore.mjs";
import * as View from "../quickshell/archive/ArchiveView.mjs";
import * as Projection from "../quickshell/archive/ArchiveRoomProjection.mjs";
import * as Terrain from "../quickshell/archive/ArchiveMapTerrain.mjs";
import * as CP from "../quickshell/archive/ArchiveCheckpoint.mjs";
import {denseFixture} from "../quickshell/tests/ArchiveB8N6Cases.mjs";
function measure(fn){
 const samples=[];let result;
 for(let i=0;i<6;i++){const start=performance.now();result=fn();const ms=performance.now()-start;if(i)samples.push(ms);}
 samples.sort((a,b)=>a-b);
 return {result,medianMs:+samples[2].toFixed(2),maxMs:+samples[4].toFixed(2)};
}
function timing(m){return {medianMs:m.medianMs,maxMs:m.maxMs};}
for(const copies of [1,8,24]){
 const {snapshot,roomId}=denseFixture(copies),before=JSON.stringify(snapshot),state=Core.session(snapshot);
 const atlas=measure(()=>View.mapPlan(snapshot)),plan=measure(()=>View.roomPlan(snapshot,roomId));
 const frame=View.mapFrame(atlas.result,1366,900,1),spec=Terrain.contourSpec(frame,1366,900,75);
 const contours=measure(()=>Terrain.contourSegments(spec));
 const projected=measure(()=>View.roomPerspective(snapshot,plan.result,1366,900));
 const raster=measure(()=>Projection.visibility(projected.result,1366,900));
 if(plan.result.shelves.length!==copies||!raster.result||raster.result.w*raster.result.h>1200000||contours.result.segments>Terrain.contourBudget)throw Error("N6 bounded geometry invariant");
 const rack=snapshot.cubbies.root.mods.find(m=>m.type==="rack");
 const staged=Core.stage(state,"root",rack.id,{r:Math.max(38,rack.r-1)});
 if(staged.draft.phase!=="pending")throw Error("Unexpected benchmark rack draft "+staged.draft.reason);
 const request=Core.request(staged),solver=measure(()=>Core.solve(request));
 const accepted=Core.accept(staged,solver.result),cancelled=Core.cancel(accepted);
 if(JSON.stringify(cancelled.snapshot)!==before||cancelled.history.length||cancelled.draft)throw Error("N6 solver cancel mutated state");
 const encoded=measure(()=>CP.encode(state,{path:["root"],theme:1,cameras:{}}));
 const decoded=measure(()=>CP.decode(encoded.result));
 if(JSON.stringify(decoded.result.snapshot)!==before||JSON.stringify(snapshot)!==before)throw Error("N6 measurement mutation");
 console.log("B8 N6 CPU-side sample "+JSON.stringify({copies,rooms:atlas.result.rooms.length,containers:Object.keys(snapshot.cubbies).length,files:Core.owners(snapshot).length,shelvesInRoom:plan.result.shelves.length,faces:projected.result.faces.length,rasterPixels:raster.result.w*raster.result.h,rasterIdentityBytes:raster.result.winners.byteLength+raster.result.floor.byteLength,contourSegments:contours.result.segments,checkpointBytes:Buffer.byteLength(encoded.result),solverPhase:accepted.draft.phase,map:timing(atlas),contours:timing(contours),plan:timing(plan),projection:timing(projected),visibility:timing(raster),solver:timing(solver),encode:timing(encoded),decode:timing(decoded)}));
}
