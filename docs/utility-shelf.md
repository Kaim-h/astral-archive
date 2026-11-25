# Batch 8 — Utility Shelf

## Goal and scope

A **second, separate dropdown** off the floating Archive Capsule. The small
mechanism emblem toggles a compact illustrated `UtilityShelf` with real controls.
The library's pinned/running shelves and the utility panel are mutually
exclusive. Neither is a wallpaper-layer widget or a full-width bar, and neither
reserves Hyprland tiling space.

The panel is illustrated 2D, with metal edging, embossed scales and simple
text labels. A setting must work or explain why it is unavailable; it must not
pretend that the device changed. We retain the KDE fallback.

## Controls and backend

| Visual relic | Behavior | Backend / prerequisites |
| --- | --- | --- |
| Speaking tube | Output volume 0–100%, mute toggle | Native `Quickshell.Services.Pipewire`, PipeWire running |
| Lantern dimmer | Backlight percent when supported | `brightnessctl`; no script/sudo; minimum change 5% |
| Wi-Fi signal relay | Wi-Fi radio on/off | Native `Quickshell.Networking`, NetworkManager |
| Bluetooth relay | Default adapter power on/off | Native `Quickshell.Bluetooth`, BlueZ |
| Power reserve | Current battery charge, battery/AC indicator | Native `Quickshell.Services.UPower`, UPower |
| System Settings plaque | Launch regular KDE System Settings | `Quickshell.execDetached(["systemsettings"])` |

**Deliberate omissions in this batch:** choosing Wi-Fi networks, entering
passwords, Bluetooth pairing, choosing audio devices, mic gain, VPN control,
full display color calibration, and suspend/reboot actions. Those need more UI,
state/error handling, and testing; use ordinary system settings instead. The
Wi-Fi/Blue toggles do not imply that a network is actually connected or that a
Bluetooth device has paired.

## Dependency approach

Quickshell v0.3.1 is the current source target. Modules can be optional in
custom Quickshell builds. If `Quickshell.Networking`, `Quickshell.Bluetooth`,
`Quickshell.Services.Pipewire`, or `Quickshell.Services.UPower` is missing from
your Quickshell installation, the QML import can fail and the shell may not
load. Verify module availability in a tiny manual test before adding auto-start.
Do not treat offline JavaScript checks as module-loading tests.

Backlight is inherently hardware-dependent; on OLED screens there may be no
`brightnessctl` backlight device. If the read command fails or its output can't
be parsed, the slider stays disabled, and the system-settings button remains
available. The slider only writes on release, never on each mouse movement.
There is no constant brightness polling. Keyboard brightness changes have a 5%
minimum to avoid blacking out the screen accidentally.

The service never runs arbitrary text in a shell. `Process.command` is always
an argument array. KDE System Settings is launched detached; the button only
requests that the normal tool open, it doesn't promise it succeeded.

## Interaction and keyboard

- Click the mechanism emblem to open/close the Utility Shelf.
- Opening the Utility Shelf closes the Library Shelf; opening Library closes
  Utility. Only one large popup is present at a time.
- Click/drags move the volume or brightness scales; the latter is disabled
  until the backlight read succeeds.
- Press **Left/Right**: change volume in 5% steps.
- Press **Shift+Left/Right**: change brightness in 10% steps.
- Press **Space**: mute/unmute; **W**: Wi-Fi power; **B**: Bluetooth power.
- Press **S**: open system settings; **Esc**: close the panel.
- Click outside: popup requests dismissal through `grabFocus`, subject to
  compositor behavior.

The utility panel is a keyboard-focusable popup *only when clicked*, not
hover-triggered. The capsule stays compact at all times.

## Implementation files

- `quickshell/panels/ArchiveCapsule.qml` — revised 7r capsule with second button
  and exclusive-popup state (replaces exactly the 7r file).
- `quickshell/panels/UtilityShelf.qml` — illustrated controls and keybindings.
- `quickshell/widgets/RelicSlider.qml` — reusable percent scale with one commit
  per drag.
- `quickshell/services/UtilityService.qml` — native/optional OS adapters.
- `quickshell/services/UtilityPolicy.js` — bounds, parsing and safety policy.
- `scripts/check-utilities.js` — offline checks (not a native runtime test).

## Native integration checklist

1. Confirm a Quickshell build with all four imports listed above; run the
   Archive from **Konsole**, not auto-start.
2. Verify the library popup remains unchanged and that only one popup opens.
3. Adjust volume and mute on a real PipeWire sink, watch external volume
   changes reflected in the slider.
4. Check Wi-Fi radio status and Bluetooth adapter availability (without
   intentionally disconnecting yourself from remote access).
5. Check battery/AC changes via UPower and handle no-battery systems gracefully.
6. Install `brightnessctl` only if desired; verify `brightnessctl -m` from a
   terminal and check whether brightness writes need udev/group access.
7. Confirm Escape, outside-click, keyboard shortcuts and pointer focus.
8. Test scaling, multi-monitor popup anchoring, and fallback settings launch.
9. Stop Quickshell with Ctrl+C if it fails. Keep a compositor-level terminal
   shortcut and KDE available; enable startup only after these tests.

## Reference API docs (v0.3.1)

- https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Pipewire/PwNodeAudio/
- https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.UPower/UPower/
- https://quickshell.org/docs/v0.3.1/types/Quickshell.Networking/Networking/
- https://quickshell.org/docs/v0.3.1/types/Quickshell.Bluetooth/Bluetooth/
- https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/Process/
- https://quickshell.org/docs/v0.3.1/types/Quickshell/PopupWindow/
