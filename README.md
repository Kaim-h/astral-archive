# Astral Archive

An illustrated Linux desktop shell and experimental spatial file manager inspired by storybook libraries, celestial observatories and the Gorilla of Destiny's *Elf-ish* typeface.

Astral Archive explores a different way of interacting with a computer: applications represented by illustrated books, files by physical objects, and information organized within customizable shelves and rooms.

The aim is to create an immersive desktop without sacrificing the practicality of a conventional one.

Built with Quickshell, Qt Quick/QML and JavaScript, Astral Archive integrates with Hyprland and existing Linux services rather than replacing the compositor.

## Current development status

**Active development — pre-release. Not ready for general installation or daily use.**

The public main branch contains the desktop shell and isolated native Archive studies, including simulated scroll physics, mixed furnished cubbies, Scroll Case transport and synthetic checkpoint Save/Load. The Archive is not yet connected to the production shell or real filesystem operations.

The B8 Shelf, Room and Map Room design is integrated as a specification. Its native implementation is in progress in [PR #19](https://github.com/Kaim-h/astral-archive/pull/19); experimental branch features are not released features. The integrated baseline has passed JavaScript, Chromium and offscreen Qt Quick checks; actual target Linux desktop validation remains outstanding.

[Current implementation](docs/development/CURRENT_STATE.md) · [Active development](docs/development/ACTIVE_WORK.md) · [Roadmap](docs/archive-roadmap.md) · [Documentation](docs/README.md)

## Development approach

Astral Archive is a non-commercial personal project developed extensively using generative AI. Much of its implementation, artwork, documentation and testing is produced by AI agents under my direction.

I establish the creative vision, design requirements and development priorities, coordinate the agents, review their work and make the final decisions on what gets integrated.

## Features

### The Desktop

- **Illustrated application launcher** — applications represented by customizable books.
- **Archive Capsule** — a compact desktop interface for accessing applications and utilities.
- **Utility Shelf** — everyday system controls.
- **Veranda of Vistas** — an illustrated wallpaper selection interface.
- **Celestial Gallery** — an observatory-inspired interface for displaying artwork.
- **Customization** — coordinated palettes, typography and celestial ornamentation.

### The Archive

The Archive is an experimental spatial file manager in development.

Its intended features include:

- Files represented by scrolls, framed artwork, sculptures and other physical objects.
- Scrolls with simulated physical interactions.
- Customizable shelves, cubbies and storage fixtures.
- Rooms with individually configurable materials and ornamentation.
- A Map Room for navigating and arranging rooms.
- An Index for quickly searching, opening and locating files without navigating the physical Archive.

The spatial interface is intended to complement efficient, keyboard-accessible file management rather than replace it.

## Project documentation

- [Design language](docs/product/VISION_AND_DESIGN_LANGUAGE.md)
- [Native Linux bring-up guide](docs/bringup.md)
- [Archive architecture review](docs/architecture/ARCHIVE_INTERDEVELOPMENT_REVIEW_2026-11-24.md) — historical technical background and advisory recommendations.

## Contributing

Suggestions, questions and artistic inspiration are welcome in [Discussions](https://github.com/Kaim-h/astral-archive/discussions).

You don't need to know how to code to contribute. Illustration, typography, architecture and visual design are all important parts of Astral Archive.

For technical contributions, please read:

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [AGENTS.md](AGENTS.md)
- [Publication preflight](docs/PUBLICATION_PREFLIGHT.md)

Development is coordinated through focused, reviewable pull requests. Ordinary development remains subject to explicit owner authorization.

## Assets and typography

Personal wallpapers, proprietary fonts, artwork and runtime state are not bundled with the repository.

Astral Archive's typographic direction includes:

- *Elf-ish* — the original inspiration for the project.
- Nova Script.
- Maple Mono.

Third-party assets must be obtained from authorized sources and used according to their respective licenses.

See the [asset guidance](docs/assets.md) and [attribution records](ATTRIBUTION.md) for further information.

## Verification

Static checks, JavaScript unit tests, browser studies, offscreen Qt Quick tests, Quickshell runtime checks and native desktop validation are distinct forms of evidence.

Detailed verification results, tested revisions and outstanding validation requirements are recorded in the [current implementation state](docs/development/CURRENT_STATE.md).

## License

Project-authored software is licensed under GPL-3.0-or-later. Original artwork and documentation are licensed under CC BY 4.0, subject to applicable third-party terms and the rights actually held by contributors.

Astral Archive is shared openly for learning, experimentation, modification and reuse. Its non-commercial development intent does not restrict commercial use permitted by its licenses.

- [Licensing scope](LICENSING.md)
- [GPL license](LICENSE)
- [CC BY license](LICENSES/CC-BY-4.0.txt)
- [Attribution](ATTRIBUTION.md)
