'use strict';
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const dir='docs/research/prototypes/2026-11-20/cubby-studies/';
const html=fs.readFileSync(dir+'Astral_Archive_Cubby_Study_B6r10.html','utf8');
assert.match(html,/<title>Astral Archive · Cubby Study B6r10<\/title>/);
assert.equal((html.match(/<\/script>/g)||[]).length,1,'Single outer script');
const outer=html.match(/<script>([\s\S]*?)<\/script>/);assert(outer);
new vm.Script(outer[1],{filename:'B6r10-outer.js'});
const base64=outer[1].match(/atob\("([A-Za-z0-9+/=]+)"\)/);assert(base64);
const base=Buffer.from(base64[1],'base64').toString('utf8');
const match=outer[1].match(/const b6r8PhysicsPatch=("(?:\\.|[^"\\])*");\nconst b6r8PhysicsSource/);assert(match);
const patch=JSON.parse(match[1]);
new vm.Script(patch,{filename:'B6r10-patch.js'});
const combined=base.replace('\n})();\n</script>','\n'+patch+'\n})();\n</script>');
const inner=combined.match(/<script>([\s\S]*?)<\/script>/);assert(inner);
new vm.Script(inner[1],{filename:'B6r10-combined-cell.js'});
for(const term of ["const requestedTargets=decisions.__targets||{};","const same=fresh.find(t=>t.key===source.key);",
 "if(source.key!==target.key)moves.push(","choices,topologyChanged","decisions.__splitAnchors?.[id]",
 "picker.className='b10Destination'","let caseTransfer=null","function b10CaseTarget(ev)",
 "casePayload=holder.items.filter(item=>item.id!==caseCarry?.id)","rackUI.cellKey=null;rackUI.scrollId=null; // leaving a cell must clear its highlight",
 "window.__cubbyB6r10="])assert(outer[1].includes(term),'Missing outer feature: '+term);
for(const term of ["Base P2R already prepared the original held-scroll insertion","beginAction('Insert from Scroll Case')",
 "st.insertion={id:b.id","st.caseShelf=st.caseShelf.filter(x=>x.id!==b.id)"])
 assert(patch.includes(term),'Missing physics insertion: '+term);
assert(!patch.includes('st.held=null;st.insertion=null;st.transaction=null;st.caseShelf.push(item(d.carried));'));
assert(!/<script\b[^>]*\bsrc=|<link\b[^>]*\bhref=/i.test(html));
console.log('PASS B6r10 standalone source, stable matching, editable move/split destinations and restored P2R insertion.');
