'use strict';
const {chromium}=require('playwright'),assert=require('node:assert/strict');
const path=require('node:path'),{pathToFileURL}=require('node:url');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--disable-web-security','--allow-file-access-from-files']});
 const page=await browser.newPage({viewport:{width:1550,height:1050}}),errors=[];
 page.on('pageerror',e=>errors.push(e.stack||e.message));
 const center=async locator=>{const r=await locator.boundingBox();assert(r,'Not visible: '+locator);return{x:r.x+r.width/2,y:r.y+r.height/2};};
 const targetPoint=key=>page.evaluate(key=>{
  const a=window.__cubbyB6r12a,m=a.current().mods.find(q=>q.type==='rack'),cell=a.geomForRack(m).cells.find(c=>c.key===key);
  const p=document.querySelector('#scene').createSVGPoint();p.x=m.x+cell.cx;p.y=m.y+cell.cy;
  const result=p.matrixTransform(document.querySelector('[data-view-cubby]').getScreenCTM());
  return{x:result.x,y:result.y};
 },key);
 try{
  await page.goto(pathToFileURL(path.resolve('docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r12a.html')).href);
  await page.waitForFunction(()=>!!window.__cubbyB6r12a);
  const initial=await page.evaluate(()=>{
   const a=window.__cubbyB6r12a;a.setSample('code');
   const m=a.current().mods.find(q=>q.type==='rack'),filled=Object.entries(m.scrollCells).find(([,items])=>items.length>2);
   const empty=a.geomForRack(m).cells.find(c=>c.area>10000&&!m.scrollCells[c.key]?.length);
   return{id:filled[1][0].id,second:filled[1][1].id,third:filled[1][2].id,source:filled[0],empty:empty.key,count:a.ownerIndex().length};
  });
  const first=()=>page.locator('#scene [data-rack-scroll="'+initial.id+'"]');
  let from=await center(first());await page.mouse.click(from.x,from.y);
  assert.equal(await page.locator('#b4CellOverlay').evaluate(e=>e.classList.contains('open')),false,'Main rack click must not open P2R iframe');
  await page.mouse.move(from.x,from.y);await page.mouse.down();await page.mouse.move(1250,780,{steps:15});await page.mouse.up();
  assert.deepEqual(await page.evaluate(id=>window.__cubbyB6r12a.ownerIndex().filter(q=>q.id===id).map(q=>q.key),initial.id),[initial.source]);
  assert.equal(await page.locator('#b12Undo').isDisabled(),true,'Invalid drop must not commit');
  from=await center(first());const dest=await targetPoint(initial.empty);
  await page.mouse.move(from.x,from.y);await page.mouse.down();await page.mouse.move(dest.x,dest.y,{steps:24});
  assert.equal(await page.locator('#b12Ghost').count(),1,'Topmost drag scroll follows pointer');
  await page.mouse.up();
  assert.deepEqual(await page.evaluate(id=>window.__cubbyB6r12a.ownerIndex().filter(q=>q.id===id).map(q=>q.key),initial.id),[initial.empty]);
  assert.equal(await page.locator('#b4CellOverlay').evaluate(e=>e.classList.contains('open')),false);
  await page.locator('#b12Undo').click();
  assert.deepEqual(await page.evaluate(id=>window.__cubbyB6r12a.ownerIndex().filter(q=>q.id===id).map(q=>q.key),initial.id),[initial.source]);
  // A rack scroll approaching the Scroll Case must OPEN the popup before drop.
  const third=await center(page.locator('#scene [data-rack-scroll="'+initial.third+'"]'));
  const dockPill=await center(page.locator('#b6HolderToggle'));
  await page.mouse.move(third.x,third.y);await page.mouse.down();
  await page.mouse.move(dockPill.x,dockPill.y,{steps:28});
  assert.equal(await page.locator('#b6Holder').getAttribute('data-expanded'),'true','Case opens while a rack scroll approaches');
  assert.equal(await page.locator('#b12Ghost').count(),1,'Carried scroll stays visible above case');
  const dockPanel=await page.locator('#b6HolderPanel').boundingBox();assert(dockPanel);
  await page.mouse.move(dockPanel.x+dockPanel.width/2,dockPanel.y+dockPanel.height*.65,{steps:6});
  await page.mouse.up();
  assert.deepEqual(await page.evaluate(id=>window.__cubbyB6r12a.ownerIndex().filter(q=>q.id===id).map(q=>q.where),initial.third),['case']);
  // Click + Ctrl-click selects two actual rack scrolls, then group-cut to the one case.
  for(const [i,id] of [initial.id,initial.second].entries()){
   const p=await center(page.locator('#scene [data-rack-scroll="'+id+'"]'));
   if(i)await page.keyboard.down('Control');
   await page.mouse.click(p.x,p.y);
   if(i)await page.keyboard.up('Control');
  }
  await page.keyboard.press('Control+x');
  assert.deepEqual(await page.evaluate(ids=>ids.map(id=>window.__cubbyB6r12a.ownerIndex().filter(q=>q.id===id).map(q=>q.where)),[initial.id,initial.second]),[['case'],['case']]);
  const toggle=await center(page.locator('#b6HolderToggle'));await page.mouse.move(toggle.x,toggle.y,{steps:8});
  await page.waitForFunction(()=>document.querySelector('#b6Holder').dataset.expanded==='true');
  const item=await center(page.locator('#b6HolderItems [data-shelf-scroll="'+initial.id+'"]'));
  await page.mouse.move(item.x,item.y);await page.mouse.down();await page.mouse.move(dest.x,dest.y,{steps:26});
  assert.equal(await page.locator('#b12Ghost').count(),1);
  await page.mouse.up();
  assert.deepEqual(await page.evaluate(id=>window.__cubbyB6r12a.ownerIndex().filter(q=>q.id===id).map(q=>[q.where,q.key]),initial.id),[['rack',initial.empty]]);
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12a.ownerIndex().length),initial.count);
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12a.save()),true,'Save the committed arrangement in browser storage');
  await page.reload();await page.waitForFunction(()=>!!window.__cubbyB6r12a);
  assert.equal(await page.evaluate(()=>window.__cubbyB6r12a.load()),true,'Reload the committed arrangement');
  assert.deepEqual(await page.evaluate(id=>window.__cubbyB6r12a.ownerIndex().filter(q=>q.id===id).map(q=>[q.where,q.key]),initial.id),[['rack',initial.empty]]);
  assert.deepEqual(errors,[],'No browser page errors');
  console.log('PASS B6r12a Chromium: direct rack cell selection without iframe, invalid-drop rollback, cross-cell move, Undo, rack-to-case proximity popup, group cut, case-to-rack placement, persistent reload and unique ownership.');
 }finally{await browser.close();}
})().catch(e=>{console.error(e.stack||e);process.exit(1);});
