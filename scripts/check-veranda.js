#!/usr/bin/env node
"use strict";
const assert=require("node:assert/strict");
const fs=require("node:fs");
const vm=require("node:vm");
const path=require("node:path");
const root=path.resolve(__dirname,"..");
const file=(rel)=>fs.readFileSync(path.join(root,rel),"utf8");
const ctx={Math,Date,isFinite,Array,String,Number,console};
vm.createContext(ctx);
vm.runInContext(file("quickshell/services/VistaPolicy.js"),ctx,{filename:"VistaPolicy.js"});
const manifest=JSON.parse(file("quickshell/data/veranda-wallpapers.json"));
const all=ctx.normalizeManifest(manifest);
assert.equal(manifest.schemaVersion,1);
assert.equal(all.length,29);
const count=(theme)=>ctx.forTheme(all,theme).length;
assert.equal(count("evening"),10);assert.equal(count("twilight"),10);assert.equal(count("midnight"),9);
assert.equal(count("gallery"),0);
assert.equal(new Set(all.map(a=>a.id)).size,29);
assert.equal(ctx.localDate(new Date(2026,10,16,23,59)),"2026-11-16");
assert.deepEqual(Array.from(ctx.normalizeManifest({wallpapers:[{id:"bad",file:"../oops.jpg",themes:["evening"]}]})),[]);
for(const a of all){
 assert.equal(a.themes.length,1); assert.ok(["evening","twilight","midnight"].includes(a.themes[0]));
 assert.ok(!a.file.toLowerCase().endsWith('-g.jpg'));
 assert.equal(a.titleVerified,false);
}
let state=ctx.initialState();
assert.equal(state.rotationEnabled,true);
assert.equal(state.transitionEnabled,true);
assert.equal(ctx.cleanState({rotationEnabled:false}).transitionEnabled,true,
    "existing Batch 9 state without transitionEnabled should keep fade as default");
assert.equal(ctx.cleanState({transitionEnabled:false}).transitionEnabled,false);
assert.equal(ctx.cleanState({transitionEnabled:"no"}).transitionEnabled,true);
assert.deepEqual(Array.from(ctx.wallpaperCommand("/tmp/painted valley.jpg", true)),
    ["awww","img","--transition-type","fade","--transition-duration","0.85","--","/tmp/painted valley.jpg"]);
assert.deepEqual(Array.from(ctx.wallpaperCommand("/tmp/painted valley.jpg", false)),
    ["awww","img","--transition-type","none","--","/tmp/painted valley.jpg"]);
const oldState=ctx.cleanState({byTheme:{evening:{current:"sample",date:"2026-11-16",queue:[]}}});
oldState.transitionEnabled=false;
assert.equal(ctx.cleanState(oldState).transitionEnabled,false);
let picks=[];
for(let d=1;d<=11;d++){
 let date=`2026-11-${String(d).padStart(2,'0')}`;
 let before=JSON.stringify(state);
 let x=ctx.forDay(state,"evening",date,all,()=>.28);
 assert.equal(JSON.stringify(state),before,"policy must be pure");
 if(d<=10) picks.push(x.id);
 state=x.state;
 let same=ctx.forDay(state,"evening",date,all,()=>.7);
 assert.equal(same.id,x.id,"no change twice in one day");
}
assert.equal(new Set(picks).size,10,"shuffled cycle should not repeat before exhaustion");
let cross=ctx.forDay(state,"midnight","2026-11-11",all,()=>.5);
assert.ok(cross.id);
assert.equal(cross.state.byTheme.evening.current,state.byTheme.evening.current);
let manual=ctx.manualSelection(cross.state,"twilight","2026-11-12",all,ctx.forTheme(all,"twilight")[3].id);
assert.equal(manual.state.byTheme.twilight.current,manual.id);
assert.equal(ctx.forDay(manual.state,"twilight","2026-11-12",all,()=>.3).id,manual.id);
let disabled=ctx.cleanState(manual.state);disabled.rotationEnabled=false;
assert.equal(ctx.forDay(disabled,"twilight","2026-11-19",all,()=>.7).id,manual.id);
assert.equal(ctx.wrappedIndex(-1,4),3);
assert.equal(ctx.selectedIndex([],"none"),-1);
const tile=file("quickshell/widgets/VistaTile.qml");
assert.match(tile,/MultiEffect/);
assert.match(tile,/maskSource: alphaShape/);
assert.match(tile,/Image\.PreserveAspectCrop/);
assert.doesNotMatch(tile,/Shear|Rotation3D|Skew/);
const gui=file("quickshell/panels/VerandaOfVistas.qml");
assert.match(gui,/THE VERANDA OF VISTAS/);
assert.match(gui,/PanelWindow/);
assert.match(gui,/exclusiveZone: 0/);
assert.match(gui,/activeArt\.title/);
assert.match(gui,/activeArt\.artist/);
assert.match(gui,/applyManual/);
// Patch 2 wiring: none of the new components should remain orphaned.
const shell=file("quickshell/shell.qml");
assert.match(shell,/Services\.VerandaService/);
assert.match(shell,/Panels\.VerandaOfVistas/);
assert.match(shell,/name: "veranda-of-vistas"/);
const capsule=file("quickshell/panels/ArchiveCapsule.qml");
assert.match(capsule,/signal verandaRequested\(\)/);
assert.match(capsule,/signal verandaCloseRequested\(\)/);
assert.match(capsule,/onVerandaRequested/);
const utility=file("quickshell/panels/UtilityShelf.qml");
assert.match(utility,/signal verandaRequested\(\)/);
assert.match(utility,/VERANDA OF VISTAS/);
assert.match(gui,/setTransitionEnabled/);
assert.match(gui,/ANIMATION: ON/);
const workflow=file(".github/workflows/logic-checks.yml");
assert.match(workflow,/node scripts\/check-veranda\.js/);
const svc=file("quickshell/services/VerandaService.qml");
assert.match(svc,/Quickshell\.statePath/);
assert.match(svc,/Policy\.wallpaperCommand\(path, animate\)/);
assert.match(svc,/Quickshell\.statePath/);
assert.match(svc,/setTransitionEnabled/);
assert.match(svc,/next\.transitionEnabled=service\.saved\.transitionEnabled/);
assert.match(svc,/onExited/);
assert.match(svc,/60000/);
console.log(`Veranda Patch 3 OK — ${all.length} artworks, daily cycling, persistent animation on/off, awww commands, wiring and CI.`);

