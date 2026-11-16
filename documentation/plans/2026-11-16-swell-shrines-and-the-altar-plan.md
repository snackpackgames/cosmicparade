# Swell, Shrines and the Altar Implementation Plan

> **For agentic workers:** Implement this plan task-by-task, committing after each task as it
> directs. Steps use checkbox (`- [ ]`) syntax for tracking. **Do not create a git worktree** —
> `CLAUDE.md → Claude Code Configuration` forbids them in this repo; work on a topic branch in
> the main working directory. The usual sub-skill for inline execution is
> `superpowers:executing-plans`; `superpowers:subagent-driven-development` is not used here
> because it provisions a worktree.

**Goal:** A Swell costs adherents and grants something specific, shrines stand on the board up to
a capacity the player owns, each projecting the domain of the offering in its vessel, and the
Altar stands somewhere that matters because it reads what those shrines project.

**Architecture:** Three things stand on the board — furniture, shrines, the Altar — and after this
plan they are **one kind of thing**: a `BoardPiece` with a footprint, occupying hexes recorded in
**one** occupancy index, carried by **one** state machine. What a piece *projects* is the only
polymorphism, and it is asked of the piece rather than branched on by the board: furniture
projects its authored domain, a shrine projects whatever is in its vessel, the Altar projects
nothing. Everything else stays derived — the Altar's reading, like elevation and zones before it,
is recomputed on demand and never stored.

**Tech Stack:** Godot 4.7.2-stable, GDScript, GUT 9.7.1.

