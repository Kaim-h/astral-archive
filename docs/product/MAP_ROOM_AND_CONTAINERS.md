# Map Room and recursive container model

**S20 current design:** [B8 spatial Archive contract](B8_SPATIAL_ARCHIVE.md) governs conflicting B8 directions below. Map is strictly top-down; Room has plan and centered perspective; Shelf is first frontal level. B8 Room furniture is Shelf-only. Optional aligned shared doorways, direct focus and assisted arrangement, valid implicit commit and geometry-aware navigation supersede earlier proposed controls and timing. Older dated material remains provenance; B9 furniture and irregular architecture deferred. Existing identity, support and file safety contracts remain.

**Provenance:** Consolidated November 17, 2026 project decisions; see the [research index](../research/README.md). Older prototypes may contain superseded material.

**Status:** approved product direction consolidated from the November 17 handoff. The wider Map Room is not implemented; B6 through B7-N2 supply an isolated synthetic recursive cubby study with mixed fixtures and universal Case transport. Higher-level Shelf/Room/Map Room implementation and real directory binding remain future work. See current state.

## Normal hierarchy

```text
Map Room                         expanding, top-down user-authored floorplan
├── The Main Hall                top-down Room furnishing plan; renameable
│   ├── Shelf A                   first frontal inspection view of modular furniture
│   │   ├── Cubby 1               one unified configurable container type
│   │   │   ├── shelf fixtures    sculptures, shelved artwork, parcels, books, upright holders and display cradles
│   │   │   ├── divider cells     physical scroll-storage partitions
│   │   │   ├── upright holder    records, tablets and ledgers
│   │   │   ├── display backing   framed artwork / video / presentation
│   │   │   └── nested cubbies    recursively represent subdirectories
│   │   └── Cubby 2
│   └── Shelf B
└── Other user-created rooms
```

- Map Room is a user-authored top-down floorplan. Rooms can be moved, resized, recolored and renamed; the map may expand / pan / zoom as needed.
- A starter room is present. “The Main Hall” is a strong suggested default, not an immutable system term.
- A Room opens to a **top-down architectural furnishing plan** of Shelf footprints and other compatible Room-scale fixtures, not a frontal row of Shelf faces or floating cards.
- A Shelf opens to a frontal inspection view of aligned, plausible furniture and cubbies. This is the first ordinary level of full file representation; directly supported objects can be represented here without an additional Cubby.
- **Cubby is the single modular core container type.** “Rack” generally means a fixture, divider scheme or visual configuration inside a cubby, not a parallel container hierarchy.
- A Cubby may contain mixed fixtures and recursively nested cubbies.
- Nested cubbies bound to actual directories represent filesystem subdirectories. The model must still distinguish real directory identity, virtual visual organization and visual placement.
- Divider cells in a scroll rack are physical partitions, **not filesystem directories**.
- Files / books may be left loose in an appropriate representational parent view (Shelf or Cubby) when intentionally uncontained. Map and Room plans do not display loose file representations; do not scatter floating UI objects.

## Browse and Arrange

These modes are strictly separate:

- **Browse:** clicking a container enters it. File action details beyond explicit Open / Locate remain open for later design.
- **Arrange:** clicking a container selects it; it does not open, including double-click. Drag, resize, recolor, rename, edit fixtures / divider geometry and save.
- Navigation while arranging requires an explicit mode change or clearly separate navigation action.
- Every level should be customizable: position, name, dimensions, material / color and divider arrangement. Inherit-parent style may be offered, but independent color overrides remain possible.
- **Owner-confirmed:** snapping has an on/off toggle and customizable snap distance (grid interval); the displayed grid must use the same interval and cubby-local origin as the snapping calculation. Grid visibility remains independently toggleable. Camera zoom scales the grid visually, not its stored interval. Changing the interval does not move committed furniture. Apply to provisional furniture placement/movement/resizing, never to physics-driven scroll motion. Fixed board thickness and dimensional/collision constraints still take precedence. Optional edge-alignment capture tolerance is separate from grid spacing and not yet decided.
- Manual dimensions win. Content overflow should be explicit. A view/camera scale can help inspect a small cubby inside a fixed outer frame; do not silently resize the user's window or mutate stored furniture dimensions.

## Navigation and creation

- Routine navigation uses a short, understated fade / crossfade (approximately 180–250 ms is a suggested direction, not a hard timing contract).
- The outer window/frame stays fixed. The opened container face/view may be uniformly scaled for comfortable inspection while retaining its own shape, divider and fixture arrangement.
- Context-sensitive creation: Map → Room; Room → Shelf; Shelf → Cubby or compatible fixtures; Cubby → nested cubby / divider / fixture. The higher-level Shelf direction is described below; exact controls remain subject to B8 design acceptance.
- Inside a cubby, physical “Divide Space” must be distinct from creating a real filesystem folder and from creating a virtual cubby.
- Real disk operations must be explicit and clearly labelled. Purely visual arrangement must never silently move, rename or delete files.

## Superseded prototype guidance

Map Room v1 was useful as a navigation outline. Map Room v2 explored themes, grid / snap, recursion and symbolic file objects, but its scattered furniture and unsupported floating objects were rejected. Do not port v1/v2 layouts as the future visual blueprint. The accepted product requirements and accepted design references take precedence; no private sketch or handoff is required to interpret this specification.

## Engineering questions still open

