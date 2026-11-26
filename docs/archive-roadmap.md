# Astral Archive roadmap

## Current dependency roadmap

This is a milestone dependency sequence, not a release schedule or authorization. See [current state](development/CURRENT_STATE.md) for integrated source and exact evidence, [active work](development/ACTIVE_WORK.md) for live topics, and [product specifications](product/) for accepted requirements.

| Stage | Status / dependency |
|---|---|
| Desktop foundations | Source integrated: illustrated launcher, Capsule, Utility Shelf, Veranda and Gallery. Actual desktop validation outstanding. |
| B6–B7 Archive foundations | Integrated isolated native study: scroll physics, recursive mixed cubbies, file representation assets, Scroll Case and synthetic checkpoint/Undo. |
| B8 spatial design | S20 specification integrated through [PR #18](https://github.com/Kaim-h/astral-archive/pull/18); [contract](product/B8_SPATIAL_ARCHIVE.md), [handoff](development/B8_IMPLEMENTATION_HANDOFF.md). |
| B8 native N1–N6 | In development in [PR #19](https://github.com/Kaim-h/astral-archive/pull/19). N1 spatial foundation, N2 furnished Shelves, N3 Room views/navigation, N4 Map Room/shared doors, N5 appearance/context interaction, N6 integrated verification. Consult live disposition; not released. |
| B8 documentation reconciliation and refinement | Consolidate final accepted implementation, compatibility and verification; separately authorized customization/refinement work. |
| Target desktop validation | Actual Fedora/Hyprland/Quickshell bring-up gate (distinct from B8-N4 Map Room); mandatory before production enablement. Retain KDE/TTY recovery and manual launch. |
| Later file Archive work | Index and explicit-root indexing/reconciliation, safe real file operations, production layout persistence and shell wiring under separately authorized scope. No backend or destructive-operation policy assumed. |
| Desktop quality of life | Planned: notifications, system tray, clipboard and screenshot integration, session/lock controls and everyday desktop interaction improvements. Exact scope and sequencing require separate authorization. |
| Desktop integration and distribution | Accessibility, performance, multi-monitor validation, reproducible setup and distribution according to demonstrated need; production enablement remains gated by actual target validation. |

Visual arrangement must remain distinct from filesystem mutation. Browser and offscreen Qt checks are not actual target desktop evidence. Preserve identity, support/contact geometry, reversible transactions and user data.

## Historical roadmap records (superseded status and next actions)

All sections below describe earlier checkpoints, not the current implementation or outstanding assignments. Preserve their evidence and design history; use the current dependency roadmap above for present planning.

## Historical roadmap — Batch 13 base (Batch 11)

- **Batches 1–5:** illustrated books, shelves, ornaments, themes, floating launcher, Index-first keyboard interaction and basic application activation.
- **Batch 6:** multiple-window awareness, chooser, focus recency, architecture notes and initial offline checks.
- **Batch 7 (revised):** compact floating Archive Capsule, detachable library popup, pinned / running-unpinned shelf split and workspace controls. This supersedes the earlier uncommitted full-width bar concept.
- **Batch 8:** Utility Shelf source for PipeWire volume / mute, brightnessctl where supported, UPower battery, NetworkManager Wi-Fi, BlueZ Bluetooth and KDE System Settings fallback. Native integration pending.
- **Batch 9:** Veranda of Vistas wallpaper selector, theme-filtered manifest, saved selection / rotation preferences, `awww` integration and optional transition effects. Native rendering / backend validation pending.
- **Batch 10:** Celestial Gallery / Observatory source, artwork viewer, dome / telescope, drum, Gallery music integration and fullscreen transition source. Native validation pending.
- **Batch 11:** Gallery per-artwork constellation selection and procedural sky presets, shared constellation data / rendering, editor source, shader / dome geometry fixes and expanded offline checks. At the inspected base commit the shared Gallery editor was not yet wired into `shell.qml`; the supplied Patch 12 package addresses that source-level gap but is not included in Batch 13.

## Documentation / maintenance batches

- **Patch 12 (included in the combined review branch):** proposes shared Gallery editor wiring, battery-scale handling / diagnostic logging, LF normalization, QML component resolver checks and a first native bring-up guide. It is not included in this documentation-only Batch 13; review and integrate separately.
- **Batch 13:** persistent, portable product / architecture / development documentation; a root `AGENTS.md`; current-state / active-work / environment records; an indexed November 17 handoff and prototype archive. No new application feature code is included.

## Native validation milestone

The existing source should be launched manually in the target Fedora KDE + Hyprland environment before autostart or system-level changes. Keep Plasma and a TTY / terminal recovery route. Confirm exact Quickshell / Hyprland / Qt versions and optional Quickshell modules; compile shaders; test global shortcuts, launcher / focus, Capsule / popups, Utility Shelf service values, Veranda / awww, Gallery / MPRIS / shaders, keyboard focus, fractional scaling and multiple monitors. Record failures with exact logs. See `docs/development/ENVIRONMENT.md` and `docs/development.md`.

The inspected Batch 11 CI run failed at the Gallery structure check due to missing editor wiring; other checks before that step passed. Patch 12 proposes the fix but has not been included in this Batch 13 baseline. See `docs/development/CURRENT_STATE.md`.

## Future file Archive work — product direction, not implementation

The Map Room and spatial file Archive are not present in current Quickshell source. The agreed hierarchy is Map Room → Room → Shelf → unified recursive Cubby. Cubbies contain fixture types (shelf surfaces, physical scroll partitions, upright holders, framed visual objects and nested cubbies). Nested cubbies can represent real subdirectories, while virtual organization and visual placement remain separate. Scroll partition cells are not filesystem directories.

The latest browser study is Storage Workshop v5.4. It explored connected tiled cells, pre-settled contents, selected-cell manipulation, void-based insertion, drop-from-top, undo, guided displacement and smoothed void contours. It was described as “much better” but remains a prototype and is not a production backend / solver decision.

A sensible staged direction from the handoff is:

1. Freeze / review the physical contracts and file-object fixture metadata.
2. Prove deterministic cell geometry / physics invariants with synthetic fixtures and tests.
3. Prototype native QML `ScrollEnd` / cubby fixtures using existing Book / Shelf assets.
4. Implement persistent Map Room / container hierarchy and Browse / Arrange behavior.
5. Add explicit-root file indexing, Index Open / Locate, state reconciliation and safe file actions.
6. Add optional discovery polish after core navigation is reliable.

This is a suggested dependency order, not a fixed batch-number promise. The earlier proposed Batch 12–15 breakdown is historical planning, not a committed schedule.

## Other future desktop work

Tray, notifications, clipboard / screenshot integration, session / lock controls, multi-monitor checks, accessibility, performance, reproducible setup and distribution may be considered after the current shell has passed native validation. Boot/login personalization is optional and must not compromise the KDE / TTY recovery route.

## Non-goals

- Do not replace Hyprland's compositor / tiling responsibilities.
- Do not merge Veranda wallpaper selection with Gallery artwork.
- Do not treat browser prototypes as shipped QML.
- Do not silently mutate filesystem contents when changing visual placement.
- Do not publish private images, fonts, wallpapers, Gallery artwork or user paths without an explicit asset / privacy review.

## Patch 12 + Batch 13 combined review (unmerged)

Patch 12 implementation fixes and the Batch 13 portable documentation are proposed together in a review pull request. `.gitattributes` is included, but historical line-ending renormalization is intentionally deferred. Offline checks must be confirmed against the branch's GitHub Actions run; native Fedora/Hyprland validation remains outstanding.

## November 23 browser research addendum

The preceding Batch 13 roadmap is historical. Browser studies through B6r12a are merged; B6r12b is the Session 2 review candidate for rack-native physics and explicit in-place reflow. See the [study index](research/prototypes/2026-11-20/README.md) and [B7 proposed gate](development/B7_ENTRY_CRITERIA_AND_TEST_MATRIX.md). The dependency order remains: prove identity, physical placement and reversible transactions in research before native Archive implementation. This does not authorize a filesystem backend, unrelated object families or a compositor change.

## November 24 native-first sequence (owner-approved start)

B6r12b3 is the accepted browser behavior reference for the next native step; its full CI run 45392280473 passed. Begin B6-N1 with reusable geometry, physical solver, placement identity, explicit split plans and atomic transactions, plus isolated QML model and Qt WorkerScript. Next N2 visual components, N3 native interaction parity, N4 target validation. Only then B7 adds the other file-object families. No real filesystem actions, production shell wiring, or new object families in N1. Native desktop validation remains outstanding. See [environment](development/ENVIRONMENT.md). Keep historical browser gate and run relevant scenarios on native code; separate pure logic, offscreen Qt and target desktop evidence.

## Historical B6-N2 checkpoint

N1 Qt/Node passed (run 45394196420); N2 visual candidate is added to draft PR #8. The next dependency is N3 input and active-cell scheduling parity, then N4 real target validation and B7 other object families. Retain the browser reference and the existing shell. Native desktop validation remains outstanding.

## Historical B6-N3 interactive comparison
N3 candidate is on PR #8. Actual Qt pointer tests and direct browser/native numerical comparison are necessary, but not sufficient for native target acceptance. Capture matched real renders and record gaps; retain N4 and the historical stress matrix as prerequisites for B7.

## November 24 — B7 parallel research clarification

Owner authorized standalone visual studies of other file representations before B6 target validation, starting with framed artwork. This is a research-only track, not removal of the B6 native/stress acceptance gate for production integration. See [B7 study index](research/prototypes/2026-11-24/README.md).

## Historical B6-N3r1 continuation

PR #10 merged. PR #11 starts native editor/persistence parity with structural transactions and a versioned synthetic checkpoint codec/controller. Continue on one branch; durable storage and editor UI remain next. See current state and active work. B7-C extraction is integrated but no new native representation renderer exists; target validation remains required.
