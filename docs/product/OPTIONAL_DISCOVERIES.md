# Optional discoveries and hidden customizations

**Provenance:** Consolidated November 17, 2026 project decisions; see the [research index](../research/README.md). Older prototypes may contain superseded material.

**Status:** candidate backlog, not implemented scope and not a mandatory progression system. This document consolidates the November 17 historical “Secrets & Distribution Notes” and the cross-platform handoff. Candidate ideas require owner review before implementation.

## Principles

- Hidden mechanisms and discoveries may add personality, especially the “secrets behind the bookshelf” motif.
- Discovery is optional. Every setting remains available through ordinary settings, potentially under Advanced → Secrets & Discoveries.
- Users may enable an option through settings and still experience its discovery animation later.
- Discovery state and the setting value are separate persistent concepts.
- Core controls (themes, accessibility, file actions, application controls, book color) stay ordinary and visible. Book cover/spine embellishments may be a candidate discovery; book coloring is not hidden.
- Never gate critical functionality behind puzzles or source-code archaeology.
- A special trigger must be an Archive-owned decorative object, never a real application book or user file repurposed without clear indication.
- Keep animations short, reversible, interruptible, reduce-motion-aware and quiet. Lore is optional.

## Candidate discoveries

| Candidate | Possible customization | Possible in-world trigger | Status |
|---|---|---|---|
| Celestial Cartographer | Per-artwork constellation / procedural sky controls | Subtle chartmaker dial / chart in the observatory | Candidate; current Gallery editor is source code, but this discovery mechanism is not implemented |
| Bookbinder's Workshop | Embossing, borders, clasps, metallic inlays, engraving, ribbon / cover embellishments | Distinct Archive-owned decorative book reveals a workshop | Candidate |
| Sealmaker's Cabinet | Wax seals, parchment edges, bindings and per-file ornamental marks | Peculiarly sealed decorative scroll | Candidate |
| Cabinetmaker's Tools | Cubby divider profiles, corner fittings, nameplates and trims | False-bottom drawer / joinery clue | Candidate |
| Forgotten Cartographer | Map engraving, borders, compass marks and optional connectors | Discreet map compass | Candidate |
| Clockmaker's Secret | Alternate clock faces, lunar details and small mechanical displays | Small Capsule clock detail | Candidate |
| Astronomer's Instruments | Subtle reticles and instrument markings | Engraved adjustment scale | Candidate; must not alter approved telescope geometry / dome occlusion |

A larger Archivist's Personal Collection / Marginalia journal / concealed study is a candidate idea only.

## Distribution and showcase principles

A future authentic native desktop showcase is separate from a publicly installable release. A release requires reproducible setup, supported version declarations, dependency checks, permissions / licensing review, private-data audit, rollback guidance, native validation and clear implementation status. Do not describe browser prototypes as running Fedora / Hyprland. Repository visibility and public distribution require separate explicit owner approval.
