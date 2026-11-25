# Archive inter-development architecture review — 2026-11-24

**Status:** advisory, not an accepted implementation plan. Historical technical source `4366c5cae25d949ea7d21c8c595de8132893d6b4`; original CI 45480799164 succeeded for offline-js, browser-cubby-studies and native-archive-qt. Original revision, run and PR identifiers are historical provenance, not live destination references. Checks not independently rerun for this review, artifacts not inspected, no target performance claim.

## Technical direction and scope

- Documentation-only review; recommendations are not accepted architecture or implementation mandates. Coordinate with separate design, audit and corrective topics.
- Aim for a responsive, efficient desktop shell. Use evidence-led performance work on the target environment; faster compatible languages are an option only for demonstrated bottlenecks or justified capability needs.
- Goal: eventual file-manager replacement if feasible and safe. Retain conventional recovery/file manager while validating. No approval yet of specific filesystem backend, indexing roots, deletion policies or production integration.

## Current architectural organization

PRs #10 (assets), #11 (N3r1), #13 (AUD-01–08), #14 (B7-N1), #16 (B7-N2) and #15 (AUD-09–15) merged. B7-N2 is an isolated synthetic study with mixed shelf/holder/mount/rack owners, universal Case, transactional arrangement and versioned checkpoint. Production shell has no Archive study import; real file operations and production Map Room absent. See [B7-N2 checkpoint](../development/B7_N2_MIXED_CUBBIES.md), [environment](../development/ENVIRONMENT.md) and [current state](../development/CURRENT_STATE.md) for dated evidence.

| Source relative to quickshell/ | Observed responsibility |
|---|---|
| archive/ArchiveCore.mjs:437–623, 681–700, 788–951 | Synthetic snapshot, ownership, geometry, validation, revision-scoped proposals, commit and Undo. |
| archive/ArchiveModel.qml:10–145; ArchivePlanner.mjs | QML publication, coalesced WorkerScript planning, revision guards, timeout/restart. |
| archive/ArchiveMotion.mjs; ArchiveMotion.qml | Provisional live motion, separate membership/positions, idle timer stop, Core commit. |
| archive/ArchiveScene.qml:13–145, 340–378; ArchiveView.mjs | Rendering, camera/navigation, selection, interaction orchestration, lifecycle reconciliation. |
| archive/representation/B7Ownership.mjs:1–130; B7Layout.mjs; RepresentationCatalog.mjs | Mixed ownership, appearance, conservative occupied geometry, asset policy. |
| archive/ArchiveCapacity.mjs; ArchiveCheckpoint.mjs | Shared capacity preflight and v1/v2 synthetic codec. |
| tests/ArchiveB7MixedWindow.qml; ArchiveStudyStorage.qml | Separate Qt study, explicit synchronous single-slot SQLite checkpoint, no automatic startup restore. |
| shell.qml | Production shell, not importing isolated study. |

These boundaries are useful. No wholesale rewrite or split based only on file size; no parallel inventory or duplicated scene for each higher level without justification. Generic offscreen Qt is not target Quickshell/Hyprland verification.

## Recommendations (not accepted decisions)

### A — Critical before real filesystem integration: identity and operation boundaries

Core.owners enumerates each physical record in rack, Case, shelf, holder or mount; Core.commit (586–590) validates and requires the same sorted ID set; Undo (607–611) restores a previous snapshot. B7Ownership.preferred/currentAppearance separates preferred art from portable Case/rack form. These are sound arrangement invariants but cannot directly represent file creation, deletion, duplication or external changes.

Keep same-ID layout commits. Add a separately reviewed inventory reconciliation/operation boundary for deliberate membership changes. Distinguish stable logical file identity, observed filesystem reference (path and filesystem-dependent evidence), container/fixture/placement identity and visual representation. Paths change or get replaced; inode-like identifiers can be reused and are not globally unique. Define hard-link, symlink, copy, mount-loss and stale-reference policy; never silently bind a placement to a different file.

Proposed sequence: synthetic operation contract and deterministic failures → explicit-root read-only metadata indexing, Open/Locate, missing/offline state → explicit file operations in temporary test roots → recovery, crash and Undo tests → target validation and gradual adoption. Layout Undo and filesystem Undo must be separate: an old layout snapshot cannot reverse disk writes safely. File operations need source/destination revalidation, collision and permission handling, partial-failure reporting, cancellation/restart, and recoverable trash when supported. No implicit disk action from Arrange, fixture removal or Case transport. Keep Dolphin or another recovery path until safe; never test destructive operations on personal files.

Alternatives: read-only spatial layer using OS services (lowest risk, incomplete manager), mature file-operation adapter/library (evaluate capabilities and licensing), custom native service (higher complexity, only for capability gaps). No schema/backend selected. Cost: multi-checkpoint milestone, not a B8 prerequisite. Tests: temporary roots, rename/replace, hard links/symlinks, duplicate names, cross-device moves, permission failure, mount loss, interrupted operations, stale Locate and separate layout Undo.

### B — Near-term before native B8: hierarchy and physical support

