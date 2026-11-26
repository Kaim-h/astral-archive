# Astral Archive — development history

A readable retrospective of how Astral Archive developed, why major changes were made and where to find the original evidence. This is not a release changelog: integrated source, standalone studies, accepted designs and production-ready features are different things.

**Initial history snapshot: November 26, 2026.** Dates below refer to recorded research milestones or public PR integration, not release dates. Earlier development is summarized from retained repository records; no complete day-by-day chronology is implied.

For the latest work, see [current state](CURRENT_STATE.md), [active work](ACTIVE_WORK.md) and the [roadmap](../archive-roadmap.md). For detailed historical records, exact revisions, rejected alternatives and regression evidence, see the [engineering history index](history/README.md).

## 1. Desktop foundations — early development through November 17

Astral Archive began as an illustrated Linux desktop shell, with applications represented by books. The goal was an atmospheric interface that still made everyday tasks practical.

| Earlier batch | Development |
|---|---|
| 1–5 | Illustrated books, shelves, themes, a floating launcher and keyboard-first application access. |
| 6–7 | Window awareness, focus and workspace controls; the compact Archive Capsule replaced the earlier full-width bar direction. |
| 8–9 | Utility Shelf system controls and Veranda of Vistas wallpaper selection. |
| 10–11 | Celestial Gallery artwork display, observatory-inspired rendering, constellation selection and procedural skies. |
| Patch 12 / Batch 13 | Integration corrections, portable documentation, contributor guidance and native bring-up planning. |

These are the earlier desktop-shell batch numbers, not the later Archive research milestones B6–B8. Source-level development did not establish actual target desktop acceptance.

