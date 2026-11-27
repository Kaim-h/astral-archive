import QtQuick
import "ArchiveAppearance.mjs" as Appearance
import "ArchiveView.mjs" as View
import "ArchiveCore.mjs" as Core
import "ArchiveSpatial.mjs" as Spatial

// Existing revision-bound proposal is the only source of document edits.
Column {
    id:editor
    required property var colors
    required property var snapshot
    required property var proposal
    required property int desktopPalette
    property string tab:"basic"
    signal changed(string key,var value)
    readonly property string target:proposal&&proposal.command.containerId||""
    readonly property var container:snapshot.cubbies[target]||null
    readonly property bool shelf:!!container&&Spatial.kind(snapshot,target)==="shelf"
    readonly property var base:container&&container.appearance||({})
    readonly property var patch:proposal&&proposal.command.patch||({})
    readonly property string family:patch.family!==undefined&&patch.family!==null?patch.family:
        proposal&&proposal.snapshot&&container?Spatial.resolveAppearance(proposal.snapshot,target,desktopPalette).family:
        container?Spatial.resolveAppearance(snapshot,target,desktopPalette).family:"None"
    readonly property var entries:Appearance.emblems(family)
    property string selectedField:""
    property var fieldText:({})
    readonly property var fields:Array.isArray(value("fields"))?value("fields"):[]
    readonly property var field:fields.find(f=>f.id===selectedField)||null
    readonly property bool editingField:!!field
    spacing:5
    function value(key){return Object.prototype.hasOwnProperty.call(patch,key)?patch[key]:base[key]===undefined?null:base[key]}
    function choices(values){return [{key:null,label:"Default / inherit"}].concat(values.map(v=>({key:v,label:v.charAt(0).toUpperCase()+v.slice(1)})))}
    function fieldValue(key){return field&&field[key]!==undefined?field[key]:null}
    function updateField(key,value){
        if(!field)return
        var next=Core.clone(fields),item=next.find(f=>f.id===selectedField);item[key]=value;changed("fields",next)
    }
    function fieldNumber(key,text){
        var raw=Object.assign({},fieldText);raw[key]=text;fieldText=raw
        var n=/^-?(?:[0-9]+(?:\.[0-9]+)?|\.[0-9]+)$/.test(text)?Number(text):null
        updateField(key,Number.isFinite(n)?n:null)
    }
    function addField(){
        if(!container||proposal.error)return
        var f=Appearance.suggestField(fields,container.w,container.h)
        if(!f)return
        fieldText={};selectedField=f.id;changed("fields",fields.concat([f]))
    }
    function removeField(){
        if(!field)return
        var next=fields.filter(f=>f.id!==selectedField)
        selectedField=next.length?next[0].id:"";fieldText={};changed("fields",next)
    }
    onTargetChanged:{selectedField="";fieldText={};if(emblemScroll)emblemScroll.resetPosition()}
    onFamilyChanged:if(emblemScroll)emblemScroll.resetPosition()
    onTabChanged:if(tab==="emblems"&&emblemScroll)emblemScroll.resetPosition()
    Column {
        visible:editor.tab==="materials";width:editor.width;spacing:5
        ArchiveChoice {width:parent.width;colors:editor.colors;prefix:"appearance-frame";title:"Frame material";options:editor.choices(Appearance.materialRoles);value:editor.value("frame");onSelected:function(v){editor.changed("frame",v)}}
        ArchiveChoice {width:parent.width;colors:editor.colors;prefix:"appearance-backing";title:"Backing material";options:editor.choices(Appearance.materialRoles);value:editor.value("backing");onSelected:function(v){editor.changed("backing",v)}}
    }
    Column {
        visible:editor.tab==="emblems";width:editor.width;spacing:5
        Text {text:editor.family+" · "+editor.entries.length+" primary emblems";color:editor.colors.text;font.pixelSize:11}
        ArchiveButton {objectName:"appearance-emblem-default";width:parent.width;colors:editor.colors;label:"Family default";active:editor.value("emblem")===null;onClicked:editor.changed("emblem",null)}
        ArchiveInspectorScroll {
            id:emblemScroll;objectName:"appearance-emblem-gallery"
            width:parent.width;height:152;contentHeight:emblemGrid.implicitHeight
            Grid {
                id:emblemGrid;width:emblemScroll.width;columns:2;spacing:4
                Repeater {
                    model:editor.tab==="emblems"?editor.entries:[]
                    ArchiveButton {
                        required property var modelData
                        objectName:"appearance-emblem-"+modelData.id
                        colors:editor.colors;width:(emblemGrid.width-4)/2;height:74
                        label:"";hint:modelData.name
                        active:!!Appearance.emblem(editor.family,editor.value("emblem"))&&Appearance.emblem(editor.family,editor.value("emblem")).id===modelData.id
                        ArchiveFamilyMark {
                            family:editor.family;emblemKey:parent.modelData.id;colors:editor.colors
                            anchors.centerIn:undefined;anchors.horizontalCenter:parent.horizontalCenter;anchors.top:parent.top;anchors.topMargin:3
                            width:42;height:42;opacity:1
                        }
                        Text {anchors.bottom:parent.bottom;anchors.bottomMargin:5;width:parent.width-6;anchors.horizontalCenter:parent.horizontalCenter;text:parent.modelData.name;color:editor.colors.text;font.pixelSize:10;elide:Text.ElideRight;horizontalAlignment:Text.AlignHCenter}
                        onClicked:editor.changed("emblem",modelData.id)
                    }
                }
            }
        }
        Row {
            spacing:4
            ArchiveButton {colors:editor.colors;label:"‹ Previous";enabled:emblemScroll.contentY>1;onClicked:emblemScroll.contentY=Math.max(0,emblemScroll.contentY-156)}
            ArchiveButton {colors:editor.colors;label:"Next ›";enabled:emblemScroll.contentY+emblemScroll.height<emblemScroll.contentHeight-1;onClicked:emblemScroll.contentY=Math.min(emblemScroll.contentHeight-emblemScroll.height,emblemScroll.contentY+156)}
        }
    }
    Column {
        visible:editor.tab==="backing";width:editor.width;spacing:5
        ArchiveChoice {width:parent.width;colors:editor.colors;prefix:"appearance-border";title:"Border";options:editor.choices(Appearance.borderStyles);value:editor.value("border");onSelected:function(v){editor.changed("border",v)}}
        ArchiveChoice {width:parent.width;colors:editor.colors;prefix:"appearance-center";title:"Center composition";options:editor.choices(Appearance.centerStyles);value:editor.value("center");onSelected:function(v){editor.changed("center",v)}}
        Text {text:"Independent engraving fields · "+editor.fields.length+"/16";color:editor.colors.engraving;font.pixelSize:11}
        Row {
            spacing:4
            ArchiveButton {objectName:"appearance-field-add";colors:editor.colors;label:"Add field";enabled:!!editor.proposal&&!editor.proposal.error&&editor.fields.length<16;onClicked:editor.addField()}
            ArchiveButton {objectName:"appearance-field-reset";colors:editor.colors;label:"Default field";onClicked:{editor.selectedField="";editor.fieldText={};editor.changed("fields",null)}}
        }
        ArchiveChoice {
            visible:editor.fields.length>0;width:parent.width;colors:editor.colors
            prefix:"appearance-field";title:"Select field";value:editor.selectedField
            options:editor.fields.map(f=>({key:f.id,label:f.id}))
            onSelected:function(v){if(!editor.proposal.error){editor.selectedField=v;editor.fieldText={}}}
        }
        Column {
            visible:!!editor.field;width:parent.width;spacing:4
            Repeater {
                model:editor.editingField?["x","y","w","h","opacity"]:[]
                Row {
                    required property string modelData
                    width:editor.width;spacing:5
                    Text {width:70;text:parent.modelData==="opacity"?"Strength":parent.modelData.toUpperCase();color:editor.colors.engraving;font.pixelSize:11;anchors.verticalCenter:parent.verticalCenter}
                    Rectangle {
                        width:108;height:26;radius:3;color:editor.colors.background;border.color:editor.colors.metal
                        TextInput {
                            objectName:"appearance-field-input-"+parent.parent.modelData
                            anchors.fill:parent;anchors.margins:4;clip:true;maximumLength:12
                            color:editor.colors.text;font.pixelSize:11
                            text:editor.fieldText[parent.parent.modelData]!==undefined?editor.fieldText[parent.parent.modelData]:String(editor.fieldValue(parent.parent.modelData))
                            onTextEdited:editor.fieldNumber(parent.parent.modelData,text)
                            Accessible.name:"Field "+parent.parent.modelData
                        }
                    }
                }
            }
            ArchiveChoice {
                width:parent.width;colors:editor.colors;prefix:"appearance-field-family";title:"Field family"
                options:View.ornamentFamilies;value:editor.fieldValue("family")
                onSelected:function(v){editor.updateField("family",v)}
            }
            ArchiveChoice {
                width:parent.width;colors:editor.colors;prefix:"appearance-field-emblem";title:"Field emblem"
                options:[{key:null,label:"Default / inherit"}].concat(Appearance.emblems(editor.fieldValue("family")||editor.family).map(e=>({key:e.id,label:e.name})))
                value:editor.fieldValue("emblem");onSelected:function(v){editor.updateField("emblem",v)}
            }
            ArchiveChoice {width:parent.width;colors:editor.colors;prefix:"appearance-field-border";title:"Field border";options:editor.choices(Appearance.borderStyles);value:editor.fieldValue("border");onSelected:function(v){editor.updateField("border",v)}}
            ArchiveChoice {width:parent.width;colors:editor.colors;prefix:"appearance-field-center";title:"Field center";options:editor.choices(Appearance.centerStyles);value:editor.fieldValue("center");onSelected:function(v){editor.updateField("center",v)}}
            ArchiveButton {objectName:"appearance-field-remove";colors:editor.colors;label:"Remove field";onClicked:editor.removeField()}
        }
    }
    Column {
        visible:editor.tab==="glazing";width:editor.width;spacing:5
        Text {width:parent.width;wrapMode:Text.WordWrap;text:editor.shelf?"Default for nested Cubbies without a local override.":"Local Cubby only. Reset to use the enclosing Shelf default.";color:editor.colors.engraving;font.pixelSize:11}
        ArchiveChoice {
            width:parent.width;colors:editor.colors;prefix:"appearance-glazing";title:"Satin glazing"
            options:editor.choices(Appearance.glazingStyles);value:editor.value(editor.shelf?"glazingDefault":"glazing")
            onSelected:function(v){editor.changed(editor.shelf?"glazingDefault":"glazing",v)}
        }
    }
}
