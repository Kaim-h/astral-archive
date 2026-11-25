import { chromium } from "playwright";
import {pathToFileURL} from "node:url";
import path from "node:path";
import assert from "node:assert/strict";
import * as V from "../quickshell/archive/ArchiveView.mjs";
const browser=await chromium.launch({headless:true,args:["--allow-file-access-from-files"]});
try{
 const page=await browser.newPage({viewport:{width:1366,height:768}});
 const errors=[];page.on("pageerror",e=>errors.push(String(e)));
 await page.goto(pathToFileURL(path.resolve("docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r12b3.html")).href);
 await page.waitForFunction(()=>!!window.__cubbyB6r12b3);
 const fixture=V.fixture();
 await page.evaluate(s=>{
  const a=window.__cubbyB6r12b3;
  for(const c of Object.values(s.cubbies)){c.depth=c.id==="root"?0:1;c.camera={zoom:1,dx:0,dy:0};c.selected=null;c.color=null;c.innerColor=null;}
  a.state.cubbies=s.cubbies;a.state.path=s.path;a.state.next=s.next;a.state.theme="twilight";a.state.moduleScheme="balanced";a.state.previewMode="veiled";
  a.holder.items=s.caseItems;a.holder.selectedId=null;a.renderHolder();a.setMode("browse");
 },fixture);
 assert.equal(await page.locator("#scene [data-rack-scroll]").count(),Object.values(fixture.cubbies.root.mods[0].scrollCells).flat().length);
 await page.mouse.move(1,1);await page.waitForTimeout(150);
 await page.screenshot({path:"archive-browser-reference.png"});
 // Use the same committed fixture, viewport and scenarios in the native
 // capture test. Change only view settings; do not modify archived HTML.
 const scenarios=[
  {name:"evening-inventory",theme:"evening",mode:"inventory",path:["root"]},
  {name:"midnight-closed",theme:"midnight",mode:"closed",path:["root"]},
  {name:"twilight-child",theme:"twilight",mode:"veiled",path:["root","child"]}
 ];
 for(const scenario of scenarios){
  await page.evaluate(q=>{
   const a=window.__cubbyB6r12b3;
   a.state.theme=q.theme;a.state.previewMode=q.mode;a.state.path=q.path;
   a.setMode("browse");a.renderHolder();
  },scenario);
  const c=fixture.cubbies[scenario.path[scenario.path.length-1]];
  const count=c.mods.filter(m=>m.type==="rack").flatMap(m=>Object.values(m.scrollCells).flat()).length;
  assert.equal(await page.locator("#scene [data-rack-scroll]").count(),count);
  if(scenario.mode==="inventory")assert.equal(await page.locator('#scene [data-child-preview][data-preview-mode="inventory"]').count(),1);
  if(scenario.mode==="closed")assert.equal(await page.locator("#scene [data-child-preview]").count(),0);
  await page.mouse.move(1,1);await page.waitForTimeout(150);
  await page.screenshot({path:`archive-browser-reference-${scenario.name}.png`});
 }
 assert.deepEqual(errors,[]);
 console.log("Captured actual B6r12b3 SVG browser reference: default, inventory, closed, entered child.");
}finally{await browser.close()}
