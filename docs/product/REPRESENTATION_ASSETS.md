# B7-C representation asset contract (implementation candidate)

## Canonical inputs

[Asset manifest](../../quickshell/archive/representation-assets/manifest.json) pins four exact Git blobs: B7r3 artwork, B7s11 sculpture, B7u3 upright holder, B7p10 parcels. [Review index](../research/prototypes/2026-11-24/README.md) gives direct references. The existing B6r12b3 scroll art and native ScrollEnd remain authoritative for scrolls; existing application Book remains separate. Older studies including B7p3 are historical.

## Asset format

46 variants: six artwork motifs, sixteen sculptures (eight ceramics, eight stone), six parcels, six each record/ledger/tablet. 64 standalone SVGs including 18 edge views. Each contains original symbolic SVG art with local definitions, no embedded script, external asset, DOM or private file content. Frame and fixture art are not baked into face assets. Native SVG support and appearance need actual Qt verification; clip paths, gradients and nested coordinates may require a different native renderer. The extracted artwork is not a new visual redesign. Frozen ceramic ring cross-sections are sampled from the exact S11 silhouette in Chromium; grain seeds remain original variant IDs.

Manifest schema 1 uses stable namespaced variant IDs, source blob SHA, labels/material, relative SVG paths, viewport [x,y,width,height], bounds [left,top,right,bottom], contact [x,y], nominal width/height and upright thickness/edge dimensions. Viewport padding includes strokes; anchors are in SVG local coordinates, not image pixel offsets. Sculpture bounds retain reference selection envelopes (not tight collision meshes; verify before using for collisions). Parcel bounds are sampled geometric envelopes excluding strokes. Upright bounds are nominal, record face geometry ends about one unit inside the nominal bottom (as in U3). Artwork motif crops via slice to the frame aperture; anchor belongs to the frame, not the motif. Map coordinates with a uniform transform; place contact on fixture datum, not hardcoded y. Expanded plaques and interactive hit regions are separate from art and do not change physical footprint.

## Fixture and interaction contracts

| Family | Fixture | Contract |
|---|---|---|
| Artwork | mounted backing or ledge | R3 frame profiles bronze/stone/slim, stone uses background role, side-only trapezoid shadow, lower-right plaque; mount implied, ledge contact on bottom |
| Sculpture/parcel | shelf/plinth or parcel shallow tray | shared support line; fixture plaque, optional tray lip in front, never float |
| Record/ledger/tablet | shared upright holder | edge-on widths from thickness, 10-unit record edge, aligned rear rail, smooth separators, dots centered between upper fascia bar and bottom; click presents same identity in supported side cradle, drag moves/swaps after 5 CSS px threshold (native threshold needs verification), Escape cancels or returns |
| Scroll | existing rack | retain B6 semantics, no modifications |

Frame formula in RepresentationCatalog.mjs preserves R3 width-dependent thickness/reveal, shadow and plaque bounds; reject impossible apertures. Theme roles resolved from Theme.qml by future native renderer. U3 holder width formula: natural slot width thickness*scale + 12, vacant tester uses max thickness, fit=min(1,630/total) in study coordinates; recompute widths after swaps. Treat dimensions as study values not immutable production pixels. Preserve exact identity on presentation/move/return; synthetic metadata does not become disk facts.

## Candidate automatic mapping

Pure RepresentationCatalog.mjs proposes extension-based family and stable FNV-1a-style UTF-16 ID hash for deterministic pool choice; explicit variant override validated against pool, compact scroll override wins. File IDs must come from the eventual identity service, not paths or names. Unknowns fall back to scroll. No content reads, filesystem operations or production hookup. Scientific instruments: **owner decided November 24** to omit the instrument family from implementation/automatic classification. Purpose is not file format; preserve [B7p4 instrument design research](../research/prototypes/2026-11-24/Astral_Archive_Parcel_Instrument_Study_B7p4.html) as historical artwork, not a live family. Optional decorative use is not yet approved. Extension list is a candidate, not exhaustive MIME inference or security policy. Existing application identity is separate.

## Reproduction and validation

Run `node scripts/build-b7-assets.mjs` (read-only exact regeneration comparison against pinned source), `node scripts/check-b7-assets.mjs` (manifest/asset references/policy/geometry). Explicit `--write` regenerates files; review diffs, never silently replace accepted geometry. Historical prototypes are build-time provenance, not runtime dependencies. `node scripts/check-b7-assets-browser.mjs` (after installing the workflow's Playwright Chromium) independently compares all 64 assets against actual reference functions in Chromium, allowing .02 units for ceramic path sampling, and decodes each image. Target Qt SVG rendering remains a separate pending check. `supportedImage` maps padded viewports onto contact points; `uprightLayout` implements U3-derived edge spacing and vacancy geometry without changing identity or solver state. No actual filesystem or QML changes in B7-C.

## Regression safeguards

P3 discarded functioning layout, physical contact, scaling and hover; forced clicks hid selection failure. First P9 delivery was identical to P8 because an unchecked replacement missed its target. For future visual changes, assert exact intended source matches, compare actual generated art for changed and unaffected variants, verify internal version and exact artifact hash, assert actual non-forced pointer selection/metadata, check contact/scale and inspect real rendered captures. No JS errors alone is not a pass. Owner visual approval is separate from numerical/source checks.

## B7-N1 native implementation boundary

See [B7-N1 active handoff](../development/B7_NATIVE_REPRESENTATION_WORK.md). The first isolated Qt study uses manifest-exact static runtime data and original face/edge SVGs; support transforms align padded viewports and selection envelopes to shelf board top. Mounted frame candidate uses the R3 profile/aperture formulas. Actual SVG decode and rendered captures require fresh CI. No mixed ownership, rack edits, instrument implementation or production integration.

Native correction: initial actual Qt capture identified unsupported/incorrect sculpture clip-path rendering despite successful SVG decoding. `node scripts/build-b7-native-raster.mjs` generates transparent 4x sculpture PNG derivatives from the exact pinned SVGs using the workflow's Playwright Chromium. Preserve canonical art, viewport, contact geometry and separate hit envelope; no raster redraw or runtime browser. All 48 other face/edge SVGs lack clip paths and remain vector. During isolated development, generate derivatives once (or install the CI artifact under `quickshell/archive/representation-raster/`) before standalone launch; output is ignored and carries source/PNG digests. Fresh actual render inspection required. Final packaging remains later.
