import QtQuick
import Quickshell.Hyprland
import "ShelfModel.js" as Model

// Workspace state and dispatch stay outside visual controls.
// Hyprland handles placement and all compositor-side focus management.
Item {
    id: service
    visible: false
    width: 0
    height: 0

    property int minimumSlots: 5
    readonly property int activeId: Hyprland.focusedWorkspace
        ? Hyprland.focusedWorkspace.id : 1
    readonly property var workspaceIds: buildWorkspaceIds()

    function buildWorkspaceIds() {
        var source = Hyprland.workspaces.values;
        var ids = [];
        for (var i = 0; i < source.length; ++i) ids.push(source[i].id);
        return Model.visibleWorkspaceIds(ids, minimumSlots);
    }

    function requestWorkspace(id) {
        var number = Number(id);
        if (!Number.isInteger(number) || number <= 0) return;
        var source = Hyprland.workspaces.values;
        for (var i = 0; i < source.length; ++i) {
            if (source[i].id === number) {
                source[i].activate();
                return;
            }
        }
        if (Hyprland.usingLua) {
            console.warn("Archive: empty workspace creation is not configured for Hyprland Lua mode.");
            return;
        }
        Hyprland.dispatch("workspace " + number);
    }
}
