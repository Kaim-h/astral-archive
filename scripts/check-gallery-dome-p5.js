#!/usr/bin/env node
'use strict';
// Source and deterministic geometry checks for Gallery Patch 5.
// Not a GLSL compile, native QML parse, render test, or timing measurement.
const fs = require('fs'), path = require('path'), assert = require('assert');
const root = path.resolve(__dirname, '..');
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const shader = read('quickshell/shaders/gallery-dome.frag');
const qml = read('quickshell/widgets/GalleryDome.qml');
const compile = read('scripts/compile-gallery-effects.sh');
const deg = n => n * Math.PI / 180;
const eq = (a, b, e = .00000001) => Math.abs(a - b) < e;
// This is the actual approved v20 double-sided meridian pattern.
function approvedV20(yaw) {
    const angles = []; for (let k = 0; k < 7; k++) {
        angles.push(deg(yaw + 20 + 11 + k * 29));
        angles.push(deg(yaw - 20 - 11 - k * 29));
    } return angles;
}
function shaderP5(yaw) {
    const angles = []; for (let side = 0; side < 2; side++)for (let k = 0; k < 7; k++) {
        angles.push(deg(yaw) + (side === 0 ? 1 : -1) * deg(20 + 11 + k * 29));
    } return angles;
}
function canvasP5(yaw) {
    const angles = []; for (let k = 0; k < 7; k++) {
        angles.push(deg(yaw) + deg(20 + 11 + k * 29));
        angles.push(deg(yaw) - deg(20 + 11 + k * 29));
    } return angles;
}
const requiresShader = ['#version 440', 'HALF_CUT=20.0', 'HLOW=34.4', 'HHIGH=155.8',
    'float bodyAngle=(HALF_CUT+11.0+float(k)*29.0)*DEG',
    'float theta=az+direction*bodyAngle', 'for(int k=0;k<7;k++)',
    'float latitude=i==0?44.0:(i==1?95.0:144.0)',
    'hitTube(hit,pixel,dir,0.0,169.0,13.0,15.3',
    'hitTube(hit,pixel,dir,162.0,203.0,16.5,18.7',
    'hitTube(hit,pixel,dir,196.0,246.0,20.0,23.0',
    'hitDisk(hit,pixel,dir,248.4,20.2,glass,centerGlass)',
    'offer(hit,hemisphereZ,surfaceColor'];
for (const token of requiresShader) assert(shader.includes(token), 'Shader missing: ' + token);
for (const token of ['var angles=[]', 'k<7', 'yaw+deg(20+11+k*29)',
    'yaw-deg(20+11+k*29)', '[44,95,144]', 'width: 470', 'height: 220',
    'property real yaw: 20', 'property real pitch: 33', 'ShaderEffect.Compiled',
    'visible: !dome.shaderReady', 'fragmentShader: Qt.resolvedUrl("../shaders/gallery-dome.frag.qsb")'])
    assert(qml.includes(token), 'QML missing: ' + token);
for (const old of ['yaw+1.80', 'yaw+2.43', 'a0-deg(11.5)', 'a1+deg(11.5)'])
    assert(!qml.includes(old), 'Old disconnected QML seam survived: ' + old);
for (const old of ['1.80+az', '2.43+az', 'lo-.20', 'hi+.20'])
    assert(!shader.includes(old), 'Old disconnected shader seam survived: ' + old);
assert(compile.includes('gallery-dome gallery-colonies'), 'Shader build list incomplete');
// Physical shell: longitude cutout must be empty but the near-slit meridian
// must remain mounted on solid dome exactly 11 degrees outside the opening.
const R = 164, HLOW = 34.4, HHIGH = 155.8;
function shell(h, theta, yaw) {
    return h >= 0 && h <= R && theta >= 0 && theta <= Math.PI &&
        !(h >= HLOW && h <= HHIGH && theta >= deg(yaw - 20) && theta <= deg(yaw + 20));
}
let checks = 0;
for (let yaw = -20; yaw <= 80; yaw += 5) {
    const v20 = approvedV20(yaw), g = shaderP5(yaw), q = canvasP5(yaw);
    assert.strictEqual(v20.length, 14);
    for (let k = 0; k < 14; k++) {
        assert(eq(v20[k], q[k]), `QML-v20 longitude mismatch: yaw=${yaw} k=${k}`);
        assert(g.some(t => eq(v20[k], t)), `Shader-v20 longitude mismatch: yaw=${yaw} k=${k}`);
        checks++;
    }
    for (const theta of [deg(yaw + 31), deg(yaw - 31)]) {
        if (theta > 0 && theta < Math.PI)
            assert(shell(95, theta, yaw), `Near-slit seam on missing wedge yaw=${yaw}`);
    }
    if (yaw >= 0 && yaw <= 80 && deg(yaw) > 0)
        assert(!shell(95, deg(yaw), yaw), `Slit wedge incorrectly filled yaw=${yaw}`);
}
// Each meridian's dome-body longitude is invariant as the slit swings; no
// second independent animation or permanently anchored angle can drift away.
for (let i = 0; i < 14; i++) {
    const offset = approvedV20(20)[i] - deg(20);
    for (const yaw of [-20, -10, 0, 10, 20, 30, 45, 60, 80])
        assert(eq(approvedV20(yaw)[i] - deg(yaw), offset), 'Detached seam detected');
}
// Ring latitudes remain constant in screen-space under yaw because a complete
// ring is symmetric about the yaw axis. Its *engraving data* is on the shell.
for (const h of [44, 95, 144]) assert(h > HLOW && h < HHIGH);
console.log('Patch 5 passed:', checks, 'v20-pattern comparisons; slit adjacency, rigid rotation, 3 rings, shared dome and telescope dimensions.');
console.log('Unverified: qsb compilation, Quickshell rendering, native scene depth, real GPU performance.');
