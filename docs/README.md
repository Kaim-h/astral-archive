# Astral Archive documentation index

Current source establishes implementation, accepted product requirements establish intended behavior, and named checks establish verification. Technical decisions, constraints and reproducible evidence must be recoverable from this repository without relying on private conversations.

## Available at this checkpoint

- [Contribution requirements](../CONTRIBUTING.md) — engineering, design, verification, documentation and review.
- [Contributor entry point](../AGENTS.md) — startup instructions.
- [Topic workflow](development/TOPIC_WORKFLOW_AND_HANDOFF.md) — branch continuity, checkpoints and review.
- [Asset guidance](assets.md) — redistribution and local-resource boundaries.
- [Licensing scope](../LICENSING.md) and [attribution](../ATTRIBUTION.md) — software, artwork, documentation and external terms.

## Technical index

- [Current state](development/CURRENT_STATE.md) and [active work](development/ACTIVE_WORK.md) — integrated implementation and historical checkpoint evidence.
- [Roadmap](archive-roadmap.md) — milestones and dependencies.
- [Architecture](architecture.md) and [component map](architecture/COMPONENT_MAP.md).
- [Design decisions](design-decisions.md) and [product specifications](product/) — intended behavior and design boundaries.
- [Development guide](development.md), [environment](development/ENVIRONMENT.md) and [native bring-up](bringup.md) — dependencies, safe launch and verification.
- [Archive native studies](../quickshell/archive/README.md), [mixed cubbies](development/B7_N2_MIXED_CUBBIES.md) and [representation assets](product/REPRESENTATION_ASSETS.md).
- [Capsule](capsule.md), [utility shelf](utility-shelf.md), [Veranda](veranda-of-vistas.md), [Gallery](celestial-gallery-qml.md) and [Gallery customization](gallery-customization.md).
- [Research index](research/README.md) — standalone studies, accepted baselines and historical evidence.

Historical status entries are not live assignments. Baseline review is ongoing; no new runtime validation is claimed.

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
