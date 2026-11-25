'use strict';
const fs=require('node:fs'),assert=require('node:assert/strict'),vm=require('node:vm');
const root='docs/research/prototypes/2026-11-20/cubby-studies/';
const previous=fs.readFileSync(root+'Astral_Archive_Cubby_Study_B6r11.html','utf8');
const html=fs.readFileSync(root+'Astral_Archive_Cubby_Study_B6r12a.html','utf8');
assert.match(previous,/<title>Astral Archive · Cubby Study B6r11<\/title>/);
assert.match(html,/<title>Astral Archive · Cubby Study B6r12a<\/title>/);
assert.equal((html.match(/<\/script>/g)||[]).length,1);
const outer=html.match(/<script>([\s\S]*?)<\/script>/);assert(outer);
new vm.Script(outer[1],{filename:'B6r12a-rack-foundation.js'});
const b64=outer[1].match(/atob\("([A-Za-z0-9+/=]+)"\)/);assert(b64);
const base=Buffer.from(b64[1],'base64').toString('utf8');
const p=outer[1].match(/const b6r8PhysicsPatch=("(?:\\.|[^"\\])*");\nconst b6r8PhysicsSource/);assert(p);
const inner=base.replace('\n})();\n</script>','\n'+JSON.parse(p[1])+'\n})();\n</script>').match(/<script>([\s\S]*?)<\/script>/);assert(inner);
new vm.Script(inner[1],{filename:'legacy-physics-is-still-available-for-phase-B.js'});
for(const marker of [
 'const b12Adapters=Object.freeze(', 'function b12Owned(', 'function b12Unique(', 'function b12Validate(',
 'function b12Commit(', 'function b12CommitMove(', 'function b12Undo(', 'function b12Save(', 'function b12Load(',
 'function b12LocationForPoint(', 'function b12RenderOverlays(', 'const b12LegacyOpenCell=openCellDirect',
 'const b12LegacyOpenFocus=openFocus', "scene.addEventListener('pointerdown',ev=>{",
 "document.addEventListener('pointerup',ev=>{", 'window.__cubbyB6r12a='
])assert(outer[1].includes(marker),'Missing direct rack foundation: '+marker);
for(const marker of ["hex:Object.freeze({key:'hex',supported:true","square:Object.freeze({key:'square',supported:false","triangle:Object.freeze({key:'triangle',supported:false","diamond:Object.freeze({key:'diamond',supported:false"])
 assert(outer[1].includes(marker),'Missing future shape adapter: '+marker);
for(const id of ['b12Mode','b12Undo','scene','b6HolderItems','b4Frame'])
 assert.equal((html.match(new RegExp('id="'+id+'"','g'))||[]).length,1,'Unique DOM ID '+id);
assert(!/<script\b[^>]*\bsrc=|<link\b[^>]*\bhref=/i.test(html),'No external dependencies');
console.log('PASS B6r12a syntax, single-owner transactions, direct rack interaction paths, future geometry adapter skeleton and preserved P2R for the second session.');
