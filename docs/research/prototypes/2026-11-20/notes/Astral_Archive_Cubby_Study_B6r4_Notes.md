# Astral Archive — Cubby Study B6r4 (experimental)

**Source:** [B6r4 HTML](../cubby-studies/Astral_Archive_Cubby_Study_B6r4.html) — separately versioned browser study forked from [B6r3](../cubby-studies/Astral_Archive_Cubby_Study_B6r3.html). **Status:** proposal for owner review; not approved native implementation or completion of B7.

## Owner feedback addressed (November 23, 2026)

1. The focused cell's **active scroll holder** appeared disconnected from the portable **scroll case**; the embedded **Lift selected** operation could appear to send an object into an abyss.
2. The rack adjustment preview panel was too bulky, immobile, and blocked examination of the rack.
3. Cell view should offer **cubby/cell depth controls**.

These observations are the reason for B6r4. Do not relabel them as confirmed B6r3 fixes or delete the B6r3 source.

## B6r4 changes

### Active cell tray → portable case, with deliberate Save

The P2R simulator's **Lift into cell tray** remains a local, reversible physics operation. The parent now observes the active tray and current selection over the existing cell bridge. The portable case expands to show a tray-to-case prompt. **Send selected/tray → case** accepts either a selected stored scroll or a scroll already lifted into the local tray. The latter used to be rejected because P2R's `stash` bridge considered its own held scroll a busy state.

An acknowledged transfer is **staged**, shown as an explicitly pending item in the case, not counted as already committed. **Save cell + case** commits the source-cell removal and portable-case inventory update together. **Cancel · discard** closes the provisional cell simulation without changing the committed case inventory. Case-item IDs remain the source's stable IDs, mapped from the simulator's temporary numeric IDs. The Save path refuses a missing/duplicate cell ID or an item simultaneously present in the cell and the case staging list. An already-carried case scroll may not be duplicated by sending it back to the case; it must be inserted or the cell edit cancelled.

### Slim rack adjustment panel

Rack adjustment is reduced to approximately **310 px** width, with independently scrollable split issues. It can be repositioned by dragging the dedicated header, nudged with **arrow keys** when the header has focus (**Shift + arrow** for finer moves), and reset to the default corner. The panel is clamped to its stage, including after viewport resizing. This **moves only the panel**; the rack ghost, geometry and explicit split permissions remain unchanged.

### Cell-level depth control

The focused-cell header now contains a **Cell recess** slider, range **0–24**. This is a **visual depth/recession setting** for the selected hex cell, not a filesystem directory depth, not an additional cubby hierarchy, and not an increase in scroll capacity. Its preview shades the P2R backing; Save stores `cellMeta[cellKey].depth` for the corresponding stable physical cell, and the rack overview reads it for backing shading. Cancel does not commit it. Holder/journal and rack Undo paths are extended to retain prior cell metadata where necessary. Cell metadata is propagated by the existing B6r3 reflow mapper; multi-step lineage still needs independent testing.

## Verification and limits

- `node scripts/check-b6r4.js` parses **both** the parent HTML JavaScript and its embedded P2R script with Node's `vm.Script`, checks expected bridge/depth/panel integration points, and checks unique outer HTML control IDs. This is a **static/source check**, not a browser interaction test.
- The established offline workflow also runs its existing project checks. Record the actual workflow result when it finishes; do not claim native Quickshell or Playwright verification from syntax checks.
- The existing browser physics, worker-based reflow and original B6r3 version are preserved as separate research. No filesystem mutations, QML, or new file-object families are introduced.

## Manual browser test matrix still needed

1. **Tray lift → case:** Open a populated cell, select a stored scroll, click *Lift into cell tray* in P2R, confirm the portable case identifies the active tray, click *Send to case*, confirm one staged item, Save, then verify one committed case item and no duplicate source ID.
2. **Direct selection → case:** Select a stored scroll without using the tray, send it to the case, Save, verify its identity, then return it safely to the origin.
3. **Cancel & Undo:** Repeat both paths and Cancel before Save; the original cell/case must remain unchanged. Save a case move, then Undo the holder operation and verify scroll and cell metadata.
4. **Incoming carried scroll:** Select an existing portable-case scroll, open a destination cell and ensure it cannot be re-stashed as a duplicate. Insert successfully or Cancel; verify no lost ID.
5. **Depth edit:** Change recess 0→24 and Cancel, then Save and Undo; confirm depth remains presentation-only and applies to the same physical cell. Repeat after rack resize and split where allowed.
6. **Move the rack panel:** Test desktop and narrow viewports, pointer drag, arrow nudge, Reset, and split-permission controls while the preview is visible. Reflow should not move when the panel is dragged.
7. **B6/B7 regressions:** Retry dense painted racks, repeated resizing, stale worker proposals, holder return following split, zero/invalid radius, collision, and exact identity/lineage integrity.

**Known limits:** No Playwright/Chromium interaction run or native desktop test is claimed by this source change. The cell-depth control is an explicit interpretation of the requested depth UI and is open to further owner feedback. The finite reflow worker is not a mathematical packing oracle. All B7 gates remain subject to their existing test matrix.
