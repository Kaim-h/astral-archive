import * as Core from "../archive/ArchiveCore.mjs";

export function fixture(){
    let s=Core.session(Core.fixture());
    function edit(q){s=Core.editStructure(s,q);if(s.error)throw Error(s.error);}
    edit({kind:"create",type:"cubby",cubbyId:"root",patch:{x:520,y:0,w:160,h:120}});
    const child=s.snapshot.cubbies.root.mods[1].childId;
    edit({kind:"cubby",cubbyId:child,patch:{name:"Checkpoint observatory",w:650,h:420,b:12,color:"#39504a"}});
    edit({kind:"create",type:"shelf",cubbyId:child,patch:{x:20,y:350,w:600,h:15}});
    edit({kind:"materials",cubbyId:"root",patch:{scheme:"quiet"}});
    s=Core.paintCell(s,"root","rack-1","-1:3",null,20);
    if(s.error)throw Error(s.error);
    // A portable record with stale origin is synthetic, never a real file.
    const snapshot=Core.clone(s.snapshot);
    snapshot.caseItems.push({id:"checkpoint-case",name:"portable.md",r:23,originStale:true});
    const board=snapshot.cubbies[child].mods.find(m=>m.type==="shelf");
    board.items=[
        {kind:"object",x:90,scale:.86,support:"tray",record:{id:"restart-parcel",name:"Bundle.zip",r:23,representation:"parcel",variant:"parcel/satchel",kind:"Compressed archive",synthetic:true}},
        {kind:"holder",id:"restart-holder",x:200,w:130,scale:.86,slots:[
            {id:"restart-ledger",name:"Ledger.csv",r:23,representation:"ledger",variant:"ledger/v2",kind:"Spreadsheet",synthetic:true},null,
            {id:"restart-tablet",name:"Script.otf",r:23,representation:"tablet",variant:"tablet/v1",kind:"Font",synthetic:true}]}
    ];
    snapshot.cubbies[child].mods.push({id:"restart-artwork",type:"artwork",x:350,y:20,w:120,h:100,profile:"slim",record:{id:"restart-picture",name:"River.png",r:23,representation:"artwork",variant:"artwork/estuary",kind:"Image",synthetic:true}});
    snapshot.caseItems.push({id:"restart-carried",name:"Vessel.stl",r:23,representation:"sculpture",variant:"sculpture/jar",originCubbyId:child,originModuleId:board.id,originPlacement:{kind:"object",x:90,scale:.86,support:"plinth"},originStale:true,moveMode:"cut"});
    Core.session(snapshot);
    return {snapshot,child,view:{path:["root",child],theme:2,cameras:{root:{zoom:1.2,x:7,y:-9},[child]:{zoom:.85,x:13,y:17}},cubbyPreviewMode:"inventory",snapEnabled:true,showGrid:false,snapDistance:35}};
}
