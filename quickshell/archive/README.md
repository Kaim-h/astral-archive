# Archive native studies

## Integrated baseline and verification status

The preserved technical baseline is historical main `4366c5cae25d949ea7d21c8c595de8132893d6b4` (November 24, 2026). Historical PR #16 (B7-N2) merged at `17fecd7cf3161ecd324645ffb4608541b404d818`; historical PR #15 (independent stable-main fixes) subsequently merged at the baseline. B7-N2 is implemented as an isolated synthetic study, not a production filesystem interface. Its four agreed checkpoints were completed at tested implementation `e04c1e4bbb1b52f32fd91ee22336d23f3f2c1cf7`. Historical CI run 45479039959 passed offline-js, browser-cubby-studies and native-archive-qt for that implementation. Later integration changed independent desktop shell/service source and tests; this is not a claim that the complete migrated tree has passed those checks.

N4 target-environment validation remains mandatory before production integration. Native desktop validation remains outstanding. Real filesystem indexing/actions, production Archive shell wiring, complete Map Room/Shelf architecture and derivative packaging remain later work. Do not infer a validated production Archive from synthetic studies.

The sections below are retained historical checkpoints, not current assignments or live PR state. All old PR, CI, artifact and commit identifiers are historical provenance. This clean baseline has not yet been runtime-tested. Ordinary development must not resume before baseline integration and explicit authorization.


**Historical N3r1 status:** isolated native study complete within agreed N3r1 scope, awaiting owner merge of PR #11. CI 45454859789 (historical `actions/runs/45454859789`) at code checkpoint `4088d8b137ed02cf87339edb991bd526d507e11e` passed all three jobs (offline-js, browser-cubby-studies, native-archive-qt). Native Qt logs: N1 5, N2 5, N3 9, N3r1 19, checkpoint writer 3 and independent reader 3 passed, including setup/cleanup; zero failures. Reader verifies confirmed restoration, Cancel/Escape, missing/corrupt/unsupported refusal, view and arrangement recovery, and reset of Undo. Final actual native capture artifact (historical `actions/runs/45454859789/artifacts/14950475664`) inspected: full “The Main Hall · study cubby” inscription is visible, correctly centered within its plaque, and separated from the collapsed Scroll Case. Browser artifact (historical `actions/runs/45454859789/artifacts/14949817287`).

At this historical N3r1 checkpoint, AUD-02 (depth-only cell customization loss on rack reflow) remained open; it was subsequently fixed in integrated historical PR #13; see advisory comment (historical `pull/11#issuecomment-7139125411`). No solver or reflow correction implied. N4 target-environment validation remains mandatory before production integration. Native desktop validation remains outstanding. Optional sample variants, extra historical stress extensions, other representation families/mixed shelves, room motifs, automatic persistence, Map Room and real filesystem work are outside the completed PR #11 scope.

The following sections retain historical development notes; later milestones supersede earlier limitations. See [active work](../../docs/development/ACTIVE_WORK.md) for the authoritative current handoff.

This isolated research directory is **not imported by shell.qml**. The reference is B6r12b3 (commit f2e78523897d13ef518209eb2f9ef60e1cad12a4; browser CI 45392280473 passed). `ArchiveCore.mjs` contains the same bounded hex geometry, clipped wall math, fixed-step 120 Hz solver, supported/contained checks, packing, explicit split and connected void/top entrance logic as the browser reference, with Qt-compatible JSON copying instead of structuredClone and ordinary indexing instead of Array.at. The native value-model API owns synthetic snapshot, revision-scoped preview, explicit consent, atomic Apply/Cancel/Undo and a bounded synchronous transfer helper for tests. The latter is not a UI live scheduler. N1 deliberately accepts rack-only synthetic fixture models, not imported real directories or general shelf/object models.

