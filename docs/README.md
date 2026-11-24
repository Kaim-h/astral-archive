# Astral Archive documentation index

Current source establishes implementation, accepted product requirements establish intended behavior, and named checks establish verification. Technical decisions, constraints and reproducible evidence must be recoverable from this repository without relying on private conversations.

## Available at this checkpoint

- [Contribution requirements](../CONTRIBUTING.md) — engineering, design, verification, documentation and review.
- [Contributor entry point](../AGENTS.md) — startup instructions.
- [Topic workflow](development/TOPIC_WORKFLOW_AND_HANDOFF.md) — branch continuity, checkpoints and review.
- [Asset guidance](assets.md) — redistribution and local-resource boundaries.

## Planned technical index

The complete baseline will include architecture, product specifications, current implementation and active-work records, development/bring-up guides, source and tests, relevant accepted prototypes and provenance. Links will be added as the reviewed files arrive. This checkpoint does not assert that those files are present or that any runtime checks have passed.

## Status vocabulary

- **DECIDED** — accepted product requirement.
- **DIRECTION** — supported preference open to refinement.
- **CANDIDATE** — idea, not approved for implementation.
- **IMPLEMENTED SOURCE** — code exists in the checked-out revision.
- **OFFLINE-VERIFIED** — named static/pure-policy checks passed.
- **BROWSER-VERIFIED** — named browser checks passed.
- **QT-OFFSCREEN-VERIFIED** — actual Qt Quick engine checks passed; not target Quickshell evidence.
- **NATIVE-VERIFIED** — exercised in the actual target Quickshell / Hyprland desktop.
- **PROTOTYPE** — exploratory implementation.
- **SUPERSEDED** — historical, no longer authoritative.

Identify exact revision and named check when reporting evidence; distinguish tests not run from actual failures.
