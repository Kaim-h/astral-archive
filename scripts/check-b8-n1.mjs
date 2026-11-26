import {run} from '../quickshell/tests/ArchiveB8FoundationCases.mjs';
import {fixture} from '../quickshell/tests/ArchiveB8ShelfFixture.mjs';
import * as Core from '../quickshell/archive/ArchiveCore.mjs';
import {performance} from 'node:perf_hooks';
console.log('PASS B8-N1/N2a shared hierarchy, geometry, ownership, transaction, checkpoint and view contract: '+run()+' assertions.');
let session=Core.session(fixture()),previews=[],commits=[];
for(let i=0;i<13;i++){
 const command={kind:'spatialShelfEdit',containerId:'root',patch:{h:1051+i}};
 const start=performance.now(),p=Core.previewStructure(session,command),mid=performance.now();
 if(!p.ok)throw Error(p.error);
 session=Core.applyStructure(session,p);
 const end=performance.now();if(session.error)throw Error(session.error);
 if(i>=3){previews.push(mid-start);commits.push(end-mid);}
}
function median(samples){const s=samples.slice().sort((a,b)=>a-b);return ((s[4]+s[5])/2).toFixed(2);}
console.log('B8 N2a populated sample (not a performance gate): '+Core.owners(session.snapshot).length+' file owners; median preview '+median(previews)+' ms, Apply '+median(commits)+' ms; serialized Undo history '+Buffer.byteLength(JSON.stringify(session.history))+' bytes.');
