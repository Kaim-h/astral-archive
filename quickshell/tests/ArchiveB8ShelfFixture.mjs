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
