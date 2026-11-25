#!/usr/bin/env node
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const file = rel => fs.readFileSync(path.join(__dirname, "..", rel), "utf8");
const policySource = file("quickshell/themes/ThemePolicy.js");
const Policy = new Function(policySource + "\nreturn {validIndex,decodePreferences,encodePreference};")();
const qml = file("quickshell/services/ThemePreferences.qml");
const start = qml.indexOf("    function startInitialization(");
const end = qml.indexOf("    Component.onCompleted:");
assert.ok(start >= 0 && end > start);
const factory = new Function("service", "Policy", "Themes", "stateFile", "Qt", "console", "initializationDeadline", "Quickshell",
    qml.slice(start,end) + "\nreturn {startInitialization,noteRead,finishInitialization,select,persistSelection,writeSucceeded,writeFailed};");
function mock(raw, failWrite = false, throwRead = false) {
    const Themes = {Theme:{index:1}}, queue = [], writes = [], warnings = [];
    const service = {ready:false,initializationStarted:false,readStatus:"pending",writable:false,userSelected:false,
        savedIndex:-1,writingIndex:-1,warning:""};
    let text = raw, reads=0, pathSets=0;
    const timer={running:false,start(){this.running=true},stop(){this.running=false}};
    const stateFile = {
        set path(value){pathSets++},
        text(){reads++;if(throwRead)throw Error("read failed");return text;},
        setText(value){
            writes.push(value);
            if(failWrite === "throw")throw Error("write failed");
            if(failWrite) service.writeFailed();
            else {text=value;service.writeSucceeded();}
        }
    };
    Object.assign(service,factory(service,Policy,Themes,stateFile,
        {callLater(fn){queue.push(fn);}}, {warn(msg){warnings.push(msg);}},
        timer,{statePath(name){return "/synthetic/"+name;}}));
    service.startInitialization();
    return {service,Themes,writes,warnings,raw:()=>text,timer,reads:()=>reads,pathSets:()=>pathSets,
        expire(){if(timer.running){timer.running=false;service.noteRead("timeout");}},
        drain(){while(queue.length)queue.shift()();}};
}
for (const i of [0,1,2]) {
    const raw = Policy.encodePreference(i);
    assert.equal(Policy.validIndex(i),true);
    assert.equal(Policy.decodePreferences("loaded",raw).index,i);
    const m=mock(raw);
    m.service.noteRead("loaded");m.drain();
    assert.equal(m.Themes.Theme.index,i);
    assert.equal(m.service.ready,true);
    assert.equal(m.service.writable,true);
    assert.equal(m.writes.length,0);
    m.service.select(i);assert.equal(m.writes.length,0);
    m.service.select((i+1)%3);assert.equal(m.writes.length,1);
    assert.equal(JSON.parse(m.raw()).index,(i+1)%3);
    m.service.select((i+1)%3);assert.equal(m.writes.length,1);
    m.service.noteRead("failed");m.service.finishInitialization();m.drain();
    assert.equal(m.Themes.Theme.index,(i+1)%3);
    assert.equal(m.service.writable,true);
}
for (const invalid of [-1,3,0.5,"1",null,undefined,NaN,Infinity,true,{},[]]) {
    assert.equal(Policy.validIndex(invalid),false);
    assert.throws(()=>Policy.encodePreference(invalid));
    const m=mock("");m.service.noteRead("missing");m.drain();
    m.service.select(invalid);
    assert.equal(m.Themes.Theme.index,1);assert.equal(m.writes.length,0);
}
const malformed=["","{","null","[]","{}",'{"version":1}', '{"version":"1","index":1}',
    '{"version":1,"index":-1}','{"version":1,"index":3}','{"version":1,"index":1.2}',
    '{"version":1,"index":"1"}','{"version":1,"index":null}'];
