import QtQuick
import Quickshell
import "../widgets" as Widgets

// Batch 8's *second* capsule popup. Illustrated, compact, and above windows.
// No fullscreen surface, no wallpaper attachment, no fake setting controls.
PopupWindow {
    id: popup
    width: 416
    height: 586
    visible: false
    color: "transparent"
    grabFocus: true

    property var palette: ({ background: "#121e23", panel: "#263c37",
        metal: "#8c6e5a", engraving: "#91ada1", text: "#e6e1d8" })
    property var utility: null
    readonly property bool hasUtility: utility !== null
    signal dismissed()
    signal verandaRequested()

    onVisibleChanged: {
        if (utility) utility.popupOpen = visible;
        if (visible) Qt.callLater(function() {
            if (popup.visible) keyboardSurface.forceActiveFocus();
        });
        else dismissed();
    }

    Item {
        id: keyboardSurface
        anchors.fill: parent
        focus: true
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                popup.visible = false;
                event.accepted = true;
            } else if (!popup.hasUtility) return;
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                var delta = event.key === Qt.Key_Left ? -5 : 5;
                if (event.modifiers & Qt.ShiftModifier)
                    popup.utility.changeBrightness(delta * 2);
                else popup.utility.changeVolume(delta);
                event.accepted = true;
            } else if (event.key === Qt.Key_Space) {
                popup.utility.toggleMute(); event.accepted = true;
            } else if (event.key === Qt.Key_W) {
                popup.utility.toggleWifi(); event.accepted = true;
            } else if (event.key === Qt.Key_B) {
                popup.utility.toggleBluetooth(); event.accepted = true;
            } else if (event.key === Qt.Key_S) {
                popup.utility.openSystemSettings(); event.accepted = true;
            }
        }

        Rectangle {
            id: frame
            anchors.fill: parent
            radius: 11
            color: popup.palette.panel
            border.color: popup.palette.metal
            border.width: 2
            Rectangle {
                anchors.fill: parent
                anchors.margins: 7
                radius: 7
                color: "transparent"
                border.color: popup.palette.engraving
                border.width: 1
                opacity: 0.3
            }
            Text {
                x: 22; y: 16
                text: "THE UTILITY SHELF"
                font.family: "serif"
                font.pixelSize: 18
                font.bold: true
                color: popup.palette.text
            }
            Text {
                x: 24; y: 43
                text: "MECHANISMS · CONTROLS · SIGNALS"
                font.family: "monospace"
                font.pixelSize: 10
                color: popup.palette.engraving
            }
            Rectangle {
                x: parent.width - width - 17; y: 15
                width: 27; height: 25; radius: 4
                color: popup.palette.background
                border.color: popup.palette.metal
                Text { anchors.centerIn: parent; text: "×"; font.pixelSize: 19; color: popup.palette.text }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.visible = false
                }
            }
            Rectangle { x: 22; y: 66; width: parent.width - 44; height: 1; color: popup.palette.metal; opacity: 0.58 }

            // Sound: uses PipeWire output node, not a fake progress bar.
            Text { x: 25; y: 81; text: "I · SPEAKING TUBE"; color: popup.palette.engraving; font.pixelSize: 12; font.bold: true }
            Text {
                x: 25; y: 106
                text: popup.hasUtility && popup.utility.audioAvailable
                    ? (popup.utility.muted ? "Output muted" : "Master output") : "No audio output detected"
                color: popup.palette.text; font.pixelSize: 11
            }
            Widgets.RelicSlider {
                id: volumeSlider
                x: 25; y: 129; width: 270
                value: popup.hasUtility ? popup.utility.volumePercent : 0
                interactive: popup.hasUtility && popup.utility.audioAvailable
                trackColor: popup.palette.background
                fillColor: popup.palette.metal
                outlineColor: popup.palette.engraving
                textColor: popup.palette.text
                onValueCommitted: function(percent) { if (popup.hasUtility) popup.utility.setVolume(percent); }
            }
            Text {
                x: 303; y: 137
                text: popup.hasUtility && popup.utility.audioAvailable
                    ? volumeSlider.shownValue + "%" : "--"
                color: popup.palette.text; font.pixelSize: 12; font.family: "monospace"
            }
            Rectangle {
                x: 349; y: 131; width: 39; height: 29; radius: 5
                color: popup.hasUtility && popup.utility.muted ? popup.palette.background : "transparent"
                border.color: popup.palette.metal
                opacity: popup.hasUtility && popup.utility.audioAvailable ? 1 : 0.4
                Text {
                    anchors.centerIn: parent
                    text: popup.hasUtility && popup.utility.muted ? "×" : "◖))"
                    font.pixelSize: 12; color: popup.palette.text
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: popup.hasUtility && popup.utility.audioAvailable
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.utility.toggleMute()
                }
            }
            Rectangle { x: 22; y: 177; width: parent.width - 44; height: 1; color: popup.palette.metal; opacity: 0.42 }

            // Brightness: brightnessctl reports a percentage; commits on release.
            Text { x: 25; y: 189; text: "II · LANTERN DIMMER"; color: popup.palette.engraving; font.pixelSize: 12; font.bold: true }
            Text {
                x: 25; y: 211
                text: popup.hasUtility && popup.utility.brightnessAvailable
                    ? "Display backlight" : "Brightness control unavailable"
                color: popup.palette.text; font.pixelSize: 11
            }
            Widgets.RelicSlider {
                id: brightnessSlider
                x: 25; y: 234; width: 270
                value: popup.hasUtility ? popup.utility.brightnessPercent : 0
                interactive: popup.hasUtility && popup.utility.brightnessAvailable &&
                    !popup.utility.brightnessWritePending
                trackColor: popup.palette.background
                fillColor: popup.palette.metal
                outlineColor: popup.palette.engraving
                textColor: popup.palette.text
                onValueCommitted: function(percent) { if (popup.hasUtility) popup.utility.setBrightness(percent); }
            }
            Text {
                x: 303; y: 242
                text: popup.hasUtility && popup.utility.brightnessAvailable
                    ? brightnessSlider.shownValue + "%" : "--"
                color: popup.palette.text; font.pixelSize: 12; font.family: "monospace"
            }
            Rectangle { x: 22; y: 281; width: parent.width - 44; height: 1; color: popup.palette.metal; opacity: 0.42 }

            // These are real state toggles; pairing / network selection stays
            // with the mature native settings app in this first version.
            Text { x: 25; y: 292; text: "III · SIGNAL RELAYS"; color: popup.palette.engraving; font.pixelSize: 12; font.bold: true }
            Rectangle {
                x: 24; y: 316; width: 179; height: 44; radius: 5
                color: popup.palette.background
                border.color: popup.palette.metal
                opacity: popup.hasUtility && popup.utility.wifiHardwareEnabled ? 1 : 0.5
                Text {
                    anchors.centerIn: parent
                    text: "WIFI   " + (popup.hasUtility && popup.utility.wifiEnabled ? "● ON" : "○ OFF")
                    color: popup.palette.text; font.family: "monospace"; font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: popup.hasUtility && popup.utility.wifiHardwareEnabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.utility.toggleWifi()
                }
            }
            Rectangle {
                x: 213; y: 316; width: 179; height: 44; radius: 5
                color: popup.palette.background
                border.color: popup.palette.metal
                opacity: popup.hasUtility && popup.utility.bluetoothAvailable ? 1 : 0.5
                Text {
                    anchors.centerIn: parent
                    text: "BLUE   " + (popup.hasUtility && popup.utility.bluetoothEnabled ? "● ON" : "○ OFF")
                    color: popup.palette.text; font.family: "monospace"; font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: popup.hasUtility && popup.utility.bluetoothAvailable
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.utility.toggleBluetooth()
                }
            }
            Text { x: 26; y: 365; text: "For networks and pairing: open System Settings"; font.pixelSize: 10; color: popup.palette.engraving }
            Rectangle { x: 22; y: 392; width: parent.width - 44; height: 1; color: popup.palette.metal; opacity: 0.42 }

            Text { x: 25; y: 403; text: "IV · POWER RESERVE"; color: popup.palette.engraving; font.pixelSize: 12; font.bold: true }
            Text {
                x: 265; y: 403; width: 125; horizontalAlignment: Text.AlignRight
                text: popup.hasUtility && popup.utility.batteryAvailable
                    ? popup.utility.batteryPercent + "% " + (popup.utility.onBattery ? "BATTERY" : "AC")
                    : "NOT AVAILABLE"
                font.pixelSize: 11; font.family: "monospace"; color: popup.palette.text
            }
            Rectangle {
                x: 26; y: 428; width: 365; height: 9; radius: 2
                color: popup.palette.background; border.color: popup.palette.metal
                Rectangle {
                    x: 2; y: 2; height: parent.height - 4
                    width: popup.hasUtility && popup.utility.batteryAvailable
                        ? (parent.width - 4) * popup.utility.batteryPercent / 100 : 0
                    color: popup.palette.engraving; radius: 1
                }
            }
            Rectangle {
                x: 23; y: 453; width: parent.width - 46; height: 34; radius: 5
                color: popup.palette.background
                border.color: popup.palette.metal
                Text { anchors.centerIn: parent; text: "✧   OPEN SYSTEM SETTINGS"; color: popup.palette.text; font.pixelSize: 12 }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (popup.hasUtility) popup.utility.openSystemSettings(); }
                }
            }
            // A route to the independent centered Veranda, not a third dropdown.
            Rectangle {
                x: 23; y: 495; width: parent.width - 46; height: 37; radius: 5
                color: popup.palette.background
                border.color: popup.palette.metal
                Text {
                    anchors.centerIn: parent
                    text: "✧   VERANDA OF VISTAS"
                    color: popup.palette.text
                    font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        popup.visible = false;
                        popup.verandaRequested();
                    }
                }
            }
            Text {
                x: 24; y: 545; width: parent.width - 48
                text: popup.hasUtility && popup.utility.message.length
                    ? popup.utility.message
                    : "←→ volume · Shift+←→ light · Space mute · W Wi-Fi · B Blue · Esc close"
                color: popup.palette.engraving; font.pixelSize: 10
                elide: Text.ElideRight
            }
        }
    }
}
