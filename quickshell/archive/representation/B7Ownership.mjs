// B7-N2: DOM/Qt-free ownership and conservative placement policy.
// ArchiveCore alone publishes snapshots, validates uniqueness and stores Undo.
import * as C from "../RepresentationCatalog.mjs";
import * as L from "./B7Layout.mjs";

const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
const plain=v=>!!v&&typeof v==="object"&&!Array.isArray(v);
const id=v=>typeof v==="string"&&v.length>0&&v.length<=128&&!["__proto__","constructor","prototype"].includes(v);
const finite=(v,min,max)=>Number.isFinite(v)&&v>=min&&v<=max;
function need(ok,message){if(!ok)throw Error(message)}
function copy(v){return JSON.parse(JSON.stringify(v))}
const upright=f=>["record","ledger","tablet"].includes(f);

// Preferred family/variant are intrinsic metadata; the owner supplies the
// current form. Existing legacy representation/variant fields are supported.
export function preferred(record){
    need(plain(record)&&id(record.id)&&typeof record.name==="string"&&record.name.length<=512,"Invalid file identity or name");
    const family=record.representation===undefined?C.representation(record.name):record.representation;
    need(family==="scroll"||own(C.pools,family),"Unknown preferred representation");
    if(record.compact!==undefined)need(typeof record.compact==="boolean","Invalid compact preference");
    if(family==="scroll")need(record.variant==null,"Scroll has no symbolic variant");
    return {family,variant:C.chooseVariant(family,record.id,record.variant)};
}
export function portableError(record){
    // Legacy B6 records without explicit art metadata remain byte-compatible.
    if(record.representation===undefined&&record.variant===undefined&&record.compact===undefined)return null;
    try{preferred(record);return null}catch(e){return String(e.message||e)}
}
function file(record){
    need(plain(record)&&finite(record.r,.1,200),"Invalid portable radius");
    const p=preferred(record);
    need(record.compact!==true&&p.family!=="scroll","Compact scroll needs a rack");
    return p;
}
export function currentAppearance(entry){
    const p=preferred(entry.scroll);
    return entry.where==="case"||entry.where==="rack"?{family:"scroll",variant:null}:p;
}
export function overlap(a,b){
    return a.x<b.x+b.w-.001&&a.x+a.w>b.x+.001&&a.y<b.y+b.h-.001&&a.y+a.h>b.y+.001;
}
function rect(x,y,w,h){return {x,y,w,h}}
function objectRect(entry){
    need(plain(entry)&&finite(entry.x,0,1800)&&finite(entry.scale,.4,1.3),"Invalid shelf object placement");
    const p=file(entry.record);
    if(p.family==="artwork"){
        need(entry.support==="shelf"&&plain(entry.frame)&&finite(entry.frame.w,40,400)&&finite(entry.frame.h,40,400),"Invalid shelved frame");
        const g=C.frameGeometry(entry.frame.w,entry.frame.h,entry.frame.profile);
        return rect(entry.x-entry.frame.w/2,-entry.frame.h,entry.frame.w+g.shadow.width,entry.frame.h);
    }
    need(["sculpture","parcel"].includes(p.family),"Object requires an upright holder");
    const support=L.supportFixture(p.variant,entry.x,0,entry.scale,entry.support);
    const shape=L.supportedLayout(p.variant,entry.x,support.supportY,entry.scale).box;
    // Conservative selection envelope plus small stroke allowance. The
    // secondary support width is included even when artwork is narrower.
    const x=Math.min(support.x,shape.x-2),right=Math.max(support.x+support.w,shape.x+shape.width+2);
    const y=shape.y-2;
    return rect(x,y,right-x,-y);
}
function holderRect(entry){
    need(id(entry.id)&&finite(entry.x,0,1800)&&finite(entry.w,90,800)&&finite(entry.scale,.4,1.3)&&Array.isArray(entry.slots)&&entry.slots.length>=1&&entry.slots.length<=48,"Invalid upright holder");
    for(const record of entry.slots)if(record!==null)need(upright(file(record).family),"Incompatible holder record");
    // Reserve a supported full-face cradle beside the holder, including the
    // tallest possible face for this scale, even while no item is presented.
    const records=entry.slots.map(r=>r===null?null:{id:r.id,variant:preferred(r).variant});
    L.uprightGeometry(records,entry.scale,entry.w-24,0);
    const envelope=L.holderEnvelope(entry.scale,entry.w);
    return rect(entry.x,-envelope.height,envelope.width,envelope.height);
}
// Board surfaces remain inherently eligible. A rack or nested Cubby face
// has a top datum only when explicitly opted in by spatial-state policy.
export function supportsTop(module){
    return !!module&&(module.type==="shelf"||
        (module.type==="rack"||module.type==="cubby")&&module.flatTop===true);
}
export function supportSurface(module){
    need(supportsTop(module),"Fixture has no eligible support surface");
    return {moduleId:module.id,x:module.x,y:module.y,w:module.w};
}
export function validateShelf(module){
    need(supportsTop(module),"Fixture has no eligible support surface");
    const entries=module.items===undefined?[]:module.items;
    need(Array.isArray(entries)&&entries.length<=64,"Invalid shelf contents");
    const boxes=[];
    for(const entry of entries){
        need(plain(entry),"Invalid shelf entry");
        const b=entry.kind==="object"?objectRect(entry):entry.kind==="holder"?holderRect(entry):null;
        need(b&&b.x>=-.001&&b.x+b.w<=module.w+.001,"Object or holder exceeds shelf width");
        need(!boxes.some(q=>overlap(q,b)),"Shelf objects overlap");
        boxes.push(b);
    }
    return boxes;
}
export function validateMount(m){
    need([m.x,m.y,m.w,m.h].every(Number.isFinite)&&finite(m.w,40,400)&&finite(m.h,40,400),"Invalid artwork mount");
    const g=C.frameGeometry(m.w,m.h,m.profile);
    if(m.record!==null)need(file(m.record).family==="artwork","Mount requires artwork");
    return g;
}
export function fixtureRects(m){
    if(m.type==="artwork"){
        const g=validateMount(m);
        return [rect(m.x,m.y,m.w+g.shadow.width,m.h)];
    }
    const boxes=[rect(m.x,m.y,m.w,m.h)];
    if(supportsTop(m))for(const b of validateShelf(m))boxes.push(rect(m.x+b.x,m.y+b.y,b.w,b.h));
    return boxes;
}
// Preserve existing .scroll member for B6 callers; non-rack entries expose
// module/holder/slot locators instead of inventing rack cells.
export function owners(cubbyId,m){
    const out=[];
    if(m.type==="artwork"&&m.record)out.push({id:m.record.id,where:"artwork",cubbyId,moduleId:m.id,scroll:m.record});
    if(supportsTop(m))for(const e of m.items||[]){
        if(e.kind==="object")out.push({id:e.record.id,where:"shelf",cubbyId,moduleId:m.id,scroll:e.record});
        else if(e.kind==="holder")for(let i=0;i<e.slots.length;i++)if(e.slots[i]){
            const r=e.slots[i];out.push({id:r.id,where:"holder",cubbyId,moduleId:m.id,holderId:e.id,slot:i,scroll:r});
        }
    }
    return out;
}
export function clearMixedOrigin(r){
    for(const key of ["originModuleId","originHolderId","originSlot","originPlacement"])delete r[key];
}
function clearRackOrigin(r){
    for(const key of ["originRackId","originKey","originCellId"])delete r[key];
}
function moduleAt(snapshot,e){
    const c=snapshot.cubbies[e.cubbyId],m=c&&c.mods.find(q=>q.id===e.moduleId);
    need(m,"Fixture no longer exists");return m;
}
export function detach(snapshot,e,item,stale){
    const m=moduleAt(snapshot,e);
    clearRackOrigin(item);clearMixedOrigin(item);
    Object.assign(item,{originCubbyId:e.cubbyId,originModuleId:e.moduleId,originStale:stale});
    if(e.where==="artwork"){need(m.record&&m.record.id===e.id,"Missing artwork");m.record=null;}
    else if(e.where==="shelf"){
        const i=m.items.findIndex(q=>q.kind==="object"&&q.record.id===e.id);need(i>=0,"Missing shelf object");
        const placement=copy(m.items[i]);delete placement.record;item.originPlacement=placement;m.items.splice(i,1);
    }else if(e.where==="holder"){
        const holder=m.items.find(q=>q.kind==="holder"&&q.id===e.holderId);
        need(holder&&holder.slots[e.slot]&&holder.slots[e.slot].id===e.id,"Missing holder record");
        item.originHolderId=e.holderId;item.originSlot=e.slot;holder.slots[e.slot]=null;
    }else throw Error("Unsupported source");
}
export function place(snapshot,item,d){
    const m=moduleAt(snapshot,d),p=file(item);
    // Placement coordinates are not file metadata. Remove stale cell positions
    // when returning to a non-scroll representation, preserving provenance.
    delete item.x;delete item.y;delete item.cellKey;
    if(d.kind==="artwork"){
        need(m.type==="artwork"&&m.record===null&&p.family==="artwork","Choose a vacant compatible artwork mount");
        m.record=item;
    }else if(d.kind==="shelf"){
        need(supportsTop(m)&&(m.type==="shelf"||snapshot.spatial),"Choose an eligible support surface");
        const entry={kind:"object",record:item,x:d.x,scale:d.scale,support:d.support};
        if(p.family==="artwork")entry.frame=copy(d.frame);
        objectRect(entry);
        if(!m.items)m.items=[];
        m.items.push(entry);
    }else if(d.kind==="holder"){
        need(supportsTop(m)&&(m.type==="shelf"||snapshot.spatial)&&upright(p.family),"Choose a compatible upright holder");
        const h=(m.items||[]).find(e=>e.kind==="holder"&&e.id===d.holderId);
        need(h&&Number.isInteger(d.slot)&&d.slot>=0&&d.slot<h.slots.length&&h.slots[d.slot]===null,"Choose a vacant holder slot");
        h.slots[d.slot]=item;
    }else throw Error("Unsupported destination");
}

