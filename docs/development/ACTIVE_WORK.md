# Active work — current topics and blockers

Snapshot: November 27, 2026, main `6c8c90733b43d24ce66aea3eba4c330c48644ad8` after merged PR #19. [Current state](CURRENT_STATE.md) records exact integrated evidence; [roadmap](../archive-roadmap.md) describes dependencies. Confirm live refs and checks before editing. Ordinary development requires explicit owner authorization; this table is not a new assignment or approval gate.

| Public PR / branch / head at snapshot | Immediate next action / dependency |
|---|---|
| B8 documentation consolidation — [#21](https://github.com/Kaim-h/astral-archive/pull/21) | Reconcile accepted integrated B8 source/evidence and proposed issue workflow; final publication/CI review and owner integration remain separate. |
| [#3](https://github.com/Kaim-h/astral-archive/pull/3) · `docs/stable-main-bug-audit-2026-11-24` · `6061b7e119468640555fe54e73855ef2be6445d4` | Audit ledger: retain AUD IDs and reconcile integrated dispositions, including AUD-22 and residual Veranda persistence verification; preserve history and audit index entries when integrating. |
| WP-03 / WP-08 follow-ups | Optional service-module isolation remains advisory. Initial WP-08 efficiency improvements integrated through #20; further provisioning/cache/parallelization proposals require measurement and separate authorization. [CI efficiency record](CI_EXECUTION_EFFICIENCY.md). |
| Veranda write confirmation | Bounded follow-up: reported save failures latch writes off; upstream atomic-commit false-success is not independently checked by Veranda. See [persistence limitation](../veranda-of-vistas.md#bounded-startup-recovery-wp-07--aud-22). No new runtime repair authorized. |
| Target desktop validation (historical N4, not B8-N4 Map Room) | Outstanding: confirm actual target dependencies and runtime, preserve KDE/TTY recovery and manual launch; [bring-up](../bringup.md) before production integration. |

Completed [#11](https://github.com/Kaim-h/astral-archive/pull/11) and subordinate #12/#14/#13/#16: WP-01/05/06 and authorized WP-07 are integrated in main. Exact merge checkpoints and CI are in [current state](CURRENT_STATE.md#external-review-integration). AUD-22 is corrected in integrated source at mock/policy evidence level; actual Quickshell validation remains outstanding.

Integrated in main at this snapshot, not continuing topics: B7-N2, AUD-01–21, publication preflight (PR #8), regression guidance (PR #10), post-cutover reconciliation (PR #9), architecture advisory [#6](https://github.com/Kaim-h/astral-archive/pull/6), November 20 prototype recovery [#17](https://github.com/Kaim-h/astral-archive/pull/17), B8 S20 design [#18](https://github.com/Kaim-h/astral-archive/pull/18) native B8 and automated N6a–d [#19](https://github.com/Kaim-h/astral-archive/pull/19) and CI-only [#20](https://github.com/Kaim-h/astral-archive/pull/20). See [current state](CURRENT_STATE.md) and [correction record](STABLE_MAIN_BUGFIXES_3.md) for exact evidence and AUD-21's remaining causal uncertainty.

Before further B8 refinement or filesystem work, confirm integrated baseline and separately authorized scope; preserve geometry, support/contact, identity, transaction/Undo and explicit persistence contracts. Indexing/reconciliation, production Archive wiring and real file actions remain future work. Do not revive merged branches by default. Coordinate overlapping paths and preserve both contributions; current-main CI is not exact-head verification of drafts.

[B8 consolidation record](B8_DOCUMENTATION_CONSOLIDATION.md) and [integrated implementation](B8_INTEGRATED_IMPLEMENTATION.md) reconcile the merged source. Actual target validation remains mandatory before production enablement. Proposed issue migration and new backlog tasks require separate owner authorization.

[History index and relocation map](history/README.md) — completed checkpoints, decisions, old PR/run/artifact references, rejected alternatives and earlier next steps. Retrieve only relevant records. [Topic workflow](TOPIC_WORKFLOW_AND_HANDOFF.md), [regression verification](REGRESSION_VERIFICATION.md) and [publication preflight](../PUBLICATION_PREFLIGHT.md) still apply.
