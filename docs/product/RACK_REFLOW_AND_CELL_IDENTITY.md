# Identity-preserving hex rack reflow and painted cells

**Status:** user-directed constraints and research direction, based on the November 20 proposal and later B6r3 notes. **Not implemented in native Quickshell; not a certified algorithm.** For chronology and testing see [B6 research status](../development/B6_RESEARCH_STATUS_2026-11-23.md).

## Identity model

- `rackId`: stable physical rack fixture with location, dimensions and hex radius (prototype standard radius 64).
- `gridKey`: temporary lattice row/column. It is **not** a persistent ID.
- `cellId`: unique stable identity for a physical cell, with optional inherited wall pigment, membership and split ancestry.
- **f-cell:** a populated cell whose grouping has been manually arranged or established and should remain intact unless the owner explicitly permits otherwise.
- `scrollId`: unique file/object identity; across rack cells plus portable holder it must occur **exactly once**.
- `holderOrigin`: original cubby, rack and stable cell, including provenance to resolve splits; not a stale grid key.
- `camera`: view-only transform. Zoom/viewport changes never regenerate physical cell size or scroll identity.

## Reflow contract

1. Validate finite positive bounded radius, rack width and height **before** tessellation. Empty numeric input is incomplete, not a valid zero radius. Bound lattice counts, iterations, worker time and total proposal cost.
2. Preview the proposed rack as one attached ghost: outer frame, real clipped cells, seams and independent wall paint, labels and scrolls all under the same geometry/camera transform. Distinguish valid, invalid, computing and attention states.
3. Preserve whole populated f-cells preferentially. Their relative rack position, neighbor relationships, content identity and visual grouping matter more than minimizing one large group's travel at the expense of others. B6r3 trials used global minimum-cost bipartite matching rather than B6r2's greedy first-fit; optimizer remains replaceable.
4. **Re-settle every preserved group** into its new physical cell, even when translated scroll coordinates are non-overlapping. Check gravity support, polygon insets and overlap tolerances; never leave floating piles by skipping settling.
5. If intact assignment is infeasible, **do not split automatically**. In the B6r3 study each affected stable cell requires explicit consent specific to the proposed dimensions; Apply remains blocked until resolved. Users can revoke consent; changes in proposal dimensions invalidate it. A future refinement might allow direct choice of successor hex destinations.
6. Only empty successor cells may receive an authorized split, preferably a small connected cluster. Do not steal other populated groups as overflow. A source cell ID can survive in **at most one** successor, other successors get fresh IDs with explicit `splitFromId` lineage. Wall paint and file origins must remain traceable.
7. Preserve empty **painted** cell identities near their old positions when successor capacity permits. Populated identities take precedence; document loss of empty paint due to a physically smaller rack.
8. Treat proposal generation as read-only: no advancement of persistent `state.next`, no changes to Undo stacks, scrolls or holder inventory. Apply must validate the *latest* proposal and atomically commit; Cancel restores the complete pre-preview snapshot and Undo reverses the whole accepted operation.
9. Verify global invariants: unique IDs, identical multiset of scroll IDs, no uncontained circles, no invalid overlaps, no structural collision, consistent cell/split/holder provenance and no unintended filesystem action.
10. If a bounded heuristic cannot find a layout, report **search budget exhausted or no feasible plan found**, not proven physical impossibility. Provide counts of kept, moved, split, unplaced and requiring consent.

## Status of B6r3 experiment

The reported 38-scroll/10-group radius sweep reduced unnecessary group relocation and implemented explicit split permission. It does not settle the problem of manual successor choice, repeated chains, dense painted cells or production `cellMeta` lineage. A native geometry solver, persistence schema and host integration remain separate work.

The original B6 failure catalogue, test results and source files remain preserved by reference rather than rewriting their historical status.
