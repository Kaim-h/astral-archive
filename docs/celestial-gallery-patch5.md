# Celestial Gallery — Patch 5: dome engraving parity with HTML v20

**Source of the agreed geometry:** `celestial_gallery_music_twinkle_v20.html`, function `domeDetailMesh(yaw)`. Patch 5 restores the exact *family* of longitude marks v20 used; it does not invent a new look.

## One rotating longitude lattice

For `k = 0..6`, the two seam series are mounted to the dome shell at body-local longitudes `+(20° + 11° + 29°×k)` and `−(20° + 11° + 29°×k)`. A single yaw angle is added to **every** seam. The slit is also rotated by that same yaw and extends 20° either side. When projected onto the visible hemisphere, marks are culled if `theta <= 0.035 rad` or `theta >= π−0.035 rad` and cut away wherever the real opening removes shell material. In particular, the first visible meridian remains **11° outside each slit edge**; no independently positioned near-slit marks exist.

The latitude circles are at design heights **44, 95, 144px** above the center, following the original v20 design instead of Patch 4's 47/111 pair. Because a full latitude circle is symmetric around the yaw axis, it *looks stationary* during yaw—correct physics. The longitudinal lines **do** visibly turn and intersect all three circles, producing a coherent wireframe.

## Unchanged approved design

- Hemisphere radius **164px**, diameter **328px**.
- Slit spans `[yaw−20°, yaw+20°]`, shell height **34.4–155.8px**.
- Telescope mount is **20px** above dome center; three opaque tube stages at `0–169`, `162–203`, `196–246` with three raised collars and real lens; native focus `60° yaw/30° pitch`, rest `20° yaw/33° pitch`.
- Native shader uses a **shared depth comparison** between physical dome and telescope; Canvas is a fallback only.
- The **282px drum** (one continuous physical moving surface, 15-minute revolution), architecture, themes, music, panning, 1px fullscreen transition, and control choreography are untouched.

## Regression precautions and native checks

Do not reintroduce the detached `yaw+1.80`, `yaw+2.43`, `lo−0.20`, `hi+0.20` longitude series or a screen-space seam overlay. The slit cut **edges** are separate from the adjacent engraving marks, but they rotate together with the shell. The stone *dome seat* underneath does not rotate, because it is a separate architectural component.

Test yaw `−20°, 0°, +10°, +20°, +30°` at pitch `33°`, then focus `+60°/30°`; inspect the full meridian lattice moving with both slit edges through the 0–20° crossover. Test the GPU shader after compiling its QSB and the Canvas fallback separately. Verify all themes and avoid interpreting the unchanging silhouette or symmetric latitude rings as a second, stationary engraving layer.

**Verified offline:** formula parity across 294 meridian samples (21 yaw values × 14 meridians), source-level geometry, slit side placement. **Not verified:** Qt/qsb compilation, QML runtime, device scaling or GPU performance.
