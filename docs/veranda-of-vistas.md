# Veranda of Vistas — Batch 9, Patch 3

## Purpose

The centered **Veranda of Vistas** chooses wallpapers only. It is not the
**Celestial Gallery** (the future observatory and the `-g` artwork).
Its undistorted parallelogram previews, floating title/artist inscription,
per-theme daily rotation and explicit APPLY action are unchanged.

## Wallpaper effect based on the Reddit reference

Reference: https://www.reddit.com/r/hyprland/comments/1xq8r00/wallpaper_transitions_that_outline_the_character/
Author's source: https://github.com/diegoMalagrida/pocket-dots (GPL-3.0)

The reference uses a temporary Quickshell shader above `awww`: it traces a
subject's cut-out silhouette when one is present, then fills from the subject;
for other images, pixel colonies spread across the old wallpaper. The daemon
is swapped invisibly while the shader is covering the background.

Patch 3 implements **an original visual adaptation of this technique**; it
does **not** copy upstream GPL-licensed code, QSB files, or artist assets. The
outline follows an approximate radial sweep around the subject's centroid,
not the reference author's exact contour-arclength algorithm. It is not an
identical effect. Native rendering still must be tested.

- **ANIMATION: ON (default):** when the shader is available and this shell has
  successfully applied a previous wallpaper, use the Quickshell shader layer:
  pixel colonies on ordinary wallpapers; outline-first for wallpapers with a
  prepared and enabled subject map. Once covered, `awww` switches with `none`.
- **ANIMATION: OFF:** `awww` changes wallpaper immediately (`none`).
- **Fallback:** if no prior wallpaper is known, shader is unavailable, images
  or subject map fail to load, or shader loading times out, use the normal
  `awww` fade (0.85 s). A failed `awww` call is reported, not marked successful.
- Switching the toggle does not affect a currently playing transition or
  turn off the Veranda's independent Coverflow animations.
- Settings persist in `Quickshell.statePath("veranda-of-vistas.json")`.

**The first wallpaper after a fresh Quickshell startup uses the ordinary fade**
because the service has not yet confirmed which background `awww` is showing.
Subsequent different wallpapers in that session use the shader when available.
This avoids trying to interpolate from an unknown or incorrect old image.

The temporary `WlrLayer.Bottom` layer sits above the wallpaper daemon's
background and below ordinary windows. It has an empty input region, so it
cannot grab keyboard/mouse input; it must never replace the real wallpaper.
The service keeps the original `awww` behavior as a fallback.

## Mandatory shader build

Qt 6 `ShaderEffect` requires a compiled `.qsb` file. This package contains
**original GLSL source and a compile script, NOT a compiled QSB** because qsb
was unavailable in the packaging environment.

1. Install Qt Shader Baker (`qsb`) from Fedora's Qt 6 Shader Tools package
   that provides it. Check the package with `dnf provides '*/qsb'` before
   installing, because the exact split package can vary by Fedora release.
2. From the repository root run:

   ```bash
   bash scripts/compile-vista-shader.sh
   ```

3. Verify the file exists:

   ```bash
   ls -l quickshell/shaders/vista-transition.frag.qsb
   ```

4. Keep that compiled file in your Quickshell config. Do not
   assume it works on all Qt versions or GPU drivers until native testing.

If the `.qsb` is missing, wallpaper application uses the ordinary `awww`
transition. The shader is checked when Quickshell starts: **restart Quickshell
after compiling it**. A QSB that exists but is incompatible with the GPU/Qt
version may still fail to render; this needs native testing, and the code has
an image-readiness timeout, not a guarantee against all GPU shader failures.

## Optional subject outlines — local preparation only

All **29 supplied wallpaper manifest entries** default to pixel colonies;
no `-g` image is included. Landscape wallpapers often lack a distinct subject to outline, so segmentation is optional.

For a selected wallpaper with a well-defined subject (person, creature,
architecture, etc.), produce a **PNG subject mask** matching the dimensions
and alignment of the original artwork. The mask must have transparent
background and opaque subject; grayscale white-on-black also works.

Store locally at:

`assets/wallpapers/.subjects/<artwork-id>.png`

To use the reference post's optional BiRefNet segmentation technique, you
can install `rembg` separately and try, for example:

```bash
rembg i -m birefnet-general \
  "assets/wallpapers/<original-file>.jpg" \
  "assets/wallpapers/.subjects/<artwork-id>.png"
```

The exact file path and ID come from `quickshell/data/veranda-wallpapers.json`.
Do not take the segmentation result on faith: inspect and manually correct it.
For landscapes, automatic foreground segmentation may pick the wrong object.
`rembg` may download a large model on first use. It is **optional** and is
never launched automatically by the desktop.

After adding any masks, run:

