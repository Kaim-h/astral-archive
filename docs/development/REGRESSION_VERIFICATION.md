# Regression verification: interactions, identity and rendered output

Practical guidance supplementing [contributor requirements](../../CONTRIBUTING.md), the [development workflow](../development.md) and [topic handoff](TOPIC_WORKFLOW_AND_HANDOFF.md). These safeguards describe engineering and evidence practices, not new product behavior, architecture decisions or mandatory approval gates. Apply them to the affected contract; do not impose a particular implementation on unrelated components.

The examples come from the integrated AUD-16–21 corrections in [PR #4](https://github.com/Kaim-h/astral-archive/pull/4). The [correction record](STABLE_MAIN_BUGFIXES_3.md) preserves exact historical failures, final revisions, CI and evidence limitations. Do not reopen a verified correction without evidence or infer that a historical prototype defect exists in a different implementation.

## Design a meaningful regression

Identify the actual user action, expected contract, relevant implementation and identity domains before editing a test. Establish a failing reproduction where feasible; distinguish a test defect from an application defect and record when reproduction remains incomplete. Exercise genuine input and verify state before, during and after an operation as appropriate. Include rejection, cancellation, rollback, Undo or persistence where the contract involves them. Keep existing relevant checks, including superseded-prototype regression gates. Do not force input, bypass the application path, loosen assertions or repeat a failed action until a green result appears.

### Asynchronous interaction and observation

Input API completion is not application completion. A click/key event, asynchronous iframe message, worker result, queued signal, animation or transaction settlement may complete at a different time from the state transition being tested.

1. Establish the intended focus and initial state; check that the target can actually receive focus. Record which handler receives input where routing matters.
2. Perform genuine input once. When completion is asynchronous, wait within a bounded, justified deadline for the actual expected postcondition (for example, exact membership and move mode), not an unrelated flag or arbitrary sleep. A deadline is not permission to retry the operation.
3. Verify the resulting state and subsequent operations independently. A wrong result, refusal or lost input must fail the test; do not hide it by clicking or pressing the shortcut again.
4. Preserve diagnostic evidence: immediate and final states, focus, event/relay delivery, guard or refusal state and relevant revision/transaction identifiers. Distinguish an observation race from lost input, a legitimate refusal and incorrect behavior.

**Example — AUD-21:** the historical B6r7 grouped cut sometimes read four source records immediately after selecting three and issuing Ctrl+X, rather than one. The iframe can handle the key directly or receive an asynchronous parent relay; the SVG was not explicitly focusable. The corrected test waits for exact source and Case membership with cut mode, then verifies Save, persistent identity, manifest and a single authoritative Case. Final runs confirmed the parent relay and passed, but both observed the completed cut immediately. The original timing failure was not conclusively reproduced after instrumentation; the corrected synchronization weakness and passing checks are established, not its sole root cause. Accepted B6r12b3 and native Qt have distinct input paths.

### Actual rendered output and intermediate states

Component existence, a visible property and Canvas painted notifications do not establish that intended content is visible in the composited scene. A notification may precede the frame or texture sampled by the test.

- Test lift, drag, provisional destination, settlement, cancellation and commit where relevant, not just a settled screenshot. Preserve gesture capture and fixture geometry while independently checking actual ownership, rollback and identity invariants.
- When essential visual feedback must appear immediately, consider separating it from asynchronous decorative rendering. Evaluate the component's actual behavior; a permanent Rectangle is one solution, not a requirement for all Canvas components.
- Sample meaningful regions of the actual composed frame when pixel evidence is appropriate. Map local geometry to the captured scene, account for scale/transforms, opacity and antialiasing, and ensure region coordinates refer to the same interaction state as the capture. Use meaningful coverage/tolerance rather than an isolated pixel where rendering makes that brittle.
- Preserve the exact capture before a potentially failing assertion and arrange diagnostic retention on failure where the test environment supports it. Inspect changed and unaffected visual elements, including support/contact, occlusion, unwanted duplicates and missing objects. A plausible frame alone cannot prove correct committed ownership; verify model and render evidence separately.

**Example — AUD-17:** initial passing CI concealed outline-only provisional scroll cues in intermediate captures. A later single-pixel assertion failed despite a Canvas painted signal; its exact cause was not established. Permanent parchment fill beneath decorative Canvas ink plus mapped interior-region checks provided actual visible feedback and passing offscreen Qt evidence. Do not generalize that implementation to every component or claim target compositor acceptance.

## Identity domains and transaction boundaries

Before changing any identity-related implementation or assertion, trace the lifecycle from source record through view, gesture/simulation, operation and persistence. For each identifier determine its owner, scope, lifetime (persistent or transient), reuse rules, translation points and the invariants it must preserve at completion, cancellation and persistence. Do not assume equivalence merely because two identifiers refer to the same conceptual object.

| Domain | Verification focus |
|---|---|
| Application identity and transient compositor window address | Match within the application domain; keep window lifetimes and reuse separate from persistent application identity. |
| Archive record, fixture identity and camera key | Verify the actual owner, key scope, existence and lifecycle; distinguish record membership from fixture/view state. |
| Temporary physics identity and persistent Archive ID | Verify the translation map, temporary selection/membership and persistent identities after Save independently. |
| Filesystem identity, virtual organization and placement | Preserve separate domains; real-file identity and operation policy remain subject to approved contracts. Visual arrangement must not silently alter disk data. |

**Example — AUD-21 test regression:** selected temporary IDs `[1,2,3]` were compared to persistent IDs `["s3","s4","s5"]`. Both jobs failed before Ctrl+X; this was a test mistake, not an application defect. The historical B6r7 bridge creates `b4Cell.indexMap` when opening the cell and translates membership back on Save. The corrected test verifies the mapping and each domain separately. Never repair a cross-domain assertion by blindly stringifying or removing it. Assert exact identity and membership, not just counts.

### Identifier-keyed lookup

AUD-18 and AUD-20 exposed inherited properties mistaken for valid dictionary entries. Use own-property membership checks, null-prototype dictionaries, Map or Set as appropriate to the environment and serialization contract. Test inherited-name keys, genuine missing entries, ordering, lifecycle and roundtrips where relevant. Do not reject formerly valid identifiers merely to avoid unsafe lookup.

### External command and service contracts

AUD-16 exposed an artificial brightnessctl CSV fixture whose field order did not match real output. Check the documented or observed upstream format and version, including units, field order, device identity and error semantics. Test representative verified output, malformed/ambiguous values, command failure and same-device read/write behavior as applicable. Synthetic fixtures do not establish actual installed-backend compatibility; keep target service validation separate.

### Shared physical geometry and compatibility

AUD-19 exposed a cradle envelope that did not reserve enough space at the maximum supported representation scale. Where practical, use the same authoritative geometry calculations for rendering, occupied bounds, hit/placement policy and validation. Test supported parameter ranges and boundary cases rather than just default scale; check empty and occupied fixtures where relevant. Preserve stable contacts and unaffected objects. If stricter validation rejects a previously accepted persisted arrangement, document compatibility and explicit recovery/refusal behavior; do not silently resize, relocate or discard objects. This guidance does not select a new geometry solver or persistence format.

## CI evidence and acceptance

Use the evidence classes in [CONTRIBUTING.md](../../CONTRIBUTING.md): source/structure, deterministic JS logic, browser prototype, offscreen Qt Quick, actual Quickshell process and target desktop/hardware/service integration. Each establishes only its exercised scope.

Record exact head, base and checked-out commit/tree where available, workflow event, run ID/attempt, job/step, command, result and diagnostic artifact. Push CI generally tests the pushed head; PR CI may test a prospective merge commit. Compare actual trees before attributing different outcomes to changes. A failure before executed test steps is distinct from an executed assertion failure; report infrastructure cause only when established. A later pass is useful evidence but does not erase an intermittent failure or prove its cause. Seek repeated relevant execution where feasible, retain failure diagnostics and avoid unnecessary full-suite reruns solely to obtain a green result. An older success cannot verify later changed source.

A verified corrective head and successful post-merge checks support bounded merge-readiness and integration status; they are not release approval or production readiness. N4 target Fedora/Hyprland/Quickshell validation remains mandatory before production Archive integration. Preserve KDE/TTY recovery and distinguish actual measurements from performance hypotheses.
