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

## November 25 — generalized Advanced and Secrets interface

Owner-confirmed design direction (not implemented by this documentation change):

- Every customizable object or environment offers an Advanced customization entry. Ordinary advanced settings are not inherently secrets. Keep a distinct **Secrets** heading and divider within Advanced wherever discovery-associated options apply, including after discovery.
- Below Secrets, present discovered options normally and a generalized **View undiscovered options** action when relevant discoveries remain. The same warning applies across all discovery families. Viewing and using undiscovered options must not mark the discovery as found, prevent its later in-world reveal, or require a puzzle.
- Suggested shared warning, retained from the November 17 ideation: “I won't stop you from adjusting these settings. They are yours, after all. But if you possess even the slightest sense of adventure, you should know that some of them can be discovered within the Archive itself.” Exact copy and dialog design remain candidates. Use a clear continuation action and a way back.
- The owner favors enduring decorative triggers that are not necessarily tied to one physical location: for example, a recognizable decorative book that appears intermittently on different shelves, or a mark that persists across architectural Shelves. Discovery must not become unavailable through deleting, rearranging, recoloring or resizing user furniture.
- The Cabinetmaker hallmark concealed among the existing lintel diamonds is the preferred trigger direction for the next Shelf experiment: ordinary diamonds all receive a small internal engraving, while a slightly different inner shape identifies the actual mark. A separate conspicuous icon is unnecessary. The specific shape, location policy and activation gesture remain experimental.

### Shared behavior and placement candidates

A registry keyed by discovery identity can associate customization option IDs, eligible surfaces, placement policy, trigger interaction and optional reveal. Treat discovery state, manual disclosure and actual setting values as distinct. Archive-wide discovery with per-object customization is the proposed model; exact persistence, per-secret disclosure scope and reset/replay controls still require review. A centralized discovery list is a possible ordinary access path, not a requirement to complete a collection.

Four useful placement patterns: distributed architectural details, recurring/wandering decorative objects, fixed interface fittings, and contextual/conditional details. Do not insert triggers at the expense of real files or app books, alter normal launch/file actions, reshuffle user layouts, obscure essential controls, move a trigger during interaction, or introduce long waits. Use free suitable space, predictable reappearance and accessible direct settings. Once found, retaining a trigger as a workshop shortcut is a candidate. No trigger depends on network availability or secrecy of public source. Provide keyboard access and reduced-motion alternatives.

### Candidate mechanisms — exploration, not authorized implementation

| Discovery | Candidate placement and interaction | Design distinction and constraints |
|---|---|---|
| Cabinetmaker's Tools | Distributed anomalous lintel diamond on each architectural Shelf; press or slide a small inlaid piece. Ordinary inner diamonds and one subtly asymmetric inner hallmark. | Stable relative position per Shelf when feasible; provide fallback if an architectural profile lacks usable diamonds. Same monochrome palette, no persistent highlight. Backing-panel layout, fine borders, secondary emblems, glazing and furniture trim are candidate secret options; ordinary geometry stays available. |
| Bookbinder's Workshop | Recurring distinctive Archive-owned decorative book among application books; pull it forward or open its clasp. | Preserve fixed book-size rules and actual application identities. Appears only in a suitable free position, not by replacing or moving real books. A recurring visitor rather than a permanent oddity. No time-based hard gate. Book color stays ordinary. |
| Sealmaker's Cabinet | A wandering Archive-owned scroll with an unusual seal, or an occasional decorative seal matrix in a free cubby position. Lift the seal or press its impression into a small wax medallion. | Do not masquerade as indexed data, become an ordinary file owner, consume rack capacity by surprise, or modify actual scroll sizes/physics. Separate decorative trigger from file/Case records. |
| Forgotten Cartographer | Map Room compass bezel with a subtly interrupted graduation; rotate an ornamental ring until two witness marks align, revealing a survey layer. | Fixed map-frame fitting, not a requirement for map navigation. Candidate scope includes contour background, map engraving and optional compass decorations; map geometry stays unaffected. Exact Map Room structure is future research. |
| Celestial Cartographer | Gallery-owned star chart on a frame margin; connect a small, incomplete constellation or slide a chart overlay into alignment. | Use a dedicated chart ornament so artwork selection and sky controls do not change unexpectedly. Reuse shared future constellation definitions rather than invent a second editor. Gallery placement versus earlier observatory placement remains a candidate. |
| Clockmaker's Secret | Capsule clock surround with a tiny independent winding key or a misaligned graduation; rotate a decorative collar into alignment. | Existing ClockDisplay is digital, not an analog clock face; do not assume a bezel or lunar dial already exists. Never alter system time, the clock readout, Capsule controls or require a particular hour. |
| Astronomer's Instruments | A small engraved optical fitting on the observatory housing; slide a decorative shutter or rotate a collar to expose a reticle. | Separate hit target from existing dome/telescope selection. No changes to approved telescope geometry, dome occlusion, motion or actual optical behavior. |
| Archivist's Personal Collection (larger candidate) | Optional Marginalia record collecting symbols or short notes found through the above interactions; a concealed study might be discoverable later. | No mandatory sequence, collection gate or inaccessible settings. Not part of current B8 scope. |

