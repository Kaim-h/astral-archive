// Visual adapter for the native study. All geometry and record coordinates
// originate in ArchiveCore; this module never mutates committed snapshots.
import * as Core from "./ArchiveCore.mjs";
import * as Spatial from "./ArchiveSpatial.mjs";
import * as Architecture from "./ArchiveArchitecture.mjs";
import * as RoomProjection from "./ArchiveRoomProjection.mjs";
import * as Mixed from "./representation/B7Ownership.mjs";

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
// Resolve only the requested container's local palette. Family inheritance
// is independent; no parent palette is propagated to a child.
export function spatialPalette(snapshot,id,palettes,desktop){
    const resolved=Spatial.resolveAppearance(snapshot,id,desktop);
    return appearancePalette(palettes[resolved.palette],snapshot.materials);
}
// Bounded frame-detail geometry shared by future scene consumers. These
// are in-envelope ornament treatments, not external silhouette profiles.
// No line may claim space outside the stored frame or over the aperture.
export function shelfTrim(c,profile){
    const b=Number(c.b)||11,w=c.w+2*b,h=c.h+2*b,t=Math.min(1,b/4),out=[];
    function add(x,y,w,h,role){if(w>0&&h>0)out.push({x,y,w,h,role});}
    const side=Math.max(0,h-2*b-8);
    add(t,b*.27,w-2*t,t,'metal');
    add(b,b*.70,w-2*b,t,'engraving');
    add(t,h-b*.30-t,w-2*t,t,'metal');
    for(const x of [b*.40,w-b*.40-t])add(x,b+4,t,side,'engraving');
    if(profile==='pilaster'){
        for(const x of [b*.70,w-b*.70-t])add(x,b+4,t,side,'metal');
        for(const x of [0,w-b])for(const y of [b,h-2*b])add(x,y,b,Math.min(b,2*t),'metal');
    }
    if(profile==='crest'){
        // Stepped central inscription within the lintel; no raised crest
        // or overhang until the physical profile envelope is reconciled.
        const span=Math.min(c.w*.35,110);
        for(let i=0;i<3;i++){const half=span*(1-i*.26)/2;add(w/2-half,b*(.12+i*.22),half*2,t,'engraving');}
    }
    return out;
}
// Archived default primary emblem for each family. Keep unknown stored names
// intact; the visual fallback is Architectural, not an identity migration.
export const ornamentFamilies=Object.freeze([
    {key:null,label:"Inherit"},{key:"None",label:"None"},
    {key:"Architectural",label:"Architectural"},
    {key:"Astral",label:"Astral"},
    {key:"Botanical",label:"Botanical"},
    {key:"Bestiary",label:"Bestiary"},
    {key:"Elemental · Water",label:"Water"},
    {key:"Elemental · Air",label:"Air"},
    {key:"Elemental · Earth",label:"Earth"},
    {key:"Elemental · Fire",label:"Fire"},
    {key:"Horological",label:"Horological"}
]);
export function ornamentKey(family){
    if(family==="None")return "";
    const keys={"Architectural":"plain","Astral":"astral","Botanical":"botanical","Bestiary":"bestiary","Elemental · Water":"water","Elemental · Air":"air","Elemental · Earth":"earth","Elemental · Fire":"fire","Horological":"horological"};
    return Object.prototype.hasOwnProperty.call(keys,family)?keys[family]:"plain";
}
export function ornamentAsset(family,paletteName){
    const key=ornamentKey(family);
    const theme=["Evening","Twilight","Midnight"].includes(paletteName)?paletteName.toLowerCase():"twilight";
    return key?"ornaments/"+key+"-"+theme+".svg":"";
}
export function familyMarkSize(w,h,exterior){
    return Math.max(0,Math.min(exterior?40:112,w*.32,h*.32));
}
// Provisional three-theme book treatment: preserve the stable binding hue
// supplied by AppMatching, coordinate its cover with the current panel.
// The production launcher and native ribbon mechanics are unchanged.
export function bookColors(binding,p){
    const amount=p.name==="Evening"?.12:p.name==="Midnight"?.32:.22;
    const cover=mix(binding,p.panel,amount);
    function luminance(hex){
        const rgb=[1,3,5].map(i=>parseInt(hex.slice(i,i+2),16)/255).map(v=>v<=.04045?v/12.92:Math.pow((v+.055)/1.055,2.4));
        return .2126*rgb[0]+.7152*rgb[1]+.0722*rgb[2];
    }
    const contrast=(a,b)=>{const x=luminance(a),y=luminance(b);return (Math.max(x,y)+.05)/(Math.min(x,y)+.05);};
    const inscription=contrast(cover,p.text)>=4.5?p.text:contrast(cover,"#ffffff")>=contrast(cover,"#080f10")?"#ffffff":"#080f10";
    return {cover,inscription,ornament:p.metal};
}
export function frameColor(c,p,depth){return c.color||(depth?(p.materials?p.materials.cubby:mix(p.panel,p.metal,.24)):p.panel);}
export function backingColor(c,p,depth){return c.innerColor||(depth%2?mix(p.background,p.engraving,.20):mix(p.background,p.panel,.25));}
export function rackColor(m,p){return m.color||(p.materials?p.materials.rack:mix(p.panel,p.engraving,.18));}
export function shelfColor(m,p){return m.color||(p.materials?p.materials.shelf:p.panel);}
export function wallColor(meta,p){return meta&&meta.color||mix(p.panel,p.metal,.34);}
export function recessColor(meta,p){return mix(mix(p.background,p.engraving,.15),p.background,Math.max(0,Math.min(24,Number(meta&&meta.depth)||0))/24*.46);}
// Exterior inventory counts immediate placed representations: rack files,
// mounted files, supported file objects, occupied holder slots and apps.
// Count each eligible support once, independent of fixture type. A Cubby
// counts as a fixture; its interior (and Case contents) is not traversed.
export function cubbyPreviewSummary(c){
    const counts={rack:0,shelf:0,cubby:0,items:0};
    for(const m of c.mods){
        if(m.type==="rack"){
            counts.rack++;
            for(const records of Object.values(m.scrollCells||{}))counts.items+=records.length;
        }else if(m.type==="shelf")counts.shelf++;
        else if(m.type==="artwork"){if(m.record)counts.items++;}
        else if(m.type==="cubby")counts.cubby++;
        if(Mixed.supportsTop(m)){
            for(const entry of m.items||[])counts.items+=entry.kind==="holder"?entry.slots.filter(Boolean).length:1;
        }
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
    const roots=Spatial.roots(snapshot);
    const result=[Array.isArray(path)&&roots.includes(path[0])?path[0]:roots.includes(snapshot.path[0])?snapshot.path[0]:roots[0]];
    if(!Array.isArray(path)||path[0]!==result[0])return result;
    for(let i=1;i<path.length;i++){
        const parent=snapshot.cubbies[result[result.length-1]],id=path[i];
        if(!Object.prototype.hasOwnProperty.call(snapshot.cubbies,id)||!parent.mods.some(m=>m.type==="cubby"&&m.childId===id))break;
        result.push(id);
    }
    return result;
}
// Use the same explicit exterior for camera fitting and rendering.
export function frontEnvelope(s,id,c){
    if(Spatial.physicalProfiles(s)&&Spatial.kind(s,id)==='shelf'){
        const p=s.spatial.shelves[id];
        return Architecture.shelfGeometry(c,Spatial.shelfProfile(s,id),p.depth);
    }
    const b=Number(c.b)||11;
    return {w:c.w+2*b,h:c.h+2*b,aperture:{x:b,y:b,w:c.w,h:c.h}};
}
export function fitEnvelope(e,w,h,zoom,pan){
    const fit=Math.max(.01,Math.min(Math.max(1,w-32)/e.w,Math.max(1,h-32)/e.h));
    const scale=fit*Math.max(.5,Math.min(2.5,zoom));
    return {scale,x:(w-e.w*scale)/2+pan.x,y:(h-e.h*scale)/2+pan.y};
}
export function camera(cubby,w,h,zoom,pan){
    const b=Number(cubby.b)||11;
    return fitEnvelope({w:cubby.w+2*b,h:cubby.h+2*b},w,h,zoom,pan);
}
// Room-local plan from the same adopted geometry and shared door records.
// No renderer-specific dimensions or additional arrangement state.
export function roomPlan(s,roomId){
    if(!Spatial.physicalProfiles(s)||!Object.prototype.hasOwnProperty.call(s.spatial.rooms,roomId))return null;
    const room=s.spatial.rooms[roomId],shelves=[],openings=[];
    for(const id of Object.keys(s.spatial.shelves)){
        const p=s.spatial.shelves[id];if(p.roomId!==roomId)continue;
        const g=Spatial.shelfGeometry(s,id);
        shelves.push({id,name:s.cubbies[id].name||id,box:Spatial.footprint(s,id),glyph:Architecture.planGlyph(g,p)});
    }
    for(const id of Object.keys(s.spatial.doors||{})){
        const g=Spatial.doorGeometry(s,id);
        for(const o of g.openings)if(o.roomId===roomId)openings.push(Object.assign({id},o));
    }
    return {room,shelves,openings};
}
export function profilePartColor(role,frame,p){
    return role==='foot'||role==='capital'||role==='base'?mix(frame,p.metal,.32):role==='crest'?mix(frame,p.metal,.16):frame;
}
export function roomPerspective(s,plan,width,height){
    return plan?RoomProjection.projectedScene(RoomProjection.roomMesh(s,plan.room.id,plan.openings),width,height):null;
}
export function roomPerspectiveHit(scene,x,y){
    const face=RoomProjection.faceAt(scene,x,y);return face?face.shelfId:'';
}
export function roomFloorColor(p){return mix(p.background,p.panel,.52);}
export function roomPerspectiveColor(s,face,palettes,desktop,roomColors){
    if(!face.shelfId)return face.side==='north'||face.side==='east'?mix(roomColors.panel,roomColors.metal,.13):mix(roomColors.background,roomColors.metal,.32);
    const p=spatialPalette(s,face.shelfId,palettes,desktop),c=s.cubbies[face.shelfId];
    const base=face.role==='backing'?backingColor(c,p,0):profilePartColor(face.role,frameColor(c,p,0),p);
    return face.side==='front'?base:mix(p.background,base,face.side==='back'?.68:.80);
}
// Room arrangement is view-local until release. The captured floor mapping
// is reused for the whole gesture; snap relative deltas, never the old anchor.
export function roomGesture(s,id,kind,start,mapping){
    if(!Spatial.physicalProfiles(s)||Spatial.kind(s,id)!=='shelf'||!['move','resize'].includes(kind)||!start)return null;
    const p=s.spatial.shelves[id],c=s.cubbies[id];
    return {id,kind,start,mapping,attachment:Object.assign({},p),w:c.w,h:c.h,box:Spatial.footprint(s,id)};
}
export function roomFloorAt(mapping,x,y){
    if(!mapping||![x,y].every(Number.isFinite))return null;
    return mapping.frame?RoomProjection.floorInverse(x,y,mapping.frame):
        {x:(x-mapping.x)/mapping.scale,y:(y-mapping.y)/mapping.scale};
}
export function roomGesturePatch(g,point,snap,interval){
    if(!g||!point||![point.x,point.y].every(Number.isFinite))return null;
    const dx=Core.snapCoordinate(point.x-g.start.x,interval,snap),dy=Core.snapCoordinate(point.y-g.start.y,interval,snap),p=g.attachment,patch={};
    if(g.kind==='move'){
        if(dx)patch.x=p.x+dx;
        if(dy)patch.y=p.y+dy;
    }else{
        const sideways=p.orientation%180!==0,wide=sideways?dy:dx,deep=sideways?dx:dy;
        if(wide)patch.w=Math.round(g.w+wide);
        if(deep)patch.depth=p.depth+deep;
    }
    return patch;
}
// An outline only, not a validated candidate or a publication path.
export function roomEditOutline(s,id,patch){
    if(!Spatial.physicalProfiles(s)||Spatial.kind(s,id)!=='shelf'||!patch)return null;
    const c=Object.assign({},s.cubbies[id]),p=Object.assign({},s.spatial.shelves[id]);
    for(const key of ['w','h'])if(Object.prototype.hasOwnProperty.call(patch,key))c[key]=patch[key];
    for(const key of ['x','y','depth'])if(Object.prototype.hasOwnProperty.call(patch,key))p[key]=patch[key];
    if(![p.x,p.y,p.depth,c.w,c.h].every(Number.isFinite)||p.depth<=0||c.w<=0||c.h<=0||
        [p.x,p.y,p.depth,c.w,c.h].some(v=>Math.abs(v)>20000))return null;
    return Architecture.profileFootprint(Architecture.shelfGeometry(c,Spatial.shelfProfile(s,id),p.depth),p);
}
export function roomPlanHit(plan,x,y){
    if(!plan||!Number.isFinite(x)||!Number.isFinite(y))return '';
    const item=plan.shelves.find(v=>x>=v.box.x&&x<v.box.x+v.box.w&&y>=v.box.y&&y<v.box.y+v.box.h);
    return item?item.id:'';
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

// AUD-18: legal imported identifiers may also be Object.prototype names.
export function cameraFor(cameras,id){
    return cameras&&Object.prototype.hasOwnProperty.call(cameras,id)
        ?cameras[id]:{zoom:1,x:0,y:0};
}
export function copyCameras(cameras){
    return Object.assign(Object.create(null),cameras||{});
}

 // AUD-14: normal creation is fresh even if exact snapshot Undo reused
 // its ID. Retain cameras only for current and restorable cubbies.
export function reconcileCameras(previous,next,history,cameras,undoing,activeId,activeCamera){
    const out=copyCameras(cameras);
    if(Object.prototype.hasOwnProperty.call(previous.cubbies,activeId)&&!Object.prototype.hasOwnProperty.call(next.cubbies,activeId))out[activeId]=Object.assign({},activeCamera);
    if(!undoing)for(const id of Object.keys(next.cubbies))if(!Object.prototype.hasOwnProperty.call(previous.cubbies,id))delete out[id];
    const keep=new Set(Object.keys(next.cubbies));
    for(const state of history)for(const id of Object.keys(state.cubbies))keep.add(id);
    for(const id of Object.keys(out))if(!keep.has(id))delete out[id];
    return out;
}