const unsupported=['{"version":2,"index":2}','{"version":1,"index":2,"other":true}'];
for (const [kind,items] of [["malformed",malformed],["unsupported",unsupported]]) {
    for (const raw of items) {
        const m=mock(raw);
        assert.equal(Policy.decodePreferences("loaded",raw).status,kind);
        m.service.noteRead("loaded");m.drain();
        assert.equal(m.Themes.Theme.index,1);assert.equal(m.service.writable,false);
        m.service.select(2);assert.equal(m.Themes.Theme.index,2);
        assert.equal(m.raw(),raw);assert.equal(m.writes.length,0);assert.ok(m.service.warning);
    }
}
const missing=mock("");missing.service.noteRead("missing");missing.drain();
assert.equal(missing.Themes.Theme.index,1);assert.equal(missing.writes.length,0);
missing.service.select(2);assert.equal(missing.writes.length,1);
for(const readThrows of [false,true]){
    const failed=mock("untouched",false,readThrows);
    failed.service.noteRead(readThrows?"loaded":"failed");failed.drain();
    assert.equal(Policy.decodePreferences("failed","").status,"unreadable");
    assert.equal(failed.Themes.Theme.index,1);assert.equal(failed.service.writable,false);
    failed.service.select(0);assert.equal(failed.Themes.Theme.index,0);
    assert.equal(failed.raw(),"untouched");assert.equal(failed.writes.length,0);
}
for(const mode of [true,"throw"]){
    const brokenWrite=mock(Policy.encodePreference(0),mode);
    brokenWrite.service.noteRead("loaded");brokenWrite.drain();brokenWrite.service.select(2);
    assert.equal(brokenWrite.Themes.Theme.index,2);assert.equal(JSON.parse(brokenWrite.raw()).index,0);
    assert.equal(brokenWrite.service.savedIndex,0);assert.equal(brokenWrite.service.writable,false);
    assert.ok(brokenWrite.service.warning);brokenWrite.service.select(1);
    assert.equal(brokenWrite.Themes.Theme.index,1);assert.equal(brokenWrite.writes.length,1);
    brokenWrite.service.writeSucceeded();assert.equal(brokenWrite.service.savedIndex,0);
}
// Selection before read completion (and while a deferred callback is queued).
for(const [status,raw,writable] of [["loaded",Policy.encodePreference(0),true],
    ["missing","",true],["loaded","{broken",false],["failed","unreadable",false]]) {
    const m=mock(raw);
    m.service.finishInitialization();assert.equal(m.service.ready,false);
    m.service.select(0);assert.equal(m.writes.length,0);
    m.service.noteRead(status);m.service.select(2);
    assert.equal(m.writes.length,0);m.drain();
    assert.equal(m.Themes.Theme.index,2);assert.equal(m.service.ready,true);
    assert.equal(m.writes.length,writable?1:0);
    if(writable)assert.equal(JSON.parse(m.raw()).index,2);else assert.equal(m.raw(),raw);
    m.service.finishInitialization();m.service.noteRead("loaded");m.drain();
    assert.equal(m.writes.length,writable?1:0);
}
const same=mock(Policy.encodePreference(2));same.service.select(2);
same.service.noteRead("loaded");same.drain();assert.equal(same.writes.length,0);
assert.equal(Policy.decodePreferences("pending","").writable,false);
assert.match(qml,/atomicWrites:\s*true/);assert.match(qml,/blockWrites:\s*true/);
assert.match(qml,/FileViewError\.FileNotFound \? "missing" : "failed"/);
assert.match(qml,/onSaveFailed: service\.writeFailed\(\)/);
assert.match(qml,/onSaved: service\.writeSucceeded\(\)/);
assert.equal((qml.match(/stateFile\.setText\(/g)||[]).length,1);
const shell=file("quickshell/shell.qml"), capsule=file("quickshell/panels/ArchiveCapsule.qml");
assert.match(shell,/Services\.ThemePreferences\s*\{/);
assert.match(shell,/themeReady:\s*themePreferences\.ready/);
assert.match(shell,/onThemeRequested: function\(index\) \{ themePreferences\.select\(index\); \}/);
assert.match(capsule,/onClicked: capsule\.themeRequested\(/);
assert.ok(!/Themes\.Theme\.index\s*=/.test(capsule));
assert.match(file("quickshell/services/VerandaService.qml"),/if \(!themeReady \|\| !manifestReady/);
assert.ok(!/import Quickshell|FileView/.test(file("quickshell/themes/Theme.qml")));
// AUD-22: real extracted start/completion functions, simulated timer.
for(const selection of [null,0,2]){
    const m=mock(Policy.encodePreference(0));
    m.service.startInitialization();
    assert.equal(m.pathSets(),1);assert.equal(m.reads(),0);assert.equal(m.timer.running,true);
    assert.equal(m.service.ready,false);
    if(selection!==null)m.service.select(selection);
    m.expire();m.service.noteRead("loaded");m.drain();
    assert.equal(m.service.readStatus,"timeout");assert.equal(m.service.ready,true);
    assert.equal(m.service.writable,false);assert.equal(m.Themes.Theme.index,selection===null?1:selection);
    assert.equal(m.reads(),0);assert.equal(m.writes.length,0);
    assert.match(m.service.warning,/timed out/);assert.equal(m.timer.running,false);
    m.service.noteRead("missing");m.service.select(1);m.drain();
    assert.equal(m.service.readStatus,"timeout");assert.equal(m.writes.length,0);
    assert.equal(m.raw(),Policy.encodePreference(0));
}
const onTime=mock(Policy.encodePreference(2));
onTime.service.noteRead("loaded");onTime.expire();onTime.service.noteRead("missing");onTime.drain();
assert.equal(onTime.service.readStatus,"loaded");assert.equal(onTime.service.ready,true);
assert.equal(onTime.Themes.Theme.index,2);assert.equal(onTime.reads(),1);
assert.equal(onTime.writes.length,0);assert.equal(onTime.timer.running,false);
assert.match(qml,/preload:\s*true/);assert.match(qml,/blockLoading:\s*false/);
assert.match(qml,/onTriggered: service\.noteRead\("timeout"\)/);
console.log("PASS AUD-22 theme deadline, pending intent and first-result guard (mocked callbacks).");
console.log("PASS Theme policy and mocked production adapter: valid/invalid values, recovery, write failure, explicit selection, late callbacks and startup ordering.");
