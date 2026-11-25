# November 20 original proposal — reconciliation ledger

> Historical provenance only. The original ZIP is not distributed here; old pull request and commit identifiers do not identify current work.
>
> **November 25 update:** The exact original archive was recovered and all 63 overlay digests independently verified. See the [source audit and exact import inventory](ZIP_SOURCE_INVENTORY.md) for byte-identical deduplication, 29 missing sources at the audited base, publication review and outstanding import. The earlier filename-only audit below is retained as historical evidence.

**Source file:** user-provided `ASTRAL_ARCHIVE_B6_UNCOMMITTED_DOCS_AND_PROTOTYPES(1).zip` (2,980,789 bytes; SHA-256 `c71c267a2d8d07af4158d362b9dd62b09388574b94d9fd8555f52da0278db48b`). The original ZIP explicitly says it was prepared outside Git from `main` commit `82e850e96e1bf5c1d75c50d9b43840d11498fe32` and warns **not to apply wholesale over changed docs**. The user's subsequent message authorized creating a new review branch and PR, not overwriting history or merging to main.

This ledger is a transparent record of what was reviewed and what is still absent. **Listing a file here does not mean its content is checked into the repository.**

## ZIP inventory

The ZIP contains **66 entries**: three top-level proposal/manifest texts and **63 `repo_overlay/` files**. Those 63 consist of **26 Markdown**, **30 HTML** and **7 PNG** files. The 30 HTML examples are 12 Storage Workshop (`v5_1` through `v5_12`), 14 Cubby Studies (`A1`–`A6`, `B1`–`B6` including bookmark and B4r), three Scroll Physics (`P1`, `P2`, `P2R`), and one Map Room v3. No source text or images have been altered inside the ZIP.

## What merged PR #3 preserved versus what remains external

| Original material | Status in PR | Reason |
|---|---|---|
| Separate B6r, B6r2, B6r3 HTML uploads | **On `main` through merged PR #3; recorded as verbatim** | All three intact; Git blob SHA verified against originals |
| Separate B6r3 Markdown notes | **On `main` through merged PR #3; recorded as verbatim** | Full original notes retained with historic wording |
| ZIP's new rack reflow, storage-interaction, scroll physics and seal requirements | **Already synthesized on `main` by PR #3** | Later B6r3 findings qualify some original B6 warnings; new docs retain status vocabulary |
| ZIP's B7 test gate | **Already adapted on `main` by PR #3; scenarios retained** | B6r3 sampled radius tests do not establish universal gate completion |
| ZIP's B6 defects / master handoff | **Already summarized on `main` by PR #3**, not imported verbatim | Prevents historical B6 P0 defects from appearing to be current B6r3 or QML implementation assertions |
| ZIP's proposed replacements to current README, docs/README, architecture/component map, active work, roadmap, design decisions, state snapshot and product docs | **Not blindly applied** | Existing historical material and more recent `main` edits would be lost; PR #3 added indexes and research instead |
| ZIP's 30 historical HTML source files | **ZIP source set not imported or verified as a set** | Five same-version Storage Workshop files predate PR #3 in Git; exact ZIP equivalence unverified. The other 25 version names are absent. See audit below |
| ZIP's four earlier research notes | **Not imported verbatim** | Retained inside external ZIP; this PR carries the later original B6r3 note |
| ZIP's seven PNG previews | **Not imported** | Historical diagnostic imagery. Later B6r3 note asks that testing PNGs stay internal unless specifically requested |
| ZIP's `SHA256SUMS.txt`, `README_APPLY.md`, `PROPOSED_CHANGESET.md` | **Described here, not verbatim imported** | Original transfer instructions are time-bound; the original ZIP remains the authoritative full package |

## Supersession and source-truth rules

- **Oldest → newest research:** November 17 handoff and v5.4 → November 20 B5/P2R → original B6 (known-broken resize) → B6r (repair direction) → B6r2 (better compact case but grouping/settling issues) → B6r3 (sampled corrections and remaining edge cases).
- Old proofs and observations are never deleted to make a later revision look better. Conversely, **original B6's known zero-radius freeze must not be asserted as reproduced in B6r3 without testing it there**.
- Browser HTML is not production QML/Quickshell. Imported research does not change source implementation or prove native correctness. The B7 candidate gate is not declared passed.
- A stable file/cell identity design, explicit user-controlled splits, lineage, no-loss geometry, Undo integrity and respectful physical support are the durable design themes. Algorithmic choices in the prototypes remain replaceable.
- The main repository's historical November 17 and Batch 13 docs remain intact. The active-work snapshot itself is dated; a later source-state survey is needed before treating it as live implementation status.

## Future archive-completeness work

