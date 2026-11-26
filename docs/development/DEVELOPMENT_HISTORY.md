# Astral Archive — development history

A readable retrospective of how Astral Archive developed, why major changes were made and where to find the original evidence. This is not a release changelog: integrated source, standalone studies, accepted designs and production-ready features are different things.

**Initial history snapshot: November 26, 2026.** Dates below refer to recorded research milestones or public PR integration, not release dates. Earlier development is summarized from retained repository records; no complete day-by-day chronology is implied.

For the latest work, see [current state](CURRENT_STATE.md), [active work](ACTIVE_WORK.md) and the [roadmap](../archive-roadmap.md). For detailed historical records, exact revisions, rejected alternatives and regression evidence, see the [engineering history index](history/README.md).

## 1. Origins and early desktop development — through November 17

Astral Archive began as a personal experiment in reimagining the Linux desktop through the visual language of illustrated libraries, storybooks and celestial observatories. Initially developed in a private repository, it explored whether an atmospheric interface could coexist with the efficiency expected of a conventional desktop.

Development was extensively assisted by generative AI, with the maintainer establishing creative direction, requirements and priorities. Early work was organized into successive implementation batches. As the scope grew, the process increasingly relied on structured specifications, independent review, reproducible tests and persistent documentation.

### The illustrated launcher

The earliest implementation centered on applications represented by illustrated books arranged on shelves. Books represent applications, not individual windows or filesystem directories. Running and focused applications have distinct visual cues; the Index provides keyboard-accessible access to the wider application catalogue. Decorative animation must not delay application launch. Evening, Twilight and Midnight established the shared palette foundation.

### From launcher to desktop shell

| Earlier batch | Principal development |
|---|---|
| 1–5 | Illustrated books, shelving, ornaments, themes, floating launcher and keyboard-first navigation. |
| 6 | Multiple-window awareness, focus recency and application window selection. |
| 7 | Archive Capsule, workspace controls and pinned/running application shelves. |
| 8 | Utility Shelf and source integration with established Linux system services. |
| 9 | Veranda of Vistas wallpaper selection and transition experiments. |
| 10 | Celestial Gallery and its observatory-inspired artwork interface. |
| 11 | Gallery customization, constellation selection and procedural skies. |
| Patch 12 | Integration corrections and improved validation. |
| 13 | Persistent architecture, product and development documentation. |

These early desktop batch numbers are distinct from the later Archive research milestones B6–B8. They describe source-level development, not actual target desktop acceptance.

### Important design revisions

An earlier full-width bar gave way to the compact floating Archive Capsule, avoiding a mostly empty permanent panel while retaining access to applications, workspaces and utilities. Pinned and running-unpinned application shelves avoided duplicate representation of the same application. The design favored illustrated two-dimensional components at rest and selective dimensional effects; the forward book-tip experiment was deferred pending native testing.

Hyprland remained responsible for window placement, tiling and compositor behavior. Astral Archive would provide its own interface without recreating the underlying window manager.

The Veranda of Vistas extended customization into wallpaper selection, theme-aware presentation and transition effects. The Celestial Gallery provided a separate observatory-inspired environment for artwork. They shared a visual language but remained distinct systems because wallpaper selection and artwork presentation serve different purposes. Artwork-specific constellations, sky presets, shaders and geometric transitions increased the need for systematic rendering and integration checks.

