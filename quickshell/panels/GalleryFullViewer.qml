import QtQuick
import Quickshell
import Quickshell.Io
import "../widgets" as Widgets
import "../services/GalleryPolicy.js" as Policy

// Full-screen Gallery layer. The shader is genuinely fullscreen (not a tiny
// Gallery canvas stretched to fit). A compiled Qt shader is optional; if it
// isn't available, opening/closing remains functional with a plain star veil.
PanelWindow {
    id: viewer
    anchors { left: true;right: true;top: true;bottom: true }
    aboveWindows: true
    exclusiveZone: 0
    focusable: true
    visible: phase!=="idle"
    color: "transparent"

    property string phase: "idle" // idle, reveal, artwork, closing
    property string artworkId: ""
    property url imageSource: ""
    property string artworkTitle: ""
    property string artistName: ""
    property real progress: 0
    property real viewerOpacity: 0
    property var palette: ({background:"#121e23",panel:"#263c37",metal:"#8c6e5a",engraving:"#91ada1",text:"#e6e1d8"})
    property bool shaderPrepared: false
    readonly property bool shaderUsable: !!(shaderPrepared && shaderLayer.item &&
        shaderLayer.item.status === ShaderEffect.Compiled)
    property var catalogue: null
    property var editor: null
    // Frozen on scope focus. Editing the artwork never retargets an in-flight reveal.
    property var constellationsSnapshot: []
    property var skySnapshot: null
    readonly property var seedLayout: Policy.skySeeds(constellationsSnapshot,keySurface.width,keySurface.height)
    readonly property real colonySeedCount: seedLayout.length
    readonly property vector4d colonySeedsA: seedPair(seedLayout,0)
    readonly property vector4d colonySeedsB: seedPair(seedLayout,2)
    readonly property vector4d colonySeedsC: seedPair(seedLayout,4)
    readonly property vector4d colonySeedsD: seedPair(seedLayout,6)
    readonly property color skyBackground:skySnapshot&&skySnapshot.id!=="theme"?skySnapshot.background:palette.background
    readonly property color skyAccent:skySnapshot&&skySnapshot.id!=="theme"?skySnapshot.accent:palette.engraving
    readonly property color skySecondary:skySnapshot&&skySnapshot.id!=="theme"?skySnapshot.secondary:palette.panel
    readonly property real skyIndex:skySnapshot?skySnapshot.mode:0
    signal galleryDismissed()

    readonly property string compiledShaderPath: {
        var s=String(Qt.resolvedUrl("../shaders/gallery-colonies.frag.qsb"));
        return s.startsWith("file://")?decodeURIComponent(s.substring(7)):"";
    }
    Process {
        id: shaderCheck
        command: ["test","-s",viewer.compiledShaderPath]
        onExited: function(code,status) { viewer.shaderPrepared=(code===0); }
    }
    Component.onCompleted: shaderCheck.running=true
    function seedPair(seeds,index) {
        // The shader generates its own filler seeds beyond colonySeedCount.
        var a=seeds[index] || [0,0], b=seeds[index+1] || [0,0];
        return Qt.vector4d(a[0],a[1],b[0],b[1]);
    }
    function openGallery(source,title,artist,presentation) {
        artworkId=presentation && presentation.artId ? presentation.artId : "";
        reveal.stop();reverse.stop();
        var shot=presentation||{constellations:[],sky:null};
        constellationsSnapshot=shot.constellations||[];
        skySnapshot=shot.sky||null;
        imageSource=source;artworkTitle=title;artistName=artist;
        progress=0;viewerOpacity=0;phase="reveal";
        reveal.start();
        Qt.callLater(function(){if(viewer.phase!=="idle")keySurface.forceActiveFocus();});
    }
    function closeGallery() {
        if(phase!=="artwork")return;
        if(editor && editor.opened)editor.closeEditor();
        phase="closing";
        viewerOpacity=0;reverse.start();
    }
    function editViewedArtwork() {
        if(phase==="artwork" && artworkId && editor)editor.openEditor(artworkId);
    }
    function finish() {
        if(editor && editor.opened)editor.closeEditor();
        artworkId="";phase="idle";progress=0;viewerOpacity=0;galleryDismissed();
    }
    NumberAnimation {
        id:reveal
        target:viewer;property:"progress";from:0;to:1;duration:1600
        easing.type:Easing.Linear
        onFinished: { viewer.phase="artwork";viewer.viewerOpacity=1; }
    }
    NumberAnimation {
        id:reverse
        target:viewer;property:"progress";from:1;to:0;duration:1250
        easing.type:Easing.Linear
        onFinished: viewer.finish()
    }
    Item {
        id:keySurface
        anchors.fill:parent
        focus:true
        Keys.onEscapePressed: {
            if (viewer.editor && viewer.editor.opened) viewer.editor.closeEditor();
            else viewer.closeGallery();
        }
        Keys.onPressed: function(event) {
            if (event.key===Qt.Key_C && viewer.phase==="artwork") {
                viewer.editViewedArtwork();
                event.accepted=true;
            }
        }
        // Keep the canonical constellation map in a captured texture so its
        // paths obey the EXACT SAME 1px colony mask as the sky background.
        Widgets.GallerySkyMap {
            id:skyGeometry
            anchors.fill:parent
            constellations:viewer.constellationsSnapshot
            strokeColor:viewer.skyAccent
            starColor:viewer.palette.text
        }
        ShaderEffectSource {
            id:skyTexture
            anchors.fill:parent
            sourceItem:skyGeometry
            hideSource:true
            live:true
            visible:false
        }
        Loader {
            id:shaderLayer
            anchors.fill:parent
            active:viewer.visible&&viewer.shaderPrepared
            sourceComponent:Component {
                ShaderEffect {
                    property real progress: viewer.progress
                    property real screenWidth: Math.max(1,width)
                    property real screenHeight: Math.max(1,height)
                    property real seed: 27.4
                    property real skyMode: viewer.skyIndex
                    property real seedCount: viewer.colonySeedCount
                    property color accent: viewer.skyAccent
                    property color backdrop: viewer.skyBackground
                    property color secondary: viewer.skySecondary
                    property vector4d seedsA: viewer.colonySeedsA
                    property vector4d seedsB: viewer.colonySeedsB
                    property vector4d seedsC: viewer.colonySeedsC
                    property vector4d seedsD: viewer.colonySeedsD
                    property var constellationTexture:skyTexture
                    fragmentShader: Qt.resolvedUrl("../shaders/gallery-colonies.frag.qsb")
                }
            }
        }
        // Explicit non-shader fallback, not falsely advertised as pixel colonies.
        Rectangle {
            anchors.fill:parent
            visible:!viewer.shaderUsable
            color:viewer.skyBackground
            opacity:viewer.progress
            Canvas {
                anchors.fill:parent
                visible:parent.visible
                onPaint: {
                    var ctx=getContext('2d');ctx.reset();ctx.clearRect(0,0,width,height);
                    for(var i=0;i<160;i++){
                        var x=((i*173+73)%997)/997*width;
                        var y=((i*307+19)%991)/991*height;
                        ctx.fillStyle=i%9===0?'#e5dbbe':'#91ada1';
                        ctx.globalAlpha=.28+(i%7)*.075;
                        ctx.fillRect(x,y,1.3,1.3);
                    }
                    ctx.globalAlpha=1;
                }
            }
        }
        // Without qsb, fall back to a simple veil and the same star chart.
        // This is intentionally NOT described as the 1px colony transition.
        Widgets.GallerySkyMap {
            anchors.fill:parent
            constellations:viewer.constellationsSnapshot
            strokeColor:viewer.skyAccent
            starColor:viewer.palette.text
            visible:viewer.phase!=="idle" && !viewer.shaderUsable
            opacity:viewer.progress*.85
        }
        // Image remains physically contained; frame hugs *painted* image,
        // not a preselected portrait/landscape/square aspect-ratio box.
        Image {
            id:fullImage
            anchors.centerIn:parent
            width:Math.max(1,parent.width*.86)
            height:Math.max(1,parent.height*.82)
            source:viewer.imageSource
            asynchronous:true;cache:false
            fillMode:Image.PreserveAspectFit
            visible:viewer.phase==="artwork"||viewer.phase==="closing"
            opacity:viewer.viewerOpacity
        }
        MouseArea {
            x:fullImage.x+(fullImage.width-fullImage.paintedWidth)/2
            y:fullImage.y+(fullImage.height-fullImage.paintedHeight)/2
            width:fullImage.paintedWidth;height:fullImage.paintedHeight
            acceptedButtons:Qt.RightButton
            enabled:viewer.phase==="artwork"
            cursorShape:Qt.PointingHandCursor
            onClicked:viewer.editViewedArtwork()
        }
        Rectangle {
            visible:fullImage.visible&&fullImage.status===Image.Ready
            x:fullImage.x+(fullImage.width-fullImage.paintedWidth)/2-3
            y:fullImage.y+(fullImage.height-fullImage.paintedHeight)/2-3
            width:fullImage.paintedWidth+6;height:fullImage.paintedHeight+6
            color:"transparent";border.color:viewer.palette.metal;border.width:3
            opacity:fullImage.opacity
        }
        Text {
            anchors.centerIn:parent
            visible:viewer.phase==="artwork"&&fullImage.status!==Image.Ready
            text:String(viewer.imageSource).length?"Gallery artwork unavailable":"No Gallery artwork selected"
            color:viewer.palette.text;font.pixelSize:15
        }
        Rectangle {
            anchors.bottom:parent.bottom;anchors.bottomMargin:24
            anchors.horizontalCenter:parent.horizontalCenter
            width:Math.min(560,parent.width-48);height:55;radius:7
            color:viewer.palette.panel;opacity:viewer.viewerOpacity*.92
            border.color:viewer.palette.metal
            Text {anchors.centerIn:parent;text:viewer.artworkTitle+"   ·   "+viewer.artistName
                color:viewer.palette.text;font.family:"serif";font.pixelSize:15;elide:Text.ElideRight;width:parent.width-24;horizontalAlignment:Text.AlignHCenter}
        }
        Rectangle {
            x:parent.width-144;y:22;width:57;height:37;radius:6
            visible:viewer.phase==="artwork" && !!viewer.artworkId && !!viewer.catalogue && viewer.catalogue.currentId===viewer.artworkId
            color:viewer.palette.panel;border.color:viewer.palette.metal
            Text {anchors.centerIn:parent;text:'✧ EDIT';font.pixelSize:11;color:viewer.palette.text}
            MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor
                onClicked:viewer.editViewedArtwork()}
        }
        Rectangle {
            x:parent.width-76;y:22;width:52;height:37;radius:6
            visible:viewer.phase==="artwork"
            color:viewer.palette.panel;border.color:viewer.palette.metal
            Text {anchors.centerIn:parent;text:"✕";font.pixelSize:21;color:viewer.palette.text}
            MouseArea {anchors.fill:parent;onClicked:viewer.closeGallery();cursorShape:Qt.PointingHandCursor}
        }
    }
}
