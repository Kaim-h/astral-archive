// Astral Archive native B6-N1. DOM-free port of B6r12b3 at f2e78523897d13ef518209eb2f9ef60e1cad12a4.
// Historical HTML is the behavioral reference; this ES module is the shared
// implementation for Node, Qt Quick and the Qt WorkerScript planner.
// Only plain JSON records cross the model/worker boundary; no QObjects,
// filesystem paths, browser globals, persistence or production shell wiring.
import * as Mixed from "./representation/B7Ownership.mjs";
import * as Capacity from "./ArchiveCapacity.mjs";
import * as Spatial from "./ArchiveSpatial.mjs";
const RACK_PAD=11, B6_WALL=3.2;
const clamp=(x,a,b)=>Math.max(a,Math.min(b,x));
export const FIXED_STEP=1/120;
export const MIN_RECOMMENDED_RADIUS=60;
export function clone(value){return JSON.parse(JSON.stringify(value));}

function cellName(row,col){return row+':'+col;}

function cellPoly(cx,cy,r){const out=[];for(let i=0;i<6;i++){const a=Math.PI/6+i*Math.PI/3;out.push({x:cx+Math.cos(a)*r,y:cy+Math.sin(a)*r});}return out;}

function clipPolygon(poly,x0,y0,x1,y1){
  const edges=[{inside:p=>p.x>=x0-1e-7,hit:(a,b)=>({x:x0,y:a.y+(b.y-a.y)*(x0-a.x)/(b.x-a.x)})},
    {inside:p=>p.x<=x1+1e-7,hit:(a,b)=>({x:x1,y:a.y+(b.y-a.y)*(x1-a.x)/(b.x-a.x)})},
    {inside:p=>p.y>=y0-1e-7,hit:(a,b)=>({x:a.x+(b.x-a.x)*(y0-a.y)/(b.y-a.y),y:y0})},
    {inside:p=>p.y<=y1+1e-7,hit:(a,b)=>({x:a.x+(b.x-a.x)*(y1-a.y)/(b.y-a.y),y:y1})}];
  let out=poly;
  for(const e of edges){const src=out;out=[];if(!src.length)break;let a=src[src.length-1];
    for(const b of src){const ai=e.inside(a),bi=e.inside(b);if(ai!==bi)out.push(e.hit(a,b));if(bi)out.push(b);a=b;}}
  return out;
}

function areaPoly(poly){let a=0;for(let j=0;j<poly.length;j++){const p=poly[j],q=poly[(j+1)%poly.length];a+=p.x*q.y-q.x*p.y;}return Math.abs(a)/2;}

function latticeForBox(box,r){
 const {x,y,w,h}=box;
 if(![x,y,w,h,r].every(Number.isFinite)||w<=0||h<=0||r<4||r>120||w>2400||h>2400)
  return [];
 const sx=Math.sqrt(3)*r,sy=1.5*r;
 const rows=Math.ceil(h/sy)+7,cols=Math.ceil(w/sx)+7;
 if(!Number.isSafeInteger(rows)||!Number.isSafeInteger(cols)||rows>260||cols>260||rows*cols>2000)return [];
 const cells=[];
 for(let row=-3;row<rows-3;row++){
  const off=(row%2===0?0:.5)*sx;
  for(let col=-3;col<cols-3;col++){
   const cx=x+off+col*sx+r,cy=y+row*sy+r;
   const poly=clipPolygon(cellPoly(cx,cy,r),x,y,x+w,y+h);
   if(poly.length<3||areaPoly(poly)<.2)continue;
   cells.push({key:cellName(row,col),row,col,cx,cy,r,poly,area:areaPoly(poly)});
  }
 }
 return cells;
}

function insetConvex(poly,thickness){
 let output=poly.map(p=>Object.assign({},p));
 for(let i=0;i<poly.length;i++){
  const a=poly[i],b=poly[(i+1)%poly.length],dx=b.x-a.x,dy=b.y-a.y,len=Math.hypot(dx,dy)||1,nx=-dy/len,ny=dx/len;
  const distance=p=>(p.x-a.x)*nx+(p.y-a.y)*ny-thickness;
  const input=output;output=[];if(!input.length)break;
  let prev=input[input.length-1],d0=distance(prev);
  for(const cur of input){const d1=distance(cur);
   if((d0<0&&d1>=0)||(d0>=0&&d1<0)){
    const t=d0/(d0-d1);output.push({x:prev.x+(cur.x-prev.x)*t,y:prev.y+(cur.y-prev.y)*t});
   }
   if(d1>=-1e-8)output.push(cur);
   prev=cur;d0=d1;
  }
 }
 return output.length>=3&&areaPoly(output)>.1?output:[];
}

function geomForRack(m){
 if((m.shape||'hex')!=='hex')return{box:{x:0,y:0,w:0,h:0},cells:[],unsupportedShape:m.shape};
 const box={x:RACK_PAD,y:RACK_PAD,w:Number(m.w)-2*RACK_PAD,h:Number(m.h)-2*RACK_PAD};
 if(!Number.isFinite(Number(m.r))||!Number.isFinite(box.w)||!Number.isFinite(box.h)||box.w<=0||box.h<=0)
  return {box,cells:[]};
 return {box,cells:latticeForBox(box,Number(m.r)).map(c=>Object.assign({},c,{innerPoly:insetConvex(c.poly,B6_WALL)}))};
}

function wallPoly(c){return c.innerPoly&&c.innerPoly.length>=3?c.innerPoly:c.poly;}

function interiorDistance(pt,poly){let min=Infinity;
 for(let i=0;i<poly.length;i++){
  const a=poly[i],b=poly[(i+1)%poly.length],dx=b.x-a.x,dy=b.y-a.y,len=Math.hypot(dx,dy)||1;
  min=Math.min(min,((pt.x-a.x)*-dy+(pt.y-a.y)*dx)/len);
 }return min;
}

function projectIntoCell(poly,pt,r){
 const p={x:pt.x,y:pt.y};for(let iter=0;iter<25;iter++){let max=0;
  for(let i=0;i<poly.length;i++){const a=poly[i],b=poly[(i+1)%poly.length],dx=b.x-a.x,dy=b.y-a.y,len=Math.hypot(dx,dy)||1,
    nx=-dy/len,ny=dx/len,delta=r+.2-((p.x-a.x)*nx+(p.y-a.y)*ny);
   if(delta>0){p.x+=nx*delta;p.y+=ny*delta;max=Math.max(max,delta);}}
  if(max<.001)break;
 }
 return interiorDistance(p,poly)>=r-.08?p:null;
}

function findCellAt(m,pt){return geomForRack(m).cells.find(cell=>interiorDistance(pt,cell.poly)>=-1e-6)||null;}

function scrollFit(cell,arr,x,y,r,clear=.24){return interiorDistance({x,y},wallPoly(cell))>=r+clear&&arr.every(s=>Math.hypot(x-s.x,y-s.y)>=r+s.r+clear);}

function staticScrollSpot(cell,arr,r,seed){const spots=[{x:cell.cx,y:cell.cy}];
 for(let rr=4;rr<=cell.r*1.2;rr+=4)for(let k=0;k<28;k++){const a=2*Math.PI*(k/28+seed*.13);spots.push({x:cell.cx+rr*Math.cos(a),y:cell.cy+rr*Math.sin(a)});}
 const viable=spots.filter(v=>scrollFit(cell,arr,v.x,v.y,r));
 // Gravity bias: choose the lower resting location to make a quiet, already packed pile.
 viable.sort((a,b)=>b.y-a.y||Math.abs(a.x-cell.cx)-Math.abs(b.x-cell.cx));return viable[0]||null;
}

function hashStr(st){let h=2166136261;for(let i=0;i<st.length;i++)h=Math.imul(h^st.charCodeAt(i),16777619);return h>>>0;}

function seeded01(st){return hashStr(st)/4294967296;}

function parseReflowNumbers(values){
 if(!values||!['x','y','w','h','r'].every(k=>typeof values[k]==='number'&&Number.isFinite(values[k])))return 'Enter finite numbers in every field.';
 if(values.w<180||values.w>1800||values.h<160||values.h>1500||values.r<38||values.r>76)return 'Width 180–1800, height 160–1500, radius 38–76 required.';
 if(values.w-2*RACK_PAD<values.r*.6||values.h-2*RACK_PAD<values.r*.6)return 'Rack is too narrow for this hex radius.';
 return null;
}

function b12bBodies(records){return records.map(s=>({s,vx:0,vy:0,inv:1/(s.r*s.r)}));}

function b12bEdges(cell){const p=wallPoly(cell);return p.map((a,i)=>{
 const b=p[(i+1)%p.length],dx=b.x-a.x,dy=b.y-a.y,L=Math.hypot(dx,dy)||1;
 return {x:a.x,y:a.y,nx:-dy/L,ny:dx/L};
});}

