# CI execution efficiency — initial rollout

Owner-requested efficiency work, independent of B8 runtime implementation. Baseline integrated main `be644bfcf6171954eca5fb6e8206d9af9a86cfb5`; observed B8 candidate `b62d3090b5751038b34050bf73f64c54cfad45be`. [PR run 45748832502](https://github.com/Kaim-h/astral-archive/actions/runs/45748832502) passed all three jobs. [Push run 45748826638](https://github.com/Kaim-h/astral-archive/actions/runs/45748826638) was still running during measurement.

| Job or step | Successful PR | Duplicate push |
| --- | ---: | ---: |
| Offline JS job | 32 s | 27 s |
| Browser job | 143 s | 172 s |
| Qt job | 107 s | Still running at observation |
| Qt runtime install | 31 s | 226 s |
| Native Chromium installation and raster generation | 19 s | 259 s |
| Native live interaction tests | 20 s | 21 s |

The two slow setup steps consumed 485 s, excluding assertions and other work. Network/setup or runner variability is suspected; the step timings alone do not isolate the individual cause. The PR's successful native job was 107 s in total. These are measured elapsed step/job times, not billed usage or proof of future speed.

## First bounded changes

- Ordinary pushes trigger the full logic workflow only on main. All pull requests (including stacked topics) continue to run the full workflow on their prospective integration commits; no branch/path filtering of PRs. Explicit workflow_dispatch allows a full check on a branch without a PR once this workflow is available on the default branch. Branch-only pushes no longer constitute CI evidence. The design-study workflow is unchanged.
- Concurrency groups supersede only older runs of the same PR; unique run-ID groups for main pushes and manual dispatch preserve distinct evidence. Cancelled work is not a pass and may lose artifacts. Main post-merge verification remains mandatory.
- All active browser and native raster scripts launch default Chromium headless without a channel or custom executable. Install the pinned Playwright 1.56.1 Chromium headless shell only, with required system dependencies. See [Playwright browser installation](https://playwright.dev/docs/browsers#chromium-headless-shell). No browser engine/version or rendering command change.
- Preserve all three job names, every existing assertion/test command, runner images, timeouts, dependency packages, diagnostic captures and retention policies. No skip-by-path, cached test success, reduced solver/interaction checks or automatic retries of failed input. B8 foundation registrations remain on their own branch and must be preserved during reconciliation.

## Acceptance and measurement

Initial WP-08 changes integrated through [PR #20](https://github.com/Kaim-h/astral-archive/pull/20) at main `494b0f8493adbf072884ee0fd5906a6a8c69240b`; [post-merge CI 45750244590](https://github.com/Kaim-h/astral-archive/actions/runs/45750244590) passed all three jobs. This establishes integrated policy and successful main verification, not completion of every rollout observation below or a measured future speedup. Further efficiency proposals remain advisory.

Confirm the candidate PR automatically starts and all three unchanged job names succeed with actual tests, PNG generation and capture checks. The first branch push may still use old trigger behavior until integration. Inspect exact-head checkout and artifact evidence. After owner merge, confirm full main CI; reconcile B8's workflow additions against integrated main using a normal merge, not a replacement. Verify subsequent PR synchronization starts one full logic workflow, obsolete same-PR work can be superseded, and manual branch dispatch works. No claim of completed rollout until those events are observed.

Record repeated normal/cold-run setup durations and overall elapsed time. One automatic run instead of two removes duplicate full-suite execution for the usual development PR checkpoint; it does not guarantee half wall-clock latency or eliminate slow apt mirrors. Headless-only installation removes an unnecessary full browser download. Further improvements (dependency provisioning/cache, parallelization, static HTML artifact consolidation) require separately measured benefit, preserved provenance/diagnostics and review. Do not weaken required checks or actual target desktop validation (historical N4, distinct from B8-N4 Map Room).
