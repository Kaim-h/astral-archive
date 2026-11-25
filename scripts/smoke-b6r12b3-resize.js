'use strict';
const {chromium}=require('playwright'),assert=require('node:assert/strict'),path=require('node:path'),{pathToFileURL}=require('node:url');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--disable-web-security','--allow-file-access-from-files']});
 const page=await browser.newPage({viewport:{width:1366,height:768}}),errors=[];
 page.on('pageerror',e=>errors.push(e.stack||e.message));
 try{
  await page.goto(pathToFileURL(path.resolve('docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r12b3.html')).href);
  await page.waitForFunction(()=>!!window.__cubbyB6r12b3);
  const original=await page.evaluate(()=>{
   const a=window.__cubbyB6r12b3;a.setSample('code');a.setMode('arrange');
   const m=a.current().mods.find(q=>q.type==='rack');a.current().selected=m.id;return {snapshot:a.snapshot,dims:{x:m.x,y:m.y,w:m.w,h:m.h,r:m.r},id:m.id};
  });
  // Check every synchronous frame before the worker can reply, including
  // real input handlers. Neither the rack bounds nor the lattice radius
  // may flash back to the committed model.
  const frames=await page.evaluate(()=>{
   const a=window.__cubbyB6r12b3,m=a.current().mods.find(q=>q.type==='rack'),base={w:m.w,h:m.h,r:m.r},out=[];
   function inspect(label){
    const v=a.previewView,group=document.querySelector('[data-b12b-provisional]'),frame=group.querySelector('[data-rack-frame]'),ids=Object.values(m.scrollCells).flat().map(s=>s.id).sort(),
     partition=[...Object.values(v.rack.scrollCells).flat().map(s=>s.id),...v.caseOverflow.map(s=>s.id),...v.unresolved.map(s=>s.id)].sort();
    out.push({label,phase:a.proposal.phase,proposed:{...a.proposal.proposed},display:{w:Number(frame.getAttribute('width')),h:Number(frame.getAttribute('height')),r:Number(group.dataset.previewRadius),x:Number(frame.getAttribute('x')),y:Number(frame.getAttribute('y'))},cells:group.querySelectorAll('[data-hex-cell]').length,expectedCells:a.geomForRack(v.rack).cells.length,ids,partition,next:a.state.next,meta:Object.keys(v.rack.cellMeta).length});
   }
   a.preview(m,{w:base.w-12,h:base.h-9,r:60});inspect('initial pending');
   for(let n=0;n<20;n++){
    const field=document.querySelector('#b6ReflowR');field.value=String(59-n%7);field.dispatchEvent(new Event('input',{bubbles:true}));inspect('radius '+n);
    a.preview(m,{w:base.w-13-n,h:base.h-10-n});inspect('size '+n);
   }
   a.preview(m,{r:0});inspect('invalid radius');
   a.preview(m,{w:base.w-14,h:base.h-11,r:60});inspect('valid again');
   return out;
  });
  for(const f of frames){
   assert.deepEqual(f.partition,f.ids,'Scroll partition '+f.label);assert.equal(f.next,original.snapshot.next,'No preview allocation');
   assert.equal(f.cells,f.expectedCells);assert.equal(f.meta,f.expectedCells);
   if(f.label==='invalid radius'){assert.equal(f.phase,'invalid');assert.deepEqual(f.display,frames.at(-3).display,'Invalid numeric edit retains last drawable shape');}
   else{for(const k of ['x','y','w','h','r'])assert.equal(f.display[k],f.proposed[k],f.label+' '+k);assert.equal(f.phase,'pending');}
  }
  await page.waitForFunction(()=>window.__cubbyB6r12b3.proposal.phase!=='pending');
  const settled=await page.evaluate(()=>{const a=window.__cubbyB6r12b3,g=document.querySelector('[data-b12b-provisional]'),f=g.querySelector('[data-rack-frame]');return {w:Number(f.getAttribute('width')),h:Number(f.getAttribute('height')),r:Number(g.dataset.previewRadius),phase:a.proposal.phase,snapshot:a.snapshot};});
  assert.equal(settled.w,frames.at(-1).display.w);assert.equal(settled.h,frames.at(-1).display.h);assert.equal(settled.r,60);assert.notEqual(settled.phase,'invalid');assert.deepEqual(settled.snapshot,original.snapshot);
  await page.locator('#b6CancelReflow').click();
  assert.equal(await page.locator('[data-b12b-provisional]').count(),0);
  assert.deepEqual(await page.evaluate(()=>window.__cubbyB6r12b3.snapshot),original.snapshot);
  // The next resize must not reuse an old cache result from a moved rack.
  await page.evaluate(()=>{const a=window.__cubbyB6r12b3,m=a.current().mods.find(q=>q.type==='rack');a.preview(m,{x:m.x+1});});
  await page.waitForFunction(()=>window.__cubbyB6r12b3.proposal.phase!=='pending');
  await page.evaluate(()=>{const a=window.__cubbyB6r12b3,m=a.current().mods.find(q=>q.type==='rack');a.preview(m,{x:m.x});});
  await page.waitForFunction(()=>window.__cubbyB6r12b3.proposal.phase!=='pending');
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b3.proposal.result.unchanged),true);
  assert.equal(await page.locator('#b6Apply').isDisabled(),true);
  await page.locator('#b6CancelReflow').click();
  assert.deepEqual(errors,[]);
  console.log('PASS B6r12b3: synchronous frame/lattice continuity across 40 rapid edits, invalid numeric fallback, exact partition/allocator, worker handoff, no-op and Cancel.');
 }finally{await browser.close();}
})().catch(e=>{console.error(e.stack||e);process.exit(1);});
