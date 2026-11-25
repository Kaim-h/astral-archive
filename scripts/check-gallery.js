#!/usr/bin/env node
'use strict';
// Static/offline assertions, NOT a substitute for qmllint or a Hyprland run.
const fs = require('fs'), path = require('path'), assert = require('assert');
const root = path.resolve(__dirname, '..');
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const have = p => assert(fs.existsSync(path.join(root, p)), `Missing ${p}`);
const gallery = ['quickshell/panels/CelestialGallery.qml', 'quickshell/panels/GalleryFullViewer.qml',
    'quickshell/widgets/GalleryArtwork.qml', 'quickshell/widgets/GalleryDome.qml',
    'quickshell/widgets/GalleryDrum.qml', 'quickshell/widgets/GallerySkyMap.qml',
    'quickshell/widgets/GalleryMusic.qml', 'quickshell/services/GalleryCatalogue.qml',
    'quickshell/services/GalleryPolicy.js', 'quickshell/panels/GalleryCelestialEditor.qml',
    'quickshell/config/GalleryGeometry.js', 'quickshell/data/gallery-artworks.json',
    'quickshell/data/gallery-constellations.json', 'quickshell/data/gallery-sky-presets.json',
    'quickshell/shaders/gallery-colonies.frag', 'quickshell/shaders/gallery-dome.frag',
    'scripts/compile-gallery-effects.sh'];
for (const f of gallery) have(f);
for (const theme of ['twilight', 'evening', 'midnight']) {
    for (const prefix of ['architecture', 'drum-skin']) {
        const name = `quickshell/assets/gallery/${prefix}-${theme}.svg`; have(name);
        const s = read(name); assert(s.includes('viewBox=') && s.includes('xmlns='), `${name} invalid-looking SVG`);
    }
}
const s = read('quickshell/panels/CelestialGallery.qml');
assert(s.includes('interval:1000') && s.includes('%900'), 'Drum should update once a second over 900s');
assert(s.includes('Widgets.GalleryDrum') && read('quickshell/widgets/GalleryDrum.qml').includes('width:282'),
    'The 282px drum now lives in a single canonical Canvas component');
assert(s.includes('designScale: .8'), 'Default scale must be 80%');
assert(!s.includes('staticConstellations'), 'Do not restore separate stationary markings');
assert(s.includes('GalleryMusic') && s.includes('GalleryArtwork') && s.includes('GalleryDome') && s.includes('GalleryDrum'));
assert(s.includes('displayMode: "hidden"') && s.includes('musicOnly()') && s.includes('hideGallery()'));
const d = read('quickshell/widgets/GalleryDome.qml');
assert(d.includes('164*164') && d.includes('yaw-20') && d.includes('yaw+20'));
assert(d.includes('slitLo') === false || d.includes('domeEngravings'), 'Slit-adjacent engravings needed');
const art = read('quickshell/widgets/GalleryArtwork.qml');
assert(art.includes('sourceFraction: .60') && art.includes('ctx.clip()'));
const viewer = read('quickshell/panels/GalleryFullViewer.qml');
assert(viewer.includes('Image.PreserveAspectFit') && viewer.includes('fullImage.paintedWidth'));
const music = read('quickshell/widgets/GalleryMusic.qml');
assert(music.includes('import Quickshell.Services.Mpris') && music.includes('canTogglePlaying'));
assert(music.includes('Library integration pending'));
const shader = read('quickshell/shaders/gallery-colonies.frag');
assert(shader.includes('pixel=floor(uv*dims)') && !shader.includes('/4.0'));
const shell = read('quickshell/shell.qml');
assert(shell.includes('name: "celestial-gallery"'));
assert(shell.includes('Panels.GalleryFullViewer') && shell.includes('Panels.CelestialGallery') && shell.includes('Panels.GalleryCelestialEditor'));
const meta = JSON.parse(read('quickshell/data/gallery-artworks.json'));
assert(Array.isArray(meta.artworks), 'Expected artworks manifest');
assert(JSON.parse(read('quickshell/data/gallery-constellations.json')).constellations.length >= 10);
assert(JSON.parse(read('quickshell/data/gallery-sky-presets.json')).skies.length >= 4);
// Lightweight delimiter tracking in QML: excludes strings and JS // + /* comments.
function checkBalanced(text, file) {
    let stack = [], i = 0, state = 'code';
    while (i < text.length) {
        let c = text[i], n = text[i + 1];
        if (state === 'line') { if (c === '\n') state = 'code'; i++; continue; }
        if (state === 'block') { if (c === '*' && n === '/') { i += 2; state = 'code'; } else i++; continue; }
        if (state === 'string') { if (c === '\\') { i += 2; continue; } if (c === quote) state = 'code'; i++; continue; }
        if (c === '/' && n === '/') { state = 'line'; i += 2; continue; }
        if (c === '/' && n === '*') { state = 'block'; i += 2; continue; }
        if (c === '"' || c === "'" || c === '`') { var quote = c; state = 'string'; i++; continue; }
        if ('({['.includes(c)) stack.push([c, i]);
        else if (')}]'.includes(c)) { const a = stack.pop(); assert(a && '({['[')}]'.indexOf(c)] === a[0], `Unbalanced ${file} near ${i}`) }
        i++;
    }
    assert(stack.length === 0, `Unclosed delimiters in ${file}`);
}
for (const f of gallery.filter(x => x.endsWith('.qml') || x.endsWith('.js'))) checkBalanced(read(f), f);
console.log('Gallery static checks passed: QML structure, manifests, themed assets, the shared 15m drum and sky, and fullscreen transitions.');
console.log('Not tested: native QML parsing, Quickshell imports, QtSvg runtime, compiled shader, or visual fidelity.');


