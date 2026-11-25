import { chromium } from 'playwright';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const path='docs/research/prototypes/2026-11-24/b8/Astral_Archive_Shelf_Study_B8s2.html';
const browser=await chromium.launch({headless:true});
try{
 const p=await browser.newPage({viewport:{width:1366,height:900}});
 const errors=[];p.on('pageerror',e=>errors.push(String(e)));
 await p.goto(pathToFileURL(process.cwd()+'/'+path).href);
 const cubby=p.locator('[data-cubby=manuscripts]');
 assert.equal(await cubby.getAttribute('data-mode'),'open');
 for(const mode of ['veiled','inventory','closed','open']){await cubby.click();assert.equal(await cubby.getAttribute('data-mode'),mode)}
 await p.locator('[data-cubby=notes]').focus();await p.keyboard.press('Enter');assert.equal(await p.locator('[data-cubby=notes]').getAttribute('data-mode'),'inventory');
 await p.locator('#allOpen').click();assert.equal(await p.locator('[data-mode=open]').count(),3);
 const assets=await p.evaluate(()=>Object.entries(ASSETS).map(([id,a])=>({id,...a})));
 for(const a of assets){const bytes=Buffer.from(a.svg);assert.deepEqual(bytes,fs.readFileSync('quickshell/archive/representation-assets/'+a.path));assert.equal(crypto.createHash('sha1').update('blob '+bytes.length+'\0').update(bytes).digest('hex'),a.sha)}
 assert.equal(assets.length,7);
 const decoded=await p.evaluate(async()=>Promise.all([...document.querySelectorAll('image[data-asset]')].map(async el=>{const im=new Image();im.src=el.getAttribute('href');await im.decode();return im.naturalWidth>0})));
 assert.ok(decoded.length>=7&&decoded.every(Boolean));
 assert.equal(await p.locator('svg text').filter({hasText:'FIELD SCROLLS'}).count(),0);
 await p.locator('#allClosed').click();assert.equal(await p.locator('[data-mode=closed]').count(),3);
 await p.locator('#allOpen').click();
 await p.locator('#guides').click();assert.equal(await p.locator('#guides').getAttribute('aria-pressed'),'true');
 await p.locator('#edit').click();await p.locator('#width').focus();await p.keyboard.press('End');
 assert.equal(await p.locator('#wo').innerText(),'1100');await p.locator('#cancel').click();assert.equal(await p.locator('#wo').innerText(),'840');
 await p.locator('#height').focus();await p.keyboard.press('End');await p.locator('#apply').click();assert.equal(await p.locator('#ho').innerText(),'660');
 await p.locator('#undo').click();assert.equal(await p.locator('#ho').innerText(),'480');
 await p.locator('#width').focus();await p.keyboard.press('Home');await p.locator('#height').focus();await p.keyboard.press('Home');
 assert.equal(await p.locator('#wo').innerText(),'700');assert.equal(await p.locator('#ho').innerText(),'440');
 await p.locator('#edit').click();await p.locator('#edit').click();assert.equal(await p.locator('#wo').innerText(),'700');await p.locator('#cancel').click();
 await p.locator('#edit').click();await p.locator('#guides').click();
 for(const theme of ['Twilight','Evening','Midnight'])for(const profile of ['crest','cornice','pilaster']){await p.locator('#theme').selectOption(theme);await p.locator('#profile').selectOption(profile);assert.equal(await p.locator('[data-cubby]').count(),3)}
 await p.locator('#theme').selectOption('Twilight');await p.locator('#profile').selectOption('crest');await p.locator('#allOpen').click();
 await p.screenshot({path:'B8s2-preview.png',fullPage:true});
 await p.setViewportSize({width:500,height:750});assert.ok(await p.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
 assert.deepEqual(errors,[]);console.log('B8s2: pointer/keyboard modes, exact seven asset bytes, decode, themes/profiles, envelope transactions, responsive width, zero page errors passed');
}finally{await browser.close()}
