# Stable main bug audit — 2026-11-24

**Historical provenance:** The three audit passes below retain original source revisions, source paths, line ranges, CI run IDs and PR numbers as historical evidence. These identifiers refer to the original technical history, not to live destination refs. Reproduction snippets describe the audited revision, not a claim that the integrated baseline still exhibits the defect. AUD-01–15 have integrated source fixes; AUD-16–20 remain a separate unfinished corrective topic. No new execution or native acceptance is claimed by this migration.

Baseline: merged main 084931f (historical `commit/084931f1f877e71e20ddf7134ddd99262a740d4d`); baseline CI run 45431884739 (historical `actions/runs/45431884739`) succeeded. PR #11 and all unmerged work are explicitly excluded. This is a documentation-only record, not a fix or native sign-off. Priorities are proposed; all findings open at the audited revision. Coordinate future fixes with continuing development topics and recheck against the then-current main. Unfinished Map Room, fixture, persistence and filesystem features are not defects merely because they are unfinished.

| ID | Priority | Finding | Evidence |
|---|---|---|---|
| AUD-01 | P1 | Gallery colony shader violates premultiplied alpha contract | Source + Qt specification; render impact untested |
| AUD-02 | P2 | Reflow silently loses recess-only empty cell customization | Reproduced in fetched merged pure JS |
| AUD-03 | P3 | Inherited object properties pass catalogue ID validation | Constellation reproduction; analogous sky code inspected |
| AUD-04 | P1 | Read failure can lead to overwriting recoverable preferences | Conditional source-level data loss risk |
| AUD-05 | P2 | Artwork identity not locked at focus initiation | Source-level interaction defect; target test pending |
| AUD-06 | P2 | Pixel grid uses logical instead of physical dimensions | Scaling fidelity gap; target test pending |
| AUD-07 | P3 | Different constellation aspect ratios in drum and sky | Source-level geometry discrepancy |
| AUD-08 | P3 | Artwork file names interpolated into URLs without encoding | Source-level risk; Qt behavior needs reproduction |

**Later status:** all eight original findings have source fixes merged in PR #13; see the second audit pass below for the newer baseline and remaining verification caveats.

## AUD-01 — Gallery shader transparency

gallery-colonies.frag:78–92 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/shaders/gallery-colonies.frag#L78-L92`); [Qt ShaderEffect documentation](https://doc.qt.io/qt-6/qml-qtquick-shadereffect.html).

Current output: `fragColor = vec4(color, a * qt_Opacity);`. RGB remains nonzero even with zero colony coverage. Qt Quick expects premultiplied output; zero-alpha fragments with nonzero RGB can add color rather than preserve the underlying scene. Partial item opacity is also mishandled.

Candidate correction: `fragColor = vec4(color * a, a) * qt_Opacity;`. Check the chart blend at lines 90–91 as well: if its sampled texture is premultiplied, the current mix attenuates RGB twice. Candidate composite for a premultiplied chart: `color = color * (1.0 - chart.a * .85) + chart.rgb * .85;`. Verify the actual texture convention.

Acceptance: compile with qsb; inspect rendered frames at progress 0, intermediate and 1, reverse, contrasting underlay and partial opacity. Masked pixels must leave the underlying scene unchanged; constellation lines share the mask. Verify fallback too. No native render was executed for this audit.

## AUD-02 — Depth-only cell customization disappears on reflow

ArchiveCore.mjs:203–254 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/archive/ArchiveCore.mjs#L203-L254`); paintCell:650–660 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/archive/ArchiveCore.mjs#L650-L660`); [reflow contract](../product/RACK_REFLOW_AND_CELL_IDENTITY.md).

The planner protects colored empty cells, not cells customized only by recess depth, both for eligible destinations and review of removed cells.

Reproduced in the merged JS: fixture rack 500 × 400, radius 75; empty cell -1:3 (hc5), color null, depth 20; shrink to 400 × 320, same radius. Planner ready, review empty, Apply succeeds with no error; original ID and depth absent.

Portable equivalent reproduction from repo root on the audited revision:

```sh
node --input-type=module <<'JS'
import * as C from './quickshell/archive/ArchiveCore.mjs';
let s = C.session(C.fixture());
s = C.paintCell(s, 'root', 'rack-1', '-1:3', null, 20);
const old = s.snapshot.cubbies.root.mods[0].cellMeta['-1:3'];
s = C.stage(s, 'root', 'rack-1', {w:400,h:320});
s = C.accept(s, C.solve(C.request(s)));
console.log(s.draft.phase, s.draft.result.review);
s = C.apply(s);
console.log(s.error, Object.values(s.snapshot.cubbies.root.mods[0].cellMeta)
  .some(m => m.id === old.id));
JS
```

The fetched-source execution returned ready, no review, no error, false for identity retention and false for depth retention. The shell snippet is an equivalent reproduction, not a separately executed checkout test.

Suggested correction: central customization predicate for reservation and relocation/discard, including deliberate depth overrides; distinguish inherited/default depth from override. Extending painted-cell protection to depth is a proposed interpretation of preservation intent, not a newly approved product rule.

Acceptance: depth-only, pigment-only and combined overrides; retained/disappearing addresses, relocation, explicit discard, destination conflicts, exact Cancel/Undo, unique IDs and unchanged scroll ownership. Coordinate with the existing Archive topic after owner review; do not duplicate its changes.

## AUD-03 — Invalid catalogue ID acceptance

GalleryPolicy.js:20–64 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/services/GalleryPolicy.js#L20-L64`); GalleryCatalogue.qml:75–105 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/services/GalleryCatalogue.qml#L75-L105`).

