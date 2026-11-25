import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {chromium} from 'playwright';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const dir=path.join(root,'quickshell/archive/representation-assets');
const m=JSON.parse(fs.readFileSync(path.join(dir,'manifest.json'),'utf8'));
const browser=await chromium.launch({headless:true});
let count=0;
try{
 const page=await browser.newPage({viewport:{width:1366,height:900}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 for(const [key,source] of Object.entries(m.source)){
  await page.goto('about:blank');await page.setContent(fs.readFileSync(path.join(root,source.path),'utf8'));
  const assets=Object.values(m.assets).filter(a=>key==='upright'?['record','ledger','tablet'].includes(a.family):a.family===key);
  for(let i=0;i<assets.length;i++){
   const a=assets[i];
   for(const view of ['face','edge'].filter(v=>a[v])){
    const actual=fs.readFileSync(path.join(dir,a[view]),'utf8');
    const result=await page.evaluate(async ({key,id,i,view,actual})=>{
     let reference;
     if(key==='artwork')reference=drawing(i);
     else if(key==='sculpture')reference=art(files.find(f=>f.shape===id.split('/')[1]),'asset');
     else if(key==='parcel')reference=art(files.find(f=>f.id===id.split('/')[1]),'asset');
     else {
      const [family,v]=id.split('/'),f=files.find(f=>f.id===family+'-'+(Number(v.slice(1))-1));
      const defs=document.querySelector('#stage defs').outerHTML;
      reference=defs+(view==='face'?face(f,0,0,1):edge(f,0,0,f.t,f.h));
     }
     const parser=new DOMParser(),ns='http://www.w3.org/2000/svg';
     const aa=parser.parseFromString(actual,'image/svg+xml'),bb=parser.parseFromString('<svg xmlns="'+ns+'">'+reference+'</svg>','image/svg+xml');
     if(aa.querySelector('parsererror')||bb.querySelector('parsererror'))throw Error('Invalid SVG XML '+id);
     function compare(a,b){
      if(a.localName!==b.localName)throw Error('Element mismatch '+id);
      const attrs=x=>Array.from(x.attributes).filter(q=>q.name!=='xmlns').sort((u,v)=>u.name.localeCompare(v.name));
      const x=attrs(a),y=attrs(b);
      if(x.length!==y.length)throw Error('Attribute count '+id);
      for(let j=0;j<x.length;j++){
       if(x[j].name!==y[j].name)throw Error('Attribute name '+id);
       if(x[j].value===y[j].value)continue;
       if(x[j].name==='d'&&a.getAttribute('class')==='throwing-ring'){
        const numbers=s=>s.match(/-?(?:\d*\.)?\d+(?:e[+-]?\d+)?/gi).map(Number);
        const u=numbers(x[j].value),v=numbers(y[j].value);
        if(u.length===v.length&&u.every((n,k)=>Math.abs(n-v[k])<.02))continue;
       }
       throw Error('Attribute mismatch '+id+' '+x[j].name+' '+x[j].value+' != '+y[j].value);
      }
      if(a.children.length!==b.children.length)throw Error('Child count '+id);
      for(let j=0;j<a.children.length;j++)compare(a.children[j],b.children[j]);
     }
     if(aa.documentElement.children.length!==bb.documentElement.children.length)throw Error('Root children '+id);
     for(let j=0;j<aa.documentElement.children.length;j++)compare(aa.documentElement.children[j],bb.documentElement.children[j]);
     const image=new Image();image.src='data:image/svg+xml;charset=utf-8,'+encodeURIComponent(actual);await image.decode();
     return {w:image.naturalWidth,h:image.naturalHeight};
    },{key,id:a.id,i,view,actual});
    assert.ok(result.w>0&&result.h>0);count++;
   }
  }
 }
 assert.equal(count,64);assert.deepEqual(errors,[]);
 console.log('B7-C: 64 SVG views match actual Chromium reference structures (ceramic arcs within .02 units), all decode');
}finally{await browser.close()}
