# Physical fixtures, placement and scroll behavior

**Provenance:** Consolidated November 17, 2026 project decisions; see the [research index](../research/README.md). Older prototypes may contain superseded material.

**Status:** product requirements and prototype lessons from the November 17 cross-platform handoff. v5.4 is historical. B6r12b3 is the accepted scroll browser direction; B6 through B7-N2 are isolated native synthetic source. See [current state](../development/CURRENT_STATE.md) and [B7 asset contract](REPRESENTATION_ASSETS.md) for later evidence.

## Physical placement architecture

Keep these responsibilities separate:

1. **Object metadata / asset geometry:** illustration family, nominal dimensions, silhouette bounds, contact point, optional face / edge art, anchor points, collision proxy and render order.
2. **Fixture geometry:** shelf board, holder rails / slots, polygonal scroll cell, frame / backing, cubby subdivisions.
3. **Placement policy / solver:** resting on boards, occupying slots, staying inside scroll-cell polygons, attaching to plinth / backing and settling under gravity.
4. **Renderer:** consumes calculated transforms; it must not invent unrelated fixed pixel offsets to make each object appear to fit.

Debug view should be able to show collision bounds, support lines, contact points, cells and slots.

## Existing bookshelf baseline

Reuse `quickshell/widgets/Book.qml` and `quickshell/shelves/Shelf.qml` rather than drawing generic new book rectangles.

- Book spine width is about 42 px; height is clamped around 90–160 px.
- Books have covers, borders, inscriptions, etched bands / ornaments and contextual running / focused ribbons.
- The shelf row uses approximately 2 px book separation.
- Book bottoms align to the top of a 10 px physical shelf board.
- Do not remove bookmarks / ribbons or let books float above the board.

## Scroll cell geometry

- A rack contains connected tiled cells. Diamond / square / triangular / hex methods may be explored, but the cells must form a genuine shared tessellation, not independent polygons touching only at corners.
- Cell boundaries and scroll centers/radii must be validated. Scrolls remain within the cell polygon and do not overlap beyond the chosen tolerance.
- Scroll size uses roughly four or five logarithmic / compressed tiers based on file size, with slight repeatable variation.
- Scrolls remain quiet and settled in Browse mode. Hover alone does not pull an object out.
- An opened cell can respond to deliberate manipulation: select → explicit Lift → carry / choose target → Insert or Drop from top. Click + Lift exists in v5.4; drag-to-lift remains open for exploration.
- Opening a cell must not trigger a visible initial collapse. All cells should be pre-settled before the rack overview first appears.

## Void-based insertion and drop

- Insertion identifies actual connected empty regions bounded by scroll ends and/or the cell polygon, not random “fitting dots.”
- Hover subtly highlights the whole region. Click locks the selected region so it remains selected when the cursor moves to a control or screenshot / clip tool.
- Inserting into a currently smaller-than-scroll void is allowed as an attempt: neighbors may be displaced gently to create space.
- If the total capacity / achievable packing cannot accommodate the scroll, reject with a clear explanation and preserve the previous layout. Never lose, hide, silently relocate or shrink a file-object to make the operation appear successful.
- Drop from top is a distinct action: the object enters through an actual valid top opening, collides and settles. Reject if the opening is too narrow or the cell is full.

## Physics direction and v5.4 findings

A bounded position-based / constraint solver with gravity, wall projection, collision separation, friction and damping is a plausible prototype direction, not a selected production backend or physically rigorous rigid-body engine. Use fixed-step updates, finite iteration budgets, numerical guards, capped impulses, damping, stable state and deterministic behavior. Avoid converting large positional corrections directly into velocity.

The v5.4 browser prototype was reviewed positively (“much better”) for:

- pre-settling cells before display;
- connected tiled geometry;
- smoothed vector void contours / masking;
- click-to-lock void selection;
- gentle guided insertion (approximately 650 ms in that prototype);
- improved damping and undo;
- optional visual-only contact squash in the 0–3% range (default 1.5% in the prototype).

This is not final approval. The squash is a visual contact effect; collision geometry remains rigid. The browser prototype uses synthetic files and simplified methods. Native renderer / solver, geometry tolerances, performance budgets and persisted state remain open.

