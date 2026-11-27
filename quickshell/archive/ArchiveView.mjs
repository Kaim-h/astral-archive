// Visual adapter for the native study. All geometry and record coordinates
// originate in ArchiveCore; this module never mutates committed snapshots.
import * as Core from "./ArchiveCore.mjs";
import * as Spatial from "./ArchiveSpatial.mjs";
import * as Doors from "./ArchiveDoors.mjs";
import * as Architecture from "./ArchiveArchitecture.mjs";
import * as RoomProjection from "./ArchiveRoomProjection.mjs";
import * as Mixed from "./representation/B7Ownership.mjs";
import * as Appearance from "./ArchiveAppearance.mjs";

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
export function emblemSource(family,key,p){
    const svg=Appearance.emblemSvg(family,key,p.engraving);
    return svg?'data:image/svg+xml,'+encodeURIComponent(svg):ornamentAsset(family,p.name);
}
// A centered square strictly within the sampled crest silhouette; the
// narrow-case width cap keeps the upper corners below its curved edge.
export function crestMarkBounds(g){
    const crest=g&&g.parts&&g.parts.find(p=>p.role==='crest');
    if(!crest)return null;
    const xs=crest.points.map(p=>p[0]),ys=crest.points.map(p=>p[1]);
    const left=Math.min(...xs),right=Math.max(...xs),top=Math.min(...ys),bottom=Math.max(...ys);
    const rise=bottom-top,size=Math.min(rise*.68,(right-left)*.18);
    return size>0?{x:(left+right-size)/2,y:top+rise*.58-size/2,w:size,h:size}:null;
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
export function frameColor(c,p,depth){return c.appearance&&Appearance.materialRoles.includes(c.appearance.frame)&&p[c.appearance.frame]||c.color||(depth?(p.materials?p.materials.cubby:mix(p.panel,p.metal,.24)):p.panel);}
export function backingColor(c,p,depth){return c.appearance&&Appearance.materialRoles.includes(c.appearance.backing)&&p[c.appearance.backing]||c.innerColor||(depth%2?mix(p.background,p.engraving,.20):mix(p.background,p.panel,.25));}
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
        return Architecture.shelfGeometry(c,Spatial.shelfProfile(s,id),p.depth,Spatial.independentProfiles(s)?p.frameBasis:undefined);
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
export function roomPerspective(s,plan,width,height,research=null){
    return plan?RoomProjection.projectedScene(RoomProjection.roomMesh(s,plan.room.id,plan.openings,research),width,height):null;
}
export function roomPerspectiveHit(scene,x,y){
    const face=RoomProjection.faceAt(scene,x,y);return face?face.shelfId:'';
}
export function roomFloorColor(p){return mix(p.background,p.panel,.72);}
// Paint-only edge color for the same visible surface owner.
export function roomEdgeColor(fill,p){return mix(fill,p.metal,.34);}
export function architectureSurfaceColor(face,frame,backing,p){
    const base=face.role==='backing'?backing:profilePartColor(face.role,frame,p);
    if(face.side==='front')return base;
    if(face.side==='back')return mix(p.background,base,.68);
    if(face.surface==='top')return mix(base,p.metal,.30);
    if(face.surface==='bottom')return mix(p.background,base,.55);
    return mix(base,p.metal,.12);
}
export function roomPerspectiveColor(s,face,palettes,desktop,roomColors){
    if(!face.shelfId){
        const fill=face.side==='north'||face.side==='east'?mix(roomColors.panel,roomColors.metal,.27):mix(roomColors.background,roomColors.metal,.36);
        return face.surface==='cap'?mix(fill,roomColors.metal,.45):face.surface==='base'?mix(fill,roomColors.background,.32):fill;
    }
    const p=spatialPalette(s,face.shelfId,palettes,desktop),c=s.cubbies[face.shelfId];
    return architectureSurfaceColor(face,frameColor(c,p,0),backingColor(c,p,0),p);
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
    return Architecture.profileFootprint(Architecture.shelfGeometry(c,Spatial.shelfProfile(s,id),p.depth,Spatial.independentProfiles(s)?p.frameBasis:undefined),p);
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


// N4a: top-down atlas from committed authoritative Rooms, Shelf footprints
// and one shared door record. No copied arrangement or renderer-side solver.
export function mapPlan(s){
    if(!Spatial.physicalProfiles(s))return null;
    const rooms=Object.values(s.spatial.rooms).map(r=>({id:r.id,name:r.name,x:r.x,y:r.y,w:r.w,h:r.h,
        family:r.appearance&&r.appearance.family!=null?r.appearance.family:s.spatial.appearance&&s.spatial.appearance.family!=null?s.spatial.appearance.family:"Architectural",
        palette:r.appearance&&r.appearance.palette!=null?r.appearance.palette:null,mapStyle:Appearance.mapRoomPolicy(s,r.id),shelves:[]}));
    if(!rooms.length)return null;
    const byId=new Map(rooms.map(r=>[r.id,r]));
    for(const [id,p] of Object.entries(s.spatial.shelves)){
        const room=byId.get(p.roomId),box=Spatial.footprint(s,id);
        const glyph=Architecture.planGlyph(Spatial.shelfGeometry(s,id),p),world=q=>[q[0]+room.x,q[1]+room.y];
        room.shelves.push({id,box:{x:room.x+box.x,y:room.y+box.y,w:box.w,h:box.h},glyph:{layers:glyph.layers.map(l=>({role:l.role,points:l.points.map(world)})),front:glyph.front.map(world)}});
    }
    const doors=Object.keys(s.spatial.doors||{}).map(id=>Object.assign({id},Spatial.doorGeometry(s,id)));
    const x=Math.min(...rooms.map(r=>r.x)),y=Math.min(...rooms.map(r=>r.y)),
        right=Math.max(...rooms.map(r=>r.x+r.w)),bottom=Math.max(...rooms.map(r=>r.y+r.h));
    return {rooms,doors,bounds:{x,y,w:right-x,h:bottom-y}};
}
export function mapFrame(data,w,h,zoom=1,center=null){
    if(!data||![w,h,zoom].every(Number.isFinite)||w<=0||h<=0)return null;
    const b=data.bounds,k=Math.min(Math.max(1,w-64)/b.w,Math.max(1,h-244)/b.h)*Math.max(.25,Math.min(8,zoom));
    const c=center&&[center.x,center.y].every(Number.isFinite)?center:{x:b.x+b.w/2,y:b.y+b.h/2};
    return {scale:k,x:w/2-c.x*k,y:h/2-c.y*k,cx:c.x,cy:c.y};
}
export function mapAt(frame,x,y){
    return frame&&[x,y].every(Number.isFinite)?{x:(x-frame.x)/frame.scale,y:(y-frame.y)/frame.scale}:null;
}
export function mapRoomHit(data,x,y){
    if(!data||![x,y].every(Number.isFinite))return '';
    const r=data.rooms.find(r=>x>=r.x&&x<r.x+r.w&&y>=r.y&&y<r.y+r.h);
    return r?r.id:'';
}

// N4b: transient Room arrangement helpers. Core remains the validator.
export function mapRoomDraft(data){
    if(!data)return null;
    const b=data.bounds,w=1000,h=800,limit=Spatial.spatialLimits.mapCoordinate;
    const positions=[[b.x+b.w,b.y],[b.x-w,b.y],[b.x,b.y+b.h],[b.x,b.y-h]];
    const pos=positions.find(v=>v.every(n=>Number.isInteger(n)&&Math.abs(n)<=limit));
    return {name:'New Room',x:pos?pos[0]:0,y:pos?pos[1]:0,w,h};
}
export function mapRoomDraftAt(data,point,snap,interval){
 if(!data||!point||![point.x,point.y].every(Number.isFinite))return null;
 const w=1000,h=800,limit=Spatial.spatialLimits.mapCoordinate;
 const x=Core.snapCoordinate(point.x-w/2,interval,snap),y=Core.snapCoordinate(point.y-h/2,interval,snap);
 const options=[[x,y]];
 for(let ring=1;ring<=12;ring++)for(let i=-ring;i<=ring;i++){
  options.push([x+i*w/2,y-ring*h/2],[x+i*w/2,y+ring*h/2]);
  if(Math.abs(i)<ring)options.push([x-ring*w/2,y+i*h/2],[x+ring*w/2,y+i*h/2]);
 }
 options.sort((a,b)=>Math.hypot(a[0]-x,a[1]-y)-Math.hypot(b[0]-x,b[1]-y));
 for(const v of options){const a=Core.snapCoordinate(v[0],interval,snap),b=Core.snapCoordinate(v[1],interval,snap);
  if(Math.abs(a)>limit||Math.abs(b)>limit||data.rooms.some(r=>a<r.x+r.w&&r.x<a+w&&b<r.y+r.h&&r.y<b+h))continue;
  return {name:'New Room',x:a,y:b,w,h};
 }
 return null;
}
export function mapRoomOutline(s,cmd){
    if(!cmd||!Spatial.physicalProfiles(s))return null;
    const r=cmd.kind==='spatialRoomCreate'?{}:s.spatial.rooms[cmd.roomId];
    if(!r)return null;
    const b=Object.assign({},r,cmd.patch||{});
    if(![b.x,b.y,b.w,b.h].every(Number.isFinite)||b.w<=0||b.h<=0||
       Math.abs(b.x)>Spatial.spatialLimits.mapCoordinate||Math.abs(b.y)>Spatial.spatialLimits.mapCoordinate||
       b.w>Spatial.spatialLimits.roomSize||b.h>Spatial.spatialLimits.roomSize)return null;
    return {x:b.x,y:b.y,w:b.w,h:b.h};
}
export function mapRoomLostDoors(s,cmd){
    if(!cmd||!Spatial.physicalProfiles(s)||!['spatialRoomEdit','spatialRoomDelete'].includes(cmd.kind)||
       !Object.prototype.hasOwnProperty.call(s.spatial.rooms,cmd.roomId))return [];
    if(cmd.kind==='spatialRoomEdit'&&!mapRoomOutline(s,cmd))return [];
    if(cmd.kind==='spatialRoomDelete'&&Object.values(s.spatial.shelves).some(p=>p.roomId===cmd.roomId))return [];
    const copy=Core.clone(s);
    if(cmd.kind==='spatialRoomDelete'){delete copy.spatial.rooms[cmd.roomId];return Doors.invalidated(copy,Spatial.footprint);}
    const captured=Doors.captureRoomDoors(copy,cmd.roomId,Spatial.footprint);
    Object.assign(copy.spatial.rooms[cmd.roomId],cmd.patch);
    return Doors.reconcileRoomDoors(copy,captured,Spatial.footprint);
}
export function mapRoomGesture(data,id,kind,frame,x,y){
    const r=data&&data.rooms.find(v=>v.id===id),start=mapAt(frame,x,y);
    if(!r||!start||!['move','resize','resize-nw','resize-n','resize-ne','resize-e','resize-se','resize-s','resize-sw','resize-w'].includes(kind))return null;
    return {id,kind,start,frame:Object.assign({},frame),box:{x:r.x,y:r.y,w:r.w,h:r.h},
        neighbors:data.rooms.filter(v=>v.id!==id).map(v=>({x:v.x,y:v.y,w:v.w,h:v.h}))};
}
export function mapRoomGesturePatch(g,x,y,snap,interval,magnetic){
    if(!g)return null;
    const point=mapAt(g.frame,x,y);if(!point)return null;
    const dx=Core.snapCoordinate(point.x-g.start.x,interval,snap),dy=Core.snapCoordinate(point.y-g.start.y,interval,snap),b=g.box;
    if(!dx&&!dy)return {};
    const move=g.kind==='move',side=g.kind==='resize'?'se':g.kind.slice(7),patch={};
    if(move){patch.x=b.x+dx;patch.y=b.y+dy;}
    else{
        if(side.includes('e'))patch.w=b.w+dx;
        if(side.includes('w')){patch.x=b.x+dx;patch.w=b.w-dx;}
        if(side.includes('s'))patch.h=b.h+dy;
        if(side.includes('n')){patch.y=b.y+dy;patch.h=b.h-dy;}
    }
    if(magnetic){
        const limit=10/g.frame.scale;
        const overlaps=(a,b)=>a.x<b.x+b.w&&b.x<a.x+a.w&&a.y<b.y+b.h&&b.y<a.y+a.h;
        const valid=r=>r.w>=130&&r.h>=100&&r.w<=Spatial.spatialLimits.roomSize&&r.h<=Spatial.spatialLimits.roomSize&&
            Math.abs(r.x)<=Spatial.spatialLimits.mapCoordinate&&Math.abs(r.y)<=Spatial.spatialLimits.mapCoordinate&&!g.neighbors.some(n=>overlaps(r,n));
        for(const [axis,delta,low,high] of [['x',dx,'w','e'],['y',dy,'n','s']]){
            if(!delta||!move&&!side.includes(low)&&!side.includes(high))continue;
            const size=axis==='x'?'w':'h',other=axis==='x'?'y':'x',otherSize=axis==='x'?'h':'w';
            const r=Object.assign({},b,patch),choices=[];
            for(const n of g.neighbors){
                if(r[other]>=n[other]+n[otherSize]||n[other]>=r[other]+r[otherSize])continue;
                // Only opposing walls, not coincident same-side edges.
                if(move||side.includes(low))choices.push({shift:n[axis]+n[size]-r[axis],low:true});
                if(move||side.includes(high))choices.push({shift:n[axis]-(r[axis]+r[size]),low:false});
            }
            choices.sort((a,b)=>Math.abs(a.shift)-Math.abs(b.shift));
            for(const q of choices){
                if(Math.abs(q.shift)>limit)break;
                const next=Object.assign({},r);
                if(move)next[axis]+=q.shift;
                else if(q.low){next[axis]+=q.shift;next[size]-=q.shift;}
                else next[size]+=q.shift;
                if(!valid(next))continue;
                if(move||q.low)patch[axis]=next[axis];
                if(!move)patch[size]=next[size];
                break;
            }
        }
    }
    return patch;
}

// N4c: map suggestions and direct gesture adapters over the authoritative
// shared-wall solver. The renderer never creates or copies doorway records.
export function mapDoorSuggestions(s,roomId){
    if(!Spatial.physicalProfiles(s)||!roomId)return [];
    const list=[];
    for(const p of Doors.adjacentPairs(s,roomId,Spatial.footprint))for(const span of p.spans){
        const width=Math.min(160,span.end-span.start),start=Math.floor((span.start+span.end-width)/2),end=start+width;
        list.push({a:p.a,b:p.b,vertical:p.vertical,line:p.line,start,end,patch:{a:p.a,b:p.b,start:start-p.origin,end:end-p.origin}});
    }
    return list;
}
export function mapDoorGesture(s,id,kind,frame,x,y){
    const d=Spatial.physicalProfiles(s)&&s.spatial.doors&&s.spatial.doors[id],point=mapAt(frame,x,y);
    if(!d||!point||!['move','start','end'].includes(kind))return null;
    const g=Spatial.doorGeometry(s,id),span=Doors.doorEditSpan(s,d,Spatial.footprint);
    if(!span)return null;
    return {id,kind,frame:Object.assign({},frame),start:point,geometry:g,span,origin:Doors.edge(s,d.a).start};
}
export function mapDoorGesturePatch(g,x,y,snap,interval){
    if(!g)return null;
    const p=mapAt(g.frame,x,y);if(!p)return null;
    const axis=g.geometry.vertical?'y':'x',delta=Core.snapCoordinate(p[axis]-g.start[axis],interval,snap);
    return Doors.gesturePatch(g.geometry,g.span,g.origin,g.kind,delta);
}
export function mapDoorOutline(s,id,patch){
    const d=Spatial.physicalProfiles(s)&&s.spatial.doors&&s.spatial.doors[id];
    if(!d||!patch)return null;
    const a=Doors.edge(s,d.a),start=patch.start===undefined?d.start:patch.start,end=patch.end===undefined?d.end:patch.end;
    if(!Number.isInteger(start)||!Number.isInteger(end)||start<0||end<=start||end>a.length)return null;
    return {vertical:a.vertical,line:a.line,start:a.start+start,end:a.start+end};
}
export function mapDoorHit(data,frame,x,y,tolerance=10){
    if(!data||!frame||![x,y,tolerance].every(Number.isFinite))return '';
    let best=null,dist=tolerance;
    for(const d of data.doors){
        const a=d.vertical?frame.y+d.start*frame.scale:frame.x+d.start*frame.scale,
              b=d.vertical?frame.y+d.end*frame.scale:frame.x+d.end*frame.scale,
              line=d.vertical?frame.x+d.line*frame.scale:frame.y+d.line*frame.scale,
              along=d.vertical?y:x,cross=d.vertical?x:y;
        const z=Math.hypot(cross-line,Math.max(a-along,0,along-b));
        if(z<=dist){best=d.id;dist=z;}
    }
    return best||'';
}
export function mapDoorGestureMerge(s,id,patch){
    const d=s.spatial&&s.spatial.doors&&s.spatial.doors[id],g=mapDoorOutline(s,id,patch);if(!d||!g)return '';
    const same=(a,b)=>a.roomId===b.roomId&&a.side===b.side;
    return Object.values(s.spatial.doors).filter(other=>other.id!==id&&(same(d.a,other.a)&&same(d.b,other.b)||same(d.a,other.b)&&same(d.b,other.a))).filter(other=>{const q=Spatial.doorGeometry(s,other.id);return g.start===q.end||g.end===q.start;}).map(v=>v.id).sort()[0]||'';
}
export function mapDoorMergeChoices(s,id){
    const d=s.spatial&&s.spatial.doors&&s.spatial.doors[id];if(!d)return [];
    const g=Spatial.doorGeometry(s,id),same=(a,b)=>a.roomId===b.roomId&&a.side===b.side;
    return Object.values(s.spatial.doors).filter(other=>{
        if(other.id===id||!(same(d.a,other.a)&&same(d.b,other.b)||same(d.a,other.b)&&same(d.b,other.a)))return false;
        const q=Spatial.doorGeometry(s,other.id);
        return g.start<=q.end&&q.start<=g.end;
    }).map(d=>d.id).sort();
}

export function mapDoorCommandOutline(s,cmd){
    if(!cmd||!Spatial.physicalProfiles(s))return null;
    if(cmd.kind==='spatialDoorEdit')return mapDoorOutline(s,cmd.doorId,cmd.patch);
    if(cmd.kind==='spatialDoorCreate'){
        const p=cmd.patch;if(!p||!Number.isInteger(p.start)||!Number.isInteger(p.end)||p.start<0||p.end<=p.start)return null;
        const a=Doors.edge(s,p.a);if(p.end>a.length)return null;
        return {vertical:a.vertical,line:a.line,start:a.start+p.start,end:a.start+p.end};
    }
    if(cmd.kind==='spatialDoorMerge'){
        const d=s.spatial.doors&&s.spatial.doors[cmd.doorId],other=s.spatial.doors&&s.spatial.doors[cmd.patch.otherId];
        if(!d||!other)return null;
        const a=Spatial.doorGeometry(s,d.id),b=Spatial.doorGeometry(s,other.id);
        return {vertical:a.vertical,line:a.line,start:Math.min(a.start,b.start),end:Math.max(a.end,b.end)};
    }
    return null;
}

// Map decorative insets never change the authoritative boundary or opening.
export function mapWallRuns(data,r,inset=0){
    if(!data||!r||!Number.isFinite(inset)||inset<0||inset*2>=Math.min(r.w,r.h))return [];
    const out=[];
    for(const [side,vertical,line,lo,hi,draw] of [['north',false,r.y,r.x,r.x+r.w,r.y+inset],['south',false,r.y+r.h,r.x,r.x+r.w,r.y+r.h-inset],['west',true,r.x,r.y,r.y+r.h,r.x+inset],['east',true,r.x+r.w,r.y,r.y+r.h,r.x+r.w-inset]]){
        const gaps=data.doors.filter(d=>d.openings.some(o=>o.roomId===r.id&&o.side===side)).sort((a,b)=>a.start-b.start);
        let cursor=lo+inset,end=hi-inset;
        for(const d of gaps){const to=Math.min(end,d.start);if(to>cursor)out.push({vertical,line:draw,start:cursor,end:to});cursor=Math.max(cursor,d.end);}
        if(end>cursor)out.push({vertical,line:draw,start:cursor,end});
    }
    return out;
}
export function mapRoomDetail(r,frame,zoom){
    return !!r&&!!frame&&zoom>=1.3&&Math.min(r.w,r.h)*frame.scale>=56;
}

// N4e: transient map camera; bounds are view-only, never geometry clamps.
export const mapCenterLimit=1000000;
export function mapCameraCenter(x,y){
    if(![x,y].every(Number.isFinite))return null;
    const clamp=v=>Math.max(-mapCenterLimit,Math.min(mapCenterLimit,v));
    return {x:clamp(x),y:clamp(y)};
}
export function mapFocusCamera(data,w,h,kind,id){
    const fit=mapFrame(data,w,h,1);if(!fit)return null;
    let b;
    if(kind==='room'){
        const r=data.rooms.find(q=>q.id===id);if(!r)return null;
        const pad=Math.max(95,Math.max(r.w,r.h)*.17);b={x:r.x-pad,y:r.y-pad,w:r.w+2*pad,h:r.h+2*pad};
    }else if(kind==='door'){
        const d=data.doors.find(q=>q.id===id);if(!d)return null;
        const size=Math.max(320,(d.end-d.start)*3.7),mid=(d.start+d.end)/2,cx=d.vertical?d.line:mid,cy=d.vertical?mid:d.line;
        b={x:cx-size/2,y:cy-size/2,w:size,h:size};
    }else return null;
    const target=mapFrame({bounds:b},w,h,1);
    return {zoom:Math.max(.25,Math.min(8,target.scale/fit.scale)),center:mapCameraCenter(b.x+b.w/2,b.y+b.h/2)};
}
export function mapTransitionFrame(from,to,t){
    if(!from||!to||!Number.isFinite(t))return null;
    t=Math.max(0,Math.min(1,t));if(t===0)return Object.assign({},from);if(t===1)return Object.assign({},to);const mix=(a,b)=>a+(b-a)*t;
    return {scale:mix(from.scale,to.scale),x:mix(from.x,to.x),y:mix(from.y,to.y),cx:mix(from.cx,to.cx),cy:mix(from.cy,to.cy)};
}

export function roomPalette(s,id,palettes,desktop){const a=s.spatial&&s.spatial.rooms[id]&&s.spatial.rooms[id].appearance;return palettes[a&&a.palette!==null&&a.palette!==undefined?a.palette:desktop];}
export function planGlyphColor(s,id,role,p){const c=s.cubbies[id],a=c.appearance||{};return role==='frame'?a.frame||c.color?mix(frameColor(c,p,0),p.metal,.55):p.metal:role==='recess'?a.backing||c.innerColor?backingColor(c,p,0):p.background:frameColor(c,p,0);}
// Periodic S14r5 stone tile geometry. Both projections sample the same
// bounded lookup in world coordinates; no extra structural faces.
export function roomTilePattern(a){
 const n=a.floorScale,tiles=[];let w=2*n,h=2*n,angle=a.floorAngle;
 const mod=(x,m)=>((x%m)+m)%m;
 const poly=(p,tag)=>tiles.push({p,tag});
 const rect=(x,y,W,H,t)=>poly([[x,y],[x+W,y],[x+W,y+H],[x,y+H]],t);
 if(a.floor==='plain')return null;
 if(a.floor==='slabs'||a.floor==='diagonal'){for(let j=0;j<2;j++)for(let i=0;i<2;i++)rect(i*n,j*n,n,n,i+2*j);if(a.floor==='diagonal')angle+=45;}
 if(a.floor==='bond'){h=n;for(let j=0;j<2;j++)for(let i=-1;i<=2;i++)rect(i*n+j%2*n/2,j*n/2,n,n/2,mod(i,2)+j*2);}
 if(a.floor==='octagon'){const c=n*(1-1/Math.sqrt(2));for(let j=-1;j<=2;j++)for(let i=-1;i<=2;i++){const x=i*n,y=j*n;poly([[x+c,y],[x+n-c,y],[x+n,y+c],[x+n,y+n-c],[x+n-c,y+n],[x+c,y+n],[x,y+n-c],[x,y+c]],mod(i,2)+2*mod(j,2));poly([[x,y-c],[x+c,y],[x,y+c],[x-c,y]],4);}}
 if(a.floor==='hex'){const r=n/2,s=Math.sqrt(3)*r;w=2*s;h=3*r;for(let j=-1;j<=2;j++)for(let i=-1;i<=2;i++){const x=i*s+mod(j,2)*s/2,y=j*1.5*r,ps=[];for(let k=0;k<6;k++)ps.push([x+r*Math.cos(Math.PI/6+k*Math.PI/3),y+r*Math.sin(Math.PI/6+k*Math.PI/3)]);poly(ps,mod(i,2)+2*mod(j,2));}}
 if(a.floor==='herringbone'){const L=3,u=n/L;for(let j=-L;j<2*L;j++)for(let i=-L;i<2*L;i++){if(mod(i+j,2*L)===0)rect(i*u,j*u,L*u,u,mod(i,2)+2*mod(j,2));if(mod(i+j,2*L)===L)rect(i*u,j*u,u,L*u,mod(i,2)+2*mod(j,2));}angle+=45;}
 if(a.floor==='basket'){for(let j=0;j<2;j++)for(let i=0;i<2;i++)for(let k=0;k<3;k++){if((i+j)%2)rect(i*n+k*n/3,j*n,n/3,n,k);else rect(i*n,j*n+k*n/3,n,n/3,k);}}
 if(a.floor==='ashlar'){rect(0,0,1.5*n,n,0);rect(1.5*n,0,.5*n,.5*n,1);rect(1.5*n,.5*n,.5*n,.5*n,2);rect(0,n,.5*n,n,3);rect(.5*n,n,1.5*n,.5*n,4);rect(.5*n,1.5*n,.75*n,.5*n,5);rect(1.25*n,1.5*n,.75*n,.5*n,6);}
 return {w,h,angle,tiles};
}
export function roomSurfaceTable(a,p){
 const pattern=roomTilePattern(a),base=roomFloorColor(p),colors=[base,mix(base,p.metal,.4*a.detail/100)];
 for(let i=0;i<7;i++)colors.push(mix(base,i%2?p.background:p.engraving,Math.min(.18,(.04+i*.015)*a.variation/100)));
 if(!pattern)return {pattern:null,colors};
 const size=48,indices=new Uint8Array(size*size);
 for(let j=0;j<size;j++)for(let i=0;i<size;i++){
  const x=(i+.5)*pattern.w/size,y=(j+.5)*pattern.h/size;
  for(const tile of pattern.tiles){let inside=true,edge=Infinity;
   for(let k=0;k<tile.p.length;k++){const q=tile.p[k],r=tile.p[(k+1)%tile.p.length],dx=r[0]-q[0],dy=r[1]-q[1],cross=dx*(y-q[1])-dy*(x-q[0]);if(cross<-.00001){inside=false;break;}edge=Math.min(edge,cross/Math.sqrt(dx*dx+dy*dy));}
   if(inside){indices[j*size+i]=edge<Math.max(a.grout/2,.6)?1:2+tile.tag%7;break;}
  }
 }
 const angle=pattern.angle*Math.PI/180;return {pattern,colors,size,indices,cos:Math.cos(angle),sin:Math.sin(angle)};
}
export function roomFloorSample(t,a,x,y,w,h){
 const near=Math.min(x,y,w-x,h-y);
 if(a.floorBorder&&near>=0){const d=Math.abs(near-12);if(d<(a.borderStyle==='band'?3:1.5)||a.borderStyle==='double'&&Math.abs(near-20)<1.5||a.borderStyle==='diamond'&&d+Math.abs(((x+y)%24+24)%24-12)<4)return t.colors[1];}
 if(!t.pattern)return t.colors[0];
 const X=x*t.cos+y*t.sin,Y=-x*t.sin+y*t.cos,p=t.pattern,mod=(n,m)=>((n%m)+m)%m;
 return t.colors[t.indices[Math.min(t.size-1,Math.floor(mod(Y,p.h)/p.h*t.size))*t.size+Math.min(t.size-1,Math.floor(mod(X,p.w)/p.w*t.size))]];
}
export function roomWallMark(a,t,z,length,height){
 if(height<=0||length<=0)return false;
 const bay=length/Math.max(1,Math.round(length/a.wallScale)),u=((t%bay)+bay)%bay/bay,v=1-z/height;
 const near=(x,y,d=.012)=>Math.abs(x-y)<d;
 const box=(l,r,top,bottom)=>(v>=top&&v<=bottom&&(near(u,l)||near(u,r)))||(u>=l&&u<=r&&(near(v,top)||near(v,bottom)));
 let mark=false;
 switch(a.wall){
 case 'panel':mark=box(.06,.94,.08,.92)||box(.12,.88,.14,.86);break;
 case 'masonry':mark=near(v,1/3)||near(v,2/3)||near(u,Math.floor(v*3)%2?.5:0);break;
 case 'rubble':mark=near(v,.32)||near(v,.73)||near(u,v<.32?.38:v<.73?.7:.24)||v>.73&&near(u,.67);break;
 case 'pilaster':mark=box(.04,.18,.05,.95)||near(u,.085)||near(u,.135)||box(.25,.94,.15,.85);break;
 case 'arcade':mark=v>.35&&(near(u,.11)||near(u,.89))||v<=.36&&near(v,.36-.27*Math.sqrt(Math.max(0,1-Math.pow((u-.5)/.39,2))),.015)&&u>.11&&u<.89;break;
 case 'wainscot':mark=near(v,.65)||box(.06,.94,.68,.94)||v>.68&&(near(u,.33)||near(u,.67));break;
 case 'ribbed':mark=box(.06,.94,.08,.92)||v>.15&&v<.9&&u>.12&&u<.88&&Math.abs(u*9-Math.round(u*9))<.08;break;
 }
 return mark||a.wallMarks&&Math.abs(u-.5)+Math.abs(v-.37)*1.3<.07&&Math.abs(u-.5)+Math.abs(v-.37)*1.3>.048;
}
export function roomWallPoint(frame,face,x,y){const depth=face.plane.m*x+face.plane.n*y+face.plane.k;if(!Number.isFinite(depth)||depth<=0)return null;
 const q=1/depth,u=(x-frame.ox)/frame.scale,v=(y-frame.oy)/frame.scale,s=frame.distance-q;
 const X=u*q/frame.distance+frame.w/2,Y=frame.sin*s+frame.cos*v*q/frame.distance+frame.h/2,Z=frame.cos*s-frame.sin*v*q/frame.distance;
 return {t:face.side==='north'||face.side==='south'?X:Y,z:Z};
}

