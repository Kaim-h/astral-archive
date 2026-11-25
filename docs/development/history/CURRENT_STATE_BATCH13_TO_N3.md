# Current state — Batch 13 base snapshot

> Historical identifiers refer to earlier development history, not current pull requests or new checks.

> **Historical snapshot notice (November 23, 2026):** This document retains its original dated claims for provenance, including statements about Patch 12/Batch 13 that may have been superseded by later commits. It is **not a live status feed**. For subsequent browser-only storage research see [B6 research chronology](../B6_RESEARCH_STATUS_2026-11-23.md); check current source and CI before assuming native implementation. No part of that browser research was ported to Quickshell by this documentation PR.

**Snapshot date:** November 18, 2026 (source state; not a live status feed)  
**Repository:** historical development baseline  
**Branch / base commit inspected:** `main` / `edd9964af8bc69c3a0558652068ea0342d5fee50` (`batch 11, and patch four and five`)  
**Batch 13 scope:** persistent project knowledge and documentation integration. No Quickshell implementation changes are included in this documentation batch.

> Re-check the branch head before relying on this snapshot. It describes the repository state inspected while preparing Batch 13, not a live status feed.

## 1. What exists in tracked source

At the inspected base commit, the repository contains 104 tracked files: 45 QML files, 23 JavaScript files (including scripts), four JSON data files, three GLSL fragment shaders, 13 documentation files, plus workflow and asset placeholders.

Current tracked application areas:

| Area | Main source | Current source status |
|---|---|---|
| Shell composition | `quickshell/shell.qml` | Launcher, Veranda, Gallery, Capsule and global shortcuts are composed here. |
| Launcher / Index | `panels/LauncherPanel.qml`, `widgets/Book.qml`, `widgets/IndexBook.qml`, `services/ApplicationService.qml`, `services/LauncherModel.js` | App catalogue, app books, Index app search and launch/focus requests. Index does not yet index files or rooms. |
| Windows / workspaces | `services/WindowService.qml`, `WindowModel.js`, `AppMatching.js`, `WorkspaceService.qml`, `widgets/WindowChooser.qml` | Hyprland integration and transient window activation/focus behavior. Native behavior remains unverified. |
| Capsule / shelves | `panels/ArchiveCapsule.qml`, `panels/ShelfPopup.qml`, `shelves/Shelf.qml`, `services/ShelfModel.js` | Compact floating Capsule and pinned / running-unpinned shelves. |
| Utility Shelf | `panels/UtilityShelf.qml`, `services/UtilityService.qml`, `services/UtilityPolicy.js`, `widgets/RelicSlider.qml` | Source adapters for PipeWire, brightnessctl, UPower, NetworkManager and BlueZ. Hardware behavior not verified. |
| Veranda | `panels/VerandaOfVistas.qml`, `services/VerandaService.qml`, `services/VistaPolicy.js`, `widgets/VistaTransition.qml` | Wallpaper manifest, preferences, awww calls and optional shader transition source. Local wallpapers are ignored. |
| Celestial Gallery | `panels/CelestialGallery.qml`, `GalleryFullViewer.qml`, `GalleryCelestialEditor.qml`, Gallery widgets/services/data/shaders | Gallery observatory, artwork presentation and per-artwork constellation / sky customization source. Native runtime is not verified. |
| Themes / ornaments | `themes/Theme.qml`, `ornaments/` | Three existing visual themes and reusable illustrated embellishments. |

## 2. Product features not yet implemented in native source

The following are product requirements / prototypes, not current Quickshell implementation at this snapshot:

- Map Room and real room/shelf/cubby navigation.
- The unified recursively nestable Cubby model and filesystem-to-visual placement mapping.
- File indexing, filesystem-aware Index search, direct file Open and spatial Locate.
- Symbolic file-object families (scrolls, framed art, sculptures, records, tablets, ledgers, satchels, instruments).
- Shared tessellated scroll-cell geometry and the v5.4 lift / insert / drop interaction.
- Physical fixture-aware object placement and a native scroll physics implementation.
- Persistent Archive layout, import roots, file lifecycle reconciliation and Arrange-mode persistence.

The Map Room v1/v2 and Storage Workshop v3–v5.4 included with the handoff are standalone HTML/SVG/JavaScript prototypes. They must not be described as pushed QML components.

## 3. Validation state

