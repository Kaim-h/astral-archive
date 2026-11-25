import QtQuick
import Quickshell
import Quickshell.Hyprland
import "AppMatching.js" as Matching

// The UI never launches processes directly. All OS work stays here.
Item {
    id: service
    visible: false
    width: 0
    height: 0

    property var windowService: null // injected by LauncherPanel; optional in legacy tests
    property var pinnedIds: ["org.kde.dolphin", "org.kde.konsole", "firefox", "code"]
    property int maxVisible: 12
    property int page: 0
    property string searchText: ""
    property string lastMessage: "No application selected."

    // Captured just before the floating launcher acquires keyboard focus.
    // This preserves the desktop-focused ribbon while the Index is active.
    property string focusedAppIdOverride: ""

    readonly property var identityIndex: windowService ? windowService.identityIndex
        : Matching.buildWindowIndex(DesktopEntries.applications.values)
    readonly property var catalogue: buildCatalogue()
    readonly property var filtered: filterCatalogue(catalogue, searchText)
    readonly property int pageCount:
        Math.max(1, Math.ceil(filtered.length / Math.max(1, maxVisible)))
    readonly property var bookEntries: buildBookEntries()

    onSearchTextChanged: page = 0
    onMaxVisibleChanged: page = 0

    function buildCatalogue() {
        var source = DesktopEntries.applications.values;
        var result = [];
        for (var i = 0; i < source.length; ++i) {
            var app = source[i];
            // NoDisplay desktop entries should not appear in a launcher.
            if (!app || !app.id || !app.name || app.noDisplay) continue;
            result.push({
                appId: String(app.id),
                title: String(app.name),
                startupClass: String(app.startupClass || ""),
                comment: String(app.comment || ""),
                genericName: String(app.genericName || ""),
                keywords: String(app.keywords || ""),
                runInTerminal: Boolean(app.runInTerminal)
            });
        }
        result.sort(function(a, b) {
            return Matching.compareApplications(a, b, service.pinnedIds);
        });
        return result;
    }

    function filterCatalogue(allApps, query) {
        var matches = [];
        for (var i = 0; i < allApps.length; ++i) {
            if (Matching.matchesSearch(allApps[i], query))
                matches.push(allApps[i]);
        }
        return matches;
    }

    function matchingToplevel(app, windows) {
        for (var i = 0; i < windows.length; ++i) {
            var top = windows[i];
            if (top && Matching.matchesWindow(app, top.appId, service.identityIndex))
                return top;
        }
        return null;
    }

    // Converts any subset of catalogue entries into the properties Book.qml
    // understands. Used by the small launcher room AND legacy live test.
    function booksFor(apps) {
        var windows = Hyprland.toplevels.values;
        var active = Hyprland.activeToplevel;
        var previous = service.focusedAppIdOverride;
        var result = [];
        for (var i = 0; i < apps.length; ++i) {
            var app = apps[i];
            var top = service.matchingToplevel(app, windows);
            var count = service.windowService
                        ? service.windowService.windowCount(app)
                        : (top ? 1 : 0);
            var isFocused = Boolean(count > 0 && (
                (previous && Matching.matchesWindow(app, previous, service.identityIndex)) ||
                (!previous && active && Matching.matchesWindow(app, active.appId, service.identityIndex))
            ));
            result.push({
                appId: app.appId,
                title: app.title,
                spineLabel: app.title.length > 7
                    ? app.title.slice(0, 7).toUpperCase()
                    : app.title.toUpperCase(),
                titleOrientation: i % 3 === 0 ? "horizontal" : "vertical",
                coverColor: Matching.bindingColor(app.appId),
                running: count > 0,
                focused: isFocused,
                windowCount: count,
                ornamentStyle: "etched",
                bandCount: 2,
                ribbonEnd: "notch",
                showRibbon: true
            });
        }
        return result;
    }

    function buildBookEntries() {
        var start = Math.min(service.page, service.pageCount - 1)
                  * Math.max(1, service.maxVisible);
        return service.booksFor(service.filtered.slice(
            start, start + Math.max(1, service.maxVisible)));
    }

    function nextPage() { if (page + 1 < pageCount) page += 1; }
    function previousPage() { if (page > 0) page -= 1; }

    // Status strings mean requests, not guaranteed application focus/success.
    function activate(appId) {
        var app = DesktopEntries.byId(appId);
        if (!app) {
            lastMessage = "Application not found: " + appId;
            return "not-found";
        }
        var descriptor = {
            appId: String(app.id),
            startupClass: String(app.startupClass || "")
        };
        if (service.windowService) {
            var status = service.windowService.focusRecent(descriptor);
            if (status === "focus-requested" || status === "focus-error") {
                lastMessage = status === "focus-requested"
                    ? "Focus requested: " + app.name
                    : "Couldn't request window focus: " + app.name;
                return status;
            }
        } else {
            // Standalone older tests may omit WindowService.
            var top = matchingToplevel(descriptor, Hyprland.toplevels.values);
            if (top) {
                try { top.activate(); lastMessage = "Focus requested: " + app.name; return "focus-requested"; }
                catch (error) { lastMessage = "Couldn't request focus: " + error; return "focus-error"; }
            }
        }
        return launchAgain(appId);
    }

    function focusSpecific(appId, address) {
        var app = DesktopEntries.byId(appId);
        if (!app || !windowService) return "window-gone";
        var descriptor = {
            appId: String(app.id),
            startupClass: String(app.startupClass || "")
        };
        var status = windowService.focusSpecific(descriptor, address);
        lastMessage = status === "focus-requested"
                    ? "Focus requested: " + app.name
                    : "Window no longer available: " + app.name;
        return status;
    }

    // Explicit secondary command: unlike activate(), this does NOT focus an
    // existing window. The application itself decides whether to open a new
    // window, reuse its existing process, or reject another launch.
    function launchAgain(appId) {
        var app = DesktopEntries.byId(appId);
        if (!app) { lastMessage = "Application not found: " + appId; return "not-found"; }
        if (app.runInTerminal) {
            lastMessage = app.name + " needs a terminal; not launched.";
            return "terminal-not-supported";
        }
        try {
            app.execute();
            lastMessage = "Launch requested: " + app.name;
            return "launch-requested";
        } catch (error) {
            lastMessage = "Couldn't launch " + app.name + ": " + error;
            return "launch-error";
        }
    }
}