Exact persisted data model, filesystem / virtual placement mapping, import roots and symlink policy, state reconciliation, container dimensions, room map connections, divider editor details and the first native delivery scope need deliberate design. The older Python daemon / SQLite schemas and proposed filenames are recommendations only, not already-selected architecture.

## Shelf fixture versus Shelf navigation level

A shelf board is a horizontal support surface inside a cubby, distinct from the higher-level Shelf view. All ordinary objects and holder/display subfixtures rest on a board, except independent racks/cubbies and wall-mounted artwork. See [physical fixtures](PHYSICAL_FIXTURES_AND_SCROLL_BEHAVIOR.md). Explicit removal sends affected file identities to the Scroll Case as portable scrolls, recursively and atomically; no disk deletion.

## Owner-confirmed contextual customization (November 24)

Customization controls are transient right-click context menus, expandable submenus or short-lived inspectors, not permanently visible adjustment rails. Target-specific actions: empty interior (add fixtures, appearance, grid/snap), frame (name, dimensions, material), shelf/rack/cell (appropriate geometry, color, removal), file (metadata/representation/actions). Respect Browse/Arrange boundaries; structural changes need an explicit Arrange transition and provisional Apply/Cancel; complex rack overflow can use a temporary inspector until resolved. Provide keyboard-accessible equivalents; close/dismiss on Escape, outside click when safe, and context change. Preserve pending edits until explicit Apply/Cancel; do not silently apply on dismissal. Current study toolbars/panels are developmental scaffolding, not final interaction design.

Room and higher-level Shelf character with coherent shared motif is a supported direction under discussion, not a finalized ornament catalog. See vision/design language. Distinguish architectural Shelf from shelf board fixtures.

## Owner-confirmed cubby sizing priority

Growth is the common case: interior width/height may increase independently of a nested cubby's parent footprint, retaining furniture dimensions, positions, identities and contents. A proportions lock is optional and explicit. Shrink must preserve furniture; block an invalid reduction with a minimum-size explanation. A separately previewed suggested rearrangement is approved as a later option, not automatic repositioning or scaling. No proportional furniture resizing without a future decision. Fixed window, uniformly fitted inspection view, explicit Apply/Cancel and Undo; no actual file operation.

## Later B8 design direction — not implemented

The accepted direction is a higher-order recursive Shelf containing compatible mixed furniture and supported representations directly, not only named cubbies. Suitable module tops may act as support surfaces where clearance permits; ornament is primarily additive outside the usable rectangular envelope. Manual dimensions remain authoritative, with any expansion explicitly previewed. Exact support eligibility, dependent movement/resize/removal, contact and clearance rules, and final visual treatment remain open for the separate B8 design handoff. These are not claims of completed B8 implementation or approval of a specific prototype. The existing B7 cubby board-support contract remains the implemented baseline; broader support generalization requires review.

## November 25 — owner-confirmed plan / inspection distinction

Both Map Room and Room are top-down architectural drawings. The Map Room organizes Rooms; a Room organizes Shelf footprints, orientation and Room-scale furnishing. Shelf is the first frontal inspection level. Cubby or compatible fixtures expose detailed representations and file interaction. Two plan levels before direct file representation are intentional. No forced miniature file thumbnails or floating objects at the upper levels. Existing direct Shelf representations remain valid. Search/Open/Locate shortcuts, summary previews and navigation details remain separate design work; do not make them prerequisites for testing plan geometry.

Room-plan width and depth are distinct axes from Shelf frontal width and height. A plan footprint has position and facing direction; changing plan depth is not changing frontal height. Exact footprint-width reconciliation with a populated Shelf, including occupied bounds and expansion/shrink, needs a shared contract before runtime integration. Never silently scale or discard nested content. The S12 browser study deliberately uses empty synthetic footprints and a rectangular Room, quarter-turn rotations, collision and wall-boundary checks, relative drag increments and exact numeric entry independent of snapping. It is not an implementation specification for irregular walls, door clearance, aisle constraints or production placement. See the [B8 research record](../research/prototypes/2026-11-24/b8/README.md). Tooltips, selection-driven navigation, contents and persistence are intentionally deferred in this study.

## November 25 — mixed Room furniture and reading-table direction

Owner accepted the S12r1 rotation correction and authorized S13 mixed Room furniture research. A Room may contain non-Shelf fixtures; not every furnishing is a recursive storage container. Candidate roles: reading table (temporary presentation), display cabinet (curated storage/display), chest of drawers (alternative storage), writing desk (documents/journal), surveying table (map tools/puzzle box), pedestal (individual display), bench and column (decoration), and rug (floor decoration). Exact contents and interactions remain future study, not implementation requirements.

Owner specifically identifies reading tables as a place to inspect files already in the Scroll Case. Proposed contract: enter the table, select or carry a Case record into a temporary presentation, inspect its metadata/preferred representation and explicitly open when supported. Presentation does not transfer ownership, duplicate a file identity, consume another storage slot, change the file or remove the record from the Case; ending presentation leaves Case state intact. Reuse the B7 representation and ownership contracts. Comparison and representation editing are later candidates, not approved native scope. Room plans remain architectural footprints; entering a functional fixture may lead to its own inspection surface, without requiring an intervening Shelf. No actual table interaction in S13.

S13 tests solid footprint exclusion and a separate nonblocking rug layer. Rugs may underlie solids; rug-to-rug overlap and room-wall crossings are blocked. This is a reversible design experiment, not an accepted production floor-layer rule. No aisle/door clearance, layered storage, or native filesystem operations. See the B8 research record for exact artifacts and limits.