function b12bStep(cell,bodies,edges,tether=null){
 const dt=1/120,scale=cell.r/282,cap=305*scale,starts=bodies.map(b=>[b.s.x,b.s.y]);
 for(const b of bodies){
  const p=b.s;b.vy+=150*scale*dt;
  const target=tether instanceof Map?tether.get(p.id):tether&&tether.id===p.id?tether:null;
  if(target){b.vx+=(95*(target.x-p.x)-13*b.vx)*dt;b.vy+=(95*(target.y-p.y)-13*b.vy)*dt;}
  const damping=Math.exp(-2.1*dt);b.vx*=damping;b.vy*=damping;
  const limit=target?cap*3.5:cap;const speed=Math.hypot(b.vx,b.vy);if(speed>limit){b.vx*=limit/speed;b.vy*=limit/speed;}
  p.x+=b.vx*dt;p.y+=b.vy*dt;
 }
 for(let iter=0;iter<12;iter++){
  for(const b of bodies)for(const e of edges){
   const p=b.s,pen=p.r-(p.x-e.x)*e.nx-(p.y-e.y)*e.ny;
   if(pen<=0)continue;
   p.x+=pen*.96*e.nx;p.y+=pen*.96*e.ny;
   const vn=b.vx*e.nx+b.vy*e.ny;
   if(vn<0){
    const impulse=-(1+(vn<-24*scale ? .145 : 0))*vn;
    b.vx+=impulse*e.nx;b.vy+=impulse*e.ny;
    const tx=-e.ny,ty=e.nx,vt=b.vx*tx+b.vy*ty,f=clamp(vt,-.16*impulse,.16*impulse);
    b.vx-=f*tx;b.vy-=f*ty;
   }
  }
  for(let i=0;i<bodies.length;i++)for(let j=i+1;j<bodies.length;j++){
   const a=bodies[i],b=bodies[j],p=a.s,q=b.s,dx=q.x-p.x,dy=q.y-p.y,d=Math.hypot(dx,dy),sum=p.r+q.r;
   if(d>=sum)continue;
   const nx=d>1e-7?dx/d:1,ny=d>1e-7?dy/d:0,w=a.inv+b.inv,correction=Math.max(0,sum-d-.002)*.86/w;
   p.x-=nx*correction*a.inv;p.y-=ny*correction*a.inv;q.x+=nx*correction*b.inv;q.y+=ny*correction*b.inv;
   const vn=(b.vx-a.vx)*nx+(b.vy-a.vy)*ny;
   if(vn<0){
    const impulse=-(1+(vn<-20*scale ? .18 : 0))*vn/w;
    a.vx-=impulse*a.inv*nx;a.vy-=impulse*a.inv*ny;b.vx+=impulse*b.inv*nx;b.vy+=impulse*b.inv*ny;
    const tx=-ny,ty=nx,vt=(b.vx-a.vx)*tx+(b.vy-a.vy)*ty,fric=clamp(-vt/w,-.16*impulse,.16*impulse);
    a.vx-=fric*a.inv*tx;a.vy-=fric*a.inv*ty;b.vx+=fric*b.inv*tx;b.vy+=fric*b.inv*ty;
   }
  }
 }
 return bodies.reduce((max,b,i)=>Math.max(max,Math.hypot(b.s.x-starts[i][0],b.s.y-starts[i][1])),0);
}

function b12bContained(cell,records){
 const poly=wallPoly(cell);
 return records.every((s,i)=>Number.isFinite(s.x)&&Number.isFinite(s.y)&&Number.isFinite(s.r)&&s.r>0&&
  interiorDistance(s,poly)>=s.r-.12&&records.every((q,j)=>j<=i||Math.hypot(q.x-s.x,q.y-s.y)>=q.r+s.r-.12));
}

function b12bSupported(cell,records){
 const edges=b12bEdges(cell),grounded=new Set();
 for(const s of records)if(edges.some(e=>e.ny<-.08&&(s.x-e.x)*e.nx+(s.y-e.y)*e.ny<=s.r+.55))grounded.add(s.id);
 for(let i=0;i<records.length;i++)for(const s of records)if(!grounded.has(s.id)&&records.some(q=>grounded.has(q.id)&&q.y>=s.y+.02&&Math.hypot(q.x-s.x,q.y-s.y)<=q.r+s.r+.55))grounded.add(s.id);
 return grounded.size===records.length;
}

function b12bPack(cell,records,from,explicit=false){
 if(!records.length)return [];
 if(!cell||!from||records.length>96)return null;
 const run=arr=>{
  const bodies=b12bBodies(arr),edges=b12bEdges(cell);let quiet=0;
  for(let i=0;i<960;i++){
   const motion=b12bStep(cell,bodies,edges);quiet=motion<.035?quiet+1:0;
   if(i>=60&&quiet>=36&&b12bContained(cell,arr)&&b12bSupported(cell,arr))return arr;
  }
  return null;
 };
 const translated=[];
 for(const item of records){
  const p=projectIntoCell(wallPoly(cell),{x:item.x+cell.cx-from.cx,y:item.y+cell.cy-from.cy},item.r);
  if(!p)break;translated.push(Object.assign({},item,p,{cellKey:cell.key}));
 }
 if(translated.length===records.length){const result=run(translated);if(result)return result;}
 // Only explicitly directed overflow permits a new packing search.
 if(!explicit)return null;
 const packed=[];
 for(const item of records.slice().sort((a,b)=>b.r-a.r||a.id.localeCompare(b.id))){
  const p=staticScrollSpot(cell,packed,item.r,seeded01(item.id));if(!p)return null;
  packed.push(Object.assign({},item,p,{cellKey:cell.key}));
 }
 return run(packed);
}

// Recess is presentation-only; zero/absent is the existing reset/default.
function hasCellRecess(meta){return !!meta&&Number(meta.depth)>0;}
function hasCellCustomization(meta){return !!meta&&(!!meta.color||hasCellRecess(meta));}
function b12bPlan(m,p,decisions={}){
 const invalid=parseReflowNumbers(p);if(invalid)return{ok:false,reason:invalid};
 const old=geomForRack(m).cells,fresh=geomForRack(Object.assign({},m,p)).cells;
 if(!fresh.length||!old.length||fresh.length>1200)return{ok:false,reason:'Unsupported lattice or search budget.'};
 const identical=['w','h','r'].every(k=>m[k]===p[k]),unchanged=identical&&m.x===p.x&&m.y===p.y;
 if(identical)return{ok:true,unchanged,mapped:clone(m.scrollCells||{}),meta:clone(m.cellMeta||{}),review:[],caseOverflow:[],reason:unchanged?'Exact no-op.':'Only the rack position changes.'};
 const newByKey=new Map(fresh.map(c=>[c.key,c])),oldByKey=new Map(old.map(c=>[c.key,c]));
 const groups=Object.entries(m.scrollCells||{}).filter(([,v])=>v.length);
 const reserved=new Set(groups.map(([key])=>key)),customized=new Set(Object.entries(m.cellMeta||{}).filter(([,v])=>hasCellCustomization(v)).map(([k])=>k));
 const eligible=fresh.filter(c=>!reserved.has(c.key)&&!customized.has(c.key)&&wallPoly(c).length>=3).map(c=>c.key);
 const mapped={},meta={},review=[],caseOverflow=[],used=new Map();let seq=0,blocked=false;
 const newId=()=>('~new-'+(++seq));
 for(const cell of fresh)meta[cell.key]=clone((m.cellMeta&&m.cellMeta[cell.key])||{id:newId(),color:null});
 for(const [key,records] of groups){
  const from=oldByKey.get(key),cell=newByKey.get(key),source=m.cellMeta&&m.cellMeta[key];
  if(!from||!source||!source.id)return{ok:false,reason:'Missing original cell identity or geometry.'};
  const byDest=new Map(),kept=[];let reason='';
  for(const item of records){
   const dest=decisions[item.id]||'';
   if(!dest){kept.push(item);continue;}
   if(dest!=='case'&&!eligible.includes(dest)){reason=hasCellRecess((m.cellMeta||{})[dest])?'Choose an empty destination without pigment or recess customization.':'Choose an empty unpainted destination other than the original populated cell.';continue;}
   if(!byDest.has(dest))byDest.set(dest,[]);byDest.get(dest).push(item);
  }
  const packed=kept.length?b12bPack(cell,kept,from):[];
  if(!packed)reason=cell?'The original cell did not settle with the retained scrolls. Choose exactly which should leave.':'The original lattice address disappeared; choose destinations for its scrolls.';
  else if(packed.length)mapped[key]=packed;
  const destinations=Array.from(byDest.keys()).filter(k=>k!=='case');
  const home=!cell?(destinations.length===1?destinations[0]:decisions['home:'+source.id]):null;
  if(!cell&&destinations.length>1&&!destinations.includes(home))reason='Choose which destination inherits the displaced original cell identity.';
  for(const [dest,list] of byDest){
   if(dest==='case'){
    for(const item of list)caseOverflow.push(Object.assign({},item,{originRackId:m.id,originKey:key,originCellId:source.id,originStale:!cell,moveMode:'cut'}));
    continue;
   }
   if(used.has(dest)){reason='Destination '+dest+' is already assigned to another original group.';continue;}
   used.set(dest,key);
   const placed=b12bPack(newByKey.get(dest),list,from,true);
   if(!placed){reason='The selected scrolls could not settle in '+dest+' within the search budget.';continue;}
   mapped[dest]=placed;
   meta[dest]=dest===home?clone(source):Object.assign(clone(source),{id:newId(),splitFromId:source.id,lineage:(source.lineage||[]).concat([source.id])});
  }
  if(reason)blocked=true;
  if(reason||byDest.size)review.push({type:'group',key,cellId:source.id,records:records.map(s=>({id:s.id,name:s.name,r:s.r})),options:eligible,reason:reason||'Ready for explicit Apply.',homeOptions:!cell&&destinations.length>1?destinations:[]});
 }
 for(const [key,value] of Object.entries(m.cellMeta||{}))if(hasCellCustomization(value)&&!newByKey.has(key)&&!reserved.has(key)){
  const options=eligible.filter(k=>!used.has(k)),choice=decisions['paint:'+value.id];
  // Keep the existing paint decision protocol and historical pigment-only plan messages.
  const recess=hasCellRecess(value);
  if(choice==='discard')review.push({type:'paint',key,cellId:value.id,options,reason:recess?'Cell customization removal explicitly selected.':'Paint removal explicitly selected.'});
  else if(options.includes(choice)){meta[choice]=clone(value);used.set(choice,key);review.push({type:'paint',key,cellId:value.id,options,reason:recess?'Cell customization relocation ready.':'Paint relocation ready.'});}
  else {blocked=true;review.push({type:'paint',key,cellId:value.id,options,reason:recess?'Customized empty cell disappears; choose a destination or explicitly discard its pigment/recess.':'Painted empty cell disappears; choose a destination or explicitly discard its paint.'});}
 }
 return{ok:!blocked,needsAttention:blocked,unchanged:false,mapped,meta,review,caseOverflow,
  reason:blocked?'Resolve marked cells; no committed records have changed.':'Ready: original lattice addresses retained wherever possible.'};
}

