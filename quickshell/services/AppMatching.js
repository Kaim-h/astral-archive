// Pure JavaScript helpers for the ApplicationService.
// No Quickshell imports: these are easy to test without Linux.

function normalizedId(value) {
    var text = String(value || "").trim().toLowerCase();
    return text.replace(/\.desktop$/, "");
}

// Resolve against the full installed catalogue, not the visible page.
// Equal-ranked distinct desktop IDs remain unresolved regardless of order.
function buildWindowIndex(applications) {
    var index = Object.create(null);
    function offer(key, id, rank) {
        if (!key) return;
        var old = index[key];
        if (!old || rank > old.rank) index[key] = {rank:rank,id:id};
        else if (rank === old.rank && old.id !== id) index[key] = {rank:rank,id:null};
    }
    for (var i=0; i<applications.length; i++) {
        var app = applications[i];
        if (!app) continue;
        var raw = String(app.appId || app.id || "");
        var id = normalizedId(raw);
        if (!id) continue;
        offer(id,raw,3);
        offer(normalizedId(app.startupClass),raw,2);
        var parts=id.split("."), suffix=parts[parts.length-1];
        if (parts.length>1 && suffix.length>=4) offer(suffix,raw,1);
    }
    return index;
}
function resolveWindowId(index, windowAppId) {
    var key=normalizedId(windowAppId);
    return key && index && index[key] ? index[key].id : null;
}
function matchesWindow(app, windowAppId, index) {
    return !!app && !!app.appId && resolveWindowId(index,windowAppId)===String(app.appId);
}

function pinnedRank(id, pins) {
    var candidate = normalizedId(id);
    for (var i = 0; i < pins.length; i++) {
        if (candidate === normalizedId(pins[i]))
            return i;
    }
    return pins.length + 1;
}

function compareApplications(a, b, pins) {
    var ar = pinnedRank(a.appId, pins);
    var br = pinnedRank(b.appId, pins);
    if (ar !== br) return ar - br;

    var an = String(a.title || "").toLowerCase();
    var bn = String(b.title || "").toLowerCase();
    if (an < bn) return -1;
    if (an > bn) return 1;
    var ai = normalizedId(a.appId);
    var bi = normalizedId(b.appId);
    return ai < bi ? -1 : ai > bi ? 1 : 0;
}

function matchesSearch(app, term) {
    var query = String(term || "").trim().toLowerCase();
    if (!query) return true;
    return [app.title, app.appId, app.comment, app.genericName,
    app.keywords].join(" ").toLowerCase().indexOf(query) !== -1;
}

function bindingColor(id) {
    var colors = [
        "#526f63", "#605c79", "#836b54", "#54777b",
        "#6e6450", "#576e66", "#775f6e", "#656f84",
        "#71795e", "#8a7458"
    ];
    var key = normalizedId(id);
    var hash = 0;
    for (var i = 0; i < key.length; i++)
        hash = (hash * 31 + key.charCodeAt(i)) >>> 0;
    return colors[hash % colors.length];
}
