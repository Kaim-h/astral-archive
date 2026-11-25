'use strict';
const {chromium}=require('playwright'),assert=require('node:assert/strict'),path=require('node:path'),{pathToFileURL}=require('node:url');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--disable-web-security','--allow-file-access-from-files']});
 const page=await browser.newPage({viewport:{width:1550,height:1030}}),errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 try{
  await page.goto(pathToFileURL(path.resolve('docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r9.html')).href);
  await page.waitForFunction(()=>!!window.__cubbyB6r9);
  // Unchanged dimensions (including 75 -> 75) cannot rematch cells or settle scrolls.
  const reflow=await page.evaluate(()=>{
   const a=window.__cubbyB6r9;a.setSample('code');
   const m=a.current().mods.find(q=>q.type==='rack');
   const snapshot=JSON.stringify(m.scrollCells);
   const noOp=a.b6Reflow(m,{...m,r:m.r});
   const fixture={...m,r:75};
   const same75=a.b6Reflow(fixture,{...fixture,r:75});
   const changed=a.b6Reflow(m,{...m,r:75});
   return{noOp:{ok:noOp.ok,unchanged:noOp.unchanged,moves:noOp.moves?.length,same:JSON.stringify(noOp.mapped)===snapshot},
    same75:{ok:same75.ok,unchanged:same75.unchanged,moves:same75.moves?.length},
    changed:{ok:changed.ok,moves:changed.moves?.length,topologyChanged:changed.topologyChanged},
    unchangedState:JSON.stringify(m.scrollCells)===snapshot};
  });
  assert.deepEqual(reflow.noOp,{ok:true,unchanged:true,moves:0,same:true});
  assert.deepEqual(reflow.same75,{ok:true,unchanged:true,moves:0});
  assert.equal(reflow.unchangedState,true,'Planner never mutates live source');
  await page.evaluate(()=>{
   const a=window.__cubbyB6r9;a.previewRackResize(a.current().mods.find(q=>q.type==='rack'),{r:75});
  });
  await page.waitForFunction(()=>['ready','attention','invalid'].includes(window.__cubbyB6r9.b6Preview?.phase),{timeout:15000});
  const gate=await page.evaluate(()=>({
   phase:window.__cubbyB6r9.b6Preview.phase,
   ok:!!window.__cubbyB6r9.b6Preview.result?.ok,
   changes:(window.__cubbyB6r9.b6Preview.result?.moves||[]).length,
   topology:!!window.__cubbyB6r9.b6Preview.result?.topologyChanged,
   visible:!document.getElementById('b6MovementReview').hidden,
   disabled:document.getElementById('b6Apply').disabled
  }));
  if(gate.ok&&(gate.changes||gate.topology)){
   assert(gate.disabled&&gate.visible,'Movement must require explicit review');
   assert.equal(await page.evaluate(()=>window.__cubbyB6r9.applyRackResize()),false,
    'Programmatic Apply must be blocked without review');
   if(gate.changes)assert.equal(await page.locator('#b6MovementReview .b9ReviewRow').count()>0,true);
  }
  await page.evaluate(()=>window.__cubbyB6r9.cancelRackResize());
  const before=await page.evaluate(()=>{
   const a=window.__cubbyB6r9;a.setSample('code');const m=a.current().mods.find(q=>q.type==='rack');
   const [key,records]=Object.entries(m.scrollCells).find(([,arr])=>arr.length>=4);
   a.openCellDirect(m,key);return {id:m.id,key,count:records.length,first:records[0].id};
  });
  const frame=page.frameLocator('#b4Frame');
  await frame.locator('#b6r7Case').waitFor();
  await page.waitForFunction(()=>window.__cubbyB6r9.cellBridge.ready);
  const stage=frame.locator('#scene');
  assert.equal(await stage.evaluate(()=>window.__b6r8Case.collapsed),true,'Focused case starts collapsed');
  const box=await frame.locator('[data-case-panel] rect').first().boundingBox();
  assert(box,'Case target');
  const approach={x:box.x+box.width*.54,y:box.y+15};
  await page.mouse.move(approach.x,approach.y,{steps:8});
  assert.equal(await stage.evaluate(()=>window.__b6r8Case.collapsed),false,'Focused case opens on approach');
  await frame.locator('[data-case-toggle]').click();
  assert.equal(await stage.evaluate(()=>window.__b6r8Case.collapsed),true,'Focused case close X works');
  await page.mouse.move(2,2);
  await page.mouse.move(approach.x,approach.y,{steps:4});
  assert.equal(await stage.evaluate(()=>window.__b6r8Case.collapsed),false,'Reapproach opens focused case');
  await frame.locator('[data-case-manifest]').hover();
  await frame.locator('[data-case-manifest]').click();
  assert.equal(await stage.evaluate(()=>window.__b6r8Case.ledgerOpen),true,'Register opens');
  await frame.locator('[data-ledger-close]').click();
  assert.equal(await stage.evaluate(()=>window.__b6r8Case.ledgerOpen),false,'Register X closes');
  const source=await frame.locator('#scrolls [data-id]').first().boundingBox();
  assert(source);
  const to={x:box.x+box.width*.67,y:box.y+box.height*.50};
  await page.mouse.move(source.x+source.width/2,source.y+source.height/2);
  await page.mouse.down();await page.mouse.move(to.x,to.y,{steps:20});
  const layer=await stage.evaluate(()=>({
   front:document.querySelector('#scene').lastElementChild?.id,
   visible:!!window.__b6r8Case.dragPreview?.querySelector('circle'),
   behind:!!(document.querySelector('#b6r7Case').compareDocumentPosition(document.querySelector('#scrolls'))&Node.DOCUMENT_POSITION_FOLLOWING)
  }));
  assert.equal(layer.front,'b6r8DragPreview');
  assert(layer.visible&&layer.behind,'Dragged scroll stays above case');
  await page.mouse.up();
  assert.equal(await stage.evaluate(()=>window.__b6r8Case.items.length),1,'Drag enters focused Scroll Case');
  await page.waitForTimeout(1100);
  for(let i=0;i<9;i++){
   if(!await page.evaluate(()=>!!window.__cubbyB6r9.cellBridge.rackId))break;
   await page.locator('#b4SaveCell').click();await page.waitForTimeout(850);
  }
  const saved=await page.evaluate(([rack,key])=>{
   const a=window.__cubbyB6r9,m=a.current().mods.find(q=>q.id===rack);
   return{open:!!a.cellBridge.rackId,source:m.scrollCells[key].length,items:a.holder.items.map(q=>q.id)};
  },[before.id,before.key]);
  assert.equal(saved.open,false,'Cell saved');
  assert.equal(saved.source,before.count-1,'One source scroll removed');
  assert.deepEqual(saved.items,[before.first],'Same scroll ID stored exactly once');
  // The centered dock opens only on approach and its X must actually close it.
  const toggle=await page.locator('#b6HolderToggle').boundingBox();assert(toggle);
  await page.mouse.move(20,200);
  assert.equal(await page.locator('#b6Holder').getAttribute('data-expanded'),'false');
  await page.mouse.move(toggle.x+toggle.width/2,toggle.y+toggle.height/2,{steps:8});
  assert.equal(await page.locator('#b6Holder').getAttribute('data-expanded'),'true');
  await page.locator('#b6HolderClose').click();
  assert.equal(await page.locator('#b6Holder').getAttribute('data-expanded'),'false','Outer X works');
  await page.mouse.move(20,200);
  await page.mouse.move(toggle.x+toggle.width/2,toggle.y+toggle.height/2,{steps:8});
  assert.equal(await page.locator('#b6Holder').getAttribute('data-expanded'),'true');
  // Rack overview drag must remain available, not start with the case opened.
  await page.mouse.move(20,200);
  const from=await page.evaluate(()=>{
   const a=window.__cubbyB6r9;a.setSample('code');const m=a.current().mods.find(q=>q.type==='rack');
   const [key,scrolls]=Object.entries(m.scrollCells).find(([,arr])=>arr.length>=2);
   const dest=a.geomForRack(m).cells.find(c=>c.key!==key&&c.area>10000&&(!m.scrollCells[c.key]||!m.scrollCells[c.key].length));
   if(!dest)throw Error('No full empty destination');
   return{rack:m.id,key,dest:dest.key,id:scrolls[0].id,count:scrolls.length};
  });
  const a=await page.locator('#scene [data-rack-scroll="'+from.id+'"]').boundingBox();
  const d=await page.locator('#scene [data-rack-cell="'+from.dest+'"]').first().boundingBox();
  assert(a&&d);
  await page.mouse.move(a.x+a.width/2,a.y+a.height/2);await page.mouse.down();
  await page.mouse.move(d.x+d.width/2,d.y+d.height/2,{steps:20});
  assert.equal(await page.evaluate(()=>window.__cubbyB6r9.crossTransfer?.phase),'drag','Overview drag active');
  assert.equal(await page.locator('#b6Holder').getAttribute('data-expanded'),'false','Dock stays closed away from pointer');
  await page.mouse.up();
  assert.equal(await page.evaluate(()=>window.__cubbyB6r9.crossTransfer?.phase),'inspector','Overview drag opens destination inspector');
  await page.locator('#b4DiscardCell').click();
  const restored=await page.evaluate(([rack,key,id])=>{
   const app=window.__cubbyB6r9,m=app.current().mods.find(q=>q.id===rack);
   return{transfer:!!app.crossTransfer,exists:m.scrollCells[key].some(q=>q.id===id),count:m.scrollCells[key].length};
  },[from.rack,from.key,from.id]);
  assert.deepEqual(restored,{transfer:false,exists:true,count:from.count},'Cancel restores rack source');
  // Rack-to-case drag: approaching the dock opens it only during hover, then stores the ID.
  const b=await page.locator('#scene [data-rack-scroll="'+from.id+'"]').boundingBox();
  const pill=await page.locator('#b6HolderToggle').boundingBox();
  assert(b&&pill);
  await page.mouse.move(b.x+b.width/2,b.y+b.height/2);await page.mouse.down();
  await page.mouse.move(b.x+80,b.y-45,{steps:8});
  assert.equal(await page.locator('#b6Holder').getAttribute('data-expanded'),'false');
  await page.mouse.move(pill.x+pill.width/2,pill.y+pill.height/2,{steps:20});
  assert.equal(await page.locator('#b6Holder').getAttribute('data-expanded'),'true','Approach opens outer drop zone');
  const dock=await page.locator('#b6HolderPanel').boundingBox();assert(dock);
  await page.mouse.move(dock.x+dock.width/2,dock.y+dock.height-35,{steps:6});
  const ghost=await page.evaluate(()=>{
   const app=window.__cubbyB6r9,g=app.rackDragGhost,p=document.getElementById('b6HolderPanel');
   if(!g||!p)return{exists:false};
   const a=g.getBoundingClientRect(),b=p.getBoundingClientRect();
   return{exists:true,z:Number(getComputedStyle(g).zIndex),pointerEvents:getComputedStyle(g).pointerEvents,
    overlaps:!!(a.left<b.right&&a.right>b.left&&a.top<b.bottom&&a.bottom>b.top),
    bounds:{x:a.left,y:a.top,w:a.width,h:a.height}};
  });
  assert(ghost.exists&&ghost.z>=100000&&ghost.pointerEvents==='none','Carried rack scroll is topmost and nonblocking');
  if(!ghost.overlaps)console.log('B6r9 ghost geometry diagnostic:',JSON.stringify({ghost,dock}));
  assert(ghost.overlaps,'Drag ghost remains visibly over the opened case panel');
  await page.mouse.up();
  const carried=await page.evaluate(()=>({
   transfer:!!window.__cubbyB6r9.crossTransfer,ids:window.__cubbyB6r9.holder.items.map(q=>q.id)
  }));
  assert.equal(carried.transfer,false);
  assert.deepEqual(carried.ids,[from.id],'Rack-to-case preserves exactly one ID');
  assert.deepEqual(errors,[],'No page errors');
  console.log('PASS B6r9 Chromium: proximity, both X controls, drag ghost above case, Save IDs, rack cross-cell Cancel and rack-to-case hover.');
 }finally{await browser.close();}
})().catch(e=>{console.error(e.stack||e);process.exit(1);});