Ordinary object dictionaries inherit constructor, toString and __proto__. Testing allowed[id] accepts these despite missing real definitions. The editor count and rendered constellation count can differ. Sky-pool normalization uses an analogous lookup.

Portable equivalent reproduction:

```sh
node --input-type=module <<'JS'
import fs from 'node:fs';
import vm from 'node:vm';
const ctx = vm.createContext({});
vm.runInContext(fs.readFileSync('quickshell/services/GalleryPolicy.js','utf8'),ctx);
const lib=JSON.parse(fs.readFileSync('quickshell/data/gallery-constellations.json')).constellations;
const skies=JSON.parse(fs.readFileSync('quickshell/data/gallery-sky-presets.json')).skies;
const result=ctx.normalizeSetting('test-artwork',
  {count:5,ids:['constructor','toString','__proto__']},lib,skies);
console.log(result.ids, ctx.selectDefinition(result.ids,lib).length);
JS
```

Observed fetched-source result: [constructor, toString, __proto__, well, fox], i.e. five IDs but only two real definitions. Ordinary catalogue choices were not shown to fail. Sky analogue has not been separately executed. No remote exploit claimed.

Suggested fix: Set, null-prototype maps or explicit own-property checks; review artwork/state maps too. Test invalid, duplicate and removed IDs, valid custom IDs, malformed sky pools and count consistency.

## AUD-04 — State read failure risks preference overwrite

GalleryCatalogue.qml:94–124 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/services/GalleryCatalogue.qml#L94-L124`), write path:115–134 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/services/GalleryCatalogue.qml#L115-L134`).

Read/parse errors become empty state; unsupported versions also fall back to empty. With valid catalogue and selected artwork, initialization persists defaults. A recoverable old file could be replaced if the subsequent write succeeds. Atomic writes do not prevent writing the wrong state. Actual user data loss not observed.

Acceptance: distinguish missing first-run state from read/parse failure and unsupported schema. Preserve original bytes on error; warn and block automatic overwrite pending explicit recovery/reset. Test using disposable synthetic files, including save failure.

## AUD-05 — Artwork identity may change during focus

CelestialGallery.qml:34–89 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/panels/CelestialGallery.qml#L34-L89`), Prev/Next:256–264 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/panels/CelestialGallery.qml#L256-L264`), GalleryFullViewer.qml:72–81 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/panels/GalleryFullViewer.qml#L72-L81`), editor:21–28 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/panels/GalleryCelestialEditor.qml#L21-L28`).

Focus starts on the selected artwork, but the presentation/title/image are read from the live catalogue after focus and glow delay. Prev/Next is not disabled. Focus on A, navigate to B during the delay, and B may open. Viewer snapshot is separate from the editor's live selection, so alternate entry points could edit the wrong work.

Acceptance: two synthetic artworks; try changing selection during 1450 ms focus and 1170 ms delay. Freeze intended stable ID/presentation at agreed boundary or block navigation. Editor must address viewed artwork; check cycle increments exactly once per intended opening, dismissal, right-click and keyboard entry. Native interaction not tested.

## AUD-06 — Physical pixel grid under scaling

GalleryFullViewer.qml:139–145 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/panels/GalleryFullViewer.qml#L139-L145`), gallery-colonies.frag:78–84 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/shaders/gallery-colonies.frag#L78-L84`).

Shader dimensions are logical QML item units; floor(uv * dims) cannot guarantee a one-physical-pixel grid at nonunit DPR. Use actual target pixel dimensions rather than a guessed global scale; account for fractional scaling and compositor resampling. Test 100%, 125%, 150%, 200%, output changes and actual capture dimensions. No target capture yet.

## AUD-07 — Constellation geometry distorted

GalleryDrum.qml:42–53 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/widgets/GalleryDrum.qml#L42-L53`), GallerySkyMap.qml:25–33 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/widgets/GallerySkyMap.qml#L25-L33`).

Shared topology is preserved, but x and y stretch independently across slots of different proportions. Figures can differ across drum count and display aspect. Fidelity issue, not identity loss. Future astronomical projection choices remain open.

Acceptance: common uniform fit or explicitly documented projection, matching colony seed placement; compare counts 1/5/8, portrait/landscape and label legibility. Preserve complete drum skin motion.

## AUD-08 — Reserved URL characters in filenames

GalleryCatalogue.qml:22 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/services/GalleryCatalogue.qml#L22`), manifest validation:82–90 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/services/GalleryCatalogue.qml#L82-L90`).

Manifest permits # and ? but raw filename is concatenated into a URL; fragment/query semantics may interfere. Percent sequences also need testing. Reproduce Qt behavior with synthetic images. Distinguish filesystem paths from URLs; encode filename segment once or use correct Qt file URL API. Test Unicode, spaces, #, ?, %, literal percent escapes and existing local-only checks. Review analogous Veranda paths if relevant.

## Performance risks — not confirmed defects

ArchiveCore.mjs:123–160 (historical `blob/084931f1f877e71e20ddf7134ddd99262a740d4d/quickshell/archive/ArchiveCore.mjs#L123-L160`): at 96 scrolls, 12 iterations and 120 Hz, the quadratic loop evaluates up to 54,720 unordered pairs per step or 6,566,400/s per continuously active cell. The active-cell scheduler already limits idle work. These are operation counts, not a CPU benchmark. Profile heavy cells and frame times before changing solver. Repeated rack geometry generation may benefit from caching by dimensions/radius; profile before adding cache/invalidation complexity.

## Follow-up and verification

