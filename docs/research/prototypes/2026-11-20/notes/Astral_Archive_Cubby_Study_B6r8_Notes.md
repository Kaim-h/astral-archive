# Astral Archive — Cubby Study B6r8

**Status:** Standalone offline browser research. B6r7 is preserved unchanged; no native Quickshell/QML implementation or B7 gate is claimed.

## Owner feedback addressed

1. The parchment inventory was too literal. It is now called **Scroll Register**, not a shipping manifest. It is a roll/parchment list of the complete internal clipboard contents beyond the four visible cradle scrolls; status remains CUT/STORED for research clarity. No logistics/shipping terminology is needed.
2. The focused Scroll Case visually covered a dragged scroll. Its SVG layer now sits **behind** the physics scroll layer. The pointer-carried scroll graphic is drawn in a separate last/top SVG preview with pointer events disabled, so it stays visible across the case until release.
3. The **×** did not reliably close the case. The focused case has an explicit close control and remains dismissed until the pointer departs. The Scroll Register × also works. The outer dock × now unconditionally collapses, even after a drag offer.
4. The case should **open only when approached**. The focused case starts as a narrow header and opens when the pointer reaches its proximity area (including a dragged scroll). It folds on departure. The centered dock remains a slim pill until hover/drag approach; it closes when the pointer leaves and supports keyboard access.
5. Rack-wide dragging seemed broken. In B6r7, startCrossTransfer called showHolderAsDropTarget(true) immediately, which expanded the floating dock at drag start. In B6r8 drag makes the dock *eligible* as a target, but only physically nearing it expands the case. In the rack overview, a scroll can still move between full cells, cancel back to its source, or enter the case on hover without a forced overlay.

## Behavior and safety

- One authoritative Scroll Case inventory: focused view and dock show the same case state.
- Four visible cradle slots plus Scroll Register for overflow.
- Ctrl/Shift multi-selection, Ctrl+X / Ctrl+V, direct dragging and explicit Save/Cancel/Undo remain from B6r7.
- Embedded physics settles scrolls **inside cells**. Moving to/from the Scroll Case remains provisional until Save in a focused cell; rack overview transfer uses its existing transactional return/cancel path.
- An invalid drop returns or cancels; it must not delete scrolls. No actual OS clipboard or filesystem mutation occurs.

## Checks

- Local headless Chromium: focused case initially folded; opens on approach; × closes and stays dismissed until leave; reapproach opens. Register opens and its × closes.
- Local headless Chromium: drag source scroll into case; drag preview is the last SVG layer while case background is behind scrolls; Save decreases cell by one and increments case by one with identical scroll ID.
- Local headless Chromium: dock hover opens; × closes; away/reapproach reopens.
- Local headless Chromium: rack scroll → distinct full hex cell activates destination inspector; Cancel restores source; Escape can also cancel.
- Local headless Chromium: rack scroll → approached case stores exactly once with ID preserved; case stays closed at drag start away from dock.
- scripts/check-b6r8.js parses standalone outer, patch and embedded JS, checks markers, required controls and no external dependencies. scripts/smoke-b6r8.js checks the paths above in Chromium CI.

**Not validated:** very dense racks and long drag sessions, all truncated edge cells, touch devices, large register pagination, every reflow/split identity edge case or native Quickshell integration.

## Development workflow

Continue on the existing ongoing branch `research/cubby-study-b6r5-2026-11-23` and update PR #6; do not spawn a new branch or PR for every HTML iteration. The PR is stacked on B6r4 PR #5 until the owner explicitly resolves/merges that dependency.
