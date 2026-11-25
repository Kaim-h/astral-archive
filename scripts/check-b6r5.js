'use strict';
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const path='docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r5.html';
const html=fs.readFileSync(path,'utf8');
assert.match(html,/<title>Astral Archive · Cubby Study B6r5<\/title>/);
assert.equal((html.match(/<\/script>/g)||[]).length,1,'Exactly one outer script end');
const outer=html.match(/<script>([\s\S]*?)<\/script>/);
assert(outer,'Outer script present');
new vm.Script(outer[1],{filename:'B6r5-outer.js'});
const base64=outer[1].match(/atob\("([A-Za-z0-9+/=]+)"\)/);
assert(base64,'Embedded original P2R physics');
const original=Buffer.from(base64[1],'base64').toString('utf8');
const payload=outer[1].match(/const b6r5PhysicsPatch=("(?:\\.|[^"\\])*");\nconst b6r5PhysicsSource/);
assert(payload,'B6r5 patch text');
const patch=JSON.parse(payload[1]);
const needle='\n})();\n</script>';
assert(original.includes(needle),'Original simulator IIFE closure');
const updated=original.replace(needle,'\n'+patch+needle);
assert(updated.includes('window.__b6r5Shelves'),'Physics patch injected');
const inner=updated.match(/<script>([\s\S]*?)<\/script>/);
assert(inner,'Patched cell script present');
new vm.Script(inner[1],{filename:'B6r5-cell.js'});
for(const term of [
 'const holder={items:[],active:[]', 'if(d.r5){', "if(d.action==='inventory')",
 'b4Cell.previewActive','b4Cell.previewCase', 'holderActive:JSON.stringify(holder.active)',
 'function b6PointerInsideActive(ev)', 'const b6r5PhysicsSource='
])assert(outer[1].includes(term),'Missing parent integration: '+term);
for(const term of [
 'function shelfDraw()', "function finish()", "svg.addEventListener('pointerup'",
 "window.__b6r5Shelves", "action:'inventory'", "action:'export',r5:true",
 "st.activeShelf", "st.caseShelf", "snapshot=function()"
])assert(patch.includes(term),'Missing physics integration: '+term);
for(const id of ['b6r5ActiveShelf','b6r5ActiveItems','b6r5ActiveCount'])
 assert.equal((html.match(new RegExp('id="'+id+'"','g'))||[]).length,1,'Unique element '+id);
console.log('PASS B6r5 outer, embedded physics, two-shelf bridge and save invariants syntax/provenance.');
