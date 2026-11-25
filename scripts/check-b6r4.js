'use strict';
// Offline syntax/provenance checks for browser-only B6r4. No DOM or native runtime is exercised.
const fs=require('node:fs');
const vm=require('node:vm');
const assert=require('node:assert/strict');
const base='docs/research/prototypes/2026-11-20/cubby-studies/';
const b6r3=fs.readFileSync(base+'Astral_Archive_Cubby_Study_B6r3.html','utf8');
const b6r4=fs.readFileSync(base+'Astral_Archive_Cubby_Study_B6r4.html','utf8');
assert.match(b6r3,/<title>Astral Archive · Cubby Study B6r3<\/title>/);
assert.match(b6r4,/<title>Astral Archive · Cubby Study B6r4<\/title>/);
const outer=b6r4.match(/<script>([\s\S]*?)<\/script>/);
assert(outer,'B6r4 outer JavaScript exists');
new vm.Script(outer[1],{filename:'B6r4-outer.js'});
const embedded=outer[1].match(/atob\("([A-Za-z0-9+/=]+)"\)/);
assert(embedded,'B6r4 embeds its P2R cell source');
const cell=Buffer.from(embedded[1],'base64').toString('utf8');
const cellScript=cell.match(/<script>([\s\S]*?)<\/script>/);
assert(cellScript,'Embedded physics JavaScript exists');
new vm.Script(cellScript[1],{filename:'B6r4-cell.js'});
const requiredOuter=[
 'function sendActiveCellToCase()', "if(d.action==='tray')", "if(d.action==='stashed')",
 'b4Cell.pendingStash', 'actualIds.size', "if(b4Cell.trayBody)", 'function syncCaseBridge()',
 'b6HolderUndoSnapshot', 'depthChanged', 'm.cellMeta[cell.key].depth=b4Cell.depthDraft',
 'function placeB6Panel(x,y)', "b6Handle.addEventListener('pointerdown'",
 "b6Handle.addEventListener('keydown'", "get cellBridge(){return b4Cell;}"
];
for(const term of requiredOuter)assert(outer[1].includes(term),'Missing B6r4 integration point: '+term);
const requiredCell=[
 'Lift into cell tray', "action:'tray'", "data.action==='stash'",
 'const fromTray=!!state.held', 'if(fromTray){state.held=null;state.transaction=null;}',
 "data.action==='depth'", 'function setCellDepth(value)'
];
for(const term of requiredCell)assert(cell.includes(term),'Missing embedded B6r4 bridge: '+term);
const expectedIDs=[
 'b6Reflow','b6ReflowHandle','b6ReflowHome','b6CellDepth','b6DepthReadout',
 'b6Holder','b6CaseBridge','b6BridgeStatus','b6BridgeSend','b6CasePending','b6Stash'
];
for(const id of expectedIDs){
 const rx=new RegExp('\\bid="'+id+'"','g');
 assert.equal([...b6r4.matchAll(rx)].length,1,'Expected exactly one outer HTML id='+id);
}
console.log('PASS B6r4: outer/embedded JS parse; bridge, provisional depth, movable panel, unique controls found.');