// Bounded horizontal rearrangement. Keep all still-fitting entries fixed;
// move only displaced entries, in deterministic width/index order. No scale,
// representation, slot or record edits. Failure is not a proof of impossibility.
export function suggestShelfItems(module){
    if(!Array.isArray(module.items)||module.items.length>64)return null;
    try{
        const items=copy(module.items),fixed=[],displaced=[];
        const bounds=e=>e.kind==="holder"?holderRect(e):objectRect(e);
        for(let i=0;i<items.length;i++){
            const b=bounds(items[i]);if(b.w>module.w+.001)return null;
            const q={i,b};if(b.x>=-.001&&b.x+b.w<=module.w+.001)fixed.push(q);else displaced.push(q);
        }
        if(fixed.some((a,i)=>fixed.slice(i+1).some(b=>overlap(a.b,b.b))))return null;
        displaced.sort((a,b)=>b.b.w-a.b.w||a.i-b.i);
        for(const q of displaced){
            const max=Math.max(0,module.w-q.b.w),clamp=v=>Math.max(0,Math.min(max,v));
            const xs=new Set([0,max,clamp(q.b.x)]);
            for(const p of fixed){xs.add(clamp(p.b.x-q.b.w));xs.add(clamp(p.b.x+p.b.w));}
            const candidates=[...xs].sort((a,b)=>Math.abs(a-q.b.x)-Math.abs(b-q.b.x)||a-b);
            const x=candidates.find(x=>!fixed.some(p=>overlap(p.b,Object.assign({},q.b,{x}))));
            if(x===undefined)return null;
            items[q.i].x+=x-q.b.x;fixed.push({i:q.i,b:Object.assign({},q.b,{x})});
        }
        validateShelf(Object.assign({},module,{items}));return items;
    }catch(e){return null}
}