Suggested priority: Gallery alpha and preference recovery, then depth preservation in the appropriate continuing Archive topic, then other Gallery fixes. Keep these as bounded changes; do not interrupt or modify PR #11 for this report.

Earlier audit executed fetched pure JavaScript for AUD-02/03; AUD-01 is independently supported by Qt's shader contract. All other findings are source inspection, conditional risks or fidelity gaps. No new full regression, native Quickshell, hardware, Wayland or GPU test is claimed for this documentation PR. Baseline CI success does not establish absence of these defects. Future fixes should expand relevant Gallery and Archive regression tests and record actual results, including offscreen Qt and native target checks where applicable. Record resolutions with fixing PR/commit and evidence. This dated audit does not replace CURRENT_STATE or ACTIVE_WORK.

---

# Second audit pass — merged main 0a1f52e (2026-11-24)

**New baseline:** 0a1f52e (historical `commit/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316`), the merge of PR #13 (historical `pull/13`). Main CI run 45457756998 (historical `actions/runs/45457756998`) reports success. PR #11 has since been merged by the owner; this pass inspects only its changes as incorporated in main, not its former development branch.

**Later status:** AUD-09–15 also have merged source fixes (PRs #15 and #16); see third audit pass for the current baseline.

**Status of AUD-01–08:** PR #13 reports source fixes for all eight and is merged. The first section remains historical reproduction evidence, not an assertion that those defects are still present. This pass inspected the updated core (including recess protection) and PR #13's scope; it does not independently recertify every fix or native rendering. Target acceptance remains separate.

| ID | Priority | Finding | Evidence |
|---|---|---|---|
| AUD-09 | P2 | Committed Archive arrangement can exceed checkpoint cell budget | Executed actual merged pure JS |
| AUD-10 | P2 | Ambiguous app ID matches can focus another application's window | Executed actual matching policy; compositor effect inferred |
| AUD-11 | P1 | Veranda preference read failure can overwrite recoverable state | Conditional source-level risk |
| AUD-12 | P3 | Manual wallpaper selection while paused causes redundant apply | Executed policy and compared service keys; native backend not run |
| AUD-13 | P3 | Paused MPRIS seek/track change can leave stale progress | Source inspection |
| AUD-14 | P3 | Undo can reuse cubby IDs with stale camera state | Executed core ID reuse; camera consequence from source |
| AUD-15 | P3 | Veranda raw filename/URL handling has analogous unresolved edge cases | Source inspection; Qt/daemon reproduction pending |

## AUD-09 — Legal Archive edits eventually produce an unsavable checkpoint

ArchiveCore.mjs:754–793 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/archive/ArchiveCore.mjs#L754-L793`), ArchiveCheckpoint.mjs:18–38 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/archive/ArchiveCheckpoint.mjs#L18-L38`), save/export:52–57 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/archive/ArchiveCheckpoint.mjs#L52-L57`).

The structural editor and Core.validate accept more aggregate cells than the checkpoint codec's 12,000-cell limit. Each individual rack is valid, all identities are valid, and ordinary edit/commit succeeds; explicit checkpoint save then refuses the entire arrangement. This is not a claim that a saved database is destroyed: the current arrangement remains in memory but cannot be saved as a new checkpoint. This is the isolated synthetic study only.

**Executed:** fetched exact merged Core and Checkpoint sources into a JS runtime, removed module syntax to expose their unchanged functions, and created nested fixtures through editStructure. At 36 child cubbies with 333 cells each (11,988 total), encoding succeeds (443,342 characters); with 37 (12,321 cells), Core.validate still returns null and last edit error is empty, but Checkpoint.encode throws `Cell budget exceeded`. Below the separate two-million-character cap in the successful case. No native UI interaction was executed.

Equivalent reproduction from repo root (not a separately executed checkout command):

```sh
node --input-type=module <<'JS'
import * as C from './quickshell/archive/ArchiveCore.mjs';
import * as CP from './quickshell/archive/ArchiveCheckpoint.mjs';
let s=C.session(C.fixture());
const edit=cmd=>{s=C.editStructure(s,cmd);if(s.error)throw Error(s.error);};
edit({kind:'cubby',cubbyId:'root',patch:{w:1800,h:1500}});
edit({kind:'delete',cubbyId:'root',moduleId:'rack-1'});
for(let i=0;i<37;i++){
  edit({kind:'create',type:'cubby',cubbyId:'root',
    patch:{x:(i%10)*160,y:Math.floor(i/10)*120,w:150,h:110}});
  const id=s.snapshot.cubbies.root.mods.at(-1).childId;
  edit({kind:'cubby',cubbyId:id,patch:{w:1800,h:1500}});
  edit({kind:'create',type:'rack',cubbyId:id,
    patch:{x:0,y:0,w:1800,h:1500,r:60}});
  if(i>=35){
    console.log(i+1,C.validate(s.snapshot));
    try {console.log(CP.encode(s,{path:['root'],theme:0,cameras:{}}).length);}
    catch(e){console.log(String(e));}
  }
}
JS
```

Acceptance: reconcile editor/commit and persistence budgets; reject over-budget proposals before publishing, or explicitly support saving every allowed committed arrangement within agreed storage limits. Do not remove safety caps without review. Test create and reflow near aggregate limits; ensure last saved checkpoint survives a refused save, Cancel/Undo and ownership remain intact. Consider record count and byte limits in the same review.

## AUD-10 — Ambiguous desktop application matching

AppMatching.js:9–29 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/services/AppMatching.js#L9-L29`), WindowService.qml:44–69 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/services/WindowService.qml#L44-L69`), focus:100–115 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/services/WindowService.qml#L100-L115`), ApplicationService.qml:122–148 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/services/ApplicationService.qml#L122-L148`).

The fallback accepts the last component of a desktop ID without considering whether another installed application matches the same window. It may count one window under multiple books, and activating the wrong book could focus that window instead of launching the requested app. A full ID or explicit StartupWMClass match should take precedence globally, not only within each independent app test.

**Executed:** evaluating fetched matchesWindow for app IDs `org.example.editor` and `com.other.editor`, both with empty startupClass, against window appId `editor` returns true for both. Synthetic IDs demonstrate the ambiguous policy; no particular installed application pair or live misfocus is claimed.

Equivalent reproduction:

```sh
node --input-type=module <<'JS'
import fs from 'node:fs';
import vm from 'node:vm';
const c=vm.createContext({});
vm.runInContext(fs.readFileSync('quickshell/services/AppMatching.js','utf8'),c);
for(const appId of ['org.example.editor','com.other.editor'])
  console.log(appId,c.matchesWindow({appId,startupClass:''},'editor'));
JS
```

Acceptance: catalogue-aware resolution with ranked exact desktop ID / explicit class evidence and only unambiguous fallback; handle ties honestly rather than guessing. Same mapping for running shelf, launcher, focus counts and chooser. Test full-ID versus suffix collision, two suffixes, duplicate classes, case handling, window disappearance and launch behavior; native compositor test later.

## AUD-11 — Veranda state recovery is not protected like the Gallery

VerandaService.qml:43–65 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/services/VerandaService.qml#L43-L65`), 92–99 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/services/VerandaService.qml#L92-L99`), 199–209 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/services/VerandaService.qml#L199-L209`), VistaPolicy.js:48–64 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/services/VistaPolicy.js#L48-L64`).

This is the related but separate Veranda service, not a reopening of fixed Gallery AUD-04. It silently replaces failed JSON reads with initialState; cleanState also ignores unknown version. A valid catalogue triggers ensureToday on startup; backend success persists its selected state. User rotation/transition toggles also call persist directly. If the existing state was malformed, temporarily unreadable or a newer version, a later successful write may overwrite recoverable preferences. AtomicWrites does not distinguish legitimate first run from failed recovery.

Acceptance: reuse or adapt the Gallery's now-merged guarded recovery pattern for Veranda, without combining wallpaper and Gallery state. Preserve original bytes for malformed/unsupported/unreadable state, clearly surface warnings and require explicit recovery/reset before writes; test synthetic files, unknown schema, missing first-run state, successful apply and toggles during guarded mode. No actual data loss observed.

## AUD-12 — Redundant wallpaper apply while daily rotation is paused

VerandaService.qml:92–99 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/services/VerandaService.qml#L92-L99`), 141–153 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/services/VerandaService.qml#L141-L153`), 167–173 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/services/VerandaService.qml#L167-L173`), 199–210 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/services/VerandaService.qml#L199-L210`).

Automatic polling uses theme:fixed:id when rotation is disabled. Manual apply always uses theme:date:id. Successful completion stores the manual key; the next 60-second poll sees a different key for the identical current wallpaper and invokes the backend again. Similarly, a preference toggle while an application is busy can leave a key inconsistent with the final preference. This is a redundant request, not evidence of visible flicker.

**Executed:** fetched VistaPolicy with rotationEnabled=false and two eligible synthetic artworks. manualSelection('b') and subsequent forDay both return b. With date 2026-11-24 and theme twilight, the service's respective key expressions yield twilight:2026-11-24:b and twilight:fixed:b; they cannot deduplicate. No real wallpaper command run.

Acceptance: central key helper shared by manual/automatic requests and successful completion, reconcile final preference state; verify paused manual apply followed by multiple timer ticks results in one successful apply, while rotation/theme changes and explicit retry still work. Use mocked backend first.

## AUD-13 — Music progress can become stale while paused

GalleryMusic.qml:10–35 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/widgets/GalleryMusic.qml#L10-L35`), progress display:88–91 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/widgets/GalleryMusic.qml#L88-L91`).

Progress is a stored scalar refreshed when the player object changes or once a second while playing and active. If the same paused player seeks, changes track, or updates duration, no refresh is wired to those properties. A stale fraction can remain until playback resumes or a different player is selected. Reopening the Gallery with the same paused player does not explicitly refresh it either.

Acceptance: event-driven refresh for selected player position, seek, length/track and visibility/active changes, using signals actually provided by the installed Quickshell MPRIS version. Retain low-rate position updates during playback only. Test paused seek, next track while paused, new duration, hiding/reopening and player disappearance with a real or mocked MPRIS player. This is source-level evidence; target behavior untested.

## AUD-14 — Stale camera preference after undo and ID reuse

ArchiveCore.mjs:587–590 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/archive/ArchiveCore.mjs#L587-L590`), editorId:677–683 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/archive/ArchiveCore.mjs#L677-L683`), ArchiveScene.qml:99–116 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/archive/ArchiveScene.qml#L99-L116`), snapshot change:298–306 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/archive/ArchiveScene.qml#L298-L306`).

Undo restores snapshot.next, so a later create can reuse a cubby ID from an undone creation. Camera preferences live outside the snapshot in a map keyed only by cubby ID; saveCamera stores them on navigation, and onSnapshotChanged repairs path/selection but does not retire camera entries. Checkpoint export prunes absent IDs, but does not distinguish an ID reused before export.

**Executed:** fixture → create nested cubby at (520,0), size 160×120 → Undo → create at (520,160), same size. First and second child both get cubby-27, with no error; next returns to 26 after Undo. The camera consequence is inferred from inspected QML, not an executed Qt interaction.

Acceptance: create A, enter and pan/zoom, back, Undo creation, create unrelated B; B starts with default camera. Preserve expected camera restoration for genuine deleted-then-undone cubby; do not casually make all snapshot IDs monotonic if this would break exact Undo. Consider retiring/transferring camera entries by transaction lifecycle or separate generation identity. Include checkpoint save/load and navigation.

## AUD-15 — Veranda URL/path conversion still permits reserved-character ambiguity

VistaPolicy.js:6–17 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/services/VistaPolicy.js#L6-L17`), VerandaService.qml:67–79 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/services/VerandaService.qml#L67-L79`), VistaTransition.qml:49–51 (historical `blob/0a1f52e1e2c428944ca4a9a2c21dae2ddd6ac316/quickshell/widgets/VistaTransition.qml#L49-L51`).

Unlike the Gallery after PR #13, the wallpaper manifest permits filenames with #, ?, and percent sequences, and the service concatenates a raw filename to Qt.resolvedUrl then decodes it for the daemon. The transition layer re-encodes the decoded path with encodeURI, which leaves reserved # and ? unescaped. A legal local filename can become a URL fragment/query, or a percent-like string can be decoded unexpectedly. Exact Qt/daemon behavior needs local reproduction; no specific current manifest filename is claimed broken.

Acceptance: preserve literal filesystem path for the daemon; encode each URL segment once when loading images. Reuse suitable shared pure encoding policy only if it preserves the differing manifest suffix rules. Test synthetic local files with spaces, Unicode, #, ?, %, percent-escape-like strings and malformed encodings, both ordinary fade and shader path. Keep local-only checks.

## Second-pass validation and handoff

The new pure-JS evidence consists of executing the fetched Core/Checkpoint, matching and VistaPolicy functions in a JS runtime; ID reuse was also executed. QML consequences are distinguished from those results. No new full CI suite, native Qt interaction, Quickshell, MPRIS, Wayland, GPU or daemon test was run for this documentation change. Main CI success is independently retrieved baseline evidence. Suggested follow-up: prevent checkpoint save dead ends and ambiguous focus; protect Veranda recovery before real user state; then handle smaller interaction issues. These are proposed priorities, not a new product requirement or a change to active development. Recheck at the fix branch head and record the actual fixing PR and validation.

---

# Third audit pass — merged main 4366c5c (2026-11-24)

**Baseline:** 4366c5c (historical `commit/4366c5cae25d949ea7d21c8c595de8132893d6b4`), merge of PR #15 (historical `pull/15`), incorporating PR #16 / B7-N2 (historical `pull/16`) at 17fecd7. Main CI 45480799164 (historical `actions/runs/45480799164`) succeeded. Only merged main inspected. The original audit rounds remain historical, not a live open-issue list.

**Resolution status:** AUD-01–08 source fixes merged in PR #13; AUD-10–13 and AUD-15 source fixes in PR #15; AUD-09/14 source fixes and regressions in PR #16. B7-N2's recorded offscreen Qt and Node acceptance includes capacity and camera-reuse cases. This audit does not independently rerun all earlier regressions or provide target-desktop sign-off. Do not reopen these findings merely because their historical reproductions remain above. The new entries below are distinct from those fixes.

| ID | Priority | Finding | Evidence |
|---|---|---|---|
| AUD-16 | P1 | Brightness control rejects actual brightnessctl machine-readable CSV | Executed merged parser; upstream output format verified |
| AUD-17 | P2 | Mixed object remains visible at source during provisional carry/settling | Source-level view/transaction mismatch; Qt capture pending |
| AUD-18 | P3 | Valid checkpoint cubby ID can resolve inherited camera property | Executed Core/codec roundtrip and camera lookup; Qt consequence inferred |
| AUD-19 | P3 | Upright display reservation is too narrow for accepted scale 1.3 | Executed actual geometry and Core.validate; imported checkpoint edge case |
| AUD-20 | P3 | Legitimate desktop ID constructor is silently dropped from shelf and home launcher | Executed shelf policy; launcher counterpart inspected |

## AUD-16 — Real brightnessctl CSV cannot be parsed

UtilityPolicy.js:12–22 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/services/UtilityPolicy.js#L12-L22`), UtilityService.qml:101–126 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/services/UtilityService.qml#L101-L126`), check-utilities.js (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/scripts/check-utilities.js#L19-L26`).

Upstream [brightnessctl.c print_device](https://github.com/Hummer12007/brightnessctl/blob/master/brightnessctl.c#L376-L383) emits machine-readable fields in this order: device, class, current, percentage, maximum. The percent token is followed by a comma; the current regex requires whitespace or end of string after %. The repository comment and green test fixtures incorrectly put the percentage last.

**Executed against merged UtilityPolicy:** parseBrightness('intel_backlight,backlight,400,20%,2000') returned null; parseBrightness('intel_backlight,backlight,400,2000,20%') returned 20. The former matches the actual upstream printf format. The latter matches the repository's artificial test format. A successful read therefore sets brightnessAvailable false and disables normal slider interaction. No hardware command executed.

Equivalent reproduction from repo root:

```sh
node --input-type=module <<'JS'
import fs from 'node:fs';
import vm from 'node:vm';
const c=vm.createContext({});
vm.runInContext(fs.readFileSync('quickshell/services/UtilityPolicy.js','utf8'),c);
console.log(c.parseBrightness('intel_backlight,backlight,400,20%,2000'));
console.log(c.parseBrightness('intel_backlight,backlight,400,2000,20%'));
JS
```

Expected: 20 for canonical CSV; validate field order deliberately rather than accept arbitrary malformed output. Acceptance: realistic upstream CSV including 0%, 100%, multiple devices if supported, invalid/missing device, nonzero exit, range checks and consistent backlight-device selection for both read and write. Preserve the existing 5% write safety floor. Verify real read/write on laptop; do not change system settings merely to test parser. This is a high priority recommendation because the ordinary control may be disabled on first use despite installed working backend.

## AUD-17 — Mixed-source visuals are not provisional-ownership aware

ArchiveMotion.mjs:39–54 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/archive/ArchiveMotion.mjs#L39-L54`), ArchiveMotion.qml:23–28,49–74 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/archive/ArchiveMotion.qml#L23-L74`), ArchiveScene.qml:427–509 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/archive/ArchiveScene.qml#L427-L509`), carry ghost/Case:600–643 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/archive/ArchiveScene.qml#L600-L643`), B7MixedShelf.qml:34–87 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/archive/representation/B7MixedShelf.qml#L34-L87`).

Motion.lift removes a mixed record from the private draft, but the mixed shelf/mount delegate remains bound to the committed module (or material/structural preview), not live mixed ownership. Unlike rack membership and Case hiddenIds, it has no carried/source suppression input. The scene also displays the carried scroll ghost. Thus a shelf object or mounted picture can remain rendered at its original location while its scroll ghost is carried, and during rack settling the new provisional rack scroll can coexist with the old visible object. Conversely a lifted rack scroll placed onto a mixed fixture can be absent at both locations until settling commits. This does not duplicate the committed model's ownership; it is a transient visual inconsistency. Existing final-state B7 tests/captures establish post-commit identity, not this intermediate-state behavior. Qt visual reproduction pending.

Acceptance: capture mid-drag, after release while solver remains active, commit and Escape/invalid-drop rollback for shelf/mount to rack and rack to mixed fixture; no duplicate apparent objects or disappearance inconsistent with the intended carry cue. Prefer a view-only provisional membership/visibility mechanism preserving source MouseArea/capture, shelf and holder geometry, metadata, and exact committed rollback. Do not replace the active gesture delegate or shrink the holder/cradle envelope mid-gesture. A deliberately styled empty silhouette is permissible if clearly not a second file object. Keep holder's existing internal edge drag semantics and the approved universal scroll representation.

## AUD-18 — Inherited camera key in an otherwise valid imported checkpoint

ArchiveCapacity.mjs:5–12,22–24 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/archive/ArchiveCapacity.mjs#L5-L24`), ArchiveCheckpoint.mjs:12–22 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/archive/ArchiveCheckpoint.mjs#L12-L22`), ArchiveScene.qml:157–165 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/archive/ArchiveScene.qml#L157-L165`).

Checkpoint ID validation excludes __proto__, constructor and prototype, but accepts Object.prototype member names such as toString. The scene's restoreCamera looks up cameras[cubbyId] without checking ownership. A valid imported cubby with ID toString and no saved camera resolves the inherited function instead of default camera values. Its zoom/x/y are undefined; QML may reject the assignments or produce invalid view state. This is distinct from fixed AUD-14 ID reuse. Generated editor IDs use cubby-N and are not shown to trigger this.

**Executed:** start Core.fixture(), add root module {id:'child-module',type:'cubby',x:520,y:0,w:160,h:120,childId:'toString'} and child {id:'toString',w:470,h:340,mods:[]}; Core.validate returns null. Encode/decode with view {path:['root','toString'],theme:0,cameras:{}} succeeds. hasOwnProperty(cameras,'toString') is false but typeof cameras.toString is 'function'; the restoreCamera ternary chooses undefined zoom and pan coordinates. No Qt runtime invoked.

Acceptance: ensure missing camera entries default regardless of valid imported identifier, e.g. own-property check or null-prototype lookup; review camera map creation/reconciliation and other ID-keyed dictionaries consistently. Do not reject previously legal checkpoint IDs or silently rewrite them without a compatibility decision. Add explicit roundtrip/navigation tests for inherited-property names and ordinary generated IDs, preserve genuine deletion/Undo restoration.

## AUD-19 — Upright cradle reservation underestimates accepted maximum scale

B7Ownership.mjs:43–54 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/archive/representation/B7Ownership.mjs#L43-L54`), B7MixedShelf.qml:70–87 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/archive/representation/B7MixedShelf.qml#L70-L87`), B7PresentationCradle.qml:9–28 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/archive/representation/B7PresentationCradle.qml#L9-L28`), B7Layout.mjs:8–17 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/archive/representation/B7Layout.mjs#L8-L17`).

The holder validator accepts scale .4–1.3 but reserves a constant 244-wide cradle. All six record/v1–v6 assets have 190-unit face bounds. At scale 1.3 the presented face is 247 units wide; its centered bounds extend 1.5 units on each side of the cradle. The right edge exceeds the reserved fixture envelope. Adjacent furniture or a cubby wall may overlap/clip it despite a valid placement. This concerns accepted checkpoint/model scale, not the current editor's fixed .86 default or a claim that ordinary captures already overlap.

**Executed:** using exact B7Layout/B7AssetData/Catalog functions, supportedLayout('record/v1',122,0,1.3).box returns {x:-1.5,y:-247,width:247,height:247}; same for all six record faces. Core validates a fixture with root 1400×800, shelf x540 y400 w800 h15, holder x0 w130 scale1.3 with one record/v1. Its holder reservation is x540,y95.5,w390,h304.5, corresponding to 130+16+244. This proves a geometry discrepancy, not a rendered collision reproduction.

Acceptance: compute shared reserved cradle envelope from maximum permitted presentation geometry (including stroke padding) and use it for both renderer/hit geometry and validation, or formally constrain the supported scale with backwards-compatible checkpoint handling. Verify extreme allowed scales, all upright variants, adjacent fixture and wall, empty holder followed by insertion, shrink and exact Undo. Keep normal .86 visual baseline unchanged unless necessary.

## AUD-20 — Shelf policy still drops legitimate inherited-name desktop IDs

ShelfModel.js:10–43 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/services/ShelfModel.js#L10-L43`), LauncherModel.js:14–40 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/services/LauncherModel.js#L14-L40`), ArchiveCapsule.qml:56–60 (historical `blob/4366c5cae25d949ea7d21c8c595de8132893d6b4/quickshell/panels/ArchiveCapsule.qml#L56-L60`).

The ranked window index from PR #15 correctly uses null-prototype maps, but shelf availability/seen/runningSet and home launcher seen are still ordinary objects. A legitimate synthetic desktop ID constructor (or constructor.desktop after normalization for the shelf) is mistaken for an existing dictionary entry and silently omitted. This is independent of ambiguous app matching AUD-10 and malformed constellation IDs AUD-03.

**Executed:** splitShelfApps([{appId:'constructor',title:'Constructor'},{appId:'firefox',title:'Firefox'}],['constructor'],['constructor'],5,5) returns no pinned or running entries, totals zero. Home launcher has the analogous seen check for raw ID constructor (source inspected). No actual installed application with that ID is claimed. Normal common IDs are unaffected. Also note shelf case-normalizes already resolved running IDs; do not conflate exact distinct IDs if future matching semantics change. The current ranked index deliberately refuses normalized collisions, so a direct synthetic shelf collision is not evidence of a currently reachable compositor misfocus.

Acceptance: prototype-free dictionaries or Set for membership, preserve catalogue-wide resolution and pin ordering; test constructor, normal IDs, duplicates and hidden counts, home launcher fallback and running shelf. Preserve existing documented normalized-ID policy unless a separate owner decision changes it.

## Third-pass verification and follow-up

Executed fetched merged pure-JS functions in the available JS runtime (module syntax adapted only to link exact fetched dependencies for Archive tests). Upstream brightnessctl print_device was inspected, not guessed. No hardware brightness changes, native Qt capture, Quickshell session or full suite rerun for this documentation-only update. Main's successful CI is separately retrieved evidence. AUD-16, AUD-18/19 and shelf part of AUD-20 have concrete executed evidence; AUD-17 is a source-derived visual issue requiring an intermediate-state Qt test. P1/P2/P3 are suggested priorities, not owner-approved schedules. Recommend addressing AUD-16 before first laptop bring-up and AUD-17 before treating mixed transport's visual fidelity as complete. Keep PR #12 documentation-only; coordinate fixes through owner-authorized implementation topic. No filesystem operations, production wiring, new milestone or unrelated feature is proposed.

# Fourth audit pass — focused CI reliability referral (2026-11-25)

Public merged-main baseline: [53b338db7d5651311f42ff8934f018e16d6f4e8d](https://github.com/Kaim-h/astral-archive/commit/53b338db7d5651311f42ff8934f018e16d6f4e8d). [Main CI 45608436309](https://github.com/Kaim-h/astral-archive/actions/runs/45608436309) reports all three jobs successful. This pass is limited to the B6r7 referral; AUD-01–15 remain integrated source fixes and AUD-16–20 remain allocated to open public PR #4 (head 9597e88a87b3db636053bfd3924f0e47de6dac13, latest correction acceptance outstanding). No reopening or new assertion of target verification.

## AUD-21 — Intermittent B6r7 grouped-cut browser regression

**Proposed priority:** P2 / CI reliability. **Confirmed:** an executed intermittent regression-check failure on a historical browser study. **Unconfirmed:** underlying cause, persistence of a failed cut, or a corresponding current Archive interaction defect. Distinct from AUD-17 provisional native rendering.

Referral: [PR #3 comment](https://github.com/Kaim-h/astral-archive/pull/3#issuecomment-7161775345).

### Evidence independently retrieved

[Push run 45539707797, browser job 138954940153](https://github.com/Kaim-h/astral-archive/actions/runs/45539707797/job/138954940153) checked out b4c823b97116c07021d6d249492bbe39ae385a53; [PR run 45539717173, browser job 138954975063](https://github.com/Kaim-h/astral-archive/actions/runs/45539717173/job/138954975063) checked out 0be7fb019a3938a815b0f6ae5cb305e132340cc9. Raw logs identify both checkout commits; commit metadata gives identical tree 736c65adf9e8ac41df8515e9e51c9ef90402cb9a. Both jobs used the B6r7 grouped-cut step; the passing log reports successful group cut, Save, IDs, original cradle, manifest and dock collapse. Failing log reports AssertionError: 4 !== 1 at scripts/smoke-b6r7.js:35:10 after successful group-selection assertion; offline-js and native-archive-qt passed. This is an executed failure, not an infrastructure/compute block. CI installs Playwright 1.56.1, Chromium 141.0.7390.37. The [cutover baseline](https://github.com/Kaim-h/astral-archive/commit/38f218a5bae7d2ad0a37315d5fda6ab0a9d9a0bf), failing checkout and current main all contain identical test blob 00ec70bf966eb3f2f1fe920102bfdf6d83b4748a and prototype blob d87f17038d78614845b4cc8d4315c21ac565dc11. Later successful CI has not corrected these files.

### Source trace and bounded browser experiment

- [smoke-b6r7.js:10–37](https://github.com/Kaim-h/astral-archive/blob/53b338db7d5651311f42ff8934f018e16d6f4e8d/scripts/smoke-b6r7.js#L10-L37): opens four-or-more-record cell, waits for bridge, uses real Ctrl-click to select three, calls focus() on #scene, sends Control+x, then immediately evaluates body count and Case membership. First count assertion aborts before Case assertions: failed run does not establish Case contents or eventual outcome.
- [B6r7 embedded source and patch:1958–1964](https://github.com/Kaim-h/astral-archive/blob/53b338db7d5651311f42ff8934f018e16d6f4e8d/docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r7.html#L1958-L1964): decoded b4PhysicsSource line 36 is SVG #scene with role=img and no tabindex; scroll groups have tabindex=0 (decoded line 332). Base existing-body pointerdown prevents default; modifier selection patch also prevents default and stops propagation. Therefore focus() of the SVG is not a reliable assertion of actual keyboard focus. Decoded b6r7PhysicsPatch lines 114–125 cut synchronously when guards allow; lines 219–234 handle inner document keydown or parent message. The guard refuses if st.drag, st.pointer, st.insertion, st.held or st.stagedId is truthy. A refusal, lost key, or delayed message could leave all four bodies at observation. No actual guard state was captured in the failed run.
- [Outer key handler:2897–2906](https://github.com/Kaim-h/astral-archive/blob/53b338db7d5651311f42ff8934f018e16d6f4e8d/docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r7.html#L2897-L2906): when parent document receives Ctrl+X and overlay is open, it posts {channel:'astral-b4',action:'cut'} to iframe; the actual cut occurs in a subsequent message event. No explicit acknowledgement or condition-based completion wait precedes the smoke test state read.

**Executed reduced browser probe, not original-prototype reproduction:** local Python Playwright with system headless Chromium 144.0.7559.96, synthetic four-record iframe SVG and focusable parent button, source-shaped selection/preventDefault, cut membership and inner-key/outer-message handlers; omitted actual physics, model bridge, Save and full artwork. Real unforced mouse clicks, Ctrl modifier and Ctrl+X; logged active elements in both documents, handler route, source count in outer handler immediately after postMessage, subsequent evaluated count, and final Case IDs. Five repetitions each of four cases: (1) parent button initially focused, ordinary selection then nonfocusable SVG focus call; (2) deliberately restore parent focus after selection then same SVG focus call; (3) deliberately focus inner scroll group then same SVG focus call; (4) diagnostic SVG tabindex=0 then focus. Cases 1/2 retained parent BUTTON, inner BODY, parent key handler saw 4 after queuing message, then message cut; cases 3/4 focused iframe with inner g/svg and direct key handler. All 20 subsequent immediate reads returned 1 and all ended with exact carried IDs [1,2,3]. An earlier 20-run reduced focus-variant experiment also passed. Thus focus ambiguity and asynchronous route are demonstrated mechanisms, not reproduction of the CI assertion failure or proof that the message remained pending at its evaluation. No arbitrary delay injected into application or test. Exact checkout unavailable locally (network DNS blocked; CI Playwright Node package unavailable); source retrieved through GitHub, reduced probe used locally installed Python Playwright and different Chromium version. Full pinned prototype with actual physics and original smoke remains to be run/instrumented.

### Current-study scope

[B6r12b3 direct scene handler:3747–3764](https://github.com/Kaim-h/astral-archive/blob/53b338db7d5651311f42ff8934f018e16d6f4e8d/docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r12b3.html#L3747-L3764) calls b12bTransfer directly; [4166–4174](https://github.com/Kaim-h/astral-archive/blob/53b338db7d5651311f42ff8934f018e16d6f4e8d/docs/research/prototypes/2026-11-20/cubby-studies/Astral_Archive_Cubby_Study_B6r12b3.html#L4166-L4174) overrides normal rack opening to direct scene instead of historical iframe. Retained legacy source alone does not establish same route in normal current study. [Native ArchiveScene.qml:323–349](https://github.com/Kaim-h/astral-archive/blob/53b338db7d5651311f42ff8934f018e16d6f4e8d/quickshell/archive/ArchiveScene.qml#L323-L349) handles Qt Key_X and calls live.transfer with selected IDs, not browser postMessage. Other focus, refusal or async transaction issues remain possible, but require their own evidence. Neither newer interaction was reproduced in this pass.

### Recommended investigation and acceptance

Instrument original pinned B6r7 with timestamps and actual parent/iframe activeElement, keydown delivery, parent relay and child message receipt, cut entry/return with guard flags, selected IDs, both membership sets before/after, status text and Save/manifest outcomes. Repeat real unforced input on pinned CI Playwright/Chromium. Compare successful and failed traces; a delivered-but-refused cut is not a synchronization bug, and a pending successful cut is not permanent product failure. Establish intentional keyboard focus (test it rather than assume it); if delayed valid cut is demonstrated, wait with a bounded condition for exact source and Case IDs/modes and report refusal/timeout diagnostics. Do not merely add arbitrary sleeps/retries, force clicks, skip historical gates or invoke the model cut directly instead of the input path. Retain the existing Save/manifest/identity/one-authoritative-Case assertions, confirm one remaining source and exactly three carried originals, no duplicate/lost IDs. Test normal B6r12b3 and native separately if evidence warrants. Obtain repeated targeted passes with diagnostics and relevant full-suite green at corrected exact head before closing. Correction belongs to authorized corrective workstream; no runtime, prototype, test or workflow changes in this audit. No new CI dispatch or merge requested.
