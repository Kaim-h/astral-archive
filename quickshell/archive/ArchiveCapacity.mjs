// Shared persisted-state preflight; no Core import or geometry solver.
import * as Spatial from "./ArchiveSpatial.mjs";
export const limits=Object.freeze({cubbies:128,modulesPerCubby:64,fixtures:8192,cells:12000,records:4096,snapshotChars:2000000,viewChars:96000,envelopeChars:2100000,legacyChars:2000000});
function fail(msg){throw Error(msg);}
function plain(v){return !!v&&typeof v==='object'&&!Array.isArray(v);}
function id(v){return typeof v==='string'&&v.length>0&&v.length<=128&&!['__proto__','constructor','prototype'].includes(v);}
function finite(v,min,max){return Number.isFinite(v)&&v>=min&&v<=max;}
function color(v){return v===null||v===undefined||(typeof v==='string'&&/^#[0-9a-fA-F]{6}$/.test(v));}
export function pathValid(s,path){
 return Array.isArray(path)&&path.length>0&&path.length<=128&&Spatial.roots(s).includes(path[0])&&path.every((v,i)=>id(v)&&Object.prototype.hasOwnProperty.call(s.cubbies,v)&&(!i||s.cubbies[path[i-1]].mods.some(m=>m.type==='cubby'&&m.childId===v)));
}
function record(v,placed){
 if(!plain(v)||!id(v.id)||!finite(v.r,.1,200)||typeof v.name!=='string'||v.name.length>512)fail('Invalid record');
 if(placed&&(!Number.isFinite(v.x)||!Number.isFinite(v.y)))fail('Invalid position');
}
export function preflight(s,formatVersion=2){
 if(!plain(s)||!plain(s.cubbies)||!Array.isArray(s.caseItems)||s.caseItems.length>limits.records||!Number.isSafeInteger(s.next)||s.next<1)fail('Invalid checkpoint state');
 const spatial=Spatial.enabled(s);
 if(spatial!==(formatVersion===3))fail('Spatial state requires version 3');
 const keys=Object.keys(s.cubbies);if(!keys.length||keys.length>limits.cubbies||(!spatial&&!keys.includes('root')))fail('Physical container budget or root');
 let count=0,cells=0,fixtures=0;const children=new Set();
 function addRecord(v,placed){record(v,placed);if(++count>limits.records)fail('Record budget exceeded');}
 for(const key of keys){
  const c=s.cubbies[key];if(!id(key)||!plain(c)||c.id!==key||!finite(c.w,130,1800)||!finite(c.h,100,1500)||!finite(c.b===undefined?11:c.b,4,40)||!color(c.color)||!color(c.innerColor)||!Array.isArray(c.mods)||c.mods.length>limits.modulesPerCubby)fail('Invalid cubby metadata');
  for(const m of c.mods){
   if(!plain(m)||!id(m.id)||![m.x,m.y,m.w,m.h].every(Number.isFinite)||!color(m.color))fail('Invalid fixture');
   if(++fixtures>limits.fixtures)fail('Fixture budget exceeded');
   const top=spatial&&(m.type==='rack'||m.type==='cubby')&&m.flatTop===true;
   if(m.flatTop!==undefined&&!top)fail('Invalid or unsupported flat top');
   if(m.items!==undefined&&m.type!=='shelf'&&!top)fail('Items require an eligible support surface');
   if(m.type==='shelf'||top){
    if(m.type==='shelf'&&(m.h!==15||m.w<120))fail('Invalid shelf');
    if(m.items!==undefined&&(!Array.isArray(m.items)||m.items.length>64))fail('Invalid support contents');
    if(formatVersion===1&&(m.items||[]).length)fail('Version 1 cannot contain populated shelves');
    for(const e of m.items||[]){
     if(!plain(e))fail('Invalid shelf entry');
     if(++fixtures>limits.fixtures)fail('Fixture budget exceeded');
     if(e.kind==='object')addRecord(e.record,false);
     else if(e.kind==='app'){if(!spatial||!id(e.appId))fail('Application placement requires spatial v3');}
     else if(e.kind==='holder'){
      if(!id(e.id)||!Array.isArray(e.slots)||!e.slots.length||e.slots.length>48)fail('Invalid holder');
      for(const r of e.slots)if(r!==null)addRecord(r,false);
     }else fail('Invalid shelf entry');
    }
   }
   if(m.type==='shelf')continue;
   if(m.type==='cubby'){if(!id(m.childId)||(!spatial&&m.childId==='root'))fail('Invalid child');children.add(m.childId);continue;}
   if(m.type==='artwork'){
    if(formatVersion===1)fail('Version 1 cannot contain artwork mounts');
    if(m.record!==null)addRecord(m.record,false);
    continue;
   }
   if(m.type!=='rack'||!plain(m.cellMeta)||!plain(m.scrollCells))fail('Invalid rack');
   cells+=Object.keys(m.cellMeta).length;if(cells>limits.cells)fail('Cell budget exceeded');
   for(const meta of Object.values(m.cellMeta))if(!plain(meta)||!id(meta.id)||!color(meta.color)||(meta.depth!==undefined&&!finite(meta.depth,0,24)))fail('Invalid cell metadata');
   for(const records of Object.values(m.scrollCells)){if(!Array.isArray(records)||records.length>96)fail('Invalid cell records');for(const v of records)addRecord(v,true);}
  }
 }
 if(spatial){const err=Spatial.validate(s);if(err)fail(err);}
 else if(keys.some(k=>k!=='root'&&!children.has(k)))fail('Unattached cubby');
 for(const v of s.caseItems)addRecord(v,false);
 if(!pathValid(s,s.path))fail('Invalid navigation path');
 const serialized=JSON.stringify(s);
 if(!serialized||serialized.length>limits.snapshotChars)fail('Snapshot size budget exceeded');
}

export function error(s){
 try{preflight(s,Spatial.enabled(s)?3:2);return null}catch(e){return String(e.message||e)}
}
