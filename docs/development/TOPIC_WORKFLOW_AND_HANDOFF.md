# Development topics and contributor handoff

This guide expands [CONTRIBUTING.md](../../CONTRIBUTING.md); it is not permission to merge, delete branches or expand scope.

## One topic, one continuing branch, one PR

A topic is a coherent reviewable goal, not a conversation, edit or version number. Fixes, iterations, refinements, tests, failure reports and related documentation belong to its existing open PR. Commit meaningful checkpoints. A pushed draft branch is durable; merging integrates it.

| Situation | Action |
|---|---|
| New contributor, same topic | Resume existing branch and PR after inspecting head and diff. |
| New revision or defect in open PR | Focused commit on same branch; run relevant checks. |
| Related documentation | Same branch, separate commit when practical. |
| Distinct independent topic | Start from updated main after dependencies integrate; owner agreement for parallel/stacked work. |
| Owner merged topic | Preserve merged PR as historical checkpoint; do not append to stale branch by default. |
| Concurrent changes | Stop publishing, inspect latest head and reconcile without overwriting. |

Before editing, read contribution instructions, docs index, current-state and active-work records when available. Inspect open PRs, main and candidate branch heads; inspect local status/diff if using a checkout. Connector-only contributors must disclose inability to inspect local changes when relevant. Identify existing scope, latest commits and affected files. Read the relevant technical contract and accepted reference, not every historical revision.

Maintain base and branch of the active topic. Do not retarget, stack, delete, merge or change visibility without required owner authorization. No force pushes. Coordinate sequential checkpoints or explicitly disjoint paths. For a distinct topic use a descriptive branch and reviewable draft PR. Confirm expected head immediately before publishing, using non-force expected-head updates where available; stop on concurrent changes.

## Checkpoint and review

Maintain the PR description as a living, visitor-readable overview using the [PR documentation standard](PR_DOCUMENTATION_STANDARD.md), including for small changes. The principal contributor refreshes it at meaningful milestones, changes of disposition, handoff and closeout. Preserve unique old evidence and decisions in durable docs or checkpoint comments before replacing an accumulating description. Keep technical checkpoint discussion and independent reviews intact; link them from the overview. On integration, record actual outcome and exact post-merge evidence or explicitly pending checks. Do not change another contributor's PR without coordination.

Inspect actual changes and exact artifact bytes. Record base/head, commands, outcomes and uncertainty. Older CI is historical evidence only. Record the event (push or pull request), exact checked-out commit/tree, run/attempt and relevant job results; distinguish a prospective merge tree from the topic head. For intermittent failures and intermediate-state evidence use [regression verification](REGRESSION_VERIFICATION.md). Update PR discussion when useful. Log significant failures and recovery; do not hide failures or mark ready solely to obtain a merge. Owner controls integration and branch deletion; verify dependencies and unique commits before suggesting cleanup. After integration verify actual main head and post-merge checks.

For a substantial milestone record topic, branch/PR/base/head, scope, next concrete step, requirements versus candidates, canonical paths, actual tests and outcomes, observed failures and renders, open invariants, blockers and pending decisions in the relevant technical documentation. Preserve identity, user data, KDE/TTY recovery, and no production shell exposure or autostart without validation.

Visual revisions must assert that intended changed output differs and unaffected outputs stay unchanged; verify internal version and delivered blob hash, assert real unforced input results and support/scale, inspect actual renders. Rejected B7p3 and initial byte-identical P9 are negative examples. Offscreen Qt is real Qt but not target desktop validation; SVG structure/decode is not Qt visual fidelity.

The source and tests establish implementation; accepted product documents establish intended behavior; named checks establish verification. Report contradictions rather than promoting candidates silently. Do not resume ordinary development against an incomplete baseline.
