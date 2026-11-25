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
            stateFile.path = Quickshell.statePath("theme.json");
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
        try {
            stateFile.setText(Policy.encodePreference(index));
        } catch (error) {
            service.writeFailed();
        }
    }
    function writeSucceeded() {
        if (service.writingIndex === -1) return;
        service.savedIndex = service.writingIndex;
        service.writingIndex = -1;
    }
    function writeFailed() {
        if (service.writingIndex === -1) return;
        service.writingIndex = -1;
        // Fail closed for the session; do not retry against an unknown file.
        service.writable = false;
        service.warning = "Theme preference not saved — session-only changes.";
        console.warn(service.warning + " Check state storage and restart.");
    }

    Component.onCompleted: service.startInitialization()
}
