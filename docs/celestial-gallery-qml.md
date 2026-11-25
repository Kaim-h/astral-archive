# Celestial Gallery — Batch 10 / first Quickshell implementation

## Status

A **native QML integration draft**, delivered locally for review. It has **not run in a Quickshell/Hyprland session**. Do not treat source-level checks or browser prototypes as native execution. Nothing here changes GitHub, the wallpaper service, or the existing Veranda UI.

### Approved behaviors carried over

- Hemisphere: 328 design px diameter, 40° longitude slit, lifted (+20 px) telescope mount. Idle yaw −20°..+30°, pitch 25°..45°, 10 FPS with 5s pauses. Focus +60°/30°, return +20°/33°; focus animation 1450ms and independent of idle FPS.
- Tower: **one Ionic column per side**, 30px equal perpendicular arch band, moving source-relative 60%-crop artwork with pauses, 2 narrow inscription bands; artwork remains local and Git-ignored.
- Drum: **exactly 282 px wide**, full upper rotating cylinder. The ALL-in-one constellation/seams/roman-numerals SVG scrolls once every **900,000 milliseconds (15 minutes)**. No stationary constellation layer, no ritual mode, no detached markings. Fixed shadow = lighting, not stationary paint.
- Music: real MPRIS metadata/album art/play/pause/previous/next; hover-only title scroll. **+** reports unsupported (standard MPRIS doesn't implement adding to a library).
- Controls: full Gallery, downward music-only, left full minimize leaving restore tab.
- Opening: focus scope, fixed lens glint, fullscreen 1px colony reveal, contained full artwork with a border hugging the actual painted image; reverse sky and return to rest. Shader is source-only; compile locally with `scripts/compile-gallery-shader.sh` using Qt `qsb`. If unavailable, it falls back to a simple dark star veil, **not** 1px colonies.
- Themes: Evening, Twilight and Midnight are derived from existing `Theme.qml`. Architectural SVGs for each theme are pre-generated (no fonts or copyrighted artwork included).

## Deliberate technical differences vs HTML

The existing HTML dome uses a depth-tested WebGL mesh. This first QML pass uses **native QtQuick Canvas with analytic projection**, retaining the same geometry/pose parameters but not yet perfect 3D depth ordering. The telescope/dome occlusion and engraved edges need **native visual validation** against the HTML before claiming pixel-perfect parity. Do not silently replace the approved HTML baseline.

The stationary architecture uses theme-specific SVG assets generated from the original centerline/geometry. QtSvg loading requires the Qt SVG image plugin (`qt6-qtsvg`). The arch's normal offsets are generated once offline; the artwork moves separately and does not rerender the architecture.

## Installation (do not overwrite blindly)

1. Back up or commit your existing working repo first.
2. Copy **only the supplied paths** from this ZIP into the checkout; review the changed `quickshell/shell.qml` before overwriting, since it adds a new panel and global shortcut.
3. Put your own licensed/local `-g` artworks in `assets/wallpapers/`, which is already ignored by Git. Do **not** include them in commits.
4. Edit `quickshell/data/gallery-artworks.json` to reference each filename and its title/artist, e.g.:

   ```json
   {"artworks":[{"file":"example-g.jpg","title":"Example","artist":"Artist"}]}
   ```

   The actual `example-g.jpg` must exist locally; it is not bundled.
5. Install/verify Qt 6 Quick, QtSvg, Shader Tools `qsb`, Quickshell with MPRIS, and Hyprland. Compile shader: `bash scripts/compile-gallery-shader.sh`.
6. Run `node scripts/check-gallery.js` for offline structural checks, then `qs -p quickshell/shell.qml` from the repository root **inside Hyprland**. Check QML logs, QtSvg asset loading, MPRIS player discovery, native behavior and GPU utilization.
7. Bind the global shortcut name `celestial-gallery` through your normal Hyprland/Quickshell shortcut configuration (as with `astral-archive`). The restore tab is also clickable.

## Native-test checklist / constraints

- [ ] Confirm QML loads without import errors and all 3 theme SVG assets render correctly.
- [ ] Ensure 282 px drum skin wraps seamlessly at 15 minutes, **all markings rotate together**, and the arch occludes its lower surface.
- [ ] Verify the 40° dome opening, 0–20° crossover trace, engravings adjacent to both slit boundaries, and telescope cylinder collars against HTML v9. The dome's analytical Canvas representation is only a provisional port.
- [ ] Inspect artwork crop bounds for both portrait and landscape, gentle pan/rests, and edge mist in each theme.
- [ ] Check album art, title scroll-on-hover, previous/next/pause, and **no false save** action.
- [ ] Inspect at 1920×1080 and 80% design scale. Check real screen click targets; if small, enlarge interactive targets *without enlarging the artwork*.
- [ ] Test down (music-only), left (fully hidden), restore; no idle redraw while fully hidden.
- [ ] Compile the fullscreen shader; inspect 1px colonies, lens glint anchor, portrait/landscape/square viewer border and reverse close.
- [ ] Verify native performance and refine native render pacing. The QML Canvas and SVG image plugins may need targeted optimizations once actual hardware metrics exist.

## Preservation rules

Never change GitHub without user authorization. Do not bundle fonts or copyrighted artwork. Do not change wallpaper for the Gallery's viewer. Do not treat unchecked QML as verified production code. Retain the current HTML v9 and v10 as visual/regression references.