The shared mechanisms should feel like different acts of craftsmanship (pulling, pressing, sealing, aligning, tracing, winding) rather than identical hidden buttons. Candidate drawings, hit areas, animation timing, recurrence scheduling, discoverability and persistence remain unverified. The decorative object's presentation identity is separate from actual files, app launchers and physical inventory. All discoveries remain optional. Do not implement full secret-system infrastructure merely to complete a Shelf interaction study.


## November 25 — further discovery review

The following discussion supersedes the corresponding trigger examples above as current research direction, not as authorization to implement native features.

- Cabinetmaker: the first asymmetric hallmark illustration was too obvious. Keep the same outer diamond, color, stroke weight and approximate inner size; introduce only a small geometrical asymmetry in one inner engraving. Assess at actual display scale, not solely magnified.
- Sealmaker: owner proposed clarifying the action as a recurring decorative stamp, selecting a scroll to pin its metadata tooltip, and dragging the stamp over the seal in that tooltip. Candidate interaction: an eligible scroll's decorative wax seal acts as the target; no second rare object required. Pinned tooltip must remain open during the drag and have an accessible equivalent. Reveal applies only to presentation/discovery state, never file contents, metadata, ownership or physics. Exact stamp placement, tooltip target and gestures await review.
- Formerly Forgotten Cartographer: owner likes compass alignment but wants a distinct name to avoid overlap with Celestial Cartographer. **Surveyor's Table** is the suggested replacement, not a finalized name. Focus on terrestrial mapping, floorplan engraving and contour-field appearance.
- Celestial Cartographer: owner proposes placing small engraved decorative symbols on the telescope itself. Prolonged hover produces restrained illumination; click the revealed symbol to discover the shared constellation maker. Keep actual telescope geometry, dome occlusion, motion and existing selection behavior unchanged. Focus-based equivalent, modest dwell, no mandatory wait through ordinary settings, and no persistent glow before activation. Exact symbols, hit targets, timing and reveal remain candidates.
- Astronomer's Instruments: owner suggests cutting the separate discovery; recommend retiring it from the active candidate set because of overlap with the telescope-based Celestial Cartographer. Preserve historical notes; any useful reticle/optical appearance options can remain ordinary Advanced customization if separately approved. No existing functionality is removed by this documentation.
- Clockmaker: owner requests more ideation. A candidate alternative to an exposed winding key is a barely noticeable seam in the digital Capsule clock surround, revealing a tiny concealed mechanical movement when deliberately opened; turning a gear or winding wheel reveals the workshop. No modification of system time, digit accuracy or existing Capsule controls. No required real-world time. The secret's meaningful customization scope (typography-adjacent ornament, mechanical display treatments, optional lunar/astronomical detail) must be clarified before committing to a mechanism.

All shared Advanced/Secrets, manual disclosure, persistent discovery and accessibility principles remain intact. These are design discussion records; no prototype, runtime or test changes.

## Distribution and showcase principles

A future authentic native desktop showcase is separate from a publicly installable release. A release requires reproducible setup, supported version declarations, dependency checks, permissions / licensing review, private-data audit, rollback guidance, native validation and clear implementation status. Do not describe browser prototypes as running Fedora / Hyprland. Repository visibility and public distribution require separate explicit owner approval.
