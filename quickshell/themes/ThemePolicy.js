// Versioned, pure preference policy. Independent of Qt and I/O.
var DEFAULT_INDEX = 1;

function validIndex(index) {
    return typeof index === "number" && Number.isInteger(index) && index >= 0 && index < 3;
}

function decodePreferences(status, text) {
    function result(kind, index, writable, savedIndex) {
        return {status: kind, index: index, writable: writable, savedIndex: savedIndex};
    }
    if (status === "missing") return result("missing", DEFAULT_INDEX, true, -1);
    if (status !== "loaded") return result(status === "pending" ? "pending" : "unreadable", DEFAULT_INDEX, false, -1);
    var value;
    try { value = JSON.parse(text); }
    catch (error) { return result("malformed", DEFAULT_INDEX, false, -1); }
    if (!value || typeof value !== "object" || Array.isArray(value) ||
        !Object.prototype.hasOwnProperty.call(value, "version") ||
        !Number.isInteger(value.version))
        return result("malformed", DEFAULT_INDEX, false, -1);
    if (value.version !== 1)
        return result("unsupported", DEFAULT_INDEX, false, -1);
    if (!Object.prototype.hasOwnProperty.call(value, "index") || !validIndex(value.index))
        return result("malformed", DEFAULT_INDEX, false, -1);
    // Do not erase unknown fields written by another implementation.
    if (Object.keys(value).length !== 2)
        return result("unsupported", DEFAULT_INDEX, false, -1);
    return result("valid", value.index, true, value.index);
}

function encodePreference(index) {
    if (!validIndex(index)) throw Error("Invalid theme index");
    return JSON.stringify({version: 1, index: index}, null, 2) + "\n";
}
