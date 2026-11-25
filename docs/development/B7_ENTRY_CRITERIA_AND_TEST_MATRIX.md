# B7 study entry gate — preserved proposal with B6r3 status

**Origin:** November 20 draft gate for B6r repair, subsequently informed by the separately supplied B6r3 notes. **This is a proposed evaluation matrix, not a claim that B6r3 passed every entry.** Browser checks cannot certify native QML/Wayland work.

## Core blocking invariants

- [ ] Empty / zero / negative / NaN / Infinity radius, invalid dimensions and enormous lattices are rejected before geometry without freezing the browser.
- [ ] Preview rack frame, exact cells, paint, labels and scrolls remain one coupled ghost at zoom 0.75/1/1.5/2, with honest valid/invalid/search/consent state.
- [ ] Every cell and scroll identity is unique; no duplicated/lost scroll on resize, split, transfer or holder return; split ancestry remains explicit.
- [ ] Preview, Cancel and Undo restore the exact prior state including allocator, paint, holder, positions and journal; accepted Apply is latest-proposal-only and atomic.
- [ ] Populated group matching respects layout and adjacency, avoids unnecessary travel, settles under actual cell gravity and requires **explicit consent to split**; never claims finite search proves impossibility.
- [ ] Impossible crowded shrink refuses without mutation; painted empty cells and provenance preserved where capacity allows.
- [ ] Multi-scroll holder carries at least three distinct items across cells/cubbies; selecting one doesn't consume others; returning to a resized/split source is well defined or visibly refused.
- [ ] Click versus drag threshold and origin rollback; direct cell open; destination stages for P2R, never auto-inserts. Escape and Cancel exact.
- [ ] P2R connected void hover/click-lock, Shift-click attempts, wall-aware insertion, distinct top drop, live pushing and valid settled Save.
- [ ] Browse/Build/Back and provisional placement remain usable; bookmarks, compact tooltips, role themes and painted walls do not regress.
- [ ] Responsive editor at 1366×768 and 1024×600, including reflow approval controls, without inaccessible stage or panel.

## Targeted scenario matrix (proposal)

| ID | Scenario |
|---|---|
| F-01–03 | Partial/zero radius inputs; 20 rapid edits; ghost attachment under zoom |
| G-01–07 | Radius chain 64→56→48→38→64; 38-scroll Code sample; impossible 180×160 shrink; clipped cells; multiple split descendants; deep-equal cancel; stale worker results |
| P-01–08 | Return to origin; cross-cell staged transfer; 3 held scrolls; holder origin after shrink; inspector save/undo; impossible insertion; locked void; Shift-click and top drop |
| UI-01–03 | Browse/Build/back/breadcrumb; right-click pigment and theme; tooltip/bookmark |
| PERF-01–02 | 100+ cells and dense populations; fixed-step behavior across 30/60/120 Hz |
| R-01–03 | **Added after B6r3:** hand-painted custom racks and arbitrary original groups; repeated radius/dimension chains with cumulative lineage checks; user-preferred split destinations and holder provenance |

**Reported in B6r3 notes, narrow evidence only:** 38 scrolls, 10 groups; radius 38 (7/10 groups intact, three approvals), 42/48/52/56 (9/10, one approval), 60/64/68/72/74/76 (10/10, no approval), Undo back to 64 and 38 scrolls. Playwright/Chromium and Node syntax sampled; 1366×768 and 1024×600 height tests passed. These reports do **not** check the entire matrix.

## B7 scope after passing the gate

Unify the scroll representation/interaction across overview, carried ghost, portable case and active physics cell: same ID, name, radius, metadata, seal, palette, coordinate transform and collision geometry. Prefer one canonical state model and reversible transactions; remove iframe/render divergence when practical. Do **not** add all other file-object families, real filesystem mutations or unrelated ornate controls before the basic scroll behavior is stable.

## November 24 dependency update

B6r12b3 passed the named offline/Chromium checks (run 45392280473), not every historical matrix entry. The owner approved starting the native B6 checkpoint before B7 object expansion. Treat the invariant matrix as a continued acceptance checklist across N1–N4. N1 is synthetic geometry/transaction/worker logic, not a claim of interaction parity. Native desktop validation remains outstanding.

## B7-C checkpoint — gate still open

Owner authorized parallel visual research, merged in PR #9, and asset consolidation PR #10. This does not waive the native/physical stress gate. N1–N3 source is merged and selected named tests have passed; see [comparison](B6_NATIVE_BROWSER_COMPARISON_2026-11-24.md) for bounded evidence. No blanket checkmarks have been added to this historical matrix. N3r1 should fill editor/persistence gaps and record scenario-by-scenario evidence; N4 target performance, scaling, input and recovery remain mandatory before production integration.
