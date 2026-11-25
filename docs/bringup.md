# Native Linux bring-up guide

Nothing in this project has been run natively yet. The offline Node checks only
test pure logic and file structure; they are **not** QML tests. This page is the
plan for the first real run, and a list of everything the code assumes about
Quickshell that has not been confirmed.

Plain-words glossary:

- **Quickshell (`qs`)**: the program that runs the shell. It reads QML files and
  draws the panels.
- **Hyprland**: the window manager (it places windows and handles keys).
- **Global shortcut**: a key combo that Hyprland forwards to Quickshell. Quickshell
  declares the shortcut; you must add a matching `bind` line to Hyprland's config.
- **appid**: the first half of the shortcut's full name. Quickshell uses `quickshell`
  unless the code sets another one. The code does not, so it is `quickshell`.

## Where the shell runs from

From the repository root, inside a Hyprland session:

```sh
qs -p quickshell/shell.qml
```

`-p` means "run this config path". The shell file is `quickshell/shell.qml`.
Compiled shaders (`*.qsb`) are generated into `quickshell/shaders/` by the scripts
in `scripts/` and are not committed.

## Hyprland bind lines

The three shortcuts are declared in `quickshell/shell.qml`. The key choices
below are suggestions only; pick any free combo. Check the key is not already
bound (`hyprctl binds`).

```ini
bind = SUPER, V, global, quickshell:veranda-of-vistas
bind = SUPER, G, global, quickshell:celestial-gallery
bind = SUPER, A, global, quickshell:astral-archive
```

| Shortcut name | What it does |
|---|---|
| `veranda-of-vistas` | Opens or closes the wallpaper selector |
| `celestial-gallery` | Shows or hides the Celestial Gallery |
| `astral-archive` | Opens or closes the launcher |

Put the lines in your Hyprland config, reload it, then run:

```sh
hyprctl globalshortcuts
```

All three should be listed as `quickshell:<name>` once the shell is running. If
one is missing, the name in the bind does not match the name in `shell.qml`.

> Config format note: `WorkspaceService.qml` checks `Hyprland.usingLua`. If your
> Hyprland uses a Lua config instead of the classic `hyprland.conf`, the bind
> line is written differently; check the Hyprland docs for your version.

## First-hour checklist

Do these in order and stop at the first failure. Copy the exact error text.

1. [ ] Make sure a plain terminal / KDE login still works as a fallback.
2. [ ] `qs --version` prints a version. The code targets **Quickshell v0.3.1**.
3. [ ] Normalize line endings first (`git add --renormalize .`, see CHANGES.md).
       Then `head -1 scripts/compile-gallery-shader.sh | od -c` must end in `\n`, not `\r \n`.
4. [ ] `which qsb` finds Qt Shader Tools. Then `bash scripts/compile-gallery-effects.sh`
       and `bash scripts/compile-vista-shader.sh`. (Without them the shell still
       runs, with a plain fallback instead of shader effects.)
5. [ ] `qs -p quickshell/shell.qml` starts. Read the first error in the log, if any.
       A missing module (see assumptions below) usually shows as `module "..." is not installed`.
6. [ ] `hyprctl globalshortcuts` lists the three shortcuts, then each bind opens its panel.
7. [ ] Capsule is visible and does not reserve screen space.
8. [ ] Launcher: opens, lists apps, launches one; right-click window chooser works.
9. [ ] Veranda: opens, wallpaper change works (needs `awww` installed; see assumptions).
10. [ ] Celestial Gallery: opens; open the full-screen viewer from it; then
        open the editor with `C`, a right-click on the artwork, or the "EDIT" button
        (also reachable from the Gallery panel). Escape closes the editor first,
        then the viewer.
11. [ ] Utility shelf battery: find the log line starting `[astral-archive] UPower raw percentage=`
        (in the terminal running `qs`). Write down the raw value. It should be a
        fraction like `0.81` (docs say it equals energy / energyCapacity) or a whole
        number like `81`. The shelf must show the real charge either way.
12. [ ] Brightness slider (needs `brightnessctl`), volume, mute, Wi-Fi and Bluetooth toggles.
13. [ ] Write down anything that failed, with the log line, for Batch 13.

## Assumptions about Quickshell (not confirmed on hardware)

"Opened" means the doc page was actually read while preparing this patch.
Other links are the ones the repo's own docs already cite; they were **not** re-opened.

