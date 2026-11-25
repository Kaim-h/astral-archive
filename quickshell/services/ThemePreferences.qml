import QtQuick
import Quickshell
import Quickshell.Io
import "../themes" as Themes
import "../themes/ThemePolicy.js" as Policy

// Production-only adapter. The pure Qt palette singleton and isolated
// Archive checkpoint theme changes never write the desktop preference.
Item {
    id: service
    visible: false
    width: 0
    height: 0

    property bool ready: false
    property bool initializationStarted: false
    property string readStatus: "pending"
    property bool writable: false
    property bool userSelected: false
    property int savedIndex: -1
    property int writingIndex: -1
    property bool writeReportedSaved: false
    property string verifyStatus: "idle"
    property string warning: ""

    FileView {
        id: stateFile
        // Set path after construction so no initial result is missed.
        preload: true
        blockLoading: false
        blockAllReads: false
        atomicWrites: true
        // Tiny explicit preference writes, not animation/slider I/O.
        // Synchronous completion avoids competing writes and late save results.
        blockWrites: true
        printErrors: false
        watchChanges: false
        onLoaded: service.noteRead("loaded")
        onLoadFailed: function(error) {
            service.noteRead(error === FileViewError.FileNotFound ? "missing" : "failed")
        }
        onSaved: service.writeSucceeded()
        onSaveFailed: service.writeFailed()
    }

    // Independent reader: keep startup nonblocking and never mistake a
    // late startup callback or cached write for persisted readback.
    FileView {
        id: verifyFile
        preload: false
        blockLoading: true
        blockAllReads: true
        printErrors: false
        watchChanges: false
        onLoaded: service.noteVerify("loaded")
        onLoadFailed: service.noteVerify("failed")
    }

    Timer {
        id: initializationDeadline
        interval: 3000
        repeat: false
        onTriggered: service.noteRead("timeout")
    }

    function startInitialization() {
        if (service.initializationStarted || service.ready) return;
        service.initializationStarted = true;
        initializationDeadline.start();
        try {
            var path = Quickshell.statePath("theme.json");
            if (typeof path !== "string" || path.charAt(0) !== "/")
                throw Error("Theme state path unavailable");
            stateFile.path = path;
            // Background preload; read text only after loaded.
        } catch (error) {
            service.noteRead("failed");
        }
    }
    function noteRead(status) {
        if (!service.initializationStarted || service.ready || service.readStatus !== "pending") return;
        service.readStatus = status;
        initializationDeadline.stop();
        // Never write from inside a FileView load callback.
        Qt.callLater(service.finishInitialization);
    }
    function finishInitialization() {
        if (service.ready || service.readStatus === "pending") return;
        var decoded;
        try {
            decoded = Policy.decodePreferences(service.readStatus,
                service.readStatus === "loaded" ? stateFile.text() : "");
        } catch (error) {
            service.readStatus = "failed";
            decoded = Policy.decodePreferences("failed", "");
        }
        service.savedIndex = decoded.savedIndex;
        service.writable = decoded.writable;
        if (!decoded.writable) {
            service.warning = "Theme preference " + (service.readStatus === "timeout" ? "read timed out" : decoded.status) + " — session-only changes.";
            console.warn(service.warning + " Original file preserved; back up and repair or move theme.json before restarting.");
        }
        // Explicit selection while the read was pending wins.
        if (!service.userSelected) Themes.Theme.index = decoded.index;
        service.ready = true;
        if (service.userSelected) service.persistSelection();
    }
    function select(index) {
        if (!Policy.validIndex(index)) return;
        service.userSelected = true;
        Themes.Theme.index = index;
        service.persistSelection();
    }
    function persistSelection() {
        var index = Themes.Theme.index;
        if (!service.ready || !service.writable || service.writingIndex !== -1 ||
            !Policy.validIndex(index) || service.savedIndex === index) return;
        service.writingIndex = index;
        service.writeReportedSaved = false;
        try {
            var expected = Policy.encodePreference(index);
            stateFile.setText(expected);
            // blockWrites is synchronous. Missing completion is not success.
            if (service.writingIndex === -1) return;
            if (!service.writeReportedSaved) {
                service.writeFailed();
                return;
            }
            // v0.3.1 FileView may report saved even when QSaveFile::commit
            // fails. Its cached text is not disk evidence. Reload explicitly.
            service.verifyStatus = "pending";
            verifyFile.path = stateFile.path;
            verifyFile.reload();
            var actual = verifyFile.text();
            var confirmed = service.verifyStatus === "loaded" && actual === expected;
            service.verifyStatus = "idle";
            if (!confirmed) {
                service.writeFailed();
                return;
            }
            service.savedIndex = index;
            service.writingIndex = -1;
            service.writeReportedSaved = false;
        } catch (error) {
            service.writeFailed();
        }
    }
    function writeSucceeded() {
        if (service.writingIndex === -1) return;
        service.writeReportedSaved = true;
    }
    function writeFailed() {
        if (service.writingIndex === -1) return;
        service.writingIndex = -1;
        service.writeReportedSaved = false;
        service.verifyStatus = "idle";
        // Fail closed for the session; do not retry against an unknown file.
        service.writable = false;
        service.warning = "Theme preference not confirmed — session-only changes.";
        console.warn(service.warning + " Check state storage and restart.");
    }
    function noteVerify(status) {
        if (service.writingIndex !== -1 && service.verifyStatus === "pending")
            service.verifyStatus = status;
    }

    Component.onCompleted: service.startInitialization()
}
