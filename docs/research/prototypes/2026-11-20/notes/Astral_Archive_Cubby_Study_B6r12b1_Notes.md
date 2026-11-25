# B6r12b1 — owner-feedback correction

**Status:** separate standalone research revision on the existing PR #7 branch; B6r12b remains intact. No B7/native acceptance.

## Reproduction and fixes

- The original B6r12b Code sample at radius 52 has a twelve-scroll unresolved cell. In local Chromium, its unresolved glyphs vanished, the pending replan briefly displayed the old committed rack again, the destination selectors disappeared while planning, and the case count stayed at zero even with a ready case-overflow proposal. This demonstrates inconsistent preview presentation; it does not prove that committed records were duplicated.
- B6r12b1 derives a single provisional partition: physically placed rack records, explicitly staged case records, and unresolved records. The last valid geometry remains displayed during same-shape worker revisions; new case choices immediately remove the corresponding glyph from the rack projection and appear in the case with an asterisk and pending status. Unresolved records receive a count marker and retain individual assignment controls rather than being drawn at invalid positions. Revoking a choice removes it from the staged case; Cancel clears all staging; Apply verifies the projection and the authoritative ownership transaction. A worker failure does not silently delete or commit anything.
- The compact adjustment panel shows one issue at a time (choose another from the cell selector or click the marked cell), scrollable per-file choices, a tiny rack-picker button, abbreviated status, conditional radius warning and sticky actions. The file metadata tooltip also has a smaller hover and expanded footprint; full metadata remains accessible.
- In-cell motion no longer treats the Scroll Case approach halo as a physical drop target. Pointer capture, grab offset, wall-projected spring target, a faster held-body speed cap, and a short bounded release-followthrough improve quick gestures. Lost capture/focus safely cancels. Only affected cells wake; idle cells still sleep. This addresses specific routing and short-gesture weaknesses, not every possible intermittent report.
- The B6r12b1 checkpoint has its own key and can read an existing B6r12b checkpoint when the browser exposes it; it never writes the predecessor key.

## Tests

The original B6r12b test suite remains unchanged. A successor copy exercises the same browser contract against B6r12b1, plus a focused regression test uses the actual radius-52 sample, real per-scroll selectors, same-task pending view assertions, rapid consecutive choices, revocation, Apply/Undo/Cancel, compact panel bounds at 1366×768 and 1024×600, fast drag activation and case approach-halo isolation. The source check compiles the new script. Consult CI results rather than treating test presence as a pass. Owner interaction/visual acceptance and the wider B7 matrix remain separate.
