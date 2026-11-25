'use strict';
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const root='docs/research/prototypes/2026-11-20/cubby-studies/';
const previous=fs.readFileSync(root+'Astral_Archive_Cubby_Study_B6r7.html','utf8');
const html=fs.readFileSync(root+'Astral_Archive_Cubby_Study_B6r8.html','utf8');
assert.match(previous,/<title>Astral Archive · Cubby Study B6r7<\/title>/);
assert.match(html,/<title>Astral Archive · Cubby Study B6r8<\/title>/);
assert.equal((html.match(/<\/script>/g)||[]).length,1,'One outer HTML script');
const outer=html.match(/<script>([\s\S]*?)<\/script>/);assert(outer);
new vm.Script(outer[1],{filename:'B6r8-outer.js'});
const raw64=outer[1].match(/atob\("([A-Za-z0-9+/=]+)"\)/);assert(raw64);
const raw=Buffer.from(raw64[1],'base64').toString('utf8');
const patched=outer[1].match(/const b6r8PhysicsPatch=("(?:\\.|[^"\\])*");\nconst b6r8PhysicsSource/);assert(patched);
const patch=JSON.parse(patched[1]);
new vm.Script(patch,{filename:'B6r8-patch.js'});
const anchor='\n})();\n</script>';assert(raw.includes(anchor));
const embed=raw.replace(anchor,'\n'+patch+anchor);
const inner=embed.match(/<script>([\s\S]*?)<\/script>/);assert(inner);
new vm.Script(inner[1],{filename:'B6r8-embedded.js'});
for(const term of [
 'function closeEnough(p)','function updateCaseProximity(p)','caseDismissed',
 "svg.insertBefore(layer,scrollLayer)",
 'b6r8DragPreview','svg.appendChild(preview)',"get dragPreview()",
 "textAt(ledger,'SCROLL REGISTER'",
 "action:'inventory'", "action:'export',r5:true",
 'function cutSelected(mode)','function pasteCase(ids,point)'
])assert(patch.includes(term),'Missing B6r8 focused behavior '+term);
for(const term of [
 'let holderDockNearby=false,holderDragEligible=false,holderDismissed=false',
 'function b6r8NearDock(event)',"holderDragOffer=holderDragEligible&&holderDockNearby",
 "if(b6PointerInsideHolder(ev)){stashCrossTransfer('case');return;}",
 'holderDismissed=true;syncHolderDock()', "function b6r7ShelfArt(items)"
])assert(outer[1].includes(term),'Missing B6r8 outer integration '+term);
assert(!patch.includes('SHIPPING MANIFEST'),'No literal shipping terminology in focused register');
assert(!html.includes("window.__cubbyB6r7="),'Version hook moved forward');
for(const id of ['b6Holder','b6HolderClose','b6HolderToggle','b6r7ManifestToggle','b4Frame']){
 assert.equal((html.match(new RegExp('id="'+id+'"','g'))||[]).length,1,'Unique DOM ID '+id);
}
assert(!/<script\b[^>]*\bsrc=|<link\b[^>]*\bhref=/i.test(html),'Self-contained prototype');
console.log('PASS B6r8: outer/embedded scripts parse, register terminology, proximity case, visible ghost, rack transfer and close controls.');
