'use strict';
const fs=require('node:fs');
const vm=require('node:vm');
const assert=require('node:assert/strict');
const base='docs/research/prototypes/2026-11-20/cubby-studies/';
const html=fs.readFileSync(base+'Astral_Archive_Cubby_Study_B6r6.html','utf8');
const previous=fs.readFileSync(base+'Astral_Archive_Cubby_Study_B6r5.html','utf8');
assert.match(previous,/<title>Astral Archive · Cubby Study B6r5<\/title>/);
assert.match(html,/<title>Astral Archive · Cubby Study B6r6<\/title>/);
assert.equal((html.match(/<\/script>/g)||[]).length,1,'Only one outer script closing tag');
const outer=html.match(/<script>([\s\S]*?)<\/script>/);
assert(outer,'Outer script');
new vm.Script(outer[1],{filename:'B6r6-outer.js'});
const encoded=outer[1].match(/atob\("([A-Za-z0-9+/=]+)"\)/);
assert(encoded,'Self-contained embedded physics');
const orig=Buffer.from(encoded[1],'base64').toString('utf8');
const encodedPatch=outer[1].match(/const b6r6PhysicsPatch=("(?:\\.|[^"\\])*");\nconst b6r6PhysicsSource/);
assert(encodedPatch,'Original-art physics patch');
const patch=JSON.parse(encodedPatch[1]);
const closing='\n})();\n</script>';
assert(orig.includes(closing),'Physics scope anchor');
const result=orig.replace('viewBox="0 0 1020 750"','viewBox="0 0 1240 750"')
 .replace('</style>','#trayLayer{display:none!important}</style>')
 .replace(closing,'\n'+patch+closing);
assert(result.includes('#trayLayer{display:none!important}'),'Third active holder is suppressed');
assert(result.includes('viewBox="0 0 1240 750"'),'Cradles outside the hex are fully visible');
const inner=result.match(/<script>([\s\S]*?)<\/script>/);
assert(inner,'Patched physics code');
new vm.Script(inner[1],{filename:'B6r6-cell.js'});
for(const marker of [
 "data-holder':'shelf-scrolls", "SHELF_PAGE_SIZE=4", "get caseCollapsed(){return caseCollapsed;}",
 "data-b6r6-toggle", "function zone(p){", "function shelfDraw(){",
 "data-b6r6-source", "action:'export',r5:true", "action:'inventory'"
])assert(patch.includes(marker),'Missing B6r6 physics feature: '+marker);
for(const marker of [
 "function b6r6DisplayShelf(target,items,source)", "holderArt.appendChild(rect(",
 "b6r6OuterCaseCollapsed", "b6r6CaseToggle", "b6r6ActiveItems",
 'holder.selectedActiveId', 'b6r6PhysicsSource=b4PhysicsSource.replace'
])assert(outer[1].includes(marker),'Missing B6r6 integration: '+marker);
for(const id of ['b6r6ActiveShelf','b6r6ActiveItems','b6r6ActiveCount','b6r6CaseToggle'])
 assert.equal([...html.matchAll(new RegExp('id="'+id+'"','g'))].length,1,'Single element '+id);
assert(!/<script\b[^>]*\bsrc=|<link\b[^>]*\bhref=/i.test(html),'No external asset dependency');
console.log('PASS B6r6: outer and embedded JS parse; original cradles, collapsible case and no duplicate tray.');
