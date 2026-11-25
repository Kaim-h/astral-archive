import * as Core from "../archive/ArchiveCore.mjs";
import * as View from "../archive/ArchiveView.mjs";
export function fixture(){
    const s=View.fixture(),root=s.cubbies.root;root.w=1400;root.h=820;root.name="The Main Hall · mixed study";
    const record=(id,name,representation,variant,kind)=>({id,name,r:13,representation,variant,kind,size:"Synthetic sample",synthetic:true});
    root.mods.push({id:"mixed-art",type:"artwork",x:830,y:40,w:180,h:140,profile:"stone",record:record("mixed-picture","Moonlit.png","artwork","artwork/moonlit-mountains","Image")},
        {id:"mixed-board",type:"shelf",x:550,y:470,w:800,h:15,items:[
            {kind:"object",x:90,scale:.86,support:"plinth",record:record("mixed-jar","Vessel.stl","sculpture","sculpture/jar","3D model")},
            {kind:"object",x:285,scale:.86,support:"tray",record:record("mixed-parcel","Notes.zip","parcel","parcel/satchel","Archive")},
            {kind:"holder",id:"mixed-upright",x:400,w:130,scale:.86,slots:[record("mixed-audio","Nocturne.flac","record","record/v1","Audio"),null,record("mixed-font","Astral.otf","tablet","tablet/v1","Font")]}
        ]},{id:"mixed-lower",type:"shelf",x:550,y:760,w:800,h:15,items:[
            {kind:"object",x:680,scale:.86,support:"shelf",record:record("mixed-owl","Owl.obj","sculpture","sculpture/owl","3D model")}
        ]});
    const error=Core.validate(s);if(error)throw Error(error);return s;
}
