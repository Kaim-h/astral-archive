import QtQuick
import Quickshell
import "../themes" as Themes
import "../widgets" as Widgets

// A separate LayerShell surface, not a new window manager or an Electron view.
// No exclusive zone. Hidden mode has only a small left-hand restore tab.
// Does not modify the wallpaper service or the established Archive capsule.
Scope {
    id: gallery
    property var viewer: null
    property var catalogue: null
    property var editor: null
    readonly property var palette: Themes.Theme.current
    readonly property string themeKey: String(palette.name||"Twilight").toLowerCase()
    readonly property real designScale: .8
    property string displayMode: "hidden"  // full, music, hidden
    property bool focusing: false
    property var openingSnapshot: null
    property bool scopeIdle: true
    property real yaw: 20
    property real pitch: 33
    property real searchElapsed: 0
    property int searchStop: 0
    property real fromYaw: 20
    property real fromPitch: 33
    property bool waitingOnSky: false
    readonly property var searchStops: [[-12,30],[29,44],[-18,38],[19,26],[30,35],[20,33]]

    function toggleGallery(){if(displayMode==="hidden")openGallery();else hideGallery();}
    function openGallery(){ if(focusing)return;displayMode="full"; }
    function hideGallery(){ if(focusing)return; displayMode="hidden"; }
    function musicOnly(){ if(focusing)return;displayMode="music"; }
    function showTower(){ if(focusing)return;displayMode="full"; }
    function requestFocus(){
        if(focusing || displayMode==="hidden" || !viewer || viewer.phase!=="idle" ||
                (editor && editor.opened) || (catalogue && !catalogue.initialized))return;
        focusing=true;setIdle(false);
        openingSnapshot=catalogue ? catalogue.prepareOpening()
            : {artId:"",source:"",title:"Gallery artwork",artist:"",constellations:[],sky:null};
        scopeToFocus.stop();scopeToFocus.start();
    }
    function completeReturn(){
        // Reopen music after the reverse fullscreen reveal is finished.
        scopeToRest.stop();scopeToRest.start();
    }
    function beginNextSearch(){
        if(!scopeIdle||focusing||displayMode==="hidden")return;
        fromYaw=yaw;fromPitch=pitch;searchElapsed=0;
        searchClock.start();
    }
    function setIdle(active){
        scopeIdle=active;searchClock.stop();searchRest.stop();
        if(active)beginNextSearch();
    }

    Timer {
        id:searchClock
        interval:100;repeat:true
        running:false
        onTriggered:{
            gallery.searchElapsed+=100;
            var t=Math.min(1,gallery.searchElapsed/21000);
            var eased=t<.5?2*t*t:1-2*(1-t)*(1-t);
            var next=gallery.searchStops[gallery.searchStop%gallery.searchStops.length];
            gallery.yaw=gallery.fromYaw+(next[0]-gallery.fromYaw)*eased;
            gallery.pitch=gallery.fromPitch+(next[1]-gallery.fromPitch)*eased;
            if(t>=1){
                stop();gallery.searchStop++;searchRest.start();
            }
        }
    }
    Timer {
        id:searchRest;interval:5000;repeat:false
        onTriggered:gallery.beginNextSearch()
    }
    ParallelAnimation {
        id:scopeToFocus
        NumberAnimation {target:gallery;property:"yaw";to:60;duration:1450;easing.type:Easing.InOutCubic}
        NumberAnimation {target:gallery;property:"pitch";to:30;duration:1450;easing.type:Easing.InOutCubic}
        onFinished:{lensGlow.start();skyBegin.start();}
    }
    Timer {
        id:skyBegin
        interval:1170;repeat:false
        onTriggered:{
            var shot=gallery.openingSnapshot;
            if(gallery.focusing && gallery.viewer && shot){
                gallery.viewer.openGallery(shot.source,shot.title,shot.artist,shot);
            } else if(gallery.focusing) {
                gallery.completeReturn();
            }
        }
    }
    ParallelAnimation {
        id:scopeToRest
        NumberAnimation {target:gallery;property:"yaw";to:20;duration:1450;easing.type:Easing.InOutCubic}
        NumberAnimation {target:gallery;property:"pitch";to:33;duration:1450;easing.type:Easing.InOutCubic}
        onFinished:{gallery.openingSnapshot=null;gallery.focusing=false;gallery.setIdle(true);}
    }
    SequentialAnimation {
        id:lensGlow
        PropertyAction {target:glint;property:"opacity";value:1}
        ParallelAnimation {
            NumberAnimation {target:glint;property:"scale";from:.2;to:1.10;duration:520;easing.type:Easing.OutCubic}
            NumberAnimation {target:glint;property:"glow";from:0;to:1;duration:520}
        }
        ParallelAnimation {
            NumberAnimation {target:glint;property:"scale";from:1.10;to:.18;duration:1110;easing.type:Easing.InOutQuad}
            NumberAnimation {target:glint;property:"glow";from:1;to:0;duration:1110}
        }
        PropertyAction {target:glint;property:"opacity";value:0}
    }
    Connections {
        target:gallery.viewer
        ignoreUnknownSignals:true
        function onGalleryDismissed(){gallery.completeReturn();}
    }

    PanelWindow {
        id:window
        anchors {left:true;top:true}
        implicitWidth:390
        implicitHeight:gallery.displayMode==="music"?188:630
        margins {
            left:0
            top:screen?Math.max(0,Math.floor((screen.height-window.implicitHeight)/2)):90
        }
        aboveWindows:true
        exclusiveZone:0
        focusable:true
        visible:gallery.displayMode!=="hidden"
        color:"transparent"
        // Parent clip is the retracting housing: dome remains when the tower
        // collapses downward; no conditional re-creation of the telescope.
        Item {
            id:viewport
            width:window.implicitWidth;height:window.implicitHeight
            clip:true
            Rectangle {anchors.fill:parent;radius:12;color:gallery.palette.background;opacity:.06}
            Item {
                id:scene
                x:12;y:15
                width:456*gallery.designScale;height:721*gallery.designScale
                // QML coordinate system is the original SVG viewBox (157,50).
                Widgets.GalleryDome {
                    id:dome
                    x:28*gallery.designScale
                    y:-30*gallery.designScale
                    scale:gallery.designScale
                    transformOrigin:Item.TopLeft
                    yaw:gallery.yaw;pitch:gallery.pitch;palette:gallery.palette
                    onSelected:gallery.requestFocus()
                }
                Widgets.GalleryDrum {
                    id:drum
                    x:87*gallery.designScale; y:203*gallery.designScale
                    scale:gallery.designScale
                    transformOrigin:Item.TopLeft
                    palette:gallery.palette
                    constellations:gallery.openingSnapshot ? gallery.openingSnapshot.constellations : (gallery.catalogue ? gallery.catalogue.selectedConstellations : [])
                    rotationFraction:gallery.rotationSeconds/900
                    // All stars, links, names, ordinal marks and seams are one
                    // cached material, rotated together in exactly 15 minutes.
                }
                Widgets.GalleryArtwork {
                    id:artworkCrop
                    x:0;y:0
                    scale:gallery.designScale
                    transformOrigin:Item.TopLeft
                    palette:gallery.palette
                    source:gallery.openingSnapshot ? gallery.openingSnapshot.source : (gallery.catalogue?gallery.catalogue.artUrl:"")
                    active:gallery.displayMode==="full" && !gallery.focusing
                    focused:gallery.focusing
                    onSelected:gallery.requestFocus()
                }
                Image {
                    id:architecture
                    x:0;y:0;width:456*gallery.designScale;height:721*gallery.designScale
                    source:Qt.resolvedUrl("../assets/gallery/architecture-"+gallery.themeKey+".svg")
                    smooth:true;asynchronous:false;fillMode:Image.Stretch
                    // The file includes the 30px arch, one Ionic column on
                    // either side, 2-stage base and short stationary dome trim.
                }
                Text {
                    x:82*gallery.designScale;y:635*gallery.designScale
                    width:292*gallery.designScale;height:22*gallery.designScale
                    text:gallery.openingSnapshot ? gallery.openingSnapshot.artist : (gallery.catalogue?gallery.catalogue.artist:"ARTIST NAME")
                    font.family:"serif";font.pixelSize:11;elide:Text.ElideRight
                    horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter
                    color:gallery.palette.text
                }
                Text {
                    x:72*gallery.designScale;y:660*gallery.designScale
                    width:310*gallery.designScale;height:25*gallery.designScale
                    text:gallery.openingSnapshot ? gallery.openingSnapshot.title : (gallery.catalogue?gallery.catalogue.title:"ARTWORK / PIECE TITLE")
                    font.family:"serif";font.pixelSize:11;elide:Text.ElideRight
                    horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter
                    color:gallery.palette.text
                }
                Widgets.GalleryMusic {
                    id:music
                    x:78.8*gallery.designScale
                    y:82.8*gallery.designScale
                    scale:gallery.designScale
                    transformOrigin:Item.TopLeft
                    palette:gallery.palette
                    active:gallery.displayMode!=="hidden"
                    opacity:gallery.focusing?0:1
                    Behavior on opacity {NumberAnimation {duration:1450;easing.type:Easing.InOutCubic}}
                }
                Item {
                    id:glint
                    property real glow:0
                    x:dome.x+gallery.designScale*(dome.lensX-33)
                    y:dome.y+gallery.designScale*(dome.lensY-33)
                    width:66*gallery.designScale;height:66*gallery.designScale
                    transformOrigin:Item.Center
                    opacity:0;scale:.2
                    Canvas {
                        anchors.fill:parent
                        onPaint:{
                            var ctx=getContext('2d');ctx.reset();ctx.clearRect(0,0,width,height);
                            var cx=width/2,cy=height/2;
                            ctx.translate(cx,cy);ctx.fillStyle=gallery.palette.text;
                            ctx.beginPath();ctx.moveTo(0,-height*.45);
                            ctx.quadraticCurveTo(width*.035,-height*.03,width*.45,0);
                            ctx.quadraticCurveTo(width*.035,height*.03,0,height*.45);
                            ctx.quadraticCurveTo(-width*.035,height*.03,-width*.45,0);
                            ctx.quadraticCurveTo(-width*.035,-height*.03,0,-height*.45);
                            ctx.fill();
                        }
                    }
                }
            }
            // Discrete icon affordances for two MINIMIZE meanings.
            Row {
                anchors.right:parent.right;anchors.rightMargin:13;anchors.top:parent.top;anchors.topMargin:12
                spacing:6
                Repeater {
                    model:["✧",gallery.displayMode==="full"?"↓":"↑","←"]
                    delegate:Rectangle {
                        required property int index
                        required property string modelData
                        width:26;height:27;radius:5;color:gallery.palette.panel
                        border.color:gallery.palette.metal
                        Text {anchors.centerIn:parent;text:modelData;color:gallery.palette.text;font.pixelSize:16}
                        MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor
                            onClicked:{
                                if(index===0){if(!gallery.focusing && gallery.editor)gallery.editor.openEditor();}
                                else if(index===2)gallery.hideGallery();
                                else if(gallery.displayMode==="full")gallery.musicOnly();
                                else gallery.showTower();
                            }
                        }
                    }
                }
            }
            Text {
                visible:gallery.displayMode==="full" && catalogue && catalogue.items.length>1
                x:80;y:window.implicitHeight-24;width:230;height:20
                color:gallery.palette.engraving
                text:"◀ PREV   ·   NEXT ▶"
                horizontalAlignment:Text.AlignHCenter
                font.pixelSize:10
                opacity:gallery.catalogue && gallery.catalogue.selectionLocked ? .4 : 1
                MouseArea {anchors.fill:parent;enabled:!!gallery.catalogue && !gallery.catalogue.selectionLocked;onClicked:if(gallery.catalogue)gallery.catalogue.step(mouseX<width/2?-1:1)}
            }
        }
        Behavior on implicitHeight {NumberAnimation {duration:650;easing.type:Easing.InOutCubic}}
    }
    // Sliding the whole panel to the left leaves a very small restore tab.
    PanelWindow {
        id:restoreTab
        anchors {left:true;top:true}
        implicitWidth:35;implicitHeight:124
        margins {left:0;top:screen?Math.max(0,Math.floor((screen.height-124)/2)):170}
        visible:gallery.displayMode==="hidden"
        aboveWindows:true;exclusiveZone:0
        color:"transparent"
        Rectangle {
            anchors.fill:parent
            radius:6;color:gallery.palette.panel;border.color:gallery.palette.metal
            Text {anchors.centerIn:parent;text:"✦\nG\nA\nL\nL\nE\nR\nY";font.pixelSize:11;color:gallery.palette.text;horizontalAlignment:Text.AlignHCenter}
            MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:gallery.openGallery()}
        }
    }

    // 15-minute drum turn. At 1Hz the skin moves only ~0.25 design px per
    // update; no 60fps animation engine is left running for an idle drum.
    property real rotationSeconds:0
    Timer {
        interval:1000;repeat:true
        running:gallery.displayMode==="full" && !gallery.focusing
        onTriggered:gallery.rotationSeconds=(gallery.rotationSeconds+1)%900
    }
    onDisplayModeChanged:{
        if(displayMode==="hidden") {searchClock.stop();searchRest.stop();}
        else if(scopeIdle && !focusing)beginNextSearch();
    }
}
