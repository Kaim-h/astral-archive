// Veranda of Vistas — pure, deterministic policy; no QML or OS calls.
// These functions also run under Node for offline verification.
var THEMES = ["evening", "twilight", "midnight"];

function validTheme(theme) { return THEMES.indexOf(theme) >= 0; }
function safeFile(file) {
    return typeof file === "string" && file.length > 0 &&
        file !== "." && file !== ".." && !/[\\/\u0000-\u001f]/.test(file) &&
        file.indexOf("..") < 0;
}
// Manifest filenames are literal local segments, never pre-encoded URLs.
function fileSegment(file) {
    if (!safeFile(file)) return "";
    try { return encodeURIComponent(file); } catch (e) { return ""; }
}
// Decode only the trusted installation-directory URL, never a raw filename.
function localDirectory(url) {
    if (typeof url !== "string" || url.indexOf("file:///") !== 0 || /[#?]/.test(url)) return "";
    try {
        var p = decodeURIComponent(url.substring(7));
        if (p.indexOf("\0") >= 0) return "";
        return p.charAt(p.length-1) === "/" ? p : p + "/";
    } catch (e) { return ""; }
}
function localImagePath(directory, file) {
    return directory && directory.charAt(0) === "/" && fileSegment(file)
        ? directory + file : "";
}
function localImageUrl(path) {
    if (typeof path !== "string" || path.charAt(0) !== "/" || path.indexOf("\0") >= 0) return "";
    try { return "file://" + path.split("/").map(encodeURIComponent).join("/"); }
    catch (e) { return ""; }
}
function normalizeManifest(input) {
    var records = input && Array.isArray(input.wallpapers) ? input.wallpapers : [];
    var out = [], used = Object.create(null);
    for (var i = 0; i < records.length; i++) {
        var a = records[i];
        if (!a || typeof a.id !== "string" || !/^[a-z0-9-]+$/.test(a.id) ||
            used[a.id] || !fileSegment(a.file) || !Array.isArray(a.themes)) continue;
        var themes = a.themes.filter(function (t) { return validTheme(t); });
        if (!themes.length) continue;
        used[a.id] = true;
        var x = Number(a.focusX), y = Number(a.focusY);
        out.push({
            id: a.id, file: a.file,
            title: typeof a.title === "string" && a.title.trim() ? a.title.trim() : a.file,
            artist: typeof a.artist === "string" && a.artist.trim() ? a.artist.trim() : "Uncredited — verify",
            themes: themes, focusX: isFinite(x) ? Math.max(0, Math.min(1, x)) : .5,
            focusY: isFinite(y) ? Math.max(0, Math.min(1, y)) : .5,
            titleVerified: a.titleVerified === true,
            subjectOutline: a.subjectOutline === true
        });
    }
    return out;
}
function forTheme(entries, theme) {
    return (entries || []).filter(function (a) { return a.themes.indexOf(theme) >= 0; });
}
function localDate(d) {
    function z(n) { return n < 10 ? "0" + n : String(n); }
    return d.getFullYear() + "-" + z(d.getMonth() + 1) + "-" + z(d.getDate());
}
function blankTheme() { return { current: "", date: "", queue: [] }; }
function initialState() {
    return {
        version: 1, rotationEnabled: true, transitionEnabled: true,
        byTheme: { evening: blankTheme(), twilight: blankTheme(), midnight: blankTheme() }
    };
}
function cleanState(x) {
    var out = initialState();
    if (!x || typeof x !== "object") return out;
    if (typeof x.rotationEnabled === "boolean") out.rotationEnabled = x.rotationEnabled;
    // Old Batch 9 state lacks this field: default to animated fade.
    if (typeof x.transitionEnabled === "boolean") out.transitionEnabled = x.transitionEnabled;
    for (var i = 0; i < THEMES.length; i++) {
        var theme = THEMES[i], s = x.byTheme && x.byTheme[theme];
        if (!s || typeof s !== "object") continue;
        out.byTheme[theme] = {
            current: typeof s.current === "string" ? s.current : "",
            date: typeof s.date === "string" && /^\d{4}-\d\d-\d\d$/.test(s.date) ? s.date : "",
            queue: Array.isArray(s.queue) ? s.queue.filter(function (id) { return typeof id === "string"; }) : []
        };
    }
    return out;
}
// Keep normalization for internal policy transitions; validate persisted
// envelopes separately so a failed read cannot authorize overwriting defaults.
function decodePreferences(status, text) {
    var fallback = initialState();
    if (status === "missing") return { writable: true, state: fallback };
    if (status !== "loaded") return { writable: false, state: fallback };
    function plain(v) { return !!v && typeof v === "object" && !Array.isArray(v); }
    try {
        var raw = JSON.parse(text);
        if (!plain(raw) || raw.version !== 1 || !plain(raw.byTheme) ||
            typeof raw.rotationEnabled !== "boolean" ||
            (raw.transitionEnabled !== undefined && typeof raw.transitionEnabled !== "boolean"))
            return { writable: false, state: fallback };
        for (var i=0; i<THEMES.length; i++) {
            var t = raw.byTheme[THEMES[i]];
            if (!plain(t) || typeof t.current !== "string" || typeof t.date !== "string" ||
                (t.date !== "" && !/^\d{4}-\d\d-\d\d$/.test(t.date)) ||
                !Array.isArray(t.queue) || t.queue.some(function(id){return typeof id !== "string";}))
                return { writable: false, state: fallback };
        }
        return { writable: true, state: cleanState(raw) };
    } catch(e) { return { writable: false, state: fallback }; }
}
// Date is the selection date, not the time the asynchronous backend exits.
function applicationKey(theme, date, id, rotationEnabled) {
    return theme + ":" + (rotationEnabled ? date : "fixed") + ":" + id;
}
function appliedKey(applied, rotationEnabled) {
    return applied ? applicationKey(applied.theme, applied.date, applied.id, rotationEnabled) : "";
}
function shuffled(ids, random) {
    var list = ids.slice();
    var rand = typeof random === "function" ? random : Math.random;
    for (var i = list.length - 1; i > 0; i--) {
        var r = Number(rand()); if (!isFinite(r)) r = 0;
        var j = Math.floor(Math.max(0, Math.min(.999999999, r)) * (i + 1));
        var t = list[i]; list[i] = list[j]; list[j] = t;
    }
    return list;
}
function forDay(state, theme, date, entries, random) {
    // Pure: return a new state. Caller persists only after backend success.
    var next = cleanState(state), eligible = forTheme(entries, theme);
    if (!validTheme(theme) || !eligible.length) return { state: next, id: "" };
    var s = next.byTheme[theme], ids = eligible.map(function (a) { return a.id; });
    var currentValid = ids.indexOf(s.current) >= 0;
    if (currentValid && (!next.rotationEnabled || s.date === date))
        return { state: next, id: s.current };
    var queue = s.queue.filter(function (id, idx, all) { return ids.indexOf(id) >= 0 && all.indexOf(id) === idx; });
    if (!next.rotationEnabled && currentValid) return { state: next, id: s.current };
    if (!queue.length) queue = shuffled(ids, random);
    // Ensure no immediate repeat at a reshuffle boundary when possible.
    if (currentValid && queue.length > 1 && queue[0] === s.current) {
        var first = queue.shift(); queue.push(first);
    }
    var picked = queue.shift();
    s.current = picked; s.date = date; s.queue = queue;
    return { state: next, id: picked };
}
function manualSelection(state, theme, date, entries, id) {
    var next = cleanState(state), eligible = forTheme(entries, theme);
    if (!validTheme(theme) || !eligible.some(function (a) { return a.id === id; }))
        return { state: next, id: "" };
    var s = next.byTheme[theme]; s.current = id; s.date = date;
    s.queue = s.queue.filter(function (x) { return x !== id; });
    return { state: next, id: id };
}
function selectedIndex(entries, id) {
    for (var i = 0; i < entries.length; i++) if (entries[i].id === id) return i;
    return entries.length ? 0 : -1;
}
function wrappedIndex(i, length) { return length ? ((i % length) + length) % length : -1; }

// Safe argument array for awww: no shell interpolation, path is its own arg.
// Explicit "none" disables animation even if the daemon has other defaults.
function wallpaperCommand(imagePath, transitionEnabled) {
    var command = ["awww", "img", "--transition-type",
        transitionEnabled ? "fade" : "none"];
    if (transitionEnabled) command.push("--transition-duration", "0.85");
    command.push("--", imagePath);
    return command;
}
