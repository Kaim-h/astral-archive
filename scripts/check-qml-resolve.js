// Run with: node scripts/check-qml-resolve.js
// Offline check: every `import "path" as Alias` points at a real folder or .js
// file, and every `Alias.Name {` points at a real Name.qml in that folder.
// This is NOT a QML parser and does not replace qmllint/native testing.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..', 'quickshell');

function walk(dir) {
    return fs.readdirSync(dir, { withFileTypes: true }).flatMap(e => {
        const full = path.join(dir, e.name);
        return e.isDirectory() ? walk(full) : [full];
    });
}

const files = walk(root).filter(f => f.endsWith('.qml'));
const problems = [];
let importCount = 0, typeCount = 0;

for (const file of files) {
    const rel = path.relative(root, file);
    // Drop // comments so commented-out code is not checked.
    const text = fs.readFileSync(file, 'utf8').split(/\r?\n/)
        .map(l => l.replace(/(^|\s)\/\/.*$/, '$1')).join('\n');
    const aliases = {}; // alias -> absolute folder (QML folders only)
    for (const m of text.matchAll(/^\s*import\s+"([^"]+)"\s+as\s+(\w+)/gm)) {
        importCount++;
        const target = path.resolve(path.dirname(file), m[1]);
        if (!fs.existsSync(target)) {
            problems.push(`${rel}: import "${m[1]}" as ${m[2]} -> not found`);
        } else if (fs.statSync(target).isDirectory()) {
            aliases[m[2]] = target;
        }
    }
    for (const m of text.matchAll(/\b([A-Z]\w*)\.([A-Z]\w*)\s*\{/g)) {
        if (!aliases[m[1]]) continue; // Quickshell/Qt types or JS aliases
        typeCount++;
        if (!fs.existsSync(path.join(aliases[m[1]], m[2] + '.qml'))) {
            problems.push(`${rel}: ${m[1]}.${m[2]} { -> no ${m[2]}.qml in that folder`);
        }
    }
}

if (problems.length) {
    console.error('QML resolution problems:\n' + problems.map(p => ' - ' + p).join('\n'));
    process.exit(1);
}
console.log(`QML resolve check passed: ${files.length} QML files, ${importCount} path imports, ${typeCount} local types.`);
console.log('Not tested: qmllint, property names, Quickshell/Qt imports, or anything at runtime.');
