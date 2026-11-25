# Active work and continuation point

> Historical identifiers refer to earlier development history, not current pull requests or new checks.

> **Historical snapshot notice (November 23, 2026):** This document retains its original dated claims for provenance, including statements about Patch 12/Batch 13 that may have been superseded by later commits. It is **not a live status feed**. For subsequent browser-only storage research see [B6 research chronology](../B6_RESEARCH_STATUS_2026-11-23.md); check current source and CI before assuming native implementation. No part of that browser research was ported to Quickshell by this documentation PR.

**Snapshot:** Batch 13 documentation / project-memory consolidation, based on `main` at `edd9964af8bc69c3a0558652068ea0342d5fee50`.

## Current milestone

Consolidate the product handoff, approved design requirements, implementation state and reusable AI/contributor instructions into the GitHub repository so that work can resume in a fresh conversation or another development tool without relying on chat history.

Batch 13 is documentation / continuity infrastructure. It does not implement Map Room, scroll physics or other new native desktop functionality, and it does not silently apply Patch 12.

## Next practical continuation

1. Review the combined Patch 12 + Batch 13 pull request. Patch 12 source changes are proposed on the review branch, not yet merged into `main`.
2. Verify the Gallery editor wiring and all offline checks in GitHub Actions; record the actual workflow outcome before declaring success.
3. When the target Linux environment is available, follow the first native bring-up checklist, starting manually from a terminal while keeping KDE / TTY recovery available.
4. Record actual installed versions, runtime errors, hardware/service availability and screenshots in the environment / validation records.
5. Once the native desktop baseline is reliable, choose a narrow next product milestone from the Storage Workshop / Map Room work. The v5.4 prototype is the latest reviewed browser experiment; it was described as “much better,” not final or production-ready.

## Do not assume

- That Patch 12 has been merged into `main` (it is only proposed on the review branch).
- That any native QML / Hyprland / Wayland behavior has been verified.
- That the v5.4 physics prototype has been ported to QML.
- That the old Map Room v1/v2 layouts are the current visual blueprint.
- That a specific Batch 12–15 feature sequence is approved. The earlier proposed batch numbering is historical planning, not a fixed commitment.

## Open work choices

The handoff lists genuine unresolved engineering / design questions: final fixture and file-object artwork pools, native geometry / physics method, smooth void-boundary detection, saved simulation state and file reconciliation, selected plate-face presentation, exact room/shelf/cubby proportions, file action semantics, indexing roots and symlink policy, and the backend for metadata indexing. These should be investigated when relevant, not silently decided by an implementation agent.

## November 23 continuation — B6r12 Session 2 review

The historical Batch 13 snapshot above is unchanged. The merged browser baseline is B6r12a at `c53be32542eccf78a59266265adc43564bb93c93`. GitHub Actions run 45306855919 (historical `actions/runs/45306855919`) reported both offline and Chromium jobs successful. B6r12b is a separate browser research candidate on `research/cubby-study-b6r12b-2026-11-23`; see [Session 2 notes](../../research/prototypes/2026-11-20/notes/Astral_Archive_Cubby_Study_B6r12b_Notes.md). Review actual CI and owner interaction feedback before marking the refactor or B7 gate accepted. Do not treat the native desktop as validated.

## November 24 continuation — B6-N1 native foundation

Owner accepted the B6r12b3 interaction direction and authorized starting native QML implementation. Browser reference commit `f2e78523897d13ef518209eb2f9ef60e1cad12a4`, PR #7, CI run 45392280473 (historical `actions/runs/45392280473`): both offline and browser jobs completed successfully, including continuous resize and grouped drag. Do not treat this as the full historical stress matrix or native acceptance.

The native branch is stacked on PR #7 to preserve review isolation. N1 adds the DOM-free `quickshell/archive/ArchiveCore.mjs`, a revision-aware Qt WorkerScript and synthetic QML controller, plus Node and offscreen Qt Test checks. No production shell registration, file indexing, disk operations, native persistence or new object families. N2 builds a native illustrated cubby/rack scene, N3 adds pointer-driven live solver/case/void gestures, N4 measures actual Linux performance and integration. B7 returns other objects after this checkpoint. Native desktop validation remains outstanding. Native work must remain isolated and distinguish CI Qt runtime checks from target desktop validation; see [environment](../ENVIRONMENT.md).

## November 24 continuation — B6-N2 native visual study

N1 Node and offscreen Qt jobs passed in run 45394196420. Continue on the same draft PR #8. N2 adds a native illustrated Cubby/Rack/ScrollEnd scene, clipped child silhouettes, independent camera and view navigation, existing theme roles, compact metadata tooltip, portable Case art/register and a small Arrange panel for immediate draft previews and explicit destinations. Extend synthetic validation to nested cubbies, not real directories. The isolated study window is `quickshell/tests/ArchiveNativeN2Window.qml`; see `quickshell/archive/README.md`. N3 next: live pointer capture and group drag transactions, active-only solver scheduling, physical Case and void/top-entry gestures, continuous furniture resize handles, timeout recovery and parity checks. N4 target-environment validation remains mandatory before production integration. No changes to production shell, real files or autostart.

## B6-N3 interactive candidate — PR #8
N2 full CI 45395402883 passed all three jobs. N3 adds live motion, real pointer routing, selection and group transfers, Case drop detection, prepared insertion/return and rack resize handles. It retains the same native window and browser reference. Compare actual named CI checks and captured renders before calling parity complete. Native desktop validation remains outstanding. Remaining product gaps and visual differences must be tracked; no automatic transition to B7 or production shell registration.

N3 initial run 45398055406 passed all jobs. Matched offscreen/native and browser screenshots were inspected. Follow-up corrects Case/plaque overlap, cradle and endpoint fidelity, metadata and pigment/depth authoring; verify latest run. The native study still has a smaller control surface than the browser; full creation/role/snap/guides/preview variants, checkpoint persistence and target validation remain outstanding.

## November 24 — B7 parallel visual research (owner authorized)

PRs #7 and #8 are merged into main. Begin a separate B7 research branch for small standalone HTML representation studies, starting with [B7r1 framed artwork](../../research/prototypes/2026-11-24/README.md). No inherited scroll physics or native changes. Owner review of appearance, frame geometry and fixture behavior comes before additional implementation. B6 parity gaps and target desktop validation remain open.