// Interpret only concrete compatible drop surfaces. Placement is subsequently
// validated on the private transaction, not by hit testing alone.
export function destinationAt(snapshot,cubbyId,p,record,source){
    const c=snapshot.cubbies[cubbyId];
    if(!c||!p||![p.x,p.y].every(Number.isFinite))return null;
    let pref;try{pref=file(record)}catch(e){return null}
    const family=pref.family;
    let placement=record.originPlacement;
    if(source&&source.where==="shelf"){
        const board=c.mods.find(m=>m.id===source.moduleId);
        const e=board&&(board.items||[]).find(v=>v.kind==="object"&&v.record.id===record.id);
        if(e)placement=e;
    }
    for(const m of c.mods){
        if(m.type==="artwork"&&family==="artwork"&&(!m.record||m.record.id===record.id)&&p.x>=m.x&&p.x<=m.x+m.w&&p.y>=m.y&&p.y<=m.y+m.h)
            return {kind:"artwork",cubbyId,moduleId:m.id};
        if(!supportsTop(m))continue;
        const x=p.x-m.x,y=p.y-m.y;
        if(x<0||x>m.w)continue;
        if(upright(family)){
            const rise=validateShelf(m).reduce((h,b)=>Math.max(h,-b.y),0);
            for(const h of m.items||[])if(h.kind==="holder"){
                const records=h.slots.map(r=>r?{id:r.id,variant:preferred(r).variant}:null);
                const layout=L.uprightGeometry(records,h.scale,h.w-24,rise-22);
                const left=h.x+(h.w-layout.span)/2,top=Math.max(0,rise-22-205*h.scale-8)-rise;
                if(y<top||y>0)continue;
                for(let i=0;i<layout.slots.length;i++){
                    const s=layout.slots[i];
                    if(x>=left+s.left&&x<left+s.left+s.width&&(!h.slots[i]||h.slots[i].id===record.id))
                        return {kind:"holder",cubbyId,moduleId:m.id,holderId:h.id,slot:i};
                }
            }
        }else if(y>=-36&&y<=(m.type==="shelf"?m.h:0)){
            const d={kind:"shelf",cubbyId,moduleId:m.id,x,scale:.86,support:"shelf"};
            if(placement&&placement.kind==="object"){
                d.scale=placement.scale;d.support=placement.support;
            }
            if(family==="artwork")d.frame=placement&&placement.frame?copy(placement.frame):{w:120,h:100,profile:"bronze"};
            return d;
        }
    }
    return null;
}

