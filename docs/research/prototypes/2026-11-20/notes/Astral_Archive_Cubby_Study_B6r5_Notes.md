# Astral Archive — Cubby Study B6r5 (experimental)

**Status:** Standalone offline browser research after B6r4 owner feedback; not approved Quickshell/QML or a completed B7 gate.

## Owner decision and redesign

The active holder is a **small multi-scroll shelf** separate from the **persistent portable scroll case**. B6r4 used a P2R single-scroll tray, a case chip list, and a button-based staged transfer, which became temperamental and inconsistent with direct dragging.

B6r5 preserves B6r4. Inside a focused physics cell, two physically drawn shelf surfaces now appear outside the hex: Active holder and Portable case. Drag a scroll outside the hex and release to place it on the active shelf, or drag it onto the case surface to carry it there. Drag between either shelf and a cell or between shelves. The Lift button is an optional shortcut to the active shelf. The outer dock expands to show two shelf surfaces instead of only small case chips; the earlier rack overview drag can target either shelf.

Save validates that every existing scroll ID appears **exactly once** in cell + active shelf + case, then commits all three at once. Cancel leaves committed contents unchanged. Undo snapshots retain the active shelf and portable case inventories together.

The simulator, including the new drag handlers, is embedded inside one standalone HTML file with no network dependencies. Previously developed draggable reflow preview and visual recess control remain.

## Limits and acceptance checklist

- The active shelf persists as working inventory between focused cell edits, distinct from the portable case.
- The outer dock is a selection and inspection surface; direct drag between cell and shelf happens inside the focused physics view.
- The cell shelf graphic is sized for small inventories, and narrow screens or large collections need manual usability review.
- All examples remain synthetic; no native filesystem operations or QML changes.
- Check direct cell-to-active, cell-to-case, both reverse directions, active-to-case, case-to-active, selection shortcuts, Cancel, Save, Undo, and identities after reflow.
- Check rack overview drag to either shelf, cross-cell drag and source settling.
- Verify that an invalid drop never loses a scroll or creates a duplicate.
- Static check scripts/check-b6r5.js verifies syntax and required integration points, not runtime or UI acceptance. Do not assume B7 gate completion.
