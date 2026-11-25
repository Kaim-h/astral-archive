// Pure, unit-testable utilities. No shell commands or device access here.
function clampPercent(value) {
    var n = Number(value);
    if (!isFinite(n)) return 0;
    return Math.max(0, Math.min(100, Math.round(n)));
}

function volumeFraction(value) {
    return clampPercent(value) / 100;
}

// `brightnessctl -m` returns device,class,current,max,percentage%.
// Find the LAST percentage token rather than guessing the device name.
function parseBrightness(output) {
    var data = String(output || "").trim();
    var matches = data.match(/(?:^|,|\s)([0-9]{1,3})%(?!\S)/g);
    if (!matches || !matches.length) return null;
    var last = matches[matches.length - 1].match(/([0-9]{1,3})%/);
    if (!last) return null;
    var number = Number(last[1]);
    return number >= 0 && number <= 100 ? number : null;
}

// UPower's `percentage` might be a 0-1 fraction or 0-100; the docs don't say.
// If energy and capacity are known, their ratio tells us which scale we got.
// Without them, anything up to 1 is treated as a fraction (so exactly 1 reads 100%).
function batteryPercent(value, energy, capacity) {
    var raw = Number(value);
    if (!isFinite(raw)) return 0;
    var e = Number(energy), c = Number(capacity);
    if (isFinite(e) && isFinite(c) && c > 0 && e >= 0) {
        var ratio = e / c; // 0..1 charge fraction
        return Math.abs(raw - ratio) <= Math.abs(raw - ratio * 100)
            ? clampPercent(raw * 100) : clampPercent(raw);
    }
    return raw <= 1 ? clampPercent(raw * 100) : clampPercent(raw);
}

function adjustPercent(value, delta) {
    return clampPercent(Number(value) + Number(delta));
}

// Avoid a black screen from an accidental slider movement. Users can still
// use system settings or hardware keys for values below this safety floor.
function safeBrightnessPercent(value) {
    return Math.max(5, clampPercent(value));
}
