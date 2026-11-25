'use strict';
const {chromium}=require('playwright'),assert=require('node:assert/strict'),path=require('node:path'),{pathToFileURL}=require('node:url');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--disable-web-security','--allow-file-access-from-files']});
 const page=await browser.newPage({viewport:{width:1550,height:1050}}),errors=[];
 page.on('pageerror',e=>errors.push(e.stack||e.message));
 const snap=()=>page.evaluate(()=>window.__cubbyB6r12b2.snapshot);
 const idle=()=>page.waitForFunction(()=>!window.__cubbyB6r12b2.busy,{},{timeout:22000});
 const plan=()=>page.waitForFunction(()=>window.__cubbyB6r12b2.proposal?.phase!=='pending');
 const center=async l=>{const b=await l.boundingBox();assert(b);return{x:b.x+b.width/2,y:b.y+b.height/2};};
 const glyph=id=>page.locator('#scene [data-rack-scroll="'+id+'"]');
 const caseGlyph=id=>page.locator('#b6Holder [data-shelf-scroll="'+id+'"]');
 const click=async(p,modifiers=[])=>{for(const m of modifiers)await page.keyboard.down(m);await page.mouse.click(p.x,p.y);for(const m of modifiers.reverse())await page.keyboard.up(m);};
 const start=async(p)=>{await page.mouse.move(p.x,p.y);await page.mouse.down();};
 const move=async(p)=>page.mouse.move(p.x,p.y,{steps:18});
 const selected=()=>page.evaluate(()=>[...window.__cubbyB6r12b2.engine.selection].sort());
 const owners=ids=>page.evaluate(ids=>window.__cubbyB6r12b2.ownerIndex().filter(e=>ids.includes(e.id)).map(e=>[e.id,e.where,e.key||'']).sort(),ids);
 const point=key=>page.evaluate(key=>{
  const a=window.__cubbyB6r12b2,m=a.current().mods.find(q=>q.type==='rack'),c=a.rackCell(m,key);
  const p=document.querySelector('#scene').createSVGPoint();p.x=m.x+c.cx;p.y=m.y+c.cy;const s=p.matrixTransform(document.querySelector('[data-view-cubby]').getScreenCTM());return{x:s.x,y:s.y};
 },key);
 try{
  await page.goto(pathToFileURL(path.resolve('docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r12b2.html')).href);
  await page.waitForFunction(()=>!!window.__cubbyB6r12b2);
  const fixture=await page.evaluate(()=>{
   const a=window.__cubbyB6r12b2;a.setSample('code');
   const m=a.current().mods[0],cells=a.geomForRack(m).cells;
   const source=cells.find(c=>c.area>9500&&m.scrollCells[c.key]?.length>=2&&m.scrollCells[c.key].length<=5);
   const ids=m.scrollCells[source.key].slice(0,2).map(s=>s.id);
   const empty=cells.find(c=>c.area>10000&&!m.scrollCells[c.key]?.length);
   return {ids,source:source.key,empty:empty.key,count:a.ownerIndex().length};
  });
  const ids=fixture.ids,original=await snap(),sourceOwners=await owners(ids);
  await click(await center(glyph(ids[0])));await click(await center(glyph(ids[1])),['Control']);
  assert.deepEqual(await selected(),[...ids].sort());
  const dest=await point(fixture.empty);
  await start(await center(glyph(ids[0])));await move(dest);
  assert.equal(await page.locator('#b12Ghost').getAttribute('data-group-count'),'2');
  assert.deepEqual(await snap(),original,'Group lift remains provisional');
  await page.mouse.up();await idle();
  assert.deepEqual(await owners(ids),ids.map(id=>[id,'rack',fixture.empty]).sort());
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b2.engine.history.length),1);
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b2.undo()),true);assert.deepEqual(await snap(),original);
  await click(await center(glyph(ids[0])));await click(await center(glyph(ids[1])),['Shift']);
  assert.deepEqual(await selected(),[...ids].sort());
  await start(await center(glyph(ids[0])));await move(dest);await page.keyboard.press('Escape');await page.mouse.up();await idle();
  assert.deepEqual(await snap(),original);assert.deepEqual(await owners(ids),sourceOwners);
  // Select again and drop directly on the stable pill after proximity expands it.
  await click(await center(glyph(ids[0])));await click(await center(glyph(ids[1])),['Control']);
  const pill=await center(page.locator('#b6HolderToggle'));await start(await center(glyph(ids[1])));await move(pill);
  assert.equal(await page.locator('#b6Holder').getAttribute('data-expanded'),'true');
  assert.equal(await page.locator('#b12Ghost').getAttribute('data-group-count'),'2');
  await page.mouse.up();await idle();
  assert.deepEqual(await owners(ids),ids.map(id=>[id,'case','']).sort());
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b2.ownerIndex().length),fixture.count);
  // Case cradle multiselect, then drag out together. The dock may collapse
  // during departure; the moving group remains captured by the main scene.
  await page.locator('#b6HolderToggle').click();
  await click(await center(caseGlyph(ids[0])));await click(await center(caseGlyph(ids[1])),['Control']);
  assert.deepEqual(await selected(),[...ids].sort());
  await start(await center(caseGlyph(ids[0])));await move(dest);
  assert.equal(await page.locator('#b12Ghost').getAttribute('data-group-count'),'2');
  await page.mouse.up();await idle();
  assert.deepEqual(await owners(ids),ids.map(id=>[id,'rack',fixture.empty]).sort());
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b2.undo()),true);
  assert.deepEqual(await owners(ids),ids.map(id=>[id,'case','']).sort());
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b2.undo()),true);assert.deepEqual(await snap(),original);
  // Same-cell group tether must wake more than one selected body.
  await click(await center(glyph(ids[0])));await click(await center(glyph(ids[1])),['Shift']);
  await start(await center(glyph(ids[0])));await move(await point(fixture.source));
  assert.equal(await page.locator('#b12Ghost').count(),0);
  await page.waitForFunction(ids=>ids.every(id=>document.querySelector('#scene [data-rack-scroll="'+id+'"]')?.getAttribute('transform')?.match(/translate\((?!0 0)/)),ids);
  await page.keyboard.press('Escape');await page.mouse.up();await idle();assert.deepEqual(await snap(),original);
  // Radius boundary and actual two-icon split controls.
  await page.evaluate(()=>{const a=window.__cubbyB6r12b2;a.setMode('arrange');a.current().selected=a.current().mods[0].id;a.preview(a.current().mods[0],{r:65});});await plan();
  assert.equal(await page.locator('#b11RadiusNotice').isVisible(),false);
  await page.evaluate(()=>{const a=window.__cubbyB6r12b2;a.preview(a.current().mods[0],{r:60});});await plan();
  assert.equal(await page.locator('#b11RadiusNotice').isVisible(),false);
  await page.evaluate(()=>{const a=window.__cubbyB6r12b2;a.preview(a.current().mods[0],{r:52});});await plan();
  assert.equal(await page.locator('#b11RadiusNotice').isVisible(),true);
  assert.equal(await page.locator('#b6SplitIssues select').count(),0);
  const row=page.locator('.b12bChoice').first(),id=await row.getAttribute('data-scroll-id');
  assert.equal(await row.locator('button').count(),2);
  await row.locator('[data-b12d-action="case"]').click();await plan();
  assert.equal(await page.locator('.b12bChoice[data-scroll-id="'+id+'"] [data-b12d-action="case"]').getAttribute('aria-pressed'),'true');
  await page.locator('.b12bChoice[data-scroll-id="'+id+'"] [data-b12d-action="cell"]').click();
  const target=await page.evaluate(id=>{const a=window.__cubbyB6r12b2,d=a.proposal;const issue=d.result.review.find(q=>q.records?.some(s=>s.id===id));return issue.options.find(k=>a.rackCell(a.previewView.rack,k).area>5000);},id);
  assert(target);
  await page.locator('#scene [data-b12b-destination="'+target+'"]').click({force:true});await plan();
  assert.equal(await page.evaluate(id=>window.__cubbyB6r12b2.proposal.decisions[id],id),target);
  assert.equal(await page.locator('.b12bChoice[data-scroll-id="'+id+'"] [data-b12d-action="cell"]').getAttribute('aria-pressed'),'true');
  await page.locator('#b6CancelReflow').click();assert.equal(await page.evaluate(()=>window.__cubbyB6r12b2.ownerIndex().length),fixture.count);
  assert.deepEqual(errors,[]);
  console.log('PASS B6r12b2: Ctrl/Shift selection, in-cell group tether, cross-cell group drag, atomic group Case round-trip, Cancel/Undo, radius threshold, actual icon selection.');
 }finally{await browser.close();}
})().catch(e=>{console.error(e.stack||e.message);process.exit(1);});
