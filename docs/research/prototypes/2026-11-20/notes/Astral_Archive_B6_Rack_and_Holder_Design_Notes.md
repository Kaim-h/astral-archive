# Astral Archive — proposed B6 scope: rack reflow, individual walls, and persistent scroll holder

**Status:** Proposed requirements following the B5 review, 20 November 2026. **Not implemented in B5.**

## Scope and motivation

B5 demonstrated carrying a single scroll directly between cells, with live source-cell settling and a destination inspector. The next work should preserve this interaction and eliminate three restrictions: (1) a rack currently cannot be resized safely without first removing stored scrolls, (2) its cells are difficult to tell apart visually, and (3) the physics cell holds only one incoming scroll in a temporary tray.

## 1. Resize a populated rack without losing its organization

**Primary rule:** Cells containing scrolls (**f-cells**) are the units to preserve. Their constituent files should stay together unless the new rack genuinely cannot accommodate the old grouping.

- Each cell receives a stable ID independent of its row/column key and current hex-lattice coordinates. Stable metadata includes scroll identities, color/material override, and any future label. Lattice positions may change without changing cell identity.
- Resizing produces a **preview**, not an immediate mutation. The old rack and scroll distribution remain available for cancellation and undo.
- The solver generates the new connected, clipped, regular-hex lattice using the same geometry routine as browsing and physics. Favor translating the lattice phase / preserving the previous radius where possible; never invent a differently tiled focus view.
- Match old f-cells to new cells. Optimize *lexicographically*: (1) avoid splitting an f-cell, (2) retain the most f-cells intact, (3) minimize displacement relative to their previous location (in rack coordinates), (4) retain f-cell neighborhood/adjacency relationships, (5) minimize rearrangement of empty cells. A geometrically similar target cell must still pass capacity and boundary checks for its specific scrolls.
- An enlargement should normally keep existing filled cells close to their previous positions, using the new area for additional empty cells. A shrink tries nearest valid intact placements first. Only if necessary, attempt to redistribute members of an f-cell to nearby cells, with physical packing validation.
- If no valid packing exists, **do not silently delete, overlap, resize, or move scrolls to unrelated locations**. Show the overflow, offer to expand the rack or allocate additional storage, and let the user cancel. An item in overflow/holding must remain addressable and undoable.
- Preserve the scrolls' settled relative positions within an intact f-cell when the geometry allows. Run a local settle only when wall geometry or the changed cell dimensions require it. Never visually drop an entire populated rack from uninitialized positions.
- A resize is **one undoable transaction** covering the rack geometry, cell assignments/colors, scroll positions, and any overflow. Preview metrics can show retained groups, groups relocated, groups split, and scrolls unplaced.

Suggested first algorithmic milestone: a deterministic mapping between two hex lattices that preserves stable filled-cell IDs and colors while minimizing cell movement, with tests for width growth, height growth, narrow shrink, large shrink, and clipped perimeter cells. Do not add full physics until this identity and mapping layer is reliable.

## 2. Make cells individually built and painted

- Right-click an individual cell to choose its border/frame color from the current theme's material roles or an independent custom swatch. Allow resetting to the theme default.
- Wall strokes should be visibly thicker than the old wireframe. The original shared lattice edge becomes the precise **seam between the two adjacent cell walls**. Each cell owns the half of that wall on its side, so two neighboring cells can have different paint colors; render the seam once, consistently.
- Keep the mathematical edge and the wall's visual width distinct. The physics boundary must correspond to the usable interior once the thicker walls are accounted for. A drawn border cannot conceal scrolls overlapping physical wall thickness.
- Outer clipped cell walls need the same visual treatment. Shared edges should be deduplicated to prevent doubled lines, visible gaps, or z-order artifacts.
- Keep color and any optional cell identity through resize by stable cell ID, not just row/column coordinates. Colors can aid navigation without requiring every cell to have text labels.
- Selection and hover highlights must remain legible in Evening, Twilight, and Midnight and must not permanently replace the owner's chosen paint.

## 3. Persistent multi-scroll holder (carrying inventory)

- Replace the temporary single-scroll holding tray with a low, flat illustrated **scroll holder along the bottom of the cell workspace**, stylistically consistent with the shelf scroll holder.
- The holder can carry several scrolls; each retains stable file ID, name, radius/tier, original rack/cell/cubby, and the source-cell snapshot or journal entry needed for rollback. It should not be instantiated as an extra file copy.
- The holder is a **session-level inventory**, not state local to a single cell inspector. Moving between cells keeps it; later, navigation to another rack or cubby should also keep it. It must remain visible/accessible rather than silently discarded when a cell closes.
- Select an item from the holder and insert it through the existing selected-void, crowded-target, or drop-from-top flow. Failure keeps the item in the holder. A successful insertion removes just that holder entry.
- Lifting from a source cell triggers that cell's physics. Holding multiple scrolls from different sources requires multiple independent provenance records and a transaction log; cancel/undo may need to unwind several source/destination changes safely.
- The holder should visually accommodate a small number of items and offer a compact overflow/scrolling interaction if necessary; the final capacity and presentation should be tested rather than guessed.
- Save should reject an invalid physical state without losing any held item. Do not mutate real filesystem locations: these are visual storage transfers only.

## Engineering sequence

1. **B6a — identity-preserving rack reflow:** stable cell IDs; deterministic f-cell matching, resize preview, validate/commit/undo, no silent displacement or loss.
2. **B6b — painted cell walls:** wall geometry and per-cell material styling, shared seam deduplication, context menu and persistent colors.
3. **B6c — persistent holder:** multiple scrolls, source provenance, multi-cell navigation, insertion and transactional undo. Integrate with the B5 transfer mechanism.

These may be separate prototypes before combining them. Avoid implementing all three as an untested rewrite of B5.

## Acceptance tests

- Increase rack width: all existing scrolls remain, f-cell composition and coloration remain, old adjacencies are preferentially maintained.
- Shrink rack: keep f-cells together whenever geometry permits; if not, explain relocations and any necessary split, with preview and Cancel/Undo.
- Two adjacent cells with different wall colors share one seamless central divider; rack cells remain properly tiled and physics does not clip them into walls.
- Lift two scrolls from two different cells, navigate to a third cell, insert one, retain the other in the bottom holder; Cancel/Undo preserves provenance with no loss or duplication.
- Interactions remain compatible with the existing direct-cell click, scroll drag, Browse/Build separation, and the top-left toolbar.
