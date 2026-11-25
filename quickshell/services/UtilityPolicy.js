// Pure, unit-testable utilities. No shell commands or device access here.
function clampPercent(value) {
    var n = Number(value);
    if (!isFinite(n)) return 0;
    return Math.max(0, Math.min(100, Math.round(n)));
}

function volumeFraction(value) {
    return clampPercent(value) / 100;
}

// brightnessctl -m info: device,class,current,percentage%,maximum.
// A single backlight record is expected; refuse ambiguous/malformed output.
function parseBrightnessDevice(output) {
    var fields=String(output || "").trim().split(",");
    if(fields.length!==5 || !fields[0] || /[\r\n\/\\\u0000-\u001f]/.test(fields[0]) ||
       fields[1]!=="backlight" || !/^\d+$/.test(fields[2]) ||
       !/^\d{1,3}%$/.test(fields[3]) || !/^\d+$/.test(fields[4])) return null;
    var current=Number(fields[2]), maximum=Number(fields[4]), percent=Number(fields[3].slice(0,-1));
    if(!Number.isSafeInteger(current)||!Number.isSafeInteger(maximum)||maximum<=0||
       current>maximum||percent>100) return null;
    return {device:fields[0],percent:percent};
}
function parseBrightness(output) {
    var reading=parseBrightnessDevice(output);
    return reading ? reading.percent : null;
}
function brightnessReadCommand(device) {
    var args=["brightnessctl","-m","-c","backlight"];
    if(device) args.push("-d",device);
    args.push("info");
    return args;
}
function brightnessWriteCommand(device,percent) {
    return ["brightnessctl","-c","backlight","-d",device,"set",safeBrightnessPercent(percent)+"%"];
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
