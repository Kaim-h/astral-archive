import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../widgets" as Widgets
import "../services" as Services
import "../services/ShelfModel.js" as Model
import "../themes" as Themes
import "../config/LauncherDefaults.js" as LauncherDefaults
import "../config/CapsuleDefaults.js" as Defaults

// Compact, floating, above-window Archive control. No full-width bar and
// no tiling/exclusive zone. The book shelves are a separate anchored popup.
PanelWindow {
    id: capsule
    anchors { top: true; right: true }
    margins { top: 12; right: 20 }
    implicitWidth: capsuleBody.implicitWidth
    implicitHeight: 49
    aboveWindows: true
    exclusiveZone: 0
    focusable: false
    color: "transparent"

    signal launcherRequested()
    signal verandaRequested()
    signal verandaCloseRequested()
    signal windowChooserRequested(string appId)
    signal themeRequested(int index)
    property string themePreferenceWarning: ""

    readonly property var palette: Themes.Theme.current
    property string precedingAppId: ""
    property bool latchedOpen: false
    property bool libraryHovered: libraryHover.hovered

    Services.WindowService { id: windows }
    Services.ApplicationService {
        id: apps
        windowService: windows
        pinnedIds: LauncherDefaults.pinnedIds
        focusedAppIdOverride: shelfPopup.visible ? capsule.precedingAppId : ""
    }
    Services.WorkspaceService {
        id: workspaces
        minimumSlots: Defaults.minimumWorkspaces
    }

    readonly property var shelfGroups: collectShelves()
    readonly property var pinnedBooks: apps.booksFor(shelfGroups.pinned)
    readonly property var runningBooks: apps.booksFor(shelfGroups.running)

    function collectShelves() {
        // Explicitly read refreshSerial for QML binding recalculation when
        // compositor events update an existing toplevel model in-place.
        var serial = windows.refreshSerial;
        var active = windows.activeToplevel;
        var catalogue = apps.catalogue;
        var runningIds = [];
        for (var i = 0; i < catalogue.length; ++i)
            if (windows.windowCount(catalogue[i]) > 0)
                runningIds.push(catalogue[i].appId);
        return Model.splitShelfApps(catalogue, apps.pinnedIds, runningIds,
                                    Defaults.maximumPinnedBooks,
                                    Defaults.maximumRunningBooks);
    }

    function showShelves(latch) {
        verandaCloseRequested();
        utilityPopup.visible = false; // only one dropdown at a time
        if (latch) latchedOpen = true;
        if (!shelfPopup.visible) {
            precedingAppId = Hyprland.activeToplevel
                ? String(Hyprland.activeToplevel.appId || "") : "";
            shelfPopup.visible = true;
        }
        closeGrace.stop();
    }

    function closeShelves() {
        latchedOpen = false;
        closeGrace.stop();
        shelfPopup.visible = false;
    }

    function toggleShelves() {
        if (shelfPopup.visible && latchedOpen) closeShelves();
        else showShelves(true);
    }

    // Both capsule dropdowns close before opening the independent Veranda.
    function dismissPopups() {
        closeShelves();
        utilityPopup.visible = false;
    }

    function toggleUtilityShelf() {
        if (!utilityPopup.visible) verandaCloseRequested();
        if (utilityPopup.visible) {
            utilityPopup.visible = false;
        } else {
            closeShelves();
            utilityPopup.visible = true;
        }
    }

    function considerHoverClose() {
        if (Defaults.openShelvesOnHover && !latchedOpen && shelfPopup.visible &&
            !libraryHovered && !shelfPopup.mouseInside)
            closeGrace.restart();
    }

    Timer {
        id: closeGrace
        interval: 380
        repeat: false
        onTriggered: {
            if (!capsule.latchedOpen && !capsule.libraryHovered &&
                !shelfPopup.mouseInside) capsule.closeShelves();
        }
    }

    ShelfPopup {
        id: shelfPopup
        anchor.window: capsule
        anchor.rect.x: capsule.width - shelfPopup.width
        anchor.rect.y: capsule.height + 7
        grabFocus: !Defaults.openShelvesOnHover
        hoverMode: Defaults.openShelvesOnHover
        palette: capsule.palette
        pinnedEntries: capsule.pinnedBooks
        runningEntries: capsule.runningBooks
        hiddenPinned: capsule.shelfGroups.hiddenPinned
        hiddenRunning: capsule.shelfGroups.hiddenRunning
        activeWorkspace: workspaces.activeId
        workspaceIds: workspaces.workspaceIds

        onApplicationRequested: function(appId) {
            var status = apps.activate(appId);
            if (status === "focus-requested" || status === "launch-requested")
                capsule.closeShelves();
        }
        onApplicationContextRequested: function(appId) {
            capsule.closeShelves();
            capsule.windowChooserRequested(appId);
        }
        onLauncherRequested: {
            capsule.closeShelves();
            capsule.launcherRequested();
        }
        onWorkspaceRequested: function(number) {
            workspaces.requestWorkspace(number);
            capsule.closeShelves();
        }
        onDismissed: capsule.latchedOpen = false
        onMouseInsideChanged: {
            if (mouseInside) closeGrace.stop();
            else capsule.considerHoverClose();
        }
    }

    Services.UtilityService { id: utilityService }

    UtilityShelf {
        id: utilityPopup
        anchor.window: capsule
        anchor.rect.x: capsule.width - utilityPopup.width
        anchor.rect.y: capsule.height + 7
        grabFocus: true
        palette: capsule.palette
        utility: utilityService
        onVerandaRequested: {
            capsule.dismissPopups();
            capsule.verandaRequested();
        }
    }

    Rectangle {
        id: capsuleBody
        anchors.fill: parent
        implicitWidth: controls.implicitWidth + 22
        radius: 12
        color: capsule.palette.panel
        border.color: capsule.palette.metal
        border.width: 2

        Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            radius: 9
            color: "transparent"
            border.color: capsule.palette.engraving
            border.width: 1
            opacity: 0.28
        }

        Row {
            id: controls
            anchors.centerIn: parent
            spacing: 9

            Rectangle {
                id: libraryButton
                width: 39
                height: 32
                radius: 5
                color: shelfPopup.visible ? capsule.palette.background : "transparent"
                border.color: libraryHover.hovered || shelfPopup.visible
                    ? capsule.palette.engraving : capsule.palette.metal
                border.width: 1
                // Three small, engraved book spines rather than an emoji icon.
                Row {
                    anchors.centerIn: parent
                    spacing: 2
                    Repeater {
                        model: ["#62776d", "#785e68", "#7c6a55"]
                        Rectangle {
                            required property var modelData
                            width: 6
                            height: 18
                            radius: 1
                            color: modelData
                            border.color: capsule.palette.metal
                            border.width: 1
                            Rectangle {
                                width: 4; height: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 4
                                color: capsule.palette.engraving
                            }
                        }
                    }
                }
                HoverHandler {
                    id: libraryHover
                    onHoveredChanged: {
                        if (hovered) {
                            closeGrace.stop();
                            if (Defaults.openShelvesOnHover)
                                capsule.showShelves(false);
                        } else {
                            capsule.considerHoverClose();
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: capsule.toggleShelves()
                }
            }

            Rectangle {
                id: workspaceButton
                width: 49
                height: 32
                radius: 5
                color: "transparent"
                border.color: capsule.palette.metal
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "WS " + workspaces.activeId
                    font.pixelSize: 11
                    font.family: "monospace"
                    color: capsule.palette.text
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: capsule.toggleShelves()
                }
            }

            Widgets.ClockDisplay {
                id: clock
                anchors.verticalCenter: parent.verticalCenter
                clockColor: capsule.palette.text
                latinSize: 14
                useElfish: false
            }

            Rectangle {
                id: themeButton
                width: 32
                height: 32
                radius: 5
                color: "transparent"
                border.color: capsule.palette.metal
                border.width: 1
                Accessible.name: "Cycle theme: " + capsule.palette.name
                Accessible.description: capsule.themePreferenceWarning
                Text {
                    anchors.centerIn: parent
                    text: capsule.palette.symbol
                    color: capsule.palette.metal
                    font.pixelSize: 19
                }
                Text {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 2
                    visible: capsule.themePreferenceWarning.length > 0
                    text: "!"
                    color: capsule.palette.text
                    font.pixelSize: 10
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: capsule.themeRequested((Themes.Theme.index + 1)
                        % Themes.Theme.palettes.length)
                }
            }

            // A separate mechanism emblem for the second, mutually exclusive
            // popup. No full-width bar or ever-present settings grid.
            Rectangle {
                id: utilityButton
                width: 36
                height: 32
                radius: 5
                color: utilityPopup.visible ? capsule.palette.background : "transparent"
                border.color: utilityPopup.visible ? capsule.palette.engraving : capsule.palette.metal
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "⚙"
                    font.pixelSize: 20
                    color: capsule.palette.metal
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: capsule.toggleUtilityShelf()
                }
            }
        }
    }
}
