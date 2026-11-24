import QtQuick
import Quickshell.Services.Mpris

// Real MPRIS transport + metadata; the plus has deliberately NO false save.
// Default text is stationary; title/artist can travel ONLY while hovered.
Item {
    id: music
    property var palette: ({background:"#121e23",panel:"#263c37",metal:"#8c6e5a",engraving:"#91ada1",text:"#e6e1d8"})
    property bool active: true
    readonly property var availablePlayers: Mpris.players.values
    readonly property var player: {
        var list=availablePlayers;
        for(var i=0;i<list.length;i++)if(list[i].isPlaying)return list[i];
        return list.length?list[0]:null;
    }
    readonly property string title: player ? (player.trackTitle||"Untitled track") : "No music player"
    readonly property string artist: player ? (player.trackArtist||player.identity||"Unknown artist") : "Open a music application"
    readonly property string albumArt: player ? (player.trackArtUrl||"") : ""
    readonly property bool isPlaying: player ? player.isPlaying : false
    property bool saveNotice: false
    property real progress: 0

    width: 226
    height: 166

    function refreshProgress(){
        if(!player || !player.positionSupported || !player.lengthSupported ||
           !isFinite(player.length) || player.length<=0 || !isFinite(player.position)){
            progress=0; return;
        }
        progress=Math.max(0,Math.min(1,player.position/player.length));
    }
    onPlayerChanged: refreshProgress()
    onActiveChanged: if(active) refreshProgress()
    onVisibleChanged: if(visible) refreshProgress()
    // Quickshell emits positionChanged for nonlinear movement (e.g. seek).
    // Track/length updates can arrive separately, including while paused.
    Connections {
        target: music.player
        function onPositionChanged() { music.refreshProgress() }
        function onLengthChanged() { music.refreshProgress() }
        function onLengthSupportedChanged() { music.refreshProgress() }
        function onPositionSupportedChanged() { music.refreshProgress() }
        function onPlaybackStateChanged() { music.refreshProgress() }
        function onPostTrackChanged() { music.refreshProgress() }
    }
    Timer {
        interval: 1000;repeat:true
        running: music.active && music.visible && !!music.player && music.isPlaying
        onTriggered: { if(music.player) music.player.positionChanged(); }
    }
    Timer { id: noticeExpiry; interval: 2100; onTriggered: music.saveNotice=false }

    Rectangle {
        id: display
        x: 22.6;y: 0;width: 180;height:51;radius:7
        color: music.palette.background
        border.color: music.palette.metal;border.width:1.2
        Rectangle { anchors.fill: parent; anchors.margins: 3; radius:4; color:"transparent";border.color:music.palette.engraving;opacity:.26 }
        Image {
            x:5;y:5;width:31;height:31;source:music.albumArt
            visible:music.albumArt.length>0
            asynchronous:true;fillMode:Image.PreserveAspectCrop
        }
        Rectangle {
            x:5;y:5;width:31;height:31;visible:music.albumArt.length===0
            color:music.palette.panel;border.color:music.palette.metal
            Text {anchors.centerIn:parent;text:"✦";font.pixelSize:17;color:music.palette.engraving}
        }
        Text {x:42;y:4;text:"NOW PLAYING";font.pixelSize:7;letterSpacing:1.1;color:music.palette.engraving}
        Item {
            id: titleClip
            x:42;y:14;width:132;height:15;clip:true
            property bool hovered: titleMouse.containsMouse
            Text {id:titleLabel; text:music.title; y:0; x:0; font.pixelSize:11;color:music.palette.text;wrapMode:Text.NoWrap}
            MouseArea { id:titleMouse; anchors.fill:parent;hoverEnabled:true;acceptedButtons:Qt.NoButton
                onExited:{titleTravel.stop();titleLabel.x=0;}
                onEntered: {if(titleLabel.implicitWidth>titleClip.width)titleTravel.start();}
            }
            SequentialAnimation {
                id:titleTravel;loops:Animation.Infinite
                PauseAnimation {duration:650}
                NumberAnimation {target:titleLabel;property:"x";from:0;to:Math.min(0,titleClip.width-titleLabel.implicitWidth-8);duration:6500;easing.type:Easing.InOutSine}
                PauseAnimation {duration:800}
                NumberAnimation {target:titleLabel;property:"x";to:0;duration:850;easing.type:Easing.OutCubic}
            }
        }
        Item {
            id: artistClip
            x:42;y:29;width:132;height:12;clip:true
            Text {id:artistLabel;text:music.artist; font.pixelSize:8.7;color:music.palette.engraving;wrapMode:Text.NoWrap}
            MouseArea { id:artistMouse;anchors.fill:parent;hoverEnabled:true;acceptedButtons:Qt.NoButton
                onExited:{artistTravel.stop();artistLabel.x=0;}
                onEntered:{if(artistLabel.implicitWidth>artistClip.width)artistTravel.start();}
            }
            SequentialAnimation {
                id:artistTravel;loops:Animation.Infinite
                PauseAnimation {duration:650}
                NumberAnimation {target:artistLabel;property:"x";from:0;to:Math.min(0,artistClip.width-artistLabel.implicitWidth-8);duration:7000;easing.type:Easing.InOutSine}
                PauseAnimation {duration:800}
                NumberAnimation {target:artistLabel;property:"x";to:0;duration:850;easing.type:Easing.OutCubic}
            }
        }
        Rectangle {
            x:7;y:46;width:166;height:1;color:music.palette.engraving;opacity:.3
            Rectangle {width:parent.width*music.progress;height:1;color:music.palette.metal}
        }
    }

    Rectangle {
        id: transport
        x: 0;y:57.4;width:225.6;height:32;radius:6
        color: music.palette.background;border.color:music.palette.metal;border.width:1.2
        Rectangle { anchors.fill: parent; anchors.margins:3; radius:3; color:"transparent";border.color:music.palette.engraving;opacity:.26 }
        Row {
            anchors.centerIn:parent;spacing:15
            Repeater {
                model: ["◀◀","Ⅱ","▶▶","＋"]
                delegate: Rectangle {
                    required property int index
                    required property string modelData
                    width:30;height:24;radius:3;color:button.containsMouse?music.palette.panel:"transparent"
                    opacity: {
                        if(index===0)return music.player&&music.player.canGoPrevious?1:.42;
                        if(index===1)return music.player&&music.player.canTogglePlaying?1:.42;
                        if(index===2)return music.player&&music.player.canGoNext?1:.42;
                        return .70;
                    }
                    Text {anchors.centerIn:parent;text:index===1?(music.isPlaying?"Ⅱ":"▶"):modelData; font.pixelSize:index===3?18:12;color:music.palette.text}
                    MouseArea {
                        id:button;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor
                        onClicked: {
                            var p=music.player;
                            if(index===0&&p&&p.canGoPrevious)p.previous();
                            if(index===1&&p&&p.canTogglePlaying)p.togglePlaying();
                            if(index===2&&p&&p.canGoNext)p.next();
                            if(index===3){music.saveNotice=true;noticeExpiry.restart();}
                        }
                    }
                }
            }
        }
    }
    Rectangle {
        x:1;y:93;width:224;height:23;radius:5
        visible:music.saveNotice;color:music.palette.background;border.color:music.palette.metal
        Text {anchors.centerIn:parent;text:"Library integration pending (MPRIS has no Add)";font.pixelSize:9;color:music.palette.text}
    }
}