An owner-reviewed follow-up may import **every ZIP text file verbatim under versioned research-only paths**, with a file list and original SHA-256 manifest, preserving all prior variants rather than replacing older prototypes or the current source. No images, private fonts or additional files should be committed without deciding on distribution and relevance. When older prose conflicts with B6r3, label it **superseded in scope** rather than deleting the original.

This ledger-only follow-up is **not** a complete ingestion of that ZIP. If full historical source-in-Git is required for acceptance, request the missing archive for a separate byte-preserving import before merging an archive-completion PR.

## Post-merge repository audit — November 23, 2026

- **Verified Git state:** PR #3 (historical `pull/3`) is merged at `046e51aaad805b13871c1b06f25562f8d3ad445c` on `main`. Its B6r/B6r2/B6r3 HTML studies and verbatim B6r3 notes are already archived under [this dated study index](README.md); **do not re-import or remerge them**.
- **Separate earlier ledger commit:** `09253a309fb10e1c8d104a7ecc98795161bd9e60` on `docs/archive-b6-provenance-2026-11-23` adds the initial ledger and three small dated-snapshot/index annotations, but diverges from `main`. This review proposes that documentation on a new branch based on merged `main`, without rewriting the original branch.
- **Evidence limit:** the original November 20 ZIP itself was **not provided in this continuation**. The ZIP size, overall SHA-256, 66-entry counts and descriptions above are transcribed from existing repository provenance. They are **not independently rehashed or a file-by-file comparison of the original archive** in this review. Do not treat any claimed ZIP identity as newly verified.
- **CI already observed:** the existing "Astral Archive - offline logic checks" workflow succeeded for the `main` merge (`45261364055`) and the earlier ledger commit (`45261702297`). Those completed workflows are not native Quickshell/Hyprland validation and are not checks of the future review-branch revision.

### Filename-level inventory compared with `main` at `046e51a`

| ZIP-era HTML family | Versions with same-name source already in Git | Version names with no matching tracked HTML |
|---|---|---|
| Storage Workshop (12) | `v5_1`, `v5_2`, `v5_3`, `v5_4`, `v5_12` (five; November 17 handoff tree) | `v5_5` through `v5_11` (seven) |
| Cubby A-series (6) | None | `A1`–`A6` (six) |
| Cubby B-series (8) | None: B6r/B6r2/B6r3 are **different later variants** | `B1`, `B2`, `B3`, `B3 Bookmark Revision`, `B4`, `B4r`, `B5`, original `B6` (eight) |
| Scroll Physics (3) | None | `P1`, `P2`, `P2R` (three) |
| Map Room (1) | None: earlier `v1` and `v2` are **not** `v3` | `v3` (one) |
| **Total (30)** | **Five same-version files**, not checked against ZIP bytes | **25 version names absent** |

The five same-version Storage Workshop files are under `docs/research/handoffs/2026-11-17/prototypes/`. Their presence **does not prove** that they are byte-identical to the five ZIP copies. Conversely, counting all 30 as entirely missing by name would overlook these pre-existing files. The original ZIP's source blobs and checksum manifest must be available to settle the precise overlap.

Additional unimported or unverified ZIP material: the **four earlier research notes** (B4, B4r, B6 and rack/holder according to the existing index); the **three top-level** `README_APPLY.md`, `PROPOSED_CHANGESET.md`, `SHA256SUMS.txt` documents; and the original **26 proposed Markdown overlay files** as a verbatim, independently reconciled source set. Some overlay ideas were already adapted into the merged supplemental specifications, but the originals were **not** blanket-applied. The **seven diagnostic PNGs** are intentionally absent from Git, consistent with the later B6r3 note requesting that testing screenshots remain internal unless explicitly requested.

### Conditions for a separate archive-completeness proposal

1. Obtain the original ZIP, verify its overall digest and per-entry checksum manifest, and compare exact contents of the five already-named Storage Workshop studies before deduplication decisions.
2. Import the remaining historical HTML and research-note originals additively into clearly dated/versioned research paths. Preserve distinctive earlier versions even if their conclusions are superseded. Do **not** replace accepted product specifications with ZIP overlays.
3. Record file-level import/checksum coverage and distinguish source-preserving imports from synthesized or superseding docs. Keep PNGs external unless the owner explicitly elects to include them.
4. Reconcile later browser regression tests and the proposed B7 gate separately; no tests in the current research record establish native functionality or permission to begin broad B7 work.

**Decision for this review:** carry forward the provenance ledger and dated-snapshot warnings, correct links and status wording, and stop. **No historical file content is reconstructed from descriptions.** No ZIP-source import, PNG publication, prototype code edits or native code changes are proposed without the original material and owner review.
