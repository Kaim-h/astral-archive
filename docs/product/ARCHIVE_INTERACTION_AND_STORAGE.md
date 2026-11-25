# Archive cubby and furniture interaction — research contract

**Provenance:** November 20 proposed overlay, B1–B6r3 browser studies, older November 17 handoff. This supplements the approved [Map Room / containers](MAP_ROOM_AND_CONTAINERS.md) and [physical fixtures](PHYSICAL_FIXTURES_AND_SCROLL_BEHAVIOR.md) documents. **This is a design/research direction, not native Quickshell implementation.**

## Storage grammar

- Map Room → Room → architectural shelf/section → unified, recursively nestable **Cubby**. Racks and shelves are *fixtures*; individual hex cells are not directories. Filesystem identity and visual placement remain distinct.
- Newly created cubby starts as a plain empty rectangular box with recessed, theme-aware backing, a modest frame/border and a small bottom nameplate. Do not automatically fill it with shelves or rows. Furnished code and application cubbies are sample presets.
- Modules include a single flat floating board/shelf, a shared pointy-top clipped-hex scroll rack (prototype radius 64) and a nested cubby with its own storage interior. Modules may be positioned, resized and individually colored but cannot clip real neighboring contents.
- Keep **three dimensions** distinct: cubby footprint in its parent, its own interior dimensions, and viewport camera transform. A tiny parent-view footprint can represent a large separately navigable interior; nested exterior previews may show veiled, inventory or closed representations, not full-resolution miniatures.
- Flat shelves carry their book/scroll-holder contents; the actual board and all contents occupy collision volume. The book bookmark is a restrained tab with a higher bend, not a protruding full book gimmick or 3D import.

## Modes and transactions

- **Browse / eye:** enter nested cubbies in the same viewport; Back/breadcrumb/Alt+Left; clicking a hex opens the active cell directly. Hover only reveals a tooltip; it never lifts files.
- **Build / hammer:** Add Module only in this mode. New modules appear on an independent provisional move/resize layer with grid/snapping, green valid / red invalid / amber calculating; confirm or cancel explicitly. Build-mode click never unexpectedly navigates into a cubby.
- Right-click cubby border for expansion, right-click physical hex wall for pigment; paint is navigational/personality decoration, not file security status.
- **Scroll movement:** distinguish a short click from dragging a scroll. Lift from source should let the source physics settle; dropping over its origin cancels exactly. Dropping over another cell stages that same object there for P2R insertion; neither a drag nor a hover silently saves a move. Multiple objects can remain in a portable holder while navigating.
- Undo and Cancel span source, destination, cell metadata and holder. Only a valid physically settled Save completes a transfer; no duplicate/lost scroll ID.
- Theme palettes inherit from `quickshell/themes/Theme.qml` (Evening, Twilight, Midnight); fixture pigment/custom colors remain distinct from metadata seal color.

## Engineering boundaries

Preserve existing Quickshell books, shelves and shared themes when porting. Browser successes are not proof of a native physics/Wayland backend. No visual repositioning may silently rename, move or delete real files. The full split/paint/persistence contract is [separate](RACK_REFLOW_AND_CELL_IDENTITY.md); pointer physics and insertion are [separate](SCROLL_PHYSICS_AND_INSERTION.md).
