# Issue management standard — proposal

Status: proposed workflow for owner review and adoption. Integration of this document and templates does not itself reassign roles, migrate findings, authorize implementation or establish a release commitment.

## Purpose and boundaries

Use GitHub Issues for independently actionable defects, feature proposals, research and verification tasks. The roadmap remains the high-level direction; issues form the granular backlog; pull requests contain proposed changes and review; technical documentation preserves accepted requirements, architecture and durable evidence. Link rather than duplicate records. Search existing issues, audit records and PRs before opening a new issue.

Recording an idea, accepting its direction, scheduling work and authorizing implementation are distinct decisions. New ideas outside an active PR's accepted scope belong in the backlog, not an unsolicited expansion of that PR. Public contributions and issue attachments must follow [publication preflight](../PUBLICATION_PREFLIGHT.md). Never reproduce private logs, identifiers or assets.

## Classification and lifecycle

Use existing equivalent labels for type (bug, enhancement/feature, research, verification), affected component and meaningful outstanding conditions. Suggested additional classifications include suspected, confirmed, architectural-risk, proposed, accepted-backlog, blocked and target-validation. These are suggested vocabulary, not an inventory of configured labels. Do not duplicate native open/closed indicators. Record classification in the issue body if metadata is unavailable; coordinate repository-wide taxonomy changes with the owner. Severity describes impact; priority describes scheduling. Neither implies authorization. Explain severity and priority rather than rely on a label alone.

| Stage | Meaning |
|---|---|
| Proposed / reported | Record the need or suspected defect; no implementation authority. |
| Under consideration | Investigate evidence, feasibility, design and dependencies. |
| Accepted backlog | Owner accepts direction or recognizes a defect; not necessarily scheduled. |
| Scheduled | Owner authorizes bounded work; coordinate milestone and assignment. |
| In development | Link authorized design/corrective/implementation PRs. |
| Resolved | Acceptance criteria met with named evidence; close with disposition. |

Rejected, duplicate, superseded and withdrawn issues may be closed with a reason and relevant links; do not describe them as implemented. Reopen when evidence warrants. Use milestones for meaningful development objectives, not invented dates; assign real contributors only. Keep status and evidence current at meaningful checkpoints, not every transient commit.

## Minimum issue content

Use the relevant template in [issue templates](../../.github/ISSUE_TEMPLATE/). API-created issues must supply equivalent content. Scale detail to scope; explain unknown or inapplicable fields. Include a descriptive title, type/component, objective or observed problem, scope and exclusions, dependencies, evidence and limitations, acceptance criteria or investigation deliverable, authorization status and related records.

- Defects: retain stable audit ID when assigned, severity rationale, exact inspected revision, expected/observed behavior, reproduction or source evidence, confidence (suspected/confirmed/risk), correction criteria and independent verification.
- Features: rationale, intended behavior, alternatives/open questions, dependencies, scope boundary, acceptance criteria to refine before implementation.
- Research: question, method, alternatives, constraints, evidence and expected decision/deliverable; exploratory work is not approved production implementation.
- Verification: target revision, environment, named checks, expected results, actual evidence and limitations. Distinguish not run, blocked, failed and passed; offscreen Qt is not actual target desktop evidence.

## Roles and authorization

The owner approves direction, priority and implementation scope. The Secretary coordinates scheduling, milestones and handoffs. The Designer refines interaction and appearance proposals; the Librarian advises on architecture and maintains canonical documentation. The Developer implements authorized features; the Bugfinder investigates and independently verifies findings; the Bugfixer implements authorized corrections. Contributors may propose work without acquiring implementation authority. Existing assignment and review boundaries remain in force until separately changed.

## Proposed Bugfinder transition

Preserve the existing [audit ledger PR #3](https://github.com/Kaim-h/astral-archive/pull/3) as historical evidence. After separate owner authorization and coordination with the Bugfinder and Secretary:

1. Inventory outstanding findings against exact current source and correction/verification records; distinguish confirmed defects, suspected defects and risks.
2. Migrate only unresolved independently actionable findings, retaining audit IDs, severity, exact evidence, negative results, uncertainty, dependencies and links to the original ledger and corrective PRs.
3. Cross-reference each migrated issue from the ledger at an authorized checkpoint; avoid two competing live trackers. Leave resolved findings in history unless a new actionable regression warrants an issue.
4. Adopt individual issues as the primary tracking surface for new authorized Bugfinder investigations; preserve consolidated technical lessons in regression/architecture documentation. No automatic repairs or new audit assignment follow from migration.

Do not bulk-create issues or alter the ledger merely by adopting this proposal. Existing live PRs are not to be disturbed solely for migration.

## Closure and evidence

Link implementation PRs to their issues and retain independent verification and unresolved limitations. A merged PR is not proof that all acceptance criteria are satisfied. Use non-closing references when actual target validation or other evidence remains outstanding; use automatic closing keywords only when integration satisfies the agreed closure conditions. Record exact integrated revision, named checks, outcome and remaining limitations before closure. See [PR documentation standard](PR_DOCUMENTATION_STANDARD.md) and [regression verification](REGRESSION_VERIFICATION.md).

Illustrative future backlog topics include irregular Rooms, custom color selection, imported maps/backgrounds and desktop notifications. These examples neither change the active B8 implementation scope nor create assignments.