function b12dGroupPoints(cell,existing,items,loc,offsets){
 // Prefer the dragged formation, translated as one unit. If a formation
 // spans source cells or cannot fit, try a bounded compact arrangement
 // centered on the actual drop point, never another destination cell.
 const poly=wallPoly(cell),anchor=loc.local;
 if(!anchor||!Number.isFinite(anchor.x)||!Number.isFinite(anchor.y)||!items.length)return null;
 const formation=items.map(item=>{const off=offsets&&offsets.get(item.id);return {item,x:anchor.x+(off?off.x:0),y:anchor.y+(off?off.y:0)};});
 const fit=(p,others)=>interiorDistance(p,poly)>=p.item.r+.10&&others.every(q=>Math.hypot(p.x-q.x,p.y-q.y)>=p.item.r+q.item.r+.10);
 if(formation.every((p,i)=>fit(p,formation.slice(0,i))))return formation;
 // A centered pair can fit even when greedy placement of one body at the
 // exact anchor blocks its partner. Test symmetric orientations first.
 if(items.length===2){
  const distance=(items[0].r+items[1].r+.24)/2;
  for(let i=0;i<24;i++){
   const angle=i*Math.PI/12,dx=distance*Math.cos(angle),dy=distance*Math.sin(angle);
   const pair=[{item:items[0],x:anchor.x-dx,y:anchor.y-dy},{item:items[1],x:anchor.x+dx,y:anchor.y+dy}];
   if(fit(pair[0],[])&&fit(pair[1],[pair[0]]))return pair;
  }
 }
 const placed=[],limit=Math.min(cell.r*.78,Math.max(18,items.reduce((sum,item)=>sum+item.r*item.r,0)**.5*2.1));
 const ordered=items.slice().sort((a,b)=>b.r-a.r||a.id.localeCompare(b.id));
 for(const item of ordered){
  const desired=offsets&&offsets.get(item.id),candidates=[{x:anchor.x+(desired?desired.x:0),y:anchor.y+(desired?desired.y:0)},Object.assign({},anchor)];
  for(let radius=3;radius<=limit;radius+=3){
   const n=Math.max(12,Math.ceil(2*Math.PI*radius/4));
   for(let i=0;i<n;i++){const a=2*Math.PI*i/n;candidates.push({x:anchor.x+radius*Math.cos(a),y:anchor.y+radius*Math.sin(a)});}
  }
  const candidate=candidates.map(p=>Object.assign({},p,{item})).filter(p=>fit(p,placed)&&Math.hypot(p.x-anchor.x,p.y-anchor.y)<=limit)
   .sort((a,b)=>{
    const score=p=>Math.hypot(p.x-anchor.x,p.y-anchor.y)+existing.reduce((sum,q)=>sum+Math.max(0,item.r+q.r-Math.hypot(p.x-q.x,p.y-q.y))*4,0);
    return score(a)-score(b);
   })[0];
  if(!candidate)return null;placed.push(candidate);
 }
 return placed;
}

function b12bTraceVoid(region,labels,nx,ny,x0,y0,VOID_STEP){
 const edgeList=[],adj=new Map();
 function push(ax,ay,bx,by){const k=ax+','+ay,idx=edgeList.length;edgeList.push({ax,ay,bx,by,used:false});if(!adj.has(k))adj.set(k,[]);adj.get(k).push(idx);}
 for(const k of region.pixels){const x=k%nx,y=Math.floor(k/nx);
  if(y===0||labels[k-nx]!==region.id)push(x,y,x+1,y);
  if(x===nx-1||labels[k+1]!==region.id)push(x+1,y,x+1,y+1);
  if(y===ny-1||labels[k+nx]!==region.id)push(x+1,y+1,x,y+1);
  if(x===0||labels[k-1]!==region.id)push(x,y+1,x,y);
 }
 const loops=[];
 for(let i=0;i<edgeList.length;i++){
  if(edgeList[i].used)continue;
  const loop=[],start=edgeList[i].ax+','+edgeList[i].ay;let idx=i,guard=0;
  while(idx!==undefined&&guard++<edgeList.length+2){const e=edgeList[idx];if(e.used)break;e.used=true;loop.push({x:e.ax,y:e.ay});
   const key=e.bx+','+e.by;if(key===start)break;idx=(adj.get(key)||[]).find(n=>!edgeList[n].used);}
  if(loop.length>=3)loops.push(loop);
 }
 const point=p=>({x:x0+p.x*VOID_STEP,y:y0+p.y*VOID_STEP});
 const fmt=p=>p.x.toFixed(2)+' '+p.y.toFixed(2);
 let path='';for(const raw of loops){const cleaned=[];
  for(let j=0;j<raw.length;j++){const a=raw[(j+raw.length-1)%raw.length],b=raw[j],c=raw[(j+1)%raw.length];
   if((b.x-a.x)*(c.y-b.y)-(b.y-a.y)*(c.x-b.x)!==0)cleaned.push(point(b));}
  if(cleaned.length<3)continue;
  const mid=(a,b)=>({x:(a.x+b.x)/2,y:(a.y+b.y)/2});
  path+='M'+fmt(mid(cleaned[cleaned.length-1],cleaned[0]));for(let j=0;j<cleaned.length;j++)path+='Q'+fmt(cleaned[j])+' '+fmt(mid(cleaned[j],cleaned[(j+1)%cleaned.length]));path+='Z';
 }return path;
}

function b12bVoidAtlas(cell,records){
 const poly=wallPoly(cell),edges=b12bEdges(cell),VOID_STEP=Math.max(1,cell.r/94);
 const x0=Math.min.apply(null,poly.map(p=>p.x)),x1=Math.max.apply(null,poly.map(p=>p.x)),y0=Math.min.apply(null,poly.map(p=>p.y)),y1=Math.max.apply(null,poly.map(p=>p.y));
 const nx=Math.ceil((x1-x0)/VOID_STEP),ny=Math.ceil((y1-y0)/VOID_STEP),n=nx*ny;
 const clear=new Float32Array(n),labels=new Int32Array(n);labels.fill(-1);
 const bodies=records;
 for(let y=0;y<ny;y++)for(let x=0;x<nx;x++){
  const k=y*nx+x,px=x0+(x+.5)*VOID_STEP,py=y0+(y+.5)*VOID_STEP;
  let d=Infinity;
  for(const e of edges)d=Math.min(d,(px-e.x)*e.nx+(py-e.y)*e.ny);
  if(d<=0){clear[k]=d;continue;}
  for(const b of bodies)d=Math.min(d,Math.hypot(px-b.x,py-b.y)-b.r);
  clear[k]=d;
 }
 const adj=k=>{const x=k%nx,y=Math.floor(k/nx),out=[];
  if(x>0)out.push(k-1);if(x<nx-1)out.push(k+1);
  if(y>0)out.push(k-nx);if(y<ny-1)out.push(k+nx);return out;};
 const cores=[],seen=new Uint8Array(n),threshold=Math.max(.7,cell.r*3.5/282);
 for(let k=0;k<n;k++){
  if(clear[k]<=threshold||seen[k])continue;
  const queue=[k],pixels=[];seen[k]=1;let peak=k;
  for(let qi=0;qi<queue.length;qi++){
   const z=queue[qi];pixels.push(z);if(clear[z]>clear[peak])peak=z;
   for(const zz of adj(z))if(!seen[zz]&&clear[zz]>threshold){seen[zz]=1;queue.push(zz);}
  }
  if(pixels.length>=2)cores.push({peak,pixels});
 }
 const regions=[],queue=[];
 function add(group){const id=regions.length;let pk=group.peak;
  const r={id,peak:pk,pixels:[],area:0,path:'',x:x0+((pk%nx)+.5)*VOID_STEP,y:y0+(Math.floor(pk/nx)+.5)*VOID_STEP,maxClear:clear[pk]};
  regions.push(r);for(const k of group.pixels){labels[k]=id;r.pixels.push(k);queue.push(k);}
 }
 cores.forEach(add);
 if(!regions.length){let pk=-1;for(let k=0;k<n;k++)if(clear[k]>.10&&(pk<0||clear[k]>clear[pk]))pk=k;
  if(pk>=0)add({peak:pk,pixels:[pk]});}
 for(let qi=0;qi<queue.length;qi++){
  const z=queue[qi],id=labels[z];for(const zz of adj(z))if(clear[zz]>.10&&labels[zz]<0){labels[zz]=id;regions[id].pixels.push(zz);queue.push(zz);}
 }
 for(let k=0;k<n;k++)if(clear[k]>.10&&labels[k]<0){
  const q=[k],pixels=[];labels[k]=-2;
  for(let qi=0;qi<q.length;qi++){const z=q[qi];pixels.push(z);
   for(const zz of adj(z))if(clear[zz]>.10&&labels[zz]===-1){labels[zz]=-2;q.push(zz);}}
  add({peak:k,pixels});
 }
 for(const r of regions){r.area=r.pixels.length*VOID_STEP**2;r.path=b12bTraceVoid(r,labels,nx,ny,x0,y0,VOID_STEP);}
 return {regions,labels,clear,x0,y0,nx,ny,step:VOID_STEP};
}

