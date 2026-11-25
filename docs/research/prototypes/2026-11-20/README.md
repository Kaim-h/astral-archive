# November 20–23, 2026 — Cubby / rack browser research

**Archive status:** standalone HTML, SVG and JavaScript studies, **not** Quickshell/QML application features. These do not establish native desktop behavior. Older material is preserved by date and version, not silently overwritten.

## Source and version sequence

The supplied November 20 proposal ZIP (SHA-256 `c71c267a2d8d07af4158d362b9dd62b09388574b94d9fd8555f52da0278db48b`) was recovered and rehashed on November 25; all 63 overlay checksums match. [Exact source audit and import inventory](ZIP_SOURCE_INVENTORY.md) identifies five already tracked byte-identical Storage Workshop sources, 25 missing HTML studies and four missing original notes at the audited main revision. The archive itself is not distributed; the audit alone does not establish import of missing sources. Seven diagnostic previews and obsolete doc replacements remain excluded.

The proposed older study sequence:
- Storage Workshop `v5.1`–`v5.12` (12 files): furniture / tessellation, contact and object-representation explorations, including the v5.4 reference already archived in November 17 materials.
- Cubby Study `A1`–`A6` (6 files): nested storage, geometry, inherited colors, independent child footprint/interior and camera scale.
- Cubby Study `B1`, `B2`, `B3`, `B3 Bookmark Revision`, `B4`, `B4r`, `B5`, `B6` (8 files): object/tooltips, attachment, transactional placement, per-cell live physics, cross-cell transfer and rack reflow.
- Scroll Physics `P1`, `P2`, `P2R` (3 files): increasingly refined live-circle, void and drop interactions.
- Map Room `v3` (1 file): spatial layout experimentation.
- B4, B4r, B6 and rack/holder notes are listed in the exact source inventory; seven diagnostic PNGs remain external.

**Important historical distinction:** B5 (SHA-256 `041ceabfb7edcfa6e1dd3d8cbcbb680cb18cebcac7278f9c0c0481e8512995c7`) is the positively reviewed cross-cell interaction baseline. Original B6 (SHA-256 `33a173c6f118c36b7c90d73c28e80c3fbefac6c9a77b4190ebc2e9ddc45d0841`) was observed to have dangerous reflow defects; do **not** assume it safe to open and resize without isolation. Later B6r iterations are separate preserved copies, not edits to B6.

## Later, independently supplied source files now on this branch

