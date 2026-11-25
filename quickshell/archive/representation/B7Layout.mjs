import {assets} from "./B7AssetData.mjs";
import * as Catalog from "../RepresentationCatalog.mjs";

export function assetFor(id){
    if(typeof id!=="string"||!Object.prototype.hasOwnProperty.call(assets,id))throw Error("Unknown representation asset");
    return assets[id];
}
export function supportedLayout(id,x,y,scale,edge=false){
    const a=assetFor(id),g=a.geometry;
    const anchor=edge?g.edgeContact:g.contact,bounds=edge?g.edgeBounds:g.bounds;
    if(!anchor||!bounds||(edge&&!a.edge))throw Error("Asset has no requested support anchor");
    const image=Catalog.supportedImage(g,x,y,scale,edge);
    const box={x:x+(bounds[0]-anchor[0])*scale,y:y+(bounds[1]-anchor[1])*scale,
        width:(bounds[2]-bounds[0])*scale,height:(bounds[3]-bounds[1])*scale};
    return {image,box,contact:{x,y}};
}
export function assetEntries(){
    const result=[];
    for(const id of Object.keys(assets)){
        result.push({id,edge:false});
        if(assets[id].edge)result.push({id,edge:true});
    }
    return result;
}

// U3 slots reserve their full hit width even while presented in the cradle.
export function uprightGeometry(records,scale,width,floor){
    if(!Array.isArray(records)||!records.length||records.length>48)throw Error("Invalid holder slots");
    const seen=new Set();
    const geos=records.map(r=>{
        if(r===null)return null;
        if(!r||typeof r.id!=="string"||!r.id||seen.has(r.id))throw Error("Duplicate or invalid holder identity");
        seen.add(r.id);
        const a=assetFor(r.variant);
        if(!a.edge)throw Error("Not an upright asset");
        return a.geometry;
    });
    return Catalog.uprightLayout(geos,scale,width,floor,{maxThickness:26});
}
export function uprightEdge(record,slot,scale,fit,left){
    const g=assetFor(record.variant).geometry,v=g.edgeViewport,a=g.edgeContact;
    if(!v||!a||![scale,fit,left].every(Number.isFinite)||scale<=0||fit<=0)throw Error("Invalid upright edge");
    const sx=scale*fit,sy=scale;
    const x=left+slot.cx+(v[0]-a[0])*sx;
    const y=slot.y+slot.h+(v[1]-a[1])*sy;
    return {x,y,width:v[2]*sx,height:v[3]*sy};
}
export function moveSlot(records,from,to){
    if(!Number.isInteger(from)||!Number.isInteger(to)||from<0||to<0||from>=records.length||to>=records.length||from===to||!records[from])return records;
    const next=records.slice();next[from]=records[to];next[to]=records[from];return next;
}

// Secondary supports stand on the shelf. The object contact is at the
// secondary support's upper surface, not the shelf through the support.
export function supportFixture(id,cx,shelfY,scale,mode){
    const a=assetFor(id);
    if(!["sculpture","parcel"].includes(a.family)||!["shelf","plinth","tray"].includes(mode)||
       (mode==="plinth"&&a.family!=="sculpture")||(mode==="tray"&&a.family!=="parcel"))
        throw Error("Incompatible secondary support");
    const h=mode==="plinth"?32:mode==="tray"?20:0;
    const p=supportedLayout(id,cx,shelfY-h,scale);
    const w=Math.max(mode==="plinth"?144:mode==="tray"?156:124,
        2*Math.max(cx-p.box.x,p.box.x+p.box.width-cx)+16);
    return {x:cx-w/2,y:shelfY-h,w,h,contactX:cx,supportY:shelfY-h,
        lipHeight:mode==="tray"?8:0};
}
