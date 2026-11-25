# Architecture

Updated for revised Batch 7 (November 2026). Target: Fedora Linux, Hyprland and
Quickshell/QML, with KDE retained as a fallback desktop during development.

## Layering

```text
Illustrated UI: Book / Shelf / IndexBook / WindowChooser / LauncherPanel
                    |
ApplicationService (installed apps, launch requests, visual book metadata)
WindowService      (Hyprland windows, focus history, activation requests)
                    |
Quickshell DesktopEntries and Hyprland APIs
                    |
Existing Linux apps and Hyprland tiling/workspaces
```

Hyprland owns all tiling and compositor operations. We DO NOT implement a
window manager. Quickshell provides the shell interface and desktop-service
adapters. Services are independent of the illustrated visual components.

## Repository layout

- `quickshell/shell.qml`: Quickshell entry point and global shortcut.
- `quickshell/panels/`: substantial user-facing shell surfaces. The launcher is
  a floating, non-exclusive panel; future Observatory goes here.
- `quickshell/widgets/`: reusable illustrated controls (books, Index, chooser).
- `quickshell/shelves/`: bookshelf layout, delegating click/secondary actions.
- `quickshell/services/`: Linux adapters and pure JavaScript policies.
- `quickshell/config/`: defaults, not a user preferences database yet.
- `quickshell/themes/` and `quickshell/ornaments/`: artwork system.
- `quickshell/tests/`: older visual experiments; postpone appearance judgment
  until tested with native QML.
- `scripts/`: offline checks, eventually installation and validation scripts.
- `docs/`: enduring design agreements and implementation notes.
- `assets/`: fonts and wallpapers; ignored until licensing and inclusion decided.

## App vs window identity

One **book** represents one *application/desktop entry*, not one window.
One application may have zero, one or many windows across workspaces.

`ApplicationService` discovers entries via `DesktopEntries`, then builds
book-friendly display properties. `WindowService` matches those entries to
Hyprland toplevels using `AppMatching.js` and maintains a bounded, in-memory
most-recent-focus history keyed by Hyprland window addresses. A normal click
requests activation of the most recently *observed* matching window; the
secondary chooser explicitly selects a specific window by address.

The chooser does not create or position windows. The `Launch application again`
action invokes the desktop entry's normal execute behavior. Some applications
reuse an existing window instead of creating a new one.

Window addresses are transient runtime identifiers. Never persist them in
configuration. On startup, recent-focus history begins empty and falls back
to currently active window or source order until activity is observed.

`AppMatching.js` uses conservative heuristics. Applications may expose a Wayland
appId that differs from their desktop entry ID; mismatch can cause duplicate
launches or incorrect grouping. Per-app mappings may be needed after real
Linux testing. A failed activation request is not proof that focus succeeded.

## Keyboard focus

- The launcher opens through a global shortcut; its **Index TextInput** receives
  actual Qt keyboard focus. The compositor must grant it at runtime.
- Selected book (`selectedIndex`) is a *visual navigation state*, separate from
  actual keyboard focus. Arrow keys change this state while input remains in
  the Index.
- A right-click or Ctrl+Enter opens the window chooser for a selected book.
  The Index stays the keyboard receiver; up/down/Enter operate the chooser.
  Escape in the chooser returns to the launcher; Escape in the launcher closes
  it and requests restoration of the previous desktop window.
- `running`, `focused desktop app`, `keyboard selected` and `mouse hovered`
  are separate states. A running ribbon is not a keyboard selection indicator.

## Known status and limitations

**Implemented in Batch 6 source, but not natively verified:** application
catalogue, small default shelves, Index search, keyboard selection, global
shortcut declaration, window matching, recent-focus ordering, window chooser,
launch/focus requests and straightforward count marker.

**Not yet implemented:** saved shelf configuration, file-backed scroll racks,
Map Room, persistent app/window mapping overrides, actual hotbar compositor
integration, broader system services and reliable integration tests.

**Important:** the older `LiveLauncherTest.qml` can still run independently
without injecting WindowService. It therefore retains an older, limited
single-window fallback implementation. The main launcher uses WindowService.

## Version-sensitive integration points

Batch 6 is written against Quickshell **v0.3.1** documentation. In that API,
`Hyprland.toplevels` contains Wayland `Toplevel` handles, with attached
`HyprlandToplevel` metadata (`address`, `workspace`). Native desktop validation remains outstanding.

- https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/Hyprland/
- https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandToplevel/
- https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/Toplevel/
- https://quickshell.org/docs/v0.3.1/types/Quickshell/PanelWindow/

## Revised Batch 7: compact capsule + two shelves

This batch replaces the *proposed*, uncommitted full-width hotbar with
`panels/ArchiveCapsule.qml`: an always-visible, small top-right shell panel
(`aboveWindows: true`, `exclusiveZone: 0`). It does not reserve tiling space
and does not depend on the wallpaper layer.

`panels/ShelfPopup.qml` is a Quickshell `PopupWindow` anchored to the capsule.
It shows two instances of the existing `shelves/Shelf.qml`:

1. Pinned volumes, in the configured order. They stay visible if not running.
2. Running, unpinned volumes (only currently installed/recognized apps).

`services/ShelfModel.js` enforces the split, deduplicates app identities and
limits display counts to avoid overcrowding. The full Index continues to
provide access to all installed applications; it is **not** the popup.

`services/WorkspaceService.qml` requests Hyprland workspace changes. Workspace
buttons appear inside the popup; the capsule shows only the current workspace,
clock, theme symbol and library control. The old `bar/ArchiveBar.qml` remains
in the repository for old experiments, but is **not instantiated** in `shell.qml`.

The capsule creates its own `ApplicationService` and `WindowService` instances,
as Batch 6's launcher does. This is temporary duplication of service state,
not duplication of application books in the popup. We can consolidate instances
after native testing confirms correct window activation/focus tracking.

The library control is click-to-open by default; optional hover reveal is
behind `config/CapsuleDefaults.js` and is **untested** for Wayland pointer and
keyboard-focus behavior. The popup can be closed with Escape or by clicking
outside in the default mode. Keyboard selection is local to the popup;
right-click or Ctrl+Enter delegates to the existing window chooser in the full
launcher. No startup/autostart changes are made by this batch.

The mobile-style "dynamic island" refers to compact/expandable *behavior*,
not translucent glass or a permanent full-width bar. Illustrated 2D styling
and the three established themes still govern its appearance.