The GitHub Actions workflow at the inspected base ran on November 17, 2026 and **failed** at `Gallery structure` in `scripts/check-gallery.js`. The assertion expected `quickshell/shell.qml` to contain `Panels.GalleryCelestialEditor`, but the base shell did not instantiate and connect the shared editor. Later steps were skipped after that failure.

The preceding checks in that run passed: launcher, windows, shelves, utility policy, Veranda and Vista FX. This does not prove QML runtime or native system integration.

A separate user-supplied Patch 12 package was inspected. It proposes:

- wiring one shared `GalleryCelestialEditor` into the Gallery and full viewer;
- battery percentage scale handling and diagnostic logging;
- `.gitattributes` LF normalization;
- a QML import/component resolver check;
- a first native bring-up guide.

**Patch 12 was not present on the inspected `main` commit. The combined Patch 12 + Batch 13 review branch applies the Patch 12 changes alongside these documents; see the integration note below.** Its battery heuristic and native behavior still require review/testing. Do not assume its changes are merged merely because the ZIP was supplied.

No native Quickshell/Hyprland session, QML parsing, Qt shader compilation, actual MPRIS playback, real device control, multi-monitor behavior or target desktop performance was verified by this repository inspection.

## 4. Design and environment snapshot

- Intended foundation recorded in the handoff: Fedora KDE with Plasma retained as fallback, Hyprland compositor, Quickshell / Qt Quick / QML / JavaScript shell; initial code target around Quickshell v0.3.1.
- Hyprland owns compositor behavior, tiling, workspaces and window placement; Astral Archive is not a replacement window manager.
- Existing themes are Evening, Twilight and Midnight. Role values live in `quickshell/themes/Theme.qml` and must be checked there before changing them.
- Fonts, wallpapers and user art may be local/private and must not be bundled without permission.
- The repository was private at the inspected base. No visibility change is part of Batch 13.

## 5. Batch 13 documentation and portability

The Batch 13 changeset itself adds documentation and the archived textual November 17 handoff, historical HTML prototypes and diagnostic scripts. It intentionally does **not** include reference-image binaries or Patch 12 QML/JavaScript changes. The state counts above refer to the **pre-Batch-13** base commit, not the post-merge file inventory.

## 6. Status language

Use the labels in `docs/README.md`. In particular, source presence, offline verification and native verification are different states. A prototype can inform design without being approved native architecture.

## 6. Combined Patch 12 + Batch 13 review branch (unmerged)

This additional integration note describes the proposed review branch rather than the Batch 11 snapshot above. Patch 12 adds a shared Gallery editor in `quickshell/shell.qml`, battery-scale handling and diagnostic logging, QML import resolution checks, a native bring-up guide, and `.gitattributes`. The GitHub Actions workflow is extended to execute the QML resolver check. These are **IMPLEMENTED SOURCE on the proposed branch**, not yet verified on a native Fedora/Hyprland system.

At this stage the repository's existing historical text line endings are **not repository-wide renormalized**. `.gitattributes` specifies the policy for future text handling, but the one-time `git add --renormalize .` cleanup is deferred as a separate, deliberate review.

Treat CI status as *pending* until the proposed branch's actual GitHub Actions workflow completes. Never claim native runtime validation from Node-based checks.

## November 24 native Archive candidate (unmerged)

B6r12b3 browser research candidate on PR #7 passed both jobs of run 45392280473. B6-N1 is a separately reviewable stacked native branch, containing a pure ECMAScript core, Qt Quick model and WorkerScript planner, with synthetic fixtures only. Check the native branch CI for actual Node and offscreen Qt outcomes. No production Archive panel is exposed in the main shell; Native desktop validation remains outstanding. See ENVIRONMENT.md and ACTIVE_WORK.md.

## N2 native visual candidate (unmerged, PR #8)

N1 pure Node and offscreen Qt 6.4.2 passed in run 45394196420. N2 source adds the isolated native illustrated scene and synthetic recursive cubby structure; verify its own CI before claiming native scene behavior. No production integration, live drag parity or Fedora/Hyprland measurement yet. Native desktop validation remains outstanding.

## N3 candidate (unmerged)
N2 full CI passed (45395402883). The N3 source contains live synthetic scroll transactions, native gesture and insertion paths, and comparison tests. Verify actual CI results before claiming live parity; Native desktop validation remains outstanding.
