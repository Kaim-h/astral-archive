#!/usr/bin/env node
"use strict";
// Lightweight static and policy checks. Not a QML, GLSL or Wayland test.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '..');
const read = p => fs.readFileSync(path.join(root,p),'utf8');
const ctx = { Math, Date, isFinite, Array, Number, String, console };
vm.createContext(ctx);
vm.runInContext(read('quickshell/services/VistaPolicy.js'),ctx);
const m = JSON.parse(read('quickshell/data/veranda-wallpapers.json'));
const items = ctx.normalizeManifest(m);
assert.equal(items.length, 29);
assert.ok(items.every(a => a.subjectOutline === false));
const mock = { wallpapers: [{id:'test',file:'test.jpg',title:'Test',artist:'Artist',
                            themes:['evening'],subjectOutline:true}] };
assert.equal(ctx.normalizeManifest(mock)[0].subjectOutline, true);
assert.deepEqual(Array.from(ctx.wallpaperCommand('/tmp/a b.jpg',false)),
                 ['awww','img','--transition-type','none','--','/tmp/a b.jpg']);
assert.match(ctx.wallpaperCommand('/tmp/a.jpg',true).join(' '), /fade/);
const svc=read('quickshell/services/VerandaService.qml');
assert.match(svc,/transitionLayer: null/);
assert.match(svc,/function transitionSwap\(/);
assert.match(svc,/function transitionAborted\(/);
assert.match(svc,/startBackend\(pending.path,false\)/);
assert.match(svc,/lastKnownWallpaperPath/);
assert.match(svc,/if \(transitionEnabled && fx/);
const shell=read('quickshell/shell.qml');
assert.match(shell,/Widgets\.VistaTransition/);
assert.match(shell,/transitionLayer: vistaFx/);
assert.match(shell,/onAborted/);
const fx=read('quickshell/widgets/VistaTransition.qml');
assert.match(fx,/WlrLayer\.Bottom/);
assert.match(fx,/mask: Region/);
assert.match(fx,/ShaderEffect/);
assert.match(fx,/ShaderEffect\.Compiled/);
assert.match(fx,/onTriggered: fx\.abort/);
assert.match(fx,/signal swapRequested/);
assert.match(fx,/signal aborted/);
const shader=read('quickshell/shaders/vista-transition.frag');
assert.match(shader,/#version 440/);
assert.match(shader,/colonyArrival/);
assert.match(shader,/subjectTexture/);
assert.match(shader,/qt_Opacity/);
assert.match(read('scripts/compile-vista-shader.sh'),/\bqsb\b/);
assert.match(read('scripts/prepare-vista-outlines.py'),/distance_transform_edt/);
console.log('Vista FX structure OK — pixel colonies, optional cached outlines, animation toggle and fallback.');
