import QtQuick
import "ArchiveAppearance.mjs" as Appearance
Column {
 id:options
 required property var colors
 property var room:null
 property var patch:({})
 signal changed(string key,var value)
 spacing:5
 function local(key){return Object.prototype.hasOwnProperty.call(patch,key)?patch[key]:key==="name"?room&&room.name:room&&room.appearance?room.appearance[key]:undefined}
 function value(key){var v=local(key);return v===null||v===undefined?Appearance.roomDefaults[key]:v}
 function choices(values,labels){return values.map((v,i)=>({key:v,label:labels?labels[i]:String(v)}))}
 ArchiveChoice {width:parent.width;colors:options.colors;title:"Floor";prefix:"room-floor";value:options.value("floor");options:options.choices(Appearance.floorStyles,["Matte stone","Square flagstone","Running bond","Diagonal flagstone","Octagon and dot","Hexagonal stone","Herringbone stone","Basketweave stone","Mixed ashlar"]);onSelected:function(v){options.changed("floor",v)}}
 Text {text:"Name";color:options.colors.engraving}
 TextInput {objectName:"room-appearance-name";width:parent.width;color:options.colors.text;selectByMouse:true;text:options.local("name")||"";onTextEdited:options.changed("name",text)}
 ArchiveChoice {width:parent.width;colors:options.colors;title:"Palette";prefix:"room-palette";value:options.local("palette")===undefined?null:options.local("palette");options:options.choices([null,0,1,2],["Desktop","Evening","Twilight","Midnight"]);onSelected:function(v){options.changed("palette",v)}}
 ArchiveChoice {width:parent.width;colors:options.colors;title:"Family";prefix:"room-family";value:options.local("family")===undefined?null:options.local("family");options:options.choices([null,"None","Architectural","Astral","Botanical","Bestiary","Elemental · Water","Elemental · Air","Elemental · Earth","Elemental · Fire","Horological"],["Inherit","None","Architectural","Astral","Botanical","Bestiary","Water","Air","Earth","Fire","Horological"]);onSelected:function(v){options.changed("family",v)}}
 ArchiveChoice {width:parent.width;colors:options.colors;title:"Walls";prefix:"room-wall";value:options.value("wall");options:options.choices(Appearance.wallStyles,["Plain dressed stone","Recessed panels","Coursed ashlar","Mixed ashlar","Pilastered bays","Blind arcade","Stone dado","Fluted panels"]);onSelected:function(v){options.changed("wall",v)}}
 ArchiveButton {objectName:"room-floor-border";colors:options.colors;label:"Floor border";active:!!options.value("floorBorder");onClicked:options.changed("floorBorder",!active)}
 ArchiveButton {objectName:"room-wall-marks";colors:options.colors;label:"Wall marks";active:!!options.value("wallMarks");onClicked:options.changed("wallMarks",!active)}
 ArchiveChoice {width:parent.width;colors:options.colors;title:"Border style";prefix:"room-border";value:options.value("borderStyle");options:options.choices(["single","double","band","diamond"]);onSelected:function(v){options.changed("borderStyle",v)}}
 ArchiveChoice {width:parent.width;colors:options.colors;title:"Floor angle";prefix:"room-angle";value:options.value("floorAngle");options:options.choices([0,45,90]);onSelected:function(v){options.changed("floorAngle",v)}}
 Repeater {
  model:[{key:"detail",label:"Detail"},{key:"floorScale",label:"Stone size"},{key:"grout",label:"Grout"},{key:"variation",label:"Variation"},{key:"wallScale",label:"Wall bay"}]
  Column {
   required property var modelData
   width:options.width
   Text {text:parent.modelData.label;color:options.colors.engraving}
   TextInput {objectName:"room-appearance-"+parent.modelData.key;width:parent.width;color:options.colors.text;selectByMouse:true;text:String(options.value(parent.modelData.key));onTextEdited:options.changed(parent.modelData.key,text.trim()===""?"":Number.isFinite(Number(text))?Number(text):text)}
  }
 }
}