function b12bRegionAt(atlas,pt){
 if(!atlas||!pt)return null;
 const x=Math.floor((pt.x-atlas.x0)/atlas.step),y=Math.floor((pt.y-atlas.y0)/atlas.step);
 if(x<0||x>=atlas.nx||y<0||y>=atlas.ny)return null;
 return atlas.regions[atlas.labels[y*atlas.nx+x]]||null;
}

function b12bTopEntrance(cell,records,r){
 const edges=b12bEdges(cell),poly=wallPoly(cell);
 const xmin=Math.min.apply(null,poly.map(p=>p.x)),xmax=Math.max.apply(null,poly.map(p=>p.x)),candidates=[];
 const radius=r+.24;
 for(let x=xmin+r;x<=xmax-r;x+=1){
  let lo=-Infinity,hi=Infinity,valid=true;
  for(const e of edges){
   const rhs=radius-(x-e.x)*e.nx;
   if(e.ny>1e-7)lo=Math.max(lo,e.y+rhs/e.ny);
   else if(e.ny<-1e-7)hi=Math.min(hi,e.y+rhs/e.ny);
   else if(rhs>0){valid=false;break;}
  }
  if(valid&&Number.isFinite(lo)&&lo<=hi)candidates.push({x,y:lo});
 }
 const top=Math.min.apply(null,candidates.map(p=>p.y));
 return candidates.filter(p=>p.y<=top+Math.max(2,r*.35)&&scrollFit(cell,records,p.x,p.y,r,.15))
  .sort((a,b)=>Math.abs(a.x-cell.cx)-Math.abs(b.x-cell.cx)||a.y-b.y)[0]||null;
}

function b12ePreviewGeometry(m,d){
 // Pure, bounded render geometry. Invalid numeric edits keep the most
 // recent drawable shape, never the original rack just because planning
 // has not completed. A dimensionally valid overlap remains a red draft.
 const dims=parseReflowNumbers(d.proposed)?d.drawable||{x:m.x,y:m.y,w:m.w,h:m.h,r:m.r}:d.proposed;
 const rack=Object.assign({},m,dims,{cellMeta:{},scrollCells:{}});
 const cells=geomForRack(rack).cells;
 return {rack,cells,byKey:new Map(cells.map(c=>[c.key,c]))};
}

function b12ePendingRecords(m,rack,byKey,desired){
 // Fast visual translation only. Never pack, simulate, or allocate IDs in
 // this path. If the original group cannot be displayed without clipping
 // or overlap, leave it explicitly awaiting the authoritative planner.
 const old=new Map(geomForRack(m).cells.map(c=>[c.key,c])),mapped={};
 for(const [key,items] of Object.entries(m.scrollCells||{})){
  const cell=byKey.get(key),from=old.get(key),kept=items.filter(s=>desired.get(s.id)===key);
  if(!cell||!from||!kept.length)continue;
  const shifted=kept.map(item=>Object.assign({},item,{x:item.x+cell.cx-from.cx,y:item.y+cell.cy-from.cy,cellKey:key}));
  if(b12bContained(cell,shifted))mapped[key]=shifted;
 }
 return mapped;
}

export {
 geomForRack as geometry, wallPoly as wall, interiorDistance, projectIntoCell,
 findCellAt as cellAt, scrollFit, staticScrollSpot, parseReflowNumbers as dimensionError,
 b12bBodies as bodies, b12bEdges as edges, b12bStep as step,
 b12bContained as contained, b12bSupported as supported, b12bPack as pack,
 b12bPlan as plan, b12dGroupPoints as groupPoints, b12bVoidAtlas as voidAtlas,
 b12bRegionAt as regionAt, b12bTopEntrance as topEntrance
};

// Pure value model. A cubby/rack/cell is a placement, never a disk directory.
export function rackAt(snapshot,cubbyId,rackId){
 const c=Object.prototype.hasOwnProperty.call(snapshot.cubbies,cubbyId)?snapshot.cubbies[cubbyId]:null;
 return c&&Array.isArray(c.mods) ? c.mods.find(m=>m.id===rackId&&m.type==='rack')||null : null;
}
export function owners(snapshot){
 const entries=[];
 for(const c of Object.values(snapshot.cubbies))for(const m of c.mods){
  if(m.type==='rack'){
   for(const [key,records] of Object.entries(m.scrollCells||{}))for(const scroll of records)
    entries.push({id:scroll.id,where:'rack',cubbyId:c.id,rackId:m.id,key,scroll});
  }
  entries.push(...Mixed.owners(c.id,m));
 }
 for(const scroll of snapshot.caseItems)entries.push({id:scroll.id,where:'case',scroll});
 return entries;
}
function allIds(snapshot){return owners(snapshot).map(e=>e.id).sort();}
function sameIds(a,b){return JSON.stringify(allIds(a))===JSON.stringify(allIds(b));}
function positiveRadius(s){return !!s&&typeof s.id==='string'&&!!s.id&&Number.isFinite(s.r)&&s.r>0;}
function rackBounds(c,m){
 // Board-only bounds are insufficient for occupied shelves. Keep existing
 // rack/nested geometry unchanged, and include the B7 occupied rectangles.
 try{
  const boxes=Mixed.fixtureRects(m);
  if(boxes.some(b=>b.x<-.001||b.y<-.001||b.x+b.w>c.w+.001||b.y+b.h>c.h+.001))return false;
  return !c.mods.some(q=>q.id!==m.id&&Mixed.fixtureRects(q).some(b=>boxes.some(a=>Mixed.overlap(a,b))));
 }catch(e){return false;}
}
export function validate(snapshot){
 const budget=Capacity.error(snapshot);if(budget)return budget;
 if(!snapshot||!snapshot.cubbies||!Array.isArray(snapshot.caseItems)||!Array.isArray(snapshot.path)||
  !snapshot.path.length||!Number.isSafeInteger(snapshot.next)||snapshot.next<1||
  snapshot.path.some(id=>!snapshot.cubbies[id]))return 'Invalid snapshot';
 const materialError=validateMaterials(snapshot.materials);if(materialError)return materialError;
 const ids=new Set(),cellsSeen=new Set(),modules=new Set(),parents=new Map();
 for(const [cubbyId,c] of Object.entries(snapshot.cubbies)){
  if(c.id!==cubbyId||!Array.isArray(c.mods)||!Number.isFinite(c.w)||!Number.isFinite(c.h)||c.w<=0||c.h<=0)return 'Invalid cubby';
  for(const m of c.mods){
   if(typeof m.id!=='string'||!m.id||modules.has(m.id))return 'Duplicate module identity';
   modules.add(m.id);
   // All eligible surfaces share the same B7 contact envelopes and owners;
   // rack cell records are still validated independently below.
   try{
    if(Mixed.supportsTop(m)){
     Mixed.validateShelf(m);
     for(const entry of m.items||[])if(entry.kind==='holder'){
      if(modules.has(entry.id))return 'Duplicate fixture identity';modules.add(entry.id);
     }
    }
    for(const e of Mixed.owners(cubbyId,m)){if(ids.has(e.id))return 'Duplicate file identity';ids.add(e.id);}
   }catch(e){return String(e.message||e);}
   if(m.type==='cubby'){
    if(![m.x,m.y,m.w,m.h].every(Number.isFinite)||m.w<130||m.h<100||!rackBounds(c,m))return 'Invalid nested cubby footprint';
    if(typeof m.childId!=='string'||!snapshot.cubbies[m.childId]||parents.has(m.childId)||m.childId===cubbyId)return 'Invalid or multiply parented cubby';
    parents.set(m.childId,cubbyId);continue;
   }
   if(m.type==='shelf'){
    if(![m.x,m.y,m.w,m.h].every(Number.isFinite)||m.w<120||m.h!==15||!rackBounds(c,m))return 'Invalid shelf board geometry';
    continue;
   }
   if(m.type==='artwork'){
    try{Mixed.validateMount(m);if(!rackBounds(c,m))return 'Invalid mounted artwork footprint';
    }catch(e){return String(e.message||e);}
    continue;
   }
   if(m.type!=='rack')return 'Unsupported fixture';
   if(parseReflowNumbers(m)||!rackBounds(c,m)||(m.shape||'hex')!=='hex')return 'Invalid rack geometry';
   const cells=new Map(geomForRack(m).cells.map(c=>[c.key,c]));
   if(!cells.size)return 'Empty lattice';
   for(const key of cells.keys()){
    const meta=(m.cellMeta||{})[key];
    if(!meta||typeof meta.id!=='string'||!meta.id||meta.id.indexOf('~')===0||cellsSeen.has(meta.id))return 'Invalid or duplicate cell identity';
    cellsSeen.add(meta.id);
   }
   if(Object.keys(m.cellMeta||{}).length!==cells.size)return 'Stale cell metadata';
   for(const [key,list] of Object.entries(m.scrollCells||{})){
    if(!cells.has(key)||!Array.isArray(list))return 'Invalid cell records';
    if(list.length>96||!list.every(s=>positiveRadius(s)&&s.cellKey===key)||!b12bContained(cells.get(key),list))return 'Invalid scroll geometry';
    for(const item of list){if(ids.has(item.id))return 'Duplicate scroll identity';const error=Mixed.portableError(item);if(error)return error;ids.add(item.id);}
   }
  }
 }
 for(const id of Object.keys(snapshot.cubbies)){
  const seen=new Set();let cursor=id;
  while(parents.has(cursor)){if(seen.has(cursor))return 'Cyclic cubby hierarchy';seen.add(cursor);cursor=parents.get(cursor);}
 }
 for(let i=1;i<snapshot.path.length;i++)if(parents.get(snapshot.path[i])!==snapshot.path[i-1])return 'Invalid cubby path';
 for(const item of snapshot.caseItems){if(!positiveRadius(item)||ids.has(item.id))return 'Invalid or duplicate Case record';const error=Mixed.portableError(item);if(error)return error;ids.add(item.id);}
 return null;
}

