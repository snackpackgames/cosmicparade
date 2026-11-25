# Board Piece and Placement Seam Implementation Plan

> **For agentic workers:** Implement this plan task-by-task, committing after each task as it
> directs. Steps use checkbox (`- [ ]`) syntax for tracking. **Do not create a git worktree** —
> `CLAUDE.md → Claude Code Configuration` forbids them in this repo; work on a topic branch in
> the main working directory. The usual sub-skill for inline execution is
> `superpowers:executing-plans`; `superpowers:subagent-driven-development` is not used here
> because it provisions a worktree.

**Goal:** The realm board stops deciding behaviour by asking what is standing on it. What a thing
projects, whether it holds an offering, and whether it reads influence all come from **components
it carries**, so the three type branches [#104](https://github.com/snackpackgames/cosmicparade/issues/104)
names disappear without any observable behaviour changing.

**Architecture:** A piece carries at most one **zone source** (an authored `DomainProjection` for
furniture, an `OfferingVessel` for a shrine, nothing for the Altar) and at most one **influence
reading** capability (the Altar only). A placeable asks its own components; nothing asks a
collaborator's type. Authored components share their reference; a component whose contents change
returns a copy of itself when a placeable is built, and it is the component — not the construction
site — that knows which it is. `ShrinePlacement` goes, leaving one placement class. The Altar's
footprint becomes a derived accessor instead of a stored index.

**Tech Stack:** Godot 4.7.2-stable, GDScript, GUT 9.7.1.

**Spec:** [Map: where the seam sits between a board piece and its
placement](https://github.com/snackpackgames/cosmicparade/issues/125) — eight closed decision
tickets. Every rule below links the ticket that settled it. **Where this plan says "decided", the
linked ticket holds the reasoning: do not re-derive it, and do not substitute a different answer
because it looks better in context.**

This plan follows [`2026-11-16-swell-shrines-and-the-altar-plan.md`](2026-11-16-swell-shrines-and-the-altar-plan.md),
merged. `BoardPiece`, `BoardPlacement`, `ShrinePlacement`, `Furniture`, `Shrine`, `Altar`,
`RealmState`, `PlacementRules`, `Carry`, `CarriedPiece`, `CarriedWing`, `InfluenceZone`, `Fruit`
and `GameData` all exist and are the inputs here.

## Global Constraints

- **Behaviour-preserving, with exactly one stated exception.** All three of #104's branches are
  correct today; 330-plus tests pass and lint is clean. **The suite is the acceptance criterion:
  no test's assertions may be weakened or deleted to make a refactor fit.** Tests change only
  where they construct something this plan renames or removes. The one exception is named in the
  Phase 5 constraint below.
- **Test the type of the object whose behaviour varies; never reach through to ask a
  collaborator's type** ([decided](https://github.com/snackpackgames/cosmicparade/issues/126)).
  The stopping rule an implementer greps for: **a test on `piece` or `<something>.piece` that
  governs a placement.** Engine-boundary narrowings (`$Node as Type`, `load(...) as Type`) are
  legitimate and are not touched. Assertions in `test/unit/` are **not** governed by this rule.
- **Reading authored data off a piece is not a reach-through.** #126 bans **type** tests on a
  collaborator. `PlacementRules` already reads `piece.criteria`, and this plan reads
  `piece.zone_source` and `piece.reading` the same way. A null check on a role slot is a field
  read ([decided](https://github.com/snackpackgames/cosmicparade/issues/135)). Do not "fix" these
  into something else.
- **A piece carries at most one zone source, in a named slot**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/135)). No piece has both an
  authored projection and a vessel, so `BoardPlacement.zone()` resolves one slot with no branch.
  **Do not introduce an `Array[Component]`** — `criteria` stays an array because criteria are
  cardinality-many; these are roles with at most one apiece.
- **Capability questions are default-false methods on the component base**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/135)), overridden by the
  component that answers `true`. The component answers about **itself**. Do not replace them with
  `is` checks or type-keyed lookups.
