# Celestial Gallery — Batch 11: per-artwork celestial customization

Status: **source integration draft**, based on pushed Batch 10 plus the complete Patch 5 dome fix. It has **not** been run with Quickshell, native Qt shader compilation, MPRIS, or Hyprland. No GitHub changes were made in preparing this package.

## Data and preservation

- `quickshell/data/gallery-constellations.json`: 18 **Archive-original, illustrative** figures (not verified astronomical sky maps). Each named entry defines the same normalized stars and edges used by both representations. Star IDs, brightness and connection topology are authoritative; each renderer may style and place them differently.
- `quickshell/data/gallery-sky-presets.json`: 5 procedural presets — Archive Theme, Midnight Ink, Parchment Atlas, Aurora Mist, Celestial Orrery. These are render recipes, not external photographs or copyrighted images.
- `quickshell/services/GalleryPolicy.js`: stable, distinct default selection. New registered artworks get five figures based on a deterministic hash of their stable artwork ID. Supported count is 1–8 in this *initial* implementation. Reordering is supported. New catalogue entries will not reshuffle existing saved selections.
- `quickshell/services/GalleryCatalogue.qml`: holds artwork manifest data, reads both libraries, and stores **per-artwork preferences** under `Quickshell.statePath("gallery-customization.json")` with atomic writes. No artwork is moved, renamed, or rewritten. Preferences for artworks temporarily absent from the manifest are retained.
- `quickshell/widgets/GalleryDrum.qml`: one Canvas generates the material, including stars, edges, names, Roman ordinals, grain and seams. It is rendered in two identical, tiled copies and moved as **one** skin over **900 seconds**. Only *lighting* stays fixed. The old SVG drum skins remain in the repo as unused references; they must not be layered on top of the customized surface.
- `quickshell/widgets/GallerySkyMap.qml`: places the **same canonical star topology** in a full-screen arrangement. The sky map is captured once as a texture and mixed **inside** `gallery-colonies.frag`, behind the same per-pixel reveal mask. A constellation's brightest star is also used as one of the pixel colony seed points; any unused slots use stable filler seeds.
- `quickshell/shaders/gallery-colonies.frag`: retains full-viewport 1-pixel colony calculation, adds selectable procedural sky styling, constellation seed uniforms and the captured map texture. Recompile with the supplied helper; the old `.qsb` is incompatible with the new sampler uniform.
- `quickshell/widgets/GalleryDome.qml` and `quickshell/shaders/gallery-dome.frag`: **unchanged Patch 5 implementation**, restoring the complete v20 meridian lattice, including slit-adjacent engravings, in both GPU and Canvas paths.

## Stable-main audit follow-up (PR #13, November 24, 2026)

Independent implementation topic based on merged main; audit findings are in PR #12. PR #11 (native Archive editor) is not modified.

- AUD-01: colony shader output is premultiplied by coverage and item opacity; the captured premultiplied chart is composited without multiplying its RGB by alpha twice. Recompile the shader; source checks do not establish rendered fidelity.
- AUD-03: pure selection and sky-pool membership, manifest de-duplication and per-artwork state maps use prototype-free dictionaries. Inherited object property names are not valid catalogue IDs unless actually defined.
- AUD-04: the initial FileView load outcome gates preference writes. Only a confirmed FileNotFound or a decoded version-1 object map permits saving, and only with available celestial catalogues. Read failure, malformed JSON or unsupported schema keeps the original file untouched; edits (including artwork reset and sky cycling) remain session-only. The editor reports the warning. A save failure is also reported. No automatic destructive recovery or schema migration is provided. Back up the file, repair or deliberately move it out of the way, then restart Quickshell to re-evaluate it.
- Regression cases added to `node scripts/check-gallery-customization.js`: inherited IDs, duplicate/missing IDs, schema rejection and preservation of prototype-like artwork keys; static shader and write-guard assertions. A separate fetched-source JavaScript execution passed 15 focused checks at policy blob `ff4232fcaa88e64fa50384d3ffb77b4ea01f15b1`; this is not a full Node-suite run or a FileView runtime test. CI status must be checked against the PR head.

- AUD-05: freeze the stable artwork ID, URL, title, artist, constellation definitions and sky together when a telescope focus request is accepted. The accepted request advances the selected artwork's sky cycle once; repeat requests while focusing are rejected. Selection navigation and catalogue reload are locked through focus, fullscreen reveal, reverse and return, and while the shared editor is open. Fullscreen C, right-click and EDIT use the viewed ID; the editor refuses stale targets and closes on unexpected identity change. Normal gallery navigation resumes after return.
- AUD-08: validate local filename segments and percent-encode exactly once before resolving the artwork URL. The original manifest filename and stable ID remain unchanged; literal percent escapes are treated as filename characters, not pre-encoded URLs. Path separators, NUL, unsupported suffixes and malformed UTF-16 are rejected.
- Third checkpoint focused checks: 32 checks passed against fetched JavaScript and extracted synchronous QML function bodies (not Qt runtime). The expanded Node regression script also parsed successfully. Full CI and real Qt URL resolution/input validation remain separate.

- AUD-06: for the axis-aligned fullscreen shader, derive integer render-target dimensions from adjacent-fragment UV derivatives; the logical item dimensions are only a defensive fallback for degenerate derivatives. Raster dimensions also drive procedural sky aspect calculations. This targets one pixel of the Qt render target, not a guarantee of one final physical display pixel after Wayland compositor scaling or resampling. Recompile the local qsb. Test actual capture extents and per-pixel mask at 100%, 125%, 150%, 200%, across outputs and during reveal/reverse.
- AUD-07: use a common centered uniform fit of canonical square star coordinates in the existing drum and sky slots. Preserve star IDs, edges, arrangement order, label slots and both copies of the rotating material. Fullscreen colony seeds use the identical fitted coordinates and update when viewport dimensions change. Uniform fitting can reduce figure size in narrow slots; verify legibility at counts 1/5/8 on the actual drum and at portrait/landscape display sizes.
- Fourth checkpoint: 22,704 focused geometry and simulated raster-grid assertions plus 9 source-wiring assertions passed when executing the exact added regression blocks against fetched repository source; full Node script parsed. This is mathematical/source evidence, not qsb compilation, rendered frames or Qt/Wayland validation.

