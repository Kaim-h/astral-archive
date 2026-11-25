# Current component map

This preserves the **Batch 11 shell composition snapshot** below for provenance; consult current shell.qml for actual wiring. Later Patch 12 and isolated B6 Archive source are merged. See the current extension at the end and CURRENT_STATE for evidence.

## Runtime composition (`quickshell/shell.qml`)

```text
ShellRoot (quickshell/shell.qml)
├── LauncherPanel              (owns its own application/window services)
├── VerandaService             (awww + wallpaper preferences)
├── VistaTransition            (referenced by VerandaService)
├── VerandaOfVistas            (receives VerandaService)
├── GalleryCatalogue           (gallery artwork/preferences)
├── GalleryFullViewer          (receives palette; editor unwired at base)
├── CelestialGallery           (receives viewer and catalogue)
├── ArchiveCapsule             (owns library + utility popups)
│   ├── ShelfPopup             (Shelf/Book, grouping and workspaces)
│   └── UtilityShelf           (UtilityService and RelicSlider)
└── GlobalShortcut × 3         (veranda, gallery, launcher)

LauncherPanel uses ApplicationService and WindowService, backed by
AppMatching.js, WindowModel.js and LauncherModel.js.

CelestialGallery and GalleryFullViewer use GalleryCatalogue data, Gallery
widgets and GLSL shader assets. The GalleryCelestialEditor source exists in
Batch 11 but its common shell instance/wiring is missing until Patch 12.
```

The shared Gallery customization editor is proposed in the separate supplied Patch 12 but is **not wired in the inspected Batch 11 base**; see `docs/development/CURRENT_STATE.md`.

## Main areas

| Directory | Responsibility |
|---|---|
| `quickshell/shell.qml` | Shell composition and global shortcuts. |
| `quickshell/panels/` | User-facing floating panels / popup surfaces. |
| `quickshell/widgets/` | Reusable illustrated controls and Gallery artwork/dome/drum/map/transition pieces. |
| `quickshell/shelves/` | Shelf layout and book placement. |
| `quickshell/services/` | Quickshell adapters and application-level state / integration services. |
| `quickshell/config/` | Component defaults and geometry configuration; not a complete preference database. |
| `quickshell/themes/`, `quickshell/ornaments/` | Theme role values and illustrated ornament system. |
| `quickshell/data/` | Manifests, procedural constellation / sky datasets and other static data. |
| `quickshell/shaders/` | GLSL source compiled by repository scripts into local `.qsb` artifacts. |
| `quickshell/tests/` | QML visual / test scenes; not all are full integration tests. |
| `scripts/` | Offline checks, shader compilation helpers and artwork preprocessing. |
| `docs/` | Product direction, implementation notes, current state and historical research. |

## Integration boundaries

- `ApplicationService` discovers desktop entries and prepares app-book metadata.
- `WindowService` observes Hyprland toplevels and requests activation; window addresses are transient.
- `WorkspaceService` requests Hyprland workspace changes. Hyprland remains the window manager / compositor.
- `UtilityService` wraps available Quickshell system-service APIs and optional `brightnessctl` / KDE settings actions.
- `VerandaService` owns wallpaper preferences and `awww` requests. It does not render the desktop wallpaper itself.
- `GalleryCatalogue` owns artwork metadata and per-artwork celestial customization. Gallery assets remain separate from Veranda wallpapers.

## Coupling and change-review checklist

Before changing one subsystem, inspect:

- the shell composition and all QML callers;
- public properties, signals and functions used by other panels;
- service ownership and whether state is duplicated;
- persisted state schema / migration and missing-file behavior;
- imported Quickshell modules and installed-version assumptions;
- global shortcuts and matching Hyprland binds;
- shaders and their compile scripts / uniforms;
- relevant offline checks and their CI workflow entries;
- native focus, screen anchoring, monitor scaling and service fallback requirements.

Do not assume similar-looking panels share state or services. The architecture document records intentional temporary service duplication in older batches; inspect current source before attempting consolidation.

## Historical extension — isolated Archive (B6-N3 / B7-C)

This section describes an earlier checkpoint, superseded by the B7-N2 extension below.

- `quickshell/archive/ArchiveCore.mjs`: synthetic value state, clipped cells, deterministic packing/reflow/voids and atomic transactions.
- `ArchiveModel.qml` + `ArchivePlanner.mjs`: revision-aware WorkerScript planning, preview/commit/cancel/Undo; timeout path in N3.
- `ArchiveMotion.mjs` + `ArchiveMotion.qml`: provisional live scroll motion and active-only fixed-step scheduling.
- `ArchiveScene.qml`, `ArchiveRack.qml`, `ArchiveCubbyFace.qml`, `ArchiveCase.qml`, `ArchiveScrollEnd.qml`, `ArchiveTooltip.qml`, `ArchiveView.mjs`: isolated scene, camera/navigation, fixtures, portable case, metadata and appearance.
- `quickshell/tests/ArchiveNativeN2Window.qml` and N1/N2/N3 Qt tests: actual offscreen synthetic study, not imported into shell.qml.
- B7-C candidate `RepresentationCatalog.mjs` and `representation-assets/`: pure policy/geometry and SVG/manifest; no runtime import or fixture renderer yet. See [asset contract](../product/REPRESENTATION_ASSETS.md).

Patch 12 supersedes the historical editor-wiring omission above. Remaining editor/persistence parity and target validation are tracked in ACTIVE_WORK. No Map Room or actual file actions yet.

## Integrated B7-N2 extension

At original technical main `4366c5cae25d949ea7d21c8c595de8132893d6b4`, the isolated Archive additionally uses `ArchiveCapacity.mjs` for shared capacity preflight, `ArchiveCheckpoint.mjs` for v1/v2 study checkpoints, `representation/B7Ownership.mjs` and `B7Layout.mjs` for mixed ownership and geometry, and native representation components. Core retains the same-ID arrangement commit and Undo boundary. `quickshell/tests/ArchiveB7MixedWindow.qml` runs the mixed study; `ArchiveStudyStorage.qml` provides explicit single-slot synthetic persistence. No production shell import or real file actions. See [current state](../development/CURRENT_STATE.md) and [B7-N2 record](../development/B7_N2_MIXED_CUBBIES.md) for exact evidence. N4 remains mandatory before production integration. See the [inter-development architecture review](ARCHIVE_INTERDEVELOPMENT_REVIEW_2026-11-24.md) for the pinned source map, lessons and advisory recommendations.