```bash
python3 scripts/prepare-vista-outlines.py
```

This local preparation needs Pillow, NumPy and SciPy (`python3-pillow`,
`python3-numpy`, `python3-scipy` on Fedora). It writes cached textures to:

`assets/wallpapers/.wallfx/<artwork-id>.png`

Finally set `"subjectOutline": true` for that wallpaper in the public
`quickshell/data/veranda-wallpapers.json` manifest. **Only enable it after**
its local map exists. The source mask, cache and copyrighted artwork stay in
ignored `assets/wallpapers/`; only the boolean metadata can be public.

When the map is missing, the fade fallback is used, not a made-up silhouette.

## Dependencies / safety

- Existing **Batch 9 Patch 2** must already be integrated.
- `awww-daemon` and `awww` must be available and running under Hyprland.
- The shader must be compiled with matching Qt 6 tools to produce a QSB.
- No startup services, elevated privileges, remote uploads, artist binaries
  or GitHub changes are made by this patch.
- Keep KDE/TTY available while manually testing. Do not enable untested
  Quickshell autostart just because offline checks pass.

## Tests

```bash
node scripts/check-launcher.js
node scripts/check-windows.js
node scripts/check-shelves.js
node scripts/check-utilities.js
node scripts/check-veranda.js
node scripts/check-vista-fx.js
node scripts/check-structure.js
```

These tests check state/policy integration and source structure, not shader
compilation, visual quality, input-through behavior or monitor scaling.
Native visual tests (including multi-monitor swaps and QML status/logs) are
required before the effect can be considered working on the real desktop.

## Stable-main audit follow-up (AUD-11, AUD-12, AUD-15)

The post-B7-N1 bug-fix branch preserves state bytes after failed reads, malformed or unsupported preference envelopes; only confirmed missing files and valid v1 preferences authorize writes, and a valid nonempty wallpaper catalogue is required. The historical v1 form without `transitionEnabled` still defaults to animated fade. In protected mode selection/toggles are session-only, with a persistent warning. To recover, close Quickshell, back up the original `veranda-of-vistas.json`, repair it or move it aside explicitly, then restart. Never delete or overwrite the only copy as a recovery test.

Daemon CLI paths retain literal filenames. QML preview, thumbnail, mask and transition URLs encode local path segments exactly once; the trusted installation directory URL alone is decoded. Existing manifest filenames and assets are unchanged. Automatic and manual request keys share one helper; successful completion reconciles the actual selection date and final rotation preference, not the stale request key. Preference toggles cannot claim an unconfirmed wallpaper was applied.

Regression checks are in `scripts/check-veranda.js`. Native acceptance remains: use disposable state/manifest fixtures; verify corrupt, unknown-version, unreadable and missing files, toggles while an apply is pending, successful and failed daemon commands, paused manual selection followed by multiple ticks, theme/day changes, and literal spaces, Unicode, #, ?, % and percent-like filenames in both normal fade and shader paths. No actual daemon or target Quickshell test is implied by pure logic checks.

First checkpoint: 63 focused policy/wiring assertions plus 26 extracted-service assertions passed using a mock FileView/process and deterministic date. The first local mock harness failed because its replacement date source did not override the extracted lexical function; corrected harness uses an explicitly injected date. These results are not native Qt I/O or actual wallpaper application.

## Bounded startup recovery (WP-07 / AUD-22)

Theme, catalogue and Veranda preferences are separate readiness prerequisites.
Both adapters use background FileView preload with a 3-second single-shot
startup deadline, separate from the 12-second wallpaper backend watchdog.
Read text only after a loaded callback. Each read resolves once per service
lifetime; late results cannot replace that decision while another prerequisite
is pending. The deadline requires a responsive event loop.

Veranda preference timeout permits protected **manual-only** selection for
the session: no initial apply, daily tick, theme-change apply or automatic
retry. Daily rotation displays MANUAL; explicit wallpaper and animation
changes remain session-only. Unavailable catalogue disables application and
persistence. Confirmed missing preferences still permit first-run defaults
and writes with a valid catalogue. Corrupt/failed/unsupported reads retain
the established protected fallback. Theme timeout preserves explicit pending
selection or Twilight; a valid Veranda read can initialize against this
resolved theme. Controls indicate pending startup. Save failure prohibits
subsequent persistence until restart; actual atomic-write behavior and any
already-submitted asynchronous writes require target verification.

The existing mock checks exercise absent, late, repeated and ordered
completions, deadlines, user intent, protected manual-only recovery, linked
theme readiness and failed writes. They do not exercise native FileView/timer/
binding scheduling. N4 requires disposable state, real lifecycle and first
wallpaper request counts, byte preservation, restart recovery and daemon
behavior. Preserve AUD-11/12/15. See also
[Quickshell FileView 0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/FileView/).
