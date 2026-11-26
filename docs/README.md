# Astral Archive documentation index

Current source establishes implementation, accepted product requirements establish intended behavior, and named checks establish verification. Technical decisions, constraints and reproducible evidence must be recoverable from this repository without relying on private conversations.

## Contributor entry points

- [Contribution requirements](../CONTRIBUTING.md) — engineering, design, verification, documentation and review.
- [Contributor entry point](../AGENTS.md) — startup instructions.
- [PR documentation standard](development/PR_DOCUMENTATION_STANDARD.md) — mandatory readable descriptions, templates, verification and closeout continuity.
- [Topic workflow](development/TOPIC_WORKFLOW_AND_HANDOFF.md) — branch continuity, checkpoints and review.
- [Regression verification](development/REGRESSION_VERIFICATION.md) — asynchronous input, rendered output, identity domains, external contracts, geometry and CI evidence.
- [Asset guidance](assets.md) — redistribution and local-resource boundaries.
- [Publication preflight](PUBLICATION_PREFLIGHT.md) — checks before public writes, metadata and disclosure review, and escalation of uncertain material.
- [Licensing scope](../LICENSING.md) and [attribution](../ATTRIBUTION.md) — software, artwork, documentation and external terms.

## Technical index

- [B8 documentation consolidation plan](development/B8_DOCUMENTATION_CONSOLIDATION.md) — preparation and post-integration evidence gates.
- [Current state](development/CURRENT_STATE.md) and [active work](development/ACTIVE_WORK.md) — integrated implementation and active topics.
- [Development history](development/DEVELOPMENT_HISTORY.md) — readable retrospective of major milestones and public PRs.
- [Engineering history and relocation map](development/history/README.md) — detailed decisions and exact checkpoint evidence; retrieve on demand.
- [Roadmap](archive-roadmap.md) — milestones and dependencies.
- [Architecture](architecture.md) and [component map](architecture/COMPONENT_MAP.md).
- [Design decisions](design-decisions.md) and [product specifications](product/) — intended behavior and design boundaries.
- [Development guide](development.md), [environment](development/ENVIRONMENT.md) and [native bring-up](bringup.md) — dependencies, safe launch and verification.
- [Archive native studies](../quickshell/archive/README.md), [mixed cubbies](development/B7_N2_MIXED_CUBBIES.md) and [representation assets](product/REPRESENTATION_ASSETS.md).
- [Capsule](capsule.md), [utility shelf](utility-shelf.md), [Veranda](veranda-of-vistas.md), [Gallery](celestial-gallery-qml.md) and [Gallery customization](gallery-customization.md).
- [B8 spatial Archive contract](product/B8_SPATIAL_ARCHIVE.md), [feature reference matrix](research/prototypes/2026-11-24/b8/S20_REFERENCE_MATRIX.md) and [implementation handoff](development/B8_IMPLEMENTATION_HANDOFF.md) — integrated design baseline; native implementation tracked separately in active work.
- [Research index](research/README.md) — standalone studies, accepted baselines and historical evidence.

Historical status entries are not live assignments. Public baseline integration and its offline, browser and offscreen Qt verification are complete at the revision recorded in [current state](development/CURRENT_STATE.md). See [active work](development/ACTIVE_WORK.md) for continuing public PRs and outstanding checks. Actual target desktop validation remains outstanding. Ordinary development requires explicit owner authorization.

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
