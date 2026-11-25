'use strict';
const {chromium}=require('playwright'),assert=require('node:assert/strict');
const path=require('node:path'),{pathToFileURL}=require('node:url');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--disable-web-security','--allow-file-access-from-files']});
 const page=await browser.newPage({viewport:{width:1550,height:1050}}),errors=[];
 page.on('pageerror',e=>errors.push(e.stack||e.message));
 const snapshot=()=>page.evaluate(()=>window.__cubbyB6r12b1.snapshot);
 const owners=id=>page.evaluate(id=>window.__cubbyB6r12b1.ownerIndex().filter(q=>q.id===id).map(q=>[q.where,q.cubbyId||null,q.rackId||null,q.key||null]),id);
 const waitIdle=()=>page.waitForFunction(()=>!window.__cubbyB6r12b1.busy,{},{timeout:20000});
 const waitPlan=()=>page.waitForFunction(()=>window.__cubbyB6r12b1.proposal&&window.__cubbyB6r12b1.proposal.phase!=='pending',{},{timeout:10000});
 const center=async locator=>{const b=await locator.boundingBox();assert(b,'Visible target required');return{x:b.x+b.width/2,y:b.y+b.height/2};};
 const point=key=>page.evaluate(key=>{
  const a=window.__cubbyB6r12b1,m=a.current().mods.find(q=>q.type==='rack'),c=a.rackCell(m,key);
  const p=document.querySelector('#scene').createSVGPoint();p.x=m.x+c.cx;p.y=m.y+c.cy;
  const screen=p.matrixTransform(document.querySelector('[data-view-cubby]').getScreenCTM());return{x:screen.x,y:screen.y};
 },key);
 const glyph=id=>page.locator('#scene [data-rack-scroll="'+id+'"]');
 const clickPoint=async p=>page.mouse.click(p.x,p.y);
 const drag=async(from,to)=>{await page.mouse.move(from.x,from.y);await page.mouse.down();await page.mouse.move(to.x,to.y,{steps:24});await page.mouse.up();};
 try{
  await page.goto(pathToFileURL(path.resolve('docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r12b1.html')).href);
  await page.waitForFunction(()=>!!window.__cubbyB6r12b1);
  const initial=await page.evaluate(()=>{
   const a=window.__cubbyB6r12b1;a.setSample('code');
   const m=a.current().mods.find(q=>q.type==='rack'),cells=a.geomForRack(m).cells;
   const candidates=Object.entries(m.scrollCells).filter(([k,items])=>items.length>=2&&items.length<=5&&cells.find(c=>c.key===k)?.area>9000);
   candidates.sort((x,y)=>cells.find(c=>c.key===x[0]).cy-cells.find(c=>c.key===y[0]).cy);
   const [key,items]=candidates[0];
   const empty=cells.filter(c=>c.area>10000&&!m.scrollCells[c.key]?.length).sort((x,y)=>x.cy-y.cy)[0];
   return{id:items[0].id,second:items[1].id,source:key,empty:empty.key,cubbyId:a.current().id,rackId:m.id,count:a.ownerIndex().length,validation:a.validate(a.state.cubbies,a.holder.items)};
  });
  assert.equal(initial.validation,null);
  const original=await snapshot(),sourceOwner=[['rack',initial.cubbyId,initial.rackId,initial.source]],destOwner=[['rack',initial.cubbyId,initial.rackId,initial.empty]];
  let from=await center(glyph(initial.id)),inside=await point(initial.source),dest=await point(initial.empty);
  await clickPoint(from);
  assert.equal(await page.locator('#b4CellOverlay').evaluate(e=>e.classList.contains('open')),false);
  await page.mouse.move(from.x,from.y);await page.mouse.down();await page.mouse.move(inside.x,inside.y,{steps:12});
  await page.waitForFunction(()=>window.__cubbyB6r12b1.activeCells>0);
  await page.waitForFunction(()=>[...document.querySelectorAll('#scene [data-live-x]')].some(e=>e.getAttribute('transform')&&e.getAttribute('transform')!=='translate(0 0)'));
  assert.deepEqual(await snapshot(),original,'Live motion must not change committed records');
  await page.keyboard.press('Escape');await page.mouse.up();await waitIdle();
  assert.deepEqual(await snapshot(),original,'Escape restores complete state');
  from=await center(glyph(initial.id));
  await drag(from,{x:1250,y:780});await waitIdle();
  assert.deepEqual(await snapshot(),original,'Invalid drop restores complete state');
  from=await center(glyph(initial.id));
  await page.mouse.move(from.x,from.y);await page.mouse.down();await page.mouse.move(dest.x,dest.y,{steps:20});
  assert.equal(await page.locator('#b12Ghost').count(),1);
  await page.mouse.move(inside.x,inside.y,{steps:20});await page.mouse.up();await waitIdle();
  assert.deepEqual(await snapshot(),original,'Lifted scroll returning to its origin rolls back exactly');
  from=await center(glyph(initial.id));await drag(from,dest);await waitIdle();
  assert.deepEqual(await owners(initial.id),destOwner);
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b1.activeCells),0,'Settled cells sleep');
  assert.equal(await page.evaluate(({rackId,key})=>{
   const a=window.__cubbyB6r12b1,m=a.current().mods.find(q=>q.id===rackId),c=a.rackCell(m,key),arr=m.scrollCells[key];
   return a.contained(c,arr)&&a.supported(c,arr);
  },{rackId:initial.rackId,key:initial.empty}),true,'Destination settles under physical support');
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b1.undo()),true);
  assert.deepEqual(await snapshot(),original,'Undo restores exact pre-gesture state');
  assert.deepEqual(await owners(initial.id),sourceOwner);
  // Actual pointer path to the proximity case, not a test-only data transfer.
  from=await center(glyph(initial.id));const pill=await center(page.locator('#b6HolderToggle'));
  await page.mouse.move(from.x,from.y);await page.mouse.down();await page.mouse.move(pill.x,pill.y,{steps:28});
  assert.equal(await page.locator('#b6Holder').getAttribute('data-expanded'),'true');
  assert.equal(await page.locator('#b12Ghost').count(),1);
  const dock=await page.locator('#b6HolderPanel').boundingBox();assert(dock);
  await page.mouse.move(dock.x+dock.width/2,dock.y+dock.height*.65,{steps:6});await page.mouse.up();await waitIdle();
  assert.equal((await owners(initial.id))[0][0],'case');
  // P2R connected-region hover/click-lock on the actual main SVG.
  await page.evaluate(id=>{const a=window.__cubbyB6r12b1;a.holder.selectedId=id;a.renderHolder();},initial.id);
  await page.locator('#b12bPrepare').click();await clickPoint(dest);
  assert.equal(await page.locator('#scene [data-b12b-void] path').count(),1);
  assert.equal(await page.locator('#b12bInsert').isDisabled(),false);
  await page.locator('#b12bInsert').click();await waitIdle();
  assert.deepEqual(await owners(initial.id),destOwner);
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b1.undo()),true);
  assert.equal((await owners(initial.id))[0][0],'case');
  await page.evaluate(id=>{const a=window.__cubbyB6r12b1;a.holder.selectedId=id;a.renderHolder();},initial.id);
  await page.locator('#b12bPrepare').click();await clickPoint(dest);
  await page.locator('#b12bTopDrop').click();await waitIdle();
  assert.deepEqual(await owners(initial.id),destOwner,'Top entry commits only after settling');
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b1.undo()),true);
  // Carry across a real nested cubby; global history must survive navigation.
  const child=await page.evaluate(()=>{
   const a=window.__cubbyB6r12b1,child=a.current().mods.find(m=>m.type==='cubby').childId;
   a.navigate(child);const m=a.current().mods.find(m=>m.type==='rack'),cell=a.geomForRack(m).cells.find(c=>c.area>10000&&!m.scrollCells[c.key]?.length);
   return {cubbyId:child,rackId:m.id,key:cell.key,local:{x:cell.cx,y:cell.cy}};
  });
  assert.equal(await page.evaluate(({id,child})=>window.__cubbyB6r12b1.transfer([id],child),{id:initial.id,child}),true);
  await waitIdle();
  assert.deepEqual(await owners(initial.id),[['rack',child.cubbyId,child.rackId,child.key]]);
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b1.undo()),true);
  assert.equal((await owners(initial.id))[0][0],'case');
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b1.undo()),true);
  assert.deepEqual(await owners(initial.id),sourceOwner);
  // Deterministic fixture: radius-75 and radius-38 share the same central lattice key,
  // but three radius-23 scrolls cannot fit into the smaller cell together.
  const fixture=await page.evaluate(()=>{
   const a=window.__cubbyB6r12b1;a.setSample('empty');const c=a.current();
   const m={id:'test-rack',type:'rack',shape:'hex',x:0,y:0,w:500,h:400,r:75,color:null,scrollCells:{},cellMeta:{}};
   const cells=a.geomForRack(m).cells,cell=cells.find(q=>q.key==='1:1');
   for(const q of cells)m.cellMeta[q.key]={id:'test-cell-'+q.key,color:null};
   m.cellMeta[cell.key].color='#796a92';
   m.scrollCells[cell.key]=[{id:'test-a',name:'alpha.md',r:23,x:cell.cx-25,y:cell.cy-15,cellKey:cell.key},
    {id:'test-b',name:'beta.md',r:23,x:cell.cx+25,y:cell.cy-15,cellKey:cell.key},
    {id:'test-c',name:'gamma.md',r:23,x:cell.cx,y:cell.cy+30,cellKey:cell.key}];
   c.mods.push(m);a.setMode('arrange');c.selected=m.id;
   const fresh=a.geomForRack({...m,r:38}).cells;
   const empty=fresh.find(q=>q.key!==cell.key&&q.area>3600).key;
   return {key:cell.key,stable:m.cellMeta[cell.key].id,empty,valid:a.validate(a.state.cubbies,a.holder.items)};
  });
  assert.equal(fixture.valid,null);
  const beforeResize=await snapshot();
  // Radius 75->76, 76->75, 57->56 and 56->57: one scroll in an intact original
  // cell must keep its key and stable ID; no approval for a mere center shift.
  const sweep=await page.evaluate(()=>{
   const a=window.__cubbyB6r12b1,base=a.current().mods[0],results=[];
   for(const [from,to] of [[75,76],[76,75],[57,56],[56,57]]){
    const m={...structuredClone(base),r:from,scrollCells:{},cellMeta:{}};
    for(const c of a.geomForRack(m).cells)m.cellMeta[c.key]={id:'sweep-'+c.key,color:null};
    const c=a.rackCell(m,'1:1');m.scrollCells[c.key]=[{id:'sweep-scroll',name:'sweep.md',r:8,x:c.cx,y:c.cy,cellKey:c.key}];
    m.cellMeta[c.key].color='#796a92';
    const dims={x:m.x,y:m.y,w:m.w,h:m.h,r:to},no=a.plan(m,{...dims,r:from}),p=a.plan(m,dims);
    results.push({from,to,unchanged:no.unchanged&&JSON.stringify(no.mapped)===JSON.stringify(m.scrollCells)&&JSON.stringify(no.meta)===JSON.stringify(m.cellMeta),
      ok:p.ok,key:Object.keys(p.mapped||{})[0],stable:p.meta?.[c.key]?.id,paint:p.meta?.[c.key]?.color,review:p.review?.length});
   }return results;
  });
  for(const p of sweep){assert(p.unchanged,JSON.stringify(p));assert(p.ok,JSON.stringify(p));assert.equal(p.key,'1:1');assert.equal(p.stable,'sweep-1:1');assert.equal(p.paint,'#796a92');assert.equal(p.review,0);}
  await page.evaluate(()=>{const a=window.__cubbyB6r12b1;a.preview(a.current().mods[0],{r:75});});
  await waitPlan();
  assert.equal(await page.locator('#b6Apply').isDisabled(),true,'Unchanged geometry is exact no-op');
  assert.deepEqual(await snapshot(),beforeResize);
  await page.evaluate(()=>window.__cubbyB6r12b1.cancel());assert.deepEqual(await snapshot(),beforeResize);
  await page.evaluate(()=>{const a=window.__cubbyB6r12b1;a.preview(a.current().mods[0],{r:38});});
  await waitPlan();
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b1.proposal.phase),'attention');
  assert.equal(await page.locator('#b6Apply').isDisabled(),true,'Never auto-split');
  assert.equal(await page.locator('#scene [data-b12b-provisional]').count(),1);
  assert.equal(await page.locator('#scene .b6ReflowGhost').count(),0);
  assert.deepEqual(await snapshot(),beforeResize,'Preview does not allocate or mutate');
  await page.evaluate(({empty})=>{
   const a=window.__cubbyB6r12b1;a.proposal.decisions['test-b']='case';a.proposal.decisions['test-c']=empty;a.preview(a.current().mods[0],{});
  },fixture);
  await waitPlan();
  const proposal=await page.evaluate(()=>({phase:window.__cubbyB6r12b1.proposal.phase,result:window.__cubbyB6r12b1.proposal.result}));
  assert.equal(proposal.phase,'ready',JSON.stringify(proposal.result.review));
  assert.equal(proposal.result.meta[fixture.key].id,fixture.stable);
  assert.equal(proposal.result.meta[fixture.key].color,'#796a92');
  assert.equal(proposal.result.meta[fixture.empty].splitFromId,fixture.stable);
  assert.deepEqual(await snapshot(),beforeResize,'Explicit choices remain provisional');
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b1.apply()),true);
  assert.equal((await owners('test-b'))[0][0],'case');
  assert.equal((await owners('test-c'))[0][3],fixture.empty);
  assert.equal((await owners('test-a'))[0][3],fixture.key);
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b1.ownerIndex().length),3);
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b1.undo()),true);
  assert.deepEqual(await snapshot(),beforeResize,'Undo restores geometry, paint, allocation and case');
  // Repeat and cancel: decisions must not touch IDs or case inventory.
  await page.evaluate(()=>{const a=window.__cubbyB6r12b1;a.preview(a.current().mods[0],{r:38});});
  await waitPlan();await page.evaluate(()=>window.__cubbyB6r12b1.cancel());
  assert.deepEqual(await snapshot(),beforeResize);
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b1.save()),true);
  await page.reload();await page.waitForFunction(()=>!!window.__cubbyB6r12b1);
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12b1.load()),true);
  assert.deepEqual(await snapshot(),beforeResize,'Checkpoint reload preserves committed records');
  assert.deepEqual(errors,[],'No page errors');
  console.log('PASS B6r12b1 inherited Chromium: live motion/cancel, origin rollback, cross-cell and case, void/top insertion, cross-cubby Undo, four radius transitions, exact no-op, explicit multi-destination split, paint/lineage, Cancel/Undo and local reload.');
 }finally{await browser.close();}
})().catch(error=>{console.error(error.stack||error);process.exit(1);});
