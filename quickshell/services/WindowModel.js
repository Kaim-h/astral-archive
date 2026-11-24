// Pure, non-visual multi-window policy. No compositor or QML dependencies.
// Hyprland addresses are unique while windows live; do not persist them.
function cleanAddress(value) {
    return String(value || "").trim().toLowerCase();
}

function noteFocus(history, address, limit) {
    var key = cleanAddress(address);
    var result = [];
    var capacity = Math.max(1, Math.floor(limit || 100));
    if (key) result.push(key);
    for (var i = 0; i < history.length && result.length < capacity; i++) {
        var entry = cleanAddress(history[i]);
        if (entry && result.indexOf(entry) === -1) result.push(entry);
    }
    return result;
}

function pruneFocus(history, liveAddresses) {
    var live = {};
    var result = [];
    for (var i = 0; i < liveAddresses.length; i++) {
        var key = cleanAddress(liveAddresses[i]);
        if (key) live[key] = true;
    }
    for (i = 0; i < history.length; i++) {
        var address = cleanAddress(history[i]);
        if (address && live[address] && result.indexOf(address) === -1)
            result.push(address);
    }
    return result;
}

// Input records have {address, ...}; preserve original order for unknown recency.
// The active window wins, then focus history; unknown items keep source order.
function orderByRecency(records, history, activeAddress) {
    var active = cleanAddress(activeAddress);
    var wrapped = [];
    for (var i = 0; i < records.length; i++) {
        var address = cleanAddress(records[i].address);
        var rank = history.indexOf(address);
        if (address && address === active) rank = -1;
        else if (!address || rank < 0) rank = 1000000;
        wrapped.push({ item: records[i], rank: rank, original: i });
    }
    wrapped.sort(function (a, b) {
        return a.rank - b.rank || a.original - b.original;
    });
    return wrapped.map(function (entry) { return entry.item; });
}

function chooseRecent(records, history, activeAddress) {
    var ordered = orderByRecency(records, history, activeAddress);
    return ordered.length ? ordered[0] : null;
}
