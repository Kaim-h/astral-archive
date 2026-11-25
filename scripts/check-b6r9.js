'use strict';
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const path='docs/research/prototypes/2026-11-20/cubby-studies/';
const b8=fs.readFileSync(path+'Astral_Archive_Cubby_Study_B6r8.html','utf8');
const b9=fs.readFileSync(path+'Astral_Archive_Cubby_Study_B6r9.html','utf8');
assert.match(b8,/<title>Astral Archive · Cubby Study B6r8<\/title>/);
assert.match(b9,/<title>Astral Archive · Cubby Study B6r9<\/title>/);
assert.equal((b9.match(/<\/script>/g)||[]).length,1,'One outer script');
const script=b9.match(/<script>([\s\S]*?)<\/script>/);assert(script);
new vm.Script(script[1],{filename:'B6r9-outer.js'});
const b64=script[1].match(/atob\("([A-Za-z0-9+/=]+)"\)/);assert(b64);
const decoded=Buffer.from(b64[1],'base64').toString('utf8');
const patch=script[1].match(/const b6r8PhysicsPatch=("(?:\\.|[^"\\])*");\nconst b6r8PhysicsSource/);assert(patch);
const joined=decoded.replace('\n})();\n</script>','\n'+JSON.parse(patch[1])+'\n})();\n</script>');
const inner=joined.match(/<script>([\s\S]*?)<\/script>/);assert(inner);
new vm.Script(inner[1],{filename:'B6r9-cell.js'});
for(const v of [
 'function b6Reflow(m,next,decisions={})',
 'if(m.w===cand.w&&m.h===cand.h&&m.r===cand.r)',
 'unchanged:true,moves:[],topologyChanged:false',
 'const moves=[]','const topologyChanged=old.length!==fresh.length||old.some',
 'function b6DesiredCenter(cell,oldRack,newRack)',
 'b6Preview.moveApprovals={};b6Preview.topologyApproved=false',
 'function refreshB6Status()','function applyRackResize()',
 'Review and approve every proposed cell movement',
 'b6MovementReview','b9ReviewList','b9ReviewRow',
 "textContent='Review all'",'function b9UpdateRackGhost(pointerEvent)',
 'b9RackScrollGhost','get rackDragGhost(){return b9RackGhost;}',
 "document.addEventListener('pointermove',event=>",
 'function b9RemoveRackGhost()'
])assert(b9.includes(v),'Missing B6r9 integration '+v);
assert(!b9.includes(' // Improve adjacency without sacrificing sensible placement. Swap ONLY feasible'),
 'Remove adjacency optimizer that could reshuffle equal choices');
for(const id of ['b6MovementReview','b6SplitIssues','b6Reflow','b6Apply','b6ReflowHandle'])
 assert.equal((b9.match(new RegExp('id="'+id+'"','g'))||[]).length,1,'Unique element '+id);
assert(!/<script\b[^>]*\bsrc=|<link\b[^>]*\bhref=/i.test(b9),'One self-contained HTML');
console.log('PASS B6r9: no-op preservation, positional/lattice review gate, top-layer rack drag ghost, standalone scripts.');