**Spec:** [Map: what a Swell costs, and where shrines and the Altar
stand](https://github.com/snackpackgames/cosmicparade/issues/73) — nine closed decision tickets
and one prototype, `test/prototypes/78-shrine-influence-reach/`. Every rule below links the ticket
that settled it. **Where this plan says "decided", the linked ticket holds the reasoning: do not
re-derive it, and do not substitute a different answer because it looks better in context.**

This plan builds on
[`2026-11-14-realm-arrangement-puzzle-plan.md`](2026-11-14-realm-arrangement-puzzle-plan.md).
Its Phases 1–4 are merged: `Footprint`, `Furniture`, `FurniturePlacement`, `RealmState`,
`PlacementCriterion` and its five subclasses, `PlacementContext`, `PlacementRules`,
`PlacementVerdict`, `Carried`, `CarriedFurniture`, `Carry`, `HexCursor`, `FurnitureView` and the
live preview in `realm/realm.gd` all exist and are the inputs here.

**Two phases of this plan wait on that plan's Phase 6**, [wings through the carry verb, then the
ADRs and the README](https://github.com/snackpackgames/cosmicparade/issues/70), which delivers
`CarriedWing` and the first correction to `README.md → Scenes → Realm`. Phases 5 and 6 below
consume both and must not reimplement either.

## Global Constraints

- **A shrine is a single hex projecting a radius-2 disc, with no placement criteria at all**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/74)). Single-hex because every
  multi-hex footprint at radius 2 projects 24–29 of 37 hexes, the mush
  [#52](https://github.com/snackpackgames/cosmicparade/issues/52) rejected; criteria-free because
  `README.md` says shrines are "freely placed" and
  [#30](https://github.com/snackpackgames/cosmicparade/issues/30) demanded the criteria system be
  **reused, not populated**.
- **A shrine projects the domain of the offering in its vessel. An empty vessel projects nothing
  at all** ([decided](https://github.com/snackpackgames/cosmicparade/issues/75)) — no domain, no
  zone, nothing for [#37](https://github.com/snackpackgames/cosmicparade/issues/37)'s tally. One
  vessel, one offering, one domain, one zone. The radius stays 2 however full the vessel is,
  because [#55](https://github.com/snackpackgames/cosmicparade/issues/55) lets nothing modify what
  a piece projects.
- **The player owns one shrine per point of shrine capacity and holds un-placed ones as stock**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/74)), placed and stowed through
  the existing inventory path — **no second placement path**, and nothing new in the carry state
  machine.
- **Shrine capacity starts at 2 and rises only on the two ring Swells, to 4, and never again**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/80)).
- **The Altar occupies a triangle-three, carries exactly one criterion — level footprint — and
  projects nothing** ([decided](https://github.com/snackpackgames/cosmicparade/issues/77)). It has
  **no domain field and no zone radius**: the absence is the decision, and nothing may add them
  "for symmetry".
- **The Altar starts at the origin in its default orientation**, covering `(0,0)`, `(1,0)`,
  `(1,-1)` ([decided](https://github.com/snackpackgames/cosmicparade/issues/77)). The origin never
  moves ([#53](https://github.com/snackpackgames/cosmicparade/issues/53)) and the starting board
  is flat, so the level-footprint gate passes trivially at creation.
- **"Every realm must have one" is enforced by an absence, not a check**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/77)). The Altar gets **no stock
  entry**, so a carry can only end in a placement or in cancel-to-origin. Do not add a guard.
- **The Altar reads a per-domain count of the shrine zones covering *any* hex of its footprint,
  counting each shrine once** ([decided](https://github.com/snackpackgames/cosmicparade/issues/79)).
  **Shrines only** — furniture influence is not read. Derived on demand, **never stored**. Its
  range is **0–4**.
- **The balance is a plain `RefCounted` the realm constructs and injects — not a `Resource`, not a
  field on `RealmState`, and not an autoload**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/76)). `CLAUDE.md → Autoloads`
  wants both a scene change to outlive *and* more than one system; today there is neither.
- **Affordability is checked, the geometry is performed, and the balance is debited only if the
  board actually changed** ([decided](https://github.com/snackpackgames/cosmicparade/issues/76)).
  No refunds, and no window in which the balance is wrong.
- **Two refusals, at two moments** ([decided](https://github.com/snackpackgames/cosmicparade/issues/76)).
  Inability to afford is an **unmet price** that gates *entering* a Swell — the action is
  unavailable with its price showing, never a refusal. An illegal wing siting inside a Swell
  **is** [#62](https://github.com/snackpackgames/cosmicparade/issues/62)'s refusal, reusing the
  carry machinery verbatim.
- **Swell has three phases** ([decided](https://github.com/snackpackgames/cosmicparade/issues/80)):
  two **ring** Swells granting board *and* capacity, four **wing** Swells granting board only, and
  past the fourth wing nothing realm-side — so **in M1 the action is simply unavailable after the
  sixth**. The board's permanent maximum is 91 hexes plus four wings.
- **The six prices are 10 / 20 / 40 / 70 / 110 / 160**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/81)), authored in the tier
  table, 410 for the complete ladder.
- **Everything the realm surfaces about these numbers is a debug readout** behind
  `OS.is_debug_build()` ([decided](https://github.com/snackpackgames/cosmicparade/issues/85)),
  beside the existing F8/F9 keys. Player-facing presentation is `area:ui` work and is **not built
  here**.
- Godot **4.7.2-stable**; GDScript indented with **tabs**; `max-line-length: 100` per `.gdlintrc`.
- **Never name a local `set` or `get`.** `gdlint` treats both as grammar keywords and fails to
  *parse* the file, with no rule name to look up, while Godot accepts the code — so GUT goes green
  and the pre-push hook is where it surfaces. Call a hex set `hex_set`.
- Every script declares a `class_name`. After adding one, run `bash scripts/import.sh`.
- **Commit `.uid` sidecars for every new script.** Hand-authored `.tres` in this repo carry none —
  match `data/realm/furniture/*.tres`.
- Tests are GUT, extend `GutTest`, and mirror the source tree under `test/unit/realm/`.

### Test helpers used throughout

GUT gives these tests no shared base class, so each test file declares the helpers it uses. Their
bodies are given here once; do not vary them, because several tasks' expected values depend on the
exact placeholder pieces.

```gdscript
func _fruit(domain: Domain.Kind) -> Fruit:
	var fruit := Fruit.new()
	fruit.fruit_name = "test fruit"
	fruit.domain = domain
	return fruit


func _shrine() -> Shrine:
	var shrine := Shrine.new()
	shrine.piece_name = "test shrine"
	return shrine


func _altar() -> Altar:
	var altar := Altar.new()
	altar.piece_name = "test altar"
	altar.criteria = [LevelFootprintCriterion.new()] as Array[PlacementCriterion]
	return altar


func _piece(domain: Domain.Kind, radius: int) -> Furniture:
	var piece := Furniture.new()
	piece.piece_name = "test piece"
	piece.domain = domain
	piece.shape = Footprint.Shape.SINGLE
	piece.zone_radius = radius
	return piece


func _state() -> RealmState:
	return RealmState.new(RealmGeometry.new())


# Places a fed shrine at `hex` and returns its placement.
func _place_shrine(state: RealmState, hex: Vector2i, domain: Domain.Kind) -> ShrinePlacement:
	var placement := ShrinePlacement.new(_shrine(), 0, [hex] as Array[Vector2i])
	placement.offering = _fruit(domain)
	state.place(placement)
	return placement
```

### What this plan does not decide, and must not invent

- **What an offering buys.** Entity arrivals, how many parades one lasts, consumption and early
  swapping are M4. This plan gives a `Fruit` a domain and a vessel a present-or-absent offering,
  and nothing else — the map moved exactly that much into scope and no more.
- **What Summon and Fire do with the reading.** M3/M4. This plan produces a reading with a stable
  meaning; it does not spend it.
- **A pageant's rewards.** [#81](https://github.com/snackpackgames/cosmicparade/issues/81) records
  the *intent* that the ladder spans roughly 50 pageants — about 8 adherents each — as an anchor
  for M5/M6 to honour or revise deliberately. No code here earns an adherent.
- **Player-facing presentation.** [#85](https://github.com/snackpackgames/cosmicparade/issues/85)
  put every readout behind `OS.is_debug_build()`.
- **An offering vessel's *kind*** (bowl, urn, kylix, cauldron). Ruled out of scope on the map:
  every candidate effect is M4 or is forbidden by #55. **Author no field for it.**
- **Save persistence.** Board, wallet and capacity live in memory for the session.

## Review Focus

Five failure modes the spec implies that no task's happy path exercises. Each has its test written
into the task that owns the code.

1. **A shrine covering two or three of the Altar's hexes counted more than once.** The reading
   counts each *shrine* once, on *any* hex ([#79](https://github.com/snackpackgames/cosmicparade/issues/79)) —
   and 12 board hexes reach all three, so this is the common case, not the corner. *Task 3.3.*
2. **The balance debited when the board did not change.** Three ways in: a ring Swell past radius
   5, a wing siting the geometry refuses, and a carry the player cancels. All three must leave the
   balance untouched ([#76](https://github.com/snackpackgames/cosmicparade/issues/76)). *Tasks 4.3
   and 5.1.*
3. **A shrine lifted from stock when stock is empty.** Capacity is the only thing limiting shrines
   ([#74](https://github.com/snackpackgames/cosmicparade/issues/74)); with all of them placed there
   is nothing to lift, and the lift must be inert rather than conjuring a shrine. *Task 2.4.*
4. **Depth 4 reached by shrines alone.** It must not be: capacity caps at 4 and depth needs five
   same-domain zones, so four fed shrines reach depth 3 and only a fifth same-domain *furniture*
   zone takes it to 4 ([#80](https://github.com/snackpackgames/cosmicparade/issues/80)). *Task 4.3.*
5. **A vessel emptied under a placed piece.** The ground it raised drops immediately
   ([#38](https://github.com/snackpackgames/cosmicparade/issues/38)) and the piece **stays**,
   because criteria are never re-checked ([#55](https://github.com/snackpackgames/cosmicparade/issues/55)).
   *Task 2.3.*

## Phases

| Phase | Delivers | Waits on |
|---|---|---|
| 1 | One board piece, one placement, one index | — |
| 2 | The shrine, its vessel, and shrine capacity | Phase 1 |
| 3 | The Altar, and what it reads | Phase 2 |
| 4 | The wallet, the tier table, and the ring Swells | Phase 3 |
| 5 | Wings bought through Swell, and the lift the Altar refuses | Phase 4, **#70** |
| 6 | The debug readout and the record | Phase 5, **#70** |

---

## Phase 1 — One board piece, one placement, one index

Three things will stand on the board and `RealmState` keeps **one** occupancy index over all of
them, because [#51](https://github.com/snackpackgames/cosmicparade/issues/51)'s
footprints-never-overlap and `README.md`'s shrine-tiles-must-not-collide are **one rule**, not
three. [#74](https://github.com/snackpackgames/cosmicparade/issues/74) made a shrine a *sibling*
of `Furniture` rather than a subclass, and [#77](https://github.com/snackpackgames/cosmicparade/issues/77)
flagged that the three placement types therefore need a common supertype for that index to stay
typed.

This phase adds no gameplay. It ends with the existing suite green and nothing visible changed.

### Task 1.1 — A board piece, and what it projects

**Files:**
- Create: `realm/board_piece.gd`
- Modify: `realm/furniture.gd`
- Test: `test/unit/realm/test_board_piece.gd`

**Interfaces:**
- Produces: `BoardPiece extends GameData` with `@export var piece_name: String`,
  `@export var shape: Footprint.Shape`, `@export var anchor: Vector2i`,
  `@export var criteria: Array[PlacementCriterion]`, and
  `func zone_for(_hexes: Array[Vector2i]) -> InfluenceZone` returning `null`.
- Produces: `Furniture extends BoardPiece`, keeping `domain` and `zone_radius`, overriding
  `zone_for` as `InfluenceZone.project(domain, hexes, zone_radius)`.

**The base returns `null`, and that is the Altar's whole implementation.** A piece that projects
nothing is not a piece projecting an empty zone — #37's tally must not see an entry for it at all
([decided](https://github.com/snackpackgames/cosmicparade/issues/77)), and a null is the only
return that cannot be miscounted.

Moving `piece_name`, `shape`, `anchor` and `criteria` up to the base leaves `Furniture`'s exported
property *names* unchanged, so the three authored `.tres` in `data/realm/furniture/` load as they
are. Do not re-author them.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_a_bare_board_piece_projects_nothing() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/77 — the Altar projects no
	# domain, no radius, and nothing for #37's tally. Null, not an empty zone.
	var piece := BoardPiece.new()
	assert_null(piece.zone_for([Vector2i.ZERO] as Array[Vector2i]))


func test_furniture_projects_its_authored_domain_at_its_authored_radius() -> void:
	var piece := _piece(Domain.Kind.FLAME, 2)
	var zone := piece.zone_for([Vector2i.ZERO] as Array[Vector2i])
	assert_eq(zone.domain, Domain.Kind.FLAME)
	assert_eq(zone.hex_count(), 19)


func test_furniture_is_a_board_piece() -> void:
	assert_true(_piece(Domain.Kind.FOREST, 1) is BoardPiece)
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `bash scripts/test.sh realm/test_board_piece.gd`
Expected: FAIL — `BoardPiece` is not a known class.

- [ ] **Step 3: Add `realm/board_piece.gd` and reparent `Furniture`**

Move the four shared `@export`s to the base. `Furniture` keeps `domain` and `zone_radius` and
overrides `zone_for`.

- [ ] **Step 4: Rebuild the class cache and run the whole suite**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS, including every pre-existing `Furniture` test unchanged.

- [ ] **Step 5: Commit**

```bash
git add realm/board_piece.gd realm/board_piece.gd.uid realm/furniture.gd \
  test/unit/realm/test_board_piece.gd test/unit/realm/test_board_piece.gd.uid
git commit -m "refactor: give furniture a board piece base that projects nothing"
```

### Task 1.2 — One placement type, one occupancy index

**Files:**
- Rename: `realm/furniture_placement.gd` → `realm/board_placement.gd`
- Modify: `realm/realm_state.gd`, `realm/placement_context.gd`, `realm/furniture_view.gd`,
  `realm/carried_furniture.gd`, `realm/realm.gd`
- Rename: `test/unit/realm/test_furniture_placement.gd` → `test/unit/realm/test_board_placement.gd`

**Interfaces:**
- Consumes: `BoardPiece.zone_for` (Task 1.1).
- Produces: `BoardPlacement extends RefCounted` with `piece: BoardPiece`, `orientation: int`,
  `hexes: Array[Vector2i]`, and `func zone() -> InfluenceZone` returning `piece.zone_for(hexes)`.
- Produces: `RealmState.placements: Array[BoardPlacement]`,
  `RealmState.occupant_at(hex) -> BoardPlacement`, `place`, `remove`, `placements_within`,
  `placements_touching` all over `BoardPlacement`.

`zone()` **delegates to the piece** rather than branching, so the board never asks what kind of
thing is standing on it. `Realm`'s `piece_returned` signal is retyped to carry a `BoardPiece` in
the same pass, since it will shortly carry shrines as well as furniture. `RealmState.zones()` **skips a null**, which is what
[#75](https://github.com/snackpackgames/cosmicparade/issues/75) requires of an empty vessel — "do
not assume every placed thing contributes one".

A rename rather than a subclass: with `zone()` delegating, a `FurniturePlacement` would add
nothing, and the name would be wrong on two of its three users.

**One consequence is free and is meant to be.** `FurnitureView.show_placements` draws a prism per
occupied hex of every placement it is given, so once it is retyped, shrines and the Altar appear
on the board without a line of drawing code. They are placeholder prisms like everything else —
how a shrine or the Altar *reads* is art direction and out of scope on the map.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_a_placement_asks_its_piece_what_to_project() -> void:
	var placement := BoardPlacement.new(_piece(Domain.Kind.STONE, 1), 0, [Vector2i.ZERO] as Array[Vector2i])
	assert_eq(placement.zone().domain, Domain.Kind.STONE)


func test_a_placement_of_a_piece_that_projects_nothing_has_no_zone() -> void:
	var placement := BoardPlacement.new(BoardPiece.new(), 0, [Vector2i.ZERO] as Array[Vector2i])
	assert_null(placement.zone())


func test_the_state_omits_a_placement_that_projects_nothing() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/75 — a null zone is absent
	# from the tally, not a zero entry in it.
	var state := _state()
	state.place(BoardPlacement.new(BoardPiece.new(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	state.place(BoardPlacement.new(_piece(Domain.Kind.GALE, 1), 0, [Vector2i(2, 0)] as Array[Vector2i]))
	assert_eq(state.zones().size(), 1)
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `bash scripts/test.sh realm/test_board_placement.gd`
Expected: FAIL — `BoardPlacement` is not a known class.

- [ ] **Step 3: Rename the class and retype its users**

`git mv` both files, rename the `class_name`, change the constructor's first parameter to
`BoardPiece`, delegate `zone()`, and retype every annotation in the five modified files. Add the
null skip in `RealmState.zones()`.

- [ ] **Step 4: Rebuild and run the whole suite**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS. `grep -rn "FurniturePlacement" realm/ test/` returns nothing.

- [ ] **Step 5: Commit**

```bash
git add -A realm/ test/unit/realm/
git commit -m "refactor: one placement type over one occupancy index"
```

### Task 1.3 — The rules and the carry take any board piece

**Files:**
- Modify: `realm/placement_rules.gd`
- Rename: `realm/carried_furniture.gd` → `realm/carried_piece.gd`
- Rename: `test/unit/realm/test_carried_furniture.gd` → `test/unit/realm/test_carried_piece.gd`
- Modify: `realm/realm.gd`

**Interfaces:**
- Produces: `PlacementRules.verdict(piece: BoardPiece, orientation, target, grab_offset, state)`
  and `PlacementRules.zone_for(piece: BoardPiece, orientation, target, grab_offset)`.
- Produces: `CarriedPiece extends Carried`, constructed from a `BoardPiece`, a grab offset and an
  optional `BoardPlacement` origin.

`PlacementRules.verdict` currently builds the candidate zone itself from `piece.domain` and
`piece.zone_radius`. It must instead call `piece.zone_for(occupied)` and **append only a
non-null**, or a shrine with an empty vessel would be judged against a zone it does not project.

`zone_for` returns `null` for a piece that projects nothing; `Carry` already tolerates that, since
[#70](https://github.com/snackpackgames/cosmicparade/issues/70) specifies `CarriedWing.zone_at()`
as null for the same reason.

**One carried type for all three** ([decided](https://github.com/snackpackgames/cosmicparade/issues/74),
[again](https://github.com/snackpackgames/cosmicparade/issues/77)) — "no second placement path and
nothing new in the carry state machine".

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_a_piece_that_projects_nothing_is_judged_without_a_zone() -> void:
	var state := _state()
	var verdict := PlacementRules.verdict(BoardPiece.new(), 0, Vector2i.ZERO, Vector2i.ZERO, state)
	assert_true(verdict.allowed)


func test_carrying_a_piece_that_projects_nothing_aims_a_null_zone() -> void:
	var carried := CarriedPiece.new(BoardPiece.new(), Vector2i.ZERO, null)
	assert_null(carried.zone_at(Vector2i.ZERO, 0))
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `bash scripts/test.sh realm/test_carried_piece.gd`
Expected: FAIL — `CarriedPiece` is not a known class.

- [ ] **Step 3: Retype the rules and rename the carried type**

- [ ] **Step 4: Rebuild and run the whole suite**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS. `grep -rn "CarriedFurniture" realm/ test/` returns nothing.

- [ ] **Step 5: Commit**

```bash
git add -A realm/ test/unit/realm/
git commit -m "refactor: judge and carry any board piece, not only furniture"
```

---

## Phase 2 — The shrine, its vessel, and shrine capacity

### Task 2.1 — A placeholder fruit

**Files:**
- Create: `realm/fruit.gd`
- Create: `data/realm/fruit/moss_plum.tres`, `data/realm/fruit/ember_fig.tres`
- Test: `test/unit/realm/test_fruit.gd`

**Interfaces:**
- Produces: `Fruit extends GameData` with `@export var fruit_name: String` and
  `@export var domain: Domain.Kind`.

Fruit does not exist in this project yet and growing it is M2/M4. The map moved exactly one thing
into scope — that **an offering carries exactly one domain**, and that its presence gates the
shrine's zone ([#75](https://github.com/snackpackgames/cosmicparade/issues/75)) — so this resource
carries exactly that and a name, standing in the way `data/realm/furniture/*.tres` stands in for
authored pieces.

Two instances, so tests can tell two domains apart: **Moss Plum** (Forest) and **Ember Fig**
(Flame). Hand-authored `.tres` carry no uid attribute and no `.uid` sidecar — match
`data/realm/furniture/`.

- [ ] **Step 1: Write the failing test**

```gdscript
func test_the_authored_fruits_carry_one_domain_each() -> void:
	var plum: Fruit = load("res://data/realm/fruit/moss_plum.tres")
	var fig: Fruit = load("res://data/realm/fruit/ember_fig.tres")
	assert_eq(plum.domain, Domain.Kind.FOREST)
	assert_eq(fig.domain, Domain.Kind.FLAME)
	assert_true(plum is GameData)
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `bash scripts/test.sh realm/test_fruit.gd`
Expected: FAIL — `Fruit` is not a known class.

- [ ] **Step 3: Add `realm/fruit.gd` and the two resources**

- [ ] **Step 4: Rebuild and run**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_fruit.gd && bash scripts/lint.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add realm/fruit.gd realm/fruit.gd.uid data/realm/fruit/ \
  test/unit/realm/test_fruit.gd test/unit/realm/test_fruit.gd.uid
git commit -m "feat: add a placeholder fruit carrying one domain"
```

### Task 2.2 — The shrine and the vessel it holds

**Files:**
- Create: `realm/shrine.gd`, `realm/shrine_placement.gd`
- Create: `data/realm/shrine/plain_shrine.tres`
- Test: `test/unit/realm/test_shrine.gd`, `test/unit/realm/test_shrine_placement.gd`

**Interfaces:**
- Consumes: `BoardPiece` (Task 1.1), `BoardPlacement` (Task 1.2), `Fruit` (Task 2.1).
- Produces: `Shrine extends BoardPiece` with `const ZONE_RADIUS := 2`.
- Produces: `ShrinePlacement extends BoardPlacement` with `var offering: Fruit`, overriding
  `zone()`.

A shrine is **one hex, a radius-2 disc, and no criteria at all**
([decided](https://github.com/snackpackgames/cosmicparade/issues/74)). The radius is a **`const`,
not an `@export`** — that ticket settled "one value for all shrines", and an exported field would
invite a second. `shape` stays `SINGLE` and `criteria` stays empty in the authored resource:
honouring "freely placed" literally, which is why #30's demand that the criteria system be reused
is met by *reuse being possible*, not by populating it.

**`ShrinePlacement` overrides `zone()` rather than `Shrine` overriding `zone_for()`**, because the
offering is per-placement runtime state and a `.tres` is shared by every holder of its path. The
split is the honest one: a piece knows what it projects *as a type*, a placement knows what it is
projecting *right now*.

An empty vessel returns **null** — no domain, no zone, nothing for the tally
([decided](https://github.com/snackpackgames/cosmicparade/issues/75)). The radius is 2 however
full the vessel is, since #55 lets nothing modify what a piece projects.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_a_shrine_is_one_hex_with_no_criteria() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/74 — single-hex because every
	# multi-hex footprint at radius 2 projects 24-29 of 37 hexes; criteria-free because
	# the README says shrines are freely placed.
	var shrine: Shrine = load("res://data/realm/shrine/plain_shrine.tres")
	assert_eq(shrine.shape, Footprint.Shape.SINGLE)
	assert_eq(shrine.criteria.size(), 0)
	assert_eq(Shrine.ZONE_RADIUS, 2)


func test_an_empty_vessel_projects_nothing_at_all() -> void:
	var placement := ShrinePlacement.new(_shrine(), 0, [Vector2i.ZERO] as Array[Vector2i])
	assert_null(placement.zone())


func test_a_fed_vessel_projects_the_offerings_domain_at_radius_two() -> void:
	var placement := ShrinePlacement.new(_shrine(), 0, [Vector2i.ZERO] as Array[Vector2i])
	placement.offering = _fruit(Domain.Kind.WETLAND)
	assert_eq(placement.zone().domain, Domain.Kind.WETLAND)
	assert_eq(placement.zone().hex_count(), 19)


func test_the_radius_does_not_change_with_what_is_offered() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/55 — nothing modifies what a
	# piece projects.
	var placement := ShrinePlacement.new(_shrine(), 0, [Vector2i.ZERO] as Array[Vector2i])
	for domain: Domain.Kind in [Domain.Kind.FOREST, Domain.Kind.FLAME, Domain.Kind.GALE]:
		placement.offering = _fruit(domain)
		assert_eq(placement.zone().hex_count(), 19)
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `bash scripts/test.sh realm/test_shrine.gd`
Expected: FAIL — `Shrine` is not a known class.

- [ ] **Step 3: Add the two scripts and the authored shrine**

- [ ] **Step 4: Rebuild and run**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add realm/shrine.gd realm/shrine.gd.uid realm/shrine_placement.gd \
  realm/shrine_placement.gd.uid data/realm/shrine/ test/unit/realm/test_shrine*.gd \
  test/unit/realm/test_shrine*.gd.uid
git commit -m "feat: a shrine projects the domain of the offering in its vessel"
```

### Task 2.3 — Shrine zones, and the ground that drops when a vessel empties

**Files:**
- Modify: `realm/realm_state.gd`
- Test: `test/unit/realm/test_realm_state.gd`

**Interfaces:**
- Produces: `RealmState.shrine_zones() -> Array[InfluenceZone]` — the zones of
  `ShrinePlacement`s only, nulls skipped.
- Produces: `RealmState.shrine_placements() -> Array[ShrinePlacement]`.

`zones()` keeps returning **everything**: [#30](https://github.com/snackpackgames/cosmicparade/issues/30)
has fixtures raising ground like anything else, so elevation must keep counting shrines.
`shrine_zones()` is the narrower question the Altar asks
([decided](https://github.com/snackpackgames/cosmicparade/issues/79)), and giving `InfluenceZone`
a source field instead was rejected — it would make a derived object carry provenance nothing else
wants.

**Review Focus 5 lands here.** Shrine influence is the only influence in the realm that expires
([#75](https://github.com/snackpackgames/cosmicparade/issues/75)), so emptying a vessel is the one
operation that removes a zone without moving a piece. Removal lowers ground immediately with no
high-water mark ([#38](https://github.com/snackpackgames/cosmicparade/issues/38)) and criteria are
never re-checked ([#55](https://github.com/snackpackgames/cosmicparade/issues/55)) — so the ground
drops and the piece standing on it **stays**.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_shrine_zones_are_only_the_shrines_and_only_the_fed_ones() -> void:
	var state := _state()
	_place_shrine(state, Vector2i(-2, 0), Domain.Kind.FOREST)
	state.place(ShrinePlacement.new(_shrine(), 0, [Vector2i(2, 0)] as Array[Vector2i]))
	state.place(BoardPlacement.new(_piece(Domain.Kind.FOREST, 1), 0, [Vector2i(0, 2)] as Array[Vector2i]))
	assert_eq(state.zones().size(), 2)
	assert_eq(state.shrine_zones().size(), 1)


func test_emptying_a_vessel_drops_the_ground_and_leaves_the_piece_standing() -> void:
	# Review Focus 5. https://github.com/snackpackgames/cosmicparade/issues/38 — removal
	# lowers ground immediately; https://github.com/snackpackgames/cosmicparade/issues/55
	# — criteria are never re-checked, so nothing is displaced.
	var state := _state()
	var shrine := _place_shrine(state, Vector2i(1, 0), Domain.Kind.FOREST)
	state.place(BoardPlacement.new(_piece(Domain.Kind.FOREST, 1), 0, [Vector2i(0, 0)] as Array[Vector2i]))
	assert_eq(Elevation.depth_at(Vector2i.ZERO, state.zones()), 1)

	shrine.offering = null

	assert_eq(Elevation.depth_at(Vector2i.ZERO, state.zones()), 0)
	assert_eq(state.placements.size(), 2)
	assert_not_null(state.occupant_at(Vector2i.ZERO))
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `bash scripts/test.sh realm/test_realm_state.gd`
Expected: FAIL — `shrine_zones` is not a method.

- [ ] **Step 3: Add the two accessors**

- [ ] **Step 4: Run the whole suite**

Run: `bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add realm/realm_state.gd test/unit/realm/test_realm_state.gd
git commit -m "feat: ask the board for shrine zones alone"
```

### Task 2.4 — Shrine capacity, and the stock the player holds

**Files:**
- Modify: `realm/realm_state.gd`, `realm/realm.gd`
- Test: `test/unit/realm/test_realm_state.gd`, `test/unit/realm/test_realm.gd`

**Interfaces:**
- Produces: `RealmState.shrine_capacity: int` starting at `RealmState.STARTING_SHRINE_CAPACITY`
  (**2**), and `RealmState.shrines_in_stock() -> int` = capacity minus placed shrines.
- Produces: `Realm.lift_from_stock()`, which lifts a shrine through the existing inventory path
  and is **inert** when stock is empty.

Capacity lives on `RealmState` and the adherent balance does not
([#76](https://github.com/snackpackgames/cosmicparade/issues/76)) — the difference is that
capacity is a property of the realm, while adherents are earned in the parade and spent here.

Stock is **derived, never stored**: the player owns one shrine per point of capacity
([decided](https://github.com/snackpackgames/cosmicparade/issues/74)), so what is in hand is what
is not on the board. There is no inventory object to desynchronise.

**Review Focus 3 lands here.** With every shrine placed there is nothing to lift, and the lift
must do nothing rather than conjure one.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_a_new_realm_holds_two_shrines_in_stock() -> void:
	var state := _state()
	assert_eq(state.shrine_capacity, 2)
	assert_eq(state.shrines_in_stock(), 2)


func test_placing_a_shrine_takes_it_out_of_stock() -> void:
	var state := _state()
	_place_shrine(state, Vector2i(-2, 0), Domain.Kind.FOREST)
	assert_eq(state.shrines_in_stock(), 1)


func test_furniture_does_not_come_out_of_shrine_stock() -> void:
	var state := _state()
	state.place(BoardPlacement.new(_piece(Domain.Kind.FOREST, 1), 0, [Vector2i(0, 2)] as Array[Vector2i]))
	assert_eq(state.shrines_in_stock(), 2)


func test_lifting_from_an_empty_stock_does_nothing() -> void:
	# Review Focus 3. Capacity is the only thing limiting shrines
	# (https://github.com/snackpackgames/cosmicparade/issues/74), so an empty stock must
	# be inert rather than conjuring one.
	var realm: Realm = add_child_autofree(preload("res://realm/realm.tscn").instantiate())
	await wait_frames(1)
	_place_shrine(realm.state, Vector2i(-2, 0), Domain.Kind.FOREST)
	_place_shrine(realm.state, Vector2i(2, 0), Domain.Kind.FOREST)
	assert_eq(realm.state.shrines_in_stock(), 0)

	realm.lift_from_stock()

	assert_false(realm.carry.is_carrying())
	assert_eq(realm.state.placements.size(), 2)
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `bash scripts/test.sh realm/test_realm_state.gd`
Expected: FAIL — `shrine_capacity` is not a property.

- [ ] **Step 3: Add capacity, derived stock, and the guarded lift**

`lift_from_stock` loads the authored shrine and calls the same `Carry.lift` path
`lift_from_inventory` already uses — **no second placement path**
([decided](https://github.com/snackpackgames/cosmicparade/issues/74)).

- [ ] **Step 4: Run the whole suite**

Run: `bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add realm/realm_state.gd realm/realm.gd test/unit/realm/test_realm_state.gd \
  test/unit/realm/test_realm.gd
git commit -m "feat: the realm holds shrines up to its capacity"
```

---

## Phase 3 — The Altar, and what it reads

### Task 3.1 — The Altar as a board piece

**Files:**
- Create: `realm/altar.gd`
- Create: `data/realm/altar/altar.tres`
- Test: `test/unit/realm/test_altar.gd`

**Interfaces:**
- Consumes: `BoardPiece` (Task 1.1), `LevelFootprintCriterion` (merged).
- Produces: `Altar extends BoardPiece`, adding **nothing**.

`Altar` adds no members at all. It occupies a **triangle-three**, carries **one** criterion —
level footprint — and **projects nothing**
([decided](https://github.com/snackpackgames/cosmicparade/issues/77)). It inherits `BoardPiece`'s
null `zone_for`, which is the whole implementation of "projects nothing".

**Do not give it a domain field or a zone radius.** The absence is the decision: `README.md:192`
describes the Altar only as *affected by* shrine influence, `adr/0005` fixes six domains and the
Altar belongs to none, and a zone would both enter #37's tally and let the Altar read its own
contribution.

The level-footprint gate is authored **inline as a typed sub-resource** on `altar.tres`, per
[#55](https://github.com/snackpackgames/cosmicparade/issues/55) — not a shared `.tres`. Follow
`data/realm/furniture/standing_stone.tres`'s form.

Why that gate and no other: [#37](https://github.com/snackpackgames/cosmicparade/issues/37) makes
raised ground and deep influence the *same hexes*, so requiring a level footprint permanently sets
the Altar's best reading position against the flattest ground it can stand on. An interior/not-rim
gate was rejected — board position drifts as wings redraw the rim, and one gate is enough.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_the_altar_is_a_triangle_three_with_one_gate() -> void:
	var altar: Altar = load("res://data/realm/altar/altar.tres")
	assert_eq(altar.shape, Footprint.Shape.TRIANGLE)
	assert_eq(altar.criteria.size(), 1)
	assert_true(altar.criteria[0] is LevelFootprintCriterion)


func test_the_altar_projects_nothing() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/77 — no domain, no radius,
	# no entry in #37's tally. Adding either is a design change, not a feature.
	var altar: Altar = load("res://data/realm/altar/altar.tres")
	assert_null(altar.zone_for([Vector2i.ZERO, Vector2i(1, 0), Vector2i(1, -1)] as Array[Vector2i]))
	assert_false("domain" in altar)
	assert_false("zone_radius" in altar)
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `bash scripts/test.sh realm/test_altar.gd`
Expected: FAIL — `Altar` is not a known class.

- [ ] **Step 3: Add `realm/altar.gd` and the authored resource**

- [ ] **Step 4: Rebuild and run**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add realm/altar.gd realm/altar.gd.uid data/realm/altar/ \
  test/unit/realm/test_altar.gd test/unit/realm/test_altar.gd.uid
git commit -m "feat: add the Altar, a triangle-three that projects nothing"
```

### Task 3.2 — The Altar stands at the origin, and can be carried but not stowed

**Files:**
- Modify: `realm/realm_state.gd`, `realm/realm.gd`
- Test: `test/unit/realm/test_realm_state.gd`, `test/unit/realm/test_realm.gd`

**Interfaces:**
- Produces: `RealmState.altar_placement: BoardPlacement` and
  `RealmState.place_altar(altar: Altar) -> BoardPlacement`, siting it at the origin in orientation
  0 and registering it in the occupancy index like anything else.
- Produces: `Realm._ready` placing the authored Altar before the first view refresh.

The Altar starts at `(0, 0)`, `(1, 0)`, `(1, -1)`
([decided](https://github.com/snackpackgames/cosmicparade/issues/77)). The origin never moves
([#53](https://github.com/snackpackgames/cosmicparade/issues/53)) and is the one hex guaranteed to
exist at every core radius and after every wing, so no coordinate is authored. The starting board
is flat, so the level gate passes trivially — there is no bootstrap paradox.

**Nothing here enforces "every realm must have one."** With one occupancy index,
`lift_under_cursor` already lifts the Altar and `Carry.cancel` already restores it: the rule holds
because the Altar has **no stock entry to be stowed into**
([decided](https://github.com/snackpackgames/cosmicparade/issues/77)), so a carry can only end in
a placement or a cancel. **Do not add a guard** — the absence is the mechanism, and a guard would
imply there is a path to block.

The Altar-less instant mid-carry is unobservable: `adr/0009` makes the parade the only clock and
nothing advances while the player is in the realm, so no system can look for an Altar and fail to
find one.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_a_new_realm_stands_its_altar_on_the_origin() -> void:
	var state := _state()
	state.place_altar(_altar())
	for hex: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1)]:
		assert_not_null(state.occupant_at(hex))
	assert_eq(state.altar_placement.hexes.size(), 3)


func test_the_altar_contributes_no_zone() -> void:
	var state := _state()
	state.place_altar(_altar())
	assert_eq(state.zones().size(), 0)


func test_the_altar_can_be_lifted_and_cancelled_back() -> void:
	var realm: Realm = add_child_autofree(preload("res://realm/realm.tscn").instantiate())
	await wait_frames(1)
	realm.cursor.aim_at(Vector2i.ZERO)
	realm.lift_under_cursor()
	assert_true(realm.carry.is_carrying())
	assert_null(realm.state.occupant_at(Vector2i.ZERO))

	realm.carry.cancel()

	assert_not_null(realm.state.occupant_at(Vector2i.ZERO))
	assert_eq(realm.state.altar_placement.hexes.size(), 3)


func test_there_is_no_way_to_stow_the_altar() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/77 — "must have one" is
	# enforced by the absence of a destination, not by a check.
	var realm: Realm = add_child_autofree(preload("res://realm/realm.tscn").instantiate())
	await wait_frames(1)
	assert_eq(realm.state.shrines_in_stock(), 2)
	realm.cursor.aim_at(Vector2i.ZERO)
	realm.lift_under_cursor()
	realm.carry.cancel()
	assert_eq(realm.state.shrines_in_stock(), 2)
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `bash scripts/test.sh realm/test_realm_state.gd`
Expected: FAIL — `place_altar` is not a method.

- [ ] **Step 3: Add `place_altar` and call it from `Realm._ready`**

- [ ] **Step 4: Run the whole suite**

Run: `bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add realm/realm_state.gd realm/realm.gd test/unit/realm/test_realm_state.gd \
  test/unit/realm/test_realm.gd
git commit -m "feat: stand the Altar on the origin of every realm"
```

### Task 3.3 — What the Altar reads

**Files:**
- Create: `realm/altar_reading.gd`
- Modify: `realm/realm_state.gd`
- Test: `test/unit/realm/test_altar_reading.gd`

**Interfaces:**
- Consumes: `RealmState.shrine_zones()` (Task 2.3), `RealmState.altar_placement` (Task 3.2).
- Produces: `AltarReading extends RefCounted` with
  `static func of(hexes: Array[Vector2i], shrine_zones: Array[InfluenceZone]) -> AltarReading`,
  `count_for(domain: Domain.Kind) -> int`, `domains_present() -> Array[Domain.Kind]`,
  `is_empty() -> bool`.
- Produces: `RealmState.altar_reading() -> AltarReading`.

Stated once, precisely
([decided](https://github.com/snackpackgames/cosmicparade/issues/79)): *for each domain, how many
shrines holding an offering of that domain project a zone covering at least one of the Altar's
three hexes.*

Three properties, each load-bearing:

- **A per-domain tally**, not a presence set or a single winner, because it degrades gracefully —
  `count_for(d) > 0` answers presence, the maximum answers character, and the magnitude survives
  for M3/M4 to spend.
- **Each shrine counted once, on any hex.** 27 board hexes reach at least one Altar hex and only
  12 reach all three (`test/prototypes/78-shrine-influence-reach/`), so counting per-hex would
  make the triangle-three a **multiplier**; counting per-zone makes it a **reach advantage**, 27
  against a single hex's 19, and footprint size can never inflate the number.
- **Shrines only.** `README.md`'s "unlike furniture" cannot mean furniture is uninfluenced, since
  #55 has furniture reading influence as *gates* — the contrast is gate versus ongoing effect. The
  deciding argument is that capacity starts at two shrines against furniture by the dozen, so an
  all-influence reading would barely register the pieces the system exists to make matter.

A named type rather than a bare `Dictionary`, following `PlacementVerdict`: M3 and M4 consume this
across a milestone boundary and deserve a name.

**Review Focus 1 lands here.**

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_a_shrine_covering_all_three_hexes_counts_once() -> void:
	# Review Focus 1. https://github.com/snackpackgames/cosmicparade/issues/79 — each
	# shrine once, on any hex, so the triangle-three is reach and not a multiplier.
	# (-1, 0) is distance 1, 2 and 2 from the Altar's three hexes.
	var state := _state()
	state.place_altar(_altar())
	_place_shrine(state, Vector2i(-1, 0), Domain.Kind.FOREST)
	assert_eq(state.altar_reading().count_for(Domain.Kind.FOREST), 1)


func test_a_shrine_reaching_only_one_hex_still_counts() -> void:
	var state := _state()
	state.place_altar(_altar())
	_place_shrine(state, Vector2i(3, -1), Domain.Kind.FOREST)
	assert_eq(state.altar_reading().count_for(Domain.Kind.FOREST), 1)


func test_the_reading_tallies_per_domain() -> void:
	var state := _state()
	state.place_altar(_altar())
	_place_shrine(state, Vector2i(-1, 0), Domain.Kind.FOREST)
	_place_shrine(state, Vector2i(-1, 1), Domain.Kind.FOREST)
	_place_shrine(state, Vector2i(2, 0), Domain.Kind.FLAME)
	assert_eq(state.altar_reading().count_for(Domain.Kind.FOREST), 2)
	assert_eq(state.altar_reading().count_for(Domain.Kind.FLAME), 1)
	assert_eq(state.altar_reading().domains_present().size(), 2)


func test_furniture_is_not_read() -> void:
	var state := _state()
	state.place_altar(_altar())
	state.place(BoardPlacement.new(_piece(Domain.Kind.FOREST, 2), 0, [Vector2i(-1, 0)] as Array[Vector2i]))
	assert_true(state.altar_reading().is_empty())


func test_a_lapsed_shrine_in_range_reads_as_nothing() -> void:
	var state := _state()
	state.place_altar(_altar())
	var shrine := _place_shrine(state, Vector2i(-1, 0), Domain.Kind.FOREST)
	shrine.offering = null
	assert_true(state.altar_reading().is_empty())
	assert_eq(state.altar_reading().count_for(Domain.Kind.FOREST), 0)
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `bash scripts/test.sh realm/test_altar_reading.gd`
Expected: FAIL — `AltarReading` is not a known class.

- [ ] **Step 3: Add `realm/altar_reading.gd` and `RealmState.altar_reading()`**

`of()` iterates the zones once, incrementing a domain's count when the zone covers **any** of the
given hexes. Derived on demand and **never stored** — the same rule zones
([#59](https://github.com/snackpackgames/cosmicparade/issues/59)) and elevation
([#31](https://github.com/snackpackgames/cosmicparade/issues/31)) already follow, and load-bearing
here because #75's offerings expire across parades, so a stored reading would go stale exactly
where nobody is watching.

- [ ] **Step 4: Rebuild and run the whole suite**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add realm/altar_reading.gd realm/altar_reading.gd.uid realm/realm_state.gd \
  test/unit/realm/test_altar_reading.gd test/unit/realm/test_altar_reading.gd.uid
git commit -m "feat: the Altar reads the shrines that reach it"
```

---

## Phase 4 — The wallet, the tier table, and the ring Swells

### Task 4.1 — The adherent balance

**Files:**
- Create: `realm/adherent_balance.gd`
- Test: `test/unit/realm/test_adherent_balance.gd`

**Interfaces:**
- Produces: `AdherentBalance extends RefCounted` with `var adherents: int`,
  `can_afford(cost: int) -> bool`, `spend(cost: int) -> bool` (refusing rather than going
  negative), `grant(amount: int) -> void`.

A plain `RefCounted` ([decided](https://github.com/snackpackgames/cosmicparade/issues/76)), the
shape every realm rule already has. Three rejections, each on its own ground, and **none may be
revisited here**:

- **Not a `Resource`.** `common/game_data.gd` is the base for *authored* `.tres`, and Godot caches
  resource instances by path — a mutated one is shared by every holder and survives scene reloads
  within a session. A balance is runtime state.
- **Not a field on `RealmState`.** Adherents are earned in the parade and spent in the realm; the
  seam runs through this object even though it is one integer.
- **Not an autoload.** `CLAUDE.md → Autoloads` wants *both* a scene change to outlive and more
  than one system. Today there is one system and nothing to outlive, because earning is out of
  scope.

**No `changed` signal.** Nothing listens, and the clause that keeps it off the autoload list — "it
arrives with its first real signal or field, never empty" — keeps the signal out until a readout
wants it. Task 6.1 polls.

The promotion path is the point of the shape: only the constructor knows where the balance comes
from, so the first autoload is a registration line plus one deleted `.new()`.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_a_new_balance_is_empty() -> void:
	assert_eq(AdherentBalance.new().adherents, 0)


func test_granting_accumulates() -> void:
	var balance := AdherentBalance.new()
	balance.grant(10)
	balance.grant(10)
	assert_eq(balance.adherents, 20)


func test_spending_what_is_not_there_is_refused_and_changes_nothing() -> void:
	var balance := AdherentBalance.new()
	balance.grant(10)
	assert_false(balance.spend(20))
	assert_eq(balance.adherents, 10)


func test_spending_what_is_there_succeeds_exactly() -> void:
	var balance := AdherentBalance.new()
	balance.grant(10)
	assert_true(balance.spend(10))
	assert_eq(balance.adherents, 0)
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `bash scripts/test.sh realm/test_adherent_balance.gd`
Expected: FAIL — `AdherentBalance` is not a known class.

- [ ] **Step 3: Add `realm/adherent_balance.gd`**

- [ ] **Step 4: Rebuild and run**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add realm/adherent_balance.gd realm/adherent_balance.gd.uid \
  test/unit/realm/test_adherent_balance.gd test/unit/realm/test_adherent_balance.gd.uid
git commit -m "feat: add the adherent balance the realm spends"
```

### Task 4.2 — The tier table

**Files:**
- Create: `realm/swell_tier.gd`
- Create: `data/realm/swell_tier/01_first_ring.tres` … `06_fourth_wing.tres`
- Test: `test/unit/realm/test_swell_tier.gd`

**Interfaces:**
- Produces: `SwellTier extends GameData` with `@export var tier_name: String`,
  `@export var board_effect: Effect` where `enum Effect {RING, WING}`,
  `@export var shrine_capacity_delta: int`, `@export var cost: int`.

Six rows, in order ([decided](https://github.com/snackpackgames/cosmicparade/issues/80) for the
grants, [decided](https://github.com/snackpackgames/cosmicparade/issues/81) for the costs):

| File | Name | Effect | Capacity delta | Cost |
|---|---|---|---|---|
| `01_first_ring` | First Ring | `RING` | +1 | 10 |
| `02_second_ring` | Second Ring | `RING` | +1 | 20 |
| `03_first_wing` | First Wing | `WING` | 0 | 40 |
| `04_second_wing` | Second Wing | `WING` | 0 | 70 |
| `05_third_wing` | Third Wing | `WING` | 0 | 110 |
| `06_fourth_wing` | Fourth Wing | `WING` | 0 | 160 |

**There is no seventh row.** Past the fourth wing, Swell grants nothing realm-side — that phase
carries only the cross-milestone column M3 and M4 own — so the action becomes unavailable rather
than expensive ([decided](https://github.com/snackpackgames/cosmicparade/issues/80)). Do not
author a placeholder row for it.

Authored rather than constants because the costs are the kind of number that gets tuned, and
tuning should not need a rebuild. Numeric filename prefixes give the table its order; `Swell`
holds an explicit ordered list of paths rather than scanning the directory, so the order is in
code review rather than in the filesystem.

**Capacity rises only on the two ring Swells, to 4, and never again.** A rising "+1 every Swell"
was rejected on the prototype's evidence: it holds a flat 77–79% board coverage through the rings
and then drifts to 91% by the fourth wing, making the realm **mushier as the player progresses**.
Capping inverts it — coverage falls to about 64% and the realm outgrows its shrines.

- [ ] **Step 1: Write the failing tests**

```gdscript
const EXPECTED := [
	["First Ring", SwellTier.Effect.RING, 1, 10],
	["Second Ring", SwellTier.Effect.RING, 1, 20],
	["First Wing", SwellTier.Effect.WING, 0, 40],
	["Second Wing", SwellTier.Effect.WING, 0, 70],
	["Third Wing", SwellTier.Effect.WING, 0, 110],
	["Fourth Wing", SwellTier.Effect.WING, 0, 160],
]


func test_the_table_is_six_rows_in_the_decided_order() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/80 (grants) and
	# https://github.com/snackpackgames/cosmicparade/issues/81 (costs). A seventh row is
	# a design change: past the fourth wing Swell grants nothing realm-side.
	assert_eq(Swell.TIER_PATHS.size(), 6)
	for index: int in EXPECTED.size():
		var tier: SwellTier = load(Swell.TIER_PATHS[index])
		assert_eq(tier.tier_name, EXPECTED[index][0])
		assert_eq(tier.board_effect, EXPECTED[index][1])
		assert_eq(tier.shrine_capacity_delta, EXPECTED[index][2])
		assert_eq(tier.cost, EXPECTED[index][3])


func test_the_ladder_totals_four_hundred_and_ten() -> void:
	var total := 0
	for path: String in Swell.TIER_PATHS:
		total += (load(path) as SwellTier).cost
	assert_eq(total, 410)


func test_capacity_rises_by_two_across_the_whole_ladder() -> void:
	var delta := 0
	for path: String in Swell.TIER_PATHS:
		delta += (load(path) as SwellTier).shrine_capacity_delta
	assert_eq(delta, 2)
	assert_eq(RealmState.STARTING_SHRINE_CAPACITY + delta, 4)
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `bash scripts/test.sh realm/test_swell_tier.gd`
Expected: FAIL — `SwellTier` is not a known class.

- [ ] **Step 3: Add `realm/swell_tier.gd` and the six resources**

`Swell.TIER_PATHS` is declared in Task 4.3; write that constant first if this task runs alone.

- [ ] **Step 4: Rebuild and run**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add realm/swell_tier.gd realm/swell_tier.gd.uid data/realm/swell_tier/ \
  test/unit/realm/test_swell_tier.gd test/unit/realm/test_swell_tier.gd.uid
git commit -m "feat: author the six Swell tiers and their prices"
```

### Task 4.3 — The Swell coordinator, and the two ring Swells

**Files:**
- Create: `realm/swell.gd`
- Test: `test/unit/realm/test_swell.gd`

**Interfaces:**
- Consumes: `RealmState` (Task 2.4 for capacity), `AdherentBalance` (Task 4.1), `SwellTier`
  (Task 4.2).
- Produces: `Swell extends RefCounted`, `const TIER_PATHS: Array[String]` (six, ordered),
  `_init(state: RealmState, balance: AdherentBalance)`, `var tiers_taken: int`,
  `is_available() -> bool`, `next_tier() -> SwellTier`, `cost_for_next() -> int`,
  `can_afford() -> bool`, `take_ring() -> Array[Vector2i]`.
- Produces: `Realm.balance: AdherentBalance` and `Realm.swell: Swell`, both constructed in
  `_ready` and injected — the realm owns them, nothing global does
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/76)). The existing debug F9
  key calls `swell.take_ring()` instead of `state.geometry.swell()`, so the board can no longer
  grow without being paid for.

**Not a method on `Realm`** — that is the scene root and logic there cannot be tested without
instantiating the scene, which no realm rule requires. `Swell` owns the only two facts that know a
Swell is a purchase: the price of the next one, and the order of operations.

**The order is load-bearing** ([decided](https://github.com/snackpackgames/cosmicparade/issues/76)):
check affordability, perform the geometry, and debit **only if hexes actually arrived**.
`RealmGeometry.swell()` already returns `[]` past radius 5, so "did the board change" is a fact
readable at the call site and needs no new signal. **No refunds**, and no window in which the
balance is wrong — this is #54's inert-while-refused rule restated in the economy.

`RealmGeometry` gains **no** knowledge of cost and `AdherentBalance` gains **no** knowledge of
Swell. Passing the cost into `swell()` was rejected because
[#53](https://github.com/snackpackgames/cosmicparade/issues/53) built the geometry as a generator
and this map prices that sequence rather than redesigning it.

`cost_for_next()` is a **query**, readable before any interaction starts, because affordability
gates *entering* a Swell. It is well-defined for wings too, since #53's four figures are all 6 or
7 hexes — price cannot depend on which the player picks.

**Review Focus 2 (the ring half) and Review Focus 4 land here.**

- [ ] **Step 1: Write the failing tests**

```gdscript
func _swell(adherents: int) -> Array:
	var state := _state()
	var balance := AdherentBalance.new()
	balance.grant(adherents)
	return [Swell.new(state, balance), state, balance]


func test_the_first_swell_costs_ten_and_is_readable_before_it_is_taken() -> void:
	var parts := _swell(0)
	assert_eq((parts[0] as Swell).cost_for_next(), 10)
	assert_false((parts[0] as Swell).can_afford())


func test_a_ring_swell_grows_the_board_raises_capacity_and_debits() -> void:
	var parts := _swell(10)
	var swell: Swell = parts[0]
	var state: RealmState = parts[1]
	assert_eq((swell.take_ring() as Array).size(), 24)
	assert_eq(state.geometry.hexes().size(), 61)
	assert_eq(state.shrine_capacity, 3)
	assert_eq((parts[2] as AdherentBalance).adherents, 0)


func test_two_ring_swells_reach_ninety_one_hexes_and_capacity_four() -> void:
	var parts := _swell(30)
	var swell: Swell = parts[0]
	swell.take_ring()
	swell.take_ring()
	assert_eq((parts[1] as RealmState).geometry.hexes().size(), 91)
	assert_eq((parts[1] as RealmState).shrine_capacity, 4)
	assert_eq(swell.next_tier().board_effect, SwellTier.Effect.WING)


func test_an_unaffordable_swell_changes_nothing() -> void:
	# Review Focus 2. https://github.com/snackpackgames/cosmicparade/issues/76 — the
	# balance is debited only after the board has actually changed.
	var parts := _swell(9)
	assert_true((parts[0] as Swell).take_ring().is_empty())
	assert_eq((parts[1] as RealmState).geometry.hexes().size(), 37)
	assert_eq((parts[2] as AdherentBalance).adherents, 9)


func test_a_ring_swell_past_the_ceiling_debits_nothing() -> void:
	# Review Focus 2. RealmGeometry.swell() returns [] past radius 5; the balance must
	# not move when the board did not.
	var parts := _swell(1000)
	var swell: Swell = parts[0]
	swell.take_ring()
	swell.take_ring()
	var before: int = (parts[2] as AdherentBalance).adherents
	assert_true(swell.take_ring().is_empty())
	assert_eq((parts[2] as AdherentBalance).adherents, before)


func test_swell_is_unavailable_past_the_sixth() -> void:
	var parts := _swell(0)
	var swell: Swell = parts[0]
	swell.tiers_taken = 6
	assert_false(swell.is_available())
	assert_null(swell.next_tier())
	assert_false(swell.can_afford())


func test_four_shrines_reach_depth_three_and_furniture_takes_it_to_four() -> void:
	# Review Focus 4. https://github.com/snackpackgames/cosmicparade/issues/80 — capacity
	# caps at 4 and depth needs five same-domain zones, so the elevation ceiling now
	# requires both halves of the realm.
	var state := _state()
	for hex: Vector2i in [Vector2i(-2, 0), Vector2i(-2, 1), Vector2i(-1, -1), Vector2i(-1, 0)]:
		_place_shrine(state, hex, Domain.Kind.FOREST)
	assert_eq(Elevation.depth_at(Vector2i.ZERO, state.zones()), 3)

	state.place(BoardPlacement.new(_piece(Domain.Kind.FOREST, 1), 0, [Vector2i(0, 1)] as Array[Vector2i]))

	assert_eq(Elevation.depth_at(Vector2i.ZERO, state.zones()), 4)
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `bash scripts/test.sh realm/test_swell.gd`
Expected: FAIL — `Swell` is not a known class.

- [ ] **Step 3: Add `realm/swell.gd`**

`take_ring()` returns the arrived hexes, or an empty array when the tier is unavailable,
unaffordable, not a `RING`, or the geometry refused. Repoint `Realm.swell()` — the debug F9 path
— at it, and keep the board's rebuild exactly as it is. It raises `state.shrine_capacity` by the
tier's delta and increments `tiers_taken` **only** on success.

- [ ] **Step 4: Rebuild and run the whole suite**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add realm/swell.gd realm/swell.gd.uid realm/realm.gd test/unit/realm/test_swell.gd \
  test/unit/realm/test_swell.gd.uid test/unit/realm/test_realm.gd
git commit -m "feat: buy the two ring Swells, debiting only when the board grew"
```

---

## Phase 5 — Wings bought through Swell, and the lift the Altar refuses

**This phase waits on [Phase 6 of the arrangement-puzzle
plan](https://github.com/snackpackgames/cosmicparade/issues/70)**, which delivers `CarriedWing`
and attaching a new wing through the carry verb. Read that issue's acceptance criteria before
starting: it already specifies that attaching through the carry takes the board from 91 to 98
hexes and that cancelling leaves it at 91. **Do not reimplement any of it** — this phase attaches
a price to it.

### Task 5.1 — Buying a wing, and paying only once it lands

**Files:**
- Modify: `realm/swell.gd`, `realm/realm.gd`
- Test: `test/unit/realm/test_swell.gd`, `test/unit/realm/test_realm.gd`

**Interfaces:**
- Consumes: `CarriedWing` and the wing-attaching carry path (#70).
- Produces: `Swell.can_take_wing() -> bool` — a next tier exists, its effect is `WING`, and the
  balance covers it.
- Produces: `Swell.complete_wing() -> bool` — debits and increments `tiers_taken`. **Called only
  after the board has actually grown.**
- Produces: `Realm.begin_wing_swell(shape: WingShape) -> void`, inert unless `can_take_wing()`.

A wing Swell is **not instantaneous**, because #53 has the player choose a figure and a place. So
the purchase spans a carry, and the order from
[#76](https://github.com/snackpackgames/cosmicparade/issues/76) still holds exactly: affordability
gates **entering** the carry, the geometry is performed by the commit, and the debit happens
**after** the board grew. A cancelled carry and a siting the geometry refuses both leave the
balance untouched and `tiers_taken` unchanged — there is nothing to refund because nothing was
taken.

Affordability is re-checked at entry and nothing can spend during a carry, so `complete_wing()`
cannot find itself short.

**The two refusals stay distinct** ([decided](https://github.com/snackpackgames/cosmicparade/issues/76)).
Not affording is an **unmet price** that stops the carry from beginning — `begin_wing_swell` is
inert, which is the same surface as the place action being inert while refused. An illegal siting
*inside* the carry is [#62](https://github.com/snackpackgames/cosmicparade/issues/62)'s refusal,
already produced by #70's verdict. Do not merge them.

Which figure the player gets is a **debug choice** in M1
([#85](https://github.com/snackpackgames/cosmicparade/issues/85) put every realm-side affordance
behind `OS.is_debug_build()`): `Realm` holds the four authored shapes in an ordered const and a
debug key cycles which one `begin_wing_swell` is called with. Price never depends on the choice —
#53's figures are all 6 or 7 hexes.

**Review Focus 2 (the wing half) lands here.**

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_a_wing_tier_is_takeable_only_once_the_rings_are_done() -> void:
	var parts := _swell(1000)
	var swell: Swell = parts[0]
	assert_false(swell.can_take_wing())
	swell.take_ring()
	swell.take_ring()
	assert_true(swell.can_take_wing())
	assert_eq(swell.cost_for_next(), 40)


func test_an_unaffordable_wing_never_begins() -> void:
	var parts := _swell(30)
	var swell: Swell = parts[0]
	swell.take_ring()
	swell.take_ring()
	assert_false(swell.can_take_wing())


func test_completing_a_wing_debits_and_advances_the_tier() -> void:
	var parts := _swell(70)
	var swell: Swell = parts[0]
	swell.take_ring()
	swell.take_ring()
	assert_true(swell.complete_wing())
	assert_eq((parts[2] as AdherentBalance).adherents, 0)
	assert_eq(swell.tiers_taken, 3)
	assert_eq(swell.cost_for_next(), 70)


func test_cancelling_a_wing_carry_costs_nothing() -> void:
	# Review Focus 2. https://github.com/snackpackgames/cosmicparade/issues/76 — the
	# debit waits for hexes to arrive, so a cancel leaves board and balance untouched.
	var realm: Realm = add_child_autofree(preload("res://realm/realm.tscn").instantiate())
	await wait_frames(1)
	realm.balance.grant(1000)
	realm.swell.take_ring()
	realm.swell.take_ring()
	var hexes_before: int = realm.state.geometry.hexes().size()
	var adherents_before: int = realm.balance.adherents

	realm.begin_wing_swell(load("res://data/realm/wing_shape/disc.tres"))
	realm.carry.cancel()

	assert_eq(realm.state.geometry.hexes().size(), hexes_before)
	assert_eq(realm.balance.adherents, adherents_before)
	assert_eq(realm.swell.tiers_taken, 2)
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `bash scripts/test.sh realm/test_swell.gd`
Expected: FAIL — `can_take_wing` is not a method.

- [ ] **Step 3: Add the wing half of the coordinator and wire it to the carry**

`Realm` connects `carry.placed` to `complete_wing()` **only while a wing Swell is the thing in
hand**, so placing furniture never debits.

- [ ] **Step 4: Run the whole suite**

Run: `bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add realm/swell.gd realm/realm.gd test/unit/realm/test_swell.gd \
  test/unit/realm/test_realm.gd
git commit -m "feat: buy a wing, paying once the player has sited it"
```

### Task 5.2 — The lift the Altar refuses

**Files:**
- Modify: `realm/realm_state.gd`, and the wing-lift entry point #70 built
- Test: `test/unit/realm/test_realm_state.gd`

**Interfaces:**
- Produces: `RealmState.altar_straddles_wing(wing_index: int) -> bool` — true when the Altar's
  footprint covers hexes both on that wing and off it.
- Produces: the wing lift consulting it, refusing the same way it already refuses a lift that
  would disconnect the board.

[#53](https://github.com/snackpackgames/cosmicparade/issues/53) relocates a wing *with its
contents* and returns a **straddling furniture footprint to the player**. The Altar has no
destination to be returned to ([#77](https://github.com/snackpackgames/cosmicparade/issues/77)),
so that path is closed to it and **the lift is refused instead**
([decided](https://github.com/snackpackgames/cosmicparade/issues/77)).

This costs nothing new. #70 already refuses a lift that would leave the board not edge-connected,
via `RealmGeometry.can_lift_wing()`, so a refused wing lift is an existing concept and this is a
**second named cause** on it. Find that entry point in `CarriedWing` or `Realm` and add the second
condition there; do not invent a parallel refusal.

The check lives on `RealmState` rather than `RealmGeometry` because geometry knows nothing about
placements, and this question is about both.

Nothing is permanently blocked: the recourse is to carry the Altar clear first, which is always
available.

**A straddling *shrine* is a different case, and it needs no new code.**
[#53](https://github.com/snackpackgames/cosmicparade/issues/53) returns a straddling footprint to
the player, and [#74](https://github.com/snackpackgames/cosmicparade/issues/74) gave shrines a
destination the Altar does not have — **stock**. Because stock is *derived* (capacity minus
placed shrines, Task 2.4), removing the placement is the whole of "returned to stock": there is no
inventory object to put it in. Assert it rather than build it, and leave #70's `piece_returned`
path exactly as it is.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_a_wing_carrying_the_whole_altar_can_still_be_lifted() -> void:
	# #53 relocates a wing with its contents; an Altar wholly aboard travels.
	var state := _state()
	state.geometry.swell()
	state.geometry.swell()
	var added := state.geometry.attach(load("res://data/realm/wing_shape/disc.tres"), 0, Vector2i(7, -1))
	assert_false(added.is_empty())
	state.place_altar(_altar())
	assert_false(state.altar_straddles_wing(0))


func test_an_altar_across_the_seam_pins_the_wing() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/77 — the straddling path
	# returns furniture to the player, and the Altar has nowhere to be returned to.
	var state := _state()
	state.geometry.swell()
	state.geometry.swell()
	var added := state.geometry.attach(load("res://data/realm/wing_shape/disc.tres"), 0, Vector2i(7, -1))
	assert_false(added.is_empty())
	var seam_hex: Vector2i = added[0]
	state.altar_placement = BoardPlacement.new(
		_altar(), 0, Footprint.occupied(Footprint.Shape.TRIANGLE, 0, seam_hex, Vector2i.ZERO)
	)
	assert_true(state.altar_straddles_wing(0))


func test_a_straddling_shrine_goes_back_to_stock_by_being_removed() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/74 gave shrines the
	# destination the Altar lacks, and stock is derived — so removal is the whole of it.
	var state := _state()
	var shrine := _place_shrine(state, Vector2i(-2, 0), Domain.Kind.FOREST)
	assert_eq(state.shrines_in_stock(), 1)

	state.remove(shrine)

	assert_eq(state.shrines_in_stock(), 2)
	assert_null(state.occupant_at(Vector2i(-2, 0)))
```

The second test's anchor must be chosen so the triangle-three has at least one hex on the wing and
at least one off it; assert both facts in the test rather than trusting the anchor, and **if it
fails, fix the anchor arithmetic in the test, not the rule**.

- [ ] **Step 2: Run them and confirm they fail**

Run: `bash scripts/test.sh realm/test_realm_state.gd`
Expected: FAIL — `altar_straddles_wing` is not a method.

- [ ] **Step 3: Add the predicate and the second refusal cause**

- [ ] **Step 4: Run the whole suite**

Run: `bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add realm/realm_state.gd realm/ test/unit/realm/test_realm_state.gd
git commit -m "feat: refuse a wing lift the Altar is standing across"
```

---

## Phase 6 — The debug readout and the record

**This phase also waits on [#70](https://github.com/snackpackgames/cosmicparade/issues/70)**,
which makes the first correction to `README.md → Scenes → Realm`. Task 6.2 edits the same
paragraphs and must land after it, or the two will conflict.

### Task 6.1 — The debug readout

**Files:**
- Create: `realm/debug_readout.gd`
- Modify: `realm/realm.tscn`, `realm/realm.gd`
- Test: `test/unit/realm/test_debug_readout.gd`

**Interfaces:**
- Consumes: `AltarReading` (Task 3.3), `AdherentBalance` (Task 4.1), `Swell` (Tasks 4.3, 5.1).
- Produces: `DebugReadout extends CanvasLayer` with
  `func refresh(reading: AltarReading, balance: AdherentBalance, swell: Swell) -> void` and
  `func text() -> String`, which returns what is currently displayed so the tests can read it
  without scraping a `Label`.
- Produces: `const Swell.DEBUG_GRANT := 10` — the first ring Swell's price, asserted equal to it
  rather than repeated by hand.

**One rule for all three numbers** ([decided](https://github.com/snackpackgames/cosmicparade/issues/85)):
a readout behind `OS.is_debug_build()`, beside the existing F8/F9 keys. Player-facing presentation
is `area:ui` work, which has no map, and **is not built here**. In-scene presentation was
considered and put aside — #76 had already set this floor for the balance, the map's *Out of
scope* defers how a Swell reads as an event, and nothing in M1 spends the Altar's reading.

It shows, each on its own line:

- the Altar's reading **per domain**, omitting domains at zero, with its range of **0–4**;
- the adherent balance;
- the next Swell's price and what it grants, from `cost_for_next()` and `next_tier()`;
- past the sixth Swell, **that there is no further Swell** — #80 leaves the action unavailable
  rather than expensive, and a readout showing no price would be indistinguishable from a bug.

**It updates live while a piece is carried**, not only when one lands. `Realm._on_aimed` already
composes the candidate zone with the committed ones; refresh from there as well as from
`_refresh_view()`. The reading must be built from **shrine zones only**, so when the carried piece
is a shrine its candidate zone joins `state.shrine_zones()` and otherwise it does not.

Also add two debug affordances, guarded by `OS.is_debug_build()`:

| InputMap action | Does |
|---|---|
| `debug_grant_adherents` | `balance.grant(Swell.DEBUG_GRANT)` — **10**, the first ring Swell's price ([decided](https://github.com/snackpackgames/cosmicparade/issues/76), [valued](https://github.com/snackpackgames/cosmicparade/issues/81)), cumulative, so one press buys one of the cheapest Swell |
| `debug_empty_vessel` | empties the vessel of the shrine under the cursor |

**These are InputMap actions, not raw keycodes**, even though the F8/F9 affordances Phase 4 of the
other plan left in place are raw keys.
[#76](https://github.com/snackpackgames/cosmicparade/issues/76) named `debug_grant_adherents` as
an action and that decision stands; `debug_empty_vessel` follows it for consistency. Add both to
`project.godot`'s `[input]` section beside the realm actions
[#83](https://github.com/snackpackgames/cosmicparade/pull/83) added. Bind them to F10 and F11.

The second exists because **a lapse cannot otherwise be observed in M1 at all**: `adr/0009` makes
the parade the only clock, parades are M5/M6, so no offering ever expires during anything this
plan builds. Without it, the one behaviour #75 called the realm's most distinctive would ship with
no way to see it by hand.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_the_readout_names_each_domain_the_altar_reads() -> void:
	var state := _state()
	state.place_altar(_altar())
	_place_shrine(state, Vector2i(-1, 0), Domain.Kind.FOREST)
	var readout: DebugReadout = add_child_autofree(DebugReadout.new())
	readout.refresh(state.altar_reading(), AdherentBalance.new(), Swell.new(state, AdherentBalance.new()))
	assert_string_contains(readout.text(), "Forest 1")


func test_the_readout_says_when_there_is_no_further_swell() -> void:
	var state := _state()
	state.place_altar(_altar())
	var swell := Swell.new(state, AdherentBalance.new())
	swell.tiers_taken = 6
	var readout: DebugReadout = add_child_autofree(DebugReadout.new())
	readout.refresh(state.altar_reading(), AdherentBalance.new(), swell)
	assert_string_contains(readout.text(), "no further Swell")


func test_the_debug_grant_is_the_first_swells_price() -> void:
	assert_eq(Swell.DEBUG_GRANT, 10)
	assert_eq(Swell.DEBUG_GRANT, (load(Swell.TIER_PATHS[0]) as SwellTier).cost)
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `bash scripts/test.sh realm/test_debug_readout.gd`
Expected: FAIL — `DebugReadout` is not a known class.

- [ ] **Step 3: Add the readout, mount it in `realm.tscn`, declare the two actions in
  `project.godot`, and handle them in `Realm._unhandled_input`**

- [ ] **Step 4: Rebuild and run the whole suite**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add realm/debug_readout.gd realm/debug_readout.gd.uid realm/realm.tscn realm/realm.gd \
  project.godot \
  test/unit/realm/test_debug_readout.gd test/unit/realm/test_debug_readout.gd.uid
git commit -m "feat: show the reading, the balance and the next price in debug"
```

### Task 6.2 — Correct the record

**Files:**
- Modify: `README.md`, `CLAUDE.md`

**No new tests.** Verify with `grep` and by reading.

`README.md` is the authoritative design document and several of its lines are now wrong. The map
carried this as a **standing preference** from its charting session. #70 has already rewritten the
board's extent and the carry verb in `Scenes → Realm`; this task adds what this map decided on top
of that, and **must not undo it**.

| Where | Becomes |
|---|---|
| `Terminology` → **Swell** | spending adherents to enlarge the realm and raise its **shrine capacity** |
| `Scenes → Realm` opening | the realm starts with a **shrine capacity of 2**; "slot" leaves the shrine vocabulary |
| `Scenes → Realm` → **Shrine slots** heading and paragraph | **Shrines** — a capacity you hold, one shrine per point, freely placed, footprints never colliding; fruit goes in the shrine's **offering vessel** |
| `Scenes → Realm` → **Swell** paragraph | the three phases: two ring Swells to 91 spaces raising capacity to 4, four wing Swells, then nothing realm-side; the permanent maximum of 115–119 spaces |
| `Scenes → Realm` → **Altar** paragraph | a triangle-three footprint, standing at the centre of a new realm, requiring level ground, projecting no influence of its own, moved by the same carry verb |
| `Settled Decisions` → **Shrine slots** entry | renamed to **shrine capacity**, with the offering vessel named and the cap of 4 stated |
| `Settled Decisions` | a new entry for what the Altar reads: a per-domain count of the shrine zones reaching any of its hexes, shrines only, derived and never stored |
| `CLAUDE.md` → 3D Physics Layers | one line saying the `fixture` and `furniture` masks exist for **picking**, and that footprint non-overlap is grid data in `RealmState`, not physics |

The word **slot** survives only in `adr/0006`'s tile assembly
([decided](https://github.com/snackpackgames/cosmicparade/issues/74)) — the collision was between
"shrine slot" as a *count* and as the *place an offering goes*, and both uses give way.

`README.md → Open Design Questions` is **unchanged**. This map answers none of them —
*Communicating domain influence* is adjacent but #85 deliberately left player-facing surfacing to
`area:ui`.

- [ ] **Step 1: Amend `README.md`**

- [ ] **Step 2: Add the `CLAUDE.md` line**

- [ ] **Step 3: Verify the vocabulary actually changed**

Run: `grep -n "shrine slot" README.md CLAUDE.md`
Expected: no matches outside `adr/0006`'s tile-assembly sense.

Run: `grep -n "Open Design Questions" -A 60 README.md | grep -c "Swell\|shrine capacity"`
Expected: `0`.

- [ ] **Step 4: Run lint and the suite**

Run: `bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add README.md CLAUDE.md
git commit -m "docs: record Swell's cost and tiers, shrine capacity and the Altar"
```
