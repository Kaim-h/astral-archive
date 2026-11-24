import QtQuick
import Quickshell
import Quickshell.Io
import "../themes" as Themes
import "VistaPolicy.js" as Policy

// One wallpaper service for the whole shell. Uses the existing Wayland
// wallpaper daemon (awww); it does not render the background itself.
// Copyrighted images stay in the Git-ignored assets/wallpapers directory.
Item {
    id: service
    visible: false
    width: 0
    height: 0

    property bool initialized: false
    property bool manifestReady: false
    property string stateReadStatus: "pending"
    property bool preferencesWritable: false
    property string preferenceWarning: ""
    readonly property string displayMessage: preferenceWarning || message
    readonly property string wallpaperDirectory: Policy.localDirectory(String(Qt.resolvedUrl("../../assets/wallpapers/")))
    property var lastSuccessful: null
    property var artworks: []
    property var saved: Policy.initialState()
    property string message: ""
    property bool busy: false
    property string lastAppliedKey: ""
    property string lastAttemptKey: ""
    property string backendErrorText: ""
    property var pending: null
    property var transitionLayer: null // VistaTransition supplied by shell.qml
    property string lastKnownWallpaperPath: "" // only trust images applied this session

    readonly property string themeName: Themes.Theme.current.name.toLowerCase()
    readonly property var eligible: Policy.forTheme(artworks, themeName)
    readonly property bool rotationEnabled: saved.rotationEnabled
    readonly property bool transitionEnabled: saved.transitionEnabled
    readonly property string currentId: saved.byTheme[themeName]
        ? saved.byTheme[themeName].current : ""

    signal wallpaperApplied(string id, string theme)

    FileView {
        id: catalogue
        path: Qt.resolvedUrl("../data/veranda-wallpapers.json")
        blockLoading: true
        printErrors: true
    }
    FileView {
        id: stateFile
        path: Quickshell.statePath("veranda-of-vistas.json")
        blockLoading: true
        printErrors: false // Missing on first launch is expected.
        atomicWrites: true
        onLoaded: {
            service.stateReadStatus = "loaded";
            Qt.callLater(service.finishInitialization);
        }
        onLoadFailed: function(error) {
            service.stateReadStatus = error === FileViewError.FileNotFound ? "missing" : "failed";
            Qt.callLater(service.finishInitialization);
        }
        onSaveFailed: {
            service.preferenceWarning = "Preferences not saved — changes may be lost on restart.";
            console.warn(service.preferenceWarning);
        }
    }

    function loadAll() {
        try { artworks = Policy.normalizeManifest(JSON.parse(catalogue.text())); }
        catch (error) { message = "Wallpaper manifest could not be read"; console.warn(error); }
        manifestReady = true;
        stateFile.text();
        finishInitialization();
    }
    function finishInitialization() {
        if (!manifestReady || initialized || stateReadStatus === "pending") return;
        var decoded = Policy.decodePreferences(stateReadStatus,
            stateReadStatus === "loaded" ? stateFile.text() : "");
        saved = decoded.state;
        preferencesWritable = decoded.writable && artworks.length > 0;
        if (!decoded.writable) {
            preferenceWarning = "Preferences protected — session-only changes.";
            console.warn("Veranda preferences unreadable or unsupported; original file preserved. Back up and repair or move the state file before restarting.");
        } else if (!preferencesWritable) {
            preferenceWarning = "Preferences protected — wallpaper catalogue unavailable.";
        }
        initialized = true;
        if (artworks.length) ensureToday(true);
        else message = "No Veranda wallpapers in the manifest";
    }
    Component.onCompleted: Qt.callLater(service.loadAll)

    function persist(next) {
        saved = Policy.cleanState(next);
        if (!preferencesWritable) return;
        stateFile.setText(JSON.stringify(saved, null, 2) + "\n");
    }
    function imageUrl(art) {
        return Policy.localImageUrl(imagePath(art));
    }
    function imagePath(art) {
        // CLI receives a literal path, not a URL.
        return art ? Policy.localImagePath(wallpaperDirectory, art.file) : "";
    }
    function subjectFieldPath(art) {
        return art && art.subjectOutline && wallpaperDirectory
            ? Policy.localImagePath(wallpaperDirectory+".wallfx/", art.id+".png") : "";
    }
    function thumbnailUrl(art) {
        return art && wallpaperDirectory
            ? Policy.localImageUrl(Policy.localImagePath(wallpaperDirectory+".thumbs/",art.id+".jpg")) : "";
    }
    function findArt(id, theme) {
        var list = Policy.forTheme(artworks, theme);
        for (var i=0;i<list.length;i++) if (list[i].id===id) return list[i];
        return null;
    }
    function currentArtwork() { return findArt(currentId, themeName); }
    function currentDate() { return Policy.localDate(new Date()); }

    function ensureToday(force) {
        if (!initialized || busy || !eligible.length) return;
        var date = currentDate();
        var result = Policy.forDay(saved, themeName, date, artworks);
        if (!result.id) return;
        var key = Policy.applicationKey(themeName, date, result.id, rotationEnabled);
        if (!force && (key === lastAppliedKey || key === lastAttemptKey)) return;
        requestApply(result, themeName, key);
    }
    // Start awww directly for instant changes or as a safe animated fallback.
    // Animated changes can instead be handed to the temporary shader layer.
    function startBackend(path, animate) {
        wallpaperProcess.command = Policy.wallpaperCommand(path, animate);
        wallpaperProcess.running = true;
        watchdog.restart();
    }
    function requestApply(result, theme, key) {
        if (busy || !result.id) return;
        var art=findArt(result.id, theme), path=imagePath(art);
        if (!art || !path) { message="Wallpaper path unavailable";return; }
        pending={state:result.state,id:result.id,theme:theme,key:key,
                 path:path,effect:false,swapStarted:false};
        lastAttemptKey=key;
        backendErrorText="";
        busy=true;
        message="Applying wallpaper…";
        var fx=transitionLayer;
        if (transitionEnabled && fx && lastKnownWallpaperPath &&
            lastKnownWallpaperPath!==path &&
            fx.begin(lastKnownWallpaperPath,path,subjectFieldPath(art),
                     art.subjectOutline,Themes.Theme.current.engraving,
                     Themes.Theme.current.text)) {
            pending.effect=true;
            message="Drawing the next vista…";
        } else startBackend(path,transitionEnabled);
    }
    function transitionSwap() {
        if (!pending || !pending.effect || pending.swapStarted) return;
        pending.swapStarted=true;
        message="Changing wallpaper beneath the scene…";
        startBackend(pending.path,false); // never double-animate with awww
    }
    function transitionAborted(reason) {
        if (!pending || !pending.effect) return;
        if (pending.swapStarted) return; // awww already owns the pending swap
        pending.effect=false;
        message="Shader unavailable — using normal fade";
        console.warn("Vista transition fallback:",reason);
        startBackend(pending.path,true);
    }
    function applyManual(id) {
        if (busy || !initialized) return;
        var date=currentDate();
        var result=Policy.manualSelection(saved,themeName,date,artworks,id);
        if (!result.id) { message="Wallpaper is not eligible for this theme";return; }
        requestApply(result,themeName,Policy.applicationKey(themeName,date,result.id,rotationEnabled));
    }
    function setRotationEnabled(enabled) {
        if (!initialized) return;
        var next=Policy.cleanState(saved);
        next.rotationEnabled=Boolean(enabled);
        persist(next);
        // Never mark a wallpaper applied just because the preference changed.
        lastAppliedKey=Policy.appliedKey(lastSuccessful,rotationEnabled);
        message=enabled ? "Daily rotation enabled" : "Daily rotation paused";
    }
    function setTransitionEnabled(enabled) {
        // Toggle affects the next wallpaper apply, not any running transition.
        if (!initialized) return;
        var next=Policy.cleanState(saved);
        next.transitionEnabled=Boolean(enabled);
        persist(next);
        message=enabled ? "Wallpaper animation enabled" : "Wallpaper animation disabled";
    }
    function retry() { lastAttemptKey=""; ensureToday(true); }

    onThemeNameChanged: {
        if (initialized) Qt.callLater(function(){service.ensureToday(true);});
    }
    Timer {
        // Local-calendar boundary and wake-from-sleep check; no fast polling.
        interval: 60000
        running: true
        repeat: true
        onTriggered: service.ensureToday(false)
    }
    Timer {
        id: watchdog
        interval: 12000
        repeat: false
        onTriggered: {
            if (!service.busy) return;
            service.busy=false;
            if (service.pending && service.pending.effect && service.transitionLayer)
                service.transitionLayer.backendSwapped(false);
            service.pending=null;
            service.message="Wallpaper backend did not respond; verify awww-daemon";
            wallpaperProcess.running=false;
        }
    }
    Process {
        id: wallpaperProcess
        stderr: StdioCollector {
            onStreamFinished: service.backendErrorText=String(this.text).trim()
        }
        onExited: function(code, status) {
            watchdog.stop();
            if (!service.pending) return; // A timed-out process is not success.
            var p=service.pending;
            service.pending=null;
            service.busy=false;
            if (code===0) {
                service.lastKnownWallpaperPath=p.path;
                if (p.effect && service.transitionLayer)
                    service.transitionLayer.backendSwapped(true);
                // Preserve preference toggles made while the backend was busy.
                // Only the chosen wallpaper/date/rotation queue comes from p.state.
                var next=Policy.cleanState(p.state);
                next.rotationEnabled=service.saved.rotationEnabled;
                next.transitionEnabled=service.saved.transitionEnabled;
                service.persist(next);
                service.lastSuccessful={theme:p.theme,id:p.id,date:next.byTheme[p.theme].date};
                service.lastAppliedKey=Policy.appliedKey(service.lastSuccessful,next.rotationEnabled);
                service.lastAttemptKey="";
                service.message="Wallpaper applied";
                service.wallpaperApplied(p.id,p.theme);
            } else {
                if (p.effect && service.transitionLayer)
                    service.transitionLayer.backendSwapped(false);
                service.message="Wallpaper failed — check awww-daemon and image path";
                if (service.backendErrorText) console.warn(service.backendErrorText);
            }
            if (service.themeName !== p.theme) Qt.callLater(function(){service.ensureToday(true);});
        }
    }
}
