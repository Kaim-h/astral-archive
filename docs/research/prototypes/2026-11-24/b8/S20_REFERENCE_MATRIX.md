# S20 — feature-specific reference matrix

Verified exact artifact blobs against the design head before closeout. All paths relative to this document unless noted. The [workshop index](README.md) gives per-study critique, evidence, commands and limitations. No single tester is authoritative for all features.

| Feature | Reference and blob | Authority / boundary |
|---|---|---|
| Cubby/rack scroll interaction | [B6r12b3](../../2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r12b3.html) `8addfb6f275ebc04593127cae89ea0046d61ba89` | Accepted browser baseline; retain native B6/B7 contract. |
| Framed art | [B7r3](../Astral_Archive_Artwork_Study_B7r3.html) `084085e24e767997d89a985cc45a9fb2f4a82a92` | Accepted source art/anchor. |
| Sculpture | [B7s11](../Astral_Archive_Sculpture_Study_B7s11.html) `0d7f25220df7a3a42c8a07b5a29594c20a5dd20e` | Canonical art, native clip-path derivative policy. |
| Upright holder | [B7u3](../Astral_Archive_Upright_Study_B7u3.html) `bccc632e871daabe19464c47a9fd405d2c2998d2` | Full holder interaction, not only S18 present/return. |
| Parcel | [B7p10](../Astral_Archive_Parcel_Study_B7p10.html) `aefc4cae35dab41a462a207aab5055868f752650` | Accepted art/contact/metadata. |
| Support board | [Lighting Lab](../../../handoffs/2026-11-17/prototypes/Astral_Archive_Book_Lighting_Lab.html) `530dcc099027070a40f2c9f676ee297d8fd87a16` | Original flat board recovered in S18r3; not historical book art. |
| Shelf casework, glazing, backing, emblems | [S11r1](Astral_Archive_Shelf_Study_B8s11r1.html) `59e8278ad6247eda2c08bd013271e55c7abfd411` | Owner-accepted exact recovered source; later flat fills and implicit commit supersede earlier treatment. Catalogue not blanket art acceptance. |
| Shelf geometry and rack affordance | [S10r1](Astral_Archive_Shelf_Study_B8s10r1.html), [S9 contract](B8s9_ARRANGEMENT.md), [S18r4](Astral_Archive_Shelf_Study_B8s18r4.html) | Shared fixtures, selected dimensions, diamond radius, independent book support; static packing not live physics. |
| Contextual Shelf controls | [S18r4](Astral_Archive_Shelf_Study_B8s18r4.html) `364711da783cf8f2a2ef5ab12e92268bf99e64ba`, [review](S18R4_REVIEW.md) | Accepted progression, scoped tests; native and complete historical parity not established. |
| Room projection/quality | [S14r5](Astral_Archive_Room_Study_B8s14r5.html) `69f5794b628a022c8fe039f39e3e8287547a0c31` | Accepted rendering improvement; no mandatory CPU port. |
| Room plan | [S15r4](Astral_Archive_Room_Study_B8s15r4.html) `a1f7f2e1bd5e603134eb070aa7054a843137a868` | H only; S15r3 Shelf-only scope, S16r2 canonical colour correction. |
| Room→Shelf navigation | [S16r3](Astral_Archive_Room_Study_B8s16r3.html) `a7df5de25e31ac48d8f3a05e175f676efb285b32` | Method A accepted, 500ms initial default documented later (HTML uses 600ms); actual geometry and appearance integration outstanding. |
| Map editor and doors | [S19r2](Astral_Archive_Map_Room_Study_B8s19r2.html) `60c2c5419f22a74e653ca4d3eab566b88a7e23e6` | R1 focus/assistance, r2 merge/delete/corner; simplified solver not native contract. |
| Map aesthetics | [S19r3](Astral_Archive_Map_Room_Study_B8s19r3.html) `95a7cbedc813d407a8e27a0b584da36904c1f67f` | Accepted except old contours; map-only appearance. |
| Map contours | [S19r4](Astral_Archive_Map_Room_Study_B8s19r4.html) `4f6de59d132bdec80b3a0891585ccb34561f50b1` | Owner approved progression; synthetic CC0-derived field, no real USGS extract. Discrete LOD and performance provisional. |

## Exclusions and reference boundaries

S17 unreliable visual comparison, only demonstrates inheritance/context behavior; no numerical density requirements. S18r2 fixed app bookshelf rejected; S18r3/r4 independent board and books supersede it. Use current native Book/catalogue art, three-theme coordinated colour requirement; static bookmarks not final motion. S16 alternatives B/C/control archived, accepted A not reopened merely for 900ms. Early Map v1/v2 scattered objects rejected. No mandatory connectivity, fixed inspector or preview cycling as production. Non-Shelf Room furniture S13–S15r2 deferred to B9, discoveries tentative B10. Historical 3D books abandoned. Five previously unarchived B8 variants recovered exactly; historical November 20 ZIP separate review, no blanket import. Secondary Bestiary fang unresolved. Later testers omit full physics and holder drag/swap; preserve [representation assets](../../../../product/REPRESENTATION_ASSETS.md), [native mixed cubbies](../../../../development/B7_N2_MIXED_CUBBIES.md).

## Test evidence and review

Relevant scripts [S11](check-b8s11.py), [S16r3](check-b8s16r3.py), [S18r4](check-b8s18r4.py), [S19r2](check-b8s19r2.py), [S19r3](check-b8s19r3.py), [S19r4](check-b8s19r4.py), earlier B6/B7 CI and native tests. Read actual script options, use explicit baseline where supported; some harness paths assume local study folders. Do not silently change original baselines; record harness adjustments. Historical tests scoped, not unified regression or fresh verification. S20 documentation-only. Independent review must confirm exact references, no lost behavior, accepted vs proposed decisions, current native baseline and publication safety before integration. See [design contract](../../../../product/B8_SPATIAL_ARCHIVE.md) and [handoff](../../../../development/B8_IMPLEMENTATION_HANDOFF.md).
