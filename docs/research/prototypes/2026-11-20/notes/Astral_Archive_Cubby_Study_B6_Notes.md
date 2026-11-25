# Astral Archive — Cubby Study B6 implementation notes

Date: 2026-11-20. Browser prototype, **not** native Quickshell/QML. Built from the working B5 file; no GitHub changes were made.

## User-visible changes

- **Return to origin:** dragging a scroll over its source hex and releasing restores the exact original rack snapshot, including all the source scroll positions. Dragging outside the rack *except over the holder* still cancels. Dropping over the bottom holder stashes the scroll.
- **Populated rack resizing:** changing a populated rack's width, height or hex radius enters a preview instead of refusing outright or committing immediately. The preview shows potential new geometry, counts f-cells retained intact, relocations, groups redistributed, and unplaced scrolls, and has Apply/Cancel. A rejected resize leaves the original untouched. Undo restores its prior dimensions, cell identities, scrolls, and paint.
- **Stable cell identity:** `rack.cellMeta[key]={id,color}` separates persistent identity and material from transient lattice row/column keys. The resize mapper first preserves populated cells intact (with their contents/colors) using proximity and adjacency as a tie-breaker, then attempts split redistribution only for unmatched groups. New cells get new IDs. It is a **greedy deterministic heuristic**, not a proven global optimum. Very dense shrinkage may be rejected even where an alternative packing exists.
- **Individually painted walls:** each clipped/regular cell has a colored wall strip rendered inward from the mathematical shared edge. The shared edge seam is drawn once. Right click in Browse or Build to choose Theme Default, Copper, Sage, Blue, Burgundy, Violet, Sand, or custom wall pigment. Cell paint persists through reflow when the cell ID survives.
- **Thicker wall geometry:** the paint band is 3.2 units into each cell, while the physical scroll solver uses that inset boundary. Thin clipped slivers have no usable scroll capacity. The old hex lattice remains the exact divider seam; no retessellation in the focused physics cell.
- **Persistent multi-scroll holder:** a low holder dock remains at the bottom. Drag scrolls out of rack cells into the holder; select a held item then click a destination hex to feed it into P2R. Multiple different scrolls can be carried across cubbies. An opened cell also has **Lift selected into holder**; save to commit the lift, cancel to discard it. Returning a selected held item attempts safe physical placement into its original **stable cell ID**, including after a rack resize.
- **Holder Undo:** cell-to-holder, holder-to-cell and return operations use a holder/rack journal so Undo restores both storage contents and carried inventory. Resizing a rack clears old holder-action Undo entries to prevent restoring an incompatible obsolete geometry. This is a browser-session journal only.
- **Active insertion cradle:** the P2R physical insertion tray is relocated into a flatter, lower cradle at the bottom-right of its canvas. The separate bottom dock is the persistent inventory; the physics-cell cradle shows only the currently selected item entering the cell.

## How to test

1. Open the HTML file and choose **Code cubby**.
2. Right-click one hex; choose **Paint cell · Burgundy**. Switch to Build, select the rack, and change its width, height or radius. Review the metrics and click Apply or Cancel. Test **Undo rack resize / paint**.
3. Return to View. Drag a scroll away from its source hex, then release over the **same** hex to verify the entire original arrangement is restored.
4. Drag a scroll into the **bottom holder**, then a second scroll. Both remain available while navigating the library.
5. Select one held scroll, open a destination hex, click or Shift-click a target region, insert, allow the physics to settle, then **Save cell to rack**. The other scroll remains in the holder.
6. To lift within a cell, click a scroll in the inspector, choose **Lift selected into holder**, allow the source cell to settle, then Save. **Undo holder move** restores both the rack and holder.
7. Attempt a shrink into 180×160; the preview should refuse if the scrolls cannot all fit. It should never drop file IDs.

## Tests actually run

- Chromium code sample loads with no page errors; its rack has 38 sample scrolls.
- Browser pointer drag/release over the original cell yielded an *exact* JSON snapshot match against the original arrangement.
- Two scrolls dragged in sequence from the rack were retained in the bottom holder.
- P2R selected-held loading and Shift-click insertion into a different empty hex succeeded; after settling, Save consumed the held item and restored the original total file count.
- Populated rack preview 500×500 → 440×430 kept 10/10 filled groups intact with all 38 scroll IDs, and Undo restored the earlier dimensions and IDs.
- A 180×160 shrink was refused when 13 scrolls had no safe placement; Apply was disabled.
- Real Chromium right-click opened the paint context menu; selected paint persisted across successful reflow, tied to the same stable cell ID.
- Stashing one scroll from within P2R, saving and choosing **Undo holder move** restored the byte-equivalent rack scroll snapshot and returned the holder to empty.
- `node --check` on the extracted main script passed.

## Limitations and future engineering

- The mapping is heuristic, not provably optimal for all adjacency/packing cases. Complex shrinkage may require a global-assignment/constraint solver.
- This is synthetic data, not actual filesystem state; no real file moves are performed.
- The holder and rack changes persist for the lifetime of the browser page, not across reloads. A persistent storage schema and recovery journal are future tasks.
- P2R cell physics still runs inside an embedded same-page inspector. The shared hex geometry and scroll identity are transferred through the bridge, but the cell scene and archive scene are separate renderers.
- Large numbers of cells/scrolls should be stress-tested before native integration. The synchronous reflow preview may pause briefly on difficult shrinkage.
- Separate `Undo rack resize / paint`, `Undo scroll transfer`, and `Undo holder move` operations are retained to avoid destructive conflation. A future unified archive undo journal would be preferable.
- Folders/cubbies can share a carrying inventory; cross-rack and cross-room direct dragging, performance budgeting, and native Quickshell bring-up remain unimplemented.
