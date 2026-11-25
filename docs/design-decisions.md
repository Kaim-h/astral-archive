# Design decisions — Astral Archive

Record decisions that should survive between batches. Mark experiments as
proposals rather than silently treating them as implemented requirements.

## Visual language

- **Illustrated 2D at rest** for the entire desktop; consistent dimensionality
  for books, shelves, bar, Observatory and utility relics.
- Temporary dimensional animation is a possible later enhancement. The forward
  book-tip experiment is **deferred until native Quickshell testing**.
- Preserve theme palettes: Evening (`#343c43` background), Twilight
  (`#121e23`) and Midnight (`#080f10`) with their associated panel, metal,
  engraving and text colors in `themes/Theme.qml`.
- The Archive is useful first: responsive, keyboard-accessible and legible,
  with tactile exploration as an optional pleasure rather than forced friction.

## Launcher and books

- A **book is an application**, not a directory, document or folder.
- A **folder is a container**: rack, cubby/group or larger library section.
  Never substitute an ordinary book for a folder.
- Spines are compact, usually about 42 px wide and 90–160 px tall, with
  **2 px spacing** between books. Supports alternate title orientation,
  inscriptions, engraved bands, static ornaments and decorative ribbon.
- `spineLabel` can abbreviate the visible title; the full application name
  remains searchable.
- Default room is conservative: a few curated books on two shelves; Index
  accesses the wider application catalogue. Expand with actual need.
- The launcher floats rather than covering the full screen.
- The Index is a special reference book fixed to the lower-right.
- The Index receives keyboard focus on opening. Navigating with arrows changes
  a highlighted book without moving actual keyboard focus from Index input.
- Activation is immediate; do not delay application launch for an animation.
- Ribbon states indicate running/focused desktop application. Keyboard
  selection and mouse hover are visually distinguishable from those states.
- One book means one app even if it has multiple windows. A normal activation
  selects the most recently observed window; a secondary action lists them.

## Scroll racks — future expansion, not v1

- Files appear as **scrolls viewed end-on**, packed densely in user-defined
  racks/cubbies. No individual showcase compartments for each scroll.
- Scrolls have varied radii based on compressed/logarithmic file-size tiers
  (roughly four or five), with slight aesthetic variation.
- Placement should look natural/haphazard, **Suika-like circle packing**, but
  the settled result must be saved and deterministic between launches.
- **No scroll pull-out on hover.** Scroll stays in place; a tooltip shows
  seal/icon, filename, description and useful metadata. Activation opens file
  with its native application or enters the target container.
- The wax seal may be a tooltip detail rather than visibly decorating every
  stored scroll.
- `Browse` mode is static and quick; `Arrange` mode lets the user move/resize
  cubbies and reassign scrolls, then settle/save positions. No perpetual
  simulation; manual pinning may be useful.
- Physically rearranging scrolls/cubbies must **never silently move disk files**.
  A real filesystem move is a separate explicit operation.

## Map Room — future expansion

- A distinct **top-down, user-authored library floorplan**, not an abstract
  directory tree. It may grow to any useful size.
- Each customizable rectangle represents a screen-sized shelf/rack/section;
  its position, name, dimensions and color can be changed.
- Navigation and filesystem identity are distinct. A folder may be represented
  by one cubby, several cubbies, a rack or an entire screen.
- The future global Index finds apps/files/containers fast but preserves the
  spatial metaphor: **highlight the destination screen on the Map Room first**,
  then highlight the exact item after entering that screen. Keep highlighting
  visible at the destination. "Locate" and "Open" may coexist.

## Integration boundaries

- Use Quickshell APIs and mature Linux services for backend functionality.
  Adapt permissibly licensed existing code only when useful; document licenses.
- Hyprland handles windows, tiling and workspaces; we configure it rather than
  replacing the compositor.
- KDE remains a fallback while Hyprland and Quickshell are under development.
- Visual experiments do not count as integration tests. Native desktop validation remains outstanding.

## Compact desktop controls — revised Batch 7

- No permanent, mostly-empty full-width bar. Use a small illustrated floating
  capsule, sized only for its library emblem, current workspace, clock and
  theme glyph. It sits above standard windows and reserves no tiling space.
- The library control reveals **two shelves** in a popup: one for pinned
  installed applications, the other for running applications that are NOT
  pinned. A pinned running app appears only once and keeps its running ribbon.
- Reuse `Shelf.qml` and `Book.qml` rather than rendering an unrelated strip of
  generic application buttons.
- Default to click-to-open; optional hover-to-open is a native-testing
  experiment, with grace-period closing to avoid pointer-gap flicker.
- A popup offers keyboard selection and access to the full floating Index.
  The larger launcher remains independently summonable with its hotkey.
- Hyprland remains in charge of tiling, and the capsule/popup must never be
  part of the wallpaper layer where ordinary application windows cover them.
- No permanent full-width panel should be launched as part of Batch 7.

## November 24 — B7 visual baselines and implementation boundaries

- Owner accepted moving on from R3 artwork, S11 sculpture, U3 upright objects and P10 parcel studies. See [B7 index](research/prototypes/2026-11-24/README.md) and [asset contract](product/REPRESENTATION_ASSETS.md). These are visual directions, not target runtime acceptance.
- Keep the established illustrated 2D language: coherent contact, perspective where used, and material-specific shading. P3's sparse pictograms and P7's gourd-like sack ribs were rejected. Prefer focused art changes over UI rewrites.
- U3 holder uses unified click/present and drag/reorder (no special drag mode inside the holder); container Browse/Arrange separation remains a separate requirement.
- **Decided (owner, November 24):** leave scientific instruments out of B7 implementation and automatic representation. Use format-based mapping with scroll fallback. Preserve [B7p4 instrument design](research/prototypes/2026-11-24/Astral_Archive_Parcel_Instrument_Study_B7p4.html) as historical design evidence; no decorative implementation authorized.
- **Owner-directed development rule:** one continuing branch and PR per coherent active topic, including revisions and related documentation. See [topic workflow](development/TOPIC_WORKFLOW_AND_HANDOFF.md).

## November 24 — owner decisions: shelf and Case

- Shelf is the general-purpose horizontal support for all ordinary file representations and holders/cradles, including books, sculptures (optional plinth), shelved art, parcels and upright-holder displays; independent racks, nested cubbies and wall-mounted art are exceptions. See [physical fixture contract](product/PHYSICAL_FIXTURES_AND_SCROLL_BEHAVIOR.md).
- Every carried file appears as a scroll in the Case irrespective of normal art; preserve stable identity, preferred family/variant, metadata and provenance. Confirmed fixture/subtree deletion evacuates contents atomically to Case, marks deleted origin stale and supports exact Undo; no disk deletion. N3r1 rack records and empty boards first, B7 general ownership and conversion later.

## November 24 — B7-N2 owner interaction decisions

- Automatic rack compaction: dropping any compatible file identity into a valid scroll cell uses a scroll form, without setting its explicit compact preference or changing its preferred family/variant. Restore preferred representation at a compatible non-rack fixture; explicit compact preference remains a separate choice.
- Hybrid transport: local direct movement within a cubby; use the universal Scroll Case between cubbies. Cradle presentation is not an additional owner. Invalid drop changes nothing.
- Occupied shelf shrink: block invalid placement, offer conservative explicit rearrangement preview; preserve existing positions where possible, no silent scale changes, compaction or evacuation. Cancel and exact Undo required.
- B7-N2 four checkpoints: ownership/validation, mixed scene and occupied arrangement, universal transfers/checkpoint compatibility, final actual verification. No new art, automatic persistence, Map Room, application identity conversion or real file operations.
