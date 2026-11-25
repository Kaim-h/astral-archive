import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../services" as Services
import "../services/LauncherModel.js" as Model
import "../shelves" as Shelves
import "../widgets" as Widgets
import "../themes" as Themes
import "../config/LauncherDefaults.js" as Defaults

// Floating illustrated launcher. One window, one actual keyboard target:
// the Index's TextInput. Selected books are visual state, not Qt focus.
PanelWindow {
    id: launcher
    visible: false
    focusable: true
    aboveWindows: true
    exclusiveZone: 0
    anchors { top: true; left: true }
    margins { top: 72; left: 56 }
    implicitWidth: 600
    implicitHeight: 550
    color: "transparent"

    property var palette: Themes.Theme.current
    property bool showAll: false
    property bool indexExpanded: false
    property int currentPage: 0
    // -1 is the Index; all positive values index the visible book list.
    property int selectedIndex: -1
    property var precedingWindow: null
    property string precedingAppId: ""
    property bool windowPickerOpen: false
    property string windowPickerAppId: ""
    readonly property var windowPickerApp: appService.catalogue
        ? appService.catalogue.find(function(app) { return app.appId === windowPickerAppId; })
        : null
    readonly property var windowPickerRows: windowPickerApp
        ? windowService.windowsFor(windowPickerApp) : []
    readonly property var pageData: Model.pageView(
        appService.catalogue, appService.pinnedIds,
        indexInput.text, showAll, currentPage,
        Defaults.homeCapacity, Defaults.indexPageCapacity)
    readonly property var decoratedBooks: appService.booksFor(pageData.items)
    readonly property var firstShelfEntries: decoratedBooks.slice(0, 4)
    readonly property var secondShelfEntries: decoratedBooks.slice(4, 8)
    readonly property string pageDescription:
        pageData.mode === "search" ? "INDEX · RESULTS"
      : pageData.mode === "index" ? "INDEX · CATALOGUE"
      : "THE STUDY"

    Services.WindowService { id: windowService }

    Services.ApplicationService {
        id: appService
        pinnedIds: Defaults.pinnedIds
        windowService: windowService
        focusedAppIdOverride: launcher.visible ? launcher.precedingAppId : ""
    }

    function openLauncher() {
        // Capture desktop focus before the launcher grabs keyboard input.
        precedingWindow = Hyprland.activeToplevel;
        precedingAppId = precedingWindow ? String(precedingWindow.appId || "") : "";
        visible = true;
    }

    function closeLauncher(restoreDesktopFocus) {
        windowPickerOpen = false;
        windowPickerAppId = "";
        visible = false;
        if (restoreDesktopFocus && precedingWindow) {
            try { precedingWindow.activate(); }
            catch (error) { console.warn("Couldn't restore desktop focus:", error); }
        }
    }

    function toggleLauncher() {
        if (visible) closeLauncher(true);
        else openLauncher();
    }

    function openWindowPicker(appId) {
        if (!appId) return;
        windowPickerAppId = appId;
        windowPickerOpen = true;
        // Index TextInput keeps Qt keyboard focus, even for this chooser.
        indexInput.forceActiveFocus();
    }

    function closeWindowPicker() {
        windowPickerOpen = false;
        windowPickerAppId = "";
        indexInput.forceActiveFocus();
    }

    function focusPickedWindow(address) {
        var status = appService.focusSpecific(windowPickerAppId, address);
        if (status === "focus-requested") closeLauncher(false);
        else closeWindowPicker();
    }

    function launchPickedAgain() {
        var status = appService.launchAgain(windowPickerAppId);
        if (status === "launch-requested") closeLauncher(false);
        else closeWindowPicker();
    }

    function openSelectedWindows() {
        if (selectedIndex < 0 || selectedIndex >= pageData.items.length) return;
        openWindowPicker(pageData.items[selectedIndex].appId);
    }

    function showIndexCatalogue() {
        selectedIndex = -1;
        showAll = true;
        indexExpanded = true;
        currentPage = 0;
        indexInput.forceActiveFocus();
    }

    function changePage(amount) {
        if (pageData.pages <= 1) return;
        currentPage = Math.max(0, Math.min(pageData.pages - 1,
                                         pageData.page + amount));
        selectedIndex = pageData.items.length > 0 ? 0 : -1;
    }

    function activateSelected() {
        if (selectedIndex < 0) {
            if (indexInput.text.length > 0) {
                if (pageData.items.length === 0) return;
                selectedIndex = 0;
            } else {
                showIndexCatalogue();
                return;
            }
        }
        if (selectedIndex >= pageData.items.length) return;
        activateApp(pageData.items[selectedIndex].appId);
    }

    function activateApp(appId) {
        var status = appService.activate(appId);
        if (status === "launch-requested" || status === "focus-requested")
            closeLauncher(false);  // No delay for any visual animation.
    }

    onVisibleChanged: {
        if (visible) {
            showAll = false;
            indexExpanded = false;
            selectedIndex = -1;
            currentPage = 0;
            windowPickerOpen = false;
            windowPickerAppId = "";
            indexInput.text = "";
            // Queue this after the window is made visible. The Wayland
            // compositor must still grant keyboard focus at runtime.
            Qt.callLater(function() {
                if (launcher.visible) indexInput.forceActiveFocus();
            });
        }
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: 12
        color: launcher.palette.panel
        border.color: launcher.palette.metal
        border.width: 2

        Rectangle {
            x: 13; y: 12; width: parent.width - 26; height: parent.height - 24
            color: "transparent"
            border.color: launcher.palette.engraving
            border.width: 1
            opacity: 0.4
            radius: 8
        }

        Text {
            id: heading
            anchors.top: parent.top
            anchors.topMargin: 23
            anchors.horizontalCenter: parent.horizontalCenter
            text: "THE ASTRAL ARCHIVE"
            color: launcher.palette.text
            font.family: "serif"
            font.pixelSize: 21
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: heading.bottom
            anchors.topMargin: 8
            text: launcher.pageDescription
            color: launcher.palette.engraving
            font.family: "monospace"
            font.pixelSize: 11
        }

        Shelves.Shelf {
            id: upperShelf
            anchors.top: heading.bottom
            anchors.topMargin: 39
            anchors.horizontalCenter: parent.horizontalCenter
            entries: launcher.firstShelfEntries
            selectedIndex: launcher.selectedIndex >= 0 && launcher.selectedIndex < 4
                          ? launcher.selectedIndex : -1
            selectionColor: launcher.palette.metal
            surfaceColor: launcher.palette.panel
            metalColor: launcher.palette.metal
            engravingColor: launcher.palette.engraving
            ornamentPattern: "◇ ✧ ◇"
            bookSpacing: 2
            onBookActivated: function(appId) { launcher.activateApp(appId); }
            onBookContextRequested: function(appId) { launcher.openWindowPicker(appId); }
        }
        Shelves.Shelf {
            id: lowerShelf
            anchors.top: upperShelf.bottom
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            entries: launcher.secondShelfEntries
            selectedIndex: launcher.selectedIndex >= 4
                          ? launcher.selectedIndex - 4 : -1
            selectionColor: launcher.palette.metal
            surfaceColor: launcher.palette.panel
            metalColor: launcher.palette.metal
            engravingColor: launcher.palette.engraving
            ornamentPattern: "✧ ◇ ✧"
            bookSpacing: 2
            onBookActivated: function(appId) { launcher.activateApp(appId); }
            onBookContextRequested: function(appId) { launcher.openWindowPicker(appId); }
        }

        Text {
            visible: launcher.pageData.total === 0
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: lowerShelf.verticalCenter
            text: indexInput.text.length ? "No matching volumes" : "No installed applications found"
            color: launcher.palette.text
            font.pixelSize: 12
        }

        // A deliberately small reference book occupies the lower-right.
        Widgets.IndexBook {
            id: indexBook
            anchors.right: parent.right
            anchors.rightMargin: 32
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 32
            selected: launcher.selectedIndex === -1
            searching: indexInput.text.length > 0
            metalColor: launcher.palette.metal
            accentColor: launcher.palette.engraving
            textColor: launcher.palette.text
            onRequested: launcher.showIndexCatalogue()
        }

        // The TextInput is *always* the actual keyboard receiver. Its
        // annotation fades into view when the user types or opens the Index.
        Rectangle {
            id: indexAnnotation
            anchors.right: indexBook.left
            anchors.rightMargin: 12
            anchors.bottom: indexBook.bottom
            anchors.bottomMargin: 8
            width: 245
            height: 46
            radius: 5
            color: launcher.palette.background
            border.color: launcher.palette.metal
            border.width: 1
            opacity: launcher.indexExpanded || indexInput.text.length > 0 ? 1 : 0

            TextInput {
                id: indexInput
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                height: 28
                verticalAlignment: TextInput.AlignVCenter
                color: launcher.palette.text
                selectedTextColor: launcher.palette.background
                selectionColor: launcher.palette.engraving
                font.pixelSize: 12
                clip: true
                selectByMouse: true
                activeFocusOnTab: false

                onTextChanged: {
                    launcher.currentPage = 0;
                    launcher.indexExpanded = text.length > 0 || launcher.showAll;
                    launcher.selectedIndex = text.length > 0 && launcher.pageData.items.length > 0
                                             ? 0 : -1;
                }

                Keys.onPressed: function(event) {
                    // All input still arrives at the Index. The chooser is
                    // a visual selection state, never another focus target.
                    if (launcher.windowPickerOpen) {
                        if (event.key === Qt.Key_Escape)
                            launcher.closeWindowPicker();
                        else if (event.key === Qt.Key_Up)
                            windowChooser.moveSelection(-1);
                        else if (event.key === Qt.Key_Down)
                            windowChooser.moveSelection(1);
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                            windowChooser.acceptSelection();
                        event.accepted = true;
                        return;
                    }
                    if ((event.modifiers & Qt.ControlModifier) &&
                        (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                        launcher.openSelectedWindows();
                        event.accepted = true;
                        return;
                    }
                    var direction = "";
                    if (event.key === Qt.Key_Left) direction = "left";
                    else if (event.key === Qt.Key_Right) direction = "right";
                    else if (event.key === Qt.Key_Up) direction = "up";
                    else if (event.key === Qt.Key_Down) direction = "down";
                    if (direction !== "") {
                        launcher.selectedIndex = Model.arrowSelection(
                            launcher.selectedIndex, direction,
                            launcher.pageData.items.length, 4);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        launcher.closeLauncher(true);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return ||
                               event.key === Qt.Key_Enter) {
                        launcher.activateSelected();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_PageDown) {
                        launcher.changePage(1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_PageUp) {
                        launcher.changePage(-1);
                        event.accepted = true;
                    }
                }
            }
            Text {
                visible: launcher.indexExpanded && indexInput.text.length === 0
                anchors.left: indexInput.left
                anchors.verticalCenter: indexInput.verticalCenter
                text: "Search the Index…"
                color: launcher.palette.engraving
                font.pixelSize: 12
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 29
            width: 212
            elide: Text.ElideRight
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 48
            text: launcher.pageData.mode === "study"
                  ? "Type to consult the Index · Arrows to browse"
                  : launcher.pageData.total + " volumes · Page "
                    + (launcher.pageData.page + 1) + "/" + launcher.pageData.pages
            color: launcher.palette.engraving
            font.pixelSize: 11
        }
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 29
            width: 250
            elide: Text.ElideRight
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 28
            text: "Enter: open · Ctrl+Enter: windows · Esc: back"
            color: launcher.palette.text
            opacity: 0.8
            font.pixelSize: 10
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 29
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 91
            spacing: 7
            visible: launcher.pageData.pages > 1
            Repeater {
                model: ["←", "→"]
                Rectangle {
                    required property int index
                    required property string modelData
                    width: 27; height: 24; radius: 4
                    color: launcher.palette.background
                    border.color: launcher.palette.metal
                    opacity: index === 0 && launcher.pageData.page === 0 ||
                             index === 1 && launcher.pageData.page === launcher.pageData.pages - 1
                             ? 0.4 : 1
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: launcher.palette.text
                        font.pixelSize: 13
                    }
                    TapHandler {
                        onTapped: launcher.changePage(index === 0 ? -1 : 1)
                    }
                }
            }
        }
        // Right-click a book or use Ctrl+Enter on a selected book.
        // This overlays the two shelves; it never changes desktop tiling.
        Widgets.WindowChooser {
            id: windowChooser
            anchors.centerIn: parent
            z: 30
            visible: launcher.windowPickerOpen
            appTitle: launcher.windowPickerApp
                ? launcher.windowPickerApp.title : "Application"
            windows: launcher.windowPickerRows
            panelColor: launcher.palette.panel
            backdropColor: launcher.palette.background
            metalColor: launcher.palette.metal
            accentColor: launcher.palette.engraving
            textColor: launcher.palette.text
            onWindowRequested: function(address) { launcher.focusPickedWindow(address); }
            onLaunchAgainRequested: launcher.launchPickedAgain()
            onDismissed: launcher.closeWindowPicker()
        }
    }
}
