# Astral Archive — Cubby Study B6r6

**Status:** Standalone offline HTML/SVG browser research, not Quickshell/QML implementation or a B7 sign-off. B6r5 remains unchanged.

## Owner-confirmed artwork

The correct visual reference is the real screenshot of the original shelf-based holder from Astral_Archive_Cubby_Study_B6r.html. Source: existing drawShelfContents and scrollHolderLayout SVG functions. Its essential primitives are a low frontal cradle, thin inlaid line, raised ends, and concentric parchment scroll ends. Do not substitute generic circles in large boxes or generated imagery.

- **Active shelf:** temporary multi-scroll working inventory.
- **Portable case:** distinct persistent carried inventory. Independently collapsible.

B6r6 renders both focused inventories using the original SVG cradle and parchment palette, scaled for legibility, and uses the same artwork in the outer dock. The visual cradle width grows with the visible scroll count. For more than four items, page between groups in the focused view.

B6r5 inadvertently showed the older P2R ACTIVE SCROLL HOLDER tray in addition to the new active shelf and case. B6r6 hides only the obsolete #trayLayer drawing; it preserves its underlying physics code. Exactly one active shelf and one portable case are visible in the focused interaction. The outer dock is another *view* of those inventories, not a third inventory.

The portable case can collapse within the focused cell and within the outer dock. Dragging onto its collapsed header still stores a scroll and reopens the case. Folding does not remove contents. Rack reflow preview and cell recess remain as in B6r4.

## Data integrity and scope

B6r5's cell+active+case transaction remains: Save validates unique scroll IDs across all three destinations and commits atomically; Cancel discards provisional movements; Undo restores both shelves with cell geometry. P2R physics handles placement and settling within the hex, not portable inventory ownership. No filesystem write or native UI feature is asserted.

## Tests and limitations

- Local headless Chromium: cell→active, active→case, case→cell, case→active plus Cancel; Save and Undo preserved scroll identities.
- Local headless Chromium: case collapsed during drop, delivery succeeds, case reopens, obsolete tray hidden, two cradles exist.
- Local headless Chromium: outer dock displays both cradles, case collapse/expand leaves inventory intact, no JavaScript errors.
- Static and Chromium CI scripts: scripts/check-b6r6.js and scripts/smoke-b6r6.js.
- Remaining: dense inventory/pagination, narrow viewports, long physics sequences, touch, reflow split lineage and native B7 gates.

## One ongoing development branch

Continue work on the existing branch research/cubby-study-b6r5-2026-11-23, updating the existing PR #6 rather than creating a new branch/PR for each iteration. Preserve each historical HTML version as its own file. PR #6 is stacked on still-open B6r4 PR #5 until its dependency is resolved deliberately.