`ArchivePlanner.mjs` imports the same core and executes on Qt WorkerScript. `ArchiveModel.qml` is a small isolated QML controller, not the final visual scene. One request is in flight; pending inputs coalesce; older replies cannot publish after a new edit, reset or Cancel. Draft geometry is drawn/available immediately and the planner returns settled positions asynchronously. QML uses value replacement for change notification. There is no worker interruption/watchdog yet (the browser has a watchdog); measure and add production scheduling/failure recovery during N3 before exposing this in the shell. The finite solver can reject a feasible packing. No real disk actions, persistence, Wayland integration or automatic startup.

Checks:
- From repo root: `node scripts/check-archive-n1.mjs` — pure logic.
- With Qt 6 Quick Test installed: `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qmltestrunner -input quickshell/tests/tst_ArchiveNativeN1.qml` (binary path depends on distro).
- CI installs distro Qt on Ubuntu, not Quickshell or Fedora. Native desktop validation remains outstanding; see `docs/development/ENVIRONMENT.md`.

Historical next action: N2 native visuals with one canonical geometry/scroll representation and existing theme roles; N3 input, active-cell scheduling and case/void parity; N4 actual target system validation; B7 other objects. No production integration until the isolated study is validated.

Compatibility follow-up: initial CI (45393876760) exposed Qt 6.4.2's unsupported object spread and an overly greedy pair placement. Use Object.assign and explicit null guards in the shared module; retain the same solver. The group helper tries symmetric centered pair placements before the original compact search. The positive test chooses a complete hex rather than a clipped edge cell. The Qt controller's state property is named archiveState, avoiding Item.state. Check the succeeding run for actual evidence.

## N2 — illustrated native scene (review candidate)

The reference geometry and data are consumed directly by `ArchiveRack.qml` and the event-driven masonry Canvas; scroll ends are separate QML items. `ArchiveCubbyFace.qml` renders the stored child footprint and scaled veiled silhouettes. `ArchiveScene.qml` owns the camera, view-only navigation and Browse/Arrange selection, not file ownership. `ArchiveCase.qml` shares the endpoint component and displays the complete register, including provisional case entries. `ArchiveTooltip.qml` shows actual synthetic record fields, not invented disk metadata. The existing Theme singleton supplies Evening/Twilight/Midnight. `ArchiveNativeN2Study.qml` is an isolated test harness with dimensions, split icon picking, Apply/Cancel/Undo and explicit child entry. No live scroll dragging or pointer resize handles yet; those belong to N3. N2 extends the synthetic model only to nested cubbies, with bounded nonoverlapping footprints, unique parents and cycle checks; the hierarchy and camera do not mutate file placement.

Launch the standalone study with the installed Qt 6 QML viewer (if available): `qml quickshell/tests/ArchiveNativeN2Window.qml`. Qt Quick Test: `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qmltestrunner -input quickshell/tests/tst_ArchiveNativeN2.qml`. Node: `node scripts/check-archive-n2.mjs`. CI Qt on Ubuntu is not target Quickshell/Fedora validation. No screenshots, private art or fonts committed. The small scroll curl/ornament and Case illustration are a first native approximation, not final visual acceptance. Native desktop validation remains outstanding.

## N3 interactive candidate
`ArchiveMotion.mjs` and `ArchiveMotion.qml` isolate a revision-scoped provisional transaction and bounded 120 Hz solver, updating active cells only, with stable membership and independent glyph positions. Mouse capture routes group gestures; the Case uses its actual pill/panel bounds, not the approach halo. Prepared void, Shift-click and top-entry gestures, origin return, Ctrl+X/V, Escape/Undo and native rack handles are wired into the existing isolated N2 study entrypoint. The planner has a revision-aware timeout/recreation path; the bounded solver remains a research approximation and hard interruption of a native worker has not been verified. Selected group budget: up to 96 scrolls and 24 touched cells; refuse larger groups atomically. Real files and native persistence remain intentionally absent. N3 does not yet claim full B6 parity or target hardware performance.
`scripts/check-archive-browser-parity.mjs` reads actual B6r12b3 functions from the historical source and compares geometry, plans, physics and voids on shared fixtures. CI captures real matched Qt and Chromium renders as artifacts, not design mockups. Use actual test outcomes and the comparison report for status.