export function session(snapshot){
 const error=validate(snapshot);if(error)throw Error(error);
 return {snapshot:clone(snapshot),history:[],revision:0,draft:null,error:''};
}
function updateSession(s,patch){return Object.assign({},s,patch);}
export function cancel(s){return updateSession(s,{draft:null,revision:s.revision+1,error:''});}
export function stage(s,cubbyId,rackId,patch,decisions){
 const m=rackAt(s.snapshot,cubbyId,rackId);
 if(!m)return updateSession(s,{error:'Rack does not exist'});
 const prev=s.draft&&s.draft.cubbyId===cubbyId&&s.draft.rackId===rackId?s.draft:null;
 const base=prev?prev.proposed:{x:m.x,y:m.y,w:m.w,h:m.h,r:m.r};
 const proposed=Object.assign({},base);
 for(const k of ['x','y','w','h','r'])if(Object.prototype.hasOwnProperty.call(patch,k))proposed[k]=patch[k];
 const shapeChanged=!prev||['w','h','r'].some(k=>base[k]!==proposed[k]);
 const numericError=parseReflowNumbers(proposed);
 const invalid=numericError||(!rackBounds(s.snapshot.cubbies[cubbyId],Object.assign({},m,proposed))?'Rack overlaps or exceeds cubby':null);
 const revision=s.revision+1;
 const draft={revision,cubbyId,rackId,proposed,drawable:numericError?(prev?prev.drawable:{x:m.x,y:m.y,w:m.w,h:m.h,r:m.r}):clone(proposed),
  decisions:clone(decisions!==undefined?decisions:shapeChanged?{}:prev.decisions),approved:!shapeChanged&&prev?prev.approved:false,
  phase:invalid?'invalid':'pending',result:null,reason:invalid||''};
 return updateSession(s,{revision,draft,error:''});
}
export function approveRadius(s,approved){
 return s.draft?updateSession(s,{draft:Object.assign({},s.draft,{approved:!!approved})}):s;
}
export function needsRadiusApproval(s){
 const d=s.draft;if(!d)return false;
 const m=rackAt(s.snapshot,d.cubbyId,d.rackId);
 return d.proposed.r<MIN_RECOMMENDED_RADIUS&&d.proposed.r!==m.r&&!d.approved;
}
export function request(s){
 const d=s.draft;if(!d||d.phase!=='pending')return null;
 return clone({revision:d.revision,rack:rackAt(s.snapshot,d.cubbyId,d.rackId),proposed:d.proposed,decisions:d.decisions});
}
export function solve(message){
 try{return {revision:message.revision,result:b12bPlan(message.rack,message.proposed,message.decisions)};}
 catch(error){return {revision:message.revision,result:{ok:false,reason:String(error)}};}
}
export function accept(s,message){
 const d=s.draft;
 if(!d||d.phase!=='pending'||message.revision!==d.revision)return s;
 const r=message.result||{ok:false,reason:'Planner returned no result'};
 return updateSession(s,{draft:Object.assign({},d,{result:clone(r),phase:r.ok?'ready':r.needsAttention?'attention':'invalid',reason:r.reason||''})});
}
export function projection(s){
 const d=s.draft;if(!d)return null;
 const m=rackAt(s.snapshot,d.cubbyId,d.rackId),{rack,cells,byKey}=b12ePreviewGeometry(m,d);
 const result=d.result&&d.result.mapped?d.result:null;
 const source=[];for(const [key,list] of Object.entries(m.scrollCells||{}))for(const item of list)source.push({key,item});
 const desired=new Map(source.map(e=>[e.item.id,d.decisions[e.item.id]||e.key])),seen=new Set(),caseOverflow=[];
 for(const c of cells)rack.cellMeta[c.key]=clone((result&&result.meta[c.key])||m.cellMeta[c.key]||{id:'~preview-'+m.id+'-'+c.key,color:null});
 for(const e of source)if(desired.get(e.item.id)==='case'){
  caseOverflow.push(Object.assign({},e.item,{originCubbyId:d.cubbyId,originRackId:m.id,originKey:e.key,originCellId:m.cellMeta[e.key].id,moveMode:'cut'}));seen.add(e.item.id);
 }
 const mapped=result?result.mapped:b12ePendingRecords(m,rack,byKey,desired);
 for(const [key,items] of Object.entries(mapped)){
  if(!byKey.has(key))continue;
  const kept=items.filter(item=>!seen.has(item.id)&&desired.get(item.id)===key);
  if(kept.length&&b12bContained(byKey.get(key),kept)){rack.scrollCells[key]=clone(kept);for(const item of kept)seen.add(item.id);}
 }
 return {rack,caseOverflow,unresolved:source.filter(e=>!seen.has(e.item.id)).map(e=>({key:e.key,id:e.item.id,destination:desired.get(e.item.id)}))};
}
function commit(s,next){
 const error=validate(next);
 if(error||!sameIds(s.snapshot,next))return updateSession(s,{error:error||'Ownership set changed'});
 return {snapshot:next,history:s.history.concat([s.snapshot]).slice(-30),revision:s.revision+1,draft:null,error:''};
}
export function apply(s){
 const d=s.draft;
 if(!d||d.phase!=='ready'||!d.result.ok||d.result.unchanged||needsRadiusApproval(s))return updateSession(s,{error:'No approved latest proposal'});
 const view=projection(s),r=d.result;
 if(view.unresolved.length||JSON.stringify(view.caseOverflow.map(e=>e.id).sort())!==JSON.stringify(r.caseOverflow.map(e=>e.id).sort()))return updateSession(s,{error:'Unresolved ownership'});
 const next=clone(s.snapshot),m=rackAt(next,d.cubbyId,d.rackId),used=new Set();
 for(const c of Object.values(next.cubbies))for(const rack of c.mods)for(const meta of Object.values(rack.cellMeta||{}))used.add(meta.id);
 const meta=clone(r.meta);
 for(const value of Object.values(meta))if(value.id.indexOf('~new-')===0){let id;do{id='hc'+next.next++;}while(used.has(id));value.id=id;used.add(id);}
 Object.assign(m,d.proposed,{cellMeta:meta,scrollCells:clone(r.mapped)});
 for(const item of r.caseOverflow){const record=Object.assign({},item,{originCubbyId:d.cubbyId});Mixed.clearMixedOrigin(record);next.caseItems.push(record);}
 for(const item of next.caseItems)if(item.originCubbyId===d.cubbyId&&item.originRackId===d.rackId){
  const key=Object.keys(meta).find(k=>meta[k].id===item.originCellId);item.originStale=!key;if(key)item.originKey=key;
 }
 return commit(s,next);
}
export function undo(s){
 if(s.draft||!s.history.length)return updateSession(s,{error:'No available Undo'});
 return {snapshot:s.history[s.history.length-1],history:s.history.slice(0,-1),revision:s.revision+1,draft:null,error:''};
}

