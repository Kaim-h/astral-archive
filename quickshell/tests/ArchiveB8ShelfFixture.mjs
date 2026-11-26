// Synthetic N2a specimen using the established mixed fixture and Core.
import * as Core from "../archive/ArchiveCore.mjs";
import * as Mixed from "./ArchiveB7MixedFixture.mjs";
export function fixture(){
 const s=Mixed.fixture(),root=s.cubbies.root;
 root.name="Main Hall Shelf";root.h=1050;
 root.mods.find(m=>m.id==="rack-1").y=220;
 root.mods.find(m=>m.id==="cubby-child").y=245;
 // Keep the old board and mount geometry clear of moved furniture.
 root.mods.find(m=>m.id==="mixed-board").y=730;
 root.mods.find(m=>m.id==="mixed-lower").y=990;
 let state=Core.session(s);
 function edit(command){state=Core.editStructure(state,command);if(state.error)throw Error(state.error);}
 edit({kind:"spatialPromote"});
 edit({kind:"spatialSupport",containerId:"root",moduleId:"rack-1",patch:{enabled:true}});
 edit({kind:"spatialSupport",containerId:"root",moduleId:"cubby-child",patch:{enabled:true}});
 edit({kind:"spatialAppRegister",patch:{appId:"org.example.Reader",title:"Reader"}});
 edit({kind:"spatialAppRegister",patch:{appId:"org.example.Notes",title:"Notes"}});
 edit({kind:"spatialAppRegister",patch:{appId:"org.example.Atlas",title:"Atlas"}});
 edit({kind:"spatialAppPlace",appId:"org.example.Reader",containerId:"root",moduleId:"rack-1",patch:{x:100}});
 edit({kind:"spatialAppPlace",appId:"org.example.Notes",containerId:"root",moduleId:"cubby-child",patch:{x:110}});
 state=Core.transfer(state,["mixed-parcel"],{kind:"shelf",cubbyId:"root",moduleId:"rack-1",x:300,scale:.86,support:"tray"});if(state.error)throw Error(state.error);
 edit({kind:"spatialRoomCreate",patch:{name:"Observatory",x:2000,y:0,w:1200,h:1000}});
 const room=Object.keys(state.snapshot.spatial.rooms).find(k=>k!==state.snapshot.spatial.shelves.root.roomId);
 edit({kind:"spatialShelfCreate",roomId:room,patch:{name:"Observatory Shelf",x:50,y:50,w:700,h:500}});
 const shelf=Object.keys(state.snapshot.spatial.shelves).find(k=>k!=="root");
 edit({kind:"create",type:"rack",cubbyId:shelf,patch:{x:50,y:80,w:500,h:350,r:75}});
 return state.snapshot;
}


// Representative mixed population: repeat the furnished hierarchy with
// distinct file, app and structural identities, not empty capacity racks.
// Fixture construction is outside timed transactions. This is test-only.
export function populatedFixture(copies){
 if(!Number.isInteger(copies)||copies<1||copies>24)throw Error("Invalid sample size");
 const specimen=fixture(),s=Core.clone(specimen);
 const originalRoom=specimen.spatial.rooms[specimen.spatial.shelves.root.roomId];
 const source={root:specimen.cubbies.root,child:specimen.cubbies.child,caseItems:specimen.caseItems,apps:specimen.spatial.apps};
 const ids=new Set();
 function collect(v){
  if(!v||typeof v!=="object")return;
  for(const [k,x] of Object.entries(v)){
   if((k==="id"||k==="appId")&&typeof x==="string")ids.add(x);
   else collect(x);
  }
 }
 collect(source);
 for(let i=1;i<copies;i++){
  const prefix="sample-"+i+"-",map=new Map(Array.from(ids,k=>[k,prefix+k]));
  function remap(v){
   if(typeof v==="string")return map.has(v)?map.get(v):v;
   if(Array.isArray(v))return v.map(remap);
   if(!v||typeof v!=="object")return v;
   // Qt 6.4's JS engine does not provide Object.fromEntries.
   // Source keys and generated IDs are bounded synthetic fixture data.
   const out={};
   for(const [k,x] of Object.entries(v))out[map.has(k)?map.get(k):k]=remap(x);
   return out;
  }
  const copy={root:remap(source.root),child:remap(source.child),caseItems:remap(source.caseItems),apps:remap(source.apps)},roomId=prefix+"room";
  const room=Object.assign({},originalRoom,{id:roomId,name:"Sample Room "+i,x:2000*(i+1),y:0});
  s.spatial.rooms[roomId]=room;
  s.cubbies[copy.root.id]=copy.root;s.cubbies[copy.child.id]=copy.child;
  s.spatial.shelves[copy.root.id]=Object.assign({},specimen.spatial.shelves.root,{roomId});
  Object.assign(s.spatial.apps,copy.apps);s.caseItems.push(...copy.caseItems);
 }
 const error=Core.validate(s);if(error)throw Error(error);
 return s;
}


// Valid nested specimen exposing the furnished root in Inventory mode.
// The enclosing Cubby footprint is independent of interior dimensions.
export function inventoryFixture(){
 const s=fixture(),other=Object.keys(s.spatial.shelves).find(k=>k!=="root");
 delete s.spatial.shelves.root;
 s.cubbies[other].mods.push({id:"inventory-parent-face",type:"cubby",childId:"root",x:560,y:70,w:130,h:180});
 s.path=[other];
 const error=Core.validate(s);if(error)throw Error(error);
 return s;
}
