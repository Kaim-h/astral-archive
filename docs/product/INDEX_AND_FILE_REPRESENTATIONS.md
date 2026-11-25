# Index behavior and symbolic file representations

**Provenance:** Consolidated November 17, 2026 project decisions; see the [research index](../research/README.md). Older prototypes may contain superseded material.

**Status:** the search semantics and object taxonomy below are approved / direction from the November 17 handoff. The existing native Index only searches applications; file / room / cubby indexing is future work.

## Index search behavior

- Search applications, files, folders / containers and rooms as distinguishable result categories.
- **One match:** show direct **Open** (open with the operating system's default application) and **Locate** (spatially highlight the precise item).
- **Multiple matches:** show the relevant distinct results and let the user choose. Include filename and discriminating path / type / count information. Do not pick an arbitrary first result.
- Suggested ranking: exact name → prefix → partial name → path / tags. Exact tuning remains open.
- **Zero matches:** show a calm “No entries found in indexed locations” result and keep the query editable. Do not move the map or highlight an unrelated object. No result does not prove a file is absent outside indexed roots.
- Locate progresses through the actual hierarchy: room → shelf → cubby / nested cubby chain → exact file object / scroll. The exact target highlight persists until entered, dismissed or stale.
- Direct Open bypasses Map Room navigation.
- Deduplicate aliases / duplicate placements appropriately and handle stale or missing files without redirecting to a different item.
- Keyboard arrows change result selection without stealing actual focus from the Index text input.

Real indexing roots, symlink behavior, metadata-only versus full-content indexing, tags, search backend and file action details remain unresolved. Start conservatively with explicit roots and metadata-only indexing until the owner authorizes a broader policy.

## File representation taxonomy

These are symbolic 2D illustrations chosen from small curated pools, not content thumbnails, accurate 3D reconstructions or a promise to render the file's contents. Variant selection should be deterministic per stable file identity, with optional user override. A compact scroll representation should remain an option for dense storage.

| File category | Representation | Typical fixture | Status |
|---|---|---|---|
| Documents, text, Markdown, PDF, source, ordinary files | End-on parchment scroll | Polygonal scroll cells or compact undivided storage | DECIDED |
| CAD / architectural plans | Scroll | Scroll rack | DECIDED; special blueprint object was rejected |
| Images / photos / drawings | Framed 2D artwork | Display backing / hanging panel | DECIDED |
| Videos / presentations | Same framed-artwork family, optionally a subtle play / stacked-sheet mark | Display backing / panel | DECIDED; lantern-slide metaphor rejected |
| 3D files (OBJ / STL / GLB / Blend, etc.) | Illustrated sculpture | Actual shelf surface or plinth | DECIDED; no real 3D renderer required |
| Audio files | Records | Upright plate-holder-style rack | DECIDED |
| Font / typeface files | Engraved stone tablets | Same upright holder | DECIDED |
| Spreadsheets | Ledgers | Same upright holder | DECIDED |
| Compressed archives | Sealed satchels / parcels | Shelf or shallow tray | DIRECTION |
| Scientific / technical data | Ordinary format-based mapping; scroll fallback | Existing compatible fixture for format | DECIDED: no automatic instrument family; historical B7p4 design preserved |
| Unknown / miscellaneous / system configuration | Plain scroll fallback, optional tooltip / seal detail | Scroll rack | DECIDED general fallback |
| Applications | Existing illustrated books | Existing book / shelf baseline | DECIDED |

## Separation of identity and appearance

- A file's real type and its visual representation are separate metadata.
- Users may choose compact scroll form instead of a more elaborate object.
- A file represented as framed artwork is not automatically a Celestial Gallery artwork or Veranda wallpaper. Gallery registration remains explicit and separate.
- Object shape does not grant filesystem capabilities. It is a symbolic representation, not a security or execution boundary.

## B7-C asset contract and historical implementation direction

See [representation asset contract](REPRESENTATION_ASSETS.md). P10 parcel baseline accepted to proceed. Scientific data describes purpose rather than format; proposed simplification is ordinary format-based mapping with scroll fallback, leaving scientific instruments optional research/decorative candidates. Owner explicitly decided to leave instruments out of development, retaining the [B7p4 design study](../research/prototypes/2026-11-24/Astral_Archive_Parcel_Instrument_Study_B7p4.html) as historical design evidence. No instrument mapping or native renderer; decorative use would require a later decision.

## Universal portable form — owner decision November 24

The Scroll Case represents every carried file as a scroll, regardless of original visual family. Preserve file identity, preferred family/variant and metadata; compatible placement restores the ordinary representation. Confirmed fixture deletion transfers all affected files (including recursively nested contents) into the Case, never deletes disk data; preview count, exact Cancel and Undo. Existing application books are distinct application identities. See [physical fixture contract](PHYSICAL_FIXTURES_AND_SCROLL_BEHAVIOR.md). B7-N2 implements populated non-scroll fixture ownership and conversion in the isolated synthetic study; no real file bytes, indexing or disk actions are involved. See [mixed cubbies](../development/B7_N2_MIXED_CUBBIES.md).
