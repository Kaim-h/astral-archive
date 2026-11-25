'use strict';
const {chromium}=require('playwright'),assert=require('node:assert/strict'),path=require('node:path'),{pathToFileURL}=require('node:url');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--disable-web-security','--allow-file-access-from-files']});
 const page=await browser.newPage({viewport:{width:1366,height:768}}),errors=[];
 page.on('pageerror',e=>errors.push(e.stack||e.message));
 const snap=()=>page.evaluate(()=>window.__cubbyB6r12b3.snapshot);
 const plan=()=>page.waitForFunction(()=>window.__cubbyB6r12b3.proposal?.phase!=='pending');
 const idle=()=>page.waitForFunction(()=>!window.__cubbyB6r12b3.busy,{},{timeout:20000});
 const sceneGlyph=id=>page.locator('#scene [data-rack-scroll="'+id+'"]');
 const caseGlyph=id=>page.locator('#b6Holder [data-shelf-scroll="'+id+'"]');
 const choice=id=>page.locator('.b12bChoice[data-scroll-id="'+id+'"] button[data-b12d-action="case"]');
 const proposalPartition=()=>page.evaluate(()=>{
  const a=window.__cubbyB6r12b3,v=a.previewView,source=a.current().mods.find(m=>m.id===a.proposal.id);
  const original=Object.values(source.scrollCells).flat().map(s=>s.id).sort();
  const drawn=Object.values(v.rack.scrollCells).flat().map(s=>s.id),planned=v.caseOverflow.map(s=>s.id),unresolved=v.unresolved.map(s=>s.id);
  return {original,partition:[...drawn,...planned,...unresolved].sort(),duplicates:new Set([...drawn,...planned,...unresolved]).size!==original.length,
   caseCount:document.querySelector('#b6HolderCount').textContent,committed:a.holder.items.length,phase:a.proposal.phase,unresolved:unresolved.length};
 });
 const assertPartition=async()=>{const p=await proposalPartition();assert.deepEqual(p.partition,p.original);assert.equal(p.duplicates,false);return p;};
 try{
  await page.goto(pathToFileURL(path.resolve('docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r12b3.html')).href);
  await page.waitForFunction(()=>!!window.__cubbyB6r12b3);
  const sample=await page.evaluate(()=>{
   const a=window.__cubbyB6r12b3;a.setSample('code');a.setMode('arrange');
   const m=a.current().mods.find(q=>q.type==='rack');a.current().selected=m.id;
   return {key:'2:2',ids:m.scrollCells['2:2'].map(s=>s.id),id:m.id};
  });
  const original=await snap();
  await page.evaluate(()=>{const a=window.__cubbyB6r12b3;a.preview(a.current().mods[0],{r:52});});
  await plan();
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b3.proposal.phase),'attention');
  assert.equal(await page.locator('#scene [data-b12c-unresolved="2:2"]').getAttribute('data-count'),String(sample.ids.length));
  await assertPartition();
  const panel=await page.locator('#b6Reflow').boundingBox();
  assert(panel.width<=271&&panel.height<=341,'Adjustment panel must be substantially smaller');
  const first=sample.ids[0],second=sample.ids[1];
  // Real selector events; inspect the pending frame in the same task, before
  // a worker result can hide an intermediate duplicate/vanished record.
  const pending=await page.evaluate(({first,second})=>{
   const a=window.__cubbyB6r12b3;
   function select(id){const el=document.querySelector('.b12bChoice[data-scroll-id="'+id+'"] button[data-b12d-action="case"]');if(!el)throw Error('Choice disappeared during replanning');el.click();}
   select(first);
   const afterFirst={phase:a.proposal.phase,source:!!document.querySelector('#scene [data-rack-scroll="'+first+'"]'),case:!!document.querySelector('#b6Holder [data-shelf-scroll="'+first+'"]'),count:document.querySelector('#b6HolderCount').textContent,
    unresolved:a.previewView.unresolved.length,committed:a.holder.items.length};
   select(second);
   return {afterFirst,phase:a.proposal.phase,case:a.previewView.caseOverflow.map(x=>x.id),unresolved:a.previewView.unresolved.length,committed:a.holder.items.length};
  },{first,second});
  assert.equal(pending.afterFirst.phase,'pending');assert.equal(pending.afterFirst.source,false);assert.equal(pending.afterFirst.case,true);assert.equal(pending.afterFirst.count,'1*');assert.equal(pending.afterFirst.committed,0);
  assert.deepEqual(pending.case.sort(),[first,second].sort());assert.equal(pending.committed,0);
  await assertPartition();assert.deepEqual(await snap(),original,'Planning does not mutate committed state');
  await plan();await assertPartition();
  assert.equal(await sceneGlyph(first).count(),0);assert.equal(await caseGlyph(first).count(),1);
  assert.equal(await sceneGlyph(second).count(),0);assert.equal(await caseGlyph(second).count(),1);
  // Revoke exactly one choice; it must leave the preview case immediately.
  await choice(second).click();
  assert.equal(await caseGlyph(second).count(),0);await assertPartition();
  await plan();assert.equal(await page.evaluate(()=>window.__cubbyB6r12b3.proposal.phase),'ready');
  assert.equal(await page.locator('#b6Apply').isDisabled(),true);
  await page.locator('#b11RadiusAcknowledge').check();
  assert.equal(await page.locator('#b6Apply').isEnabled(),true);
  assert.equal(await page.locator('#b6HolderCount').textContent(),'1*');
  assert.deepEqual(await snap(),original);
  await page.locator('#b6Apply').click();
  assert.equal(await sceneGlyph(first).count(),0);assert.equal(await caseGlyph(first).count(),1);
  assert.equal(await page.locator('#b6HolderCount').textContent(),'1');
  const owners=await page.evaluate(id=>window.__cubbyB6r12b3.ownerIndex().filter(s=>s.id===id).map(s=>s.where),first);
  assert.deepEqual(owners,['case']);
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b3.undo()),true);
  assert.deepEqual(await snap(),original);
  // Cancel must remove the staged case scroll and restore every rack glyph.
  await page.evaluate(()=>{const a=window.__cubbyB6r12b3;a.preview(a.current().mods[0],{r:52});});await plan();
  await choice(first).click();await plan();
  await page.setViewportSize({width:1024,height:600});
  const small=await page.locator('#b6Reflow').boundingBox();
  assert(small.height<=295&&small.width<=271&&small.y>=0&&small.y+small.height<=600,'Resolver remains on screen at 1024×600');
  await page.locator('#b6CancelReflow').click();
  assert.equal(await caseGlyph(first).count(),0);assert.equal(await sceneGlyph(first).count(),1);
  assert.deepEqual(await snap(),original);
  // Fast in-cell manipulation: a single pointer move followed immediately
  // by release must still drive the tether and wake contact physics.
  await page.setViewportSize({width:1550,height:1050});
  const gesture=await page.evaluate(()=>{
   const a=window.__cubbyB6r12b3;a.setMode('browse');
   const m=a.current().mods[0],c=a.geomForRack(m).cells.find(c=>c.area>9000&&m.scrollCells[c.key]?.length>=2&&m.scrollCells[c.key].length<5);
   const item=m.scrollCells[c.key][0],point={x:c.cx,y:c.cy};
   function screen(x,y){const p=document.querySelector('#scene').createSVGPoint();p.x=m.x+x;p.y=m.y+y;const q=p.matrixTransform(document.querySelector('[data-view-cubby]').getScreenCTM());return{x:q.x,y:q.y};}
   return {id:item.id,from:screen(item.x,item.y),to:screen(point.x,point.y),key:c.key};
  });
  const beforeGesture=await snap();
  await page.mouse.move(gesture.from.x,gesture.from.y);await page.mouse.down();
  await page.mouse.move(gesture.to.x,gesture.to.y);await page.mouse.up();
  await page.waitForFunction(()=>window.__cubbyB6r12b3.busy&&window.__cubbyB6r12b3.activeCells>0);
  await page.waitForFunction(()=>[...document.querySelectorAll('#scene [data-live-x]')].some(e=>e.getAttribute('transform')&&e.getAttribute('transform')!=='translate(0 0)'));
  await page.keyboard.press('Escape');await idle();
  assert.deepEqual(await snap(),beforeGesture,'Fast-drag Escape rolls back exactly');
  // The old proximity halo can intersect a lower cell. Force the halo
  // predicate true, while the actual visible dock is elsewhere, to reproduce
  // the routing edge case without moving the furniture or relying on a pixel.
  await page.evaluate(()=>{window.__oldNear=b6r8NearDock;b6r8NearDock=()=>true;});
  await page.mouse.move(gesture.from.x,gesture.from.y);await page.mouse.down();await page.mouse.move(gesture.to.x,gesture.to.y,{steps:3});
  assert.equal(await page.locator('#b12Ghost').count(),0,'Approach halo alone must not lift an in-cell scroll');
  await page.waitForFunction(()=>window.__cubbyB6r12b3.activeCells>0);
  await page.keyboard.press('Escape');await page.mouse.up();await idle();
  await page.evaluate(()=>{b6r8NearDock=window.__oldNear;});
  assert.deepEqual(await snap(),beforeGesture);
  assert.deepEqual(errors,[]);
  console.log('PASS B6r12b3: actual radius-52 split; pending/ready case exclusivity; rapid edits, revoke, Apply, Undo, Cancel; two viewport sizes; fast drag wake and case-halo isolation.');
 }finally{await browser.close();}
})().catch(e=>{console.error(e.stack||e);process.exit(1);});