N3 comparison follow-up: CI 45398055406 passed all three jobs (66 exact geometry comparisons, 19 complete plans, fixed-step/void/top parity, five actual Qt interaction scenarios). Actual matched screenshot inspection found a Case/inscription collision, lower visual sharpness, missing cradle proportions and reduced metadata. Corrected the default camera reserve, restored the four-slot cradle rail and complete register, added explicit close and provisional count, bounded 2x static Canvas drawing, browser-equivalent synthetic metadata, and explicit cell pigment/recess edit with Undo. Updated tests cover default clearance and split controls; inspect the follow-up run before claiming these pass. Actual target DPI/GPU, full editor controls and persistence remain pending.

## B7-C asset consolidation candidate

See [representation asset contract](../../docs/product/REPRESENTATION_ASSETS.md), `representation-assets/manifest.json` and `RepresentationCatalog.mjs`. No runtime import, new QML, solver change or actual file actions. Run the two B7-C Node checks. B6 parity and target verification remain open.

## N3r1 first checkpoint — PR #11

Structural edit candidates share Core's validated ownership-preserving commit/Undo boundary. Preview is an unpublished result; Apply recomputes from a revision-matched command. Deletion refuses occupied racks/subtrees, Case records survive with stale origin flags. Parent footprint and child interior are independent. `ArchiveCheckpoint.mjs` is native-study version 1 JSON serialization/validation, not browser v13 or durable storage yet. `ArchiveModel.qml` exposes proposal/export/import methods for isolated test coverage; future UI must block live motion and reconcile selection/camera. Node `scripts/check-archive-n3r1.mjs`, Qt `quickshell/tests/tst_ArchiveNativeN3r1.qml`; check actual CI. Remaining UI, storage, guide/snap, material roles and preview modes tracked in ACTIVE_WORK. No production shell import or real file access.

## N3r1 shelf and deletion follow-up — owner-directed

Supersedes prior refusal of populated deletion: on Apply, every affected rack scroll moves atomically into the Case with stable ID, metadata and stale origin; Cancel/Undo preserve state. Preview publishes a transfer count, not changed ownership. `ArchiveShelf.qml` renders an empty board with top-edge supportY; scene dispatches separately from rack and cubby. Add/Edit/Remove controls currently use position/width steps with provisional board overlay and explicit confirmation. Empty board dimensions 120 minimum width and 15 height derive from B6r12b3. No populated shelves accepted yet; B7 needs generalized owners/validation and compatible restoration of normal object family from the portable scroll. See product physical fixture contract. Current source does not implement actual storage or production shell integration.

## N3r1 material customization

`ArchiveView.materialRoles` mirrors B6r12b3 Quiet/Balanced/Accented formulas and optional `snapshot.materials` role edits scoped to theme/preset. `appearancePalette` augments rather than changes semantic theme roles; explicit local overrides win. `ArchiveColorRow.qml` offers hex entry, swatch, Apply and Reset in a temporary context-invoked inspector. Existing cell pigments/recess and file seal/parchment roles remain separate. Root/child frame/backing, shelf and rack overrides are atomic Undo edits; checkpoint codec preserves preferences. Future room/Shelf motifs will add inheritance levels; not implemented. Verify actual current CI; no durable storage or target signoff.

### Material session transaction follow-up

Color-only `materialBatch` commands replay against an unpublished snapshot and commit once through Core's validated ownership-preserving boundary. The existing structural proposal lock prevents concurrent rack/motion edits, Undo and checkpoint import/export. The scene reads only appearance from the preview; the committed geometry and record ownership remain authoritative. Reset previews inheritance; Apply commits one Undo entry; Cancel discards; changed previews require explicit resolution. Hex edits are live previews; compact visual picker and further shared inspector work remain next. Check current CI.

### Compact visual color picker

