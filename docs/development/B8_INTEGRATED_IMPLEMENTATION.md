# B8 spatial Archive — integrated implementation and verification

**Status: November 27, 2026.** [PR #19](https://github.com/Kaim-h/astral-archive/pull/19) merged at `6c8c90733b43d24ce66aea3eba4c330c48644ad8`, tree `d2892863e10867e885721cf553ba38f64fd57dbb`, identical to final reviewed candidate `f9170379bd99b4bb18b2431d9f043ddd37f11036`. [Candidate CI 46071612984](https://github.com/Kaim-h/astral-archive/actions/runs/46071612984) passed all three jobs; the actual CI merge checkout `6b46f301700f9057cf1595ea3810d403a24b68f3` has that same tree. [Post-merge CI 46076867994](https://github.com/Kaim-h/astral-archive/actions/runs/46076867994) passed all three jobs. This is integrated isolated synthetic source, not a released file manager, actual target acceptance or production enablement.

## Source map and implemented contracts

See the [S20 product contract](../product/B8_SPATIAL_ARCHIVE.md) for intended behavior. The [source directory](../../quickshell/archive/) and [test host](../../quickshell/tests/ArchiveNativeN2Study.qml) are authoritative.

| Boundary | Implementation |
|---|---|
| Identity and ownership | ArchiveCore.mjs, ArchiveSpatial.mjs, representation/B7Ownership.mjs: stable Room and architectural Shelf roots, recursive Cubby interiors, one file inventory, separate synthetic app catalogue/placement, universal Case. Cross-container transport uses Case; app unplacement never becomes a file. |
| Support and geometry | ArchiveSpatial.mjs, ArchiveArchitecture.mjs, representation/B7Layout.mjs: actual occupied profile footprints, independent interior dimensions/depth/height, eligible flat tops and board contact, reserved holder cradles, cardinal Shelf orientation. No silent scaling, evacuation or unrelated rearrangement. |
| Transactions | ArchiveCore.mjs, ArchiveModel.qml, ArchivePlanner.mjs: revision-bound validated preview/replay, Apply/Cancel, single bounded chronological snapshot Undo (30 entries), worker coalescing and stale-result guards. Rack reflow/overflow, removal, dependent rearrangement and approved opening loss keep explicit consent. |
| Room and Map | ArchiveDoors.mjs, ArchiveView.mjs, ArchiveRoomProjection.mjs, ArchiveRoomPlan.qml, ArchiveMapRoom.qml, ArchiveMapTerrain.mjs: shared world geometry and inverse, plan/shallow perspective and bounded depth/identity raster, optional map layer, independent empty Room identity, pan/zoom/focus/overview and shared two-sided openings. |
| Appearance and interaction | ArchiveAppearance.mjs, ArchiveScene.qml, ArchiveAppearanceOptions.qml, ArchiveRoomAppearanceOptions.qml, ArchiveContextMenu.qml, ArchiveProfileFront.qml, ArchiveRoomTransition.qml: revision-bound single target/kind session, contextual actions, keyboard alternatives, valid ordinary implicit commits, invalid typed target retention, Escape cancellation, live/flat crest carrier. |
| Persistence and capacity | ArchiveCheckpoint.mjs, ArchiveCapacity.mjs, ArchiveModel.qml and test ArchiveStudyStorage.qml: explicit synthetic Save/Load, validated bounded state/view, separate projection preference, no production storage or filesystem operation. |

Room edits reserve still-valid world doorway intervals before deterministic nearest width-preserving relocation. If openings cannot be retained, exact lost IDs must be approved. This is a bounded greedy procedure, not a globally optimal packing solver. Explicit doorway gestures cannot jump across an obstruction or leave their contiguous clear span; contact merge is atomic and same-pair only. Both shared walls use actual occupied Shelf footprints, including frames. No implicit Shelf displacement. Rectangular Rooms and cardinal edge IDs remain initial scope.

The selected provisional independent profile policy uses a persisted reference-relative frameBasis (24 equivalent at 1400 × 1050), independent of interior b, and absolute Room wall height 1339.2 at reference (crest 1182). Explicit adoption, full validation and exact Undo preserve earlier policies. No camera fit changes stored dimensions. Actual target evidence is required before revising provisional numbers. Navigation preserves the underlying Shelf path and independent Room identity; Map entry uses ordinary non-drag Browse release (not a door-origin press); Arrange gestures and keyboard controls remain distinct. Room–Shelf Method A is initially 500 ms, Map focus/entry 240 ms; reduced motion uses instant settlement. Actual presented pacing is unverified.

## Checkpoint and preference contract

| Format | Meaning |
|---|---|
| v1/v2 | Legacy readers; v2 ordinary nonspatial writer, inherited mixed ownership contract. |
| v3 | Spatial hierarchy using legacy geometry. |
| v4 | Explicit profile-v1 adoption; physical profiles. |
| v5 | Explicit profile-v2 adoption; independent frame basis and Room height. |
| v6 | Conditional envelope for expanded appearance metadata, independent of geometry policy. |

Capacity selects the exact matching format and validates geometry policy independently. v6 is selected by presence of extended metadata, even a stored null/reset or empty extended map object; appearance defaults looking unchanged do not imply downgrade. No silent migration; old readers refuse unsupported newer formats. Undo that removes all extended metadata restores the preceding writer. Representative current-codec v3/4/5 re-encode and v6 roundtrip/Undo tests preserve bytes; this is not exhaustive historical binary interoperability. Optional Map view requires actual adopted physical profiles, not simply a version number. A non-Map host may load and re-save while dropping optional Map view; subsequent opted-in load defaults to Shelf. Checkpoint view contains nested path/cameras, theme, projection and optional layer/selection/focus camera. Interpolation and active gestures are transient, not serialized. Chart appearance and Room-local atlas overrides belong to the committed snapshot and Undo, not camera state.

Global explicit Room projection preference is separate from arrangement and structural Undo (absent defaults to 2D); successful explicit checkpoint load takes precedence, failed load leaves state unchanged, preference-write failure after successful arrangement load warns without rolling back arrangement. No automatic arrangement restore. Separate preference-store restart/precedence across processes remains release evidence, distinct from the v6 checkpoint view restart below.

Family inheritance, local non-propagating palettes, explicit None, independent Shelf profile, separate Shelf glazing default and local Cubby override retained. Expanded appearance includes 76 primary and nine secondary reference glyphs, bounded independent backing fields (max 16, min 60 local units, nonoverlap), material roles, six glazing policies, nine stone floors/eight walls and persistent chart/atlas appearance. Name/family/palette shared with canonical Room; map-only decoration never alters wall geometry. Full geometry validation still applies to profile changes. [N5 record](B8_N5_CUSTOMIZATION.md) and [Designer final disposition](https://github.com/Kaim-h/astral-archive/pull/19#issuecomment-7228310475) retain approved restrained native adaptations, not pixel-identical or exhaustive catalogue acceptance. Bestiary fang, exact book swatches/bookmark motion and later aesthetic/customization refinements remain deferred; no new art assignment.

## Integrated checkpoint records and acceptance

| Stage | Record and outcome |
|---|---|
| N1 | [Foundation](B8_N1_FOUNDATION.md): hierarchy, capacities, flat support, app/door identities, explicit migration, motion isolation. |
| N2 | [Native Shelves](B8_N2_NATIVE_SHELVES.md): furnished Shelf/Cubby, Case, support/app placement, staged geometry. |
| N3 | [Room geometry](B8_N3_ROOM_GEOMETRY.md): physical policies, shared visibility/hit authority, navigation and preference persistence. |
| N4 | [Map Room](B8_N4_MAP_ROOM.md): empty Room, arrangement, shared doors, contour/focus, optional view metadata and Chart isolation. |
| N5 | [Customization](B8_N5_CUSTOMIZATION.md): appearance sessions, v6, implicit safe commit, contextual/door interactions and representative visual acceptance at `436531aac9b04b4a6fd18a0076629b0febd2c3c1`, [CI 46068610863](https://github.com/Kaim-h/astral-archive/actions/runs/46068610863). |
| N6a–d | [Verification ledger](B8_N6_VERIFICATION.md), [final review request](https://github.com/Kaim-h/astral-archive/pull/19#issuecomment-7228707907), [Librarian](https://github.com/Kaim-h/astral-archive/pull/19#issuecomment-7229291965), [Bugfinder](https://github.com/Kaim-h/astral-archive/pull/19#issuecomment-7229314342), [Secretary](https://github.com/Kaim-h/astral-archive/pull/19#issuecomment-7229329377). Automated scope accepted for integration; actual target gate outstanding. |

Final candidate actual Node: 15,105 shared assertions. Native Qt Quick totals 6 synthetic, 6 foundation, 5 illustrated, 10 live, 19 structural/checkpoint, 3+3 legacy restart, 9 B7 support, 12 mixed, 50 Shelf, 3+3 B8 restart (including setup/cleanup where reported), zero failures/skips. [Offline log](https://github.com/Kaim-h/astral-archive/actions/runs/46071612984/job/140749629888), [native log](https://github.com/Kaim-h/astral-archive/actions/runs/46071612984/job/140749629645), [captures](https://github.com/Kaim-h/astral-archive/actions/runs/46071612984/artifacts/15232554437). Separate writer/reader Qt processes use isolated temporary SQLite state; validated v6 view and arrangement restored, Undo cleared, malformed saved selected-door identity refused without changing snapshot/view/history/revision/focus. Test restores known-good bytes before UI re-save; not automatic repair, crash/power-loss, direct overwrite of corrupt row or physical storage fault proof. Projection tested across processes as checkpoint view, not separate preference slot. Three actual pointer hierarchy cycles across themes/two widths, mode-switch functions and exact nonmutation do not establish absence of routing intermittency.

Retain negative evidence: N5 inherited activation/hover failures (46055658913, 46063343784, 46064260685) and unresolved singular cause; layout-only correction insufficient. N6 initial native foundation failed one generic corruption check [46071174405](https://github.com/Kaim-h/astral-archive/actions/runs/46071174405); later suites not reached. Named independent mutations, changed payload and refusal-category assertions pass in final actual Node/Qt. Bugfinder's V8 probes found original/revised corrupt payloads byte-identical pairwise; no demonstrated decoder fix or proven Qt cause. Other earlier failures and diagnoses remain in stage ledgers; connector adapter evidence is distinct from actual CI execution.

## Bounded performance evidence

[Node measurement script](../../scripts/check-b8-n6.mjs) excludes fixture construction, one warm-up plus five synchronous elapsed samples per operation, median/max. No absolute timing gate. Final candidate measurements:

| Populated roots / files | 1 / 20 | 8 / 160 | 24 / 480 |
|---|---:|---:|---:|
| Projected faces | 30 | 152 | 428 |
| Contour segments | 3,506 | 7,427 | 14,748 |
| UTF-8 checkpoint bytes | 9,855 | 74,126 | 222,350 |
| Map median ms | 0.13 | 0.14 | 0.34 |
| Contours median ms | 4.07 | 5.23 | 8.66 |
| Plan median ms | 0.02 | 0.10 | 0.12 |
| Projection median ms | 0.30 | 1.58 | 2.08 |
| Visibility median / max ms | 8.40 / 13.23 | 8.04 / 9.81 | 13.71 / 18.92 |
| Solver median ms | 3.27 | 1.46 | 1.47 |
| Encode median / max ms | 1.43 / 1.69 | 6.72 / 8.01 | 14.93 / 23.22 |
| Decode median / max ms | 1.27 / 1.94 | 6.74 / 9.17 | 14.25 / 16.08 |

Each 1366 × 900 projection raster bounded to 1,199,261 pixels; retained winner/floor arrays 5,996,305 bytes, not process RAM. Same selected rack request, not scaling with per-rack complexity; ready and exact document/history cancellation, revision may advance. Native eight-root Room 990,350 pixels / 152 faces; entry-plus-perspective 304 ms including input/settling, no additional Room paints, hidden Map paints or contour builds in 250 ms observation. These are elapsed CPU-side samples and short paint counters, not presented FPS, sustained utilization, GPU, power or target latency. No speculative optimization mandate.

## Remaining release gate

[Actual target bring-up](../bringup.md) is mandatory before production integration; historical N4 gate is distinct from B8-N4 Map development. Actual Fedora/Hyprland/Quickshell versions, manual isolated launch, import/renderer, accessibility/ergonomics, all themes/contrast, fractional DPR, repeated mixed-button and edge routing, compositor deactivation/cancellation, presented transitions, dense cold/warm render and varied solver/door complexity, sustained idle and CPU/GPU/RAM/power, standalone restart/independent preference precedence and isolated I/O/crash recovery remain unperformed. Test direct Save replacing corrupt row without pre-repair and safely induced permission/disk faults; record untested cases. Preserve recovery path and sanitized technical evidence. No real filesystem indexing/actions, production Archive wiring/autostart, B9/B10, new aesthetics or release authorization follows from merge.
