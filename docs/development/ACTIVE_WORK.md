# Active work — current topics and blockers

Snapshot: November 25, 2026, verified main `6c263d9e149869506fffde4746e95e9936d9a0f0` ([CI 45615829704](https://github.com/Kaim-h/astral-archive/actions/runs/45615829704), all three jobs passed). Confirm live refs, PR state and actual checks before editing. [Current state](CURRENT_STATE.md) records integrated source/evidence; [roadmap](../archive-roadmap.md) describes dependencies. Ordinary development requires explicit owner authorization; this table is not a new assignment or approval gate.

| Public PR / branch / head at snapshot | Immediate next action / dependency |
|---|---|
| [#11](https://github.com/Kaim-h/astral-archive/pull/11) · `development/theme-persistence` · `c3565ec06fb75785f8057526488edbef39cc6347` | Theme persistence: review candidate and named checks; no integration assumed. |
| [#6](https://github.com/Kaim-h/astral-archive/pull/6) · `docs/archive-architecture-stewardship` · `aa353e373f1c5493853bffd01a181435867eb70c` | Architecture advisory: review proposals independently and reconcile shared docs. Recommendations are not implementation scope. |
| [#5](https://github.com/Kaim-h/astral-archive/pull/5) · `design/archive-b8-architecture` · `e3b1e8a701bd67cf5f5c25de19b53c82b06ce2b5` | B8 design: evaluate current candidates and evidence; finalize support, placement, interaction contracts and visual acceptance before dependent implementation. No final acceptance or native implementation implied. |
| [#3](https://github.com/Kaim-h/astral-archive/pull/3) · `docs/stable-main-bug-audit-2026-11-24` · `96a7f59c3454a10a2f9426ddb8ca7026a68ccc70` | Audit ledger: retain AUD IDs, reconcile integrated fixes and preserve evidence. |
| Reference/context-consolidation topic | Correct dangling references and reduce routine reading without losing evidence; keep review-only proposals separate. |
| N4 target validation | Outstanding: confirm actual target dependencies and runtime, preserve KDE/TTY recovery and manual launch; [bring-up](../bringup.md) before production integration. |

Integrated, not continuing topics: B7-N2, AUD-01–21, publication preflight (PR #8), regression guidance (PR #10), post-cutover reconciliation (PR #9). See [current state](CURRENT_STATE.md) and [correction record](STABLE_MAIN_BUGFIXES_3.md) for exact evidence and AUD-21's remaining causal uncertainty.

Before dependent native B8 or filesystem work, obtain accepted design handoff and authorized scope; preserve geometry, support/contact, identity, transaction/Undo and explicit persistence contracts. Indexing/reconciliation, production Archive wiring and real file actions remain future work. Do not revive merged branches by default. Coordinate overlapping paths and preserve both contributions; current-main CI is not exact-head verification of drafts.

[History index and relocation map](history/README.md) — completed checkpoints, decisions, old PR/run/artifact references, rejected alternatives and earlier next steps. Retrieve only relevant records. [Topic workflow](TOPIC_WORKFLOW_AND_HANDOFF.md), [regression verification](REGRESSION_VERIFICATION.md) and [publication preflight](../PUBLICATION_PREFLIGHT.md) still apply.
