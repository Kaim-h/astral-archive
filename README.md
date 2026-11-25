# Astral Archive

Astral Archive is a practical, illustrated Linux desktop shell and a planned spatial file Archive, built around Quickshell, Qt Quick/QML and JavaScript. It integrates with Hyprland and existing Linux services rather than replacing the compositor.

The design combines a quiet storybook-library / observatory metaphor with ordinary desktop priorities: useful controls, clear navigation, responsive interactions, keyboard access, recoverability and safe filesystem behavior.

## Implementation status

The tracked shell includes the illustrated launcher, Archive Capsule, utility controls, Veranda wallpaper selector and Celestial Gallery. The separate Archive study includes B6 native geometry/interaction foundations and B7 symbolic representations and mixed furnished cubbies. Its records and file operations are synthetic; it is not a production file manager.

Read the [current state](docs/development/CURRENT_STATE.md), [roadmap](docs/archive-roadmap.md) and [native Linux bring-up guide](docs/bringup.md). The public baseline is integrated and has passed offline, browser and offscreen Qt Quick CI. This is not a release or evidence of successful target desktop validation.

## Contributing

Start with [CONTRIBUTING.md](CONTRIBUTING.md), [AGENTS.md](AGENTS.md) and the [documentation index](docs/README.md). Keep changes focused and reviewable. Ordinary development remains paused until explicitly authorized by the owner.

## Verification and assets

Static checks, JavaScript unit tests, browser studies, offscreen Qt Quick, actual Quickshell and target desktop validation are distinct evidence classes. The public baseline at `38f218a5bae7d2ad0a37315d5fda6ab0a9d9a0bf` passed [CI 45533627218, attempt 2](https://github.com/Kaim-h/astral-archive/actions/runs/45533627218/attempts/2) (`offline-js`, `browser-cubby-studies`, `native-archive-qt`). See current state for scope and historical results. Subsequent AUD-16–21 corrections and [regression guidance](docs/development/REGRESSION_VERIFICATION.md) are integrated; [current main CI 45614308923](https://github.com/Kaim-h/astral-archive/actions/runs/45614308923) passed at `c7323c8a2ab8ea4ac63f4ed81cfb7e400e74abf1`. Target desktop validation (N4) remains outstanding; these runs do not verify unmerged topics.

Personal wallpapers, fonts, artwork and runtime state are not bundled. Wallpaper metadata serves as a theme reference, not permission to redistribute the associated images. Obtain local assets separately from authorized sources. See [asset guidance](docs/assets.md) and [design language](docs/product/VISION_AND_DESIGN_LANGUAGE.md).

## License and AI-assisted development

Project-authored software is licensed under GPL-3.0-or-later; original artwork and documentation under CC BY 4.0, subject to applicable third-party terms and the rights actually held by contributors. See [licensing scope](LICENSING.md), [GPL license](LICENSE), [CC BY license](LICENSES/CC-BY-4.0.txt) and [attribution](ATTRIBUTION.md).

Astral Archive is a non-commercial personal project developed extensively using generative AI for implementation, visual assets, documentation and testing, under human direction and review. The project is shared openly for learning, experimentation, modification and reuse; this intent does not restrict commercial use permitted by the licenses.
