# Astral Archive — Cubby Study B6r10

**Status:** Browser-only synthetic-file research on the existing cubby development branch. B6r9 stays preserved; no native QML/Quickshell or B7 acceptance is asserted.

## Why this iteration

Owner feedback: B6r9's red relocation flags were too broad. In the supplied screenshot, only the lower-right collection visibly changed its *relative arrangement*. The rest of the hex lattice simply contracted/expanded. Other regressions: loss of the Storage Workshop insertion tray when moving between rack cells, inability to drag stored scrolls out of the centered case onto an overview hex, and a highlighted cell remaining selected after its editor closed.

## Identity-first reflow

The reflow planner now locks every populated cell that can fit in its **same lattice address (row, column)** before considering any global matching. A small radius change may change a cell's physical center, but this is expected deformation, not a relocation. Any explicit owner-selected destination is reserved first. Only groups whose original address is absent or physically too small enter minimum-distance global matching. The previous adjacency optimizer remains removed.

Consequently, a red warning is generated for a **changed cell address**, not a mere change of center coordinates. A second topology warning is limited to **altered adjacency relationships among populated groups**, not a normal appearance/disappearance of clipped *empty* edge hexes. Unchanged width, height and radius still form an exact no-op.

For each actual intact move, the adjustment panel presents a **destination selector** listing the original/automatic and nearby whole-cell candidates. For a group that cannot fit, the panel also offers a target choice and, once split permission is granted, a **split-anchor selector** indicating the preferred location of the connected successor cluster. These are *requests*, not forced unsafe placements: physics packing, occupancy, group identity and uniqueness are revalidated before Apply. Incompatible choices produce a visible blocked issue rather than moving or deleting records. User choices and approvals reset as appropriate when the proposal changes.

## Restored insertion and case drag-out

The P2R base physics simulator already prepared an incoming cross-cell scroll in its holding tray and a mark-void insertion. B6r7's load handler incorrectly cleared the held/insertion state and diverted incoming scrolls into the case. B6r10 preserves the original P2R insertion flow for rack→rack and case→rack transfers. The user may insert via a selected void or Drop from top. Save remains blocked while the carried item is still held.

The focused case can still drag a scroll directly into a cell; a single dragged scroll now begins a live physics insertion rather than always teleporting to a precomputed location. Group paste retains the provisional safe-position placement workflow.

The outer Scroll Case cradle and its Scroll Register rows can initiate a drag. Dragging onto an overview rack hex opens the cell editor with the chosen scroll in P2R's prepared insertion tray. **Cancel keeps it in the case**, and **Save transfers it exactly once** only after insertion. The dragged case scroll has a pointer-events-none top-level ghost.

Closing the focused editor clears the selected cell key and scroll selection, preventing the highlight remaining when returning to the rack.

## Tests and limits

- Source checker: `scripts/check-b6r10.js` parses the outer HTML, original embedded P2R code and updated physics patch. Verifies stable assignment, user choices, case drag-out, clear focus and restored insertion markers.
- Browser regression: `scripts/smoke-b6r10.js` covers exact no-op, pure planner, ignoring trivial lattice movement in review flags, per-move selectors, moving a case scroll to an overview cell, the prepared P2R held/void insertion, and Cancel preserving the case item and clearing the highlight. Earlier browser and offline tests stay in CI.
- Further manual testing: 75→76, 76→75, 57→56, 56→57, a truly overfull cell requiring splits, user destination conflicts and constrained split locations; plus dense-scroll solver performance, thin/clipped edge cells and touch.
- This study does **not** access real OS clipboard or filesystem files, and is not a production Archive implementation.

## Branch/PR policy

Continue future prototypes on the single branch `research/cubby-study-b6r5-2026-11-23` and update **PR #6**, keeping versioned files. PR #6 remains stacked on the unmerged B6r4 PR #5 review branch. No merge into `main`.
