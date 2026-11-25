# Astral Archive — Cubby Study B6r11

**Status:** Self-contained HTML/SVG browser research, with synthetic records. Not native Quickshell/QML, not a completed B7 approval.

## Owner feedback and intended design

The reported "placement isn't permanent" refers mainly to a scroll leaving the Scroll Case during insertion, then appearing back in the case, **not** primarily to refreshing the HTML. The correct contract is: *a failed or canceled insertion leaves the scroll in the case; a valid, explicitly Saved insertion moves that same scroll ID into the destination cell exactly once*. An impossible placement must say why immediately, rather than appear successful and later revert silently.

The owner proposed a radius cap near 60, or a usability warning in the eventual QML application. **B6r11 chooses a soft experimental radius threshold of 60**. New rack defaults use 60. Existing samples and values up to 76 are preserved, but increasing a radius above 60 displays an acknowledgement checkbox and blocks Apply until the risk is explicitly accepted. This avoids breaking historical tests while providing a ready-made QML warning policy; the final native app may use a screen-space/zoom-aware warning instead of a raw model radius.

Cell geometry is specified in data, **hex** by default. The catalog reserves **hex, square, triangle and diamond**. Only hex has an implemented geometry adapter in this study; other options are visible but disabled. Unsupported shapes are explicitly rejected rather than silently interpreted as hexes. Scroll identity, storage ownership, case movement and geometry validation are conceived independently of hex-only names. Future shape adapters will have to define lattice, polygon, adjacency, containment, collision and insertion before being enabled.

## Anchored splitting

In previous versions an overfull source cell could be split into a cluster of other cells and its stable identity moved to whichever successor had the most scrolls. That violates the owner's model.

**B6r11 requires the original cell to remain at its existing lattice key, retaining its stable cell ID and all scrolls that still fit there.** The splitter may send only the remainder to exactly one explicit new destination (another available cell or the Scroll Case). There is no automatic overflow migration. The user must approve the split and choose its destination in the reflow panel. If the original lattice address doesn't exist under the proposed resize, the split cannot be applied as if it were anchored: the user must enlarge the rack or choose a separately reviewed whole-cell relocation.

For remaining scrolls, trial packing examines their original coordinates, then solves only when a placement genuinely cannot remain valid. Every committed mapping preserves the union of scroll IDs across rack + case. The case overflow is included in the same reflow transaction and Undo snapshot; no duplicated ID is permitted. Any deliberately impossible destination leaves an actionable issue rather than silently moving scrolls elsewhere.

**Limit:** This is still a one-overflow-destination prototype, not a full per-scroll split editor or arbitrary N-way shipping system. Future iterations may add picking the exact files to move and multiple target cells.

## Case insertion and placement durability

The focused case-to-cell drag now checks whether the drop center is collision-free. If blocked, it searches for a safe alternative; if none exists, it keeps the scroll in the case with an explicit message, instead of starting a fragile insertion that later silently rolls back. The original P2R holding tray remains the path for case-to-rack transfers from the overview, with *mark void* or *Drop from top*, then physics settling.

The parent Save rejects any carried scroll that hasn't actually entered the cell or is still listed in the case. On successful Save, its stable ID exists exactly once in the destination cell, disappears from the case and is checkpointed. Cancel leaves case inventory unchanged. Previously valid scroll coordinates are returned without unnecessary gravity re-settling during resizes.

To distinguish **committed** state from temporary physics drafts, B6r11 provides a browser-local study Save and Load inside the Scroll Case dock. It autosaves after committed cell Saves, rack reflows, case stores/returns and corresponding Undos, never while dragging or editing. It checks for duplicate scroll IDs during Load. Local browser storage is convenience only, not native filesystem integration, not a cross-browser backup and may depend on the browser's file:// storage policy.

## Verification

- `scripts/check-b6r11.js`: parses outer JavaScript, original embedded P2R physics and new focused patch; validates shape options, radius warning, anchored split and case-overflow ownership conservation, persistence and dependency-free HTML.
- `scripts/smoke-b6r11.js`: real Chromium test for a case-approved anchored split, original stable ID unchanged, overflow to case without losing IDs, radius warning, case→rack insertion completed with Drop from top + Save, then reloading the local browser checkpoint and confirming one destination ownership.
- Earlier B6r4–B6r10 static and browser tests remain in CI, including rack-to-rack Cancel, case-on-approach, drag visibility, unchanged resize and 57→56 case.
- Additional owner acceptance: resizing a dense real-looking group, choosing an alternate overflow hex, selecting Scroll Case fallback, attempting to place in an overcrowded cell, and checking QML-size warning behavior at different zoom levels.

## Development process

Reuses **the same running branch** `research/cubby-study-b6r5-2026-11-23` and PR #6; the old HTML prototypes remain unchanged as historical versions. PR #6 is stacked on still-open B6r4 PR #5 and should not be merged out of order.
