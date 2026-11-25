# Second stable-main bug-fixing topic

> Historical research record. PR, CI, artifact and commit identifiers refer to earlier development history, not current repository PRs or newly executed checks.

## Second stable-main audit fixes — PR #15 (active)

Owner merged B7-N1 PR #14 (historical `pull/14`) at `3a58c83bb876a7822055ced3c4bc8208bcd49309`; post-merge CI 45462328141 (historical `actions/runs/45462328141`) succeeded. PR #13 is merged. PR #12 remains documentation-only; its second audit pass identified AUD-09–15. Owner authorized separate PR #15 (historical `pull/15`), `development/stable-main-bugfixes-2`, based on that exact merged main. B7-N1 source and assets are unchanged; B7-N2 mixed ownership and persistence are separate development.

Phase I source implemented: AUD-11 guarded Veranda preference recovery, AUD-15 literal daemon paths and encoded QML URLs, AUD-12 shared apply keys and in-flight preference reconciliation. Code checkpoint `c3660d182b1462962112d817bdc755ea3cc244a2`; mock-service regression checkpoint `a5376fcb006e68cbbe6593be84ef04f8050c85c4`. 63 focused policy/wiring assertions and 26 mock-service assertions passed against candidate source; 29 manifest entries retained. See [Veranda docs](../veranda-of-vistas.md). Actual FileView, Qt URL parsing, awww/shader and target desktop verification remain open. Fresh combined CI required. No destructive recovery, no personal asset changes, no merge authorization.

Next: AUD-09 commit/checkpoint capacity alignment and AUD-14 camera lifecycle before B7-N2 ownership integration, then AUD-10 catalogue-wide window resolution and AUD-13 paused MPRIS progress. Keep capacity caps and exact Undo; avoid unrelated changes to B7 or physics. Coordinate any overlapping B7-N2 topic before modifying shared paths. Historical checkpoint status below is superseded by this section.


## Coordination with B7-N2

PR #16 opened concurrently at `40bc7fe61ed03869b9b4f7db53bc4f55a4e7b146`, changing ArchiveCore, ArchiveMotion, CI and shared status documents. Keep this topic's handoff here instead of modifying CURRENT_STATE/ACTIVE_WORK in parallel. Reassess AUD-09/AUD-14 at its actual head; avoid parallel edits to shared Archive code. Continue independent AUD-10/AUD-13 first. Coordinate the common capacity contract and camera lifecycle with the B7-N2 developer, then fix on the appropriate merged baseline. No merge or scope expansion authorized.

## Second checkpoint — AUD-10 and AUD-13

Previous combined CI 45463591808 (historical `actions/runs/45463591808`) passed. AUD-10 commit `5fb3a20d0a9c2193aa3993a76e574adc6e4dbc5a`: replace per-app suffix matching with a catalogue-wide ranked index (full desktop ID > explicit class > unique suffix; equal-rank distinct IDs unresolved). Use the same identity index for window count, launcher/running books, focused ribbon, chooser and fresh focus resolution. NoDisplay entries participate when exposed by DesktopEntries. Unresolved windows do not steal focus; explicit requested launch remains available. Keep case normalization and refuse normalized full-ID collisions. No new UI or persistent window addresses.

AUD-13: refresh Gallery music progress from the selected player's position, length/support, playback state and post-track signals, plus activation/visibility; keep 1-second notifications only while active, visible and playing. Quickshell 0.3.1 MPRIS API: https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Mpris/MprisPlayer/ . Guard unavailable/nonfinite values. Existing visual and playback controls unchanged.

Executed candidate-source tests: 41 window/launcher assertions and 29 music assertions using synthetic service and player contexts; existing test entry points extended. First synthetic harness failed because it attempted to export a nested helper, corrected before committing. Native compositor/MPRIS signals remain unverified. On target, check ambiguous suffix/class collisions, exact matches, changing catalogue, disappearing windows, paused external seek, next track, duration/capabilities, active hide/reopen and player disappearance. No CI workflow edits. AUD-09/14 remain coordinated with PR #16; do not touch shared Archive paths while it is active.
