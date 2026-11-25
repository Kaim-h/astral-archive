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
