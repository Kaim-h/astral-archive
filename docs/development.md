# Development and testing workflow

## Source of truth and continuity

The Git repository is the portable source of truth for implementation and durable project knowledge. Read `AGENTS.md`, `docs/README.md`, `docs/development/CURRENT_STATE.md` and `docs/development/ACTIVE_WORK.md` at the beginning of a substantial task. Then load only the product / subsystem docs and source relevant to that task.

Conversation history and ChatGPT Memory are optional conveniences, not dependencies. After significant work, update the relevant specifications, decisions, current state and active-work record so a fresh conversation or another AI tool can resume without a chat transcript.

## Delivery and ownership

Use **one continuing branch and one PR per active development topic**. Continue fixes, revisions, docs and CI corrections in that same PR, even across conversations and agents. Inspect open PRs, remote head and local worktree/diffs before editing. Start distinct topics from updated main after dependencies integrate, or with an explicitly agreed dependency plan. See [topic workflow and handoff](development/TOPIC_WORKFLOW_AND_HANDOFF.md). Do not overwrite user work, directly push to main, force-push, merge or delete branches without required owner authorization. Changes-only ZIPs remain optional; record exact paths and status.

## Offline checks

From repository root, run the checks relevant to the change. The GitHub Actions workflow runs the offline JavaScript / source checks configured in `.github/workflows/logic-checks.yml`.

Examples:

```sh
node scripts/check-launcher.js
node scripts/check-windows.js
node scripts/check-shelves.js
node scripts/check-utilities.js
node scripts/check-veranda.js
node scripts/check-vista-fx.js
node scripts/check-gallery.js
node scripts/check-gallery-customization.js
node scripts/check-gallery-dome-p5.js
node scripts/check-structure.js
```

Use the workflow and actual files to confirm the current list; do not assume this example is exhaustive or that every script is included in CI.

These checks validate pure JavaScript policy, assertions over source text and / or repository structure. They do not prove QML parsing, Quickshell module availability, shader compilation, Wayland focus / anchoring, hardware service behavior, visual fidelity or performance.

## Interaction and rendering regressions

Use [regression verification](development/REGRESSION_VERIFICATION.md) for practical browser and offscreen Qt test design, diagnostic capture and identity-domain checks. Retain historical regression gates, distinguish actual operation completion from input delivery, and test intermediate states as well as settled results. Read the relevant source, accepted reference and workflow before changing a test.

## Native validation

When the target Linux machine is available:

- Record Fedora, kernel, GPU / driver, Hyprland, Quickshell and Qt versions.
- Confirm Plasma and TTY / terminal fallback before starting.
- Verify Quickshell modules and external services referenced by source.
- Run `qmllint` where compatible with installed imports, then run the shell manually under Hyprland.
- Verify the global shortcuts in both QML and Hyprland configuration.
- Test launcher focus and multiple-window behavior; popup anchoring and dismissal; workspace controls; audio, battery, brightness, Wi-Fi and Bluetooth; Veranda / awww; Gallery / MPRIS / shaders; fractional scale and multiple monitors.
- Capture terminal logs, screenshots and exact reproduction steps.
- Enable autostart only after manual behavior and recovery are reliable.

Detailed assumptions live in `docs/development/ENVIRONMENT.md`. The merged Patch 12/Batch 13 work includes the first-hour guide at `docs/bringup.md`. Target desktop testing remains pending; existing B6 tests are actual generic offscreen Qt Quick tests, not a Fedora/Hyprland session.

## Product / prototype discipline

Distinguish approved product requirements from prototypes. The HTML Map Room and Storage Workshop files are browser research, not native code. A prototype result can guide geometry and behavior but does not prove native QML behavior. Preserve regression history rather than blindly porting old versions.

## Asset and license workflow

Preserve attribution for adapted code. Do not commit copyrighted wallpapers, fonts, Gallery artwork, private machine configuration or third-party reference material without checking rights and repository visibility. Keep personal assets local / ignored where appropriate. Public distribution requires a separate privacy / licensing audit.
