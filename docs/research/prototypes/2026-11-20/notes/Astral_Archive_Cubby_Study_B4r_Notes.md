# Astral Archive — Cubby Study B4r (interaction regression repair)

**Source:** browser-only Study B4, using its embedded P2R physics-cell simulator. **Status:** prototype, synthetic scrolls, not Quickshell or filesystem implementation. No repository changes or commits.

## Changes from B4

1. **Direct hex-cell entry:** In Browse, clicking a visible hexagonal cell or one of its scroll ends opens that cell's P2R physics workspace immediately. The redundant focused-rack selection stage is no longer necessary. The old focused-rack flow remains in source as legacy code but is not used for the normal interaction.
2. **Pre-settled seed positions:** Before the rack's first display, synthetic cell contents are iterated through an offline P2R-style fixed-step gravity/contact solver (150 gravity/100 liveliness parameters, scaled to each cell's actual radius). Results are committed only if scrolls remain inside the actual clipped cell polygons without problematic overlap; otherwise initial nonoverlapping positions are preserved. This is a browser prototype implementation, not an approved native physics backend.
3. **Module placement layer:** Creating Rack, Shelf or Nested Cubby switches to Arrange and starts a *provisional* movable/resizable preview. Existing modules do not block the preview's movement; they only affect whether **Place module** is green/allowed or red/disabled. Optional 20-unit grid/snap, exact X/Y/Width/Height inputs, Expand Cubby, Confirm and Cancel. The module is not created (and nested child identity is not allocated) until confirmed. Cancellation leaves no module.
4. **Stage visibility:** On wide screens, the cubby remains visible while the long control sidebar scrolls. The placement controls stay visible on the stage.
5. **Sample furniture:** Code → Utilities / Scripts / Drafts and Resources / Configurations have more deliberate, valid fixture positions. The populated racks are pre-settled. Empty created cubbies remain empty.
6. **Arrange-mode interaction:** Scroll art no longer consumes rack-selection clicks while Arrange is active.

## Validation evidence

Ran Chromium/Playwright HTML tests on the exact generated file:

- Direct cell entry from the main Code cubby, including clicking a scroll end; no intermediate modal. Opening and no-op saving returns to the same view.
- New-shelf provisional pointer dragging and handle resizing, plus safe green placement and red invalid placement.
- Green placement committed only upon confirmation; Cancel does not add a module. Tested expansion and exact dimension edits in a crowded Code cubby.
- Sample validity across Code, Utilities, Scripts, Drafts, Resources and Configurations.
- All sampled seeded rack cells settled without failures, with largest measured boundary penetration ~0.002 and largest scroll-scroll overlap ~0.004 logical units.
- Chromium JavaScript errors observed in the tested paths: none.

## Known limitations

- The physics workspace still runs in an embedded same-page iframe sourced from P2R. It is an integration prototype, not a unified engine/rendering surface.
- Pre-settling copies P2R's contact/gravity rules at rack-world scale; it is not yet a shared, single compiled solver and should be consolidated before native implementation.
- The file data is synthetic, and layout changes are not persisted to the filesystem or across reloads.
- Large/small screen and accessibility validation are incomplete. Collision tuning is deliberately not revisited in B4r.
