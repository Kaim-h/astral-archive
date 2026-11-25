# Cubby Study B6 → B6r3: historical triage and remaining work

> Historical research record. PR, CI, artifact and commit identifiers refer to earlier development history, not current repository PRs or newly executed checks.

**Date recorded:** November 23, 2026. **Scope:** documents browser research and supplied notes; **no native Quickshell implementation**. This chronology supplements, rather than rewrites, the older November 17 handoff, Batch 13 snapshots and the November 20 proposed ZIP.

## Earlier browser design baseline

The November 20 proposal describes a sequence from Storage Workshop v5.1–v5.12, Cubby A1–A6, B1–B6, Scroll Physics P1/P2/P2R and Map Room v3. B5 was the preferred cross-cell interaction baseline; P2R supplied the more promising void/physical insertion behavior. The design model includes nested independent cubbies, an exact shared hex lattice, movable painted cell walls, cross-cell scroll transfer and a portable holder. Browser studies use synthetic scrolls/files, not a real filesystem backend.

## Original B6: blocking regressions, preserved for diagnosis

The November 20 ZIP's regression plan identifies:
1. **P0 unbounded radius-zero lattice**: `latticeForBox(box,r)` can loop indefinitely if an empty radius input becomes zero before validation in `b6Reflow`. Never run this path unguarded on a valuable browser session.
2. **P0 synchronous reflow** on rapid edits, risking a blocked main thread. Expensive physics/preservation checks must be bounded, cancelled or moved off the interaction loop.
3. **P0 detached ghost / preview**: proposed frame, cells and scrolls must share the same transform and render context.
4. **P0 ID/lineage conflicts** when splits clone a source cell ID into multiple successors; all resulting IDs must remain unique.
5. **P1 preview side effects**: an uncommitted proposal must not advance persistent ID allocation or mutate holder/pigment/Undo.
6. **P1 inconsistent holder provenance and Undo** across transfer, resize and split.

These findings are *historical defects in the original B6 source*, **not a claim that every later variant retains the same issue**. Its old tests are not universal proofs of safety.

## B6r / B6r2

The supplied B6r source is a separate iteration intended to repair B6's resize design. B6r2 subsequently improved the portable scroll case into a collapsible, narrow, unobtrusive control; it condensed frequent sidebar actions and revised layout. However, user screenshots around radius **56, 74 and 52** still exposed large jumps in the location of populated groups, visually separated groups and circles that did not appear to settle under gravity. The editor remained too tall outside fullscreen. The owner also clarified that filled cells must not be automatically split.

## B6r3: claimed repairs and bounded evidence

The separate B6r3 notes describe:
- **Whole-rack minimum-cost matching** of populated cells to successor cells (Hungarian assignment) with neighborhood-preserving costs, starting with nine nearby destination candidates and broadening when needed.
- **Physical settling after every preserved-group mapping**, including cases where a translated packing fits without overlaps, removing the former floating fast path.
- **Per-stable-cell, per-dimensions permission** required for any proposed split. Without consent, the preview has an attention state and Apply is disabled. Only empty adjacent successor cells are valid overflow; preserved groups take priority. Consent can be revoked; resizing dimensions clears it. Split successor identity and wall-paint lineage are preserved.
- **Global location matching for unpopulated painted cells**, with physical successor count constraints.
- **Viewport-height editor** (scrolling sidebar and panel), not a page with a forced 650 px main stage at desktop sizes.
- Earlier cross-cell scroll/holder interaction code retained; no new file-object family or native QML work.

**Tests reported by the B6r3 notes** (not independently rerun by this documentation commit):

| Radius in Code sample | Preserved whole populated groups | Approval required before Apply |
|---|---:|---|
| 38 | 7/10 | 3 groups |
| 42, 48, 52, 56 | 9/10 | 1 group of 12 scrolls |
| 60, 64, 68, 72, 74, 76 | 10/10 | None |

The tested Code sample had **38 scrolls in 10 populated cells**. For radius 56 and 52, one approved split produced two adjacent successors for the 12-scroll group; at 38, three approvals enabled a plan. The notes say every tested Apply preserved 38 unique scroll IDs, and Undo restored radius 64 and the 38 scrolls. Revocation and inherited custom purple wall paint were checked. In selected second-pass settles, maximum observed movement was about **0.48 units at 74**, **0.02 at 56**, and **1.00 at 52**; maximum observed overlap was about **0.004 units**. These are observed samples, **not a proof of convergence or optimality**. The 1366×768 and 1024×600 tests reported document height equal to viewport, and no recorded Chromium page errors. Node script syntax checks passed.

## Remaining questions before B7

- User can authorize a split but cannot yet pick exact successor hexes or manually place successor groups.
- Planner is a finite bounded heuristic; search exhaustion is not mathematical impossibility. A worker watchdog limits running work; it does not prove global optimality.
- Stable cell metadata still lives in a relatively simple `cellMeta`; production lineage, ownership, migration and repeated-resize conflicts remain unmodeled.
- Stress cases remain: custom painted/arranged racks, tightly occupied and clipped cells, repeated resize chains, holder return following split, and custom user-created rack layouts.
- Narrow-screen resize status popover can still overlap part of the stage; an optional dockable/compact panel needs review.
- No persisted real filesystem representation, canonical cross-view file model, indexed metadata, native Quickshell renderer or portable test suite is demonstrated.

**Recommended next review:** reproduce B6r3 with custom wall paint, hand-arranged scrolls, repeated radius/dimension changes, holder provenance across a split, and explicit choice of split destinations before promoting its rules to native implementation. Consult [B7 entry matrix](B7_ENTRY_CRITERIA_AND_TEST_MATRIX.md). This document is research continuity, **not a declaration that the matrix passed**.

**Raw source:** [B6r3 study](../research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r3.html) · [verbatim B6r3 notes](../research/prototypes/2026-11-20/notes/Astral_Archive_Cubby_Study_B6r3_Notes.md). Earlier B6r and B6r2 variants remain in the same folder.

## Later continuation: B6r12a and B6r12b

B6r12a was merged into main in PR #5 (including the stacked PR #6). Both jobs in run 45306855919 (historical `actions/runs/45306855919`) completed successfully. B6r12b is the subsequent **review candidate**, with a rack-native live transaction and in-place explicit split planner. Consult the [version index](../research/prototypes/2026-11-20/README.md) and [Session 2 notes](../research/prototypes/2026-11-20/notes/Astral_Archive_Cubby_Study_B6r12b_Notes.md); older reported B6r3 limitations above are historical and not a complete description of the latest source. No B7 or native acceptance is implied.
