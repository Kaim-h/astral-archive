// Run with: node scripts/check-structure.js
// Ensures the key QML imports/references through Batch 9 Patch 2 exist on disk.
// This is NOT a QML parser and does not replace qmllint/native testing.
const path = require('node:path');
const fs = require('node:fs');
const root = path.resolve(__dirname, '..');
const needed = [
    'quickshell/shell.qml',
    'quickshell/panels/LauncherPanel.qml',
    'quickshell/panels/ArchiveCapsule.qml',
    'quickshell/panels/ShelfPopup.qml',
    'quickshell/panels/UtilityShelf.qml',
    'quickshell/panels/VerandaOfVistas.qml',
    'quickshell/services/WindowService.qml',
    'quickshell/services/WorkspaceService.qml',
    'quickshell/services/ShelfModel.js',
    'quickshell/services/UtilityService.qml',
    'quickshell/services/VerandaService.qml',
    'quickshell/services/VistaPolicy.js',
    'quickshell/services/UtilityPolicy.js',
    'quickshell/services/WindowModel.js',
    'quickshell/services/ApplicationService.qml',
    'quickshell/services/AppMatching.js',
    'quickshell/services/LauncherModel.js',
    'quickshell/shelves/Shelf.qml',
    'quickshell/widgets/Book.qml',
    'quickshell/widgets/IndexBook.qml',
    'quickshell/widgets/WindowChooser.qml',
    'quickshell/widgets/RelicSlider.qml',
    'quickshell/widgets/VistaControl.qml',
    'quickshell/widgets/VistaTile.qml',
    'quickshell/themes/Theme.qml',
    'quickshell/config/LauncherDefaults.js',
    'quickshell/config/CapsuleDefaults.js',
    'quickshell/config/VerandaDefaults.js',
    'quickshell/data/veranda-wallpapers.json',
    'scripts/check-veranda.js',
    'docs/architecture.md',
    'docs/design-decisions.md',
    'docs/development.md',
    'docs/archive-roadmap.md',
    'docs/capsule.md',
    'docs/utility-shelf.md',
    'docs/veranda-of-vistas.md'
];
const missing = needed.filter(f => !fs.existsSync(path.join(root, f)));
if (missing.length) {
    console.error('Missing required files:\n' + missing.map(x => ' - ' + x).join('\n'));
    process.exit(1);
}
console.log('✓ All ' + needed.length + ' expected project paths exist.');
