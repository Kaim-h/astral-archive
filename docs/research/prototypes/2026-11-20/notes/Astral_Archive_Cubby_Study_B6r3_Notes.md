# Astral Archive — Cubby Study B6r3

**Scope:** Repair the B6r2 rack reflow and editor geometry; do not commit to GitHub. Browser-only HTML research, not native Quickshell implementation.

## User-reported problems

- Three radius-change screenshots at 56, 74 and 52 show groups unexpectedly relocated, groups visually separated, and scrolls that appear unsupported by gravity following resizing.
- Automatically splitting filled cells compromises hand-authored spatial grouping; a user must make the split decision explicitly.
- The editor is too tall to use comfortably except in fullscreen.
- PNGs should remain internal testing artifacts, not be distributed with each HTML experiment unless requested.

## Implementation changes

1. **Global intact-cell matching:** B6r2 assigned old populated cells greedily, in descending scroll count, to the first feasible new cell. B6r3 computes a whole-rack minimum-cost bipartite assignment (Hungarian algorithm). The target position is based on the source cell's normalized location within the rack, with bounded adjacency-preserving swaps. This reduces unnecessary leaps when a large group occupies another group's natural destination. The planner searches 9 nearby candidate targets first; when a global match is impossible it tries more distant candidates before declaring a split necessary.
2. **Physics on every preserved group:** The former fast path `preserveInsideCell()` accepted non-overlapping positions without physical settling. It now runs `settleSeededCell()` even when a translated arrangement fits. This makes a large resized hex develop a new gravity-resting pile rather than retaining floating previous-height positions.
3. **User-controlled splitting:** If an f-cell has no intact destination, the preview enters an `attention` phase; Apply is disabled. An affected successor candidate receives red haze, dashed wall outline and `!`. The panel names the old cell, count and issue, and offers **Allow split of this cell**. Consent is per stable cell ID and per dimensions (changing dimensions clears approvals). Split placements are planned into a minimal connected cluster of empty successor hexes; unrelated populated groups are never used as overflow destinations. Splits inherit the parent's wall paint and lineage while assigning unique successor IDs. A successful approval shows amber markings on successor cells and a **Revoke permission** button. Cancel changes nothing. Commit and Undo remain transactional.
4. **More stable empty-cell paint:** Empty painted cells are assigned to unused destinations by global position rather than a greedy one-by-one scan. Fewer new cells can physically contain fewer empty cell identities; preserved f-cells always take precedence.
5. **Viewport-based editor:** A desktop-width browser now gets a fixed 100dvh workspace, an independently scrollable sidebar, and a stage that flexes to the available screen rather than enforcing 650px minimum height. Narrow displays stack the sidebar with independent scrolling and assign most of the viewport to the stage. The reflow panel itself scrolls when many issues are present. The focused physics inspector is unchanged and uses its existing full-window presentation.
6. **Prototype metadata:** The title and serialize status identify B6r3. All B5/B6 cross-cell and scroll-holder interaction code remains in place.

## Regression checks actually performed

- `node --check` of the standalone script passed.
- Playwright/Chromium with `/usr/bin/chromium`, loaded from `page.set_content` due local navigation restrictions.
- Radius sweep on the Code sample, which has 38 scrolls in 10 populated cells:

| Radius | Whole f-cells retained | Approval required | Outcome before consent |
|---|---:|---:|---|
| 38 | 7/10 | 3 | Locked; no data change |
| 42, 48, 52, 56 | 9/10 | 1 (12 scrolls) | Locked; no data change |
| 60, 64, 68, 72, 74, 76 | 10/10 | 0 | Ready, no splits |

- At 56 and 52, approval produced **two adjacent successors** for the 12-scroll cell; at 38, three separate approvals led to a viable plan. Each tested application retained all 38 scroll IDs, with unique final cell IDs. Undo restored radius 64 and all 38 scrolls.
- Explicit approval could be revoked; doing so returned the preview to the blocked attention state. The approved successor cells inherited the parent's tested custom purple wall color.
- Re-settling already proposed layouts a second time moved scrolls at most ~0.48 units for radius 74, ~0.02 for radius 56 and ~1.00 for radius 52 in the observed tests. These are not proof of a universal convergence bound, but show the old large floating-position regression was not present in the sampled cases. Maximum observed circle overlap in those layouts was ~0.004 units.
- Viewports 1366×768 and 1024×600 had document scrollHeight equal to viewport height, and the reflow panel stayed within the visible stage.
- No Chromium page errors in the recorded test paths. Internal screenshots were reviewed but are **not** separately delivered.

## Still unresolved / further design decisions

- Consent currently controls **whether** an individual f-cell may split; users do not yet select the exact successor hexagons or drag the successor group(s) to custom destinations. This is a natural next refinement if user testing finds the automatic adjacent placement visually undesirable.
- The split planner is a finite bounded heuristic. It may correctly refuse to resize if no connected empty successor group can fit the files within the search budget, and may fail to discover rare feasible global rearrangements.
- Existing physically decorated painted cells are stored in a simple `cellMeta` mapping; a production data model needs explicit primary/descendant lineage, record ownership, migration and conflict resolution under repeated resize/undo/holder movement.
- Complex scenarios (many tightly occupied cells, heavily clipped boundaries, repeated different-radius changes, custom/user-created racks, many carried scrolls) need more extensive native and browser testing. A worker watchdog rejects slow plans without committing; it is not proof of optimal packing.
- The resize status popover still overlaps part of the rack in a narrow viewport. Docking or a draggable compact panel is an optional future usability refinement.
- The standalone study remains ephemeral; no filesystem/indexing persistence or native QML integration is claimed.

**Do not proceed to new file-object families simply because this experiment passed.** The next review should test custom-painted and hand-arranged racks, repeated resize chains, manual split destination preference and holder provenance across a split.
