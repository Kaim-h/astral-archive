// Run with: node scripts/check-windows.js
// Pure JS tests only; these do NOT verify Quickshell or compositor behavior.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const file = path.resolve(__dirname, '../quickshell/services/WindowModel.js');
const ctx = vm.createContext({});
vm.runInContext(fs.readFileSync(file, 'utf8'), ctx, { filename: file });
const plain = a => Array.from(a);
let count = 0;
function test(name, fn) { fn(); console.log('✓', name); count++; }
test('normalizes window addresses', () => {
    assert.equal(ctx.cleanAddress(' 0xABCD '), '0xabcd');
    assert.equal(ctx.cleanAddress(null), '');
});
test('newly focused window moves to the front', () => {
    assert.deepEqual(plain(ctx.noteFocus(['0x1', '0x2'], '0x2', 20)), ['0x2', '0x1']);
});
test('empty address does not create ghost entries', () => {
    assert.deepEqual(plain(ctx.noteFocus(['0x1'], '', 20)), ['0x1']);
});
test('history is bounded and unique', () => {
    assert.deepEqual(plain(ctx.noteFocus(['0x3', '0x2', '0x1', '0x2'], '0x4', 3)), ['0x4', '0x3', '0x2']);
});
test('closed windows disappear from history', () => {
    assert.deepEqual(plain(ctx.pruneFocus(['0x3', '0x2', '0x1'], ['0x1', '0x3'])), ['0x3', '0x1']);
});
const windows = [
    { address: '0x1', title: 'Research' },
    { address: '0x2', title: 'Email' },
    { address: '0x3', title: 'Documentation' }
];
test('recently focused window is chosen before source order', () => {
    assert.equal(ctx.chooseRecent(windows, ['0x3', '0x2'], '').title, 'Documentation');
});
test('currently active window wins when available', () => {
    assert.equal(ctx.chooseRecent(windows, ['0x3', '0x2'], '0x1').title, 'Research');
});
test('untracked windows use stable original ordering', () => {
    assert.deepEqual(plain(ctx.orderByRecency(windows, [], '')).map(x => x.title),
        ['Research', 'Email', 'Documentation']);
});
test('windowless apps produce no choice', () => {
    assert.equal(ctx.chooseRecent([], ['0x3'], '0x1'), null);
});
test('addresses missing temporarily do not steal first place', () => {
    const list = [{ address: '', title: 'Pending' }, { address: '0x1', title: 'Known' }];
    assert.equal(ctx.chooseRecent(list, ['0x1'], '').title, 'Known');
});
test('source ordering is never mutated', () => {
    ctx.orderByRecency(windows, ['0x3'], '');
    assert.equal(windows[0].title, 'Research');
});
console.log(`\n${count} pure window-policy checks passed.`);


