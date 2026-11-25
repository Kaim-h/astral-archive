// Run with: node scripts/check-shelves.js
// Small, OS-independent rules check. NOT a QML/Hyprland integration test.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const policy = path.join(root, 'quickshell/services/ShelfModel.js');
const context = vm.createContext({});
vm.runInContext(fs.readFileSync(policy, 'utf8'), context, { filename: policy });
const apps = [
    { appId: 'org.kde.dolphin', title: 'Dolphin' },
    { appId: 'firefox', title: 'Firefox' },
    { appId: 'org.kde.konsole', title: 'Konsole' },
    { appId: 'vlc', title: 'VLC' },
    { appId: 'org.kde.kate', title: 'Kate' },
    { appId: 'gimp', title: 'GIMP' }
];
const ids = entries => Array.from(entries, x => x.appId);
let count = 0;
function test(name, fn) { fn(); console.log('✓', name); count++; }

test('pins remain in configured order', () => {
    const r = context.splitShelfApps(apps, ['firefox', 'org.kde.dolphin'], [], 6, 6);
    assert.deepEqual(ids(r.pinned), ['firefox', 'org.kde.dolphin']);
});
test('running unpinned apps appear only on the second shelf', () => {
    const r = context.splitShelfApps(apps, ['firefox'], ['vlc', 'firefox'], 6, 6);
    assert.deepEqual(ids(r.pinned), ['firefox']);
    assert.deepEqual(ids(r.running), ['vlc']);
});
test('pinned but closed application remains on pinned shelf', () => {
    const r = context.splitShelfApps(apps, ['org.kde.kate'], [], 6, 6);
    assert.deepEqual(ids(r.pinned), ['org.kde.kate']);
    assert.equal(r.running.length, 0);
});
test('uninstalled pins do not generate imaginary books', () => {
    const r = context.splitShelfApps(apps, ['com.example.missing'], [], 6, 6);
    assert.equal(r.pinned.length, 0);
});
test('desktop extension and case are normalized', () => {
    const r = context.splitShelfApps(apps, ['FIREFOX.DESKTOP'], ['FIREFOX.desktop'], 6, 6);
    assert.deepEqual(ids(r.pinned), ['firefox']);
    assert.equal(r.running.length, 0);
});
test('duplicate pin IDs do not duplicate books', () => {
    const r = context.splitShelfApps(apps, ['firefox', 'firefox.desktop'], [], 6, 6);
    assert.deepEqual(ids(r.pinned), ['firefox']);
});
test('running apps retain deterministic catalogue order', () => {
    const r = context.splitShelfApps(apps, [], ['gimp', 'vlc'], 6, 6);
    assert.deepEqual(ids(r.running), ['vlc', 'gimp']);
});
test('caps apply independently and report overflow', () => {
    const r = context.splitShelfApps(apps, ['firefox', 'vlc', 'gimp'], ['org.kde.kate', 'org.kde.konsole', 'org.kde.dolphin'], 2, 1);
    assert.deepEqual(ids(r.pinned), ['firefox', 'vlc']);
    assert.deepEqual(ids(r.running), ['org.kde.dolphin']);
    assert.equal(r.hiddenPinned, 1);
    assert.equal(r.hiddenRunning, 2);
});
test('zero capacity produces no books', () => {
    const r = context.splitShelfApps(apps, ['firefox'], ['vlc'], 0, 0);
    assert.equal(r.pinned.length, 0);
    assert.equal(r.running.length, 0);
});
test('empty catalogue produces two empty shelves', () => {
    const r = context.splitShelfApps([], ['firefox'], ['vlc'], 6, 6);
    assert.equal(r.totalPinned, 0);
    assert.equal(r.totalRunning, 0);
});
test('workspace minimum slots and additional IDs are sorted', () => {
    assert.deepEqual(Array.from(context.visibleWorkspaceIds([7, 2, 7], 5)), [1, 2, 3, 4, 5, 7]);
});
test('negative named workspaces do not become numbered buttons', () => {
    assert.deepEqual(Array.from(context.visibleWorkspaceIds([-99, 0, 4], 3)), [1, 2, 3, 4]);
});
test('noninteger workspace IDs are ignored', () => {
    assert.deepEqual(Array.from(context.visibleWorkspaceIds([2.5, 9, 'abc'], 2)), [1, 2, 9]);
});
test('capsule uses a popup and existing Shelf components', () => {
    const capsule = fs.readFileSync(path.join(root, 'quickshell/panels/ArchiveCapsule.qml'), 'utf8');
    const popup = fs.readFileSync(path.join(root, 'quickshell/panels/ShelfPopup.qml'), 'utf8');
    assert.match(capsule, /PanelWindow\s*\{/);
    assert.match(capsule, /exclusiveZone:\s*0/);
    assert.match(popup, /PopupWindow\s*\{/);
    assert.equal((popup.match(/Shelves\.Shelf\s*\{/g) || []).length, 2);
});
test('required QML, documentation and config paths exist', () => {
    for (const filename of [
        'quickshell/panels/ArchiveCapsule.qml', 'quickshell/panels/ShelfPopup.qml',
        'quickshell/services/WorkspaceService.qml', 'quickshell/services/ShelfModel.js',
        'quickshell/config/CapsuleDefaults.js', 'quickshell/widgets/WorkspaceIndicator.qml',
        'docs/capsule.md', 'docs/archive-roadmap.md',
        'quickshell/panels/LauncherPanel.qml', 'quickshell/shelves/Shelf.qml'
    ]) assert.ok(fs.existsSync(path.join(root, filename)), filename);
});
console.log(`\n${count} revised capsule/shelf checks passed.`);