Remaining verification: use disposable synthetic state files in an isolated Quickshell state directory. Cover missing, empty, invalid JSON, unsupported schema, unreadable and non-file paths; verify original bytes remain unchanged through initialization, editing, reset and cycle opening. Verify successful first-run writes, valid restart round-trip, absent-artwork retention and save failure. Do not run these experiments on personal preferences. Compile qsb and inspect reveal/reverse, partial opacity and contrasting underlay in a real renderer. Native desktop validation remains pending. AUD-02 was subsequently implemented against merged PR #11 in the native Archive planner; see [current state](development/CURRENT_STATE.md). AUD-06/07 still require renderer and target-desktop validation. For AUD-05, test two synthetic artworks during the focus and glow delays, reverse, right-click, C, EDIT, and sky cycling across reopen; for AUD-08, load synthetic images with spaces, Unicode, #, ?, %, and literal percent escapes using actual QML Image URLs.

## Artwork manifest / identity

Gallery art still uses the separate manual manifest `quickshell/data/gallery-artworks.json`. The source repo intentionally contains `{"artworks":[]}` and no copyrighted images. Adding a registered work is deliberate; there is **not** yet filesystem auto-discovery of every local `-g` file.

For example, the local manifest may contain:

```json
{"artworks":[
  {"id":"forest-archive-001","file":"forest-archive-g.jpg","title":"Forest Archive","artist":"Your choice of credit"}
]}
```

The image must exist locally in Git-ignored `assets/wallpapers/`. Only filenames matching `-g.png`, `-g.jpg`, `-g.jpeg` or `-g.webp` are accepted. `id` is strongly recommended; it prevents renaming a file from losing its celestial assignment. If no `id` is supplied, the filename itself is used as the stable identifier.

## User editing

One shared `GalleryCelestialEditor.qml` is instantiated by `shell.qml` and receives the same catalogue object everywhere. Entry points:

1. **✧** in the small Gallery toolbar opens the editor for the currently selected artwork.
2. **Right-click the painted image** in the fullscreen viewer, or press **C** while the full-view window has keyboard focus, or click **✧ EDIT**, to open the same editor.
3. The *future Gallery Rack* should call `galleryEditor.openEditor()` after selecting its artwork. The Rack itself is **not included in Batch 11**.

Use the constellation tab to set 1–8, toggle named figures and reorder the current selection. Use Transition Skies to select one fixed sky or opt into cycling a selected subset on successive opens. Cycling is **off by default**. "Reset this artwork" restores its deterministic five figures and preferred fixed sky.

When the telescope opens an artwork, the Gallery snapshots its constellation definitions and sky before the reveal. Edits performed while the image is open affect later opens, **not the running pixel transition**. The artwork remains `PreserveAspectFit` with its border fitted to the painted image.

## Native validation checklist

1. Recompile shaders: `bash scripts/compile-gallery-effects.sh` after installing `qsb` (Qt 6 Shader Tools). Check `gallery-colonies.frag.qsb` and `gallery-dome.frag.qsb` exist.
2. Start Quickshell inside Hyprland; check import resolution and absence of QML errors. Confirm the editor appears **above** the fullscreen viewer.
3. Add two locally owned `-g` artworks to the manifest, with explicit IDs. Confirm initial five unique figures and *different deterministic assignments*, including after a restart. Check editing one does **not** change the other.
4. Select 1, 5 and 8 constellations. Inspect tiny drum labels and seams. Ensure all markings share the 900-second motion and no older SVG skin is visible underneath.
5. Verify the same figures and edges in fullscreen. Confirm the 1px colony mask clips the constellation texture (stars must not appear before their colony). Native HiDPI/fractional scaling needs special attention.
6. Try each sky preset in all three themes. Enable cycling with two sky choices; open/close several times and restart to verify stored order and wrap. Keep default fixed mode stable across restarts.
7. Test right click on *painted artwork*, C keyboard shortcut, and editor launch from Gallery. Esc should close only the editor when the editor has focus, not dismiss the viewer beneath it. Verify focus transfer on Wayland.
8. Test portrait, landscape and square artwork, custom fields in labels, no artwork, missing artwork, missing state file, invalid catalogue data, and change of selected item during focus animation.
9. Confirm v20 slit/engraving coupling at yaw -20°, 0°, 20°, 60°, plus depth ordering, rear telescope fade, rest/focus lens glint, music panel and minimize modes unchanged.
10. Measure Canvas resource use and shader frame time in the target desktop environment. The texture is cached, but shader compilation and native scaling are **not** verified here.

If the compiled shader is unavailable or fails, the Gallery shows a simpler colored star veil and catalogue-derived chart. It does **not** claim to be the fully accurate 1px reveal fallback.

## Intentionally deferred

- The actual Gallery Rack and its filesystem import workflow; that later component will reuse the editor.
- User-authored custom constellation *drawings*. Batch 11 supports choosing and reordering curated figures; a visual star/edge editor can be considered later.
- Automatically detecting subjects/moods from artworks. Five assignments are deterministic, not AI-classified.
- Licensed background-image packs or externally supplied photographs; current sky selection uses five procedural presets.
- Native desktop validation remains outstanding.
