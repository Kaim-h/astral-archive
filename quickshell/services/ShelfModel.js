// Pure policy: one application belongs to the pinned shelf OR the running shelf.
// Quickshell and Hyprland state are obtained by QML adapters, not here.

function normalizeShelfId(value) {
    return String(value || "").trim().toLowerCase().replace(/\.desktop$/, "");
}

// All inputs are arrays of ordinary objects/strings. Pinned order is preserved.
// Running unpinned apps appear in catalogue order for deterministic placement.
function splitShelfApps(catalogue, pinnedIds, runningIds, maxPinned, maxRunning) {
    var pinned = [];
    var running = [];
    var available = Object.create(null);
    var seen = Object.create(null);
    var runningSet = Object.create(null);
    var i, app, id;
    var pinnedLimit = Math.max(0, Math.floor(Number(maxPinned) || 0));
    var runningLimit = Math.max(0, Math.floor(Number(maxRunning) || 0));

    for (i = 0; i < catalogue.length; ++i) {
        app = catalogue[i];
        if (!app || !app.appId) continue;
        id = normalizeShelfId(app.appId);
        if (id && !available[id]) available[id] = app;
    }
    for (i = 0; i < runningIds.length; ++i)
        runningSet[normalizeShelfId(runningIds[i])] = true;

    for (i = 0; i < pinnedIds.length; ++i) {
        id = normalizeShelfId(pinnedIds[i]);
        if (!id || !available[id] || seen[id]) continue;
        seen[id] = true;
        pinned.push(available[id]);
    }
    for (i = 0; i < catalogue.length; ++i) {
        app = catalogue[i];
        if (!app || !app.appId) continue;
        id = normalizeShelfId(app.appId);
        if (id && runningSet[id] && !seen[id]) {
            seen[id] = true;
            running.push(app);
        }
    }

    return {
        pinned: pinned.slice(0, pinnedLimit),
        running: running.slice(0, runningLimit),
        totalPinned: pinned.length,
        totalRunning: running.length,
        hiddenPinned: Math.max(0, pinned.length - pinnedLimit),
        hiddenRunning: Math.max(0, running.length - runningLimit)
    };
}

function visibleWorkspaceIds(currentIds, minimumCount) {
    var result = [];
    var required = Math.max(1, Math.floor(Number(minimumCount) || 1));
    for (var i = 1; i <= required; i++) result.push(i);
    for (i = 0; i < currentIds.length; i++) {
        var id = Number(currentIds[i]);
        if (Number.isInteger(id) && id > 0 && result.indexOf(id) === -1)
            result.push(id);
    }
    result.sort(function (a, b) { return a - b; });
    return result;
}