// AUD-13: execute actual refresh and event bodies with synthetic player
// properties. Native MPRIS signal delivery is a separate acceptance test.
const vm=require("node:vm");
const refresh=music.slice(music.indexOf("    function refreshProgress()"),music.indexOf("    onPlayerChanged:"));
const ms=vm.createContext({player:null,progress:1,active:true,visible:true});
ms.music=ms;
vm.runInContext(refresh,ms);
function event(name){
 const match=music.match(new RegExp("function on"+name+"\\(\\) \\{([^}]+)\\}"));
 assert(match,"missing event "+name);vm.runInContext(match[1],ms);
}
ms.refreshProgress();assert.strictEqual(ms.progress,0);
ms.player={positionSupported:true,lengthSupported:true,position:20,length:100};
ms.refreshProgress();assert.strictEqual(ms.progress,.2);
ms.player.position=65;event("PositionChanged");assert.strictEqual(ms.progress,.65);
ms.player.position=0;ms.player.length=200;event("PostTrackChanged");assert.strictEqual(ms.progress,0);
ms.player.position=50;event("PlaybackStateChanged");assert.strictEqual(ms.progress,.25);
ms.player.length=100;event("LengthChanged");assert.strictEqual(ms.progress,.5);
ms.player.positionSupported=false;event("PositionSupportedChanged");assert.strictEqual(ms.progress,0);
ms.player.positionSupported=true;ms.player.lengthSupported=false;event("LengthSupportedChanged");assert.strictEqual(ms.progress,0);
ms.player.lengthSupported=true;ms.player.position=Infinity;event("PositionChanged");assert.strictEqual(ms.progress,0);
ms.player.position=150;event("PositionChanged");assert.strictEqual(ms.progress,1);
ms.player.position=-10;event("PositionChanged");assert.strictEqual(ms.progress,0);
ms.player.position=25;
for(const hook of ["onActiveChanged: if(active) refreshProgress()","onVisibleChanged: if(visible) refreshProgress()"]){
 assert(music.includes(hook));ms.progress=0;vm.runInContext(hook.split(": ")[1],ms);assert.strictEqual(ms.progress,.25);
}
ms.player=null;ms.refreshProgress();assert.strictEqual(ms.progress,0);
assert(music.includes("target: music.player"));
assert(music.includes("running: music.active && music.visible && !!music.player && music.isPlaying"));
assert(music.includes("interval: 1000;repeat:true"));
assert(music.includes("if(music.player) music.player.positionChanged()"));
console.log("PASS AUD-13: progress math, paused seek/track/length, capability, playback and visibility event bodies.");
