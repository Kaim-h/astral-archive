# Astral Archive — Cubby Study B6r9

**Status:** Standalone browser research on the existing running development branch. B6r8 remains untouched. This does not authorize native Quickshell/QML or satisfy the B7 release gate.

## Owner report

Owner screenshots demonstrate intact filled groups that change which hex cell they occupy when adjusting the hex radius around 75–76, and unexpected rearrangement at 57 and below. The previous planner displayed green READY with all ten whole groups even when three or four were relocated, but it did not demand authorization for those moves. The owner also observed the DOM Scroll Case visually covering a scroll being dragged from the rack overview.

## Changes

**Minimum-displacement reflow:**
- When width, height and hex radius do not change, the planner returns an exact identity-preserving no-op. It does not settle the scrolls again or rematch cells (including 75 → 75).
- The assignment target now prioritizes each original cell's physical center. When downsizing the rack, the target is gently adjusted inward only as needed.
- Removed the optional adjacency-swap optimization that could exchange otherwise valid whole-cell assignments to improve a minor score.
- Hungarian matching still searches feasible intact destinations globally; it does not silently split a group. Existing split authorization stays mandatory.

**Review every positional movement:**
- Each populated cell whose successor key changes OR whose center moves more than 0.75 rack units is listed with stable cell ID, source→destination keys, distance and scroll count.
- Any lattice center shift, even at the same total number of cells, or a changed cell count, is separately flagged for approval. This catches movements of empty cells too.
- The narrow moveable rack-adjustment panel contains a scrollable checklist; the rack ghost marks proposed destinations with red dashed outlines and exclamation marks until approved. Approved destinations become amber.
- Apply is disabled until all movements and any lattice change are approved. The commit handler revalidates approvals even if called programmatically. Approval resets whenever dimensions or radius change; split decision updates also reset approvals.
- If every value is unchanged, Apply reads "No changes" and is disabled.

**Drag visibility across the case:**
- Rack-overview carries now have a dedicated viewport-layer SVG copy of the actual scroll-end glyph, with pointer-events:none and z-index 100000.
- This overlay follows document-level pointer movement even when the pointer enters the separately layered DOM Scroll Case. The rack's original in-scene ghost remains, and the viewport overlay is removed on drop, cancel, and commit.
- The case is still proximity-triggered; it must not pop up just because a drag starts.

## Test and safety scope

- Static check scripts/check-b6r9.js validates the outer and embedded scripts, review controls, no-op and overlay code presence.
- Chromium smoke scripts/smoke-b6r9.js compares exact unchanged scroll maps, checks explicit blocking of unapproved movement, and tests the topmost scroll ghost while dragging from rack toward the opened case; it also runs B6r8 focused-case, rack-to-rack Cancel and rack-to-case transfer checks.
- Existing offline and browser checks for B6r4–B6r8 remain in CI.
- Further owner checks should explicitly include 75→75, 75→76, 76→75, 57→56, 56→57, a dense cell that truly cannot fit, and a change in the number of hex cells. Acceptance should focus on visual stability rather than merely "all groups intact."
- Browser studies still use synthetic file records and an internal Scroll Case. No actual OS clipboard or filesystem cut/paste.

## Branch policy

Continue all future cubby study versions on `research/cubby-study-b6r5-2026-11-23` and update **PR #6**. Preserve each historical HTML and notes separately. PR #6 is currently stacked on the open B6r4 PR #5 and should not be merged ahead of its parent.
