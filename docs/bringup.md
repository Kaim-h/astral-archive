# Native Linux bring-up guide

The target Quickshell/Hyprland desktop has not been validated (N4). Offline Node checks test pure logic and file structure; separate offscreen Qt Quick checks exercise QML and rendering, not actual shell/service integration. This page is the plan for the first real target run and retains the original Quickshell assumptions; see [current state](development/CURRENT_STATE.md) for exact verification.

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
3. [ ] Check shell-script line endings first: `head -1 scripts/compile-gallery-shader.sh | od -c`
       must end in `\n`, not `\r \n`. Inspect `git ls-files --eol scripts/compile-gallery-shader.sh`
       and the repository's [attributes](../.gitattributes) if the checkout has CRLF. Correct only affected tracked scripts in an authorized clean worktree; inspect the diff. `git add --renormalize` stages normalization and is not a repair of checkout bytes; do not indiscriminately stage unrelated work.
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

## N4 desktop preference and startup acceptance

**Outstanding; not performed by CI or this documentation review.** Apply to the WP-01/07 candidate or its eventual integrated revision, after the first-hour safety/dependency checks. Record exact revision, actual Quickshell/Qt/backend versions and results. Use a disposable shell/session and isolated state directory; confirm resolved Quickshell state paths are inside that disposable directory before creating fixtures or starting the shell. Never modify, move, corrupt, replace or test failure against real user preference files. Retain terminal/KDE/TTY recovery, manual launch and no premature autostart; use synthetic wallpaper fixtures and safe backend isolation for failure injection. If a fault cannot be induced safely, record it as untested.

- [ ] Cycle Evening, Twilight and Midnight by explicit capsule selection; verify persisted bytes and restore each selection across actual Quickshell restarts. Verify initialization and repeated already-saved choices do not write. First wallpaper request uses the restored/resolved theme, not provisional Twilight; count requests and check backend outcome, both completion orders and no duplicate apply.
- [ ] Exercise missing, malformed, unsupported-version and unreadable theme and Veranda preference fixtures independently. Confirm only confirmed absence or valid preferences authorize writes (Veranda also requires a valid nonempty catalogue); compare original bytes before/after, verify protected session-only changes, warning and recovery on restart.
- [ ] Exercise missing/late/repeated or contradictory completion and timeout for theme, catalogue and Veranda reads, separately and combined, using a safe disposable native harness or controlled fault injection. The three-second deadlines are responsive-event-loop deadlines, not wall-clock guarantees. Confirm first terminal result is retained, explicit pending theme selection wins, protected theme fallback resolves before Veranda, and delayed callbacks do not replace decisions or unlock persistence.
- [ ] Veranda preference timeout: verify MANUAL state, no automatic initial apply, tick, theme-triggered apply or retry, no preference writes; explicitly select an eligible wallpaper and confirm one manual request, session-only animation changes and no later automatic rotation. Verify unavailable catalogue disables application and persistence.
- [ ] Exercise actual reported save failure, missing completion (theme) and atomic commit failure in disposable storage. Inspect file bytes independently of cached FileView text or saved signals; verify theme readback and write latch, Veranda reported-failure latch and whether the known false-success limitation occurs. Record asynchronous completion and already-submitted writes separately; do not infer original-byte preservation or successful persistence from a signal. Test restart recovery safely. See [theme persistence](capsule.md#desktop-theme-persistence-wp-01) and [Veranda persistence limitation](veranda-of-vistas.md#bounded-startup-recovery-wp-07--aud-22).
- [ ] Exercise isolated Archive study theme/material changes and synthetic Save/Load; verify production theme preference bytes remain unchanged.
- [ ] Preserve existing Veranda daemon, paused-selection/tick, theme/day, filename and transition tests, service availability, focus/scaling/shader and recovery requirements in the [Veranda guide](veranda-of-vistas.md), [environment](development/ENVIRONMENT.md) and relevant subsystem guides.

Record observed native behavior separately from mocked callback or offscreen Qt evidence; no claim of target acceptance until these checks are actually executed and assessed.

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

### B8-N3 selected policy target-native acceptance (provisional)

Before production integration, on actual Fedora/Hyprland/Quickshell session verify combined frame/wall proportions (24 reference, 1339.2 absolute), title and wall readability, narrow/wide/tall casework, fractional DPR/scaling, empty/populated/tall-outlier Rooms, aligned door visibility, actual hit and floor inverse at boundaries, move/resize/turn and blocked edits, navigation entry/return/interruption and real presented frame pacing (both projections), compositor deactivation and pointer cancellation. Verify global projection preference restart/checkpoint restore, default 2D on absent/legacy view, reset and failed-load behavior, v3/v4 old geometry and explicit v5 adoption/refusal/Undo/recovery. Measure responsiveness, resource use and idle/hidden cost separately from CI/JS callback proxies. No target pass inferred from offscreen Qt/browser checks; adjust provisional policies only through explicit compatible versioned changes. Preserve existing manual recovery and production gate.

### Integrated B8 target release checklist (unperformed)

Automated N6a–d passed in Node/browser/offscreen Qt; [integrated evidence](development/B8_INTEGRATED_IMPLEMENTATION.md) is not actual target acceptance. Use disposable synthetic state and manual launch, retain KDE/TTY recovery and no autostart. In addition to the N3 selected-policy and desktop N4 checks above:

- [ ] Verify actual Fedora/Hyprland/Quickshell versions, imports and renderer; contrast/legibility, accessibility and ergonomics across all themes, narrow/wide and fractional DPR.
- [ ] Repeat mixed-button and edge routing, hover/drag/right-click/Case/modal isolation, deactivation/cancellation, keyboard focus and reduced motion; measure actual presented transitions and input-to-presented frames.
- [ ] Measure dense cold/warm map/Room/render and varied occupied-cell/reflow/door obstruction complexity, sustained idle/hidden behavior and process CPU/GPU/RAM/power. Do not equate runner timings or array bytes with these measures.
- [ ] Exercise standalone v6 restart, separate preference-store restart and precedence, manual Save replacing a corrupt row without test pre-repair, representative older-format compatibility, isolated disk/permission faults and crash recovery. Never inject faults into real user files; record unsafe/unperformed cases explicitly.

All checks remain outstanding until actual target evidence is recorded and assessed. Preserve accepted native approximations and separately deferred aesthetics; no production Archive enablement from this checklist alone.
