# Pull request documentation standard

A public PR is both a review surface and a lasting entry point for future contributors. Write for a reader who has never seen the project discussion, including the maintainer returning months later. This standard applies to every PR, including drafts, one-line fixes, documentation and CI-only work. Scale detail to the change, not the obligation to explain it.

## Minimum description

Use the [PR template](../../.github/pull_request_template.md) for every new PR. Contributors opening via an API or connector must supply a completed description themselves; do not rely on automatic template insertion. Every section must contain meaningful information. A small PR may need only one or two sentences per section; use "None known" or "Not applicable" with a reason rather than omit a section or leave an unfilled prompt.

| Required section | Reader's question |
|---|---|
| Overview | What is this, why does it matter, and what outcome is intended? |
| Scope and changes | What changes, where, and what is deliberately excluded? What behavior or compatibility changes? |
| Status and progress | What actually exists at the stated revision, what is planned, and what is reviewed or accepted? |
| Verification | Which named checks ran, at which exact candidate revision or identical tested tree, and with what results and limitations? |
| Limitations and next steps | What remains uncertain, broken, deferred or dependent on another decision? What should happen next? |
| References and integration | Where can I recover requirements, source, durable technical rationale, evidence and review/closeout decisions? |

Use ordinary language before project abbreviations. Define a milestone or audit identifier on first use; link the relevant record rather than assume the reader knows the history. Describe user-visible effects even for changes that are not themselves visible; if there are none, say so. For a small self-contained change, a relevant source path and test/run link can suffice instead of creating a new technical document. No duplicated logs or mandatory screenshots for unrelated changes.

## Topic-level titles

Use a descriptive title that remains accurate as checkpoints advance. Examples: Development: Spatial Archive; Design: Architectural customization; Fix: Checkpoint write recovery; Audit: Stable-main regression backlog; Docs: Implementation consolidation; CI: Regression workflow efficiency; Research: Irregular Room geometry. Include milestone identifiers where useful, but not as the only explanation. One continuing topic keeps its branch and PR; a checkpoint is not a new topic. See [topic workflow](TOPIC_WORKFLOW_AND_HANDOFF.md).

## PR classification and metadata

Make each topic recognizable in the PR list without opening its description. The principal contributor maintains metadata alongside the living summary. Apply classification when opening a PR and revisit it at meaningful scope/status changes and closeout. This applies to API-created PRs as well as the web interface.

Use existing equivalent repository labels before requesting new ones. The following is the recommended vocabulary, not a claim that every label is already configured.

| Category | Suggested labels | Rule |
|---|---|---|
| Contribution type | development (or existing enhancement), design, bug, documentation, audit, research, ci | At least one primary type; add another only for substantive overlapping scope. |
| Affected component | archive, launcher, capsule, utility-shelf, veranda, gallery, infrastructure | Apply relevant component labels when available; repository-wide documentation need not name every component. |
| Outstanding conditions | blocked, needs-decision, needs-review, target-validation, regression, breaking-change | Apply only when the condition genuinely exists; remove or update resolved conditions. |

Do not create synonyms merely to match this table. Use GitHub's own draft, review, check and merge indicators rather than duplicating them with status labels. A target-validation label denotes outstanding actual target evidence, not a failed check or a new approval gate. Labels do not replace explicit limitations in the description.

| Other identification tool | Use |
|---|---|
| Milestone | Associate with an existing major development objective when relevant; do not invent release dates or milestones for individual checkpoints. |
| Assignee | Identify a real responsible GitHub contributor when appropriate; do not invent accounts for conversational roles. |
| Draft / ready for review | Keep active implementation draft where appropriate; readiness is not merge authorization. |
| Linked issues and PRs | Link actual requirements, defects and related topics; use automatic closing keywords only when closure on integration is intended. |
| Review requests | Request relevant actual GitHub reviewers when available; preserve independent review comments and dispositions. |
| Title and branch | Use descriptive topic-level identifiers and existing branch conventions; avoid renaming a live branch merely for classification. |
| Projects | Optional if useful; no duplicate tracking system required. |

If metadata access or a suitable label/milestone is unavailable, record the intended classification and limitation in the PR description or handoff, and coordinate with the maintainer. Repository-wide label creation, renaming, deletion and milestone administration require owner coordination. Do not bulk-relabel historical PRs or disturb live topics solely to apply this standard; adopt it at their next authorized checkpoint. Metadata must be publication-safe.

See the [issue management proposal](ISSUE_MANAGEMENT_STANDARD.md) for backlog classification, scope boundaries and evidence-based issue closure.

## Living summary, durable evidence

