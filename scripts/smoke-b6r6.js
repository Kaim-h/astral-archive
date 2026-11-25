'use strict';
const assert=require('node:assert/strict');
const path=require('node:path');
const {pathToFileURL}=require('node:url');
const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--disable-web-security','--allow-file-access-from-files']});
 const page=await browser.newPage({viewport:{width:1550,height:1000}});
 const errors=[];
 page.on('pageerror',e=>errors.push('Outer: '+e.stack));
 page.on('console',msg=>{if(msg.type()==='error')errors.push('Console: '+msg.text());});
 try{
  const file=path.resolve('docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r6.html');
  await page.goto(pathToFileURL(file).href);
  await page.waitForFunction(()=>!!window.__cubbyB6r6,{timeout:10000});
  const before=await page.evaluate(()=>{
   const a=window.__cubbyB6r6;a.setSample('code');
   const m=a.current().mods.find(q=>q.type==='rack');
   const cell=Object.entries(m.scrollCells).find(([,scrolls])=>scrolls.length>=1);
   if(!cell)throw Error('No populated cell in code sample');
   const n=cell[1].length;
   if(!a.openCellDirect(m,cell[0]))throw Error('Failed to open physics cell');
   return{rack:m.id,key:cell[0],count:n,id:cell[1][0].id};
  });
  const frame=page.frameLocator('#b4Frame');
  await frame.locator('#b6r6Shelves').waitFor({timeout:10000});
  await page.waitForFunction(()=>window.__cubbyB6r6.cellBridge.ready,{timeout:10000});
  assert.equal(await frame.locator('#scrolls [data-id]').count(),before.count);
  assert.equal(await frame.locator('#trayLayer').evaluate(el=>getComputedStyle(el).display),'none','Obsolete third holder must not be visible');
  assert.equal(await frame.locator('[data-b6r6-cradle]').count(),2,'One original-style cradle per shelf');
  await frame.locator('[data-b6r6-toggle="case"]').click();
  assert.equal(await frame.locator('#scene').evaluate(()=>window.__b6r6Shelves.caseCollapsed),true,'Portable case collapses');
  const selected=frame.locator('#scrolls [data-id]').first();
  const cellbox=await selected.boundingBox();
  const casebox=await frame.locator('[data-b6r6-zone="case"] rect').first().boundingBox();
  assert(cellbox&&casebox,'Visible source scroll and destination shelf');
  const from={x:cellbox.x+cellbox.width/2,y:cellbox.y+cellbox.height/2};
  const to={x:casebox.x+casebox.width*.6,y:casebox.y+casebox.height*.5};
  await page.mouse.move(from.x,from.y);
  await page.mouse.down();
  await page.mouse.move(to.x,to.y,{steps:25});
  await page.mouse.up();
  const virtual=await frame.locator('#scene').evaluate(()=>{
   const a=window.__b6r6Shelves;
   return{active:a.active.length,case:a.portableCase.length,bodies:window.__studyP2R.state.bodies.length};
  });
  assert.deepEqual(virtual,{active:0,case:1,bodies:before.count-1},'Direct drag commits into simulator case shelf');
  assert.equal(await frame.locator('#scene').evaluate(()=>window.__b6r6Shelves.caseCollapsed),false,'Drop onto collapsed case expands the cradle');
  await page.waitForFunction(()=>!window.__cubbyB6r6.cellBridge.requested);
  await page.waitForTimeout(1200);
  for(let i=0;i<3;i++){
   if(await page.evaluate(()=>window.__cubbyB6r6.cellBridge.rackId===null))break;
   await page.locator('#b4SaveCell').click();
   await page.waitForTimeout(1000);
  }
  const after=await page.evaluate(([rackId,key])=>{
   const a=window.__cubbyB6r6,m=a.current().mods.find(q=>q.id===rackId);
   return{open:!!a.cellBridge.rackId,count:m.scrollCells[key].length,
    caseCount:a.holder.items.length,activeCount:a.holder.active.length,
    idInCase:a.holder.items[0]?.id};
  },[before.rack,before.key]);
  assert.equal(after.open,false,'Focused cell closed after successful Save; '+JSON.stringify(after));
  assert.equal(after.count,before.count-1,'Source cell lost exactly one scroll');
  assert.equal(after.caseCount,1,'Portable case received exactly one');
  assert.equal(after.activeCount,0,'Active shelf stays empty');
  assert.equal(after.idInCase,before.id,'Scroll identity is preserved');
  await page.locator('#b6HolderToggle').click();
  assert.equal(await page.locator('#b6r6ActiveItems [data-holder="shelf-scrolls"]').count(),1,'Outer active shelf uses original art');
  assert.equal(await page.locator('#b6HolderItems [data-holder="shelf-scrolls"]').count(),1,'Outer case uses original art');
  await page.locator('#b6r6CaseToggle').click();
  assert.equal(await page.locator('#b6HolderItems').evaluate(el=>getComputedStyle(el).display),'none','Outer case collapses');
  assert.equal(await page.evaluate(()=>window.__cubbyB6r6.holder.items.length),1,'Folding case does not change inventory');
  await page.locator('#b6r6CaseToggle').click();
  assert.notEqual(await page.locator('#b6HolderItems').evaluate(el=>getComputedStyle(el).display),'none','Outer case reopens');
  assert.equal(errors.length,0,'No browser JS errors: '+errors.join('\n'));
  console.log('PASS B6r6 browser smoke: real pointer drag from cell to case, Save commits single removal with stable ID.');
 }finally{if(errors.length)console.log('Browser errors:',errors.join('\n'));await browser.close();}
})().catch(e=>{console.error(e.stack||e);process.exit(1);});