// AUD-11/15/12: persisted envelope validation, local filename round-trip,
// and request keys for manual, automatic and in-flight preference changes.
const pref=ctx.initialState();
pref.rotationEnabled=false;
pref.byTheme.twilight={current:all.find(a=>a.themes[0]==="twilight").id,date:"2026-11-24",queue:["missing-local-id"]};
const raw=JSON.stringify(pref);
assert.equal(ctx.decodePreferences("missing","").writable,true);
for(const status of ["pending","failed","unknown"])assert.equal(ctx.decodePreferences(status,raw).writable,false);
for(const malformed of ["","{","null","[]","{}",JSON.stringify({...pref,version:2}),JSON.stringify({...pref,byTheme:[]}),JSON.stringify({...pref,rotationEnabled:"false"}),JSON.stringify({...pref,byTheme:{...pref.byTheme,twilight:{current:"a",date:"",queue:[42]}}})]){
 assert.equal(ctx.decodePreferences("loaded",malformed).writable,false);
}
assert.equal(ctx.decodePreferences("loaded",raw).writable,true);
assert.equal(JSON.stringify(ctx.decodePreferences("loaded",raw).state),raw);
const legacy=JSON.parse(raw);delete legacy.transitionEnabled;
assert.equal(ctx.decodePreferences("loaded",JSON.stringify(legacy)).state.transitionEnabled,true);
assert.equal(ctx.decodePreferences("loaded",JSON.stringify(legacy)).writable,true);
const dir=ctx.localDirectory("file:///tmp/a%20b%23%25/");
assert.equal(dir,"/tmp/a b#%/");
for(const name of ["a b.jpg","雪.jpg","a#b?.jpg","literal%23.jpg","100%.jpg"]){
 const p=ctx.localImagePath(dir,name),u=ctx.localImageUrl(p);
 assert.equal(p,dir+name);
 assert.equal(decodeURIComponent(u.slice(7)),p);
 assert.ok(!/[#?]/.test(u));
 assert.equal(ctx.wallpaperCommand(p,false).at(-1),p);
}
for(const invalid of ["../a.jpg","a/b.jpg","a\\b.jpg","a\0.jpg","\ud800"])assert.equal(ctx.localImagePath(dir,invalid),"");
for(const bad of ["https://example.test/a","file://host/a","file:///tmp/%zz","file:///tmp/a#b"])assert.equal(ctx.localDirectory(bad),"");
const date="2026-11-24",theme="twilight",id=pref.byTheme[theme].current;
const choice=ctx.manualSelection(pref,theme,date,all,id);
assert.equal(ctx.forDay(choice.state,theme,date,all).id,id);
const manualKey=ctx.applicationKey(theme,date,id,false);
assert.equal(manualKey,ctx.applicationKey(theme,"2026-11-25",id,false));
const applied={theme,date,id};
assert.equal(ctx.appliedKey(applied,false),manualKey);
assert.equal(ctx.appliedKey(applied,true),ctx.applicationKey(theme,date,id,true));
assert.notEqual(ctx.appliedKey(applied,true),ctx.applicationKey(theme,"2026-11-25",id,true));
assert.equal(ctx.appliedKey(null,false),"");
assert.notEqual(ctx.appliedKey(applied,false),ctx.applicationKey("evening",date,id,false));
assert.match(svc,/error === FileViewError\.FileNotFound \? "missing" : "failed"/);
assert.match(svc,/if \(!preferencesWritable\) return;\s*stateFile\.setText/);
assert.equal((svc.match(/stateFile\.setText\(/g)||[]).length,1);
assert.match(svc,/preferencesWritable = decoded\.writable && artworks\.length > 0/);
assert.match(svc,/lastAppliedKey=Policy\.appliedKey\(service\.lastSuccessful,next\.rotationEnabled\)/);
assert.match(svc,/Policy\.applicationKey\(themeName,date,result\.id,rotationEnabled\)/);
assert.match(svc,/Policy\.localImagePath\(wallpaperDirectory, art\.file\)/);
assert.match(gui,/wallpaperService\.displayMessage/);
assert.match(file("quickshell/widgets/VistaTransition.qml"),/return Policy\.localImageUrl\(path\)/);
console.log("PASS Veranda audit: recovery guard, literal paths, URL encoding and wallpaper key reconciliation.");

// Execute actual synchronous QML functions and backend callback with
// mocked FileView/process; only replace the date source for determinism.
const serviceFns=svc.slice(svc.indexOf("    function loadAll()"),svc.indexOf("    onThemeNameChanged:"))
    .replace("    Component.onCompleted: Qt.callLater(service.loadAll)","")
    .replace("function currentDate() { return Policy.localDate(new Date()); }","function currentDate() { return service.today; }");
const exitStart=svc.indexOf("        onExited: function(code, status) {");
const exitEnd=svc.lastIndexOf("\n        }\n    }\n}");
assert.ok(exitStart>=0&&exitEnd>exitStart);
const exitFn=svc.slice(exitStart,exitEnd+10).replace("onExited: function","function backendExit");
function mockService(readStatus,raw,validManifest=true){
    const s={Policy:ctx, initialized:false,manifestReady:false,stateReadStatus:readStatus,
      preferencesWritable:false,preferenceWarning:"",artworks:[],saved:ctx.initialState(),
      themeName:"twilight",wallpaperDirectory:"/tmp/a b#%/",lastSuccessful:null,
      message:"",busy:false,lastAppliedKey:"",lastAttemptKey:"",backendErrorText:"",
      pending:null,transitionLayer:null,lastKnownWallpaperPath:"",writes:[],applies:0,
      today:"2026-11-24",console:{warn(){}},Qt:{callLater(fn){fn()}},
      catalogue:{text(){return JSON.stringify(validManifest?manifest:{wallpapers:[]})}},
      stateFile:{text(){return raw},setText(value){s.writes.push(value)}},
      watchdog:{restart(){},stop(){}},wallpaperApplied(){}};
    s.service=s;
    s.wallpaperProcess={command:[],set running(value){if(value)s.applies++}};
    Object.defineProperties(s,{
        eligible:{get(){return ctx.forTheme(s.artworks,s.themeName)}},
        rotationEnabled:{get(){return s.saved.rotationEnabled}},
        transitionEnabled:{get(){return s.saved.transitionEnabled}},
        currentId:{get(){return s.saved.byTheme[s.themeName].current}}
    });
    vm.createContext(s);
    vm.runInContext(serviceFns+"\n"+exitFn,s);
    return s;
}
const guarded=mockService("loaded","{broken");
guarded.loadAll();assert.equal(guarded.initialized,true);assert.equal(guarded.applies,1);
guarded.setRotationEnabled(false);guarded.setTransitionEnabled(false);
guarded.backendExit(0,0);assert.equal(guarded.writes.length,0);
assert.equal(guarded.rotationEnabled,false);assert.equal(guarded.transitionEnabled,false);
assert.ok(guarded.preferenceWarning.length>0);
guarded.ensureToday(false);guarded.ensureToday(false);assert.equal(guarded.applies,1);
const paused=mockService("loaded",raw);
paused.loadAll();assert.equal(paused.applies,1);paused.backendExit(0,0);
const other=all.find(a=>a.themes[0]==="twilight"&&a.id!==id).id;
paused.applyManual(other);assert.equal(paused.applies,2);paused.backendExit(0,0);
paused.ensureToday(false);paused.today="2026-11-25";paused.ensureToday(false);
assert.equal(paused.applies,2);assert.equal(paused.currentId,other);
paused.setRotationEnabled(true);paused.ensureToday(false);assert.equal(paused.applies,3);
paused.setRotationEnabled(false);paused.setTransitionEnabled(false);
paused.backendExit(0,0);paused.ensureToday(false);assert.equal(paused.applies,3);
assert.equal(paused.rotationEnabled,false);assert.equal(paused.transitionEnabled,false);
const missing=mockService("missing","");
missing.loadAll();assert.equal(missing.writes.length,0);missing.backendExit(1,0);
assert.equal(missing.writes.length,0);missing.retry();assert.equal(missing.applies,2);
missing.backendExit(0,0);assert.equal(missing.writes.length,1);
const waiting=mockService("pending","");
waiting.loadAll();assert.equal(waiting.initialized,false);assert.equal(waiting.applies,0);
waiting.stateReadStatus="failed";waiting.finishInitialization();
assert.equal(waiting.initialized,true);waiting.backendExit(0,0);assert.equal(waiting.writes.length,0);
const empty=mockService("loaded",raw,false);
empty.loadAll();empty.setRotationEnabled(true);
assert.equal(empty.applies,0);assert.equal(empty.writes.length,0);
console.log("PASS Veranda mocked service: guarded writes, paused manual apply, in-flight toggles, failure/retry and deferred initialization.");
