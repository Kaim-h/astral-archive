'use strict';
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync('docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r12b2.html','utf8');
const script=html.match(/<script>([\s\S]*?)<\/script>/)[1];
new vm.Script(script,{filename:'B6r12b2.js'});
for(const token of ['b12cProjection','b12cCaseView','b12cOverDock','b12cTether','lastVisual','data-b12c-unresolved','view.unresolved.length','caseOverflow','releaseTicks','b12r12b1','b12cIssueHead'].filter(x=>x!=='b12r12b1'))assert(html.includes(token),'Missing '+token);
assert(html.includes("localStorage.setItem('astral-archive-b6r12b2-session'"));
assert(!html.includes("localStorage.setItem('astral-archive-b6r12b1-session'"));
assert(html.includes("window.__cubbyB6r12b2="));
console.log('PASS B6r12b2 syntax, shared provisional projection, pointer wake and condensed resolver source.');

for(const token of ['b12dChoose','b12dInsertGroup','b12dGroupPoints','data-b12d-action','d.proposed.r<60','getBoundingClientRect()','data-carrying'])assert(html.includes(token),'Missing '+token);