| Version | Source | Recorded direction |
|---|---|---|
| B6r | [HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r.html) | First repair iteration after original B6: bounded geometry, revised attached resize planning; warrants regression verification |
| B6r2 | [HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r2.html) | Compact collapsible scroll case, reorganized sidebar and stage; radius changes still visibly relocated groups and left apparent floating scroll arrangements |
| **B6r3** | [HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r3.html) | Global intact-cell assignment, post-resize physical settling, explicit per-cell split permission, improved responsive editor |
| B6r3 notes | [Original notes](notes/Astral_Archive_Cubby_Study_B6r3_Notes.md) | User-reported regressions, implementation explanation, exact browser checks, limitations and next test cases |
| **B6r4 (experimental)** | [HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r4.html) | Owner-feedback iteration: tray-to-case handoff, movable slimmer rack preview and provisional cell recess control; browser behavior still needs manual testing |
| B6r4 notes | [Change log and manual test matrix](notes/Astral_Archive_Cubby_Study_B6r4_Notes.md) | Explains what changes, how Save/Cancel should work and what has not yet been verified |
| **B6r5 (experimental)** | [Standalone HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r5.html) | Drag to distinct multi-scroll active shelf or portable case, then Save both inventories and the source cell together |
| B6r5 notes | [Owner decision, design and acceptance matrix](notes/Astral_Archive_Cubby_Study_B6r5_Notes.md) | Explains the shelf distinction, recovery rules and remaining runtime tests |
| **B6r6 (experimental)** | [Standalone HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r6.html) | Original cradle artwork for both active shelf and portable case; duplicate P2R tray hidden; portable case independently collapsible |
| B6r6 notes | [Artwork provenance, tests and branch policy](notes/Astral_Archive_Cubby_Study_B6r6_Notes.md) | Owner-confirmed shelf art, drag/drop verification, one running dev branch and remaining limits |
| **B6r7 (experimental)** | [Standalone HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r7.html) | One shared Scroll Case clipboard, four visible cradle slots, full scroll-paper shipping manifest, group cut/paste via Ctrl/Shift-click and Ctrl+X/Ctrl+V |
| B6r7 notes | [Clipboard design, test scope and restrictions](notes/Astral_Archive_Cubby_Study_B6r7_Notes.md) | Explicitly distinguishes the internal simulated clipboard from real filesystem operations and deferred stacking physics |
| **B6r8 (experimental)** | [Standalone HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r8.html) | Proximity-only case, visible dragged-scroll overlay, working × close controls, subtler Scroll Register and restored rack-wide drag |
| B6r8 notes | [UI correction and rack transfer acceptance](notes/Astral_Archive_Cubby_Study_B6r8_Notes.md) | Explains specific B6r7 regressions, browser checks, known limitations and single-branch policy |
| **B6r9 (experimental)** | [Standalone HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r9.html) | Zero-shift unchanged reflow, minimum-displacement assignment, explicit cell-and-lattice movement review, topmost rack scroll ghost over case |
| B6r9 notes | [Position review and drag-layer details](notes/Astral_Archive_Cubby_Study_B6r9_Notes.md) | Explains 75→75 no-op, 57-and-below sensitivity, explicit approval controls and test limitations |
| **B6r10 (experimental)** | [Standalone HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r10.html) | Retain each valid lattice address first, then choose destinations for unavoidable moves/splits; restore incoming P2R insertion, case drag-out and clear cell focus |
| B6r10 notes | [Identity-first resizing and case return workflow](notes/Astral_Archive_Cubby_Study_B6r10_Notes.md) | Documents the planner, review policy, source/ID protections, browser test scope and next manual checks |
| **B6r11 (experimental)** | [Standalone HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r11.html) | Explicit split destination with original home retained, confirm case-to-cell Save, soft radius-60 usability warning, and shape-ready rack metadata |
| B6r11 notes | [Placement and geometry contracts](notes/Astral_Archive_Cubby_Study_B6r11_Notes.md) | Details case insertion safeguards, anchored overflow handling, future polygon adapters, browser-local checkpoint and remaining test gates |
| **B6r12a (Session 1 checkpoint)** | [Standalone HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r12a.html) | Direct main-rack scroll dragging, one-owner atomic commits, case roundtrip and Undo without entering a focused editor; **not yet full live physics or in-place reflow** |
| B6r12a notes | [Foundation, validation and Session 2 plan](notes/Astral_Archive_Cubby_Study_B6r12a_Notes.md) | Exact implemented boundary, test coverage, and remaining physics/resize/split/editor retirement requirements |
| **B6r12b (Session 2 review candidate)** | [Standalone HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r12b.html) | Live rack-native provisional contact simulation; connected void/top insertion; in-place identity-first resizing and user-selected overflow; review and CI required |
| B6r12b notes | [Session 2 scope and tests](notes/Astral_Archive_Cubby_Study_B6r12b_Notes.md) | Implementation boundaries, manual review, and test coverage targets |
| **B6r12b1 (owner-feedback correction)** | [Standalone HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r12b1.html) | Unified provisional case/rack projection, compact resolution panel and pointer wake corrections |
| B6r12b1 notes | [Reproduction and validation](notes/Astral_Archive_Cubby_Study_B6r12b1_Notes.md) | Targeted follow-up to Session 2; review actual CI and owner feedback |
| **B6r12b2 (owner-feedback revision)** | [Standalone HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r12b2.html) | Actual dock bounds, below-60 warning, icon-only scroll destinations, atomic grouped dragging |
| B6r12b2 notes | [Revision and verification](notes/Astral_Archive_Cubby_Study_B6r12b2_Notes.md) | Regression follow-up; owner acceptance remains separate |
| **B6r12b3 (resize continuity)** | [Standalone HTML](cubby-studies/Astral_Archive_Cubby_Study_B6r12b3.html) | Immediate draft geometry, asynchronous packing, last drawable shape on invalid input |
| B6r12b3 notes | [Revision and proposed native checkpoint](notes/Astral_Archive_Cubby_Study_B6r12b3_Notes.md) | Browser candidate; proposed QML-first B7 dependency order |

Preserved originals for B6r/B6r2/B6r3 and B6r3 notes are byte-for-byte from the individually supplied attachments; no CSS or behavior was changed here.

## Status is not monotonic

- **November 20 original B6:** documented reflow blocking bugs: radius-zero infinite-loop class, expensive synchronous planner, detached ghost, duplicate split IDs, preview identity mutation and holder/Undo integrity risks. Older sampled successes do not cancel these defects.
- **B6r:** repair direction, not a final sign-off.
- **B6r2:** improved presentation of a portable holder; still experienced unwanted grouping jumps, unsupportable floating positions after changing radii (notably 56, 74 and 52), and excessive editor height.
- **B6r3:** its notes report representative Chromium/Playwright tests passing, but user review, dense edge-case coverage, persisted lineage and native integration remain open. Do not call all B7 gates passed based only on the samples.

The historical November 17 files under [handoffs](../../handoffs/2026-11-17/) remain separate and unchanged. A later accepted explicit design decision takes priority over contradictory notes, but historical files remain useful evidence.

## Read next

- [B6 research chronology and unresolved validation](../../../development/B6_RESEARCH_STATUS_2026-11-23.md)
- [Rack identity and reflow design requirements](../../../product/RACK_REFLOW_AND_CELL_IDENTITY.md)
- [B7 draft test gate](../../../development/B7_ENTRY_CRITERIA_AND_TEST_MATRIX.md)
- [Current implementation state](../../../development/CURRENT_STATE.md) — QML facts are separate from HTML study results

- [Original ZIP proposal: exact import/reconciliation ledger](ZIP_PROPOSAL_RECONCILIATION.md) — what was copied, adapted, deliberately preserved or not yet imported.