| # | Assumption | Where used | Doc link | Opened? |
|---|---|---|---|---|
| 1 | `UPowerDevice.percentage` is "current charge level as a percentage" and is described as energy / energyCapacity, so its scale (0-1 or 0-100) is unclear. Code now handles both. | `UtilityService.qml` | https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.UPower/UPowerDevice | yes |
| 2 | `UPowerDevice.energy`, `.energyCapacity` (watt-hours), `.ready`, `.isLaptopBattery` exist; `ready` may be false for the default device at first. | `UtilityService.qml` | same as #1 | yes |
| 3 | `UPower.displayDevice` and `UPower.onBattery` exist. | `UtilityService.qml` | https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.UPower/UPower/ | no |
| 4 | `GlobalShortcut` has `name`, `description`, `onPressed`; `appid` defaults to `quickshell`; Hyprland bind is `bind = MODS, key, global, appid:name`. appid+name must be unique. | `shell.qml` | https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/GlobalShortcut | yes |
| 5 | `PanelWindow` supports `anchors`, `margins`, `aboveWindows`, `exclusiveZone`, `focusable`, `color`, `screen`, `implicitWidth/Height`. | all panels | https://quickshell.org/docs/v0.3.1/types/Quickshell/PanelWindow/ | no |
| 6 | `Hyprland.focusedWorkspace`, `.workspaces.values`, `.toplevels.values`, `.activeToplevel`, `.dispatch()`, `.usingLua`; `HyprlandToplevel` is an attached object with address and workspace. | `WorkspaceService.qml`, `WindowService.qml`, `ApplicationService.qml`, `LauncherPanel.qml`, `ArchiveCapsule.qml` | https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/Hyprland/ and https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandToplevel/ | no |
| 7 | `Toplevel` (from `Hyprland.toplevels`) exposes `appId` and focus/activate calls. | `ApplicationService.qml`, `ArchiveCapsule.qml` | https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/Toplevel/ | no |
| 8 | `DesktopEntries.applications.values` and `.byId()` exist. | `ApplicationService.qml` | none cited in repo | no |
| 9 | `Process` with `command` runs and reports `onExited(code, status)`; `Quickshell.execDetached([...])` starts a program without waiting. | `UtilityService.qml`, `VerandaService.qml`, `VistaTransition.qml`, `GalleryFullViewer.qml`, `GalleryDome.qml` | https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/Process/ | no |
| 10 | `FileView` (with `atomicWrites`) and `Quickshell.statePath("file.json")` store settings. | `GalleryCatalogue.qml`, `VerandaService.qml` | none cited in repo | no |
| 11 | `Pipewire.defaultAudioSink`, `PwObjectTracker`, and `node.audio.volume/muted` work once tracked. | `UtilityService.qml` | https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Pipewire/PwNodeAudio/ | no |
| 12 | `Networking.wifiEnabled` / `wifiHardwareEnabled` are readable and `wifiEnabled` is writable. | `UtilityService.qml` | https://quickshell.org/docs/v0.3.1/types/Quickshell.Networking/Networking/ | no |
| 13 | `Bluetooth.defaultAdapter` and `adapter.enabled` (read/write). | `UtilityService.qml` | https://quickshell.org/docs/v0.3.1/types/Quickshell.Bluetooth/Bluetooth/ | no |
| 14 | `Mpris.players.values` with `canTogglePlaying`. | `GalleryMusic.qml` | none cited in repo | no |
| 15 | `Variants { model: Quickshell.screens }`, and `WlrLayershell.layer` / `.namespace` as attached properties. | `VistaTransition.qml` | none cited in repo | no |
| 16 | Optional modules (`Networking`, `Bluetooth`, `Pipewire`, `UPower`) are included in the installed Quickshell build. If not, the whole shell may fail to load. | `UtilityService.qml` | see `docs/utility-shelf.md` | no |
| 17 | External programs are installed: `brightnessctl`, `systemsettings` (KDE), `awww` (wallpaper), `qsb` (shader compiler). | utility shelf, Veranda, scripts | n/a | n/a |
| 18 | Quickshell finds `.qsb` shaders next to the QML via `Qt.resolvedUrl`, and a missing shader falls back gracefully. | `GalleryFullViewer.qml`, `GalleryDome.qml`, `VistaTransition.qml` | n/a | n/a |

Items marked "no" are the most likely places for a first-run surprise.
If a link above has moved, search the property name on the Quickshell docs site.
