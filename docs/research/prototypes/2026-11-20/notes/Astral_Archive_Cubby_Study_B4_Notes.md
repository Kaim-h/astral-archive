# Cubby Study B4 — P2R scroll physics integration

**Status:** Standalone browser prototype, synthetic file data. Not production QML, not connected to a filesystem, and not pushed to GitHub.

## Sources and preserved behavior

- **Furniture and navigation:** `Astral_Archive_Cubby_Study_B3_Bookmark_Revision.html` (B3 plus the small protruding/higher-bending bookmark revision); B2's module editor, theme colors, shelf holder, seals/tooltips, and A6's recursive cubbies remain present.
- **Physics:** `Astral_Archive_Scroll_Physics_Study_P2R.html` (the reviewed single-hex live physics experiment), embedded inside B4 so the HTML works without separate assets or network access.
- **Hex cells:** B3 `geomForRack()` remains the authoritative rack tiling and scroll placement geometry. The selected cell's actual polygon vertices, including perimeter clipping, are transformed into P2R physics coordinates. Its existing scroll names, dimensions, IDs, and centers use the same reversible transform. P2R does not regenerate rack cells or their radius.

## Interaction

1. Load the **Code cubby** sample and click its large hex rack. The central cell (2:2) deliberately contains a denser synthetic set to exercise collisions.
2. Click a cell or scroll in the focused rack, then **Enter selected cell · physics** (or double-click a cell).
3. Inside the cell inspector, drag existing scrolls with the tether, prepare and insert a new scroll into a selected void, Shift-click a crowded target, or drop one from the top. Existing P2R gravity 150 and liveliness 100% defaults are retained with sliders.
4. **Save cell to rack** when the simulation is settled. The new positions and new scroll objects update only the selected cell, with a single rack-level undo entry. **Cancel · discard** changes nothing in the rack. **Undo saved cell** restores the previous arrangement.
5. The rest of the cubby, including other cells, books, shelves, recursion, theme settings, and module controls, is unchanged.

## Current limitations and next engineering steps

- Physics runs in an embedded *in-page* iframe to keep the reviewed P2R solver isolated while validating the integration contract; this is a transitional structure, not the final shared native engine.
- Only the active cell simulates. Saved scroll positions persist only within the current browser session (not across reloads). Real file identity / metadata is not connected.
- The inspector uses the P2R scroll art while the rack overview uses the simpler B3 scroll glyphs. Unify the rendering without changing geometric identity in a subsequent pass.
- P2R simulates into clipped perimeter polygons as well as complete hexes. Narrow cells may legitimately reject insertion.
- A full deterministic stress suite, long-duration physics benchmarks, and native Quickshell integration remain to be implemented.

## Browser checks performed

- Open a stored full hex with original scroll identities and counts; inspect exact transformed polygon geometry.
- Insert into a selected void, settle, save to the parent rack, then Undo; check counts and original layout restoration.
- Open a clipped perimeter hex with no scrolls; cancel safely.
- Drag a scroll physically, then discard the changed simulation; original parent rack remains unchanged.
- Switch Evening/Twilight/Midnight themes, create an empty rack, navigate to nested Utilities and return.
- Checked browser page errors in the tested flows: none observed. These browser checks do not establish native Quickshell correctness.
