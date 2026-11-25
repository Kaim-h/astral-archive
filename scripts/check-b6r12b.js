'use strict';
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const root='docs/research/prototypes/2026-11-20/cubby-studies/';
const before=fs.readFileSync(root+'Astral_Archive_Cubby_Study_B6r12a.html','utf8');
const html=fs.readFileSync(root+'Astral_Archive_Cubby_Study_B6r12b.html','utf8');
assert.match(before,/<title>Astral Archive · Cubby Study B6r12a<\/title>/);
assert.match(html,/<title>Astral Archive · Cubby Study B6r12b<\/title>/);
assert.equal((html.match(/<\/script>/g)||[]).length,1);
const script=html.match(/<script>([\s\S]*?)<\/script>/)[1];
new vm.Script(script,{filename:'B6r12b-main-rack.js'});
for(const marker of [
 'function b12bStep(', 'const dt=1/120', 'function b12bFrame(', 'function b12bSupported(',
 'function b12bAbort(', 'function b12bFinish(', 'function b12Commit(', 'function b12bPlan(',
 'function b12bDrawPreview(', 'function b12bApply(', 'function b12bVoidAtlas(',
 'function b12bTraceVoid(', 'function b12bTopEntrance(', 'function b12bMark(',
 'b12bPreviewRack(m)', 'furniture.appendChild(b12bDrawPreview(c))',
 'splitFromId:source.id', 'lineage:', 'astral-archive-b6r12b-session'
])assert(script.includes(marker),'Missing '+marker);
assert(!script.includes('furniture.appendChild(drawReflowGhost(c))'),'No legacy full-rack preview route');
assert(!script.includes("localStorage.setItem('astral-archive-b6r12a-session'"),'Predecessor checkpoint is not overwritten');
assert(!/<script\b[^>]*\bsrc=|<link\b[^>]*\bhref=/i.test(html),'Standalone offline HTML');
for(const id of ['scene','b12Undo','b12bPrepare','b12bInsert','b12bTopDrop','b12bCancelInsert','b6Apply','b6CancelReflow'])
 assert.equal((html.match(new RegExp('id="'+id+'"','g'))||[]).length,1,'Unique control '+id);
console.log('PASS B6r12b source syntax, live transaction, in-place preview, explicit split, void/top insertion and isolated checkpoint markers.');
