# Project vision and design language

**Provenance:** Consolidated project design decisions and November 17, 2026 research. Historical prototypes may contain superseded material.

**Status:** consolidated from the November 17 cross-platform handoff and the existing design decisions. This page separates settled principles from flexible visual direction.

## Product purpose

Astral Archive is an elaborate but practical desktop environment and spatial file Archive, not merely a decorative wallpaper or a one-off visual experiment. Its storybook library / observatory metaphor is an interface grammar: application books, scroll-like files, rooms, modular cubbies, fixtures and astronomical instruments.

A file-management action should remain clear and useful first. Tactile exploration and atmosphere are optional pleasures, not friction imposed on ordinary work.

## Visual direction

- Quiet, matte and illustrated 2D at rest.
- Ancient stone / aged bronze, restrained engraving, pale parchment and measured shading.
- Consistent dimensionality across books, shelves, panels, instruments and Archive furniture.
- Credible contact, support, scale, occlusion and physical placement.
- Small, curated drawing pools and modest ornament density.
- Practical legibility and recognizable object identity over elaborate ornament.
- Avoid generic corporate styling, gratuitous glitter, shiny chrome, arbitrary Victorian flourishes, unnecessary 3D and long transitions that obstruct daily work.

The visual system is not a mandate to render actual files as accurate 3D objects or content thumbnails. File representations are symbolic 2D illustrations from curated families.

## Existing themes

The three existing themes are Evening, Twilight and Midnight. Their semantic role values are defined by `quickshell/themes/Theme.qml`; consult that file as the implementation source before changing colors. The handoff records these role values:

| Role | Evening | Twilight | Midnight |
|---|---|---|---|
| Background | `#343c43` | `#121e23` | `#080f10` |
| Panel | `#3f524f` | `#263c37` | `#101c1b` |
| Metal | `#c2aa78` | `#8c6e5a` | `#869c9c` |
| Engraving | `#b7a2c8` | `#91ada1` | `#568f80` |
| Text | `#f0f0e8` | `#e6e1d8` | `#dadfd9` |

These are role colors. Do not invent a committed semantic `accent` role without an explicit design decision.

## Typography and assets