Core.validate and Capacity.pathValid currently model one root and nested cubbies. The B8 workshop at historical checkpoint `531b0f2` (original design PR #18) records accepted general direction: Shelf is higher-order recursive cubby with mixed fixtures and usable module tops, not exclusively a cubby holder; support eligibility and room/map details remain open, S2 visual approval pending. Preserve accepted cubby visuals, Browse/Arrange semantics and parent footprint/interior independence.

Reuse cubby geometry/ownership/transaction contracts where appropriate. Distinguish higher navigation, physical containment/support and actual filesystem containment. Do not copy Core/Scene wholesale or create a second owner list. Before module-top support, model eligible support datum, dependent placement, contact, clearance, no cycles, move/resize/removal and explicit consent/Undo. Core.rackBounds and B7Ownership.fixtureRects currently use conservative occupied rectangles; distinguish intentional support contact from forbidden overlap. Evaluate extending existing fixtures vs a small shared support policy. No general stacking physics or nonrectangular geometry required. Keep ornament outside usable envelope. Cost: focused contract review and synthetic tests before dependent B8 implementation. Verify same IDs, contact, support movement/removal, incompatible placement, exact Cancel/Undo, expansion and nested navigation/Locate. Recheck after accepted design merges.

### C — Near-term before production persistence: bound layout and separate durable records

Capacity limits: 128 cubbies, 64 modules/cubby, 12,000 cells, 4,096 records, 2,000,000 snapshot string characters; Core.commit retains up to 30 previous snapshots. Codec stores complete JSON snapshot plus view; test adapter writes one synchronous SQLite slot. These are reasonable study guards, not production catalog requirements. Do not merely increase caps or put the entire filesystem in one QML property. Consider bounded active spatial layout and separate indexed metadata, stable lookup interfaces, distinct durable layout and operation log lifecycles. Preserve v1/v2 compatibility or explicit migration/refusal. No automatic production persistence approved. Alternatives: bounded workspace snapshots initially, or transactional incremental persistence as needed. Cost: design/roundtrip fixtures before production persistence. Validate commit/save budget agreement, restart, corrupt/unsupported schema, no silent partial replacement and recovery.

### D — Investigative after hardware availability: measure before optimization

Hypotheses only: whole JSON copies and same-ID sorting, repeated ownership enumeration in Core.transfer, repeated geometry validation, delegate/binding invalidation and synchronous checkpoint I/O. Existing worker coalescing, revision guards, timeout, active-only physics, capacity guards and separate view policy are strengths. Measure idle/hidden/open CPU and memory, frame latency, planner duration, startup, checkpoint latency, larger supported fixtures, battery/thermal behavior on recorded hardware/runtime/workloads. Optimize measured causes (index/cache invalidation, scoped deltas, workers) first. C++/Rust only for demonstrated bottleneck/capability need and stable testable interface. No benchmark threshold or migration approved.

## Lessons from prior regressions (not a competing audit)

The continuing audit ledger remains authoritative audit history (historical PR #12). AUD-01–15 source fixes are integrated through historical PRs #13, #15 and #16; AUD-16–20 remain a separate corrective topic (historical PR #17). Lessons derive from historical audit evidence and main source, not new reproductions.

- AUD-02: empty cell customization includes depth as well as pigment. Preserve identity/metadata and consent even without contents; test each independent field during reflow.
- AUD-09: a committed layout exceeded checkpoint budget. Share capacity contract across commit and codec; test below/above boundaries.
- AUD-14: cubby ID reuse after Undo could inherit obsolete camera state. View caches must follow identity lifecycle and reset/Undo; reused ID alone is not proof of same entity.
- AUD-17/19: provisional ownership display and support reservation must agree with actual intermediate rendering and geometry, not only final state. Assert live membership and occupied visual extents. Separate corrective work remains unverified at its latest correction.
- AUD-18/20: ID strings can collide with inherited object properties; own-key lookup or suitable dictionaries at all ID-keyed boundaries, including view/adapters. Test adversarial valid IDs. Preserve the separate corrective topic.
- AUD-16: external service fixtures must match upstream field order/contract. Mocked green tests alone do not establish integration.
- Keep static, logic, browser, offscreen Qt, target and visual/performance evidence separate. No new runtime fixes here.

## Documentation hygiene and coordination

The historical source review identified stale README and current-state/active-work/roadmap claims and a component map predating mixed rendering. The integrated migration baseline has since reconciled those status summaries; preserve historical evidence, not obsolete next actions. Follow-up proposal after active merges: compact current snapshot with exact head/CI; one focused active handoff; historical checkpoints linked rather than duplicated, prominent superseded labels, selective retrieval. Coordinate status with topic authors and verify post-merge main. Not a parallel state ledger.

Keep the audit, corrective and design topics distinct. Reapply only missing technical improvements to the current README and component map; preserve newer technical baseline wording and independent audit index changes. Recheck actual changed-path overlap before integration. Use existing decision records after acceptance; proposals here are not binding.

## Contributor guidance for subsequent authorized work

Continue design/native work only within authorized scope; no wholesale rewrite. Before native B8, confirm hierarchy/support contracts with accepted design; keep Core's ownership/transaction boundary and test dependent support. Before real file operations, propose identity/reconciliation and separate layout/filesystem Undo for owner review. Do not globally relax same-ID commits, conflate Case with OS cut/delete, or commit private paths in fixtures. Preserve capacity/codec agreement, revision/lifecycle guards and target N4 gate. No production integration/autostart or performance claims before actual validation. Revisit after relevant accepted design and implementation changes.