// AUD-10: all installed entries contribute, including hidden entries when exposed.
const matching=vm.createContext({});
const source=p=>fs.readFileSync(path.resolve(__dirname,"..",p),"utf8");
vm.runInContext(source("quickshell/services/AppMatching.js"),matching);
const a={appId:"org.example.editor",startupClass:"",title:"A"};
const b={appId:"com.other.editor",startupClass:"",title:"B"};
const exact={appId:"editor",startupClass:"",title:"Exact"};
const explicit={appId:"org.example.paint",startupClass:"EDITOR",title:"Explicit"};
const resolve=(apps,key)=>matching.resolveWindowId(matching.buildWindowIndex(apps),key);
test("suffix collision remains unresolved",()=>{
 assert.equal(resolve([a,b],"editor"),null);
 assert.equal(resolve([b,a],"EDITOR"),null);
 assert.equal(resolve([a],"editor"),a.appId);
 assert.equal(resolve([a,b],a.appId),a.appId);
});
test("full ID beats class and suffix; class beats suffix",()=>{
 assert.equal(resolve([a,b,explicit,exact],"EDITOR.desktop"),exact.appId);
 assert.equal(resolve([a,b,explicit],"editor"),explicit.appId);
 assert.equal(resolve([explicit,{appId:"other.paint",startupClass:"editor"}],"editor"),null);
 assert.equal(resolve([a,{appId:a.appId.toUpperCase()}],a.appId),null);
 assert.equal(resolve([{id:"hidden.editor",noDisplay:true},a],"editor"),null);
 assert.equal(resolve([{id:"org.kde.konsole.desktop"}],"konsole"),"org.kde.konsole.desktop");
 assert.equal(resolve([{appId:"constructor"}],"constructor"),"constructor");
 assert.equal(resolve([],"constructor"),null);
 assert.equal(resolve([a],""),null);
 assert.equal(resolve([a,a],"editor"),a.appId);
 assert.equal(matching.matchesWindow(a,"editor"),false);
});
// Actual synchronous QML functions in mock desktop/compositor contexts.
const winSource=source("quickshell/services/WindowService.qml");
const appSource=source("quickshell/services/ApplicationService.qml");
const modelCode=winSource.slice(winSource.indexOf("    function hyprInfo("),winSource.indexOf("    Connections {"));
const appCode=appSource.slice(appSource.indexOf("    function buildCatalogue("),appSource.lastIndexOf("\n}"));
const live={appId:"editor",title:"Ambiguous window",HyprlandToplevel:{address:"0x1",workspace:{name:"1",id:1}},activate(){live.focuses++},focuses:0};
const da={id:a.appId,name:a.title,startupClass:"",execute(){da.launches++},launches:0};
const db={id:b.appId,name:b.title,startupClass:"",execute(){db.launches++},launches:0};
const de={id:exact.appId,name:exact.title,startupClass:"",execute(){de.launches++},launches:0};
const hypr={toplevels:{values:[live]},activeToplevel:live};
const desktop={applications:{values:[da,db]},byId(id){return this.applications.values.find(x=>x.id===id)}};
const win=vm.createContext({Matching:matching,Model:ctx,Hyprland:hypr,refreshSerial:0,focusHistory:[],console});
Object.defineProperty(win,"identityIndex",{get(){return matching.buildWindowIndex(desktop.applications.values)}});
vm.runInContext(modelCode,win);
const svc=vm.createContext({Matching:matching,Hyprland:hypr,DesktopEntries:desktop,windowService:win,pinnedIds:[],focusedAppIdOverride:"",console});
svc.service=svc;
Object.defineProperty(svc,"identityIndex",{get(){return win.identityIndex}});
vm.runInContext(appCode,svc);
test("shared resolver drives books, counts, chooser and activation",()=>{
 assert.equal(win.windowCount(a),0);assert.equal(win.windowCount(b),0);
 assert.equal(svc.booksFor([a])[0].running,false);
 assert.equal(svc.booksFor([b])[0].focused,false);
 assert.equal(svc.activate(a.appId),"launch-requested");
 assert.equal(da.launches,1);assert.equal(live.focuses,0);
 assert.equal(svc.focusSpecific(a.appId,"0x1"),"window-gone");
 desktop.applications.values.push(de);
 assert.equal(win.windowCount(a),0);assert.equal(win.windowCount(exact),1);
 assert.equal(svc.booksFor([exact])[0].focused,true);
 assert.equal(win.windowsFor(exact)[0].address,"0x1");
 assert.equal(svc.activate(exact.appId),"focus-requested");assert.equal(live.focuses,1);
 assert.equal(svc.focusSpecific(a.appId,"0x1"),"window-gone");
 assert.equal(svc.focusSpecific(exact.appId,"0x1"),"focus-requested");assert.equal(live.focuses,2);
 hypr.toplevels.values=[];
 assert.equal(svc.focusSpecific(exact.appId,"0x1"),"window-gone");assert.equal(live.focuses,2);
 hypr.toplevels.values=[live];desktop.applications.values=[da,db];
 svc.windowService=null;
 assert.equal(svc.activate(a.appId),"launch-requested");assert.equal(live.focuses,2);
 assert.equal(svc.booksFor([a])[0].running,false);
});
assert.match(winSource,/identityIndex: Matching\.buildWindowIndex\(DesktopEntries\.applications\.values\)/);
assert.match(appSource,/identityIndex: windowService \? windowService\.identityIndex/);
assert.match(appSource,/Matching\.matchesWindow\(app, previous, service\.identityIndex\)/);
assert.match(appSource,/Matching\.matchesWindow\(app, active\.appId, service\.identityIndex\)/);
console.log("PASS AUD-10: global identity, collisions and consistent window/launcher actions.");