- **A component is authored and shared when it holds only immutable data, and per-copy only when
  its contents change** ([decided](https://github.com/snackpackgames/cosmicparade/issues/127)).
  **The component declares which it is** — `for_placement()` returns `self` by default and a copy
  in `OfferingVessel` ([decided](https://github.com/snackpackgames/cosmicparade/issues/135)). The
  construction site never learns which components are mutable, and **no uniform `duplicate()`**.
- **A piece that projects nothing returns `null`, never an empty zone**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/37)). The depth tally counts
  zones, so an empty entry would be miscounted as coverage. This holds at every layer added here:
  `ZoneSource.zone_over`, `BoardPlacement.zone()`, and an `OfferingVessel` with no offering.
- **Derived, never stored.** The Altar's footprint
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/128)), "unplaced", and the
  vessel's placement ([decided](https://github.com/snackpackgames/cosmicparade/issues/127)) are
  all derived or passed at call time. A stored copy of any of them repeats how `altar_placement`
  went stale in [#102](https://github.com/snackpackgames/cosmicparade/pull/102).
- **No piece script is collapsed or renamed** ([decided](https://github.com/snackpackgames/cosmicparade/issues/127)).
  `Furniture`, `Shrine` and `Altar` all remain, even where they end up adding no members —
  `Altar` already does exactly that today, on purpose.
- **`bash scripts/import.sh` after adding any new `class_name`**, before running tests, per
  `CLAUDE.md`. Every phase here but Phase 6 adds at least one.
- **Run `bash scripts/lint.sh` before every commit.** CI runs gdlint then GUT.

## Review Focus

Five things the spec implies that no task's own happy-path test would exercise. Each has its test
pinned to the task that owns the code.

1. **Two placeables built from the same authored shrine must not share a vessel.** This is the
   whole purpose of `for_placement()` copying, and nothing in the suite covers it today — a
   `for_placement()` that returned `self` would pass every other test and silently make two
   shrines one. Pinned in Task 2.1.
2. **An empty vessel must contribute nothing to its own verdict context**, and a fed one must
   contribute its zone ([#75](https://github.com/snackpackgames/cosmicparade/issues/75),
   [#41](https://github.com/snackpackgames/cosmicparade/issues/41)). Pinned in Task 5.2.
3. **`altar_hexes()` on a realm with no Altar must return `[]`** and leave
   `altar_straddles_wing` and `altar_reading` answering without a crash — both lose a null guard
   in Phase 3 and rely on iterating empty. Pinned in Task 3.1.
4. **A placeable lifted from inventory has no hexes**, so `own_orientation()` must return `-1` and
   `hexes_at` must still answer from the grab offset. "Unplaced" is derived from this and nothing
   else. Pinned in Task 4.1.
5. **A placeable whose piece authors no zone source contributes `null`, not an empty zone.** The
   Altar is the live case; a `zone()` that returned an empty `InfluenceZone` would be miscounted
   as coverage by the depth tally. Pinned in Task 1.4.

---

## Phase 1 — The authored components and the piece's role slots

Furniture and the Altar only. Immutable, shared components with no per-copy state, so the vessel's
copying question does not arise yet. `Shrine` and `ShrinePlacement` are untouched and keep working
through `ShrinePlacement`'s own `zone()` override.

**Files:**
- Create: `realm/zone_source.gd`, `realm/domain_projection.gd`, `realm/influence_reading.gd`
- Modify: `realm/board_piece.gd`, `realm/furniture.gd`, `realm/altar.gd`,
  `realm/board_placement.gd`, `realm/placement_rules.gd`
- Modify: `data/realm/furniture/mushroom_stool.tres`, `data/realm/furniture/fern_bench.tres`,
  `data/realm/furniture/standing_stone.tres`, `data/realm/altar/altar.tres`
- Test: `test/unit/realm/test_zone_source.gd`, `test/unit/realm/test_domain_projection.gd`,
  `test/unit/realm/test_board_piece.gd`, `test/unit/realm/test_furniture.gd`,
  `test/unit/realm/test_altar.gd`, `test/unit/realm/test_board_placement.gd`

**Interfaces:**
- Consumes: `GameData`, `InfluenceZone.project(domain, hexes, radius)`, `Domain.Kind`.
- Produces: `ZoneSource.zone_over(hexes) -> InfluenceZone`,
  `ZoneSource.for_placement() -> ZoneSource`, `ZoneSource.can_hold_offering() -> bool`,
  `ZoneSource.holds_offering() -> bool`, `ZoneSource.accept_offering(Fruit) -> void`,
  `ZoneSource.empty_vessel() -> void`; `DomainProjection` with `@export domain`, `@export reach`;
  `InfluenceReading`; `BoardPiece.zone_source`, `BoardPiece.reading`,
  `BoardPiece.reads_influence() -> bool`.

### Task 1.1: `ZoneSource`, the component base

- [ ] **Step 1: Write the failing test** `test/unit/realm/test_zone_source.gd`

```gdscript
func test_the_base_projects_nothing() -> void:
	assert_null(ZoneSource.new().zone_over([Vector2i.ZERO] as Array[Vector2i]))

func test_the_base_is_shared_rather_than_copied() -> void:
	var source := ZoneSource.new()
	assert_eq(source.for_placement(), source, "immutable data shares its reference")

func test_the_base_answers_no_to_every_vessel_question() -> void:
	var source := ZoneSource.new()
	assert_false(source.can_hold_offering())
	assert_false(source.holds_offering())
```

- [ ] **Step 2: Run `bash scripts/import.sh`, then the test, to verify it fails**

Expected: FAIL — `ZoneSource` not found.

- [ ] **Step 3: Implement `realm/zone_source.gd`**

`class_name ZoneSource extends GameData`. Six methods, every one a default an override replaces:
`zone_over(_hexes: Array[Vector2i]) -> InfluenceZone` returns `null`;
`for_placement() -> ZoneSource` returns `self`;
`can_hold_offering() -> bool` and `holds_offering() -> bool` return `false`;
`accept_offering(_fruit: Fruit) -> void` and `empty_vessel() -> void` do nothing.

Document **why** each default is what it is: `null` rather than an empty zone per
[#37](https://github.com/snackpackgames/cosmicparade/issues/37); `self` rather than a copy because
authored data is never mutated at runtime, per
[#127](https://github.com/snackpackgames/cosmicparade/issues/127); and the four no-ops because a
capability question is answered by the component about itself rather than type-tested from outside,
per [#135](https://github.com/snackpackgames/cosmicparade/issues/135).

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash scripts/test.sh realm/test_zone_source.gd`

- [ ] **Step 5: Lint and commit**

```bash
bash scripts/lint.sh
git add realm/zone_source.gd realm/zone_source.gd.uid test/unit/realm/test_zone_source.gd test/unit/realm/test_zone_source.gd.uid
git commit -m "feat: add the zone source component base"
```

### Task 1.2: `DomainProjection` and `InfluenceReading`

- [ ] **Step 1: Write the failing test** `test/unit/realm/test_domain_projection.gd`

```gdscript
func test_it_projects_its_domain_at_its_reach() -> void:
	var projection := DomainProjection.new()
	projection.domain = Domain.Kind.GALE
	projection.reach = 2
	var zone := projection.zone_over([Vector2i.ZERO] as Array[Vector2i])
	assert_eq(zone.domain, Domain.Kind.GALE)
	assert_true(zone.covers(Vector2i(2, 0)), "reach 2 from the origin")
	assert_false(zone.covers(Vector2i(3, 0)))

func test_it_is_shared_rather_than_copied() -> void:
	var projection := DomainProjection.new()
	assert_eq(projection.for_placement(), projection, "it holds only authored data")

func test_it_holds_no_offering() -> void:
	assert_false(DomainProjection.new().can_hold_offering())
```

- [ ] **Step 2: Run `bash scripts/import.sh`, then the test, to verify it fails**

- [ ] **Step 3: Implement `realm/domain_projection.gd` and `realm/influence_reading.gd`**

`class_name DomainProjection extends ZoneSource` with
`@export var domain: Domain.Kind = Domain.Kind.FOREST` and `@export var reach: int = 1`
("1 is the baseline" — carry the comment over from `Furniture.zone_radius`). It overrides only
`zone_over`, returning `InfluenceZone.project(domain, hexes, reach)`. The field is named `reach`
rather than `zone_radius` to match the vocabulary [#127](https://github.com/snackpackgames/cosmicparade/issues/127)
settled, and so the vessel's identical quantity is not spelled two ways.

`class_name InfluenceReading extends GameData` carries **no members on purpose** — its presence in
a piece's slot *is* the capability, per
[#128](https://github.com/snackpackgames/cosmicparade/issues/128). Say so in the doc comment, the
way `Altar` already explains adding no members.

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash scripts/test.sh realm/test_domain_projection.gd`

- [ ] **Step 5: Lint and commit**

```bash
bash scripts/lint.sh
git add realm/domain_projection.gd realm/domain_projection.gd.uid realm/influence_reading.gd realm/influence_reading.gd.uid test/unit/realm/test_domain_projection.gd test/unit/realm/test_domain_projection.gd.uid
git commit -m "feat: add the domain projection and influence reading components"
```

### Task 1.3: `BoardPiece`'s two role slots

- [ ] **Step 1: Write the failing test** in `test/unit/realm/test_board_piece.gd`

```gdscript
func test_a_piece_with_no_slots_filled_projects_nothing_and_reads_nothing() -> void:
	var piece := BoardPiece.new()
	assert_null(piece.zone_source)
	assert_false(piece.reads_influence())

func test_a_piece_reads_influence_when_it_carries_a_reading() -> void:
	var piece := BoardPiece.new()
	piece.reading = InfluenceReading.new()
	assert_true(piece.reads_influence())
```

- [ ] **Step 2: Run the test to verify it fails**

Expected: FAIL — `reads_influence` not defined.

- [ ] **Step 3: Add the slots to `realm/board_piece.gd` and delete `zone_for`**

Add `@export var zone_source: ZoneSource` and `@export var reading: InfluenceReading`, each
documented as **at most one per role** ([#135](https://github.com/snackpackgames/cosmicparade/issues/135)),
and `func reads_influence() -> bool` returning `reading != null`.

**Delete `BoardPiece.zone_for()`** — the slot answers now. Move its `null`-not-an-empty-zone
reasoning ([#37](https://github.com/snackpackgames/cosmicparade/issues/37)) onto `zone_source`'s
doc comment so it is not lost.

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_board_piece.gd`

- [ ] **Step 5: Lint and commit**

### Task 1.4: `BoardPlacement.zone()` reads the slot; furniture and the Altar are re-authored

This is the task that carries **Review Focus 5**.

- [ ] **Step 1: Write the failing tests** in `test/unit/realm/test_board_placement.gd`

```gdscript
func test_a_placement_projects_what_its_pieces_zone_source_projects() -> void:
	var projection := DomainProjection.new()
	projection.domain = Domain.Kind.WETLAND
	projection.reach = 1
	var piece := BoardPiece.new()
	piece.zone_source = projection
	var placement := BoardPlacement.new(piece, 0, [Vector2i.ZERO] as Array[Vector2i])
	assert_eq(placement.zone().domain, Domain.Kind.WETLAND)

# Review Focus 5: null, never an empty zone — the depth tally counts zones.
func test_a_placement_whose_piece_has_no_zone_source_projects_null() -> void:
	var placement := BoardPlacement.new(
		BoardPiece.new(), 0, [Vector2i.ZERO] as Array[Vector2i]
	)
	assert_null(placement.zone(), "an empty zone would be miscounted as coverage")
```

- [ ] **Step 2: Run the tests to verify they fail**

- [ ] **Step 3: Rewrite `BoardPlacement.zone()` and `PlacementRules`' two reads of `zone_for`**

`BoardPlacement.zone()` resolves `piece.zone_source` and returns `null` when it is absent,
otherwise `zone_over(hexes)`. One slot, no branch on what kind of thing it is.

In `realm/placement_rules.gd`, replace the two calls to `piece.zone_for(...)` — in `zone_for()`
(line 42) and `_context_for()` (line 93) — with the same resolution of `piece.zone_source`. Both
still take `piece: BoardPiece` in this phase; Phase 5 changes their signatures. **Behaviour is
identical**: a `Shrine` has no `zone_source` yet, so it contributes `null` exactly as its inherited
`zone_for` did.

- [ ] **Step 4: Delete the moved fields and re-author the data**

Delete `Furniture.domain`, `Furniture.zone_radius` and `Furniture.zone_for()`. `Furniture` now adds
no members; keep the class and rewrite its doc comment to say what it is rather than what it
carries. In `realm/altar.gd`, keep the class and update the comment: it projects nothing because it
authors no `zone_source`, and it reads influence because it authors an `InfluenceReading`.

Re-author each `.tres` to carry a `DomainProjection` sub-resource in `zone_source`, preserving the
exact values: `mushroom_stool` Forest reach 1, `fern_bench` Forest reach 1, `standing_stone`
domain 3 reach 2. `altar.tres` gains an `InfluenceReading` sub-resource in `reading` and no
`zone_source`. **Do not change any authored criterion.**

- [ ] **Step 5: Run the full suite to verify nothing else moved**

Run: `bash scripts/import.sh && bash scripts/test.sh`
Expected: PASS, with only the test files this phase names having changed.

- [ ] **Step 6: Lint and commit**

```bash
bash scripts/lint.sh
git commit -am "refactor: furniture and the Altar answer through components"
```

---

## Phase 2 — The offering vessel, and one placement class

**Blocked by Phase 1** — consumes `ZoneSource` and `BoardPiece.zone_source`, and modifies
`realm/board_placement.gd` and `realm/board_piece.gd` again.

**Files:**
- Create: `realm/offering_vessel.gd`, `test/unit/realm/test_offering_vessel.gd`
- Delete: `realm/shrine_placement.gd` (+ `.uid`), `test/unit/realm/test_shrine_placement.gd` (+ `.uid`)
- Modify: `realm/shrine.gd`, `realm/board_placement.gd`, `realm/realm_state.gd`, `realm/realm.gd`
- Modify: `data/realm/shrine/plain_shrine.tres`
- Test: `test/unit/realm/test_realm_state.gd`, `test/unit/realm/test_realm.gd`,
  `test/unit/realm/test_swell.gd`, `test/unit/realm/test_altar_reading.gd`,
  `test/unit/realm/test_debug_readout.gd`, `test/unit/realm/test_carried_piece.gd`

**Interfaces:**
- Consumes: Phase 1's `ZoneSource` and its six defaults, `BoardPiece.zone_source`.
- Produces: `OfferingVessel` with `@export reach` and runtime `offering`;
  `BoardPlacement.can_hold_offering() -> bool`, `BoardPlacement.holds_offering() -> bool`,
  `BoardPlacement.offer(Fruit) -> void`, `BoardPlacement.empty_vessel() -> void`;
  `RealmState.vessel_placements() -> Array[BoardPlacement]`.

### Task 2.1: `OfferingVessel`, and the copy that keeps two shrines apart

This is the task that carries **Review Focus 1**, the one uncovered failure that would silently
make two shrines one.

- [ ] **Step 1: Write the failing tests** `test/unit/realm/test_offering_vessel.gd`

```gdscript
func test_an_empty_vessel_projects_nothing() -> void:
	var vessel := OfferingVessel.new()
	assert_null(vessel.zone_over([Vector2i.ZERO] as Array[Vector2i]))

func test_a_fed_vessel_projects_its_offerings_domain_at_its_own_reach() -> void:
	var vessel := OfferingVessel.new()
	vessel.reach = 2
	vessel.accept_offering(_fruit(Domain.Kind.FLAME))
	var zone := vessel.zone_over([Vector2i.ZERO] as Array[Vector2i])
	assert_eq(zone.domain, Domain.Kind.FLAME, "the fruit supplies only the domain")
	assert_true(zone.covers(Vector2i(2, 0)), "the reach is the vessel's")

func test_it_answers_yes_to_holding_an_offering_only_once_fed() -> void:
	var vessel := OfferingVessel.new()
	assert_true(vessel.can_hold_offering(), "it is a vessel whether or not it is fed")
	assert_false(vessel.holds_offering())
	vessel.accept_offering(_fruit(Domain.Kind.FOREST))
	assert_true(vessel.holds_offering())
	vessel.empty_vessel()
	assert_false(vessel.holds_offering())

# Review Focus 1: a per-copy component must not be shared.
func test_two_placement_copies_of_one_authored_vessel_do_not_share_contents() -> void:
	var authored := OfferingVessel.new()
	authored.reach = 2
	var first: ZoneSource = authored.for_placement()
	var second: ZoneSource = authored.for_placement()
	assert_ne(first, second, "each placeable gets its own vessel")
	first.accept_offering(_fruit(Domain.Kind.FOREST))
	assert_false(second.holds_offering(), "feeding one must not feed the other")
	assert_false(authored.holds_offering(), "nor the authored resource")
	assert_eq(second.reach, 2, "the copy keeps its authored reach")
```

- [ ] **Step 2: Run `bash scripts/import.sh`, then the tests, to verify they fail**

- [ ] **Step 3: Implement `realm/offering_vessel.gd`**

`class_name OfferingVessel extends ZoneSource`, with `@export var reach: int = 2` and
`var offering: Fruit` — exported and runtime respectively, because the reach is authored and the
contents are not. Overrides `zone_over` (null when empty, else
`InfluenceZone.project(offering.domain, hexes, reach)`), `can_hold_offering` (`true`),
`holds_offering` (`offering != null`), `accept_offering`, `empty_vessel`, and `for_placement`,
which returns a **new `OfferingVessel` carrying this one's `reach` and no offering**.

Document that `for_placement` is the one override that makes the component per-copy, and why the
component rather than the caller decides
([#135](https://github.com/snackpackgames/cosmicparade/issues/135)).

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash scripts/test.sh realm/test_offering_vessel.gd`

- [ ] **Step 5: Lint and commit**

### Task 2.2: `BoardPlacement` holds its per-copy components

- [ ] **Step 1: Write the failing tests** in `test/unit/realm/test_board_placement.gd`

```gdscript
func test_a_placement_built_from_a_vessel_piece_gets_its_own_vessel() -> void:
	var piece := _shrine_piece()        # authors an OfferingVessel with reach 2
	var first := BoardPlacement.new(piece, 0, [Vector2i.ZERO] as Array[Vector2i])
	var second := BoardPlacement.new(piece, 0, [Vector2i(2, 0)] as Array[Vector2i])
	first.offer(_fruit(Domain.Kind.FOREST))
	assert_true(first.holds_offering())
	assert_false(second.holds_offering(), "one authored piece, two vessels")

func test_relocating_carries_the_vessel_and_its_contents() -> void:
	var placement := BoardPlacement.new(
		_shrine_piece(), 0, [Vector2i.ZERO] as Array[Vector2i]
	)
	placement.offer(_fruit(Domain.Kind.WETLAND))
	var moved := placement.relocated(0, [Vector2i(1, 0)] as Array[Vector2i])
	assert_true(moved.holds_offering(), "rearranging is free (adr/0009)")
	assert_eq(moved.zone().domain, Domain.Kind.WETLAND)

func test_a_placement_whose_piece_has_no_zone_source_holds_no_vessel() -> void:
	var placement := BoardPlacement.new(
		BoardPiece.new(), 0, [Vector2i.ZERO] as Array[Vector2i]
	)
	assert_false(placement.can_hold_offering())
	assert_false(placement.holds_offering())
```

- [ ] **Step 2: Run the tests to verify they fail**

- [ ] **Step 3: Give `BoardPlacement` its own zone source and four forwarding questions**

`_init` resolves the placeable's own source once: `null` when the piece authors none, else
`piece.zone_source.for_placement()`. Store it in a private field and have `zone()` read **that**
rather than the piece's, so a fed vessel answers for this placeable alone.

Add `can_hold_offering()`, `holds_offering()`, `offer(fruit: Fruit)` and `empty_vessel()`, each
forwarding to the source and answering `false`/doing nothing when there is none. These are the
polymorphic replacements for `ShrinePlacement.offering`; **no cast and no `is` check appears in any
of them**.

`relocated(new_orientation, new_hexes)` must hand the **same source object** to the new placement
rather than letting `_init` build a second copy — otherwise a relocated shrine arrives empty. This
is the line that replaces `ShrinePlacement.relocated()`'s `moved.offering = offering`.

- [ ] **Step 4: Run the tests to verify they pass**

- [ ] **Step 5: Lint and commit**

### Task 2.3: Delete `ShrinePlacement` and make its readers ask questions

- [ ] **Step 1: Re-author the shrine and delete the subclass**

`plain_shrine.tres` gains an `OfferingVessel` sub-resource in `zone_source` with `reach = 2`.
Delete `Shrine.ZONE_RADIUS` — the reach is the vessel's
([#127](https://github.com/snackpackgames/cosmicparade/issues/127),
[#135](https://github.com/snackpackgames/cosmicparade/issues/135)) — and keep the `Shrine` class
with an updated comment. Delete `realm/shrine_placement.gd`, its `.uid`,
`test/unit/realm/test_shrine_placement.gd` and its `.uid`.

- [ ] **Step 2: Replace the type filter with the vessel question in `realm/realm_state.gd`**

Rename `shrine_placements()` to `vessel_placements() -> Array[BoardPlacement]` and select on
`placement.can_hold_offering()` instead of `placement is ShrinePlacement`. Update its two callers,
`shrine_zones()` and `shrines_in_stock()`. `shrine_zones()` keeps filtering `null` zones, which is
how an empty vessel stays out of the Altar's reading
([#79](https://github.com/snackpackgames/cosmicparade/issues/79)).

- [ ] **Step 3: Replace the two casts in `realm/realm.gd`**

`empty_vessel_under_cursor()` (line 189) drops `as ShrinePlacement` — it takes the occupant, and
guards on `placement == null or not placement.holds_offering()`, then calls
`placement.empty_vessel()`. `_carried_shrine_zone()` (line 408) drops both casts: it guards on
`carried.origin == null or not carried.origin.can_hold_offering()` and relocates as before. This
function is **deleted entirely in Phase 4**; this step only keeps it compiling.

- [ ] **Step 4: Migrate every test construction site**

Replace each `ShrinePlacement.new(piece, o, hexes)` plus `placement.offering = fruit` with
`BoardPlacement.new(piece, o, hexes)` plus `placement.offer(fruit)`, across
`test_realm_state.gd`, `test_realm.gd`, `test_swell.gd`, `test_altar_reading.gd`,
`test_debug_readout.gd` and `test_carried_piece.gd`. The helper functions in each
(`_place_shrine`, `_fed_shrine`) are the single point of change for most of them — change their
return type to `BoardPlacement`. **Assertions do not change.**

- [ ] **Step 5: Run the full suite**

Run: `bash scripts/import.sh && bash scripts/test.sh`
Expected: PASS. If any assertion needs weakening to get there, stop — that is a behaviour change
and this plan forbids it.

- [ ] **Step 6: Lint and commit**

---

## Phase 3 — The Altar's footprint, derived

**Blocked by Phase 2** — modifies `realm/realm_state.gd`, `realm/realm.gd`,
`test/unit/realm/test_realm_state.gd` and `test/unit/realm/test_realm.gd`, all of which Phase 2
also modifies. Consumes `BoardPiece.reads_influence()` from Phase 1.

**Files:**
- Modify: `realm/realm_state.gd`, `realm/realm.gd`
- Test: `test/unit/realm/test_realm_state.gd`, `test/unit/realm/test_realm.gd`

**Interfaces:**
- Consumes: `BoardPiece.reads_influence()` (Task 1.3).
- Produces: `RealmState.altar_hexes() -> Array[Vector2i]`. `RealmState.altar_placement` and
  `place_altar`'s return value are both gone.

### Task 3.1: `altar_hexes()` replaces the stored index

This task carries **Review Focus 3**.

- [ ] **Step 1: Write the failing tests** in `test/unit/realm/test_realm_state.gd`

```gdscript
func test_the_altars_hexes_are_its_footprint_once_it_stands() -> void:
	var state := _state()
	state.place_altar(_altar())
	assert_eq(state.altar_hexes().size(), 3, "a triangle-three")
	assert_true(state.altar_hexes().has(Vector2i.ZERO))

func test_the_altars_hexes_follow_it_when_it_is_relocated() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/102 -- the stored field went stale
	# here; a derived accessor holds no answer to go stale.
	var state := _state()
	state.place_altar(_altar())
	state.remove(state.placements[0])
	var moved := Footprint.occupied(
		Footprint.Shape.TRIANGLE, 0, Vector2i(-2, 0), Vector2i.ZERO
	)
	state.place(BoardPlacement.new(_altar(), 0, moved))
	assert_eq(state.altar_hexes(), moved)

# Review Focus 3: no Altar stands, and both readers must still answer.
func test_a_realm_with_no_altar_reports_no_hexes_and_still_answers() -> void:
	var state := _state()
	assert_eq(state.altar_hexes(), [] as Array[Vector2i])
	assert_false(state.altar_straddles_wing(0), "iterating nothing is aboard nowhere")
	assert_true(state.altar_reading().is_empty(), "nothing reaches an Altar that is absent")
```

`AltarReading.is_empty()` already exists (`realm/altar_reading.gd:33`) — use it rather than adding
a method.

- [ ] **Step 2: Run the tests to verify they fail**

- [ ] **Step 3: Add the accessor and delete the field**

`altar_hexes() -> Array[Vector2i]` walks `placements`, returns the first whose
`piece.reads_influence()` is true, and `[]` otherwise. Document that it **reports and does not
assert** — "every realm has one Altar" holds by the absence of an Altar stock entry, not by a
guard here ([#128](https://github.com/snackpackgames/cosmicparade/issues/128)).

Delete `var altar_placement`, the `if placement.piece is Altar` branch in `place()`, the
`if altar_placement == placement` branch in `remove()`, and `place_altar`'s `-> BoardPlacement`
return type and its `return` — the value is **dead today**, discarded by `realm.gd:69` and read by
no test.

- [ ] **Step 4: Simplify the three readers**

`altar_reading()` loses its null-check preamble and passes `altar_hexes()` straight to
`AltarReading.of`. `altar_straddles_wing()` loses the `altar_placement == null` half of its guard
— iterating `[]` leaves `aboard` and `ashore` both false — but **its `wing_index` bounds check must
stay**, because that one guards the array access below it. In `realm/realm.gd`,
`_reading_for_readout()` takes `state.altar_hexes()` directly instead of reaching for
`.hexes` behind a null check.

In `test_realm.gd`, `_bare_realm()` and the three `realm.state.altar_placement.piece` reads need a
new route to the standing Altar; take it from `realm.state.placements` or from the scene's authored
`ALTAR`, whichever reads more plainly at each site.

- [ ] **Step 5: Run the full suite, lint, and commit**

---

## Phase 4 — The carried placeable

**Blocked by Phase 3** — modifies `realm/realm.gd` and `test/unit/realm/test_realm.gd`, which
Phase 3 also modifies. Consumes Phase 2's `BoardPlacement`.

**Files:**
- Modify: `realm/carried_piece.gd`, `realm/realm.gd`
- Test: `test/unit/realm/test_carried_piece.gd`, `test/unit/realm/test_carry.gd`,
  `test/unit/realm/test_realm.gd`, `CONTRIBUTING.md` is **not** touched here (Phase 6)

**Interfaces:**
- Consumes: Phase 2's `BoardPlacement` with its own zone source, `relocated`.
- Produces: `CarriedPiece.new(placeable: BoardPlacement, grabbed: Vector2i)` — two fields.
  `CarriedPiece.origin` is gone.

### Task 4.1: `CarriedPiece` holds an unplaced placeable

This task carries **Review Focus 4**.

- [ ] **Step 1: Write the failing tests** in `test/unit/realm/test_carried_piece.gd`

```gdscript
# Review Focus 4: "unplaced" is derived from having no hexes, and from nothing else.
func test_a_placeable_from_inventory_has_no_hexes_and_no_orientation_of_its_own() -> void:
	var carried := CarriedPiece.new(_unplaced(_stool()), Vector2i.ZERO)
	assert_eq(carried.own_orientation(), -1, "the carry's sticky orientation applies")
	assert_eq(carried.hexes_at(Vector2i(1, 0), 0), [Vector2i(1, 0)] as Array[Vector2i])

func test_a_placeable_lifted_from_the_board_keeps_its_own_orientation() -> void:
	var placed := BoardPlacement.new(_stool(), 5, [Vector2i.ZERO] as Array[Vector2i])
	assert_eq(CarriedPiece.new(placed, Vector2i.ZERO).own_orientation(), 5)

func test_committing_places_the_very_placeable_that_was_carried() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var placeable := _unplaced(_stool())
	CarriedPiece.new(placeable, Vector2i.ZERO).commit(Vector2i(1, 0), 4, state)
	assert_eq(state.placements.size(), 1)
	assert_eq(state.placements[0], placeable, "one object, not a copy")
	assert_eq(state.occupant_at(Vector2i(1, 0)).orientation, 4)

func test_cancelling_puts_a_lifted_placeable_back_at_its_original_pose() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var placed := BoardPlacement.new(_stool(), 3, [Vector2i.ZERO] as Array[Vector2i])
	state.place(placed)
	var carried := CarriedPiece.new(placed, Vector2i.ZERO)
	carried.detach(state)
	carried.restore(state)
	assert_eq(state.occupant_at(Vector2i.ZERO), placed)
	assert_eq(state.occupant_at(Vector2i.ZERO).orientation, 3)
```

Keep `test_moving_a_fed_shrine_does_not_empty_its_vessel` and
`test_a_shrine_from_stock_lands_as_a_shrine_placement` — rewrite their construction to the new
signature and **keep their assertions**, retargeting the second one at
`state.vessel_placements()`.

- [ ] **Step 2: Run the tests to verify they fail**

- [ ] **Step 3: Rewrite `realm/carried_piece.gd` to two fields**

`_init(placeable: BoardPlacement, grabbed: Vector2i)`. Delete `origin` and the `piece` field;
expose the piece through the placeable where callers need it.

- `own_orientation()` returns `-1` when the placeable has no hexes, else its orientation. This is
  the derived "unplaced" ([#127](https://github.com/snackpackgames/cosmicparade/issues/127)).
- `detach(state)` removes the placeable from `state` only when it is standing there; the placeable
  **keeps its own hexes**, which is what makes `restore` free.
- `restore(state)` places it back, unchanged.
- `commit(target, orientation, state)` computes the hexes and **replaces** the placeable's pose
  rather than mutating a shared object, then places it. One path: the three-way branch on `origin`
  and `piece is Shrine` goes without replacement
  ([#127](https://github.com/snackpackgames/cosmicparade/issues/127),
  [#131](https://github.com/snackpackgames/cosmicparade/issues/131)).
- `hexes_at`, `orientation_count`, `verdict_at`, `zone_at` and `describe_requirements` keep their
  behaviour, reading `piece` through the placeable.

- [ ] **Step 4: Update the two lift sites and delete `_carried_shrine_zone()`**

`lift_from_inventory(piece)` builds an unplaced placeable — no hexes — and carries it.
`lift_under_cursor()` carries the occupant it found, which **is** the placeable, so nothing is
copied. Delete `_carried_shrine_zone()` and route `_reading_for_readout()` to the carried
placeable's own `zone()`, still filtered to vessels so a carried stool never enters the Altar's
reading ([#79](https://github.com/snackpackgames/cosmicparade/issues/79),
[#129](https://github.com/snackpackgames/cosmicparade/issues/129)).

`test_debug_readout.gd`'s `test_the_readout_tracks_a_fed_shrine_while_it_is_carried` and
`test_a_carried_piece_of_furniture_never_enters_the_altars_reading` are the guards on this step.
Both must pass unchanged.

- [ ] **Step 5: Run the full suite, lint, and commit**

---

## Phase 5 — `PlacementRules` judges a placeable

**Blocked by Phase 4** — consumes `CarriedPiece`'s placeable and modifies
`realm/carried_piece.gd` and `realm/realm.gd` again.

**This phase carries the map's one semantic change**
([decided](https://github.com/snackpackgames/cosmicparade/issues/134)): a **fed** vessel now
contributes its own zone to the context its own criteria are judged against. Observably nothing
changes — no authored shrine has `criteria`, so the suite is untouched — but the change is real and
is pinned by Task 5.2 rather than left to be discovered.

**Files:**
- Modify: `realm/placement_rules.gd`, `realm/carried_piece.gd`, `realm/realm.gd`
- Test: `test/unit/realm/test_placement_rules.gd`, `test/unit/realm/test_placement_survey.gd`,
  `test/unit/realm/test_carried_piece.gd`

**Interfaces:**
- Consumes: Phase 4's `CarriedPiece` placeable; Phase 2's `BoardPlacement.zone()`.
- Produces: `PlacementRules.verdict(placeable, orientation, target, grab_offset, state)`,
  `PlacementRules.survey(placeable, grab_offset, state)`. `PlacementRules.zone_for` is gone.

### Task 5.1: `verdict`, `survey` and `_context_for` take the placeable

- [ ] **Step 1: Update `test/unit/realm/test_placement_rules.gd` and `test_placement_survey.gd`**

Change every call to pass an unplaced placeable instead of a piece. **Assertions do not change** —
this step is a signature migration and the existing expectations are the proof it preserved
behaviour.

- [ ] **Step 2: Run the tests to verify they fail**

- [ ] **Step 3: Change the three signatures**

`verdict` and `survey` take the placeable; `_context_for` takes it too and asks **it** for the
candidate zone rather than reaching for `piece.zone_source`. Shape and criteria still resolve
through the placeable's piece. Delete `PlacementRules.zone_for` — projection comes from the
placeable now ([#127](https://github.com/snackpackgames/cosmicparade/issues/127)) — and point
`CarriedPiece.zone_at` at the placeable's `zone()` over the candidate hexes.

Rewrite the class doc comment. It currently claims *"a pure function of a candidate placement and
the committed board"* while taking a piece, and *"what a piece projects is asked of the piece"* —
the first becomes true here and **the second is now false and must go**
([#134](https://github.com/snackpackgames/cosmicparade/issues/134)).

Update `Realm._announce_if_impossible`, `survey`'s only caller, to match.

- [ ] **Step 4: Run the full suite to verify nothing moved, then lint and commit**

### Task 5.2: Pin both halves of the vessel's own contribution

This task carries **Review Focus 2**.

- [ ] **Step 1: Write the failing tests** in `test/unit/realm/test_placement_rules.gd`

```gdscript
# https://github.com/snackpackgames/cosmicparade/issues/41 -- a candidate's own influence is part
# of the board its criteria are judged against. #134 extends that to a derived projection.
func test_a_fed_vessels_own_zone_counts_toward_its_own_criteria() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var placeable := _unplaced_shrine()
	placeable.offer(_fruit(Domain.Kind.FOREST))
	placeable.piece.criteria = [_needs_forest(1)] as Array[PlacementCriterion]
	var verdict := PlacementRules.verdict(placeable, 0, Vector2i.ZERO, Vector2i.ZERO, state)
	assert_true(verdict.allowed, "its own Forest satisfies the requirement")

# https://github.com/snackpackgames/cosmicparade/issues/75 -- an empty vessel must not be judged
# against a zone it does not project.
func test_an_empty_vessel_contributes_nothing_to_its_own_criteria() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var placeable := _unplaced_shrine()
	placeable.piece.criteria = [_needs_forest(1)] as Array[PlacementCriterion]
	var verdict := PlacementRules.verdict(placeable, 0, Vector2i.ZERO, Vector2i.ZERO, state)
	assert_false(verdict.allowed, "nothing in the vessel, nothing projected")
```

`_needs_forest(n)` builds a `DomainInfluenceCriterion` inline with `domain` Forest and
`minimum` n — authored criteria are not touched, and `test_debug_readout.gd:25` is the precedent
for building one in a test. `_unplaced_shrine()` builds a `Shrine` carrying an `OfferingVessel`
and a placeable with no hexes.

- [ ] **Step 2: Run the tests; the empty case should already pass and the fed case should fail**

Record which fails. If the **fed** case already passes before Task 5.1's change is in, the
signature migration did not actually reach `_context_for` — stop and find out why.

- [ ] **Step 3: Confirm no production change is needed**

Both behaviours fall out of Task 5.1. If either test needs a production edit to pass, that edit is
outside what [#134](https://github.com/snackpackgames/cosmicparade/issues/134) decided — stop and
report rather than widening the change.

- [ ] **Step 4: Run the full suite, lint, and commit**

---

## Phase 6 — The rules, written down

**Blocked by nothing.** A documentation phase is not blocked on the code it documents
(`documentation/agents/afk-pipeline.md` → step 4): the ADR records a decision already made, and
the two bullets state rules that hold whether or not the refactor has landed. It shares no file
with any phase above. Take it first if it is the only issue free.

**Files:**
- Create: `documentation/adr/0018-the-board-never-asks-what-is-standing-on-it.md`
- Modify: `CLAUDE.md`, `CONTRIBUTING.md`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing any phase above reads.

### Task 6.1: The ADR and the `CLAUDE.md` bullet

- [ ] **Step 1: Write the ADR**

Follow `documentation/adr/0017-influence-effects-are-matched-greedily.md`'s shape exactly — it is
the pattern [#126](https://github.com/snackpackgames/cosmicparade/issues/126) named. Confirm `0018`
is the next free number before writing.

It records the criterion: **test the type of the object whose behaviour varies; never reach through
to ask a collaborator's type.** It must carry the stopping rule an implementer greps for (a test on
`piece` or `<something>.piece` that governs a placement), the two exclusions (engine-boundary
narrowings are legitimate; `test/unit/` assertions are not governed), and the clarification that
**reading authored data off a piece is not a reach-through** — `piece.criteria`, `piece.zone_source`
and `piece.reading` are field reads, not type tests
([#135](https://github.com/snackpackgames/cosmicparade/issues/135)).

- [ ] **Step 2: Add one bullet to `CLAUDE.md → Conventions`**

One line stating the criterion, linking the ADR. Match the surrounding bullets' voice.

- [ ] **Step 3: Lint and commit**

### Task 6.2: The `CONTRIBUTING.md → Tests` bullet

- [ ] **Step 1: Add one bullet to `CONTRIBUTING.md → Tests`**

> Every board piece type reaches the board through the carry in at least one test: build a `Carry`,
> lift the piece, aim, and call `place()`. A test that constructs a placement and hands it to
> `RealmState` has not exercised the path the player takes.

It **must carry its provenance** — links to
[#96](https://github.com/snackpackgames/cosmicparade/pull/96) and
[#104](https://github.com/snackpackgames/cosmicparade/issues/104)
([decided](https://github.com/snackpackgames/cosmicparade/issues/130)). Without the story the rule
reads as ceremony and gets tidied away by the next person cleaning the file.

- [ ] **Step 2: Commit**

---

## Phase 7 — Every piece type walks the player's path

**Blocked by Phase 5** — the carry-path tests assert against the finished `CarriedPiece`, `Carry`
and `RealmState`, and it modifies `test/unit/realm/test_carry.gd`, which Phase 4 also modifies.

**Files:**
- Test: `test/unit/realm/test_carry.gd`

**Interfaces:**
- Consumes: Phase 4's `CarriedPiece`, Phase 5's `PlacementRules`, Phase 2's
  `RealmState.vessel_placements()`, Phase 3's `RealmState.altar_hexes()`.
- Produces: nothing.

### Task 7.1: One carry-path test per piece type

Furniture already has several in `test_carry.gd`. The shrine's exists but sits one layer too low —
`test_carried_piece.gd` calls `commit()` with no `Carry` and so no verdict gate. The Altar has none
([decided](https://github.com/snackpackgames/cosmicparade/issues/130)).

- [ ] **Step 1: Write the failing tests** in `test/unit/realm/test_carry.gd`

```gdscript
func test_a_shrine_carried_from_stock_lands_as_something_the_board_sees() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/96 -- the defect this pins: a shrine
	# placed through the carry was invisible to the board, and every test passed.
	var state := RealmState.new(RealmGeometry.new())
	var carry := _carry(state)
	carry.lift(CarriedPiece.new(_unplaced_shrine(), Vector2i.ZERO), Vector2i(1, 0))
	assert_true(carry.place())
	assert_eq(state.vessel_placements().size(), 1, "the board sees a vessel standing")
	assert_eq(state.shrines_in_stock(), RealmState.STARTING_SHRINE_CAPACITY - 1)

func test_the_altar_relocated_through_the_carry_is_still_the_altar_the_board_reads() -> void:
	# The Altar's only carry is relocation: there is no Altar stock entry.
	var state := RealmState.new(RealmGeometry.new())
	var altar := BoardPlacement.new(
		_altar_piece(), 0, Footprint.occupied(
			Footprint.Shape.TRIANGLE, 0, Vector2i.ZERO, Vector2i.ZERO
		)
	)
	state.place(altar)
	var carry := _carry(state)
	carry.lift(CarriedPiece.new(altar, Vector2i.ZERO), Vector2i.ZERO)
	carry.aim(Vector2i(-2, 0))
	assert_true(carry.place())
	assert_eq(state.altar_hexes(), altar.hexes, "derived, so it cannot be stale")
	assert_false(state.altar_hexes().is_empty())
```

Pick aim targets that the Altar's authored `LevelFootprintCriterion` actually allows on a bare
board; if a target is refused, `place()` returns `false` and the test is asserting nothing.

- [ ] **Step 2: Run the tests to verify they fail**

- [ ] **Step 3: Make them pass**

No production change is expected — Phases 1 through 5 deliver the behaviour and these tests pin it.
If a production edit is needed, something in an earlier phase is wrong; stop and report rather than
patching here.

- [ ] **Step 4: Lift the shrine's existing test a layer**

Rewrite `test_carried_piece.gd`'s `test_a_shrine_from_stock_lands_as_a_shrine_placement` to go
through `Carry.place()`, or delete it as superseded by Step 1's first test — **it must not remain
as the only shrine carry-path test**, since it skips the verdict gate.

- [ ] **Step 5: Run the full suite, lint, and commit**
