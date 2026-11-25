import QtQuick
import Quickshell
import Quickshell.Io
import "GalleryPolicy.js" as Policy

// Gallery artwork stays separate from Veranda wallpapers. This service owns
// per-artwork celestial preferences only; it NEVER moves or edits disk images.
Item {
    id: catalogue
    width: 0; height: 0; visible: false
    property var items: []
    property int selectedIndex: 0
    property bool selectionLocked: false
    property string errorText: ""
    property var library: []
    property var skies: []
    property var settingsById: Object.create(null)
    property string stateReadStatus: "pending"
    property bool cataloguesReady: false
    property bool preferencesWritable: false
    property bool initialized: false
    property string lastWarning: ""

    readonly property var selected: selectedIndex >= 0 && selectedIndex < items.length ? items[selectedIndex] : null
    readonly property string currentId: selected ? selected.id : ""
    readonly property url artUrl: selected ? Qt.resolvedUrl("../../assets/wallpapers/" + Policy.artworkFileSegment(selected.file)) : ""
    readonly property string title: selected ? selected.title : "Gallery artwork"
    readonly property string artist: selected ? selected.artist : "Artist unknown"
    readonly property var currentSetting: currentId && settingsById[currentId] ? settingsById[currentId] : null
    readonly property var selectedIds: currentSetting ? currentSetting.ids : []
    readonly property var selectedConstellations: Policy.selectDefinition(selectedIds, library)
    readonly property int selectedCount: currentSetting ? currentSetting.count : 0
    readonly property string skyMode: currentSetting ? currentSetting.skyMode : "fixed"
    readonly property var skyPool: currentSetting ? currentSetting.skyPool : []
    readonly property string skyKey: currentSetting ? Policy.pickSky(currentSetting, skies, false) : "theme"
    readonly property var skyPreset: Policy.findById(skies, skyKey)

    FileView {
        id: manifest
        path: Qt.resolvedUrl("../data/gallery-artworks.json")
        blockLoading: true; printErrors: true
    }
    FileView {
        id: constellationFile
        path: Qt.resolvedUrl("../data/gallery-constellations.json")
        blockLoading: true; printErrors: true
    }
    FileView {
        id: skyFile
        path: Qt.resolvedUrl("../data/gallery-sky-presets.json")
        blockLoading: true; printErrors: true
    }
    FileView {
        id: stateFile
        path: Quickshell.statePath("gallery-customization.json")
        blockLoading: true; printErrors: false
        atomicWrites: true
        onLoaded: {
            catalogue.stateReadStatus = "loaded";
            Qt.callLater(catalogue.finishStateInitialization);
        }
        onLoadFailed: function(error) {
            catalogue.stateReadStatus = error === FileViewError.FileNotFound ? "missing" : "failed";
            Qt.callLater(catalogue.finishStateInitialization);
        }
        onSaveFailed: {
            catalogue.lastWarning = "Gallery preferences could not be saved; changes may be lost on restart.";
            console.warn(catalogue.lastWarning);
        }
    }
    function readCatalogues() {
        try {
            var cs = JSON.parse(constellationFile.text()).constellations;
            var ss = JSON.parse(skyFile.text()).skies;
            if (!Array.isArray(cs) || !Array.isArray(ss) || !cs.length || !ss.length)
                throw Error("Empty or malformed celestial catalogues");
            var unique=Object.create(null), result=[];
            for (var i=0; i<cs.length; i++) {
                var c=cs[i];
                if (!c || typeof c.id !== 'string' || !/^[a-z0-9-]+$/.test(c.id) || unique[c.id] || !Array.isArray(c.stars) || !Array.isArray(c.edges)) continue;
                unique[c.id]=true; result.push(c);
            }
            library=result; skies=ss;
        } catch (e) {
            library=[]; skies=[];
            lastWarning="The Gallery celestial catalogues could not be read";
            console.warn("Gallery catalogues:", e);
        }
    }
    function reload() {
        if (selectionLocked) return;
        initialized=false;
        cataloguesReady=false;
        preferencesWritable=false;
        readCatalogues();
        try {
            var data=JSON.parse(manifest.text()), list=data.artworks || [];
            if (!Array.isArray(list)) throw Error("artworks must be an array");
            var seen=Object.create(null), result=[];
            for (var i=0;i<list.length;i++) {
                var a=list[i];
                if (!a || typeof a.file!=="string") continue;
                // Only filenames ending -g; never allow path traversal or URLs.
                if (!Policy.artworkFileSegment(a.file)) continue;
                // Explicit stable IDs survive filename changes; otherwise use filename.
                var id = /^[a-zA-Z0-9_-]+$/.test(String(a.id||"")) ? String(a.id) : a.file;
                if (seen[id]) continue;
                seen[id]=true;
                result.push({id:id,file:a.file,title:String(a.title||a.file),artist:String(a.artist||"Artist unknown")});
            }
            items=result;selectedIndex=0;errorText="";
        } catch(e) {items=[];errorText=String(e);console.warn("Gallery manifest:",e);}
        cataloguesReady=true;
        // Wait for the first FileView result; never infer absence from empty text.
        stateFile.text();
        finishStateInitialization();
    }
    function finishStateInitialization() {
        if (!cataloguesReady || initialized || stateReadStatus === "pending") return;
        var decoded=Policy.decodePreferences(stateReadStatus,
            stateReadStatus === "loaded" ? stateFile.text() : "");
        preferencesWritable=decoded.writable && library.length > 0 && skies.length > 0;
        if (!decoded.writable) {
            lastWarning="Gallery preferences unreadable; changes are session-only. Original file preserved.";
            console.warn(lastWarning);
        }
        var previous=decoded.perArtwork;
        // Preserve settings for temporarily absent entries. Returning artwork
        // must not lose the celestial identity it had before a manifest edit.
        var cleaned=Object.create(null);
        for (var oldKey in previous) {
            if (library.length && skies.length)
                cleaned[oldKey]=Policy.normalizeSetting(oldKey,previous[oldKey],library,skies);
        }
        settingsById=cleaned;
        initialized=true;
        ensureSelected();
    }
    Component.onCompleted: Qt.callLater(reload)
    onCurrentIdChanged: if (initialized) Qt.callLater(catalogue.ensureSelected)
    function cloneSettings() {
        var out=Object.create(null);
        for (var key in settingsById) out[key]=settingsById[key];
        return out;
    }
    function persistSettings(updated) {
        settingsById=updated;
        if (!preferencesWritable) return;
        stateFile.setText(JSON.stringify({schemaVersion:1,perArtwork:updated},null,2)+"\n");
    }
    function ensureSelected() {
        if (!initialized || !currentId || !library.length || !skies.length || currentSetting) return;
        var next=cloneSettings();
        next[currentId]=Policy.createSetting(currentId,library,skies);
        persistSettings(next);
    }
    function setCurrentSetting(values) {
        if (!initialized || !currentId || !library.length || !skies.length) return;
        var prior=currentSetting || Policy.createSetting(currentId,library,skies);
        var nextEntry={};
        for (var key in prior) nextEntry[key]=prior[key];
        for (var prop in values) nextEntry[prop]=values[prop];
        var normalized=Policy.normalizeSetting(currentId,nextEntry,library,skies);
        var next=cloneSettings();next[currentId]=normalized;
        persistSettings(next);
    }
    function changeCount(number) {
        if (!currentId) return;
        setCurrentSetting({count:number});
    }
    function toggleConstellation(id) {
        if (!currentId || !Policy.findById(library,id)) return;
        var chosen=selectedIds.slice(),idx=chosen.indexOf(id);
        if (idx>=0) {
            if (chosen.length<=1) return;
            chosen.splice(idx,1);
        } else {
            if (chosen.length>=Math.min(Policy.MAX_CONSTELLATIONS,library.length)) return;
            chosen.push(id);
        }
        setCurrentSetting({ids:chosen,count:chosen.length});
    }
    function moveConstellation(id, delta) {
        var chosen=selectedIds.slice(),i=chosen.indexOf(id),j=i+delta;
        if (i<0 || j<0 || j>=chosen.length) return;
        var t=chosen[i];chosen[i]=chosen[j];chosen[j]=t;
        setCurrentSetting({ids:chosen});
    }
    function chooseSky(id) {
        if (!Policy.findById(skies,id)) return;
        setCurrentSetting({sky:id,skyMode:'fixed'});
    }
    function setSkyMode(mode) {
        setCurrentSetting({skyMode:mode==='cycle'?'cycle':'fixed'});
    }
    function toggleSkyPool(id) {
        if (!Policy.findById(skies,id) || !currentSetting) return;
        var pool=skyPool.slice(),index=pool.indexOf(id);
        if (index>=0) {if (pool.length<=1)return;pool.splice(index,1);}
        else pool.push(id);
        setCurrentSetting({skyPool:pool});
    }
    function resetCurrent() {
        if (!initialized || !currentId || !library.length || !skies.length) return;
        var next=cloneSettings();
        next[currentId]=Policy.createSetting(currentId,library,skies);
        persistSettings(next);
    }
    function prepareOpening() {
        // Capture every presentation field at the same boundary, including
        // artwork identity even when the celestial library is unavailable.
        var snapshot={artId:currentId,source:artUrl,title:title,artist:artist,
            constellations:[],sky:null};
        if (!currentId || !library.length || !skies.length) return snapshot;
        if (!currentSetting) ensureSelected();
        var current=currentSetting || Policy.createSetting(currentId,library,skies);
        var skyId=Policy.pickSky(current,skies,false);
        snapshot.constellations=Policy.selectDefinition(current.ids,library);
        snapshot.sky=Policy.findById(skies,skyId);
        if (current.skyMode==='cycle')
            setCurrentSetting({cycleIndex:(current.cycleIndex+1)%100000000});
        return snapshot;
    }
    function step(n) {
        if (!selectionLocked && items.length) selectedIndex=(selectedIndex+n+items.length)%items.length;
    }
}