// The live frame scheduler comes in N3. This bounded helper supports tests
// and explicit synthetic transfers; never run it on an interactive UI frame.
export function settle(cell,records){
 const copy=clone(records),bs=b12bBodies(copy),es=b12bEdges(cell);let quiet=0;
 if(!copy.length)return [];
 for(let i=0;i<960;i++){
  const motion=b12bStep(cell,bs,es);quiet=motion<.035?quiet+1:0;
  if(i>=60&&quiet>=36&&b12bContained(cell,copy)&&b12bSupported(cell,copy))return copy;
 }
 return null;
}
export function transfer(s,ids,destination){
 if(s.draft||!ids.length||new Set(ids).size!==ids.length)return updateSession(s,{error:'Invalid or busy transfer'});
 const next=clone(s.snapshot),affected=new Map(),carried=[];
 try{
  for(const id of ids){
   const e=owners(next).find(q=>q.id===id);if(!e)throw Error('Missing file '+id);
   if(destination!=='case'&&e.where!=='case'&&e.cubbyId!==destination.cubbyId)throw Error('Use the Scroll Case between cubbies');
   const item=clone(e.scroll);
   if(e.where==='case')next.caseItems=next.caseItems.filter(x=>x.id!==id);
   else if(e.where==='rack'){
    const rack=rackAt(next,e.cubbyId,e.rackId);
    rack.scrollCells[e.key]=rack.scrollCells[e.key].filter(x=>x.id!==id);
    Mixed.clearMixedOrigin(item);
    Object.assign(item,{originCubbyId:e.cubbyId,originRackId:e.rackId,originKey:e.key,originCellId:rack.cellMeta[e.key].id,originStale:false});
    affected.set([e.cubbyId,e.rackId,e.key].join('|'),e);
   }else Mixed.detach(next,e,item,false);
   carried.push(item);
  }
  if(destination==='case')for(const item of carried)next.caseItems.push(Object.assign({},item,{moveMode:'cut'}));
  else if(destination&&['shelf','holder','artwork'].includes(destination.kind)){
   if(carried.length!==1)throw Error('Choose one object for this placement');
   Mixed.place(next,carried[0],destination);
  }else{
   const rack=rackAt(next,destination.cubbyId,destination.rackId),cell=rack&&geomForRack(rack).cells.find(c=>c.key===destination.key);
   if(!cell)throw Error('No destination cell');
   const list=rack.scrollCells[cell.key]||[];
   if(list.length+carried.length>96)throw Error('Contact budget exceeded');
   const points=carried.length===1?
    (destination.local&&scrollFit(cell,[],destination.local.x,destination.local.y,carried[0].r,-.08)?[{item:carried[0],x:destination.local.x,y:destination.local.y}]:null):
    b12dGroupPoints(cell,list,carried,destination,null);
   if(!points)throw Error('No valid group placement near drop');
   rack.scrollCells[cell.key]=list.concat(points.map(p=>Object.assign({},p.item,{x:p.x,y:p.y,cellKey:cell.key})));
   affected.set([destination.cubbyId,destination.rackId,destination.key].join('|'),destination);
  }
  for(const e of affected.values()){
   const rack=rackAt(next,e.cubbyId,e.rackId),cell=geomForRack(rack).cells.find(c=>c.key===e.key),settled=settle(cell,rack.scrollCells[e.key]);
   if(!settled)throw Error('Bounded settling failed; group unchanged');rack.scrollCells[e.key]=settled;
  }
  if(JSON.stringify(next)===JSON.stringify(s.snapshot))return updateSession(s,{error:''});
  return commit(s,next);
 }catch(error){return updateSession(s,{error:String(error)});}
}

// Shared reproducible synthetic fixture: three radius-23 scrolls in a
// radius-75 cell; a radius-38 shrink requires explicit destinations.
export function fixture(){
 const m={id:'rack-1',type:'rack',shape:'hex',x:0,y:0,w:500,h:400,r:75,color:null,scrollCells:{},cellMeta:{}};
 let next=1;for(const c of geomForRack(m).cells)m.cellMeta[c.key]={id:'hc'+next++,color:null};
 const cell=geomForRack(m).cells.find(c=>c.key==='1:1');m.cellMeta[cell.key].color='#796a92';
 m.scrollCells[cell.key]=[
  {id:'test-a',name:'alpha.md',r:23,x:cell.cx-25,y:cell.cy-15,cellKey:cell.key},
  {id:'test-b',name:'beta.md',r:23,x:cell.cx+25,y:cell.cy-15,cellKey:cell.key},
  {id:'test-c',name:'gamma.md',r:23,x:cell.cx,y:cell.cy+30,cellKey:cell.key}];
 return {cubbies:{root:{id:'root',w:700,h:500,mods:[m]}},caseItems:[],next,path:['root']};
}

// Publish only a completed, revision-matched motion draft. The motion module
// owns the provisional records; this remains the sole commit boundary.
export function commitMotion(s,q){
 if(!q||s.draft||q.baseRevision!==s.revision||!q.released||q.cells.size||q.carried.length||q.error)
  return updateSession(s,{error:'Motion is incomplete or stale'});
 if(JSON.stringify(s.snapshot)===JSON.stringify(q.draft))return updateSession(s,{error:''});
 return commit(s,clone(q.draft));
}