**Read more:** [historical roadmap](../archive-roadmap.md#historical-roadmap--batch-13-base-batch-11), [early checkpoint records](history/CURRENT_STATE_BATCH13_TO_N3.md), [design language](../product/VISION_AND_DESIGN_LANGUAGE.md).

## 2. Designing a physical Archive — November 20–24

The project began investigating a spatial file interface rather than immediately implementing a filesystem backend. Standalone browser studies explored nested cubbies, scroll partitions, tactile physics, transfer between supports and safe editing of populated storage.

- **November 20:** Storage Workshop, Cubby and Scroll Physics studies explored geometry, rearrangement and Map Room concepts using synthetic records.
- **November 23:** B6 iterations exposed problems with reflow, physical settling, preserved groups and preview isolation. Later variants improved bounded planning, explicit split consent and stable identity.
- **November 24:** B6r12b3 became the accepted browser behavior reference for native work. Native B6 foundations and interaction/editor work established geometry, transactions and explicit synthetic checkpoints. B7 extended the native study with additional illustrated file-object families, mixed supports and recursive furnished cubbies.

The enduring principle was that moving an illustrated object must not silently mutate a real file. These studies established reusable behavior and evidence, not a production file manager.

**Read more:** [November 20 studies](../research/prototypes/2026-11-20/README.md), [B6 research chronology](B6_RESEARCH_STATUS_2026-11-23.md), [browser/native comparison](B6_NATIVE_BROWSER_COMPARISON_2026-11-24.md), [B7 mixed cubbies](B7_N2_MIXED_CUBBIES.md).

## 3. Establishing the public baseline — November 25

The reviewed technical baseline brought the earlier desktop and isolated native Archive work into the public repository. Documentation, licensing and verification boundaries were made explicit so contributions could be understood from the repository itself.

| PR | Contribution and outcome |
|---|---|
| [#1 — Technical baseline](https://github.com/Kaim-h/astral-archive/pull/1) | Integrated the reviewed source and technical documentation. |
| [#2 — Architecture baseline](https://github.com/Kaim-h/astral-archive/pull/2) | Clarified accepted Archive contracts and evidence; integrated into #1 before main. |
| [#7 — Licensing and attribution](https://github.com/Kaim-h/astral-archive/pull/7) | Established GPL-3.0-or-later software licensing and CC BY 4.0 original artwork/documentation licensing, subject to applicable rights and third-party terms. |
| [#8 — Publication preflight](https://github.com/Kaim-h/astral-archive/pull/8) | Established contributor safeguards for public content, assets, provenance and metadata. |
| [#9 — Baseline reconciliation](https://github.com/Kaim-h/astral-archive/pull/9) | Reconciled the verified public baseline with continuing technical topics and outstanding checks. |

The public baseline passed its named offline JavaScript, Chromium and offscreen Qt Quick checks. Earlier failed infrastructure attempts and the actual target desktop gate remain documented.

**Read more:** [current-state evidence](CURRENT_STATE.md), [licensing](../../LICENSING.md), [publication preflight](../PUBLICATION_PREFLIGHT.md).

## 4. Reliability and engineering lessons — November 25

The first public corrective and external-review topics strengthened existing behavior rather than expanding feature scope. They also improved how failures and evidence are recorded.

| PR | Contribution and outcome |
|---|---|
| [#4 — Audit corrections](https://github.com/Kaim-h/astral-archive/pull/4) | Integrated AUD-16–21 fixes, including external-service parsing, visual carry cues, safe identifier lookup, cradle geometry and an intermittent browser regression. |
| [#10 — Regression guidance](https://github.com/Kaim-h/astral-archive/pull/10) | Turned those corrections into reusable verification guidance; retained unresolved causal uncertainty. |
| [#11 — External-review integration](https://github.com/Kaim-h/astral-archive/pull/11) | Integrated guarded desktop theme persistence, bounded startup recovery for theme and Veranda, and documentation reconciliation. |
| [#12 — Reference repair](https://github.com/Kaim-h/astral-archive/pull/12) | Reduced routine documentation reading while preserving historical checkpoint records; merged into #11. |
| [#13 — Theme recovery](https://github.com/Kaim-h/astral-archive/pull/13) | Added guarded returned operations and independent readback of persisted theme; merged into #11. |
| [#14 — Startup recovery](https://github.com/Kaim-h/astral-archive/pull/14) | Added bounded read deadlines, late-result protection and protected manual-only Veranda behavior after preference timeout; merged into #11. |
| [#16 — External-review closeout](https://github.com/Kaim-h/astral-archive/pull/16) | Recorded integrated decisions, verification limits and native acceptance checklist; merged into #11. |
| [#6 — Architecture review](https://github.com/Kaim-h/astral-archive/pull/6) | Consolidated architectural advice, source mapping and maintainability lessons without imposing a new runtime architecture. |
| [#17 — Research recovery](https://github.com/Kaim-h/astral-archive/pull/17) | Restored 25 earlier HTML studies and four research notes, retaining source provenance and avoiding duplicate copies. |

These integrations did not establish native Quickshell service behavior, actual filesystem safety or full desktop acceptance. Veranda's write-confirmation limitation remains a bounded follow-up. The continuing [audit ledger #3](https://github.com/Kaim-h/astral-archive/pull/3) is distinct from merged corrective code.

**Read more:** [correction record](STABLE_MAIN_BUGFIXES_3.md), [regression verification](REGRESSION_VERIFICATION.md), [external-review evidence](CURRENT_STATE.md#external-review-integration), [architecture advisory](../architecture/ARCHIVE_INTERDEVELOPMENT_REVIEW_2026-11-24.md), [recovered research index](../research/prototypes/2026-11-20/ZIP_IMPORTED_SOURCES.md).

## 5. The B8 spatial Archive — November 25–26

The next design phase expanded individual storage units into a coherent architectural hierarchy: Map Room → Room → Shelf → recursive Cubby. The design explored shared doors, plan and perspective navigation, physical casework, appearance and support relationships.

| PR | Contribution and outcome |
|---|---|
| [#5 — B8 architectural design](https://github.com/Kaim-h/astral-archive/pull/5) | Produced the frozen S20 design/reference baseline. Its work reached main through the reconciled #18 integration, not a second independent native implementation. |
| [#18 — Design integration](https://github.com/Kaim-h/astral-archive/pull/18) | Integrated the design contract and implementation handoff with the updated public main, preserving the original research references. |
| [#20 — CI efficiency](https://github.com/Kaim-h/astral-archive/pull/20) | Reduced duplicate CI runs and Chromium setup work while retaining the regression commands and required verification scope. |

At this snapshot, main after #20 was `494b0f8493adbf072884ee0fd5906a6a8c69240b`; [CI 45750244590](https://github.com/Kaim-h/astral-archive/actions/runs/45750244590) passed all three jobs. The integrated design is not yet integrated native B8 source.

**Read more:** [B8 product contract](../product/B8_SPATIAL_ARCHIVE.md), [S20 reference matrix](../research/prototypes/2026-11-24/b8/S20_REFERENCE_MATRIX.md), [implementation handoff](B8_IMPLEMENTATION_HANDOFF.md), [CI efficiency record](CI_EXECUTION_EFFICIENCY.md).

## 6. Continuing work at the initial snapshot

| PR | Purpose |
|---|---|
| [#19 — Native spatial Archive](https://github.com/Kaim-h/astral-archive/pull/19) | Isolated implementation of B8 hierarchy, furnished Shelves, Room/Map navigation, appearance and integrated verification. Consult the live PR for individual milestone dispositions. |
| [#3 — Audit backlog](https://github.com/Kaim-h/astral-archive/pull/3) | Continuing independent defect and regression record, separate from implementation topics. |
| [#21 — Documentation preparation](https://github.com/Kaim-h/astral-archive/pull/21) | Visitor-facing README, milestone roadmap, PR documentation standards and preparation for final B8 documentation reconciliation, including this history. |

These entries are open-topic snapshots, not claims of completion. The earlier history remains distinct from future plans for Archive refinement, real file management, desktop quality of life and production integration.

## Maintaining this history

Add short, plain-language entries when significant topics integrate or close. State the date, what changed, why it mattered, disposition, relevant PRs and durable technical records. Group subordinate PRs with their integration topic; do not count the same work twice. Distinguish merged, superseded, abandoned and continuing work, and never infer a release or target acceptance from a merge.

Keep this readable without replaying every commit or test log. Preserve prior PR descriptions and comments; use the [PR documentation standard](PR_DOCUMENTATION_STANDARD.md) and [engineering history index](history/README.md) for deeper evidence. Refresh continuing entries when their outcome becomes known. Use actual public PR identifiers and exact evidence, not historical PR numbers as if they belonged to the current repository. Do not invent entries for gaps in PR numbering.

This initial retrospective uses retained public documentation and public PR metadata; it is not an exhaustive commit audit or an independent rerun of historical checks.
