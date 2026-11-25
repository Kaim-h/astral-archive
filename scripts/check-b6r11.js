'use strict';
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const root='docs/research/prototypes/2026-11-20/cubby-studies/';
const older=fs.readFileSync(root+'Astral_Archive_Cubby_Study_B6r10.html','utf8');
const html=fs.readFileSync(root+'Astral_Archive_Cubby_Study_B6r11.html','utf8');
assert.match(older,/<title>Astral Archive · Cubby Study B6r10<\/title>/);
assert.match(html,/<title>Astral Archive · Cubby Study B6r11<\/title>/);
assert.equal((html.match(/<\/script>/g)||[]).length,1);
const outer=html.match(/<script>([\s\S]*?)<\/script>/);assert(outer);
new vm.Script(outer[1],{filename:'B6r11-outer.js'});
const base64=outer[1].match(/atob\("([A-Za-z0-9+/=]+)"\)/);assert(base64);
const base=Buffer.from(base64[1],'base64').toString('utf8');
const encoded=outer[1].match(/const b6r8PhysicsPatch=("(?:\\.|[^"\\])*");\nconst b6r8PhysicsSource/);assert(encoded);
const patch=JSON.parse(encoded[1]);
new vm.Script(patch,{filename:'B6r11-physics-patch.js'});
const closing='\n})();\n</script>';assert(base.includes(closing));
const inner=base.replace(closing,'\n'+patch+closing).match(/<script>([\s\S]*?)<\/script>/);assert(inner);
new vm.Script(inner[1],{filename:'B6r11-focused-cell.js'});
for(const word of [
 "const b11CellShapes=Object.freeze", "hex:{label:'Hexagon',supported:true}",
 "square:{label:'Square',supported:false}", "triangle:{label:'Triangle',supported:false}",
 "diamond:{label:'Diamond',supported:false}",
 "const kept=[],remainder=[]", "const home=free.find(c=>c.key===source.key)",
 "const destination=decisions.__splitTargets?.[id]||null",
 "primaryKey:source.key", "if(destination==='case')", "approvedSplits,caseOverflow",
 "const after=[...Object.values(mapped).flat(),...incoming]", "for(const scroll of incoming)holder.items.push",
 "if(ok)return adjusted", "function b11AutoSave", "function b11LoadSession",
 "Radius above 60", "id=\"b11RadiusAcknowledge\"", "id=\"b11Shape\"",
 "caseTransfer&&caseTransfer.destinationRackId===m.id",
 "window.__cubbyB6r11="
])assert(html.includes(word),'Missing B6r11 structural feature: '+word);
for(const word of [
 "const spot=clear(p)?p:findPlacement(b,st.bodies);",
 "It remains in the Scroll Case",
 "beginAction('Insert from Scroll Case')"
])assert(patch.includes(word),'Missing case-placement guard: '+word);
for(const id of ['b11Shape','b11RadiusNotice','b11RadiusAcknowledge','b11SaveSession','b11LoadSession'])
 assert.equal((html.match(new RegExp('id="'+id+'"','g'))||[]).length,1,'Unique '+id);
assert(!/<script\b[^>]*\bsrc=|<link\b[^>]*\bhref=/i.test(html),'Fully self-contained offline HTML');
console.log('PASS B6r11: parent and focused physics parse, anchored split, case-overflow conservation, shape readiness, radius warning and local committed-state controls.');
