// Pure, deterministic Gallery customization policy; works in QML JS or Node vm.
// Never touches the filesystem; only GalleryCatalogue persists the result.
var MAX_CONSTELLATIONS = 8;
var DEFAULT_COUNT = 5;
// Only a confirmed absent file is first run. Failed or malformed reads
// must never authorize writing defaults over potentially recoverable data.
function decodePreferences(readStatus, text) {
    var empty = Object.create(null);
    if (readStatus === 'missing') return { writable: true, perArtwork: empty };
    if (readStatus !== 'loaded') return { writable: false, perArtwork: empty };
    try {
        var raw = JSON.parse(text);
        if (!raw || raw.schemaVersion !== 1 || !raw.perArtwork ||
            typeof raw.perArtwork !== 'object' || Array.isArray(raw.perArtwork))
            return { writable: false, perArtwork: empty };
        var keys = Object.keys(raw.perArtwork);
        for (var i = 0; i < keys.length; i++) {
            var entry = raw.perArtwork[keys[i]];
            if (!entry || typeof entry !== 'object' || Array.isArray(entry))
                return { writable: false, perArtwork: Object.create(null) };
            empty[keys[i]] = entry;
        }
        return { writable: true, perArtwork: empty };
    } catch (e) {
        return { writable: false, perArtwork: Object.create(null) };
    }
}
// Manifest entries are local filenames, not paths or already-encoded URLs.
function artworkFileSegment(filename) {
    if (typeof filename !== 'string' || filename.indexOf('\0') >= 0 || !/^[^/\\]+-g\.(png|jpe?g|webp)$/i.test(filename))
        return '';
    try { return encodeURIComponent(filename); }
    catch (e) { return ''; } // malformed UTF-16 cannot form a valid URL
}
function numberBetween(value, lo, hi) {
    var n = Math.floor(Number(value));
    if (!isFinite(n)) n = lo;
    return Math.min(hi, Math.max(lo, n));
}
function stableHash(s) {
    // 32-bit FNV-1a; Math.imul is present in Qt 6 JS and Node.
    var h = 2166136261;
    s = String(s);
    for (var i = 0; i < s.length; i++) {
        h ^= s.charCodeAt(i);
        h = Math.imul(h, 16777619) >>> 0;
    }
    return h >>> 0;
}
function uniqueIds(library) {
    var ids = [], seen = Object.create(null);
    for (var i = 0; i < library.length; i++) {
        var id = String(library[i] && library[i].id || '');
        if (!id || seen[id]) continue;
        seen[id] = true;
        ids.push(id);
    }
    return ids;
}
function defaultSelection(artId, library, count) {
    var ids = uniqueIds(library);
    var limit = numberBetween(count, 1, Math.min(MAX_CONSTELLATIONS, ids.length || 1));
    ids.sort(function (a, b) {
        var ah = stableHash(String(artId) + '|' + a);
        var bh = stableHash(String(artId) + '|' + b);
        return ah - bh || a.localeCompare(b);
    });
    return ids.slice(0, limit);
}
function normalizeSelection(artId, rawIds, library, count) {
    var allowed = Object.create(null), unique = [], ids = uniqueIds(library);
    for (var i = 0; i < ids.length; i++) allowed[ids[i]] = true;
    var limit = numberBetween(count, 1, Math.min(MAX_CONSTELLATIONS, ids.length || 1));
    if (Array.isArray(rawIds)) for (var j = 0; j < rawIds.length; j++) {
        var id = String(rawIds[j]);
        if (allowed[id] && unique.indexOf(id) < 0) unique.push(id);
    }
    var remaining = defaultSelection(artId, library, ids.length);
    for (var k = 0; k < remaining.length && unique.length < limit; k++)
        if (unique.indexOf(remaining[k]) < 0) unique.push(remaining[k]);
    return unique.slice(0, limit);
}
function findById(items, id) {
    for (var i = 0; i < items.length; i++) if (items[i].id === id) return items[i];
    return null;
}
function normalizePool(rawPool, skies) {
    var allowed = Object.create(null), pool = [];
    for (var i = 0; i < skies.length; i++) allowed[skies[i].id] = true;
    if (Array.isArray(rawPool)) for (var j = 0; j < rawPool.length; j++) {
        var id = String(rawPool[j]);
        if (allowed[id] && pool.indexOf(id) < 0) pool.push(id);
    }
    return pool.length ? pool : (skies.length ? [skies[0].id] : []);
}
function createSetting(artId, library, skies) {
    var preferred = findById(skies, 'midnight') ? 'midnight'
        : (skies.length ? skies[0].id : 'theme');
    var count = Math.min(DEFAULT_COUNT, Math.max(1, uniqueIds(library).length));
    return {
        count: count, ids: defaultSelection(artId, library, count),
        sky: preferred, skyMode: 'fixed', skyPool: skies.map(function (s) { return s.id; }),
        cycleIndex: 0
    };
}
function normalizeSetting(artId, raw, library, skies) {
    var fallback = createSetting(artId, library, skies);
    raw = raw && typeof raw === 'object' ? raw : {};
    var count = numberBetween(raw.count !== undefined ? raw.count : fallback.count,
        1, Math.min(MAX_CONSTELLATIONS, Math.max(1, uniqueIds(library).length)));
    var sky = findById(skies, String(raw.sky || '')) ? String(raw.sky) : fallback.sky;
    var mode = raw.skyMode === 'cycle' ? 'cycle' : 'fixed';
    var pool = normalizePool(raw.skyPool !== undefined ? raw.skyPool : fallback.skyPool, skies);
    return {
        count: count, ids: normalizeSelection(artId, raw.ids, library, count),
        sky: sky, skyMode: mode, skyPool: pool,
        cycleIndex: numberBetween(raw.cycleIndex || 0, 0, 100000000)
    };
}
function pickSky(setting, skies, advance) {
    if (!setting) return skies.length ? skies[0].id : 'theme';
    if (setting.skyMode !== 'cycle') return setting.sky;
    var pool = normalizePool(setting.skyPool, skies);
    var i = Number(setting.cycleIndex || 0);
    return pool[(i + (advance ? 1 : 0)) % pool.length];
}
function selectDefinition(ids, library) {
    var defs = [];
    for (var i = 0; i < ids.length; i++) {
        var item = findById(library, ids[i]);
        if (item) defs.push(item);
    }
    return defs;
}
// Canonical coordinates use a square unit field. Center that field in each
// available slot without independently stretching the two axes.
function fitFigure(x, y, w, h) {
    var side = Math.max(0, Math.min(w, h));
    return { x: x + (w - side) / 2, y: y + (h - side) / 2, size: side };
}
function figurePoint(fit, star) {
    return { x: fit.x + star.x * fit.size, y: fit.y + star.y * fit.size };
}
function skyCells(defs, width, height) {
    if (!(width > 0 && height > 0)) return [];
    return layoutCells(defs).map(function (cell) {
        var x = cell.x * width, y = cell.y * height;
        var w = cell.w * width, h = cell.h * height;
        return { definition: cell.definition, id: cell.id,
            fit: fitFigure(x, y, w, h), labelX: x + w / 2, labelY: y + h + 21 };
    });
}
function skySeeds(defs, width, height) {
    var cells = skyCells(defs, width, height), seeds = [];
    for (var i = 0; i < cells.length && i < MAX_CONSTELLATIONS; i++) {
        var stars = cells[i].definition.stars || [];
        var first = stars.length ? stars[0] : { x: .5, y: .5, brightness: 0 };
        for (var j = 1; j < stars.length; j++)
            if (stars[j].brightness > first.brightness) first = stars[j];
        var point = figurePoint(cells[i].fit, first);
        seeds.push([point.x / width, point.y / height]);
    }
    return seeds;
}
function layoutCells(defs) {
    // Stable spatial placement independent of whether artwork is viewed via
    // rack or scope. Reuse each constellation's canonical star geometry.
    var out = [], n = defs.length;
    if (!n) return out;
    var columns = Math.ceil(Math.sqrt(n * 1.65)), rows = Math.ceil(n / columns);
    for (var i = 0; i < n; i++) {
        var col = i % columns, row = Math.floor(i / columns);
        out.push({
            id: defs[i].id, definition: defs[i],
            x: (col + .14) / columns, y: (row + .12) / rows,
            w: .72 / columns, h: .70 / rows
        });
    }
    return out;
}
