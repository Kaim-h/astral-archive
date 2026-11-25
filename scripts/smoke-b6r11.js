'use strict';
const assert=require('node:assert/strict');
const path=require('node:path'),{pathToFileURL}=require('node:url');
const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--disable-web-security','--allow-file-access-from-files']});
 const page=await browser.newPage({viewport:{width:1550,height:1030}}),errors=[];
 page.on('pageerror',e=>errors.push(e.stack||e.message));
 try{
  await page.goto(pathToFileURL(path.resolve('docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r11.html')).href);
  await page.waitForFunction(()=>!!window.__cubbyB6r11,{timeout:10000});
  const structure=await page.evaluate(()=>{
   const app=window.__cubbyB6r11;app.setSample('code');
   const m=app.current().mods.find(x=>x.type==='rack');
   const shapes=app.cellShapes;
   const data=app.b6Reflow(m,{...m,r:38});
   const available=app.geomForRack({...m,r:38}).cells;
   const issue=(data.issues||[]).find(q=>available.some(c=>c.key===q.sourceKey)&&q.count>1);
   let result=null;
   if(issue){
    const plan=app.b6Reflow(m,{...m,r:38},{[issue.cellId]:'split',__splitTargets:{[issue.cellId]:'case'}});
    const split=(plan.approvedSplits||[]).find(q=>q.cellId===issue.cellId);
    const originalId=m.cellMeta?.[issue.sourceKey]?.id||issue.sourceKey;
    const proposedId=plan.meta?.[issue.sourceKey]?.id||null;
    const before=(m.scrollCells[issue.sourceKey]||[]).map(s=>s.id).sort();
    const after=[...(plan.mapped?.[issue.sourceKey]||[]),...(plan.caseOverflow||[]).filter(x=>x.originKey===issue.sourceKey)].map(s=>s.id).sort();
    result={source:issue.sourceKey,id:issue.cellId,split:split||null,
     originalId,proposedId,caseCount:plan.caseOverflow?.length||0,
     identities:JSON.stringify(before)===JSON.stringify(after),issueCount:plan.issues?.length};
   }
   return{radius:m.r,shapes,issueCount:data.issues?.length,splitResult:result};
  });
  assert.equal(structure.shapes.hex.supported,true);
  for(const shape of ['square','triangle','diamond'])assert.equal(structure.shapes[shape].supported,false);
  assert(structure.splitResult&&structure.splitResult.split,
   'A 64→38 overfull-cell fixture must permit an owner-approved split to the case: '+JSON.stringify(structure));
  assert.equal(structure.splitResult.split.primaryKey,structure.splitResult.source,'Primary cell remains in place');
  assert.equal(structure.splitResult.proposedId,structure.splitResult.originalId,'Primary cell retains exact stable ID');
  assert(structure.splitResult.caseCount>0&&structure.splitResult.identities,'Case overflow conserves every ID');

  // Radius above 60 is a usability warning, not silent loss or a global hard cap.
  await page.evaluate(()=>{
   const a=window.__cubbyB6r11,m=a.current().mods.find(x=>x.type==='rack');
   a.previewRackResize(m,{r:65});
  });
  await page.waitForFunction(()=>['ready','attention','invalid'].includes(window.__cubbyB6r11.b6Preview?.phase),{timeout:14000});
  assert.equal(await page.locator('#b11RadiusNotice').isVisible(),true);
  assert.equal(await page.locator('#b11RadiusAcknowledge').isChecked(),false);
  await page.evaluate(()=>window.__cubbyB6r11.cancelRackResize());

  // Test a *committed* transfer out of the case: previous tests only checked Cancel.
  const carried=await page.evaluate(()=>{
   const a=window.__cubbyB6r11,m=a.current().mods.find(x=>x.type==='rack');
   const [origin,records]=Object.entries(m.scrollCells).find(([,arr])=>arr.length>=1);
   const item=records.shift();
   a.holder.items.push({...item,originRackId:m.id,originCubbyId:a.current().id,
    originKey:origin,originCellId:m.cellMeta?.[origin]?.id||origin});
   a.renderHolder();
   const dest=a.geomForRack(m).cells.find(c=>c.area>10000&&c.key!==origin&&(!m.scrollCells[c.key]||m.scrollCells[c.key].length===0));
   if(!dest)throw Error('Missing empty cell');
   return {id:item.id,rack:m.id,cell:dest.key};
  });
  const toggle=await page.locator('#b6HolderToggle').boundingBox();assert(toggle);
  await page.mouse.move(toggle.x+toggle.width/2,toggle.y+toggle.height/2,{steps:7});
  await page.waitForFunction(()=>document.querySelector('#b6Holder').dataset.expanded==='true');
  const source=await page.locator('#b6HolderItems [data-shelf-scroll="'+carried.id+'"]').boundingBox();
  const dest=await page.locator('#scene [data-rack-cell="'+carried.cell+'"]').first().boundingBox();
  assert(source&&dest,'Case source scroll and destination must be visible');
  await page.mouse.move(source.x+source.width/2,source.y+source.height/2);
  await page.mouse.down();
  await page.mouse.move(dest.x+dest.width/2,dest.y+dest.height/2,{steps:26});
  await page.mouse.up();
  await page.waitForFunction(()=>window.__cubbyB6r11.cellBridge.ready,{timeout:10000});
  const frame=page.frameLocator('#b4Frame');
  const arrival=await frame.locator('#scene').evaluate(()=>{
   const s=window.__studyP2R.state;return{held:!!s.held,fromHeld:!!s.insertion?.fromHeld};
  });
  assert(arrival.held&&arrival.fromHeld,'Arrival prepares genuine held-scroll insertion');
  await frame.locator('#stage').click();
  await page.waitForFunction(()=>{
   const frame=document.querySelector('#b4Frame')?.contentWindow;
   if(!frame?.__studyP2R)return false;
   const s=frame.__studyP2R.state;
   return !s.active&&!s.transaction&&!s.insertion&&!s.held&&s.bodies.some(b=>b.name);
  },{timeout:16000});
  let saved=false;
  for(let i=0;i<4;i++){
   if(!await page.evaluate(()=>!!window.__cubbyB6r11.cellBridge.rackId)){saved=true;break;}
   await page.locator('#b4SaveCell').click();
   await page.waitForTimeout(850);
  }
  if(!saved)saved=!await page.evaluate(()=>!!window.__cubbyB6r11.cellBridge.rackId);
  const final=await page.evaluate(([rackId,cell,id])=>{
   const a=window.__cubbyB6r11,m=a.current().mods.find(x=>x.id===rackId);
   return{stillOpen:!!a.cellBridge.rackId,stored:(m.scrollCells[cell]||[]).filter(x=>x.id===id).length,
    inCase:a.holder.items.filter(x=>x.id===id).length,saveOk:a.saveStudy()};
  },[carried.rack,carried.cell,carried.id]);
  assert.equal(saved,true,'Save should complete, not silently return scroll to case');
  assert.deepEqual(final,{stillOpen:false,stored:1,inCase:0,saveOk:true},'Exactly one saved home');

  await page.reload();
  await page.waitForFunction(()=>!!window.__cubbyB6r11);
  const reloaded=await page.evaluate(([rackId,cell,id])=>{
   const a=window.__cubbyB6r11;
   const loaded=a.loadStudy();
   const m=a.current().mods.find(x=>x.id===rackId);
   return{loaded,stored:(m?.scrollCells[cell]||[]).filter(x=>x.id===id).length,inCase:a.holder.items.filter(x=>x.id===id).length};
  },[carried.rack,carried.cell,carried.id]);
  assert.deepEqual(reloaded,{loaded:true,stored:1,inCase:0},'Committed placement persists across re-opening saved study');
  assert.deepEqual(errors,[],'No browser errors');
  console.log('PASS B6r11 Chromium: home-anchored split with overflow into case, radius warning, confirmed case→rack insertion Save and reload persist same ID.');
 }finally{await browser.close();}
})().catch(err=>{console.error(err.stack||err);process.exit(1);});
