# Astral Archive roadmap

## Integrated baseline and verification status

The preserved technical baseline is historical main `4366c5cae25d949ea7d21c8c595de8132893d6b4` (November 24, 2026). Historical PR #16 (B7-N2) merged at `17fecd7cf3161ecd324645ffb4608541b404d818`; historical PR #15 (independent stable-main fixes) subsequently merged at the baseline. B7-N2 is implemented as an isolated synthetic study, not a production filesystem interface. Its four agreed checkpoints were completed at tested implementation `e04c1e4bbb1b52f32fd91ee22336d23f3f2c1cf7`. Historical CI run 45479039959 passed offline-js, browser-cubby-studies and native-archive-qt for that implementation. Later integration changed independent desktop shell/service source and tests; this is not a claim that the complete migrated tree has passed those checks.

N4 target-environment validation remains mandatory before production integration. Native desktop validation remains outstanding. Real filesystem indexing/actions, production Archive shell wiring, complete Map Room/Shelf architecture and derivative packaging remain later work. Do not infer a validated production Archive from synthetic studies.

The sections below are retained historical checkpoints, not current assignments or live PR state. All old PR, CI, artifact and commit identifiers are historical provenance. This clean baseline has not yet been runtime-tested. Ordinary development must not resume before baseline integration and explicit authorization.



This is a dependency roadmap, not a promise that every planned component is implemented or scheduled. The current native application and future file Archive are distinct scopes. Consult `docs/development/CURRENT_STATE.md` for the commit-specific implementation / verification snapshot and `docs/product/` for approved product behavior.

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

## B6-N2 checkpoint

N1 Qt/Node passed (run 45394196420); N2 visual candidate is added to draft PR #8. The next dependency is N3 input and active-cell scheduling parity, then N4 real target validation and B7 other object families. Retain the browser reference and the existing shell. Native desktop validation remains outstanding.

## B6-N3 interactive comparison
N3 candidate is on PR #8. Actual Qt pointer tests and direct browser/native numerical comparison are necessary, but not sufficient for native target acceptance. Capture matched real renders and record gaps; retain N4 and the historical stress matrix as prerequisites for B7.

## November 24 — B7 parallel research clarification

Owner authorized standalone visual studies of other file representations before B6 target validation, starting with framed artwork. This is a research-only track, not removal of the B6 native/stress acceptance gate for production integration. See [B7 study index](research/prototypes/2026-11-24/README.md).

## B6-N3r1 continuation

PR #10 merged. PR #11 starts native editor/persistence parity with structural transactions and a versioned synthetic checkpoint codec/controller. Continue on one branch; durable storage and editor UI remain next. See current state and active work. B7-C extraction is integrated but no new native representation renderer exists; target validation remains required.
