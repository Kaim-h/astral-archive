# Scroll physics and P2R insertion — browser design reference

**Status:** accepted interaction direction drawn from P2R and B5 studies; **not** a selected QML/native physics backend or proven complete solver. Study artifacts use synthetic files.

- End-on scroll circles have stable IDs and compressed/logarithmic file-size radii (roughly five tiers). Use the **same exact clipped polygon and physical painted-wall inset** in overview, focus, hit testing, collision and persistence.
- Save settled positions; pre-settle samples before overview appears. Dormant cells should be quiet/cached; only an active or explicitly manipulated cell simulates.
- Live dragging uses spring-damped pointer tether, immediate collisions and pushing with gravity/friction/low bounce. The actual scroll may trail a blocked pointer. Avoid both sluggish overdamping and teleporting/bouncy pinball behavior; fixed-step, bounded contacts and no hidden multi-step jump.
- Prototype controls defaulted to **Gravity 150** and **Liveliness 100%**, with user-facing sliders. These are study settings, not blindly portable physical constants.
- Insertion targets **connected void regions**, not arbitrary fitting dots. Hover highlights the whole visible connected void; click locks the region even when pointer moves to Insert. Shift-click may attempt an occupied/crowded position with gentle neighbor displacement, but failure must leave the scroll held and old layout untouched.
- Distinct **Drop from top** requires a physically feasible opening and visible falling, not a silent jump to another insertion site. Any successful Save needs valid settled containment and overlap tolerances.
- In rack overview, short click opens the clicked hex directly; dragging crosses a threshold to lift the same scroll, lets its source settle, and carries it visibly. Drop on origin restores the exact snapshot; drop on another hex stages it held for deliberate insertion; drop outside valid targets cancels. Do not auto-insert just because the pointer crossed a destination.
- A persistent portable holder can carry multiple scrolls between different cubbies. Each keeps stable origin `cubbyId/rackId/cellId` plus filename, radius and metadata; only the accepted Save consumes that held item. Source/destination/holder/Undo must behave as a single reversible transaction.
- Keep detailed hover/click metadata and purpose seal behavior in [scroll seals](SCROLL_SEALS_AND_METADATA.md). Do not equate purpose-pigment with file permission.

**Unresolved:** production collision engine, exact geometry integration, cross-view canonical renderer, durable source ownership/lineage, holder return after splits, performance and native Qt/Wayland behavior. Matter.js and Suika coefficient guesses were exploratory, not an engineering decision.