`ArchiveColorPicker.qml` is a QtQuick-only HSV plane/hue strip. Only the chosen swatch expands, exact six-digit RGB remains the snapshot format, and arrow-key controls/hex input complement pointer input. The inspector pins Apply/Cancel outside its scroll body; Reset and Back do not commit. Verify fresh CI and later target appearance. No Qt Controls/Dialogs dependency or room motif implementation.

### Shared temporary inspector foundation

`ArchiveInspectorFrame.qml` bounds the themed panel to its available viewport; `ArchiveInspectorScroll.qml` provides vertical-only clipped content and explicit scroll reset. Rack and material studies share these primitives while preserving their own placement, controls, transaction semantics and scene access. Structural panel/further shared focus behavior remain follow-up work. No new dependencies.

Structural placement/removal now uses the same shared frame and scroll primitives, with pinned transaction controls and explicit cancellation. It retains existing provisional ghost drag/resize, numeric steps and occupied removal semantics. Cubby interior metadata UI is a separate follow-up.

### Cubby interior growth and shrink suggestion

Interior dimensions and name preview independently of parent footprint. Growth leaves fixtures intact. When shrinking would clip furniture, an explicit suggestion may move out-of-bounds whole fixtures to nearest legal positions while leaving in-bounds fixtures fixed. This is a bounded greedy suggestion, not an exhaustive packer. New dimensions require renewed suggestion; Cancel/Undo retain all original metadata. See ACTIVE_WORK for deferred AUD-02 (rack depth-only customization); this feature does not run the rack reflow planner.

### Exterior cubby previews

The B6r12b3 reference modes are native study-wide view choices: Veiled (uniformly fitted subdued fixture rectangles), Inventory (immediate rack/shelf/cubby/item counts), Closed (empty backing/recess). No recursive miniature or file names, no changed hit targets, and no arrangement/Undo entry. The selected nested face's Arrange context exposes the mode choice. Optional `view.cubbyPreviewMode` in checkpoint v1 is validated; absent means use Veiled on future restore. No storage adapter/restore wiring yet. Populated shelf counts require B7 generalized ownership.

### Local grid and fixture drag contract

Rack and provisional structural drags share `Core.fixtureDragPatch`: map pointer motion to cubby-local deltas, snap origin or moving far edge, retain shelf thickness. The rendered grid has the same local origin and interval; camera scale/pan only change screen mapping. New tests exercise real grid controls, shelf move/resize/cancel/apply/undo and rack movement/cancel at multiple scales. No planner or physics change.

Nested fixture tests extend local-grid coverage with deliberate overlap, recovery, constrained viewport and independent interior preservation; invalid rack out-of-bounds move cannot Apply. During structural proposals the study heading is disabled and the ghost gesture is cleared when the proposal closes. Fresh CI required.

### Explicit durable study checkpoints

The standalone `ArchiveNativeN2Window.qml` injects `ArchiveStudyStorage.qml`, using QtQuick.LocalStorage (SQLite) with a dedicated database name and a single validated JSON slot. Install the Qt 6 LocalStorage QML module and SQLite driver in addition to the existing Qt runtime. Save checkpoint explicitly replaces the prior slot in a transaction; Load checkpoint asks for confirmation and restores only a valid complete snapshot/view, clearing Undo and transient interaction state, returning to Browse. No auto-save or auto-load, no paths supplied by users, no file indexing/operations. Grid/snap and preview settings are optional v1 fields. The standard QML engine offline storage path determines the actual database location (application/engine dependent). CI runs separate writer and reader processes in a temporary XDG_DATA_HOME, not the user's storage. Current source awaits verification; target Qt/Quickshell availability and runtime behavior must be checked at N4. AUD-02 is not resolved by serializing depth metadata.

Checkpoint Load confirmation now uses a fixed modal panel (Cancel default focus/Escape, separate anchored Confirm), not changing toolbar Flow contents. Scene and heading input blocked while confirming. Fresh restart CI required.
