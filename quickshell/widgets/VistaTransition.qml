import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../services/VistaPolicy.js" as Policy

// The Veranda's temporary wallpaper-transition layer. Never part of the
// permanent wallpaper and never intercepts input. All pixels remain ordinary
// 2D images: only a fragment shader chooses when the new image is revealed.
// If the compiled shader or any required image is unavailable, fail safely
// and tell VerandaService to use awww's normal fade instead.
Scope {
    id: fx

    // On this Qt 6 build the binary shader must already exist. Keep the
    // fallback immediate if its file hasn't been compiled locally yet.
    property bool shaderPrepared: false
    readonly property string shaderPath: {
        var url = String(Qt.resolvedUrl("../shaders/vista-transition.frag.qsb"));
        return url.indexOf("file://") === 0 ? decodeURIComponent(url.substring(7)) : "";
    }
    Process {
        id: shaderCheck
        command: ["test", "-s", fx.shaderPath]
        onExited: function(code, status) { fx.shaderPrepared = code === 0; }
    }
    Component.onCompleted: shaderCheck.running = true

    property string oldPath: ""
    property string newPath: ""
    property string subjectPath: ""
    property bool subjectMode: false
    property string phase: "idle" // idle, loading, running, held, fading
    property real progress: 0
    property real veil: 0
    property real seed: 0
    property bool swapComplete: false
    property bool swapRequestedAlready: false
    property int generation: 0
    property int readyCount: 0
    readonly property bool active: phase !== "idle"
    readonly property int screenCount: screens.instances.length
    property color accentColor: "#91ada1"
    property color outlineColor: "#e6e1d8"

    signal swapRequested()
    signal aborted(string reason)
    signal completed()

    function fileUrl(path) {
        return Policy.localImageUrl(path);
    }
    function begin(previousPath, nextPath, maskPath, useSubject, accent, ink) {
        if (!shaderPrepared || active || !previousPath || !nextPath || previousPath === nextPath)
            return false;
        oldPath = previousPath;
        newPath = nextPath;
        subjectPath = useSubject ? maskPath : "";
        subjectMode = Boolean(useSubject && maskPath);
        accentColor = accent;
        outlineColor = ink;
        progress = 0;
        veil = 0;
        seed = Math.random() * 1000;
        swapComplete = false;
        swapRequestedAlready = false;
        readyCount = 0;
        generation++;
        phase = "loading";
        loadDeadline.restart();
        // An empty screen list cannot display the effect safely.
        if (!screenCount) Qt.callLater(function(){fx.abort("No display for shader layer");});
        return true;
    }
    function readyScreen() {
        if (phase !== "loading") return;
        readyCount++;
        if (readyCount < screenCount) return;
        loadDeadline.stop();
        phase = "running";
        reveal.start();
        fadeIn.start();
    }
    function requestSwap() {
        if (phase !== "running" || swapRequestedAlready) return;
        swapRequestedAlready = true;
        swapRequested();
    }
    function backendSwapped(ok) {
        if (!active) return;
        if (!ok) { abort("Wallpaper backend could not swap"); return; }
        swapComplete = true;
        finishIfReady();
    }
    function finishIfReady() {
        if (!swapComplete || reveal.running || !active) return;
        phase = "fading";
        fadeOut.start();
    }
    function finish() {
        loadDeadline.stop();
        handoffDelay.stop();
        reveal.stop();
        fadeIn.stop();
        fadeOut.stop();
        phase = "idle";
        progress = 0;
        veil = 0;
        oldPath = "";
        newPath = "";
        subjectPath = "";
        completed();
    }
    function abort(reason) {
        if (!active) return;
        finish();
        aborted(reason);
    }

    Timer {
        id: loadDeadline
        interval: 2400
        onTriggered: fx.abort("Shader or artwork did not load")
    }
    Timer {
        // Wait until the shader covers the old wallpaper before changing awww.
        id: handoffDelay
        interval: 170
        onTriggered: fx.requestSwap()
    }
    NumberAnimation {
        id: fadeIn
        target: fx; property: "veil"; from: 0; to: 1
        duration: 140
        easing.type: Easing.OutQuad
        onStarted: handoffDelay.restart()
    }
    NumberAnimation {
        id: reveal
        target: fx; property: "progress"; from: 0; to: 1
        duration: fx.subjectMode ? 2100 : 1750
        easing.type: Easing.Linear
        onFinished: fx.finishIfReady()
    }
    NumberAnimation {
        id: fadeOut
        target: fx; property: "veil"; from: 1; to: 0
        duration: 130
        onFinished: fx.finish()
    }
    Timer {
        // If awww never responds, do not leave a wallpaper-covering layer up.
        interval: 3200
        running: fx.phase === "running" || fx.phase === "held"
        repeat: false
        onTriggered: fx.abort("Wallpaper handoff timed out")
    }

    Variants {
        id: screens
        model: Quickshell.screens
        PanelWindow {
            id: scene
            required property var modelData
            screen: modelData
            anchors { left: true; right: true; top: true; bottom: true }
            visible: fx.active
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "astral-archive:veranda-fx"
            mask: Region {} // No clickable wallpaper-shaped window.

            readonly property bool ready: imageOld.status === Image.Ready &&
                imageNew.status === Image.Ready &&
                (!fx.subjectMode || imageSubject.status === Image.Ready) &&
                transition.status === ShaderEffect.Compiled
            onReadyChanged: {
                if (ready) fx.readyScreen();
            }
            Image {
                id: imageOld
                visible: false; asynchronous: true; cache: false
                source: fx.fileUrl(fx.oldPath)
                sourceSize: Qt.size(scene.width, scene.height)
                fillMode: Image.PreserveAspectCrop
            }
            Image {
                id: imageNew
                visible: false; asynchronous: true; cache: false
                source: fx.fileUrl(fx.newPath)
                sourceSize: Qt.size(scene.width, scene.height)
                fillMode: Image.PreserveAspectCrop
            }
            Image {
                id: imageSubject
                visible: false; asynchronous: true; cache: false; smooth: true
                source: fx.fileUrl(fx.subjectPath)
            }
            function crop(img) {
                var iw = Math.max(1, img.implicitWidth);
                var ih = Math.max(1, img.implicitHeight);
                var scale = Math.max(scene.width / iw, scene.height / ih);
                var fracW = scene.width / (iw * scale);
                var fracH = scene.height / (ih * scale);
                return Qt.vector4d((1-fracW)/2, (1-fracH)/2, fracW, fracH);
            }
            ShaderEffect {
                id: transition
                anchors.fill: parent
                // Render once (with zero opacity) so Qt can resolve shader status.
                visible: fx.active
                opacity: scene.ready ? fx.veil : 0
                property var oldTexture: imageOld
                property var newTexture: imageNew
                property var subjectTexture: fx.subjectMode ? imageSubject : imageOld
                property real progress: fx.progress
                property real mode: fx.subjectMode ? 1 : 0
                property real screenWidth: scene.width
                property real screenHeight: scene.height
                property real seed: fx.seed
                property vector4d cropOld: scene.crop(imageOld)
                property vector4d cropNew: scene.crop(imageNew)
                property color accent: fx.accentColor
                property color ink: fx.outlineColor
                fragmentShader: Qt.resolvedUrl("../shaders/vista-transition.frag.qsb")
            }
        }
    }
}