**Read more:** [historical roadmap](../archive-roadmap.md#historical-roadmap--batch-13-base-batch-11), [early checkpoint records](history/CURRENT_STATE_BATCH13_TO_N3.md), [design language](../product/VISION_AND_DESIGN_LANGUAGE.md), [design decisions](../design-decisions.md).

## 2. Emergence of the spatial Archive and browser research — November 17–24

The next major direction was an experimental spatial file manager. Rather than treating files exclusively as icons or directory entries, the proposed Archive would represent them as physical objects arranged within architectural storage spaces.

### Establishing the physical metaphor

The initial research focused on scrolls viewed end-on, collected in customizable compartments. Instead of predetermined slots, the studies explored densely packed circular objects with varied sizes, contact and believable settling.

Several enduring requirements emerged: visual arrangement must remain independent of filesystem operations; objects retain their identities during transfers and edits; contact and support derive from coherent geometry; settled arrangements stay stable until deliberately changed. Browse and Arrange separate efficient access from structural editing, without continuous physics during ordinary browsing.

### Browser research — November 20

The Storage Workshop, Cubby and Scroll Physics studies explored natural-looking circle packing, connected storage partitions, configurable geometry, transferring scrolls, insertion into available space, resizing populated storage and recursive containers. Early Map Room studies investigated a user-authored navigable floorplan. Standalone browser studies allowed this behavior to be explored without introducing real filesystem operations into the desktop.

### The difficulties of rearranging populated storage

Early B6 variants exposed unbounded or costly reflow, unstable positions, detached previews, identifier/lineage conflicts and unintended changes to uncommitted state. Some arrangements fitted geometrically but left scrolls visually suspended; others moved populated groups unexpectedly. A valid arrangement had to do more than fit: it needed to preserve the user's organization and make necessary compromises explicit.

Later research used structured matching between existing and proposed compartments. Populated groups received priority, with bounded candidate search and settling after preservation. Splitting a populated group required explicit, revocable permission tied to the proposed dimensions. The planner remained a finite heuristic, not proof that every feasible arrangement could be found.

The portable Scroll Case evolved into a temporary holding and transport mechanism, preserving identity and origin information. The resulting transaction model separates preview, validation, consent, Apply/Cancel and Undo. Proposals do not silently change committed state.

### Choosing the native reference

On November 24 the owner accepted B6r12b3 as the behavioral reference for starting native implementation. Its recorded browser checks included continuous resizing and grouped manipulation. This established a coherent starting point without implying every stress scenario, visual question or native acceptance check was complete.

**Read more:** [November 20 studies](../research/prototypes/2026-11-20/README.md), [B6 research chronology](B6_RESEARCH_STATUS_2026-11-23.md), [B6 browser/native comparison](B6_NATIVE_BROWSER_COMPARISON_2026-11-24.md).

## 3. Native B6–B7 implementation — November 24

Native work initially remained isolated from the production desktop shell, using synthetic data to verify geometry, ownership and interaction without introducing real file operations.

| Milestone | Development |
|---|---|
| B6-N1 | DOM-free shared JavaScript model, geometry, transactions and revision-aware worker planning. |
| B6-N2 | Illustrated Qt Quick Cubby, rack and scroll rendering, theme roles and camera navigation. |
| B6-N3 | Live pointer interaction, grouped movement, Scroll Case transfers, settling and resize manipulation. |
| B6-N3r1 | Expanded structural editing, material controls, reversible transactions and explicit study checkpoints. |

The native implementation sought to preserve accepted browser behavior rather than only its appearance. Matched synthetic arrangements exposed differences in rack geometry, inscriptions, backing contrast and Case/plaque clearance. Corrections and actual capture inspection were recorded; the results did not certify every interaction or target visual parity.

### Explicit persistence

The native study introduced a versioned synthetic checkpoint format and explicit Save/Load. It preserves arrangement and view state, rejects malformed or unsupported data, and does not automatically load an arrangement at startup. The recorded restart tests used separate writer and reader processes. Production layout/index persistence and real filesystem operations remained separate future concerns.

### B7: More file representations and mixed furnished cubbies

Visual research explored framed artwork, sculptures, upright objects and wrapped parcels. Sparse parcel pictograms and gourd-like sack ribs were rejected; scientific instruments were considered but excluded from B7 implementation. The accepted visual families required distinct physical supports: sculptures need surfaces, framed art needs mounts, upright objects need holders.

B7-N2 extended the existing physical model to recursively nested cubbies with mixed fixtures and objects, rather than separate inventories per representation family. A record can appear compactly as a scroll when placed in a rack without changing its preferred appearance or file contents. A universal Scroll Case transports records between cubbies; application books retain separate identities. Occupied resize proposals preserve valid placements and require explicit rearrangement consent; no silent rescale or displacement. The shared ownership model and versioned checkpoints preserve identity and exact Undo.

Historical B6/B7 checkpoints passed their recorded JavaScript, browser and offscreen Qt Quick checks, including actual interaction and independent checkpoint restart evidence. They establish an isolated synthetic study, not production integration, actual Fedora/Hyprland/Quickshell acceptance or real filesystem safety. The original target desktop validation milestone (historically called N4) remains separate from the later B8-N4 Map Room milestone.

**Read more:** [B6 native comparison](B6_NATIVE_BROWSER_COMPARISON_2026-11-24.md), [B7 representation work](B7_NATIVE_REPRESENTATION_WORK.md), [mixed cubbies](B7_N2_MIXED_CUBBIES.md), [representation contract](../product/REPRESENTATION_ASSETS.md), [native source guide](../../quickshell/archive/README.md).

## 4. Evolution of the development process

Early implementation batches were increasingly supplemented by technical documentation, persistent handoffs, research archives and formalized design decisions. Responsibilities for implementation, visual design, defect investigation, corrective work and documentation became more differentiated. Independent review was particularly valuable where green automated checks did not establish correct visual behavior or interaction.

The project adopted one continuing topic per branch and PR, evidence distinctions between requirements, prototypes, implemented source and verified results, preservation of rejected alternatives and failures, and continuity independent of any one conversation. The maintainer retained integration and acceptance decisions.

A durable repository record became necessary as AI-assisted development produced a growing body of code, research and decisions. This history summarizes that evolution without reproducing private instructions, correspondence or unpublished materials.

**Read more:** [contribution requirements](../../CONTRIBUTING.md), [topic workflow](TOPIC_WORKFLOW_AND_HANDOFF.md), [engineering history index](history/README.md).

## 5. Transition to public development and baseline integration — November 24–25

The transition to public development was prompted in part by the exhaustion of available private-repository continuous integration (CI) resources.

By this stage, automated verification had become central to the development process. Rather than reduce testing coverage to accommodate the available compute resources, the project transitioned to a separately prepared and reviewed public repository, where development and verification could continue more sustainably.

This practical constraint accelerated the project's transition toward open-source development while providing an opportunity to improve documentation, establish explicit licensing and separate publishable technical material from private development records.

The original repository was retained as a private historical archive. The public repository became the authoritative location for continuing technical development, review and integration. The earlier technical work was carried forward rather than restarted, explaining why the first public PR already contained substantial source, research and documentation. Historical PR numbers in retained engineering records refer to the earlier development period, not the public PR numbering.

Publication was an organizational and engineering milestone, not a software release. The existing implementation limitations, unresolved defects and actual target validation requirements remained applicable. Early failed CI attempts did not establish an executed-test failure; subsequent public verification is documented below.

| PR | Contribution and outcome |
|---|---|
| [#1 — Technical baseline](https://github.com/Kaim-h/astral-archive/pull/1) | Integrated the reviewed source and technical documentation. |
| [#2 — Architecture baseline](https://github.com/Kaim-h/astral-archive/pull/2) | Clarified accepted Archive contracts and evidence; integrated into #1 before main. |
| [#7 — Licensing and attribution](https://github.com/Kaim-h/astral-archive/pull/7) | Established GPL-3.0-or-later software licensing and CC BY 4.0 original artwork/documentation licensing, subject to applicable rights and third-party terms. |
| [#8 — Publication preflight](https://github.com/Kaim-h/astral-archive/pull/8) | Established contributor safeguards for public content, assets, provenance and metadata. |
| [#9 — Baseline reconciliation](https://github.com/Kaim-h/astral-archive/pull/9) | Reconciled the verified public baseline with continuing technical topics and outstanding checks. |

The public baseline passed its named offline JavaScript, Chromium and offscreen Qt Quick checks. Earlier failed infrastructure attempts and the actual target desktop gate remain documented.

**Read more:** [current-state evidence](CURRENT_STATE.md), [licensing](../../LICENSING.md), [publication preflight](../PUBLICATION_PREFLIGHT.md).

## 6. Reliability and engineering lessons — November 25

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

## 7. The B8 spatial Archive — November 25–26

The next design phase expanded individual storage units into a coherent architectural hierarchy: Map Room → Room → Shelf → recursive Cubby. The design explored shared doors, plan and perspective navigation, physical casework, appearance and support relationships.

| PR | Contribution and outcome |
|---|---|
| [#5 — B8 architectural design](https://github.com/Kaim-h/astral-archive/pull/5) | Produced the frozen S20 design/reference baseline. Its work reached main through the reconciled #18 integration, not a second independent native implementation. |
| [#18 — Design integration](https://github.com/Kaim-h/astral-archive/pull/18) | Integrated the design contract and implementation handoff with the updated public main, preserving the original research references. |
| [#20 — CI efficiency](https://github.com/Kaim-h/astral-archive/pull/20) | Reduced duplicate CI runs and Chromium setup work while retaining the regression commands and required verification scope. |

At this snapshot, main after #20 was `494b0f8493adbf072884ee0fd5906a6a8c69240b`; [CI 45750244590](https://github.com/Kaim-h/astral-archive/actions/runs/45750244590) passed all three jobs. The integrated design is not yet integrated native B8 source.

**Read more:** [B8 product contract](../product/B8_SPATIAL_ARCHIVE.md), [S20 reference matrix](../research/prototypes/2026-11-24/b8/S20_REFERENCE_MATRIX.md), [implementation handoff](B8_IMPLEMENTATION_HANDOFF.md), [CI efficiency record](CI_EXECUTION_EFFICIENCY.md).

## 8. Continuing work at the initial snapshot

| PR | Purpose |
|---|---|
| [#19 — Native spatial Archive](https://github.com/Kaim-h/astral-archive/pull/19) | Isolated implementation of B8 hierarchy, furnished Shelves, Room/Map navigation, appearance and integrated verification. N1–N3 reached scoped implementation and review checkpoints; N3h verification passed. Owner-authorized B8-N4 Map Room work began; the first native navigation regression failed. See [active work](ACTIVE_WORK.md) for the pinned snapshot and live PR for later dispositions. |
| [#3 — Audit backlog](https://github.com/Kaim-h/astral-archive/pull/3) | Continuing independent defect and regression record, separate from implementation topics. |
| [#21 — Documentation preparation](https://github.com/Kaim-h/astral-archive/pull/21) | Visitor-facing README, milestone roadmap, PR documentation standards and preparation for final B8 documentation reconciliation, including this history. |

These entries are open-topic snapshots, not claims of completion. The earlier history remains distinct from future plans for Archive refinement, real file management, desktop quality of life and production integration.

## Maintaining this history

Add short, plain-language entries when significant topics integrate or close. State the date, what changed, why it mattered, disposition, relevant PRs and durable technical records. Group subordinate PRs with their integration topic; do not count the same work twice. Distinguish merged, superseded, abandoned and continuing work, and never infer a release or target acceptance from a merge.

Keep this readable without replaying every commit or test log. Preserve public-safe prior PR descriptions and comments, subject to [publication preflight](../PUBLICATION_PREFLIGHT.md) and authorized disclosure remediation; use the [PR documentation standard](PR_DOCUMENTATION_STANDARD.md) and [engineering history index](history/README.md) for deeper evidence. Refresh continuing entries when their outcome becomes known. Use actual public PR identifiers and exact evidence, not historical PR numbers as if they belonged to the current repository. Do not invent entries for gaps in PR numbering.

This retrospective uses retained public technical documentation, public PR metadata and a reviewed high-level account of the publication transition; it is not an exhaustive commit audit or an independent rerun of historical checks.