// Explicit visual cell paint/depth edit; identity and ownership remain unchanged.
export function paintCell(s,cubbyId,rackId,key,color,depth){
 if(s.draft)return updateSession(s,{error:'Finish the pending adjustment'});
 const next=clone(s.snapshot),rack=rackAt(next,cubbyId,rackId),meta=rack&&rack.cellMeta[key];
 if(!meta)return updateSession(s,{error:'Select a cell'});
 if(color!==undefined&&color!==null&&(typeof color!=='string'||!/^#[0-9a-fA-F]{6}$/.test(color)))return updateSession(s,{error:'Use a six-digit hexadecimal pigment'});
 if(depth!==undefined&&(!Number.isFinite(depth)||depth<0||depth>24))return updateSession(s,{error:'Depth must be 0–24'});
 if(color!==undefined)meta.color=color;
 if(depth!==undefined)meta.depth=Math.round(depth);
 if(JSON.stringify(next)===JSON.stringify(s.snapshot))return updateSession(s,{error:''});
 return commit(s,next);
}

// N3r1: speculative structural edits use the same ownership/Undo commit boundary.
function structuralError(s,message){return updateSession(s,{error:message});}
function editorId(next,prefix){
 const used=new Set(Object.keys(next.cubbies));
 if(Spatial.enabled(next))for(const k of Object.keys(next.spatial.rooms))used.add(k);
 for(const c of Object.values(next.cubbies))for(const m of c.mods){
  used.add(m.id);for(const meta of Object.values(m.cellMeta||{}))used.add(meta.id);
  for(const entry of m.items||[])if(entry.kind==='holder')used.add(entry.id);
 }
 let id;do{if(next.next>=Number.MAX_SAFE_INTEGER)throw Error('Identity budget exhausted');id=prefix+next.next++;}while(used.has(id));return id;
}
function editorColor(value){
 if(value!==null&&(typeof value!=='string'||!/^#[0-9a-fA-F]{6}$/.test(value)))throw Error('Use a six-digit hex color or reset');
 return value;
}
// Minimum interior size that retains every committed furniture position.
export function cubbyMinimum(c){
 const boxes=[];for(const m of c.mods)for(const b of Mixed.fixtureRects(m))boxes.push(b);
 return {w:Math.max(130,...boxes.map(b=>Math.ceil(b.x+b.w))),h:Math.max(100,...boxes.map(b=>Math.ceil(b.y+b.h)))};
}
// Conservative, deterministic shrink suggestion. Existing in-bounds
// furniture stays put. Try the nearest legal position for displaced fixtures
// using the boundary and placed edges; no scaling, rotation or rack reflow.
// A failed greedy fit is not a proof that rearrangement is impossible.
export function suggestCubbyPositions(c,w,h){
 if(!Number.isInteger(w)||!Number.isInteger(h)||w<130||h<100||w>1800||h>1500||c.mods.length>64)return null;
 const bounds=m=>Mixed.fixtureEnvelope(m);
 const fits=m=>{const b=bounds(m);return b.x>=-.001&&b.y>=-.001&&b.x+b.w<=w+.001&&b.y+b.h<=h+.001;};
 if(c.mods.some(m=>{const b=bounds(m);return b.w>w+.001||b.h>h+.001;}))return null;
 const fixed=c.mods.filter(fits),displaced=c.mods.filter(m=>!fits(m));
 const placed=fixed.slice(),moves=[];
 displaced.sort((a,b)=>{const aa=bounds(a),bb=bounds(b);return bb.w*bb.h-aa.w*aa.h||(a.id<b.id?-1:a.id>b.id?1:0);});
 for(const m of displaced){
  const b=bounds(m),ox=b.x-m.x,oy=b.y-m.y;
  // Integer fixture positions, including fractional art envelope edges.
  const minX=Math.ceil(-ox),minY=Math.ceil(-oy),maxX=Math.floor(w-b.w-ox),maxY=Math.floor(h-b.h-oy);
  if(maxX<minX||maxY<minY)return null;
  const cx=v=>Math.max(minX,Math.min(maxX,v)),cy=v=>Math.max(minY,Math.min(maxY,v));
  const xs=new Set([minX,maxX,cx(m.x)]),ys=new Set([minY,maxY,cy(m.y)]);
  for(const p of placed){
   const q=bounds(p);
   xs.add(cx(Math.floor(q.x-b.w-ox)));xs.add(cx(Math.ceil(q.x+q.w-ox)));
   ys.add(cy(Math.floor(q.y-b.h-oy)));ys.add(cy(Math.ceil(q.y+q.h-oy)));
  }
  let best=null,bestCost=Infinity;
  for(const x of xs)for(const y of ys){
   const candidate=Object.assign({},m,{x,y});
   if(!fits(candidate)||!rackBounds({w,h,mods:placed},candidate))continue;
   const cost=(x-m.x)**2+(y-m.y)**2;
   if(cost<bestCost||(cost===bestCost&&best&&(y<best.y||y===best.y&&x<best.x))){best=candidate;bestCost=cost;}
  }
  if(!best)return null;
  placed.push(best);
  moves.push({id:m.id,x:best.x,y:best.y});
 }
 return moves;
}
// An explicit proportions lock derives only the other interior dimension.
export function cubbyDimensionPatch(p,key,value,ratio){
 if(!['w','h','b'].includes(key)||!Number.isInteger(value))throw Error('Enter whole-number cubby dimensions');
 const next=Object.assign({},p,{[key]:value});
 if(ratio!==null&&ratio!==undefined&&key!=='b'){
  if(!Number.isFinite(ratio)||ratio<=0)throw Error('Invalid proportions');
  if(key==='w')next.h=Math.round(value/ratio);else next.w=Math.round(value*ratio);
 }
 return next;
}
function editorCubbyPatch(c,p){
 for(const k of ['w','h','b'])if(Object.prototype.hasOwnProperty.call(p,k)){
  const value=p[k],min=k==='b'?4:k==='w'?130:100,max=k==='b'?40:k==='w'?1800:1500;
  if(!Number.isInteger(value)||value<min||value>max)throw Error('Invalid cubby '+k);c[k]=value;
 }
 if(Object.prototype.hasOwnProperty.call(p,'name')){
  if(typeof p.name!=='string'||!p.name.trim()||p.name.length>80)throw Error('Name must be 1–80 characters');c.name=p.name.trim();
 }
 for(const k of ['color','innerColor'])if(Object.prototype.hasOwnProperty.call(p,k))c[k]=editorColor(p[k]);
}
// Material preferences are optional, inherited by reference, not copied onto fixtures.
// A role swatch belongs to one global theme and preset, matching B6r12b3.
export function validateMaterials(value){
 if(value===undefined)return null;
 if(!value||typeof value!=='object'||Array.isArray(value)||!['quiet','balanced','contrasted'].includes(value.scheme)||!value.roleEdits||typeof value.roleEdits!=='object'||Array.isArray(value.roleEdits))return 'Invalid material preferences';
 for(const [key,roles] of Object.entries(value.roleEdits)){
  if(!/^(Evening|Twilight|Midnight):(quiet|balanced|contrasted)$/.test(key)||!roles||typeof roles!=='object'||Array.isArray(roles))return 'Invalid material preset key';
  for(const [role,color] of Object.entries(roles))if(!['rack','shelf','cubby'].includes(role)||typeof color!=='string'||!/^#[0-9a-fA-F]{6}$/.test(color))return 'Invalid material swatch';
 }
 return null;
}
export function editStructure(s,command){
 if(s.draft)return structuralError(s,'Finish the rack proposal first');
 try{
  // A material session is an atomic, color-only batch. Replay commands
  // against an unpublished candidate, then commit once through the existing
  // validation/ownership boundary. Never accept geometry edits in this batch.
  if(command.kind==='materialBatch'){
   const edits=command.edits;
   if(!Array.isArray(edits)||edits.length>256)throw Error('Invalid material session');
   let candidate=s;
   for(const edit of edits){
    const allowed={materials:['scheme','theme','role','color','reset'],cubby:['color','innerColor'],rackColor:['color'],shelf:['color']};
    if(!edit||edit.rearrange!==undefined||!Object.prototype.hasOwnProperty.call(allowed,edit.kind)||!edit.patch||typeof edit.patch!=='object'||Array.isArray(edit.patch)||Object.keys(edit.patch).some(k=>!allowed[edit.kind].includes(k)))throw Error('Only material edits are allowed in this session');
    candidate=editStructure(candidate,edit);
    if(candidate.error)throw Error(candidate.error);
   }
   if(JSON.stringify(candidate.snapshot)===JSON.stringify(s.snapshot))return updateSession(s,{error:''});
   return commit(s,candidate.snapshot);
  }
  if(typeof command.kind==='string'&&command.kind.indexOf('spatial')===0){
   let candidate=s;
   // Reuse the established recursive fixture deletion and Case provenance
   // logic on unpublished values, then commit once from the original state.
   if(command.kind==='spatialShelfDelete'){
    const k=command.containerId;
    if(!Spatial.enabled(s.snapshot)||!Object.prototype.hasOwnProperty.call(s.snapshot.spatial.shelves,k)||Object.keys(s.snapshot.spatial.shelves).length<=1)throw Error('Keep at least one architectural Shelf');
    for(const m of s.snapshot.cubbies[k].mods){
     candidate=editStructure(candidate,{kind:'delete',cubbyId:k,moduleId:m.id});
     if(candidate.error)throw Error(candidate.error);
    }
   }
   const next=clone(candidate.snapshot);
   Spatial.edit(next,command,prefix=>editorId(next,prefix));
   if(JSON.stringify(next)===JSON.stringify(s.snapshot))return updateSession(s,{error:''});
   return commit(s,next);
  }
  const next=clone(s.snapshot),c=next.cubbies[command.cubbyId];
  if(!c)throw Error('Cubby no longer exists');
  const p=command.patch||{},m=c.mods.find(q=>q.id===command.moduleId);
  if(command.kind==='create'){
   if(c.mods.length>=Capacity.limits.modulesPerCubby||command.type==='cubby'&&Object.keys(next.cubbies).length>=Capacity.limits.cubbies)throw Error('Study furniture budget exceeded');
   const type=command.type;if(!['rack','cubby','shelf','artwork'].includes(type))throw Error('Unsupported fixture');
   const q={id:editorId(next,'module-'),type,x:p.x,y:p.y,w:p.w,h:p.h};
   if(![q.x,q.y,q.w,q.h].every(Number.isInteger))throw Error('Enter whole-number footprint dimensions');
   if(type==='rack'){
    Object.assign(q,{shape:'hex',r:p.r===undefined?64:p.r,color:null,cellMeta:{},scrollCells:{}});
    const err=parseReflowNumbers(q);if(err)throw Error(err);
    if(q.r<60)throw Error('New rack radius must be at least 60; use explicit resize approval afterward');
    if(!rackBounds(c,q))throw Error('Footprint overlaps or exceeds cubby');
    for(const cell of geomForRack(q).cells)q.cellMeta[cell.key]={id:editorId(next,'hc'),color:null};
   }else if(type==='shelf'){
    q.h=15;q.color=null;q.items=[];
   }else if(type==='artwork'){
    q.profile=p.profile===undefined?'bronze':p.profile;q.record=null;
    Mixed.validateMount(q);
   }else{
    const childId=editorId(next,'cubby-');q.childId=childId;
    next.cubbies[childId]={id:childId,name:'New cubby',w:470,h:340,b:11,mods:[]};
   }
   c.mods.push(q);
  }else if(command.kind==='delete'){
   if(!m)throw Error('Select a fixture');
   const deletedCubbyIds=new Set(),deletedRackIds=new Set();
   function collect(childId){
    if(deletedCubbyIds.has(childId))throw Error('Cyclic child');
    deletedCubbyIds.add(childId);
    for(const q of next.cubbies[childId].mods){deletedRackIds.add(q.id);if(q.type==='cubby')collect(q.childId);}
   }
   deletedRackIds.add(m.id);if(m.type==='cubby')collect(m.childId);
   // Apply is the explicit confirmation; preview never publishes the evacuation.
   const removed=owners(next).filter(e=>e.where!=='case'&&deletedRackIds.has(e.rackId||e.moduleId));
   for(const e of removed){
    const item=clone(e.scroll);
    if(e.where==='rack'){
     const rack=rackAt(next,e.cubbyId,e.rackId);
     Mixed.clearMixedOrigin(item);
     Object.assign(item,{originCubbyId:e.cubbyId,originRackId:e.rackId,originKey:e.key,originCellId:rack.cellMeta[e.key].id,originStale:true});
    }else Mixed.detach(next,e,item,true);
    next.caseItems.push(Object.assign(item,{moveMode:'cut'}));
   }
   c.mods=c.mods.filter(q=>q.id!==m.id);
   for(const id of deletedCubbyIds)delete next.cubbies[id];
   while(next.path.length>1&&deletedCubbyIds.has(next.path[next.path.length-1]))next.path.pop();
   for(const record of next.caseItems)if(deletedRackIds.has(record.originRackId)||deletedRackIds.has(record.originModuleId)||deletedCubbyIds.has(record.originCubbyId))record.originStale=true;
  }else if(command.kind==='cubby'){
   editorCubbyPatch(c,p);
   const minimum=cubbyMinimum(c);
   if(c.w<minimum.w||c.h<minimum.h){
    if(command.rearrange!==true)throw Error('Furniture needs at least '+minimum.w+' × '+minimum.h+' at current positions. Rearrange before shrinking.');
    const moves=suggestCubbyPositions(c,c.w,c.h);
    if(!moves)throw Error('No safe suggestion found. Increase the interior size or rearrange furniture manually.');
    for(const move of moves){const fixture=c.mods.find(q=>q.id===move.id);fixture.x=move.x;fixture.y=move.y;}
   }
  }else if(command.kind==='child'){
   if(!m||m.type!=='cubby')throw Error('Select a nested cubby');
   for(const k of ['x','y','w','h'])if(Object.prototype.hasOwnProperty.call(p,k)){
    if(!Number.isInteger(p[k]))throw Error('Enter whole-number footprint dimensions');m[k]=p[k];
   }
  }else if(command.kind==='shelf'){
   if(!m||m.type!=='shelf')throw Error('Select a shelf');
   for(const k of ['x','y','w'])if(Object.prototype.hasOwnProperty.call(p,k)){
    if(!Number.isInteger(p[k]))throw Error('Enter whole-number shelf dimensions');m[k]=p[k];
   }
   if(Object.prototype.hasOwnProperty.call(p,'color'))m.color=editorColor(p.color);
   if(command.rearrange===true&&m.items&&m.items.length){
    const items=Mixed.suggestShelfItems(m);if(!items)throw Error('No safe shelf rearrangement found');
    m.items=items;
   }
  }else if(command.kind==='artwork'){
   if(!m||m.type!=='artwork')throw Error('Select an artwork mount');
   for(const k of ['x','y','w','h'])if(Object.prototype.hasOwnProperty.call(p,k)){
    if(!Number.isInteger(p[k]))throw Error('Enter whole-number frame dimensions');m[k]=p[k];
   }
   if(Object.prototype.hasOwnProperty.call(p,'profile'))m.profile=p.profile;
   Mixed.validateMount(m);
  }else if(['holderCreate','holderEdit','holderDelete'].includes(command.kind)){
   if(!Mixed.supportsTop(m))throw Error('Select an eligible support surface');
   if(!m.items)m.items=[];
   const holder=m.items.find(e=>e.kind==='holder'&&e.id===command.holderId);
   if(command.kind==='holderCreate'){
    if(!Number.isInteger(p.x)||!Number.isInteger(p.w)||!Number.isInteger(p.count)||p.count<1||p.count>48)throw Error('Invalid holder dimensions or slot count');
    m.items.push({kind:'holder',id:editorId(next,'holder-'),x:p.x,w:p.w,scale:.86,slots:Array(p.count).fill(null)});
   }else{
    if(!holder)throw Error('Select an upright holder');
    if(command.kind==='holderDelete'){
     const removed=Mixed.owners(c.id,m).filter(e=>e.holderId===holder.id);
     for(const e of removed){const item=clone(e.scroll);Mixed.detach(next,e,item,true);next.caseItems.push(Object.assign(item,{moveMode:'cut'}));}
     m.items=m.items.filter(e=>e!==holder);
     for(const item of next.caseItems)if(item.originHolderId===holder.id)item.originStale=true;
    }else{
     for(const k of ['x','w'])if(Object.prototype.hasOwnProperty.call(p,k)){
      if(!Number.isInteger(p[k]))throw Error('Enter whole-number holder dimensions');holder[k]=p[k];
     }
     if(Object.prototype.hasOwnProperty.call(p,'count')){
      if(!Number.isInteger(p.count)||p.count<1||p.count>48)throw Error('Invalid slot count');
      if(holder.slots.slice(p.count).some(Boolean))throw Error('Move occupied end slots before reducing capacity');
      while(holder.slots.length<p.count)holder.slots.push(null);
      holder.slots.length=p.count;
      for(const item of next.caseItems)if(item.originHolderId===holder.id&&item.originSlot>=p.count)item.originStale=true;
     }
    }
   }
   Mixed.validateShelf(m);
  }else if(command.kind==='holderMove'){
   if(!Mixed.supportsTop(m))throw Error('Select an upright holder');
   const holder=(m.items||[]).find(e=>e.kind==='holder'&&e.id===command.holderId);
   if(!holder||!Number.isInteger(command.from)||!Number.isInteger(command.to)||command.from<0||command.to<0||command.from>=holder.slots.length||command.to>=holder.slots.length||!holder.slots[command.from]||holder.slots[command.from].id!==command.recordId)throw Error('Invalid or stale holder move');
   const a=holder.slots[command.from];holder.slots[command.from]=holder.slots[command.to];holder.slots[command.to]=a;
  }else if(command.kind==='rackColor'){
   if(!m||m.type!=='rack')throw Error('Select a rack');m.color=editorColor(p.color);
  }else if(command.kind==='materials'){
   const value=clone(next.materials||{scheme:'balanced',roleEdits:{}});
   if(p.scheme!==undefined)value.scheme=p.scheme;
   if(p.theme!==undefined){
    if(!['Evening','Twilight','Midnight'].includes(p.theme))throw Error('Invalid theme');
    const key=p.theme+':'+value.scheme;
    if(p.reset===true)delete value.roleEdits[key];
    else{
     if(!['rack','shelf','cubby'].includes(p.role))throw Error('Invalid material role');
     const roles=Object.assign({},value.roleEdits[key]||{});
     if(p.color===null)delete roles[p.role];else roles[p.role]=editorColor(p.color);
     if(Object.keys(roles).length)value.roleEdits[key]=roles;else delete value.roleEdits[key];
    }
   }
   const err=validateMaterials(value);if(err)throw Error(err);
   next.materials=value;
  }else throw Error('Unknown structural command');
  if(JSON.stringify(next)===JSON.stringify(s.snapshot))return updateSession(s,{error:''});
  return commit(s,next);
 }catch(e){return structuralError(s,String(e.message||e));}
}
export function previewStructure(s,command){
 const candidate=editStructure(s,command);
 return {revision:s.revision,command:clone(command),ok:!candidate.error&&candidate.snapshot!==s.snapshot,error:candidate.error||'',snapshot:candidate.error?null:candidate.snapshot,caseTransferCount:candidate.error?0:Math.max(0,candidate.snapshot.caseItems.length-s.snapshot.caseItems.length)};
}
export function applyStructure(s,proposal){
 if(!proposal||!proposal.ok||proposal.revision!==s.revision||s.draft)return structuralError(s,'No valid latest structural proposal');
 return editStructure(s,proposal.command);
}

 // Shared grid contract. Coordinates are cubby-local, not screen pixels.
export function snapCoordinate(value,interval,enabled){
 if(!Number.isFinite(value)||!Number.isInteger(interval)||interval<5||interval>100)throw Error('Invalid grid coordinate or interval');
 return enabled?Math.round(value/interval)*interval:Math.round(value);
}

// Both rack and structural drags consume interior-local deltas. Snap the
// moved origin or the moving far edge, never the size in isolation.
// Shelf board thickness is invariant. Validation remains with the caller.
export function fixtureDragPatch(base,dx,dy,resize,shelf,interval,snap){
 if(![base.x,base.y,base.w,base.h,dx,dy].every(Number.isFinite))throw Error('Invalid fixture drag');
 const quantize=v=>snapCoordinate(v,interval,snap);
 if(!resize)return {x:quantize(base.x+dx),y:quantize(base.y+dy)};
 const patch={w:quantize(base.x+base.w+dx)-base.x};
 if(!shelf)patch.h=quantize(base.y+base.h+dy)-base.y;
 return patch;
}

 // Resolve an explicit Case return without mutating the snapshot.
 // Motion still owns the transaction and validates the eventual placement.
export function originDestination(snapshot,record){
 if(!record||!snapshot.caseItems.some(r=>r.id===record.id))throw Error('Choose a carried record');
 const s=snapshot.caseItems.find(r=>r.id===record.id);
 if(s.originStale)throw Error('Original fixture is no longer available');
 if(s.originModuleId)return Mixed.originDestination(snapshot,s);
 const rack=rackAt(snapshot,s.originCubbyId,s.originRackId);
 const key=rack&&Object.keys(rack.cellMeta).find(k=>rack.cellMeta[k].id===s.originCellId);
 const cell=key&&geomForRack(rack).cells.find(c=>c.key===key);
 if(!cell)throw Error('Original cell unavailable');
 const spot=staticScrollSpot(cell,rack.scrollCells[key]||[],s.r,.2);
 if(!spot)throw Error('No clear space at origin');
 return {cubbyId:s.originCubbyId,rackId:s.originRackId,key,local:spot};
}