export function fixtureEnvelope(m){
    const boxes=fixtureRects(m),x=Math.min(...boxes.map(b=>b.x)),y=Math.min(...boxes.map(b=>b.y));
    return rect(x,y,Math.max(...boxes.map(b=>b.x+b.w))-x,Math.max(...boxes.map(b=>b.y+b.h))-y);
}
export function holderAt(module,p){
    if(!supportsTop(module))return null;
    const entries=module.items||[],boxes=validateShelf(module);
    for(let i=0;i<entries.length;i++){
        const b=boxes[i];
        if(entries[i].kind==="holder"&&p.x>=b.x&&p.x<=b.x+b.w&&p.y>=b.y&&p.y<=0)return entries[i];
    }
    return null;
}
// Search only bounded horizontal positions; candidate still must pass full
// cubby validation. Empty holder includes its reserved presentation cradle.
export function newHolderPatch(c,module,step){
    const p={x:0,w:160,count:4};
    if(!Number.isInteger(step)||step<1)return p;
    for(let x=0;x<=module.w-L.holderEnvelope(.86,p.w).width;x+=step){
        const entry={kind:"holder",id:"preview-holder",x,w:p.w,scale:.86,slots:Array(p.count).fill(null)};
        const candidate=Object.assign({},module,{items:(module.items||[]).concat([entry])});
        try{
            const boxes=fixtureRects(candidate);
            if(boxes.every(b=>b.x>=0&&b.y>=0&&b.x+b.w<=c.w+.001&&b.y+b.h<=c.h+.001)&&
                !c.mods.some(m=>m.id!==module.id&&fixtureRects(m).some(b=>boxes.some(a=>overlap(a,b)))))
                return Object.assign({},p,{x});
        }catch(e){}
    }
    return p;
}

export function originDestination(snapshot,record){
    need(!record.originStale,"Original fixture is no longer available");
    const d={cubbyId:record.originCubbyId,moduleId:record.originModuleId};
    const m=moduleAt(snapshot,d);
    if(m.type==="artwork"){d.kind="artwork";}
    else if(supportsTop(m)&&record.originHolderId){
        d.kind="holder";d.holderId=record.originHolderId;d.slot=record.originSlot;
    }else if(supportsTop(m)&&record.originPlacement&&record.originPlacement.kind==="object"){
        const p=record.originPlacement;
        Object.assign(d,{kind:"shelf",x:p.x,scale:p.scale,support:p.support});
        if(p.frame)d.frame=copy(p.frame);
    }else throw Error("Original fixture unavailable");
    // Validate the exact return on a disposable candidate before motion.
    const candidate=copy(snapshot),item=copy(record);
    candidate.caseItems=candidate.caseItems.filter(r=>r.id!==record.id);
    place(candidate,item,d);
    const c=candidate.cubbies[d.cubbyId],target=moduleAt(candidate,d),boxes=fixtureRects(target);
    need(boxes.every(b=>b.x>=-.001&&b.y>=-.001&&b.x+b.w<=c.w+.001&&b.y+b.h<=c.h+.001)&&
        !c.mods.some(q=>q.id!==target.id&&fixtureRects(q).some(b=>boxes.some(a=>overlap(a,b)))),"Original placement no longer fits");
    return d;
}
