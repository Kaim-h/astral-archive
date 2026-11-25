import QtQuick
import Quickshell
import Quickshell.Hyprland
import "AppMatching.js" as Matching
import "WindowModel.js" as Model

// Non-visual window management adapter for the whole Archive.
// Hyprland owns tiling/workspaces. This service only identifies and requests
// activation of particular application windows.
Item {
    id: windows
    visible: false
    width: 0
    height: 0

    property var focusHistory: []
    property int refreshSerial: 0
    readonly property var toplevels: Hyprland.toplevels.values
    readonly property var activeToplevel: Hyprland.activeToplevel
    readonly property var identityIndex: Matching.buildWindowIndex(DesktopEntries.applications.values)

    // Hyprland.toplevels contains Wayland Toplevel handles in QS 0.3.1;
    // HyprlandToplevel is an attached object exposing the address/workspace.
    function hyprInfo(top) {
        try { return top ? top.HyprlandToplevel : null; }
        catch (error) { return null; }
    }

    function addressOf(top) {
        var info = hyprInfo(top);
        return info && info.address ? Model.cleanAddress(info.address) : "";
    }

    function recordFocus() {
        var source = Hyprland.toplevels.values;
        var liveAddresses = [];
        for (var i = 0; i < source.length; ++i)
            liveAddresses.push(addressOf(source[i]));
        var recent = Model.pruneFocus(focusHistory, liveAddresses);
        var address = addressOf(Hyprland.activeToplevel);
        // Active may be available one event earlier than the toplevel list.
        focusHistory = Model.noteFocus(recent, address, 120);
        refreshSerial++;
    }

    function recordsFor(app) {
        // refreshSerial is a dependency for QML expressions that call this.
        var serial = refreshSerial;
        var source = Hyprland.toplevels.values;
        var result = [];
        for (var i = 0; i < source.length; ++i) {
            var top = source[i];
            if (!top || !Matching.matchesWindow(app, top.appId, identityIndex)) continue;
            var info = hyprInfo(top);
            var workspace = info && info.workspace ? info.workspace : null;
            result.push({
                top: top, // never persisted or returned to a visual component
                address: addressOf(top),
                title: String(top.title || app.title || app.appId || "Untitled window"),
                workspaceName: workspace ? String(workspace.name) : "Unknown",
                workspaceId: workspace ? workspace.id : null,
                appId: String(top.appId || "")
            });
        }
        return result;
    }

    function orderedRecords(app) {
        return Model.orderByRecency(recordsFor(app), focusHistory,
                                    addressOf(Hyprland.activeToplevel));
    }

    function windowCount(app) { return recordsFor(app).length; }

    // Plain data for the window chooser. Missing addresses are displayed but
    // cannot be activated by ID until Hyprland provides an address.
    function windowsFor(app) {
        var found = orderedRecords(app);
        var result = [];
        for (var i = 0; i < found.length; i++) {
            result.push({
                address: found[i].address,
                title: found[i].title,
                workspaceName: found[i].workspaceName,
                workspaceId: found[i].workspaceId
            });
        }
        return result;
    }

    function requestActivate(top) {
        if (!top) return "not-running";
        try {
            top.activate();
            return "focus-requested";
        } catch (error) {
            console.warn("Astral Archive: couldn't request window focus:", error);
            return "focus-error";
        }
    }

    function focusRecent(app) {
        var found = orderedRecords(app);
        return requestActivate(found.length ? found[0].top : null);
    }

    // Resolve the address afresh to avoid selecting a window that was closed.
    // Check the application identity too, guarding against stale selections.
    function focusSpecific(app, address) {
        var target = Model.cleanAddress(address);
        if (!target) return "window-gone";
        var matches = recordsFor(app);
        for (var i = 0; i < matches.length; i++) {
            if (matches[i].address === target)
                return requestActivate(matches[i].top);
        }
        return "window-gone";
    }

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() { windows.recordFocus(); }
    }
    Component.onCompleted: recordFocus()
}
