// node scripts/check-utilities.js - pure policy and source-contract checks.
// These checks do NOT instantiate QML or talk to DBus, PipeWire, Hyprland.
const assert = require('node:assert/strict');
const path = require('node:path');
const fs = require('node:fs');
const vm = require('node:vm');
const root = path.resolve(__dirname, '..');
const script = path.join(root, 'quickshell/services/UtilityPolicy.js');
const context = vm.createContext({});
vm.runInContext(fs.readFileSync(script, 'utf8'), context, { filename: script });
let count = 0;
function check(label, fn) { fn(); console.log('✓', label); count++; }
check('volume clamps lower bound', () => assert.equal(context.clampPercent(-100), 0));
check('volume clamps upper bound', () => assert.equal(context.clampPercent(101), 100));
check('fraction converts 73% to .73', () => assert.equal(context.volumeFraction(73), .73));
check('numeric volume rounds', () => assert.equal(context.clampPercent(61.6), 62));
check('non-numeric values fail to zero safely', () => assert.equal(context.clampPercent('garbage'), 0));
check('brightness machine output parses', () => assert.equal(context.parseBrightness('intel_backlight,backlight,511,50%,1023'), 50));
check('zero brightness parses correctly', () => assert.equal(context.parseBrightness('intel,backlight,0,0%,1200'), 0));
check('100% brightness parses correctly', () => assert.equal(context.parseBrightness('device,backlight,100,100%,100'), 100));
check('malformed brightness output is not a fake reading', () => assert.equal(context.parseBrightness('brightnessctl: no device found'), null));
check('out of range brightness is rejected', () => assert.equal(context.parseBrightness('dev,backlight,1000,999%,1000'), null));
check('empty brightness string is not a reading', () => assert.equal(context.parseBrightness(''), null));
check('brightness changes enforce a 5% safety floor', () => assert.equal(context.safeBrightnessPercent(0), 5));
check('safe brightness retains normal values', () => assert.equal(context.safeBrightnessPercent(72), 72));
check('battery percentages round and clamp', () => assert.equal(context.batteryPercent(50.5), 51));
check('battery 0-1 fraction is scaled to a percentage', () => assert.equal(context.batteryPercent(0.81), 81));
check('battery fraction is confirmed by energy/capacity', () => assert.equal(context.batteryPercent(0.01, 0.5, 50), 1));
check('battery 0-100 value is kept when energy/capacity agree', () => assert.equal(context.batteryPercent(1, 0.5, 50), 1));
check('battery full fraction reads 100', () => assert.equal(context.batteryPercent(1), 100));
check('battery bad input reads 0', () => assert.equal(context.batteryPercent(NaN), 0));
check('percentage keyboard step clamps', () => assert.equal(context.adjustPercent(98, 10), 100));
check('negative keyboard step clamps', () => assert.equal(context.adjustPercent(2, -10), 0));
check('capsule retains the original library popup and adds a separate utility popup', () => {
    const capsule = fs.readFileSync(path.join(root, 'quickshell/panels/ArchiveCapsule.qml'), 'utf8');
    assert.match(capsule, /ShelfPopup\s*\{/);
    assert.match(capsule, /UtilityShelf\s*\{/);
    assert.match(capsule, /function toggleUtilityShelf\(\)/);
    assert.match(capsule, /utilityPopup.visible\s*=\s*false; \/\/ only one dropdown at a time/);
    assert.match(capsule, /exclusiveZone:\s*0/);
    assert.doesNotMatch(capsule, /HotbarPanel\s*\{/);
});
check('service uses real backends not simulated UI values', () => {
    const service = fs.readFileSync(path.join(root, 'quickshell/services/UtilityService.qml'), 'utf8');
    for (const name of ['Quickshell.Services.Pipewire', 'Quickshell.Services.UPower', 'Quickshell.Networking', 'Quickshell.Bluetooth', 'PwObjectTracker']) assert.ok(service.includes(name), name);
    assert.match(service, /Policy\.brightnessReadCommand\(brightnessDevice\)/);
    assert.match(service, /Policy\.brightnessWriteCommand\(brightnessDevice,percent\)/);
    assert.match(service, /utility\.readBrightness\(exitCode === 0 \? utility\.brightnessReadOutput : ""\)/);
    assert.match(service, /Quickshell.execDetached\(\["systemsettings"\]\)/);
});
check('slider commits only on release', () => {
    const slider = fs.readFileSync(path.join(root, 'quickshell/widgets/RelicSlider.qml'), 'utf8');
    assert.match(slider, /onReleased/);
    assert.match(slider, /slider.valueCommitted\(slider.draftValue\)/);
    const draggingHandler = slider.split("onPositionChanged:")[1].split("onReleased:")[0];
    assert.doesNotMatch(draggingHandler, /valueCommitted/);
});
check('service read is gated by visible utility popup', () => {
    const service = fs.readFileSync(path.join(root, 'quickshell/services/UtilityService.qml'), 'utf8');
    assert.match(service, /onPopupOpenChanged/);
    assert.match(service, /if \(popupOpen\) refreshBrightness\(\)/);
    assert.doesNotMatch(service, /Timer\s*\{/);
});
check('all required Batch 8 source files present', () => {
    for (const file of ['quickshell/panels/ArchiveCapsule.qml', 'quickshell/panels/UtilityShelf.qml',
        'quickshell/services/UtilityService.qml', 'quickshell/services/UtilityPolicy.js',
        'quickshell/widgets/RelicSlider.qml', 'docs/utility-shelf.md'])
        assert.ok(fs.existsSync(path.join(root, file)), file);
});
console.log(`\n${count} utility-shelf checks passed.`);


check('AUD-16 canonical CSV and strict device selection',()=>{
    const reading=context.parseBrightnessDevice('intel_backlight,backlight,400,20%,2000\n');
    assert.equal(reading.device,'intel_backlight');assert.equal(reading.percent,20);
    for(const bad of ['intel,backlight,400,2000,20%','kbd,leds,4,20%,20','intel,backlight,10,50%,0','intel,backlight,21,100%,20','intel,backlight,1,101%,20','intel,backlight,1,5%,20\nother,backlight,1,5%,20','intel,backlight,-1,0%,20','intel,backlight,1,5%,20,extra'])
        assert.equal(context.parseBrightness(bad),null,bad);
    assert.deepEqual(Array.from(context.brightnessReadCommand('')),['brightnessctl','-m','-c','backlight','info']);
    assert.deepEqual(Array.from(context.brightnessReadCommand(reading.device)),['brightnessctl','-m','-c','backlight','-d','intel_backlight','info']);
    assert.deepEqual(Array.from(context.brightnessWriteCommand(reading.device,0)),['brightnessctl','-c','backlight','-d','intel_backlight','set','5%']);
});
