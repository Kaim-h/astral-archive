import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Networking
import Quickshell.Bluetooth
import "UtilityPolicy.js" as Policy

// The only adapter between the Utility Shelf and OS services. Event driven:
// PipeWire/UPower/Networking/Bluetooth update via Qt properties. Brightness is
// read when the utility panel opens and after user changes; no idle polling.
Item {
    id: utility
    visible: false
    width: 0
    height: 0

    property bool popupOpen: false
    property string message: ""

    // PipeWire: binding is REQUIRED before PwNode.audio.volume/muted are valid.
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [utility.sink] }
    readonly property bool audioAvailable: Boolean(sink && sink.ready && sink.audio)
    readonly property int volumePercent: audioAvailable
        ? Policy.clampPercent(sink.audio.volume * 100) : 0
    readonly property bool muted: audioAvailable ? sink.audio.muted : false

    function setVolume(percent) {
        if (!audioAvailable) { message = "No audio output detected"; return; }
        try {
            sink.audio.volume = Policy.volumeFraction(percent);
            message = "";
        } catch (error) { message = "Audio control unavailable"; console.warn(error); }
    }
    function changeVolume(delta) { setVolume(Policy.adjustPercent(volumePercent, delta)); }
    function toggleMute() {
        if (!audioAvailable) return;
        try { sink.audio.muted = !sink.audio.muted; message = ""; }
        catch (error) { message = "Mute control unavailable"; console.warn(error); }
    }

    // UPower's displayDevice is an aggregate (not a particular physical cell).
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryAvailable: Boolean(battery && battery.ready &&
        (battery.isLaptopBattery || battery.energyCapacity > 0))
    readonly property int batteryPercent: batteryAvailable
        ? Policy.batteryPercent(battery.percentage, battery.energy, battery.energyCapacity) : 0
    // Raw value kept so we can log it and confirm its scale on real hardware.
    readonly property real batteryRaw: battery ? battery.percentage : NaN
    function logBattery() {
        if (!batteryAvailable || isNaN(batteryRaw)) return;
        console.log("[astral-archive] UPower raw percentage=" + batteryRaw +
            " energy=" + battery.energy + " capacity=" + battery.energyCapacity +
            " -> showing " + batteryPercent + "%");
    }
    onBatteryRawChanged: logBattery()
    onBatteryAvailableChanged: logBattery()
    readonly property bool onBattery: UPower.onBattery

    // NetworkManager and BlueZ are Quickshell backends; no nmcli/DBus scripts.
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothAvailable: bluetoothAdapter !== null
    readonly property bool bluetoothEnabled: bluetoothAvailable
        ? bluetoothAdapter.enabled : false

    function toggleWifi() {
        if (!wifiHardwareEnabled) { message = "Wi-Fi hardware is disabled"; return; }
        try { Networking.wifiEnabled = !Networking.wifiEnabled; message = ""; }
        catch (error) { message = "Wi-Fi control unavailable"; console.warn(error); }
    }
    function toggleBluetooth() {
        if (!bluetoothAdapter) { message = "No Bluetooth adapter detected"; return; }
        try { bluetoothAdapter.enabled = !bluetoothAdapter.enabled; message = ""; }
        catch (error) { message = "Bluetooth control unavailable"; console.warn(error); }
    }

    // brightnessctl is optional and never installed automatically. A disabled
    // slider + System Settings fallback are preferable to a misleading dial.
    property bool brightnessAvailable: false
    property int brightnessPercent: 0
    property bool brightnessChecked: false
    property bool brightnessWritePending: false

    function refreshBrightness() {
        if (brightnessRead.running || brightnessWrite.running) return;
        brightnessRead.running = true;
    }
    function setBrightness(percent) {
        if (!brightnessAvailable || brightnessWrite.running) return;
        brightnessWrite.command = ["brightnessctl", "set", Policy.safeBrightnessPercent(percent) + "%"];
        brightnessWritePending = true;
        brightnessWrite.running = true;
    }
    function changeBrightness(delta) {
        setBrightness(Policy.adjustPercent(brightnessPercent, delta));
    }
    function readBrightness(text) {
        var level = Policy.parseBrightness(text);
        if (level !== null) {
            brightnessPercent = level;
            brightnessAvailable = true;
        } else {
            brightnessAvailable = false;
        }
        brightnessChecked = true;
    }
    onPopupOpenChanged: {
        if (popupOpen) refreshBrightness();
    }

    Process {
        id: brightnessRead
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: utility.readBrightness(this.text)
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                utility.brightnessAvailable = false;
                utility.brightnessChecked = true;
            }
        }
    }
    Process {
        id: brightnessWrite
        command: ["brightnessctl", "set", "50%"]
        onExited: function(exitCode, exitStatus) {
            utility.brightnessWritePending = false;
            if (exitCode !== 0) {
                utility.message = "Brightness change failed; use Display Settings";
                utility.brightnessAvailable = false;
            } else {
                utility.refreshBrightness();
            }
        }
    }

    function openSystemSettings() {
        try {
            // KDE systemsettings is installed by Fedora KDE. Quickshell spawns
            // it as a separate application; no dependency on our capsule.
            Quickshell.execDetached(["systemsettings"]);
        } catch (error) {
            message = "Open KDE System Settings from your terminal";
            console.warn("Couldn't launch systemsettings:", error);
        }
    }
}
