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
check('brightness machine output parses', () => assert.equal(context.parseBrightness('intel_backlight,backlight,511,1023,50%'), 50));
check('zero brightness parses correctly', () => assert.equal(context.parseBrightness('intel,backlight,0,1200,0%'), 0));
check('100% brightness parses correctly', () => assert.equal(context.parseBrightness('device,backlight,100,100,100%'), 100));
check('malformed brightness output is not a fake reading', () => assert.equal(context.parseBrightness('brightnessctl: no device found'), null));
check('out of range brightness is rejected', () => assert.equal(context.parseBrightness('dev,backlight,1000,1000,999%'), null));
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
    assert.match(service, /"brightnessctl", "-m"/);
    assert.match(service, /"brightnessctl", "set"/);
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
