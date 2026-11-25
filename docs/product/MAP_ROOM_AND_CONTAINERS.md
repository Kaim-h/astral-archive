# Map Room and recursive container model

**Provenance:** Consolidated November 17, 2026 project decisions; see the [research index](../research/README.md). Older prototypes may contain superseded material.

**Status:** approved product direction consolidated from the November 17 handoff. The wider Map Room is not implemented; B6 through B7-N2 supply an isolated synthetic recursive cubby study with mixed fixtures and universal Case transport. Higher-level Shelf/Room/Map Room implementation and real directory binding remain future work. See current state.

## Normal hierarchy

```text
Map Room                         expanding, top-down user-authored floorplan
├── The Main Hall                suggested starter-room name; renameable
│   ├── Shelf A                   one screen of coherent modular furniture
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
- A Room opens to one screen of orderly shelves, not an endless list of floating cards.
- A Shelf opens to one screen of aligned, plausible furniture and cubbies.
- **Cubby is the single modular core container type.** “Rack” generally means a fixture, divider scheme or visual configuration inside a cubby, not a parallel container hierarchy.
- A Cubby may contain mixed fixtures and recursively nested cubbies.
- Nested cubbies bound to actual directories represent filesystem subdirectories. The model must still distinguish real directory identity, virtual visual organization and visual placement.
- Divider cells in a scroll rack are physical partitions, **not filesystem directories**.
- Files / books may be left loose in an appropriate parent view when intentionally uncontained; this is an exception, not permission to scatter floating UI objects.

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
