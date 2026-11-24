import QtQuick
import Quickshell

// One editor, deliberately shared by the Gallery and the full-view right-click.
// The future Gallery Rack should call openEditor() on this same component.
PanelWindow {
    id: editor
    anchors {left:true;top:true}
    implicitWidth: screen ? Math.min(670,Math.max(380,screen.width-40)) : 670
    implicitHeight:screen ? Math.min(600,Math.max(430,screen.height-40)) : 600
    margins {
        left:screen ? Math.max(0,Math.floor((screen.width-editor.implicitWidth)/2)) : 80
        top:screen ? Math.max(0,Math.floor((screen.height-editor.implicitHeight)/2)) : 80
    }
    color:'transparent';aboveWindows:true;exclusiveZone:0;focusable:true
    visible:opened
    property bool opened:false
    property var catalogue:null
    property string editingArtId: ""
    property var palette:({background:'#121e23',panel:'#263c37',metal:'#8c6e5a',engraving:'#91ada1',text:'#e6e1d8'})
    property int page:0 // 0 constellations, 1 skies
    function openEditor(expectedId) {
        if (!catalogue || !catalogue.initialized || !catalogue.currentId ||
                (expectedId !== undefined && expectedId !== catalogue.currentId)) return;
        editingArtId=catalogue.currentId;
        opened=true;page=0;
        Qt.callLater(function(){if(editor.opened)keyboard.forceActiveFocus();});
    }
    function closeEditor(){opened=false;editingArtId="";}
    Connections {
        target:editor.catalogue
        function onCurrentIdChanged() {
            if(editor.opened && editor.catalogue.currentId!==editor.editingArtId)editor.closeEditor();
        }
    }
    function selected(id) {
        return !!catalogue && catalogue.selectedIds.indexOf(id)>=0;
    }
    function skyChosen(id) {
        if (!catalogue) return false;
        return catalogue.skyMode==='cycle' ? catalogue.skyPool.indexOf(id)>=0
             : catalogue.currentSetting && catalogue.currentSetting.sky===id;
    }
    Item {
        id:keyboard;anchors.fill:parent;focus:true
        Keys.onEscapePressed:editor.closeEditor()
        Rectangle {
            anchors.fill:parent;radius:14
            color:editor.palette.panel;border.color:editor.palette.metal;border.width:2
            Rectangle {
                x:8;y:8;width:parent.width-16;height:parent.height-16
                radius:9;color:'transparent';border.color:editor.palette.engraving;opacity:.32
            }
        }
        Text {
            x:24;y:17;width:parent.width-100
            color:editor.palette.text;font.family:'serif';font.pixelSize:23
            text:'THE CELESTIAL INDEX';elide:Text.ElideRight
        }
        Text {
            x:26;y:51;width:parent.width-98
            color:editor.palette.engraving;font.pixelSize:11;elide:Text.ElideRight
            text:editor.catalogue ? editor.catalogue.title+'  ·  '+editor.catalogue.artist : ''
        }
        Rectangle {
            x:parent.width-55;y:19;width:32;height:31;radius:5
            color:editor.palette.background;border.color:editor.palette.metal
            Text {anchors.centerIn:parent;text:'×';font.pixelSize:21;color:editor.palette.text}
            MouseArea {anchors.fill:parent;onClicked:editor.closeEditor();cursorShape:Qt.PointingHandCursor}
        }
        Text {
            id:preferenceWarning
            x:26;y:68;width:parent.width-52
            visible:text.length>0
            text:editor.catalogue ? editor.catalogue.lastWarning : ""
            color:editor.palette.text;font.pixelSize:11;wrapMode:Text.WordWrap
        }
        Row {
            id:editorTabs
            x:22;y:preferenceWarning.visible?preferenceWarning.y+preferenceWarning.implicitHeight+9:80;spacing:9
            Repeater {
                model:['CONSTELLATIONS','TRANSITION SKIES']
                delegate:Rectangle {
                    required property int index
                    required property string modelData
                    width:index===0?151:166;height:31;radius:5
                    color:editor.page===index?editor.palette.background:editor.palette.panel
                    border.color:editor.page===index?editor.palette.metal:editor.palette.engraving
                    border.width:1
                    Text {anchors.centerIn:parent;text:modelData;color:editor.palette.text;font.pixelSize:10;font.letterSpacing:1}
                    MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:editor.page=index}
                }
            }
        }
        Item {
            x:23;y:editorTabs.y+42;width:parent.width-46;height:Math.max(0,parent.height-y-71);clip:true
            visible:editor.page===0
            Column {
                width:parent.width;spacing:8
                Row {
                    spacing:9;height:35
                    Text {text:'Figures displayed:';color:editor.palette.text;font.pixelSize:13;anchors.verticalCenter:parent.verticalCenter}
                    Rectangle {
                        width:33;height:30;radius:5;color:editor.palette.background;border.color:editor.palette.metal
                        Text {anchors.centerIn:parent;text:'−';font.pixelSize:20;color:editor.palette.text}
                        MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:if(editor.catalogue)editor.catalogue.changeCount(editor.catalogue.selectedCount-1)}
                    }
                    Text {text:editor.catalogue?String(editor.catalogue.selectedCount):'0';color:editor.palette.text;font.pixelSize:16;anchors.verticalCenter:parent.verticalCenter}
                    Rectangle {
                        width:33;height:30;radius:5;color:editor.palette.background;border.color:editor.palette.metal
                        Text {anchors.centerIn:parent;text:'+';font.pixelSize:19;color:editor.palette.text}
                        MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:if(editor.catalogue)editor.catalogue.changeCount(editor.catalogue.selectedCount+1)}
                    }
                    Text {text:'(1–8)';color:editor.palette.engraving;font.pixelSize:11;anchors.verticalCenter:parent.verticalCenter}
                }
                Text {
                    width:parent.width;wrapMode:Text.WordWrap
                    color:editor.palette.engraving;font.pixelSize:11
                    text:'Choose and order the figures. The same stars appear on the 15-minute drum and in the fullscreen sky.'
                }
            }
            Flickable {
                id:constellationScroll
                x:0;y:79;width:parent.width;height:parent.height-79
                clip:true;contentWidth:width;contentHeight:constellationColumn.height
                boundsBehavior:Flickable.StopAtBounds
                Column {
                    id:constellationColumn;width:constellationScroll.width;spacing:6
                    Repeater {
                        model:editor.catalogue?editor.catalogue.library:[]
                        delegate:Rectangle {
                            id:option
                            required property var modelData
                            width:constellationColumn.width;height:55;radius:6
                            color:editor.selected(modelData.id)?editor.palette.background:editor.palette.panel
                            border.color:editor.selected(modelData.id)?editor.palette.metal:editor.palette.engraving
                            border.width:1
                            Rectangle {
                                x:12;y:16;width:20;height:20;radius:3
                                color:editor.selected(option.modelData.id)?editor.palette.metal:'transparent'
                                border.color:editor.palette.engraving
                                Text {anchors.centerIn:parent;text:'✓';visible:editor.selected(option.modelData.id);color:editor.palette.background;font.pixelSize:13}
                            }
                            Text {x:44;y:6;width:parent.width-143;height:21;text:option.modelData.name
                                color:editor.palette.text;font.pixelSize:13;elide:Text.ElideRight}
                            Text {x:44;y:29;width:parent.width-143;height:16;text:option.modelData.description
                                color:editor.palette.engraving;font.pixelSize:10;elide:Text.ElideRight}
                            MouseArea {
                                anchors {left:parent.left;top:parent.top;bottom:parent.bottom;right:orderButtons.left}
                                cursorShape:Qt.PointingHandCursor
                                onClicked:if(editor.catalogue)editor.catalogue.toggleConstellation(option.modelData.id)
                            }
                            Row {
                                id:orderButtons;x:parent.width-88;y:10;spacing:5
                                visible:editor.selected(option.modelData.id)
                                Repeater {
                                    model:['↑','↓']
                                    delegate:Rectangle {
                                        required property int index
                                        required property string modelData
                                        width:36;height:34;radius:4;color:editor.palette.panel;border.color:editor.palette.metal
                                        Text {anchors.centerIn:parent;color:editor.palette.text;font.pixelSize:16;text:modelData}
                                        MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor
                                            onClicked:if(editor.catalogue)editor.catalogue.moveConstellation(option.modelData.id,index===0?-1:1)}
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        Item {
            x:23;y:editorTabs.y+42;width:parent.width-46;height:Math.max(0,parent.height-y-71);clip:true
            visible:editor.page===1
            Row {
                spacing:12;height:36
                Rectangle {
                    id:fixedMode;width:125;height:30;radius:5
                    color:editor.catalogue&&editor.catalogue.skyMode==='fixed'?editor.palette.background:editor.palette.panel
                    border.color:editor.palette.metal
                    Text {anchors.centerIn:parent;text:'ONE SKY';color:editor.palette.text;font.pixelSize:11}
                    MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:if(editor.catalogue)editor.catalogue.setSkyMode('fixed')}
                }
                Rectangle {
                    width:170;height:30;radius:5
                    color:editor.catalogue&&editor.catalogue.skyMode==='cycle'?editor.palette.background:editor.palette.panel
                    border.color:editor.palette.metal
                    Text {anchors.centerIn:parent;text:'CYCLE SELECTED SKIES';color:editor.palette.text;font.pixelSize:11}
                    MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:if(editor.catalogue)editor.catalogue.setSkyMode('cycle')}
                }
            }
            Text {
                y:41;width:parent.width;height:40;wrapMode:Text.WordWrap
                text:editor.catalogue&&editor.catalogue.skyMode==='cycle'
                    ? 'Choose the skies in the cycle. One advances each time you open this artwork.'
                    : 'Choose one fixed transition sky. This is the default, so the artwork stays recognizable.'
                font.pixelSize:11;color:editor.palette.engraving
            }
            Flickable {
                id:skiesScroll;y:86;width:parent.width;height:parent.height-86
                contentWidth:width;contentHeight:skyColumn.height;clip:true
                boundsBehavior:Flickable.StopAtBounds
                Column {
                    id:skyColumn;spacing:8;width:skiesScroll.width
                    Repeater {
                        model:editor.catalogue?editor.catalogue.skies:[]
                        delegate:Rectangle {
                            id:skyTile
                            required property var modelData
                            width:skyColumn.width;height:70;radius:7
                            color:editor.palette.panel
                            border.color:editor.skyChosen(modelData.id)?editor.palette.metal:editor.palette.engraving
                            border.width:editor.skyChosen(modelData.id)?2:1
                            Rectangle {
                                x:8;y:8;width:93;height:54;radius:4
                                color:skyTile.modelData.id==='theme'?editor.palette.background:skyTile.modelData.background
                                border.color:skyTile.modelData.id==='theme'?editor.palette.engraving:skyTile.modelData.accent
                                Rectangle {x:16;y:12;width:3;height:3;radius:2;color:skyTile.modelData.id==='theme'?editor.palette.engraving:skyTile.modelData.accent}
                                Rectangle {x:57;y:31;width:2;height:2;radius:1;color:skyTile.modelData.id==='theme'?editor.palette.engraving:skyTile.modelData.accent}
                                Rectangle {x:70;y:14;width:2;height:2;radius:1;color:skyTile.modelData.id==='theme'?editor.palette.engraving:skyTile.modelData.accent}
                                Rectangle {x:37;y:40;width:2;height:2;radius:1;color:skyTile.modelData.id==='theme'?editor.palette.engraving:skyTile.modelData.accent}
                            }
                            Text {x:114;y:10;width:parent.width-160;height:23;color:editor.palette.text
                                text:skyTile.modelData.name;font.pixelSize:14;elide:Text.ElideRight}
                            Text {x:114;y:35;width:parent.width-160;height:20;color:editor.palette.engraving
                                text:skyTile.modelData.description;font.pixelSize:10;elide:Text.ElideRight}
                            Text {anchors.right:parent.right;anchors.rightMargin:14;anchors.verticalCenter:parent.verticalCenter
                                text:editor.skyChosen(skyTile.modelData.id)?'✓':'+';font.pixelSize:18;color:editor.palette.metal}
                            MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor
                                onClicked:{if(!editor.catalogue)return;
                                    if(editor.catalogue.skyMode==='cycle')editor.catalogue.toggleSkyPool(skyTile.modelData.id);
                                    else editor.catalogue.chooseSky(skyTile.modelData.id);}}
                        }
                    }
                }
            }
        }
        Rectangle {
            x:23;y:parent.height-60;width:parent.width-46;height:1;color:editor.palette.metal;opacity:.55
        }
        Row {
            x:23;y:parent.height-48;spacing:11
            Rectangle {
                width:152;height:33;radius:5;color:editor.palette.background;border.color:editor.palette.metal
                Text {anchors.centerIn:parent;text:'RESET THIS ARTWORK';color:editor.palette.text;font.pixelSize:10}
                MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:if(editor.catalogue)editor.catalogue.resetCurrent()}
            }
            Rectangle {
                width:107;height:33;radius:5;color:editor.palette.background;border.color:editor.palette.metal
                Text {anchors.centerIn:parent;text:'DONE';color:editor.palette.text;font.pixelSize:12}
                MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:editor.closeEditor()}
            }
            Text {text:editor.catalogue && editor.catalogue.preferencesWritable && !editor.catalogue.lastWarning?'Saved per artwork':'See preference status';color:editor.palette.engraving;font.pixelSize:10;anchors.verticalCenter:parent.verticalCenter}
        }
    }
}
