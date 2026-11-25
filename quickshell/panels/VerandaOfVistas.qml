import QtQuick
import Quickshell
import "../widgets" as Widgets
import "../themes" as Themes
import "../services/VistaPolicy.js" as Policy
import "../config/VerandaDefaults.js" as Defaults

// A centered, above-window scene (NOT a wallpaper-layer window or a hotbar).
// Requires no Hyprland float rules and reserves no tiling space.
PanelWindow {
    id: veranda
    anchors { left: true; top: true }
    implicitWidth: Math.min(1010, screen ? Math.max(460,screen.width - 44) : 1010)
    implicitHeight: Math.min(548, screen ? Math.max(385,screen.height - 54) : 548)
    margins {
        left: screen ? Math.max(0,Math.floor((screen.width - veranda.implicitWidth)/2)) : 40
        top: screen ? Math.max(0,Math.floor((screen.height - veranda.implicitHeight)/2)) : 40
    }
    aboveWindows: true
    exclusiveZone: 0
    focusable: true
    visible: false
    color: "transparent"

    property var wallpaperService: null
    readonly property var palette: Themes.Theme.current
    readonly property var eligible: wallpaperService ? wallpaperService.eligible : []
    property int activeIndex: 0
    readonly property var activeArt: eligible.length ? eligible[Policy.wrappedIndex(activeIndex,eligible.length)] : null

    function alignSelection() {
        activeIndex=Policy.selectedIndex(eligible,wallpaperService ? wallpaperService.currentId : "");
    }
    function openGallery() {
        alignSelection();
        visible=true;
        Qt.callLater(function(){if (veranda.visible) keySurface.forceActiveFocus();});
    }
    function closeGallery() { visible=false; }
    function toggleGallery() { if (visible) closeGallery(); else openGallery(); }
    function step(delta) {
        if (eligible.length) activeIndex=Policy.wrappedIndex(activeIndex+delta,eligible.length);
    }
    function selectOffset(delta) {
        if (delta===0) applyCurrent(); else step(delta);
    }
    function applyCurrent() {
        if (activeArt && wallpaperService) wallpaperService.applyManual(activeArt.id);
    }
    onEligibleChanged: alignSelection()
    onVisibleChanged: {
        if (visible) Qt.callLater(function(){if (veranda.visible) keySurface.forceActiveFocus();});
    }

    Item {
        id: keySurface
        anchors.fill: parent
        focus: true
        Keys.onPressed: function(event) {
            if (event.key===Qt.Key_Escape) veranda.closeGallery();
            else if (event.key===Qt.Key_Left) veranda.step(-1);
            else if (event.key===Qt.Key_Right) veranda.step(1);
            else if (event.key===Qt.Key_Return || event.key===Qt.Key_Enter) veranda.applyCurrent();
            else return;
            event.accepted=true;
        }
        Rectangle {
            id: panel
            anchors.fill: parent
            radius: 14
            color: veranda.palette.panel
            border.color: veranda.palette.metal
            border.width: 2
            Rectangle {
                anchors.fill: parent
                anchors.margins: 7
                radius: 10
                color: "transparent"
                border.color: veranda.palette.engraving
                border.width: 1
                opacity: .26
            }
            Text {
                x: 35; y: 21
                text: "THE VERANDA OF VISTAS"
                font.family: "serif"; font.bold: true; font.pixelSize: 22
                color: veranda.palette.text
            }
            Text {
                x: 37; y: 52
                text: "SCENES · " + veranda.palette.name.toUpperCase() + " · " + veranda.eligible.length + " WORKS"
                font.family: "monospace"; font.pixelSize: 10
                color: veranda.palette.engraving
            }
            Rectangle {
                x: 35; y: 79; width: parent.width-70; height: 1
                color: veranda.palette.metal; opacity: .55
            }
            Rectangle {
                id: exitButton
                x: parent.width-65; y: 20; width: 29; height: 28
                color: veranda.palette.background; radius: 5
                border.color: veranda.palette.metal
                Text { anchors.centerIn: parent; text: "×"; font.pixelSize: 20; color: veranda.palette.text }
                MouseArea { anchors.fill: parent; onClicked: veranda.closeGallery(); cursorShape: Qt.PointingHandCursor }
            }
            Item {
                id: carousel
                x: 24; y: 95
                width: parent.width-48
                height: parent.width < 690
                    ? Math.max(110, parent.height-290)
                    : Math.max(190, parent.height-265)
                clip: true
                WheelHandler { onWheel: function(event){ veranda.step(event.angleDelta.y > 0 ? -1 : 1); } }
                Repeater {
                    model: veranda.eligible.length ? Math.min(5, veranda.eligible.length) : 0
                    delegate: Widgets.VistaTile {
                        id: tile
                        required property int index
                        readonly property int offset: index - Math.floor((Math.min(5,veranda.eligible.length)-1)/2)
                        // With 1-4 entries this keeps selection visible and centered.
                        readonly property int effectiveOffset: veranda.eligible.length>=5 ? index-2 : offset
                        readonly property int artIndex: Policy.wrappedIndex(veranda.activeIndex + effectiveOffset,veranda.eligible.length)
                        art: veranda.eligible[artIndex]
                        service: veranda.wallpaperService
                        palette: veranda.palette
                        selected: effectiveOffset===0
                        slantFraction: Defaults.slantFraction
                        width: selected ? Math.min(Defaults.centralPreviewWidth,carousel.width*.53)
                            : Math.abs(effectiveOffset)===1 ? Math.min(Defaults.neighborPreviewWidth,carousel.width*.34)
                            : Math.min(Defaults.farPreviewWidth,carousel.width*.26)
                        height: selected ? Math.min(Defaults.centralPreviewHeight,carousel.height-14)
                            : Math.abs(effectiveOffset)===1 ? Math.min(Defaults.neighborPreviewHeight,carousel.height-25)
                            : Math.min(Defaults.farPreviewHeight,carousel.height-44)
                        x: (carousel.width-width)/2 + effectiveOffset*(carousel.width*.247)
                        y: (carousel.height-height)/2
                        z: 5-Math.abs(effectiveOffset)
                        opacity: selected ? 1 : Math.abs(effectiveOffset)===1 ? .72 : .48
                        onChosen: veranda.selectOffset(effectiveOffset)
                        Behavior on x { NumberAnimation {duration: 280; easing.type: Easing.OutCubic} }
                        Behavior on y { NumberAnimation {duration: 280; easing.type: Easing.OutCubic} }
                        Behavior on width { NumberAnimation {duration: 280; easing.type: Easing.OutCubic} }
                        Behavior on opacity { NumberAnimation {duration: 220} }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: !veranda.eligible.length
                    text: "No wallpapers for the active theme"
                    color: veranda.palette.engraving
                    font.family:"serif"; font.pixelSize:16
                }
            }
            // The inscription is outside the image; artwork is never overwritten.
            Text {
                id: inscription
                x: 40; y: carousel.y + carousel.height + 4
                width: parent.width-80
                text: veranda.activeArt ? veranda.activeArt.title : "No vista selected"
                font.family: "serif"; font.pixelSize: 21; font.bold: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: veranda.palette.text
            }
            Text {
                x: 40; y: inscription.y+29; width: parent.width-80
                text: veranda.activeArt ? "by " + veranda.activeArt.artist : ""
                font.family: "serif"; font.italic: true; font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                color: veranda.palette.engraving
            }
            Rectangle {
                y: parent.height-(parent.width < 690 ? 109 : 79)
                x: 35; width: parent.width-70; height: 1
                color: veranda.palette.metal; opacity: .4
            }
            Flow {
                x: 33
                y: parent.height - (parent.width < 690 ? 98 : 64)
                width: parent.width - 66
                spacing: 10
                Widgets.VistaControl {
                    label: "‹ PREV"; palette: veranda.palette
                    onPressed: veranda.step(-1)
                }
                Widgets.VistaControl {
                    label: "NEXT ›"; palette: veranda.palette
                    onPressed: veranda.step(1)
                }
                Widgets.VistaControl {
                    label: veranda.wallpaperService && veranda.wallpaperService.busy ? "APPLYING…" : "✦ APPLY VISTA"
                    palette: veranda.palette
                    enabled: !!veranda.activeArt && veranda.wallpaperService && !veranda.wallpaperService.busy
                    onPressed: veranda.applyCurrent()
                }
                Widgets.VistaControl {
                    label: veranda.wallpaperService && veranda.wallpaperService.rotationEnabled ? "DAILY: ON" : "DAILY: OFF"
                    palette: veranda.palette
                    onPressed: {
                        if (veranda.wallpaperService)
                            veranda.wallpaperService.setRotationEnabled(!veranda.wallpaperService.rotationEnabled);
                    }
                }
                Widgets.VistaControl {
                    label: veranda.wallpaperService && veranda.wallpaperService.transitionEnabled
                        ? "ANIMATION: ON" : "ANIMATION: OFF"
                    palette: veranda.palette
                    enabled: !!veranda.wallpaperService
                    onPressed: {
                        if (veranda.wallpaperService)
                            veranda.wallpaperService.setTransitionEnabled(!veranda.wallpaperService.transitionEnabled);
                    }
                }
            }
            Text {
                x: 37; y: parent.height-24; width: parent.width-74
                text: veranda.wallpaperService && veranda.wallpaperService.displayMessage.length
                      ? veranda.wallpaperService.displayMessage
                      : "← → browse · Enter apply · Esc close"
                font.family:"monospace"; font.pixelSize:10
                color: veranda.wallpaperService && veranda.wallpaperService.preferenceWarning.length
                       ? veranda.palette.text : veranda.palette.engraving
                elide: Text.ElideRight
            }
        }
    }
}
