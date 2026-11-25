// Run with: node scripts/check-launcher.js
// Tiny, fast tests for non-visual launcher behavior; no Linux required.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const file = `${__dirname}/../quickshell/services/LauncherModel.js`;
const ctx = vm.createContext({});
vm.runInContext(fs.readFileSync(file, 'utf8'), ctx, {filename: file});
const apps = [
    {appId:'org.kde.dolphin',title:'Dolphin',keywords:'files'},
    {appId:'org.kde.konsole',title:'Konsole',keywords:'terminal'},
    {appId:'firefox',title:'Firefox',keywords:'browser'},
    {appId:'org.kde.kate',title:'Kate',keywords:'editor'},
    {appId:'vlc',title:'VLC',keywords:'music'},
    {appId:'krita',title:'Krita',keywords:'painting'},
    {appId:'gimp',title:'GIMP',keywords:'image'},
    {appId:'calibre',title:'Calibre',keywords:'books'},
    {appId:'thunderbird',title:'Thunderbird',keywords:'mail'}
];
let count = 0;
function test(name, fn) { fn(); console.log('✓', name); count++; }
test('installed pinned apps retain configured order',()=>{
    const a = Array.from(ctx.homeApplications(apps,['firefox','org.kde.dolphin.desktop'],3),x=>x.appId);
    assert.deepEqual(a,['firefox','org.kde.dolphin','org.kde.konsole']);
});
test('missing pins are ignored and gaps filled',()=>{
    assert.equal(ctx.homeApplications(apps,['missing'],4).length,4);
});
test('home view stays deliberately small',()=>{
    const page=ctx.pageView(apps,['firefox'], '',false,0,6,8);
    assert.equal(page.items.length,6); assert.equal(page.mode,'study');
});
test('the Index opens the whole catalogue',()=>{
    const page=ctx.pageView(apps,[], '',true,0,6,8);
    assert.equal(page.total,9); assert.equal(page.pages,2);
});
test('search scans all installed apps, not just pinned',()=>{
    const page=ctx.pageView(apps,['firefox'], 'PAINT',false,0,6,8);
    assert.equal(page.items[0].appId,'krita'); assert.equal(page.mode,'search');
});
test('search also matches the full app ID',()=>{
    assert.equal(ctx.searchMatches(apps[0], 'org.kde.dolphin'),true);
});
test('empty results are safe',()=>{
    const page=ctx.pageView(apps,[], 'nope-9999',false,4,6,8);
    assert.equal(page.items.length,0); assert.equal(page.page,0);
});
test('out-of-range page is clamped',()=>{
    assert.equal(ctx.pageView(apps,[], '',true,900,6,8).page,1);
});
test('Index right arrow enters first shelf',()=>{
    assert.equal(ctx.arrowSelection(-1,'right',6,4),0);
});
test('Index left arrow enters last book',()=>{
    assert.equal(ctx.arrowSelection(-1,'left',6,4),5);
});
test('down arrow follows the second shelf',()=>{
    assert.equal(ctx.arrowSelection(1,'down',6,4),5);
});
test('down from bottom shelf returns to Index',()=>{
    assert.equal(ctx.arrowSelection(5,'down',6,4),-1);
});
test('empty shelf keeps Index selected',()=>{
    assert.equal(ctx.arrowSelection(-1,'right',0,4),-1);
});
console.log(`\n${count} launcher logic checks passed.`);
