// Visual adapter for the native study. All geometry and record coordinates
// originate in ArchiveCore; this module never mutates committed snapshots.
import * as Core from "./ArchiveCore.mjs";

export function mix(a,b,t) {
    function rgb(s){return [parseInt(s.slice(1,3),16),parseInt(s.slice(3,5),16),parseInt(s.slice(5,7),16)];}
    const x=rgb(a),y=rgb(b);
    return "#"+x.map((v,i)=>("0"+Math.round(v+(y[i]-v)*t).toString(16)).slice(-2)).join("");
}
// UI-only HSV conversion. Snapshots keep validated six-digit RGB strings.
// Retain the user's hue when an achromatic swatch has no intrinsic hue.
export function colorHSV(hex,fallbackHue=0){
    if(typeof hex!=="string"||!/^#[0-9a-fA-F]{6}$/.test(hex))throw Error("Invalid RGB swatch");
    const [r,g,b]=[1,3,5].map(i=>parseInt(hex.slice(i,i+2),16)/255);
    const v=Math.max(r,g,b),d=v-Math.min(r,g,b);
    let h=Math.max(0,Math.min(360,fallbackHue));
    if(d){h=60*(v===r?(g-b)/d:v===g?(b-r)/d+2:(r-g)/d+4);if(h<0)h+=360;}
    return {h,s:v?d/v:0,v};
}
export function hsvColor(h,s,v){
    if(![h,s,v].every(Number.isFinite))throw Error("Invalid HSV swatch");
    h=((h%360)+360)%360;s=Math.max(0,Math.min(1,s));v=Math.max(0,Math.min(1,v));
    const c=v*s,x=c*(1-Math.abs(h/60%2-1)),m=v-c;
    const rgb=h<60?[c,x,0]:h<120?[x,c,0]:h<180?[0,c,x]:h<240?[0,x,c]:h<300?[x,0,c]:[c,0,x];
    return "#"+rgb.map(n=>("0"+Math.round((n+m)*255).toString(16)).slice(-2)).join("");
}
export function materialRoles(p,preferences){
    const scheme=preferences?preferences.scheme:'balanced';
    let roles;
    if(scheme==='quiet')roles={rack:mix(p.panel,p.background,.10),shelf:p.panel,cubby:mix(p.panel,p.background,.08)};
    else if(scheme==='contrasted')roles={rack:mix(p.panel,p.engraving,.38),shelf:mix(p.panel,p.metal,.30),cubby:mix(p.panel,p.metal,.43)};
    else roles={rack:mix(p.panel,p.engraving,.18),shelf:p.panel,cubby:mix(p.panel,p.metal,.24)};
    return Object.assign(roles,preferences&&preferences.roleEdits[p.name+':'+scheme]||{});
}
export function appearancePalette(p,preferences){
    return Object.assign({},p,{materials:materialRoles(p,preferences)});
}
export function frameColor(c,p,depth){return c.color||(depth?(p.materials?p.materials.cubby:mix(p.panel,p.metal,.24)):p.panel);}
export function backingColor(c,p,depth){return c.innerColor||(depth%2?mix(p.background,p.engraving,.20):mix(p.background,p.panel,.25));}
export function rackColor(m,p){return m.color||(p.materials?p.materials.rack:mix(p.panel,p.engraving,.18));}
export function shelfColor(m,p){return m.color||(p.materials?p.materials.shelf:p.panel);}
export function wallColor(meta,p){return meta&&meta.color||mix(p.panel,p.metal,.34);}
export function recessColor(meta,p){return mix(mix(p.background,p.engraving,.15),p.background,Math.max(0,Math.min(24,Number(meta&&meta.depth)||0))/24*.46);}
// Exterior preview inventory describes immediate contents only. A nested
// cubby is counted once, without exposing its descendants or file names.
// N3r1 has empty shelf boards; populated shelf ownership arrives in B7.
export function cubbyPreviewSummary(c){
    const counts={rack:0,shelf:0,cubby:0,items:0};
    for(const m of c.mods){
        if(m.type==="rack"){
            counts.rack++;
            for(const records of Object.values(m.scrollCells||{}))counts.items+=records.length;
        }else if(m.type==="shelf"){
            counts.shelf++;
            for(const entry of m.items||[])counts.items+=entry.kind==="holder"?entry.slots.filter(Boolean).length:1;
        }else if(m.type==="artwork"){if(m.record)counts.items++;}
        else if(m.type==="cubby")counts.cubby++;
    }
    return counts;
}
export function purpose(record){
    if(record.purpose&&["code","config","logs","documents","system","other"].includes(record.purpose))return record.purpose;
    const parts=String(record.name||"").toLowerCase().split("."),ext=parts[parts.length-1];
    if(["py","js","ts","sh","css","c","cpp","rs"].includes(ext))return "code";
    if(["toml","ini","conf","config","yaml","yml"].includes(ext))return "config";
    if(["log","trace"].includes(ext))return "logs";
    if(["service","sys"].includes(ext))return "system";
    if(["md","txt","pdf","odt","docx"].includes(ext))return "documents";
    return "other";
}
export function parchment(record){return {code:"#c8b69b",config:"#bba67e",logs:"#c0b9a8",documents:"#d4be9b",system:"#bd9692",other:"#c4b7a1"}[purpose(record)];}
export function seal(record){return {code:"#547b89",config:"#b08a49",logs:"#68747a",documents:"#8c685a",system:"#8b3f47",other:"#807668"}[purpose(record)];}
export function records(rack){
    const list=[];
    for(const cell of Core.geometry(rack).cells)for(const record of rack.scrollCells[cell.key]||[])list.push(record);
    return list;
}
export function hitScroll(list,x,y){
    for(let i=list.length-1;i>=0;i--){const s=list[i];if(Math.hypot(x-s.x,y-s.y)<=s.r)return s;}
    return null;
}
export function seams(cells){
    const edges=new Map();
    for(const c of cells)for(let i=0;i<c.poly.length;i++){
        const a=c.poly[i],b=c.poly[(i+1)%c.poly.length],ka=a.x.toFixed(4)+","+a.y.toFixed(4),kb=b.x.toFixed(4)+","+b.y.toFixed(4);
        const key=ka<kb?ka+"|"+kb:kb+"|"+ka;if(!edges.has(key))edges.set(key,{a,b});
    }
    return Array.from(edges.values());
}
export function markers(cells,unresolved){
    const counts=new Map();
    for(const e of unresolved||[])counts.set(e.key,(counts.get(e.key)||0)+1);
    const result=[];
    for(const c of cells){
        const count=counts.get(c.key);if(!count)continue;
        const center=c.poly.reduce((p,q)=>({x:p.x+q.x/c.poly.length,y:p.y+q.y/c.poly.length}),{x:0,y:0});
        result.push({key:c.key,x:center.x,y:center.y,count});counts.delete(c.key);
    }
    // A disappeared cell has no valid geometric location. Report its
    // unresolved records at the rack plaque, not at invented positions.
    let missing=0;for(const count of counts.values())missing+=count;
    return {cells:result,missing};
}
// Longest still-reachable prefix; a reset/import can remove a currently
// open cubby before QML has delivered its snapshotChanged notification.
export function reachablePath(snapshot,path){
    const result=["root"];
    if(!Array.isArray(path)||path[0]!=="root")return result;
    for(let i=1;i<path.length;i++){
        const parent=snapshot.cubbies[result[result.length-1]],id=path[i];
        if(!snapshot.cubbies[id]||!parent.mods.some(m=>m.type==="cubby"&&m.childId===id))break;
        result.push(id);
    }
    return result;
}
export function camera(cubby,w,h,zoom,pan){
    const b=Number(cubby.b)||11;
    const fit=Math.max(.01,Math.min(Math.max(1,w-32)/(cubby.w+2*b),Math.max(1,h-32)/(cubby.h+2*b)));
    const scale=fit*Math.max(.5,Math.min(2.5,zoom));
    return {scale,x:(w-(cubby.w+2*b)*scale)/2+pan.x,y:(h-(cubby.h+2*b)*scale)/2+pan.y};
}
export function displayRack(controller,cubbyId,rack){
    return controller.draft&&controller.preview&&controller.draft.cubbyId===cubbyId&&controller.draft.rackId===rack.id?controller.preview.rack:rack;
}
export function caseRecords(controller){
    return controller.snapshot.caseItems.concat(controller.preview?controller.preview.caseOverflow:[]);
}
// Match the browser's explicitly illustrative metadata, never claim real disk facts.
function sampleMeta(record){
 const name=record.name,ext=name.lastIndexOf(".")>0?name.slice(name.lastIndexOf(".")):"None";
 const types={".app":"Application bundle",".md":"Markdown document",".txt":"Plain text document",".pdf":"PDF document",".py":"Python source",".toml":"TOML configuration"};
 let sum=0;for(let i=0;i<name.length;i++)sum+=name.charCodeAt(i);
 const day=n=>("0"+n).slice(-2);
 Object.assign(record,{synthetic:true,purpose:purpose(record),extension:ext,fileType:types[ext]||"File · compact storage",modified:day(sum%24+1)+" Nov 2026",added:day(sum%27+1)+" Oct 2026",size:(sum*7%730+22)+" KiB",path:"~/Archive/Samples/"+name});
}
export function fixture(){
    const s=Core.fixture(),c=s.cubbies.root,m=c.mods[0];
    Object.assign(c,{name:"The Main Hall · study cubby",w:800,h:520,b:12});
    Object.assign(m,{x:24,y:35});
    const originalCell=Core.geometry(m).cells.find(q=>q.key==="1:1");
    const settled=Core.settle(originalCell,m.scrollCells["1:1"]);
    if(!settled)throw Error("N2 reference pile did not settle");
    m.scrollCells["1:1"]=settled;
    const names=["main.py","config.toml","journal.log","notes.pdf","shell.service","index.md","layout.js","themes.ini","readme.txt"];
    const cells=Core.geometry(m).cells.filter(q=>q.key!=="1:1"&&q.area>10000);
    let ni=0;
    for(const cell of cells.slice(0,3)){
        const list=[];
        for(let i=0;i<3;i++){
            const r=[9,12,15][i],spot=Core.staticScrollSpot(cell,list,r,.13*i);
            if(!spot)continue;
            list.push(Object.assign({id:"visual-"+ni,name:names[ni++],r,cellKey:cell.key},spot));
        }
        const packed=Core.settle(cell,list);if(!packed)throw Error("N2 pile did not settle");m.scrollCells[cell.key]=packed;
    }
    const child={id:"child",name:"Field notes",w:470,h:340,b:11,mods:[]};
    const rack={id:"rack-child",type:"rack",shape:"hex",x:24,y:24,w:390,h:270,r:64,color:null,cellMeta:{},scrollCells:{}};
    for(const cell of Core.geometry(rack).cells)rack.cellMeta[cell.key]={id:"hc"+s.next++,color:null};
    const spotCell=Core.geometry(rack).cells.find(q=>q.area>8000);
    const p=Core.staticScrollSpot(spotCell,[],13,.2);
    const childRecord=Object.assign({id:"child-note",name:"field-notes.md",r:13,cellKey:spotCell.key},p);
    const childPacked=Core.settle(spotCell,[childRecord]);if(!childPacked)throw Error("Child pile did not settle");
    rack.scrollCells[spotCell.key]=childPacked;child.mods.push(rack);s.cubbies.child=child;
    c.mods.push({id:"cubby-child",type:"cubby",childId:"child",x:550,y:35,w:220,h:180});
    s.caseItems.push({id:"case-note",name:"observations.txt",r:10,cellKey:spotCell.key,originCubbyId:"child",originRackId:rack.id,originCellId:rack.cellMeta[spotCell.key].id,originKey:spotCell.key,moveMode:"cut"});
    for(const e of Core.owners(s))sampleMeta(e.scroll);
    const error=Core.validate(s);if(error)throw Error(error);
    return s;
}

 // AUD-14: normal creation is fresh even if exact snapshot Undo reused
 // its ID. Retain cameras only for current and restorable cubbies.
export function reconcileCameras(previous,next,history,cameras,undoing,activeId,activeCamera){
    const out=Object.assign({},cameras);
    if(previous.cubbies[activeId]&&!next.cubbies[activeId])out[activeId]=Object.assign({},activeCamera);
    if(!undoing)for(const id of Object.keys(next.cubbies))if(!previous.cubbies[id])delete out[id];
    const keep=new Set(Object.keys(next.cubbies));
    for(const state of history)for(const id of Object.keys(state.cubbies))keep.add(id);
    for(const id of Object.keys(out))if(!keep.has(id))delete out[id];
    return out;
}
