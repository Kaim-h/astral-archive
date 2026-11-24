# Contributing to Astral Archive

These technical and review requirements apply equally to human contributors, AI coding tools and other automated contributors. Product requirements and implementation facts live in the relevant technical documentation and source. A contribution is not authorization to change project scope or integrate work.

## Start here

1. Read `README.md` and `docs/README.md`.
2. Read `docs/development/CURRENT_STATE.md` and `docs/development/ACTIVE_WORK.md` when present; during baseline preparation consult the checkpoint status in the README. Do not start implementation against an incomplete baseline.
3. For representation work read `docs/product/REPRESENTATION_ASSETS.md` and the asset manifest; consult only the relevant accepted prototype if needed. Identify the requested subsystem and read only its relevant specification, existing documentation, source files, tests, and applicable ADRs.
4. Check the current Git branch/head and inspect the working tree before editing. Never assume an older handoff's commit is still current.

## Authority and evidence

Keep these categories distinct:

- **Implemented source:** what is actually present in the current checked-out repository.
- **Approved product requirement:** behavior/design explicitly decided by the owner and recorded in product specifications or accepted decisions.
- **Direction:** a supported design preference that still permits refinement.
- **Candidate:** an idea, not an approved requirement.
- **Prototype:** an exploratory HTML/SVG/JavaScript study, not production QML.
- **Verified:** only what a named check was actually run to verify.

When sources conflict, use this precedence:

1. Current source and tests for what is implemented.
2. The latest accepted product specification / decision for intended behavior.
3. Current `docs/development/CURRENT_STATE.md` for the verified status snapshot.
4. Historical handoffs and prototypes for context only; they may be superseded.

Do not turn a candidate or prototype shortcut into an approved requirement. Do not claim QML, Wayland, Hyprland, shader, MPRIS or hardware behavior is verified based only on static text checks or browser prototypes.

## Product and design integrity

- Astral Archive is a practical, functional Linux desktop/archive interface with a quiet illustrated storybook-library / observatory visual language.
- Keep it useful, legible, responsive, keyboard-accessible and low-clutter. Tactile effects are secondary to ordinary desktop tasks.
- Preserve coherent physical support, contact points, occlusion, object identity and believable fixture geometry. Do not place objects with unrelated arbitrary pixel offsets.
- Preserve the existing Evening, Twilight and Midnight theme roles and established components unless the task explicitly changes them.
- Keep Hyprland responsible for compositor, window placement, tiling and workspaces. Astral Archive does not implement a replacement window manager.
- Keep Veranda wallpaper selection separate from Celestial Gallery artwork.

## Engineering discipline

- Inspect existing code and callers before changing an interface.
- Prefer a narrow, reversible change over unrelated rewrites.
- Identify affected components, signals, state, services, external dependencies and user-visible behavior before implementation.
- Reuse existing QML components and services where appropriate; avoid duplicate implementations.
- Treat transient runtime identifiers (for example Hyprland window addresses) as transient; do not persist them unless a specification explicitly defines a safe identity model.
- Treat filesystem identity, virtual organization and visual placement as separate concepts. A visual rearrangement must not silently move, rename or delete real files.
- Use mature Quickshell/Linux APIs and services; report unavailable dependencies honestly rather than presenting fake controls.
- Preserve licenses and attribution for adapted code and assets. Never commit personal wallpapers, fonts, gallery artwork, private paths or third-party reference images without checking permission and intended repository visibility.
- Never expose credentials, tokens, personal databases or machine-specific secrets.

## Validation requirements

Classify evidence accurately:

- **Static/source check:** file structure, text assertions, import-path checks.
- **Pure logic/unit check:** deterministic JavaScript policy/model tests.
- **Browser prototype check:** standalone HTML interaction/geometry only.
- **Offscreen Qt Quick check:** actual Qt QML engine and software rendering, not Quickshell/Wayland integration.
- **Quickshell runtime check:** actual Quickshell process and installed module behavior, distinct from generic Qt Quick.
- **Native desktop check:** actual Fedora/KDE/Hyprland/Wayland session, hardware and service integration.

Run the checks relevant to the change and report exact commands and outcomes. Do not say "tests pass" without saying which tests ran. A successful offline check is not a native runtime sign-off.

For risky desktop/session changes, preserve the KDE/TTY recovery path, a known-good Git state and a manual terminal launch route. Avoid changing autostart/boot/system services as a cosmetic convenience.

## Documentation and continuity

After a substantial change:

- Update the relevant feature / architecture documentation.
- Update `docs/development/CURRENT_STATE.md` only with evidence-supported status.
- Update `docs/development/ACTIVE_WORK.md` when the active task changes.
- Record durable technical decisions in `docs/design-decisions.md` or a focused ADR; explicitly mark candidates and superseded decisions.
- Update `docs/archive-roadmap.md` when milestone status or dependencies change.
- Preserve noteworthy regression lessons and reproducible test cases.

Do not summarize every chat message. Preserve the requirements, decisions, constraints, assumptions, verified facts, failures and next actions that another contributor cannot reliably reconstruct from source alone.

## Git and user control

- Do not commit or push directly to `main`. Repository visibility changes require explicit owner authorization.
- Use a focused branch and reviewable pull request for non-trivial changes.
- Never discard or overwrite uncommitted user work. Check status and diffs first.
- Do not rewrite Git history or run destructive reset/clean commands unless the owner explicitly requests it and the working tree is known safe.
- Keep generated shader binaries (`*.qsb`) and personal runtime state out of commits unless the project explicitly changes that policy.

## Reproducible contributor continuity

Project requirements and technical evidence must be recoverable from the repository itself. A new contributor should be able to resume by reading this file, the documentation index, current-state / active-work records, relevant feature docs and source. Never require a private conversation transcript as the only source of a requirement.

### Branch integrity and development workflow

The `main` branch is the owner-controlled integration branch.

- Never commit or push directly to `main`.
- Never merge a pull request without explicit owner authorization.
- Never force-push or rewrite published history.
- Never delete branches without explicit owner authorization.
- **One continuing branch and one PR per active development topic.** A revision, bug fix, validation fix, documentation pass, new chat, or change of agent is not a new topic. Reuse the existing open branch/PR, including after a handoff.
- Before starting a branch, inspect open PRs and remote branch heads. Read the existing PR scope and latest commits; do not restart from main while related work is pending.
- Keep work focused: unrelated features are not part of the topic merely to avoid a new branch. After owner merge, start the next distinct topic from updated main. Follow-up to a merged topic starts from current main rather than reviving its stale branch by default.
- A stacked dependency or parallel experimental branch requires a clear technical reason and owner agreement. Record base, dependencies and merge order.
- Coordinate same-topic agents by sequential checkpoints or explicitly disjoint paths. Verify latest remote head before publishing; use a non-force expected-head update where supported. Stop on concurrent changes instead of overwriting them.
- Commit and push meaningful implementation checkpoints.
- Verify the target branch and latest remote commit before modifying source.
- Preserve existing work and report conflicts rather than silently overwriting changes.
- Stop and request clarification if an operation would violate these requirements.

These requirements apply to all contributors. See the topic workflow guide at `docs/development/TOPIC_WORKFLOW_AND_HANDOFF.md` once included.

### Visual regression safeguards

Assert replacements match; compare changed and unchanged artwork, verify internal version and delivered blob hash. Assert real unforced input results, support/scale geometry and inspect real captures. No page errors or forced clicks alone do not establish success. Do not reuse rejected B7p3 or the failed byte-identical initial P9 delivery. See the representation asset contract.