The handoff records the selected font-family direction as Elf-ish / Elfish for inscriptions, Nova Script for main desktop / browser-facing lettering, and [Maple Mono](https://github.com/subframe7536/maple-font) for terminal / code. Verify exact installed family spellings and font licenses before depending on them. Font binaries and embedded font specimens are not distributed with this project. Obtain fonts separately from their authorized sources; the upstream Maple Mono repository is linked for reference.

Wallpapers, user Gallery artwork, fonts and personal assets may live locally and be ignored by Git. Do not commit or redistribute them without permission and license checks.

## Typography preferences and deferred shadow-font concept (November 19, 2026)

**Current direction (not an implementation task):**

- **Nova Script** is the current practical favorite for browser text and a candidate for desktop lettering; further experimentation can happen organically while building the actual desktop. Typography exploration should **not delay Archive development**. Nova Slim was considered but is not the current choice.
- **Elf-ish / Elfish** remains the preferred readable script for Archive inscriptions or other suitable in-world uses. **Maple Mono** is preferred for terminal/code. Different surfaces may use different fonts; one font need not do everything.
- The hoped-for aesthetic is **digitally polished**, precise and consistent, rather than visibly handwritten or distressed. It should be elegant, airy, arcane/elven and subtly alien, with a celestial/spatial quality that belongs alongside the Archive's observatory themes—**not** generic science-fiction geometry, cozy whimsy or excessively classical ornament.
- Reference qualities, not approved font substitutions: **Bellota** for distinctive but graceful Latin letter anatomy; **Sirin Stencil** for intentional slits and lifted/separated strokes that make otherwise ordinary letters flow; and the specific [Requiem typeface on Envato](https://elements.envato.com/requiem-typeface-48TM95M) for the sense of unfamiliar, almost symbolic alphabet conventions. Requiem is a *wildcard reference*, not the chosen text font. These qualities need not all appear in every glyph.
- Any eventual everyday browser typeface must withstand extended reading at normal text sizes, not just look attractive in oversized specimens; spacing, kerning, punctuation, diacritics, and suitable weights/styles matter as much as unusual outlines.

**CANDIDATE / DEFERRED — original shadow-inspired typeface:**

- An original font inspired **both** by the distorted silhouettes of cast shadows **and** by the interplay of light and darkness: penumbral forms, openings, deliberate voids, interruptions, floating fragments, and occasional apparent separation of a stroke from its source.
- Keep the result **cleanly vector-drawn and intentionally designed**—not a blurry drop-shadow effect, sketchy brush script, damaged stencil, or an unreadable sci-fi alphabet. The projected-shadow logic should provide coherent reasons for strange shapes while retaining a graceful reading rhythm.
- The visual language should also feel **spacious and cosmic**, resonating with Astral Archive's atmosphere without requiring literal stars in the glyphs. A possible later experiment is **two-color lettering** (for example a base silhouette plus differently colored shadow fragments), with a dependable **monochrome text version**.
- **No custom-font project is authorized or scheduled at present.** Archive development takes priority. A future glyph study, if approved, may establish a visual direction before work on outlines, spacing, kerning, font production and browser tests. Speculative glyph designs are not accepted visual requirements.

## Interaction principles

- Responsive and keyboard-accessible; keyboard focus and visual selection are separate states where specified.
- Clear, short fades / crossfades for routine navigation; avoid theatrical camera flights.
- Do not delay useful actions for decorative animation.
- Preserve reversible, quiet effects and graceful fallbacks.
- Hover is nondestructive; explicit actions perform lifts, moves or other changes.
- Browse and Arrange are distinct modes.
- An interface must not imply that a real system or filesystem operation succeeded when it only requested an action.
- A file is useful first and delightful second.

## Product identity boundaries

- Hyprland owns compositing, tiling, workspaces and window placement.
- Veranda of Vistas selects desktop wallpapers.
- Celestial Gallery is a separate artwork / observatory experience.
- Application books, filesystem folders, virtual cubbies and storage fixtures are distinct concepts.
- A visual layout change must never silently mutate the real filesystem.

## Design status vocabulary

Use `DECIDED`, `DIRECTION`, and `CANDIDATE` precisely. The product documents and reviewed research records preserve the decisions and prototype regressions that explain them.

## Room and Shelf character — owner-supported direction, November 24

One coherent Archive visual language across rooms, with room-level character and coordinated Shelf-level variation. Inheritance proposal: global theme -> room motif/material preferences -> architectural Shelf variation -> cubby -> individual fixture override. Global Evening/Twilight/Midnight semantic roles remain; motif can influence restrained engraving grammar, material relationships, frame/profile details and inscriptions, not file identity, interaction, geometry or legibility. Prefer inherited references and explicit overrides over copying resolved colors; resetting returns to inheritance. Room motif examples (celestial, botanical, geometric) are assistant concepts only; no approved ornament catalog, assigned subject categories, exact schema or production assets. A neutral option and local variation are proposed. Room/Shelf hierarchy implementation belongs to later Map Room work; N3r1 should retain compatible material override boundaries, not build full motifs now. Customization appears in transient right-click menus/inspectors, not persistent sidebar. Keep existing global palettes unchanged; colors hierarchy accepted in direction, details of presets/inheritance still open.

Owner clarification (November 24): room character should combine coordinated colors/materials and subdued ornamentation (engraving and decorative grammar), without turning rooms into conspicuously themed attractions. Keep the common Archive visual language and avoid broad architectural redesign. For N3r1 material controls, preview changes without committing; Reset previews inheritance, Apply commits the whole session as one Undo entry, Cancel discards it. A compact contextual visual picker with precise hex entry is preferred if it stays unobtrusive. Full room/Shelf motif implementation remains later work.
