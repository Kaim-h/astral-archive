# B6r12b3 — continuous resize preview

> Historical research record. PR, CI, artifact and commit identifiers refer to earlier development history, not current repository PRs or newly executed checks.

Owner feedback: B6r12b2 is satisfactory except for a brief flashback to original size while resizing. The next milestone would restore other objects (B7); owner asked whether a QML checkpoint first would be preferable.

## Correction

The B6r12b2 projection used committed dimensions whenever a new shape cleared the previous worker result. B6r12b3 always renders the latest finite, bounded proposed geometry immediately, even while the worker is debounced or running. A malformed numeric input keeps the last drawable shape with invalid status, not a dangerous lattice. Geometry-valid but overlapping modules remain visibly invalid and cannot Apply. Preserve cell pigment and stable keys where present, give new display-only keys temporary metadata (no allocator changes), and cheaply translate only original groups that fit without overlap. Unsuitable groups show amber waiting counts until a valid solve or red resolution state. Exact solved coordinates remain worker-owned and revision-checked. Case staging, unresolved records and displayed scrolls still partition the original IDs. Include x/y in planner cache keys so exact no-op and movement cannot be confused. No native code is changed.

## Verification boundary

B6r12b2 CI 45391051001 (historical `actions/runs/45391051001`) passed inherited and split-preview contracts. Its group test passed initial cross-cell group and rack-to-Case moves before timing out trying to click a pill that disappears on proximity expansion. B6r12b3's equivalent test enters the Case by the intended hover interaction, then continues the original checks. This is not a claim that group return or all remaining tests passed. The new resize test checks synchronous dimensions and radius across rapid edits, actual input handlers, no lost/duplicated records, no allocation, invalid numeric fallback, worker handoff and Cancel. See actual CI for results.

## Suggested continuation (proposal, not approved implementation)

Freeze the corrected B6 behavior, close blocking interaction tests and keep the HTML as a reference. Before adding other object families, extract the DOM-free geometry/identity/transaction/packing logic into a testable JS core. Build an isolated Qt Quick test window under the existing native test convention with fake records, shared theme tokens, a clipped recursive Cubby scene, visible rack and scroll endpoints, a real case, browse/arrange gestures and the same latest-revision draft state. Run a bounded fixed-step solver only on active cells; use a WorkerScript or another measured Qt-compatible isolated planner if necessary. Validate with actual Qt/Quickshell versions and target Wayland session, preserving KDE recovery and existing desktop panels. Compare the browser reference and native results before adding shelf/books and other object families to the native study in B7. Do not port browser DOM or localStorage verbatim, add filesystem writes, or attach the unfinished panel to the production shell. Native first is a proposed sequence for owner approval, not a claim that native development has begun.
