# Astral Archive · Cubby Study B6r7 — Scroll Case clipboard

**Scope:** Standalone HTML/SVG/JavaScript browser research, not a Quickshell/QML implementation or real filesystem cut/paste. Historical B6r6 remains preserved. This continues the **same running development branch** `research/cubby-study-b6r5-2026-11-23` and existing PR #6.

## Owner direction

The active shelf and portable case were accidentally separate views of what should be **one Scroll Case clipboard**. Its centered dock bar also obscured the focused interface. The original `drawShelfContents` cradle artwork remains the required graphic. Four end-on parchment scrolls should be legible on the cradle; a future physical stack of approximately seven is a *design possibility*, not implemented physics. Larger inventories need an explicit shipping manifest, preferably rendered as parchment/scroll.

Cutting a file is analogous to Ctrl+X; its record moves from a cell to a temporary clipboard and may subsequently be pasted into a different cell. Support Ctrl/Shift-click grouping, keyboard cuts, direct dragging and a manifest of all held files. Preserve identity, Cancel and Undo.

## B6r7 implementation

- **One authoritative inventory:** `holder.items` in the parent and `state.caseShelf` in the focused simulator are two synchronized views of one case. The former `holder.active` inventory is merged and emptied; no extra holder view is rendered.
- **One case interface at a time:** the original centered bottom dock is a small collapsed button outside focused-cell mode. When its panel expands, the button disappears rather than forming a duplicate bar. The entire dock is suppressed while a cell is focused; that focused view owns the case controls.
- **Original cradle art:** low SVG frontal bar, inlaid line, raised end stops, concentric parchment scroll ends. A maximum of **four** items is shown on the cradle. No simulated seven-item stacking physics is claimed.
- **Parchment shipping manifest:** the focused-case manifest and outer-dock ledger list **all** carried records, including excess beyond four, names, transfer mode `CUT` or `STORED` and counts. Pages accommodate long lists. The manifest is manually opened so it does not obscure a cell on group cut.
- **Multi-selection:** focused cell Ctrl-click toggles, Shift-click selects contiguous entries based on the current cell's ordered scroll records. Ctrl+X cuts selected synthetic records to the case, and the dedicated Store button also sends a selection there. Dragging any selected scroll outside the wall or onto the case carries the selected group.
- **Paste:** select a case entry in its cradle or manifest, then drag into a suitable cell position or press Ctrl+V. For grouped paste, positions are pre-planned in an available cell region; if all selected scrolls cannot be placed, **none** are removed from the case. Allow the P2R solver to settle before Save.
- **Atomic Save:** parent checks uniqueness of existing scroll IDs across `cell + case` (legacy active-list slot is empty) and stores `moveMode` / `batchId` provenance. Cancel discards staged edits; holder Undo snapshots remain intact. No actual OS clipboard/file operation is attempted.
- **Overview drag:** the existing B5/B6 overview drag can target the centered case; the destination resolves to the case alone. Full multi-selection Ctrl+X is implemented **inside the focused cell**, not yet in rack overview.

## Tests conducted and remaining work

- Local Chromium real clicks with Ctrl multi-selection, Ctrl+X, Save and invariant checks: three scrolls removed once from source and placed in case with original IDs and `cut` provenance; centered dock shows correct inventory.
- Local Chromium dense twelve-scroll cell: six scrolls cut in one group, four visible in cradle, manifest enumerates all six; selecting a manifest entry and Ctrl+V pastes one back, leaving five in case, with no JavaScript console errors.
- Source JS parsed in Node; inner simulator patch compiled. CI adds version-specific static and Chromium tests in the existing workflow.
- Remains exploratory: long-running physics and unsettled cells may require waiting before pressing Save; large manifest pagination, narrow viewports, touch interactions, group drag under high density, and rack reflow/split lineage need owner testing. Native OS clipboard, actual filesystem cut/paste, storage persistence and seven-scroll stacking are **not implemented**. Browser prototype does not satisfy B7 entry gates.
