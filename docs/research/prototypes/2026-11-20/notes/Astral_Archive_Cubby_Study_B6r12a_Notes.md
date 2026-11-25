# Astral Archive — Cubby Study B6r12a: Session 1 checkpoint

**Status:** Experimental browser-only foundation, **NOT completed B6r12**, **NOT B7/QML acceptance**.

## Owner decision

The owner preferred two working sessions over one large brittle rewrite. This is the first coherent checkpoint. B6r11 is preserved. The second session should implement real-time rack-native physics, in-place reflow/splitting, and remove obsolete secondary rack/iframe/ghost paths.

## What this checkpoint actually implements

**One visible scene for ordinary scroll interaction.** In Browse mode, a click on a rack cell selects the cell directly on `#scene` rather than opening `#b4CellOverlay` / `#b4Frame`. A mouse drag picks up an actual scroll glyph in the main rack; a separate high-z, pointer-events-none scroll image stays visible over the Scroll Case popup. Dragging into another valid rack cell commits that item to the target. Invalid drops roll back without changing state. The focused rack modal remains preserved as legacy code for a safe next-stage port, but it is bypassed by these normal rack gestures.

**One canonical ownership transaction.** The `b12Owned` index enumerates scroll IDs across all cubby racks and the single Scroll Case. `b12Commit` operates on a cloned authoritative state, verifies no duplicate/vanished IDs, validates each occupied cell's polygon boundaries and collisions, and swaps the entire record set only when valid. It stores a complete precommit Undo snapshot. No scroll has two homes after a successful move.

**Direct rack/case gestures.** Single-scroll rack-to-rack, rack-to-case via the proximity case, case-to-rack dragging, Ctrl-click/Shift-click selection and multi-item Ctrl+X to case are handled on the one main scene and case inventory, without iframe message passing. A selected case scroll can be placed with Ctrl+V into the selected rack cell when an empty position can be found. Escape cancels the current gesture without changing stored positions. Undo (button or Ctrl+Z) restores the prior full authoritative state.

**Contact response for occupied drops.** A position that is initially clear commits exactly where it was dropped. Where the proposed point overlaps another scroll, the existing P2R-derived `settleSeededCell` solver runs on a **copy of the target cell's scrolls**, and may settle contacts locally only when successful and without a large teleport. This is still a drop-time collision solve, NOT a fully animated, continuously interacting rack physics engine. The second working session must port P2R's proper live dynamics to the rack instead of introducing yet another simulation state.

**Persistence.** Successful rack/case commits and Undo attempt to checkpoint browser-local state under a **new B6r12a-specific storage key**. The Scroll Case's Save study / Load study buttons are re-bound to this snapshot. Loading validates unique IDs, supported geometry and cell arrangement. The older B6r11 checkpoint is not overwritten. Browser file:// storage behavior is browser-dependent; this remains synthetic research, not real file moves.

**Shape-ready, not shape-complete.** An adapter registry defines the current hex geometry/fit/settle behavior and reserves explicit unsupported square, triangle and diamond adapters. Ownership and transactions do not assume hex-specific scroll IDs; new adapters must be implemented and validated before enabling their UI choices.

## Deferred to Session 2 — do NOT misrepresent as complete

1. Full P2R live gravity/contact/drag dynamics directly inside `#scene`, with per-cell activation and sleep. No second physics copy. Current use of `settleSeededCell` is a narrow on-drop bridge.
2. Actual rack resize in place, without the entire separate reflow-ghost rack. Pending invalid cells should be clearly indicated **on the current rack** while real data stays committed until accepted; Cancel must restore exact geometry.
3. Direct interactive split resolution: source cell ID and lattice address stay fixed; user clicks destination cell(s) or chooses the Scroll Case; chooses **specific overflow scroll IDs**, possibly multiple destinations; capacity/identity constraints are atomic.
4. Retire or remove legacy `#focusScene`, `#focusModal` rack editor, `#b4CellOverlay` and `#b4Frame` P2R iframe, and old input routes **only after** equivalent rack-native behavior is verified. Avoid breaking other module-inspection functionality.
5. Complete keyboard multiselection, drag preview of multiple selected scrolls, touch accessibility, geometric adapters and viewport-aware usability policies as later gates.
6. Regressions: 75→76, 76→75, 57→56, true overfull case, explicit case spill, two rack modules, cross-cubby transfer, long running physics, no-op identity preservation and camera-only zoom.

## Tests performed / CI

- Local Chromium (main scene): rack scroll selected without iframe, scroll dragged rack→different empty cell, single owner, Undo restores source; invalid drop outside rack leaves original unchanged.
- Local Chromium (case): main-scene Ctrl-click + Ctrl+X moves selected IDs once into the Scroll Case, case→rack drag moves one back, Undo restores case, no page errors.
- CI scripts `check-b6r12a.js` parses parent and preserved embedded P2R script, verifies foundation markers, unique controls, no external dependencies and geometry registry.
- CI scripts `smoke-b6r12a.js` checks main-scene click without iframe, invalid drop, rack-to-rack, Undo, group cut, case-to-rack and checkpoint reload with stable IDs.
- Old B6r4–B6r11 scripts remain in CI.

## Branch and scope

Continue on `research/cubby-study-b6r5-2026-11-23` and update PR #6. Add future B6r12b and later versions to the same branch, preserving this checkpoint. PR #6 is stacked on still-open B6r4 PR #5. Do not merge or label B7 complete without owner instruction.

**This is a reviewable stopping point, not a completed refactor.** No QML changes or real filesystem/OS clipboard changes were made.
