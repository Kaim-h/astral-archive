'use strict';
const {chromium}=require('playwright'),assert=require('node:assert/strict'),path=require('node:path'),{pathToFileURL}=require('node:url');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--disable-web-security','--allow-file-access-from-files']});
 const page=await browser.newPage({viewport:{width:1550,height:1024}}),errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 try{
  await page.goto(pathToFileURL(path.resolve('docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r7.html')).href);
  await page.waitForFunction(()=>!!window.__cubbyB6r7);
  const before=await page.evaluate(()=>{
   const a=window.__cubbyB6r7;a.setSample('code');
   const m=a.current().mods.find(v=>v.type==='rack');
   const [key,contents]=Object.entries(m.scrollCells).find(([,arr])=>arr.length>=4);
   if(!a.openCellDirect(m,key))throw Error('Could not open cell');
   return {rack:m.id,key,count:contents.length,ids:contents.map(v=>v.id)};
  });
  const frame=page.frameLocator('#b4Frame');
  await frame.locator('#b6r7Case').waitFor();
  await page.waitForFunction(()=>window.__cubbyB6r7.cellBridge.ready);
  assert.equal(await frame.locator('#trayLayer').evaluate(el=>getComputedStyle(el).display),'none','Obsolete tray hidden');
  assert.equal(await frame.locator('[data-case-cradle]').count(),1);
  assert.equal(await page.locator('#b6Holder').evaluate(el=>getComputedStyle(el).display),'none','Duplicated focused dock hidden');
  const scrolls=frame.locator('#scrolls [data-id]');
  assert.equal(await scrolls.count(),before.count);
  for(let i=0;i<3;i++){
   const r=await scrolls.nth(i).boundingBox();assert(r);
   if(i===1)await page.keyboard.down('Control');
   await page.mouse.click(r.x+r.width/2,r.y+r.height/2);
  }
  await page.keyboard.up('Control');
  assert.equal((await frame.locator('#scene').evaluate(()=>window.__b6r7Case.selected)).length,3,'Ctrl+click group');
  await frame.locator('#scene').focus();
  await page.keyboard.press('Control+x');
  const preview=await frame.locator('#scene').evaluate(()=>({count:window.__studyP2R.state.bodies.length,case:window.__b6r7Case.items.map(b=>({id:b.id,mode:b.moveMode}))}));
  assert.equal(preview.count,before.count-3);
  assert.equal(preview.case.length,3);
  assert(preview.case.every(b=>b.mode==='cut'));
  await page.waitForTimeout(1200);
  for(let i=0;i<13;i++){
   if(!await page.evaluate(()=>!!window.__cubbyB6r7.cellBridge.rackId))break;
   await page.locator('#b4SaveCell').click();
   await page.waitForTimeout(850);
  }
  const saved=await page.evaluate(([rack,key])=>{
   const a=window.__cubbyB6r7,m=a.current().mods.find(v=>v.id===rack);
   return{open:!!a.cellBridge.rackId,remaining:m.scrollCells[key].length,case:a.holder.items.map(b=>({id:b.id,mode:b.moveMode})),active:a.holder.active.length};
  },[before.rack,before.key]);
  assert.equal(saved.open,false,'Save after settling');
  assert.equal(saved.remaining,before.count-3);
  assert.deepEqual(saved.case.map(x=>x.id),before.ids.slice(0,3),'Identities stable');
  assert.equal(saved.active,0,'One authoritative case');
  await page.locator('#b6HolderToggle').click();
  assert.equal(await page.locator('#b6HolderToggle').evaluate(el=>getComputedStyle(el).display),'none','No expanded dock bar');
  assert.equal(await page.locator('#b6HolderItems [data-shelf-scroll]').count(),3);
  await page.locator('#b6r7ManifestToggle').click();
  assert.equal(await page.locator('#b6r7OuterLedger li').count(),3);
  await page.locator('#b6HolderClose').click();
  assert.equal(await page.locator('#b6Holder').getAttribute('data-expanded'),'false');
  assert.equal(await page.evaluate(()=>window.__cubbyB6r7.holder.items.length),3);
  assert.equal(errors.length,0,errors.join('\n'));
  console.log('PASS B6r7 Chromium: real Ctrl-click, group cut, Save, IDs, original cradle, manifest and dock collapse.');
 }finally{await browser.close();}
})().catch(e=>{console.error(e.stack||e);process.exit(1);});