The principal contributor maintains the description; a successor inherits that responsibility. Refresh at meaningful checkpoints, review/disposition changes, failed checks or changed limitations, handoff, readiness requests and closeout. Date or pin status when it may become stale. Do not label an entire topic complete because one stage or a test suite passed. Draft, review, implementation and integration are distinct.

| Surface | Purpose |
|---|---|
| PR description | Current readable summary; at closeout, final outcome and remaining limitations. |
| PR comments and reviews | Chronological checkpoints, exact heads/runs, independent specialist assessments, failures, decisions and responses. |
| Canonical technical docs | Accepted requirements, current architecture, behavior, compatibility, invariants and operational guidance. |
| Focused historical/regression records | Reproducible investigations, negative evidence, superseded alternatives and exact milestone history. |

Before replacing a long or outdated description, preserve unique technical decisions, links, failures and evidence in a durable record or a public-safe checkpoint comment. Do not delete or rewrite historical reviews to make the result look cleaner. Link the preserved material in the new summary. Do not rely solely on GitHub's edit history. Pin source links to exact revisions when evidence matters, avoid branch links for immutable evidence, and retain reproducible test commands/specimens when CI artifacts expire. On merge/closure, record actual outcome, remaining work, merge revision and post-merge verification when available; if pending, say so. Never imply owner approval or integration that has not occurred.

Preserve public-safe technical decisions, failures and review evidence. Historical preservation does not override confidentiality, security or third-party rights obligations. If existing material contains an accidental disclosure, follow the [publication preflight incident-response procedure](../PUBLICATION_PREFLIGHT.md#suspected-accidental-disclosure) and coordinate authorized remediation rather than reproducing the sensitive content.

Reviewers should record findings independently in comments. Coordination tracks outstanding decisions; the principal contributor reconciles dispositions into the overview without replacing independent records. Documentation maintainers maintain this standard and canonical technical records, not every topic's running description. Apply this standard to continuing open PRs at their next authorized documentation checkpoint; preserve unique old material first. Closed PRs need not be rewritten. At significant topic closeout, update or coordinate a concise entry in the [development history](DEVELOPMENT_HISTORY.md), preserving the original PR and detailed evidence.

## Additional detail proportional to scope

| Topic | Add when relevant |
|---|---|
| Development | User-facing overview, milestone table, visual preview, compatibility/migration, performance and remaining verification. |
| Design / research | Objective, alternatives, selected and rejected directions, comparison evidence, distinction between research and approved implementation. |
| Fix | Observed defect, reproducible before/after behavior, established vs suspected cause, regression and remaining risk. |
| Audit | Findings, severity rationale, affected revision, reproducibility, correction status and links to separate fixes; no unapproved repairs. |
| Docs | Affected documents, reason for revision, evidence reconciled, link/consistency checks and what was not verified. |
| CI | Workflow changes, intended cost/reliability effect, executed jobs, retained coverage, actual results and limits. |

Visual evidence must be publication-cleared. Use selected labeled before/after images with conditions, exact revision, and what the comparison establishes. Do not upload private assets, paths, logs or personal details. A screenshot is not evidence of all interactions or actual target performance. Follow [publication preflight](../PUBLICATION_PREFLIGHT.md) and [regression verification](REGRESSION_VERIFICATION.md).

## Verification reporting

For substantial changes, a concise table can distinguish static/source, pure logic, browser prototype, offscreen Qt Quick, visual inspection, actual Quickshell runtime and target desktop. Record the run/attempt and tested head/tree, with link to logs or durable record. Explain why a test is relevant; identify pending, failed, canceled, blocked, not run and not applicable separately. Prior green checks are historical evidence, not a new-head pass. Do not substitute generic Qt/browser results for actual target validation or infer final design acceptance from a test. Preserve original failures and uncertainty even after corrections. A documentation-only PR can report exact diff, reference/link checks and relevant CI without claiming native changes or unnecessary runtime verification.

## Small PR example (illustrative, not an actual change)

**Title:** Docs: Clarify checkpoint load behavior

- **Overview:** Explain that loading a synthetic checkpoint replaces the current arrangement and clears Undo.
- **Scope and changes:** Update the relevant persistence guide only; no runtime or schema changes.
- **Status and progress:** Documentation candidate ready for review; not integrated.
- **Verification:** Reviewed wording against the named source revision and load test; attach the actual revision and check results. CI pending if not yet run.
- **Limitations and next steps:** No native test performed; confirm source consistency and obtain owner disposition.
- **References and integration:** Link the persistence contract, exact source/test evidence and topic PR.

The example is intentionally short. A complete description should stand on its own even if the reader never opens the comments. This standard does not create a separate technical approval authority, automatic readiness gate, release commitment or permission to merge.