Only the active cell should animate. Other cells can be cached/static. “Continuous simulation” means the cell can respond immediately to interaction, not perpetual jitter. Offscreen and settled content should not burn CPU.

## Upright plate holder

Records, tablets and ledgers share one upright holder component with category-specific face / edge art and widths.

- Stored objects are tightly packed and primarily visible edge-on in actual supporting slots / rails.
- Clicking an edge selects a real stored item and presents that same item full-face separately off to the side.
- Do not draw a row of overlapped front-facing ellipses.
- B7u3 is the accepted browser baseline: full-face supported cradle, click presents, drag moves/swaps using a movement threshold, Escape cancels or returns. Rear rail aligned with blocks, smooth separators, dots centered below the lighter fascia bar, thicker record edges and generous hit areas. Keep slot identity and placement independent of presentation. Native event semantics and thresholds require verification; see the asset contract.

## Other object support

- Books rest on the board.
- Sculptures and parcels use fixture-specific contact anchors touching the shelf/plinth. Instruments are optional historical research, not an automatic implemented family. B7 assets have selection envelopes, not validated collision proxies.
- Framed artwork mounts to backing or rests against a panel.
- No object should float due to hardcoded y-offsets.
- The v2 Map Room and early file-representation playground contain rejected physical-layout regressions; preserve them as history, not as visual source of truth.

## Owner decision — general-purpose shelves and universal Scroll Case (November 24)

A shelf board is the general-purpose horizontal physical support for **everything except racks, nested cubbies and independently wall-mounted artwork**. Supported objects include sculpture/ceramics (optionally on a future plinth), shelved artwork, satchels/parcels (optionally in a tray), books, upright holders containing records/ledgers/font tablets, and their full-face display cradles. Plinths, trays, holders and cradles may themselves rest on the shelf. A holder is not an alternative to the supporting board. Shelf-board top is the support datum; derive all placement and collision/clearance envelopes from it. Shelf fixtures are distinct from the higher-level Shelf navigation screen and existing desktop app shelves. The board's browser baseline is minimum width 120, height 15 in study units; not immutable production pixels. Wall-mounted art has its own mount anchor, and racks/cubbies their own footprints. Mixed supported content and conservative occupied collision envelopes are implemented in the B7-N2 synthetic study; exact broader module-top support behavior remains B8 design work.

The Scroll Case is a universal portable file representation. A file travels as a scroll irrespective of normal filetype or preferred art. Stable file identity, metadata, preferred representation/variant and provenance must survive conversion; when inserted into a compatible fixture it resumes the appropriate representation, subject to explicit compact-scroll preference. Do not convert actual disk contents. On explicit deletion confirmation of any fixture or recursive cubby, preview the count of affected files, move all affected file identities to the Case atomically, mark deleted origins stale, and allow exact Undo of furniture, geometry, Case order and metadata. Cancel is nonmutating. Existing Case contents survive. No automatic deletion of real files. At the historical N3r1 checkpoint, evacuation covered rack scrolls and empty shelves only. B7-N2 subsequently implemented mixed fixture ownership, universal Case transfer, recursive evacuation and exact Undo in the isolated synthetic study; see [mixed cubbies](../development/B7_N2_MIXED_CUBBIES.md). Target desktop validation and production integration remain outstanding. App books remain application identities, not ordinary files; moving app-book shortcuts requires its own explicit model rather than silently turning apps into files.

## November 24 — B7-N2 owner interaction decisions

- Automatic rack compaction: dropping any compatible file identity into a valid scroll cell uses a scroll form, without setting its explicit compact preference or changing its preferred family/variant. Restore preferred representation at a compatible non-rack fixture; explicit compact preference remains a separate choice.
- Hybrid transport: local direct movement within a cubby; use the universal Scroll Case between cubbies. Cradle presentation is not an additional owner. Invalid drop changes nothing.
- Occupied shelf shrink: block invalid placement, offer conservative explicit rearrangement preview; preserve existing positions where possible, no silent scale changes, compaction or evacuation. Cancel and exact Undo required.
- B7-N2 four checkpoints: ownership/validation, mixed scene and occupied arrangement, universal transfers/checkpoint compatibility, final actual verification. No new art, automatic persistence, Map Room, application identity conversion or real file operations.
