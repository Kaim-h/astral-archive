'use strict';
const {chromium}=require('playwright'),assert=require('node:assert/strict'),path=require('node:path'),{pathToFileURL}=require('node:url');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--disable-web-security','--allow-file-access-from-files']});
 const page=await browser.newPage({viewport:{width:1550,height:1024}}),errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 try{
  // Capture the real keyboard/relay route before application listeners.
  // Window capture precedes the inner document's stopImmediatePropagation.
  await page.addInitScript(()=>{
   const trace=window.__b6r7CutSmokeTrace=[];
   function note(route){
    const st=window.__studyP2R?.state,active=document.activeElement;
    trace.push({route,time:performance.now(),focus:active?.tagName,id:active?.id,
     selected:window.__b6r7Case?.selected,source:st?.bodies.map(b=>b.id),
     guards:st?Object.fromEntries(['drag','pointer','insertion','held','stagedId','transaction'].map(k=>[k,!!st[k]])):null});
   }
   window.addEventListener('keydown',e=>{
    if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==='x')note('keydown');
   },true);
   window.addEventListener('message',e=>{
    if(e.source===parent&&e.data?.channel==='astral-b4'&&e.data.action==='cut')note('cut relay received');
   },true);
  });
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
  const child=await (await page.locator('#b4Frame').elementHandle()).contentFrame();
  assert(child,'Cell iframe available');
  const readCut=()=>child.evaluate(()=>{
   const st=window.__studyP2R.state,a=window.__b6r7Case,active=document.activeElement;
   return {count:st.bodies.length,source:st.bodies.map(b=>b.id),
    selected:a.selected,case:a.items.map(b=>({id:b.id,mode:b.moveMode})),
    focus:active?.tagName,focusId:active?.id,
    guards:Object.fromEntries(['drag','pointer','insertion','held','stagedId','transaction'].map(k=>[k,!!st[k]])),
    trace:window.__b6r7CutSmokeTrace||[]};
  });
  // The cell bridge maps persistent IDs to temporary numeric IDs 1..N.
  // Verify the bridge itself before comparing the two identity domains.
  const bridge=await page.evaluate(()=>window.__cubbyB6r7.cellBridge.indexMap);
  assert.deepEqual(Object.keys(bridge).map(Number),before.ids.map((_,i)=>i+1),'Bridge keys');
  assert.deepEqual(before.ids.map((_,i)=>bridge[i+1]),before.ids,'Bridge preserves persistent IDs');
  const temporary=before.ids.map((_,i)=>i+1);
  const expected={carried:temporary.slice(0,3),remaining:temporary.slice(3)};
  const selected=await readCut();
  assert.equal(selected.selected.length,3,'Ctrl+click group');
  assert.deepEqual([...selected.selected].sort(),[...expected.carried].sort(),'Exact selected IDs');
  assert.deepEqual([...selected.source].sort(),[...temporary].sort(),'Initial temporary cell IDs');
  assert.equal(selected.case.length,0,'Initially empty Case');
  // Historical SVG focus is not necessarily effective. Preserve actual input,
  // allow either legitimate keyboard route, and record where the key went.
  await frame.locator('#scene').focus();
  const focusBefore=await page.evaluate(()=>({tag:document.activeElement?.tagName,id:document.activeElement?.id}));
  await page.keyboard.press('Control+x');
  const immediate=await readCut();
  try{
   // The parent key handler uses postMessage; keyboard.press is not an
   // acknowledgement that the child cut has finished. Wait for exact membership,
   // not merely a count, without repeating the key or invoking the model.
   await child.waitForFunction(({remaining,carried})=>{
    const st=window.__studyP2R.state,items=window.__b6r7Case.items;
    const ids=st.bodies.map(b=>b.id);
    return ids.length===remaining.length&&remaining.every(id=>ids.includes(id))&&
     items.length===carried.length&&carried.every(id=>items.some(b=>b.id===id&&b.moveMode==='cut'));
   },expected,{timeout:3000});
  }catch(error){
   // A lost/refused cut must still fail. Keep route and guard evidence rather
   // than masking it with another key press or arbitrary sleep.
   console.error('AUD-21 cut did not complete:',JSON.stringify({expected,selected,focusBefore,immediate,
    final:await readCut(),parentTrace:await page.evaluate(()=>window.__b6r7CutSmokeTrace||[])}));
   throw error;
  }
  const preview=await readCut();
  assert.equal(preview.count,before.count-3);
  assert.equal(preview.case.length,3);
  assert(preview.case.every(b=>b.mode==='cut'));
  assert.deepEqual([...preview.source].sort(),[...expected.remaining].sort(),'Exact remaining source IDs');
  assert.deepEqual(preview.case.map(b=>b.id),expected.carried,'Exact carried IDs');
  console.log('AUD-21 cut observation:',JSON.stringify({focusBefore,immediateCount:immediate.count,
   finalCount:preview.count,childTrace:preview.trace,parentTrace:await page.evaluate(()=>window.__b6r7CutSmokeTrace||[])}));
  await page.waitForTimeout(1200);
  for(let i=0;i<13;i++){
   if(!await page.evaluate(()=>!!window.__cubbyB6r7.cellBridge.rackId))break;
   await page.locator('#b4SaveCell').click();
   await page.waitForTimeout(850);
  }
  const saved=await page.evaluate(([rack,key])=>{
   const a=window.__cubbyB6r7,m=a.current().mods.find(v=>v.id===rack);
   return{open:!!a.cellBridge.rackId,remaining:m.scrollCells[key].length,remainingIds:m.scrollCells[key].map(b=>b.id),case:a.holder.items.map(b=>({id:b.id,mode:b.moveMode})),active:a.holder.active.length};
  },[before.rack,before.key]);
  assert.equal(saved.open,false,'Save after settling');
  assert.equal(saved.remaining,before.count-3);
  assert.deepEqual([...saved.remainingIds].sort(),before.ids.slice(3).sort(),'Remaining persistent IDs stable');
  assert.deepEqual(saved.case.map(x=>x.id),before.ids.slice(0,3),'Identities stable');
  assert(saved.case.every(x=>x.mode==='cut'),'Saved cut mode preserved');
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
