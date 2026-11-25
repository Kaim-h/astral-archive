import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {chromium} from 'playwright';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const canonical=path.join(root,'quickshell/archive/representation-assets');
const output=path.join(root,'quickshell/archive/representation-raster');
const m=JSON.parse(fs.readFileSync(path.join(canonical,'manifest.json'),'utf8'));
const hash=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const scale=4,entries=[];
const browser=await chromium.launch({headless:true});
try{
 const page=await browser.newPage();
 for(const a of Object.values(m.assets)){
  if(a.family!=='sculpture'){
   for(const file of [a.face,a.edge].filter(Boolean)){
    assert.ok(!/<clipPath\b|clip-path=/.test(fs.readFileSync(path.join(canonical,file),'utf8')),
      'New clipped non-sculpture asset needs explicit rendering policy: '+file);
   }
   continue;
  }
  const source=fs.readFileSync(path.join(canonical,a.face),'utf8');
  const [,,w,h]=a.geometry.viewport;
  const result=await page.evaluate(async ({source,w,h,scale})=>{
   const image=new Image();
   image.src='data:image/svg+xml;charset=utf-8,'+encodeURIComponent(source);
   await image.decode();
   if(image.naturalWidth!==w||image.naturalHeight!==h)throw Error('SVG dimensions differ from viewport');
   const canvas=document.createElement('canvas');canvas.width=w*scale;canvas.height=h*scale;
   const ctx=canvas.getContext('2d',{willReadFrequently:true});
   ctx.drawImage(image,0,0,canvas.width,canvas.height);
   const data=ctx.getImageData(0,0,canvas.width,canvas.height).data;
   let opaque=0,transparent=0;
   for(let i=3;i<data.length;i+=4){if(data[i]>0)opaque++;else transparent++;}
   const corners=[0,canvas.width-1,(canvas.height-1)*canvas.width,canvas.width*canvas.height-1].map(i=>data[i*4+3]);
   return {png:canvas.toDataURL('image/png').split(',')[1],opaque,transparent,corners};
  },{source,w,h,scale});
  assert.ok(result.opaque>0&&result.transparent>0&&result.corners.every(a=>a===0),'Invalid transparent sculpture '+a.id);
  const png=Buffer.from(result.png,'base64'),file=a.face.replace(/\.svg$/,'.png');
  assert.equal(png.readUInt32BE(16),w*scale);assert.equal(png.readUInt32BE(20),h*scale);
  const target=path.join(output,file);fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,png);
  entries.push({id:a.id,source:a.face,sourceSha256:hash(source),file,pngSha256:hash(png),width:w*scale,height:h*scale});
 }
 assert.equal(entries.length,16);
 fs.writeFileSync(path.join(output,'provenance.json'),JSON.stringify({schema:1,scale,browser:browser.version(),entries},null,2)+'\n');
 console.log('Generated 16 transparent sculpture derivatives at 4x from canonical SVG; all other assets remain direct vector');
}finally{await browser.close()}
