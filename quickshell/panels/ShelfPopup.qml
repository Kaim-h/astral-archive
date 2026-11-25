import QtQuick
import Quickshell
import "../shelves" as Shelves
import "../widgets" as Widgets

// Floating illustrated shelves attached to the compact ArchiveCapsule.
// Uses the EXISTING 42px Book/Shelf components. No wallpaper-level widget,
// no independent tiled window, and no second application launcher.
PopupWindow {
    id: popup
    width: 414
    height: 566
    color: "transparent"
    visible: false

    property var palette: ({
        background: "#121e23", panel: "#263c37", metal: "#8c6e5a",
        engraving: "#91ada1", text: "#e6e1d8"
    })
    property var pinnedEntries: []
    property var runningEntries: []
    property int hiddenPinned: 0
    property int hiddenRunning: 0
    property var workspaceIds: [1, 2, 3, 4, 5]
    property int activeWorkspace: 1
    property bool hoverMode: false
    readonly property bool mouseInside: popupHover.hovered

    // These are visual selection states, not the underlying application focus.
    property int selectedShelf: -1
    property int selectedIndex: 0
    readonly property var selectedEntries: selectedShelf === 0 ? pinnedEntries
                                              : selectedShelf === 1 ? runningEntries : []
    readonly property string selectedAppId:
        selectedIndex >= 0 && selectedIndex < selectedEntries.length
        ? String(selectedEntries[selectedIndex].appId) : ""

    signal applicationRequested(string appId)
    signal applicationContextRequested(string appId)
    signal launcherRequested()
    signal workspaceRequested(int number)
    signal dismissed()

    function resetSelection() {
        selectedShelf = pinnedEntries.length ? 0 : (runningEntries.length ? 1 : -1);
        selectedIndex = 0;
    }

    function switchShelf(number) {
        if (number === 0 && pinnedEntries.length) {
            selectedShelf = 0;
            selectedIndex = Math.min(selectedIndex, pinnedEntries.length - 1);
        } else if (number === 1 && runningEntries.length) {
            selectedShelf = 1;
            selectedIndex = Math.min(selectedIndex, runningEntries.length - 1);
        }
    }

    onVisibleChanged: {
        if (visible) {
            resetSelection();
            if (!hoverMode) Qt.callLater(function() {
                if (popup.visible) keyboardSurface.forceActiveFocus();
            });
        } else {
            dismissed();
        }
    }

    Item {
        id: keyboardSurface
        anchors.fill: parent
        focus: true
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                popup.visible = false;
                event.accepted = true;
            } else if (event.key === Qt.Key_Left && popup.selectedShelf >= 0) {
                popup.selectedIndex = Math.max(0, popup.selectedIndex - 1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right && popup.selectedShelf >= 0) {
                popup.selectedIndex = Math.min(popup.selectedEntries.length - 1,
                                               popup.selectedIndex + 1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                popup.switchShelf(0);
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                popup.switchShelf(1);
                event.accepted = true;
            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) &&
                       popup.selectedAppId) {
                if (event.modifiers & Qt.ControlModifier)
                    popup.applicationContextRequested(popup.selectedAppId);
                else
                    popup.applicationRequested(popup.selectedAppId);
                event.accepted = true;
            } else if (event.key === Qt.Key_I && !event.modifiers) {
                popup.launcherRequested();
                event.accepted = true;
            } else if ((event.modifiers & Qt.AltModifier) &&
                       event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                popup.workspaceRequested(event.key - Qt.Key_0);
                event.accepted = true;
            }
        }

        Rectangle {
            id: backdrop
            anchors.fill: parent
            radius: 10
            color: popup.palette.panel
            border.color: popup.palette.metal
            border.width: 2

            Rectangle {
                anchors.fill: parent
                anchors.margins: 8
                radius: 7
                color: "transparent"
                border.color: popup.palette.engraving
                border.width: 1
                opacity: 0.32
            }

            HoverHandler { id: popupHover }

            Text {
                id: heading
                x: 22
                y: 15
                text: "THE LIBRARY"
                font.family: "serif"
                font.pixelSize: 17
                font.bold: true
                color: popup.palette.text
            }

            Rectangle {
                id: indexButton
                x: parent.width - width - 20
                y: 13
                width: 100
                height: 27
                radius: 4
                color: popup.palette.background
                border.color: popup.palette.metal
                Text {
                    anchors.centerIn: parent
                    text: "✧  INDEX"
                    font.pixelSize: 12
                    color: popup.palette.text
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.launcherRequested()
                }
            }

            Text {
                x: 22
                y: 52
                text: "WORKSPACES"
                font.family: "monospace"
                font.pixelSize: 10
                color: popup.palette.engraving
            }
            Flickable {
                x: 116
                y: 45
                width: parent.width - 139
                height: 29
                contentWidth: workspaceButtons.implicitWidth
                contentHeight: 29
                clip: true
                interactive: contentWidth > width
                Widgets.WorkspaceIndicator {
                    id: workspaceButtons
                    activeWorkspace: popup.activeWorkspace
                    workspaceIds: popup.workspaceIds
                    activeColor: popup.palette.metal
                    inactiveColor: popup.palette.background
                    textColor: popup.palette.text
                    onWorkspaceRequested: function(number) {
                        popup.workspaceRequested(number);
                    }
                }
            }
            Rectangle {
                x: 22
                y: 84
                width: parent.width - 44
                height: 1
                color: popup.palette.metal
                opacity: 0.5
            }

            Text {
                x: 25
                y: 95
                text: "PINNED VOLUMES" + (popup.hiddenPinned ? " · +" + popup.hiddenPinned : "")
                color: popup.palette.engraving
                font.family: "serif"
                font.pixelSize: 11
                font.bold: true
            }
            Shelves.Shelf {
                id: pinnedShelf
                anchors.horizontalCenter: parent.horizontalCenter
                y: 111
                entries: popup.pinnedEntries
                bookSpacing: 2
                selectedIndex: popup.selectedShelf === 0 ? popup.selectedIndex : -1
                selectionColor: popup.palette.metal
                metalColor: popup.palette.metal
                surfaceColor: popup.palette.panel
                engravingColor: popup.palette.engraving
                ornamentPattern: "◇ ✧ ◇"
                onBookActivated: function(appId) { popup.applicationRequested(appId); }
                onBookContextRequested: function(appId) { popup.applicationContextRequested(appId); }
            }
            Text {
                visible: !popup.pinnedEntries.length
                anchors.horizontalCenter: parent.horizontalCenter
                y: 206
                text: "No installed pinned applications"
                font.pixelSize: 11
                color: popup.palette.text
            }

            Text {
                x: 25
                y: 301
                text: "RUNNING · UNPINNED" + (popup.hiddenRunning ? " · +" + popup.hiddenRunning : "")
                color: popup.palette.engraving
                font.family: "serif"
                font.pixelSize: 11
                font.bold: true
            }
            Shelves.Shelf {
                id: runningShelf
                anchors.horizontalCenter: parent.horizontalCenter
                y: 318
                entries: popup.runningEntries
                bookSpacing: 2
                selectedIndex: popup.selectedShelf === 1 ? popup.selectedIndex : -1
                selectionColor: popup.palette.metal
                metalColor: popup.palette.metal
                surfaceColor: popup.palette.panel
                engravingColor: popup.palette.engraving
                ornamentPattern: "✧ ◇ ✧"
                onBookActivated: function(appId) { popup.applicationRequested(appId); }
                onBookContextRequested: function(appId) { popup.applicationContextRequested(appId); }
            }
            Text {
                visible: !popup.runningEntries.length
                anchors.horizontalCenter: parent.horizontalCenter
                y: 418
                text: "No unpinned applications running"
                font.pixelSize: 11
                color: popup.palette.text
            }

            Text {
                x: 25
                y: 533
                width: parent.width - 50
                horizontalAlignment: Text.AlignHCenter
                text: "← → books · ↑ ↓ shelves · Enter open · Ctrl+Enter windows · I Index · Esc close"
                font.pixelSize: 10
                color: popup.palette.engraving
                elide: Text.ElideRight
            }
        }
    }
}
