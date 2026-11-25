# Attribution and external references

Project credit: **Astral Archive contributors**. The project was developed extensively using generative AI under human direction and review; see [LICENSING.md](LICENSING.md). These credits distinguish design references, dependencies and third-party material from the project's own implementation. Attribution alone is not redistribution permission.

## Design and technical inspirations

| Reference | Use in Astral Archive | Terms / treatment |
|---|---|---|
| [pocket-dots](https://github.com/diegoMalagrida/pocket-dots), Diego Malagrida | Visual techniques for the Veranda pixel-colony and outline reveal; related Gallery colony effects use the project's procedural shader approach | Upstream GPL v3. Existing Veranda documentation and shader credit retained. Historical source records declare independent implementation; targeted reviews found no affirmative evidence of copied upstream code or assets. |
| [PlasMusic Toolbar](https://github.com/ccatterina/plasmusic-toolbar) | Music interaction and multi-player design reference | Upstream GPL v3. Astral Archive uses Quickshell MPRIS rather than embedding the Plasma widget. Targeted source comparison found no substantive matching lines in examined files; generation-time history is not fully recoverable. |
| Qt Quick and GLSL documentation | Shader interfaces, standard Qt/QML usage and conventional shader techniques | References and ordinary API usage; no blanket claim of ownership over third-party examples. Preserve actual upstream notices if incorporated material is identified. |
| Photograph-informed round seal illustration | The project includes a separately drawn symbolic vector sculpture, not the source photograph | The photograph is not bundled. The project licenses only its own protectable contributions; no rights in the photograph are granted. |

The historical upstream revision actually consulted for pocket-dots is not known. The review compared revision `f1480297f2f7b2f806675ee362fbecc5218d5a9a` as a plausible historical reference, not a proven generation-time revision. Conventional snippet provenance and AI-assisted creation history remain imperfectly recoverable. The present review is a bounded technical assessment, not a legal certification.

## Fonts and local images

No font binaries, personal wallpaper images or Gallery artworks are bundled. The wallpaper catalogue contains theme-reference metadata, not redistribution rights in the images. Artist credits in that catalogue remain intact.

- Maple Mono ([upstream license](https://github.com/subframe7536/maple-font/blob/variable/OFL.txt)), Nova Script ([upstream license](https://github.com/google/fonts/blob/main/ofl/novascript/OFL.txt)), Bellota ([upstream license](https://github.com/google/fonts/blob/main/ofl/bellota/OFL.txt)) and Sirin Stencil ([upstream license](https://github.com/google/fonts/blob/main/ofl/sirinstencil/OFL.txt)): SIL Open Font License 1.1 upstream license files verified; check the actual selected release.
- Elf-ish / Elfish: exact edition and terms not established; obtain only an authorized local installation.
- [Requiem on Envato](https://elements.envato.com/requiem-typeface-48TM95M): design reference, not a bundled or selected font.

## External software

The source repository references separately installed or downloaded tools and services, rather than vendoring their implementations. This list identifies principal references; see [environment](docs/development/ENVIRONMENT.md) and [bring-up](docs/bringup.md) for operational details. Check the actual versions, components and licenses when distributing binaries or a packaged build.

| Dependency / integration | Treatment |
|---|---|
| [Quickshell](https://git.outfoxxed.me/quickshell/quickshell) and [Qt](https://www.qt.io/licensing/) / Qt Quick, QtSvg, Shader Tools | External runtime and build tools; Quickshell v0.3.1 LGPL v3 per upstream source; Qt terms vary by module and distribution. |
| Hyprland, KDE Plasma, Linux desktop services (PipeWire, UPower, NetworkManager, BlueZ, MPRIS-compatible players) | Separate system software; own upstream licenses and protocols. |
| brightnessctl, awww, systemsettings | External commands/services; respective upstream licenses. |
| Node.js, Python, Playwright and Chromium | Separate development/checking tools; Playwright 1.56.1 Apache-2.0. Browser binaries and their notices are not bundled. |
| Pillow, NumPy, SciPy and optional rembg / segmentation models | Local preparation dependencies; check exact library and model licenses independently before bundling or distribution. |
| GitHub Actions and workflow actions | Separate service and tooling; referenced in workflow definitions, not copied into this source tree. |

Canonical SVG assets and their reproducible project-generated derivatives are described in [representation assets](docs/product/REPRESENTATION_ASSETS.md). No derivative packaging or new runtime verification is claimed by this notice.
