# The Archive Capsule — revised Batch 7

## Intent

The Astral Archive should have a *small, persistent access point*, not an
empty full-width bar. The capsule is an illustrated 2D interface: a compact
library emblem, current workspace, clock, theme glyph, and utility emblem. Its floating position
is independent of the wallpaper and rendered above ordinary tiled windows.

A library-shaped **PopupWindow** appears beneath it when summoned. The library popup
uses the SAME illustrated `Book.qml`/`Shelf.qml` components as the launcher;
we are not inventing a second kind of book.

## Spatial layout

```text
                                         [books] [WS 1] [12:45] [✦]
                                                │
                          ┌─────────────────────┴───────────────────┐
                          │ THE LIBRARY                 [✧ INDEX]   │
                          │ WORKSPACES  [1] [2] [3] [4] [5]         │
                          │ PINNED VOLUMES                          │
                          │  [illustrated book spines on a shelf]   │
                          │ RUNNING · UNPINNED                      │
                          │  [illustrated book spines on a shelf]   │
                          └─────────────────────────────────────────┘
```

The capsule floats at top right by default. The two shelves are compact but
preserve original book width (~42px), height (90–160px), and 2px spacing.
They are not a giant launcher or part of the wallpaper.

## Book grouping rule

- **Pinned shelf:** only configured, installed applications. Keep their order
  even when closed. Running/focused ribbons continue to work.
- **Running shelf:** installed applications with visible Hyprland windows that
  aren't pinned. Never duplicate a pinned app here.
- Multiple windows of one app remain **one book**, with the existing count
  marker and Batch 6 window selector.
- Unrecognized or hidden desktop entries currently do not get books. This is
  an acknowledged v1 limitation, not permission to create fake entries.
- To avoid huge popups, show up to six on each shelf initially. Indicate
  overflow and use the Index for full application discovery. Counts and sizing
  are provisional until tested in native QML.

## Interactions

| Action | Result |
| --- | --- |
| Click library emblem | Open/close popup; clicking latches it open |
| Hover library emblem | Accent outline; optional hover-to-open experiment is disabled by default |
| Click a book | Request launch / focus most-recently-observed window |
| Right-click a book | Delegate to full launcher's existing window chooser |
| Click workspace number in popup | Request Hyprland workspace switch |
| Click WS in capsule | Open shelves, then choose desired workspace |
| Click theme glyph | Cycle Evening → Twilight → Midnight |
| Click INDEX in popup | Open the existing floating launcher |
| Outside click (default mode) | Dismiss popup, subject to compositor behavior |
| Escape in popup | Close popup |
| Left/Right | Select previous/next book in current shelf |
| Up/Down | Switch between pinned/running shelves when populated |
| Enter | Activate selected book |
| Ctrl+Enter | Open selected book's multiple-window chooser |
| I | Open the full launcher |
| Alt+1 … Alt+9 | Request numbered workspace switch |

The popup requests keyboard focus only in the default click-open mode; in
optional hover mode it does not grab focus, so it won't steal typing from a
running application when the pointer merely passes over the capsule.

## Architecture

- `panels/ArchiveCapsule.qml`: small, always-visible `PanelWindow`, theme,
  workspace summary, time, popup ownership, action delegation.
- `panels/ShelfPopup.qml`: floating, keyboard-capable `PopupWindow` with two
  ordinary `Shelf.qml` instances and workspace selector.
- `services/ShelfModel.js`: pure pinned/running grouping and workspace-ID logic.
- `services/WorkspaceService.qml`: Hyprland workspace state and dispatch.
- `widgets/WorkspaceIndicator.qml`: dynamic numbered workspace control.
- `config/CapsuleDefaults.js`: capacity and optional hover-mode flag.
- `shell.qml`: composition with the existing independent launcher.

`bar/ArchiveBar.qml` remains unused as an old experimental component; it is
**not** part of the runtime shell after revised Batch 7. This is intentional
and avoids breaking any earlier `BarTest.qml` test scenes.

## Desktop theme persistence (WP-01)

The production shell owns one `ThemePreferences.qml` adapter for
`Quickshell.statePath("theme.json")`, with a version-1 envelope
(`{"version":1,"index":1}`; 0 Evening, 1 Twilight, 2 Midnight).
`themes/Theme.qml` remains the shared in-memory palette singleton, independent
of Quickshell I/O. Synthetic Archive checkpoints and local material overrides
are unchanged and do not write desktop preferences.

A valid saved index is restored before Veranda initialization. A missing file
starts at Twilight and is not created until a deliberate selection. Unreadable,
malformed or unsupported preferences start at Twilight and are protected from
writes for the session; deliberate selection still changes the session theme.
If a user selects before the initial read completes, that choice wins, but is
written only if the read authorizes writes. Initialization alone never writes.
The sole production writer is the capsule's explicit theme selection. Repeated
selection of the already persisted value does not write.

The adapter uses FileView atomic writes and a tiny synchronous write on an
explicit selection (no animation/frame/slider writes), so completion cannot
race a later choice. Write failure preserves the old file under FileView's
atomic-write contract, keeps the chosen session theme, and disables further
writes until restart. A small ! on the theme glyph and a log warning distinguish
session-only changes. Back up and repair the file or move it aside explicitly
while Quickshell is stopped; never automatically replace an unreadable or
incompatible file. Restart to retry after a storage failure. Concurrent external
edits/multiple production shell instances are not supported by this single-owner
preference adapter.

Regression: `node scripts/check-theme-policy.js` exercises pure policy and
actual adapter functions against mocked FileView callbacks, and
`node scripts/check-veranda.js` covers the startup gate. These do not establish
actual Quickshell file I/O or target-session restart behavior. During N4, use
disposable state storage: cycle all three themes, restart the actual shell,
confirm the first wallpaper corresponds to the restored theme, check missing,
malformed, unsupported and unreadable preferences, atomic write failure and
session-only indicator, and confirm isolated study checkpoints do not touch
the desktop preference. Preserve real user state and recovery path.

## Native testing required

- Popup placement on different resolutions, scale factors, and multiple monitors.
- Click-outside dismissal, cursor travel across the gap and optional hover mode.
- Popup keyboard input and previous-window focus when dismissed.
- Workspace state, Qt/Wayland focus management and per-app window matching.
- Rendering size of two full-height bookshelves in the popup.

These cannot be established from JavaScript checks or HTML prototypes.

## Batch 8 extension: second dropdown

A separate illustrated mechanism button opens `UtilityShelf.qml` beneath the
capsule. Opening it closes the library shelf; opening the library closes the
utility shelf. Both are `PopupWindow`s anchored to the capsule and neither
reserves a full-width panel or sits at the wallpaper layer.

The utility shelf includes sound, lantern dimmer, Wi-Fi and Bluetooth power,
battery gauge and a direct KDE System Settings entry. Sound, networking, Bluetooth
and battery use native Quickshell backends; backlight uses `brightnessctl` when
available. See [Utility Shelf](utility-shelf.md).
