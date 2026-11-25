#!/usr/bin/env node
'use strict';
// Batch 11 static and pure-policy tests; not a QML runtime test.
const fs = require('node:fs'), path = require('node:path'), vm = require('node:vm'), assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
function file(p) { return fs.readFileSync(path.join(root, p), 'utf8'); }
const policyText = file('quickshell/services/GalleryPolicy.js');
new vm.Script(policyText, { filename: 'GalleryPolicy.js' });
const context = vm.createContext({ Math, Number, String, Array, Object, isFinite });
vm.runInContext(policyText, context);
const P = context;
const lib = JSON.parse(file('quickshell/data/gallery-constellations.json'));
const skies = JSON.parse(file('quickshell/data/gallery-sky-presets.json'));
assert.equal(lib.schemaVersion, 1);
assert.ok(Array.isArray(lib.constellations) && lib.constellations.length >= 10);
assert.equal(skies.schemaVersion, 1);
assert.ok(skies.skies.length >= 4);
const ids = new Set();
for (const c of lib.constellations) {
    assert.match(c.id, /^[a-z0-9-]+$/);
    assert.ok(!ids.has(c.id)); ids.add(c.id);
    assert.equal(c.source, 'archive-original');
    assert.ok(c.name && c.description && c.stars.length >= 4 && c.edges.length >= 3);
    const pointIds = new Set();
    for (const p of c.stars) {
        assert.ok(!pointIds.has(p.id)); pointIds.add(p.id);
        assert.ok(p.x >= 0 && p.x <= 1 && p.y >= 0 && p.y <= 1);
        assert.ok(p.brightness > 0 && p.brightness <= 1);
    }
    for (const [a, b] of c.edges) { assert.ok(pointIds.has(a) && pointIds.has(b), `Broken edge ${c.id}`) }
}
const skyIds = new Set();
for (const s of skies.skies) {
    assert.ok(!skyIds.has(s.id)); skyIds.add(s.id);
    assert.match(s.background, /^#[0-9a-f]{6}$/i);
    assert.match(s.accent, /^#[0-9a-f]{6}$/i);
    assert.match(s.secondary, /^#[0-9a-f]{6}$/i);
    assert.ok(Number.isInteger(s.mode) && s.mode >= 0 && s.mode <= 4);
}
assert.equal(ids.size, lib.constellations.length);
for (let i = 0; i < 250; i++) {
    const art = `new-art-${i}`;
    const defaults = P.createSetting(art, lib.constellations, skies.skies);
    assert.equal(defaults.count, 5);
    assert.equal(defaults.ids.length, 5);
    assert.equal(new Set(defaults.ids).size, 5);
    assert.equal(P.defaultSelection(art, lib.constellations, 5).join(','), defaults.ids.join(','));
    assert.equal(P.normalizeSetting(art, defaults, lib.constellations, skies.skies).ids.join(','), defaults.ids.join(','));
    const eight = P.normalizeSetting(art, { ...defaults, count: 8 }, lib.constellations, skies.skies);
    assert.equal(eight.ids.length, 8); assert.equal(new Set(eight.ids).size, 8);
    const one = P.normalizeSetting(art, { ...defaults, count: 1 }, lib.constellations, skies.skies);
    assert.equal(one.ids.length, 1);
    const selected = P.selectDefinition(defaults.ids, lib.constellations);
    assert.equal(P.layoutCells(selected).length, 5);
}
const example = P.createSetting('test-piece', lib.constellations, skies.skies);
const invalid = P.normalizeSetting('test-piece', { count: 200, ids: ['missing', example.ids[0], example.ids[0]], sky: 'unknown', skyMode: 'cycle', skyPool: ['unknown', 'aurora', 'aurora'], cycleIndex: -8 }, lib.constellations, skies.skies);
assert.equal(invalid.count, 8);
assert.equal(invalid.ids.length, 8); assert.equal(invalid.ids[0], example.ids[0]);
assert.equal(new Set(invalid.ids).size, 8);
assert.equal(invalid.sky, example.sky);
assert.equal(invalid.skyPool.join(','), 'aurora');
assert.equal(invalid.cycleIndex, 0);
// AUD-03: inherited Object keys are not real catalogue entries.
const inheritedIds = ['constructor', 'toString', '__proto__', 'hasOwnProperty'];
const repaired = P.normalizeSetting('test-piece', {
    count: 5, ids: [...inheritedIds, 'removed-id', example.ids[0], example.ids[0]],
    skyMode: 'cycle', skyPool: [...inheritedIds, 'removed-id', 'aurora', 'aurora']
}, lib.constellations, skies.skies);
assert.equal(repaired.ids.length, repaired.count);
assert.equal(repaired.ids[0], example.ids[0]);
assert.equal(new Set(repaired.ids).size, repaired.count);
assert.ok(repaired.ids.every(id => ids.has(id)));
assert.equal(P.selectDefinition(repaired.ids, lib.constellations).length, repaired.count);
assert.equal(repaired.skyPool.join(','), 'aurora');
assert.equal(P.normalizePool(inheritedIds, skies.skies).join(','), skies.skies[0].id);
// A name is valid if it is actually present in the supplied library.
const custom = [{ id: 'constructor' }, { id: '__proto__' }, { id: 'constructor' }];
assert.equal(P.uniqueIds(custom).join(','), 'constructor,__proto__');
assert.equal(P.normalizeSelection('custom', ['__proto__', 'constructor'], custom, 2).join(','), '__proto__,constructor');
assert.equal(P.normalizePool(['constructor', 'toString'], [{ id: 'constructor' }]).join(','), 'constructor');
// AUD-04: only a confirmed missing file or valid schema authorizes writes.
assert.equal(P.decodePreferences('missing', '').writable, true);
for (const status of ['failed', 'pending', 'unknown']) {
    assert.equal(P.decodePreferences(status, '{"schemaVersion":1,"perArtwork":{}}').writable, false);
}
for (const text of ['', '{', 'null', '[]', '{}',
    '{"schemaVersion":2,"perArtwork":{}}',
    '{"schemaVersion":1,"perArtwork":[]}',
    '{"schemaVersion":1,"perArtwork":{"good":{},"broken":null}}']) {
    const decoded = P.decodePreferences('loaded', text);
    assert.equal(decoded.writable, false, text);
    assert.equal(Object.keys(decoded.perArtwork).length, 0);
}
const validState = P.decodePreferences('loaded',
    '{"schemaVersion":1,"perArtwork":{"absent-artwork":{"count":3},"__proto__":{"count":2},"constructor":{"count":1}}}');
assert.equal(validState.writable, true);
assert.equal(Object.getPrototypeOf(validState.perArtwork), null);
assert.equal(validState.perArtwork['absent-artwork'].count, 3);
assert.equal(validState.perArtwork.__proto__.count, 2);
assert.equal(validState.perArtwork.constructor.count, 1);
assert.equal(P.decodePreferences('loaded', '{"schemaVersion":1,"perArtwork":{}}').writable, true);
// AUD-08: encode exactly once; never treat filenames as URL syntax.
for (const name of ['space name-g.jpg', 'hash#-g.png', 'what?-g.webp',
    '100%-g.jpeg', 'literal%23-g.png', 'café 星-g.PNG']) {
    const segment = P.artworkFileSegment(name);
    assert.equal(segment, encodeURIComponent(name));
    assert.equal(decodeURIComponent(segment), name);
    assert.ok(!/[#?\/\\]/.test(segment));
}
assert.equal(P.artworkFileSegment('literal%23-g.png'), 'literal%2523-g.png');
for (const bad of ['../x-g.png', 'folder/x-g.png', 'folder\\x-g.png',
    'https://example.test/x-g.png', 'x.png', 'bad\0-g.png', '\ud800-g.png', null])
    assert.equal(P.artworkFileSegment(bad), '');
const loop = { ...example, skyMode: 'cycle', skyPool: ['aurora', 'atlas'], cycleIndex: 0 };
assert.equal(P.pickSky(loop, skies.skies, false), 'aurora');
loop.cycleIndex = 1; assert.equal(P.pickSky(loop, skies.skies, false), 'atlas');
loop.cycleIndex = 2; assert.equal(P.pickSky(loop, skies.skies, false), 'aurora');
// AUD-07: keep distances isotropic and seeds exactly on their rendered star.
const close = (a,b) => assert.ok(Math.abs(a-b)<1e-8, a+' != '+b);
const geometryDefs = lib.constellations.slice(0,8);
for (const count of [1,5,8]) {
    const defs = geometryDefs.slice(0,count);
    const slot = 282/count;
    for (let i=0;i<count;i++) {
        const fit = P.fitFigure(i*slot+slot*.07,18,slot*.86,99);
        const a=P.figurePoint(fit,{x:0,y:0}), b=P.figurePoint(fit,{x:1,y:1});
        close(b.x-a.x,b.y-a.y);
        assert.ok(a.x>=i*slot && b.x<=(i+1)*slot+1e-8);
        assert.ok(a.y>=18 && b.y<=117+1e-8);
    }
    for (const [w,h] of [[1920,1080],[1080,1920],[1280,720],[2560,1440],[1000,1000],[801,601]]) {
        const cells=P.skyCells(defs,w,h), slots=P.layoutCells(defs);
        const seeds=P.skySeeds(defs,w,h);
        assert.equal(cells.length,count);
        assert.equal(seeds.length,count);
        for(let i=0;i<count;i++) {
            const cell=cells[i], slot=slots[i], fit=cell.fit;
            assert.equal(cell.id,defs[i].id);
            assert.equal(cell.definition,defs[i]);
            const a=P.figurePoint(fit,{x:0,y:0}), b=P.figurePoint(fit,{x:1,y:1});
            close(b.x-a.x,b.y-a.y);
            close((a.x+b.x)/2,(slot.x+slot.w/2)*w);
            close((a.y+b.y)/2,(slot.y+slot.h/2)*h);
            assert.ok(a.x>=slot.x*w-1e-8 && b.x<=(slot.x+slot.w)*w+1e-8);
            assert.ok(a.y>=slot.y*h-1e-8 && b.y<=(slot.y+slot.h)*h+1e-8);
            const stars=defs[i].stars;
            const brightest=stars.reduce((a,b)=>b.brightness>a.brightness?b:a);
            const point=P.figurePoint(fit,brightest);
            close(seeds[i][0]*w,point.x);
            close(seeds[i][1]*h,point.y);
        }
    }
}
assert.equal(P.skySeeds(geometryDefs,0,720).length,0);
assert.equal(P.skySeeds([],1920,1080).length,0);
// AUD-06: mathematical raster-grid check, not a GPU test. Simulate
// normalized fragment spacing for integer physical raster extents.
for (const scale of [1,1.25,1.5,2]) {
    for (const logical of [801,1080,1920]) {
        const physical=Math.round(logical*scale);
        const extent=Math.floor(1/(1/physical)+.5);
        assert.equal(extent,physical);
        for(let p=0;p<physical;p++)
            assert.equal(Math.floor(((p+.5)/physical)*extent),p);
    }
}
const drum = file('quickshell/widgets/GalleryDrum.qml');
const sky = file('quickshell/widgets/GallerySkyMap.qml');
const viewer = file('quickshell/panels/GalleryFullViewer.qml');
const catalogue = file('quickshell/services/GalleryCatalogue.qml');
const gallery = file('quickshell/panels/CelestialGallery.qml');
const shell = file('quickshell/shell.qml');
const shader = file('quickshell/shaders/gallery-colonies.frag');
for (const t of [drum, sky]) assert.match(t, /\.stars\|\|\[\]/);
for (const t of [drum, sky]) assert.match(t, /\.edges\|\|\[\]/);
assert.match(drum, /copy<2/);
assert.match(gallery, /rotationSeconds\/900/);
assert.match(gallery, /rotationSeconds\+1\)%900/);
assert.match(gallery, /Widgets.GalleryDrum/);
assert.doesNotMatch(gallery, /drum-skin-/);
assert.match(gallery, /catalogue\.prepareOpening\(\)/);
assert.match(viewer, /constellationsSnapshot/);
assert.match(viewer, /presentation\|\|/);
assert.match(viewer, /ShaderEffectSource/);
assert.match(viewer, /property var constellationTexture:skyTexture/);
assert.match(viewer, /acceptedButtons:Qt.RightButton/);
assert.match(viewer, /fullImage\.paintedWidth/);
assert.match(viewer, /editor\.openEditor\(artworkId\)/);
assert.equal((viewer.match(/viewer\.editViewedArtwork\(\)/g) || []).length, 3);
assert.match(viewer, /artworkId=presentation && presentation\.artId/);
assert.match(gallery, /openingSnapshot=catalogue \? catalogue\.prepareOpening\(\)/);
assert.match(gallery, /viewer\.openGallery\(shot\.source,shot\.title,shot\.artist,shot\)/);
assert.equal((gallery.match(/catalogue\.prepareOpening\(\)/g) || []).length, 1);
assert.match(shell, /selectionLocked: celestialGallery\.focusing \|\| galleryViewer\.phase !== "idle" \|\| galleryEditor\.opened/);
assert.match(catalogue, /if \(!selectionLocked && items\.length\) selectedIndex=/);
assert.match(catalogue, /Policy\.artworkFileSegment\(selected\.file\)/);
assert.match(catalogue, /if \(!Policy\.artworkFileSegment\(a\.file\)\) continue/);
// Execute the actual synchronous QML JS functions in a synthetic context.
// This verifies logic, not Qt signals, timers, URL parsing or input delivery.
const openingCode = catalogue.slice(catalogue.indexOf('    function prepareOpening()'),
    catalogue.indexOf('    function step(n)'));
const state = {
    Policy: P, currentId: 'A', artUrl: 'file:///A-g.png', title: 'A', artist: 'Artist A',
    library: lib.constellations, skies: skies.skies,
    currentSetting: { ...P.createSetting('A', lib.constellations, skies.skies),
        skyMode: 'cycle', skyPool: ['aurora', 'atlas'], cycleIndex: 0 },
    advances: 0,
    ensureSelected() { throw Error('unexpected default initialization'); }
};
state.setCurrentSetting = values => { state.advances++; state.currentSetting = {...state.currentSetting, ...values}; };
const openingContext = vm.createContext(state);
vm.runInContext(openingCode, openingContext);
const shot = openingContext.prepareOpening();
assert.equal(shot.artId, 'A');
assert.equal(shot.source, 'file:///A-g.png');
assert.equal(shot.sky.id, 'aurora');
assert.equal(state.advances, 1);
assert.equal(state.currentSetting.cycleIndex, 1);
state.currentId = 'B'; state.artUrl = 'file:///B-g.png'; state.title = 'B';
assert.equal(shot.artId, 'A'); assert.equal(shot.title, 'A');
assert.equal(shot.source, 'file:///A-g.png'); assert.equal(shot.sky.id, 'aurora');
state.library = [];
assert.equal(openingContext.prepareOpening().artId, 'B');
assert.equal(state.advances, 1);
const focusCode = gallery.slice(gallery.indexOf('    function requestFocus()'),
    gallery.indexOf('    function completeReturn()'));
let captures = 0, starts = 0;
const focusState = {
    focusing: false, displayMode: 'full', viewer: {phase:'idle'}, editor: {opened:false},
    catalogue: {initialized:true, prepareOpening() { captures++; return shot; }},
    openingSnapshot:null, setIdle() {}, scopeToFocus:{stop(){},start(){starts++;}}
};
const focusContext = vm.createContext(focusState);
vm.runInContext(focusCode, focusContext);
focusContext.requestFocus(); focusContext.requestFocus();
assert.equal(captures, 1); assert.equal(starts, 1);
assert.equal(focusState.openingSnapshot.artId, 'A');
focusState.focusing = false; focusState.editor.opened = true;
focusContext.requestFocus(); assert.equal(captures, 1);
assert.match(shader, /pixel=floor\(uv\*dims\)/);
assert.match(shader, /vec2 uvStep=vec2\(length\(dFdx\(uv\)\),length\(dFdy\(uv\)\)\)/);
assert.match(shader, /dims=max\(floor\(1\.0\/uvStep\+0\.5\),vec2\(1\.0\)\)/);
assert.match(shader, /colorAt\(uv,pixel,dims\)/);
assert.match(drum, /Policy\.fitFigure\(left\+slot\*\.07,18,slot\*\.86,99\)/);
assert.match(drum, /Policy\.figurePoint\(fit,star\)/);
assert.match(sky, /Policy\.skyCells\(sky\.constellations\|\|\[\],width,height\)/);
assert.match(sky, /Policy\.figurePoint\(cell\.fit,p\)/);
assert.match(viewer, /seedLayout: Policy\.skySeeds\(constellationsSnapshot,keySurface\.width,keySurface\.height\)/);
assert.match(viewer, /colonySeedCount: seedLayout\.length/);
assert.match(shader, /layout\(binding=1\) uniform sampler2D constellationTexture/);
assert.match(shader, /seedPoint\(i\)/);
assert.match(shader, /skyMode/);
// AUD-01 source contract: a captured chart has premultiplied RGB and
// coverage and item opacity must attenuate every output channel.
assert.match(shader, /color\s*=\s*color\s*\*\s*\(1\.0\s*-\s*chart\.a\s*\*\s*\.85\)\s*\+\s*chart\.rgb\s*\*\s*\.85/);
assert.match(shader, /fragColor\s*=\s*vec4\(color\s*\*\s*a\s*,\s*a\)\s*\*\s*qt_Opacity\s*;/);
assert.match(catalogue, /Quickshell\.statePath\("gallery-customization\.json"\)/);
assert.match(catalogue, /atomicWrites: *true/);
// Static wiring checks; actual FileView I/O requires Quickshell runtime.
assert.match(catalogue, /error === FileViewError\.FileNotFound \? "missing" : "failed"/);
assert.match(catalogue, /stateReadStatus === "pending"\) return/);
assert.match(catalogue, /preferencesWritable=decoded\.writable && library\.length > 0 && skies\.length > 0/);
assert.match(catalogue, /if \(!preferencesWritable\) return;\s*stateFile\.setText/);
assert.equal((catalogue.match(/stateFile\.setText\(/g) || []).length, 1);
assert.match(catalogue, /property var settingsById: Object\.create\(null\)/);
assert.match(catalogue, /function prepareOpening\(\)/);
assert.match(catalogue, /function toggleConstellation\(id\)/);
assert.match(catalogue, /function toggleSkyPool\(id\)/);
assert.match(catalogue, /Preserve settings for temporarily absent entries/);
assert.match(shell, /Panels.GalleryCelestialEditor/);
assert.match(shell, /editor: galleryEditor/);
const editor = file('quickshell/panels/GalleryCelestialEditor.qml');
assert.match(editor, /RESET THIS ARTWORK/);
assert.match(editor, /text:editor\.catalogue \? editor\.catalogue\.lastWarning : ""/);
assert.match(editor, /CYCLE SELECTED SKIES/);
assert.match(editor, /function openEditor\(expectedId\)/);
assert.match(editor, /expectedId !== undefined && expectedId !== catalogue\.currentId/);
assert.match(editor, /editor\.catalogue\.currentId!==editor\.editingArtId/);
const patch5 = file('quickshell/widgets/GalleryDome.qml');
assert.match(patch5, /20\+11\+k\*29/);
const patch5frag = file('quickshell/shaders/gallery-dome.frag');
assert.match(patch5frag, /29\.0/);
console.log(`Batch 11 source-policy checks passed: ${lib.constellations.length} original constellations, ${skies.skies.length} skies, 250 default assignments, canonical drum + sky, per-art persistence and editor wiring.`);
console.log('Not tested: qmllint, native Quickshell, GLSL/qsb compilation, right-click under Wayland, real player, GPU timing.');
