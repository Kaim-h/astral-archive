// Pure JavaScript: independent of QML, Quickshell and Hyprland.
// The physical arrangement is deliberately NOT a filesystem mapping.
function normalized(id) {
    return String(id || "").toLowerCase().replace(/\.desktop$/, "");
}

function searchMatches(app, text) {
    var term = String(text || "").trim().toLowerCase();
    if (!term) return true;
    return [app.title, app.appId, app.comment, app.genericName, app.keywords]
        .join(" ").toLowerCase().indexOf(term) !== -1;
}

function homeApplications(catalogue, pins, capacity) {
    var output = [];
    var seen = Object.create(null);
    var cap = Math.max(0, Math.floor(capacity));
    var i, j, app;

    for (i = 0; i < pins.length && output.length < cap; i++) {
        for (j = 0; j < catalogue.length; j++) {
            app = catalogue[j];
            if (normalized(app.appId) === normalized(pins[i]) && !seen[app.appId]) {
                output.push(app);
                seen[app.appId] = true;
                break;
            }
        }
    }

    // A fresh installation might not contain any of the suggested IDs.
    // Fill a few spaces with real installed apps, never fictional books.
    for (i = 0; i < catalogue.length && output.length < cap; i++) {
        app = catalogue[i];
        if (!seen[app.appId]) {
            output.push(app);
            seen[app.appId] = true;
        }
    }
    return output;
}

function pageView(catalogue, pins, query, showAll, requestedPage,
    homeCapacity, indexCapacity) {
    var isSearching = String(query || "").trim().length > 0;
    var entries = isSearching
        ? catalogue.filter(function (app) { return searchMatches(app, query); })
        : (showAll ? catalogue : homeApplications(catalogue, pins, homeCapacity));
    var size = Math.max(1, isSearching || showAll ? indexCapacity : homeCapacity);
    var pages = Math.max(1, Math.ceil(entries.length / size));
    var page = Math.max(0, Math.min(pages - 1, Math.floor(requestedPage)));
    return {
        items: entries.slice(page * size, (page + 1) * size),
        total: entries.length,
        page: page,
        pages: pages,
        mode: isSearching ? "search" : (showAll ? "index" : "study")
    };
}

// -1 means the Index book, not "nothing selected".
// Books are ordered left-to-right across two shelves of at most four.
function arrowSelection(selected, key, count, perShelf) {
    if (count <= 0) return -1;
    var columns = Math.max(1, perShelf);
    if (selected < 0 || selected >= count) {
        return (key === "left" || key === "up") ? count - 1 : 0;
    }
    if (key === "left") return Math.max(0, selected - 1);
    if (key === "right") return Math.min(count - 1, selected + 1);
    if (key === "up") return selected >= columns ? selected - columns : selected;
    if (key === "down") {
        return selected + columns < count ? selected + columns : -1;
    }
    return selected;
}
