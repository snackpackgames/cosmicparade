# Realm Board and Arrangement Puzzle Implementation Plan

> **For agentic workers:** Implement this plan task-by-task, committing after each task as it
> directs. Steps use checkbox (`- [ ]`) syntax for tracking. **Do not create a git worktree** —
> `CLAUDE.md → Claude Code Configuration` forbids them in this repo; work on a topic branch in
> the main working directory. The usual sub-skill for inline execution is
> `superpowers:executing-plans`; `superpowers:subagent-driven-development` is not used here
> because it provisions a worktree.

**Goal:** Furniture can be arranged on the realm board — the board has a shape that survives
growth, a piece occupies a footprint and projects an influence zone, placement is gated by
per-piece criteria, and the player carries pieces around with a verb that previews what each
target would do.

**Architecture:** The board is **generated, never authored** — a core radius plus an ordered set
of placed wings. Everything downstream is **derived**: a piece's occupied hexes come from its
shape, orientation and grab offset; its influence zone comes from its occupied hexes; a hex's
depth comes from the zones over it. Nothing is stored twice. One carry state machine reads one
targeted hex and is the only thing that writes to the board, so the live preview is the same
derivation run against a hypothetical placement.

**Tech Stack:** Godot 4.7.2-stable, GDScript, GUT 9.7.1, `common/surface.gdshader`.

**Spec:** [Map: the realm board and the arrangement
puzzle](https://github.com/snackpackgames/cosmicparade/issues/49) — ten closed decision tickets
and two prototypes. Every rule below is linked to the ticket that settled it. **Where this plan
says "decided", the linked ticket holds the reasoning: do not re-derive it, and do not
substitute a different answer because it looks better in context.**

This plan builds on
[`2026-11-11-realm-ground-elevation-plan.md`](2026-11-11-realm-ground-elevation-plan.md), which
is merged. `HexCoordinates`, `Domain`, `InfluenceZone`, `Elevation`, `HexSpace`,
`BoardMaterial`, `RealmBoard` and `realm/realm.tscn` already exist and are the inputs here.
That plan's *What this plan does not decide, and must not invent* section lists exactly the four
things this one supplies.

## Global Constraints

- **The board is a radial hexagon of core radius 3 — 37 spaces — centred on axial `(0, 0)`, and
  it is generated from the radius, never stored as a hex set**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/50)). The origin never moves.
- **Growth is two-phase**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/53)). The first two Swells add
  whole rings — radius 3 → 4 (61) → 5 (91) — and the core never grows concentrically again.
  Every Swell after that attaches a **wing**.
- **The wing vocabulary is four authored figures**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/61)): disc (7 hexes, 1
  distinct orientation), trapezoid (7, 6), triangle (6, 2), rhombus (6, 3). A wing attaches
  edge-adjacent to **any** board hex — core or another wing, indifferently — and wings may chain.
- **A wing is just more board.** Same axial lattice; **no rule knows a hex is on a wing**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/53)). There is no second
  coordinate space, no seam flag, and no code that branches on wing membership except the
  geometry that places and lifts wings.
- **Footprint is a per-piece property from a closed vocabulary of five polyhexes** — single,
  pair, straight-three, bend-three, triangle-three; the complete set up to size 3
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/51)). **Footprints never
  overlap; influence does.** One piece projects exactly **one** zone whatever its size.
- **A zone is the union of radius-`r` discs grown from every hex the piece occupies**, with `r`
  authored per piece and **1** the default
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/52)).
- **A zone is a set of coordinates, not of board hexes. It projects into the void; the void is
  inert. Clipping happens at consumption, never in the data**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/59)).
- **Zones are recomputed from the pieces and never stored**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/59)), the same call
  [#33](https://github.com/snackpackgames/cosmicparade/issues/33) made for height.
- **A board change recomputes elevation for the hexes added or removed — nothing else**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/59)). Coverage of existing
  hexes cannot change when no footprint moved.
- **Furniture rotates: six 60° steps on every piece, orientation a single integer 0–5**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/56)), because the art has a
  facing even where the footprint has no asymmetry. **The pivot is the grab hex**, not the
  authored anchor. Orientation is **sticky** for pieces arriving from inventory; a piece lifted
  from the board keeps its own. A **wing** instead cycles only its **distinct** orientations
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/61)) — a deliberate break,
  because a wing has no art.
- **Placement criteria are a closed vocabulary of five gate types** — height, level footprint,
  domain influence count, clearance, board position
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/55)). A piece carries a list;
  **every criterion must pass on every hex of the footprint**. One quantifier, no `OR`.
- **Gates only.** What a piece projects is a property of the piece, never of where it sits
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/55)). No criterion may
  modify a zone, a radius or a depth.
- **Criteria read the board as it will be with the piece on it, own influence included**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/41), left explicitly
  unqualified by [#55](https://github.com/snackpackgames/cosmicparade/issues/55)). So a domain
  criterion counts the piece's own zone, and `Forest ≥ 2` means "a Forest neighbour".
- **Criteria are a gate checked once at placement and never re-checked**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/30)). Nothing is ever
  re-validated and no placed piece is ever displaced by a later board change.
- **The verb is carry** ([decided](https://github.com/snackpackgames/cosmicparade/issues/54)):
  click to lift, the piece rides a hex cursor, click to place, right-click or Esc to cancel back
  to its origin. No button is held. **Validity is a property of the current target**,
  re-evaluated whenever the occupied set changes, and the place action is **inert** while
  refused. **A carried piece occupies nothing** and its influence is gone for the whole carry.
- **The verb reads one targeted hex**, so mouse and gamepad/keyboard are the same path, and
  lift/place/cancel/rotate are **InputMap actions**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/54)).
- **Three signals, three jobs, no shared language**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/62)): the terrain preview
  resolves on every target, valid or not; the influence spill says "legal, and it costs you
  reach"; the refusal marks failing **hexes** on the board and failing **requirements** on the
  piece, **unpaired**.
- Godot **4.7.2-stable**; GDScript indented with **tabs**; `max-line-length: 100` per
  `.gdlintrc`.
- Every script declares a `class_name`. After adding one, run `bash scripts/import.sh`.
- **Commit `.uid` sidecars** for every new script and `.tres`
  (`CLAUDE.md → Common Gotchas`).
- Tests are GUT, extend `GutTest`, and mirror the source tree under `test/unit/realm/`.

### Test helpers used throughout

GUT gives these tests no shared base class, so each test file declares the helpers it uses.
Their bodies are given here once; do not vary them, because several tasks' expected values depend
on the exact placeholder pieces.

```gdscript
func _stool() -> Furniture:
	return load("res://data/realm/furniture/mushroom_stool.tres")


func _bench() -> Furniture:
	return load("res://data/realm/furniture/fern_bench.tres")


func _stool_at(hex: Vector2i) -> FurniturePlacement:
	return FurniturePlacement.new(_stool(), 0, [hex] as Array[Vector2i])


func _bench_at(hex: Vector2i, orientation: int) -> FurniturePlacement:
	return FurniturePlacement.new(
		_bench(), orientation,
		Footprint.occupied(Footprint.Shape.STRAIGHT, orientation, hex, Vector2i(1, 0))
	)


# Two Forest stools whose radius-1 discs together cover the line (-1,0) (0,0) (1,0),
# which is what a straight-three authoring Forest >= 2 needs. One stool cannot do it:
# the only straight-three inside a radius-1 disc runs through the disc's own centre,
# and that hex is occupied by the piece projecting it.
func _flank_the_centre_line_with_forest(state: RealmState) -> void:
	state.place(_stool_at(Vector2i(-1, 1)))
	state.place(_stool_at(Vector2i(1, 1)))
```

### Two rulings derived from the map, flagged because they are not quoted from a ticket

Both follow from rules the map states; neither is a new design choice. They are called out here
so a reviewer can check the derivation rather than discover the behaviour in code.

1. **A wing lift that would disconnect the board is refused.**
   [#53](https://github.com/snackpackgames/cosmicparade/issues/53) requires every wing to share
   an edge with the board and lets wings chain, so lifting the wing another wing hangs off would
   leave hexes floating. Read as a board **invariant** rather than only an attach-time check,
   one rule covers both directions, and `adr/0001`'s floating rock stays one object. Task 1.3.
2. **Rotate-while-hovering auto-lifts furniture only, never a wing.**
   [#56](https://github.com/snackpackgames/cosmicparade/issues/56) gave the auto-lift to a
   hovered *piece*; every board hex past radius 5 belongs to a wing, so extending it would make
   a stray rotate pick up the ground. A wing enters a carry only through an explicit lift.
   Task 4.2.

### One factual correction to a closed ticket

[#52](https://github.com/snackpackgames/cosmicparade/issues/52)'s table records the **bend-three**
as covering 12 hexes at radius 1 and 27 at radius 2. The true figures are **13 and 29** — the
same as the straight-three, because the bend's two ends are also 2 apart, so its three discs
overlap exactly as the straight's do. There are precisely three trihexes up to rotation and
their radius-1 zones are 13 (straight), 13 (bend) and 12 (triangle). **The decision is
unaffected**: radius 2 was rejected because a three-hex piece claims three quarters of the
board, which 29/37 says more strongly than 27/37. Use the real geometry in tests; do not
reproduce the table's figure.

### What this plan does not decide, and must not invent

- **What an overlap produces.** Meld and burgeon *resolution* — which domains fuse into which
  biome, `adr/0004`'s fusion table, `adr/0008`'s interior fill and boundary features — is M2 and
  on the map's *Out of scope*. This plan decides where influence falls, never what it becomes.
- **What a Swell costs, shrine slots, and the Altar.** M1's third map. `RealmGeometry.swell()`
  is a method with no price attached; the demo scene calls it from a debug action and nothing
  else does.
- **Furniture supply.** The design/blueprint inventory (`adr/0011`) is out of scope on the map.
  Pieces enter a carry through an API that takes a `Furniture` resource; the authored `.tres`
  instances here are **placeholder content** for the demo scene and tests, in the same spirit as
  `BoardMaterial`. A piece displaced by a wing move is announced on a signal rather than put
  anywhere.
- **Any art.** Colour, iconography, sound, motion, how a refusal reads, how the spill falls off
  into dust, whether the seam is visible, how many models a turned piece needs — all art
  direction on the map's *Out of scope*. Every visual this plan adds is a flat placeholder and
  says so in the code.
- **Where the requirement list is drawn** (panel, tooltip, text on the ghost) — layout, deferred
  with the rest of the placement UI's look
  ([#62](https://github.com/snackpackgames/cosmicparade/issues/62)). This plan puts it in one
  `Control` so the replacement has one seam.
- **Save/load.** No save system exists and `area:save` is not this map. Board state lives in
  memory for the session.
- **Biome criteria.** A criterion naming a fused biome would need meld resolution and is deferred
  with it ([#55](https://github.com/snackpackgames/cosmicparade/issues/55)). Criteria name only
  `adr/0005`'s six base domains.

## Review Focus

Five input classes the map's rules imply that a straightforward reading of the tasks would not
exercise. Each has a test in the task that owns the code.

1. **A footprint hanging off the board.** Occupied hexes are board hexes *by definition*
   ([#59](https://github.com/snackpackgames/cosmicparade/issues/59)), so a straight-three aimed
   at a rim hex must be refused outright — not silently placed on two hexes and the void.
   Task 3.3.
2. **A piece shifted or turned onto its own hexes.** A carried piece occupies nothing
   ([#54](https://github.com/snackpackgames/cosmicparade/issues/54)), so a straight-three must be
   able to move one hex along its own axis and to rotate about its own grab hex without colliding
   with itself. Task 4.2.
3. **Lifting a wing that another wing chains off.** Routine once wings chain, and it must be
   refused rather than orphaning hexes. Task 1.3.
4. **Clearance and board position reading off-board hexes.** Off-board means "nothing there", so
   clearance passes over the void, and an edge hex is a board hex with an absent neighbour
   ([#55](https://github.com/snackpackgames/cosmicparade/issues/55)). Task 3.2.
5. **A Swell that invalidates a placed piece's criteria.** A rim piece placed under
   `board position = edge` becomes interior when a wing lands beside it, and must stay exactly
   where it is ([#30](https://github.com/snackpackgames/cosmicparade/issues/30) — never
   re-checked). Task 6.1.

---

## Phases

| Phase | Delivers | Blocked by |
|---|---|---|
| 1 | Hex arithmetic, the wing vocabulary, and the board that grows | — |
| 2 | Pieces: footprints, orientation, the authored resource, and the zone they project | 1 |
| 3 | The five criteria and the placement verdict | 2 |
| 4 | The carry verb: targeted hex, state machine, live preview, commit | 3 |
| 5 | What the player is told: refusal, spill, and the impossible piece | 4 |
| 6 | Wings through the same verb, then `adr/0015`, `adr/0016` and the README | 5 |

One issue per phase. Commit after each task.

---

## Phase 1 — Hex arithmetic, the wing vocabulary, and the board that grows

### Task 1.1 — Neighbours, rotation, discs and rings

**Files:**
- Modify: `realm/hex_coordinates.gd`
- Modify: `test/unit/realm/test_hex_coordinates.gd`

**Interfaces:**
- Consumes: `HexCoordinates.distance(a, b) -> int`, `HexCoordinates.CIRCUMRADIUS` (both exist).
- Produces: `HexCoordinates.DIRECTIONS: Array[Vector2i]`,
  `HexCoordinates.neighbors(hex: Vector2i) -> Array[Vector2i]`,
  `HexCoordinates.rotate(hex: Vector2i, steps: int) -> Vector2i`,
  `HexCoordinates.disc(center: Vector2i, radius: int) -> Array[Vector2i]`,
  `HexCoordinates.ring(center: Vector2i, radius: int) -> Array[Vector2i]`

Every later task is arithmetic over these four. Keeping them on `HexCoordinates` is the existing
convention — one source of truth for hex geometry — and means no other file knows the lattice.

`DIRECTIONS` is the six unit steps in order: `(1, 0)`, `(1, -1)`, `(0, -1)`, `(-1, 0)`,
`(-1, 1)`, `(0, 1)`. One 60° step on the flat-top axial lattice is `(q, r) → (q + r, -q)`, which
has order 6; `rotate` applies it `posmod(steps, 6)` times.

**The sign matters and this plan first had it backwards.** There are two 60° steps,
`(q, r) → (q + r, -q)` and `(q, r) → (-r, q + r)`, and they turn opposite ways. Only the first
walks `DIRECTIONS` forwards — `rotate(DIRECTIONS[i], 1) == DIRECTIONS[i + 1]` — which is what the
tests below require, so **the tests are the specification and this paragraph follows them**. The
wing prototype (`test/prototypes/61-wing-vocabulary/main.gd`) used the other sign; that changes
handedness only, and an orientation count is the size of an orbit under a group of order 6, so
the prototype's measured counts (disc 1, trapezoid 6, triangle 2, rhombus 3) mean here exactly
what they meant there — Task 1.2's test re-derives them from the authored offsets anyway.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_the_six_directions_are_unit_steps() -> void:
	assert_eq(HexCoordinates.DIRECTIONS.size(), 6)
	for direction: Vector2i in HexCoordinates.DIRECTIONS:
		assert_eq(HexCoordinates.distance(Vector2i.ZERO, direction), 1)


func test_a_hex_has_six_neighbors_all_one_away() -> void:
	var neighbors := HexCoordinates.neighbors(Vector2i(2, -1))
	assert_eq(neighbors.size(), 6)
	for neighbor: Vector2i in neighbors:
		assert_eq(HexCoordinates.distance(Vector2i(2, -1), neighbor), 1)


func test_six_rotation_steps_return_a_hex_to_itself() -> void:
	assert_eq(HexCoordinates.rotate(Vector2i(2, -1), 6), Vector2i(2, -1))


func test_one_rotation_step_walks_the_directions() -> void:
	# Rotating direction i by one step gives direction i + 1.
	for i in 6:
		assert_eq(
			HexCoordinates.rotate(HexCoordinates.DIRECTIONS[i], 1),
			HexCoordinates.DIRECTIONS[(i + 1) % 6]
		)


func test_rotation_preserves_distance_from_the_origin() -> void:
	assert_eq(HexCoordinates.distance(Vector2i.ZERO, HexCoordinates.rotate(Vector2i(3, -1), 2)), 3)


func test_negative_rotation_steps_turn_the_other_way() -> void:
	assert_eq(HexCoordinates.rotate(Vector2i(1, 0), -1), HexCoordinates.DIRECTIONS[5])


func test_a_disc_holds_three_n_squared_plus_three_n_plus_one_hexes() -> void:
	assert_eq(HexCoordinates.disc(Vector2i.ZERO, 0).size(), 1)
	assert_eq(HexCoordinates.disc(Vector2i.ZERO, 1).size(), 7)
	assert_eq(HexCoordinates.disc(Vector2i.ZERO, 3).size(), 37)
	assert_eq(HexCoordinates.disc(Vector2i.ZERO, 5).size(), 91)


func test_a_disc_is_centred_where_it_was_asked_to_be() -> void:
	var disc := HexCoordinates.disc(Vector2i(4, -2), 2)
	assert_true(disc.has(Vector2i(4, -2)))
	for hex: Vector2i in disc:
		assert_lte(HexCoordinates.distance(Vector2i(4, -2), hex), 2)


func test_a_ring_holds_six_n_hexes_and_a_radius_zero_ring_is_its_centre() -> void:
	assert_eq(HexCoordinates.ring(Vector2i.ZERO, 0), [Vector2i.ZERO] as Array[Vector2i])
	assert_eq(HexCoordinates.ring(Vector2i.ZERO, 4).size(), 24)
	assert_eq(HexCoordinates.ring(Vector2i.ZERO, 5).size(), 30)


func test_a_ring_is_exactly_the_hexes_that_far_out() -> void:
	for hex: Vector2i in HexCoordinates.ring(Vector2i.ZERO, 3):
		assert_eq(HexCoordinates.distance(Vector2i.ZERO, hex), 3)
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm/test_hex_coordinates.gd`
Expected: FAIL — `DIRECTIONS`, `neighbors`, `rotate`, `disc` and `ring` do not exist.

- [ ] **Step 3: Implement the five additions in `realm/hex_coordinates.gd`**

`DIRECTIONS` as a `const Array[Vector2i]` in the order above. `disc` by scanning the axial
bounding box and keeping what `distance` accepts — the same shape as the existing
`realm/realm.gd` demo loop, which Task 1.3 deletes. `ring(center, radius)` as the hexes of
`disc` at exactly `radius`, returning `[center]` at radius 0 so callers need no special case.

- [ ] **Step 4: Run the tests**

Run: `bash scripts/test.sh realm/test_hex_coordinates.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/hex_coordinates.gd test/unit/realm/test_hex_coordinates.gd
git commit -m "feat: add hex neighbours, rotation, discs and rings"
```

---

### Task 1.2 — The `GameData` base and the four authored wing shapes

**Files:**
- Create: `common/game_data.gd`
- Create: `realm/wing_shape.gd`
- Create: `data/realm/wing_shape/disc.tres`
- Create: `data/realm/wing_shape/trapezoid.tres`
- Create: `data/realm/wing_shape/triangle.tres`
- Create: `data/realm/wing_shape/rhombus.tres`
- Test: `test/unit/common/test_game_data.gd`
- Test: `test/unit/realm/test_wing_shape.gd`

**Interfaces:**
- Consumes: `HexCoordinates.rotate`, `HexCoordinates.DIRECTIONS` (Task 1.1).
- Produces: `GameData extends Resource`;
  `WingShape extends GameData` with `shape_name: String`, `offsets: Array[Vector2i]`,
  `distinct_orientations: int`, and
  `wing.rotated_offsets(steps: int) -> Array[Vector2i]`;
  the four `.tres` paths above.

**This is the project's first authored `.tres`**, so it brings `GameData` with it —
`CLAUDE.md → Architecture` has the base "arriving with the first `.tres`". It stays empty of
fields on purpose: it exists to be the one type authored data extends.

The roster is authored, not computed
([decided](https://github.com/snackpackgames/cosmicparade/issues/61)) — a shared table with its
own identity, following `adr/0004`/`0006`/`0007`, which is why it lives under `data/realm/`
rather than inline on an instance the way
[#51](https://github.com/snackpackgames/cosmicparade/issues/51)'s footprints do. Offsets are
authored from an anchor at `(0, 0)`:

| `.tres` | `shape_name` | `offsets` | `distinct_orientations` |
|---|---|---|---|
| `disc.tres` | `disc` | `(0,0) (1,0) (1,-1) (0,-1) (-1,0) (-1,1) (0,1)` | 1 |
| `trapezoid.tres` | `trapezoid` | `(0,0) (0,1) (0,2) (0,3) (1,0) (1,1) (1,2)` | 6 |
| `triangle.tres` | `triangle` | `(0,0) (1,0) (2,0) (0,1) (1,1) (0,2)` | 2 |
| `rhombus.tres` | `rhombus` | `(0,0) (0,1) (0,2) (1,0) (1,1) (1,2)` | 3 |

`distinct_orientations` is **authored data, not computed at runtime**
([decided](https://github.com/snackpackgames/cosmicparade/issues/61)) — it is a property of the
shape, and the test below is what keeps the authored number honest.

- [ ] **Step 1: Write the failing tests**

`test/unit/common/test_game_data.gd`:

```gdscript
func test_game_data_is_a_resource() -> void:
	assert_true(GameData.new() is Resource)
```

`test/unit/realm/test_wing_shape.gd`:

```gdscript
const SHAPES := {
	"disc": [7, 1],
	"trapezoid": [7, 6],
	"triangle": [6, 2],
	"rhombus": [6, 3],
}


func _shape(name: String) -> WingShape:
	return load("res://data/realm/wing_shape/%s.tres" % name)


func _canonical(offsets: Array[Vector2i]) -> Array:
	# Translation-invariant form: the smallest sorted offset list over every
	# choice of which hex sits at the origin.
	var best: Array = []
	for anchor: Vector2i in offsets:
		var form: Array[Vector2i] = []
		for offset: Vector2i in offsets:
			form.append(offset - anchor)
		form.sort()
		if best.is_empty() or form < best:
			best = form
	return best


func test_the_roster_is_exactly_four_entries() -> void:
	assert_eq(DirAccess.get_files_at("res://data/realm/wing_shape").size(), 4)


func test_every_entry_has_its_decided_size_and_orientation_count() -> void:
	for name: String in SHAPES:
		var shape := _shape(name)
		assert_eq(shape.offsets.size(), SHAPES[name][0], "%s size" % name)
		assert_eq(shape.distinct_orientations, SHAPES[name][1], "%s orientations" % name)


func test_the_authored_orientation_count_matches_rotating_the_offsets() -> void:
	for name: String in SHAPES:
		var shape := _shape(name)
		var forms := {}
		for steps in 6:
			forms[_canonical(shape.rotated_offsets(steps))] = true
		assert_eq(forms.size(), shape.distinct_orientations, "%s" % name)


func test_every_entry_is_edge_connected() -> void:
	for name: String in SHAPES:
		var shape := _shape(name)
		var remaining := {}
		for offset: Vector2i in shape.offsets:
			remaining[offset] = true
		var frontier: Array[Vector2i] = [shape.offsets[0]]
		var reached := 0
		remaining.erase(shape.offsets[0])
		while not frontier.is_empty():
			reached += 1
			for neighbor: Vector2i in HexCoordinates.neighbors(frontier.pop_back()):
				if remaining.erase(neighbor):
					frontier.append(neighbor)
		assert_eq(reached, shape.offsets.size(), "%s is one patch" % name)


func test_rotating_by_zero_returns_the_authored_offsets() -> void:
	assert_eq(_shape("trapezoid").rotated_offsets(0), _shape("trapezoid").offsets)


func test_rotation_preserves_the_hex_count() -> void:
	assert_eq(_shape("trapezoid").rotated_offsets(3).size(), 7)
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm/test_wing_shape.gd`
Expected: FAIL — `WingShape` does not exist.

- [ ] **Step 3: Implement `GameData`, `WingShape` and the four `.tres`**

`class_name GameData extends Resource` with a doc comment naming its role and nothing else.
`class_name WingShape extends GameData` with the three `@export`s and `rotated_offsets(steps)`
mapping `HexCoordinates.rotate` over `offsets`. Author the four `.tres` by hand from the table
above, each with `script = ExtResource` pointing at `realm/wing_shape.gd`.

- [ ] **Step 4: Rebuild the class cache, then run the tests**

Run: `bash scripts/import.sh && bash scripts/test.sh realm`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add common/game_data.gd common/game_data.gd.uid \
        realm/wing_shape.gd realm/wing_shape.gd.uid \
        data/realm/wing_shape test/unit/common test/unit/realm/test_wing_shape.gd
git commit -m "feat: add the GameData base and the four wing shapes"
```

---

### Task 1.3 — `RealmGeometry`: a core radius plus an ordered set of wings

**Files:**
- Create: `realm/placed_wing.gd`
- Create: `realm/realm_geometry.gd`
- Test: `test/unit/realm/test_placed_wing.gd`
- Test: `test/unit/realm/test_realm_geometry.gd`

**Interfaces:**
- Consumes: `HexCoordinates.*` (Task 1.1), `WingShape` (Task 1.2).
- Produces: `PlacedWing.new(shape: WingShape, steps: int, anchor: Vector2i)`,
  `wing.hexes() -> Array[Vector2i]`, `wing.shape`, `wing.steps`, `wing.anchor`;
  `RealmGeometry.new()`, `RealmGeometry.CORE_START_RADIUS == 3`,
  `RealmGeometry.CORE_MAX_RADIUS == 5`, `geometry.core_radius: int`,
  `geometry.wings: Array[PlacedWing]`, `geometry.hexes() -> Array[Vector2i]`,
  `geometry.has_hex(hex) -> bool`, `geometry.is_edge_hex(hex) -> bool`,
  `geometry.wing_index_at(hex) -> int`, `geometry.rings_remaining() -> int`,
  `geometry.swell() -> Array[Vector2i]`,
  `geometry.can_attach(shape: WingShape, steps: int, anchor: Vector2i) -> bool`,
  `geometry.attach(shape, steps, anchor) -> Array[Vector2i]`,
  `geometry.can_lift_wing(index: int) -> bool`,
  `geometry.lift_wing(index: int) -> Array[Vector2i]`

The whole board is two generators and no coordinate list
([decided](https://github.com/snackpackgames/cosmicparade/issues/53)). `swell()` returns the
hexes it added — the new ring while `core_radius < CORE_MAX_RADIUS`, otherwise an empty array,
because past radius 5 a Swell is a wing attachment and the player chooses where. `attach` and
`lift_wing` likewise return the hexes added or removed, which is exactly the recompute set
[#59](https://github.com/snackpackgames/cosmicparade/issues/59) bounds elevation work to.

`can_attach` is three conditions: the wing's hexes must not already be board, at least one must
share an edge with a board hex, and — the same invariant read the other way — `can_lift_wing` is
false when removing that wing would leave the rest of the board not edge-connected. See
*Two rulings derived from the map*, ruling 1.

- [ ] **Step 1: Write the failing tests**

`test/unit/realm/test_placed_wing.gd`:

```gdscript
func test_a_placed_wing_is_its_shape_rotated_and_translated() -> void:
	var wing := PlacedWing.new(load("res://data/realm/wing_shape/disc.tres"), 0, Vector2i(5, -2))
	assert_eq(wing.hexes().size(), 7)
	assert_true(wing.hexes().has(Vector2i(5, -2)))


func test_rotation_steps_wrap() -> void:
	var shape: WingShape = load("res://data/realm/wing_shape/trapezoid.tres")
	assert_eq(
		PlacedWing.new(shape, 6, Vector2i.ZERO).hexes(),
		PlacedWing.new(shape, 0, Vector2i.ZERO).hexes()
	)
```

`test/unit/realm/test_realm_geometry.gd` — the load-bearing assertions:

```gdscript
func test_a_fresh_realm_is_a_radius_three_hexagon_of_thirty_seven_spaces() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/50
	var geometry := RealmGeometry.new()
	assert_eq(geometry.core_radius, 3)
	assert_eq(geometry.hexes().size(), 37)
	assert_true(geometry.has_hex(Vector2i.ZERO))
	assert_false(geometry.has_hex(Vector2i(4, 0)))


func test_the_first_two_swells_add_rings_and_the_third_adds_none() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/53
	var geometry := RealmGeometry.new()
	assert_eq(geometry.swell().size(), 24)
	assert_eq(geometry.hexes().size(), 61)
	assert_eq(geometry.swell().size(), 30)
	assert_eq(geometry.hexes().size(), 91)
	assert_eq(geometry.core_radius, RealmGeometry.CORE_MAX_RADIUS)
	assert_eq(geometry.swell(), [] as Array[Vector2i], "the core never grows again")
	assert_eq(geometry.hexes().size(), 91)


func test_the_origin_never_moves() -> void:
	var geometry := RealmGeometry.new()
	geometry.swell()
	assert_true(geometry.has_hex(Vector2i.ZERO))
	assert_true(geometry.has_hex(Vector2i(3, 0)), "ring 3 is still ring 3")


func test_a_wing_must_share_an_edge_with_the_board() -> void:
	var geometry := RealmGeometry.new()
	var disc: WingShape = load("res://data/realm/wing_shape/disc.tres")
	assert_false(geometry.can_attach(disc, 0, Vector2i(20, 0)), "nowhere near the board")
	assert_true(geometry.can_attach(disc, 0, Vector2i(5, -1)), "edge-adjacent to ring 3")


func test_a_wing_may_not_overlap_the_board() -> void:
	var geometry := RealmGeometry.new()
	var disc: WingShape = load("res://data/realm/wing_shape/disc.tres")
	assert_false(geometry.can_attach(disc, 0, Vector2i.ZERO))


func test_attaching_a_wing_adds_exactly_its_hexes() -> void:
	var geometry := RealmGeometry.new()
	var disc: WingShape = load("res://data/realm/wing_shape/disc.tres")
	assert_eq(geometry.attach(disc, 0, Vector2i(5, -1)).size(), 7)
	assert_eq(geometry.hexes().size(), 44)
	assert_true(geometry.has_hex(Vector2i(5, -1)))


func test_wings_may_chain_off_another_wing() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/53
	var geometry := RealmGeometry.new()
	var disc: WingShape = load("res://data/realm/wing_shape/disc.tres")
	geometry.attach(disc, 0, Vector2i(5, -1))
	assert_true(geometry.can_attach(disc, 0, Vector2i(8, -2)))


func test_no_rule_knows_a_hex_is_on_a_wing() -> void:
	# wing_index_at exists for lifting a wing and for nothing else.
	var geometry := RealmGeometry.new()
	geometry.attach(load("res://data/realm/wing_shape/disc.tres"), 0, Vector2i(5, -1))
	assert_eq(geometry.wing_index_at(Vector2i.ZERO), -1)
	assert_eq(geometry.wing_index_at(Vector2i(5, -1)), 0)


func test_an_edge_hex_is_a_board_hex_with_an_absent_neighbour() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/55
	var geometry := RealmGeometry.new()
	assert_true(geometry.is_edge_hex(Vector2i(3, 0)))
	assert_false(geometry.is_edge_hex(Vector2i.ZERO))
	assert_false(geometry.is_edge_hex(Vector2i(9, 9)), "off the board is not an edge hex")


func test_attaching_a_wing_rewrites_the_boards_edge() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/53 — the edge is
	# irregular and mutable. #55 accepts the drift because criteria are a gate
	# checked once and never re-checked.
	var geometry := RealmGeometry.new()
	var disc: WingShape = load("res://data/realm/wing_shape/disc.tres")
	assert_false(geometry.has_hex(Vector2i(4, -1)), "void before the Swell")
	geometry.attach(disc, 0, Vector2i(5, -1))
	assert_true(geometry.is_edge_hex(Vector2i(4, -1)), "board now, and on the new rim")
	assert_true(geometry.is_edge_hex(Vector2i(3, -1)), "a core hex keeps an absent neighbour")


func test_lifting_a_wing_removes_exactly_its_hexes() -> void:
	var geometry := RealmGeometry.new()
	geometry.attach(load("res://data/realm/wing_shape/disc.tres"), 0, Vector2i(5, -1))
	assert_eq(geometry.lift_wing(0).size(), 7)
	assert_eq(geometry.hexes().size(), 37)
	assert_eq(geometry.wings.size(), 0)


# Review Focus 3: wings chain, so a lift can orphan one.
func test_lifting_a_wing_another_wing_hangs_off_is_refused() -> void:
	var geometry := RealmGeometry.new()
	var disc: WingShape = load("res://data/realm/wing_shape/disc.tres")
	geometry.attach(disc, 0, Vector2i(5, -1))
	geometry.attach(disc, 0, Vector2i(8, -2))
	assert_false(geometry.can_lift_wing(0), "it carries the second wing's only edge")
	assert_eq(geometry.lift_wing(0), [] as Array[Vector2i], "and the lift does nothing")
	assert_eq(geometry.hexes().size(), 51)
	assert_true(geometry.can_lift_wing(1), "the outer wing comes off freely")
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm/test_realm_geometry.gd`
Expected: FAIL — `RealmGeometry` does not exist.

- [ ] **Step 3: Implement `PlacedWing` and `RealmGeometry`**

`PlacedWing extends RefCounted`, three fields set in `_init`, `hexes()` translating
`shape.rotated_offsets(steps)` by `anchor`.

`RealmGeometry extends RefCounted` holding `core_radius` and `wings`. Build the hex set as a
`Dictionary` keyed by `Vector2i` once per mutation and keep it as the lookup `has_hex` reads, so
`hexes()` is a generated list and the dictionary is a cache of the same two generators rather
than a second authority. `can_lift_wing` tests edge-connectedness of the board minus that wing
by flooding from any remaining hex — the rest of the board must all be reachable.

- [ ] **Step 4: Rebuild the class cache, then run the tests**

Run: `bash scripts/import.sh && bash scripts/test.sh realm`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/placed_wing.gd realm/placed_wing.gd.uid \
        realm/realm_geometry.gd realm/realm_geometry.gd.uid \
        test/unit/realm/test_placed_wing.gd test/unit/realm/test_realm_geometry.gd
git commit -m "feat: generate the realm board from a core radius and placed wings"
```

---

### Task 1.4 — The board follows the geometry

**Files:**
- Modify: `realm/realm_board.gd`
- Modify: `realm/realm.gd`
- Modify: `test/unit/realm/test_realm_board.gd`

**Interfaces:**
- Consumes: `RealmGeometry` (Task 1.3), `RealmBoard.build(hexes)`,
  `RealmBoard.rebuild(changed_hexes)`, `RealmBoard.hex_space(hex)` (all exist).
- Produces: `board.set_hexes(hexes: Array[Vector2i]) -> void`

`build()` stays as it is — the initial build from a hex list. `set_hexes()` reconciles: it adds a
`HexSpace` for every hex the board does not hold and frees the space for every hex no longer in
the list, leaving every other space untouched so growth costs work proportional to the hexes
added or removed ([decided](https://github.com/snackpackgames/cosmicparade/issues/59)).

`realm/realm.gd` loses its `DEMO_RADIUS` loop and builds from a `RealmGeometry` instead; Task 4.4
rewrites the rest of it.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_set_hexes_adds_the_spaces_a_swell_brings() -> void:
	var board := _board([] as Array[InfluenceZone])
	board.set_hexes(HEXES + [Vector2i(5, 0)] as Array[Vector2i])
	assert_not_null(board.hex_space(Vector2i(5, 0)))
	assert_eq(board.get_child_count(), 4)


func test_set_hexes_frees_the_spaces_a_lifted_wing_takes_away() -> void:
	var board := _board([] as Array[InfluenceZone])
	board.set_hexes([Vector2i.ZERO] as Array[Vector2i])
	await wait_frames(1)
	assert_null(board.hex_space(Vector2i(1, 0)))
	assert_eq(board.get_child_count(), 1)


func test_set_hexes_leaves_an_unchanged_space_alone() -> void:
	var board := _board([] as Array[InfluenceZone])
	var space := board.hex_space(Vector2i.ZERO)
	board.set_hexes(HEXES + [Vector2i(5, 0)] as Array[Vector2i])
	assert_eq(board.hex_space(Vector2i.ZERO), space, "the same node, not a rebuilt one")


func test_a_new_space_takes_the_depth_the_zones_already_give_it() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/59 — a Swell can raise
	# ground on the new land with nothing newly placed.
	var board := _board([
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i(5, 0)]),
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i(5, 0)]),
	] as Array[InfluenceZone])
	board.set_hexes(HEXES + [Vector2i(5, 0)] as Array[Vector2i])
	assert_almost_eq(
		board.hex_space(Vector2i(5, 0)).top_height(), Elevation.height_for_depth(1), 0.0001
	)


func test_the_realm_scene_builds_a_radius_three_board() -> void:
	var realm: Node3D = add_child_autofree(REALM_SCENE.instantiate())
	await wait_frames(1)
	assert_eq(realm.get_node("RealmBoard").get_child_count(), 37)
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm/test_realm_board.gd`
Expected: FAIL — `set_hexes` does not exist; the scene builds 37 only by coincidence of the
demo loop, so assert the failure is about `set_hexes` before continuing.

- [ ] **Step 3: Implement `set_hexes()` and point `realm.gd` at `RealmGeometry`**

`set_hexes` diffs against `_spaces`, reusing the `build()` body for an added hex and
`queue_free()` plus an erase for a removed one. `realm.gd` holds
`var geometry := RealmGeometry.new()` and calls `$RealmBoard.build(geometry.hexes())`.

- [ ] **Step 4: Run the whole suite and the linter**

Run: `bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/realm_board.gd realm/realm.gd test/unit/realm/test_realm_board.gd
git commit -m "feat: reconcile the board's spaces with the realm geometry"
```

---

## Phase 2 — Pieces, and what they project

### Task 2.1 — The footprint vocabulary and orientation

**Files:**
- Create: `realm/footprint.gd`
- Test: `test/unit/realm/test_footprint.gd`

**Interfaces:**
- Consumes: `HexCoordinates.rotate` (Task 1.1).
- Produces: `Footprint.Shape` enum `{SINGLE, PAIR, STRAIGHT, BEND, TRIANGLE}`,
  `Footprint.offsets_for(shape: Shape) -> Array[Vector2i]`,
  `Footprint.occupied(shape: Shape, orientation: int, target: Vector2i, grab_offset: Vector2i)
  -> Array[Vector2i]`

The five shapes are the complete set of polyhexes up to size 3
([decided](https://github.com/snackpackgames/cosmicparade/issues/51)) — **there is no sixth, and
none may be added**. An enum rather than authored `.tres`: the vocabulary is closed and shared,
and a piece authors a *choice* from it, not a shape of its own.

Canonical offsets, anchored at `(0, 0)`:

| Shape | Offsets | Distinct footprints under rotation |
|---|---|---|
| `SINGLE` | `(0,0)` | 1 |
| `PAIR` | `(0,0) (1,0)` | 3 |
| `STRAIGHT` | `(0,0) (1,0) (2,0)` | 3 |
| `BEND` | `(0,0) (1,0) (2,-1)` | 6 |
| `TRIANGLE` | `(0,0) (1,0) (1,-1)` | 2 |

The distinct counts are [#56](https://github.com/snackpackgames/cosmicparade/issues/56)'s table
and they are **not** used to limit the rotate input — furniture always takes six steps. They are
asserted because they are what makes the bend the bend: `BEND`'s ends are 2 apart and
non-collinear, which is the only thing distinguishing it from `STRAIGHT`.

**The pivot is the grab hex** ([decided](https://github.com/snackpackgames/cosmicparade/issues/56)),
so the occupied set is `target + rotate(offset - grab_offset, orientation)` for every offset.
The grabbed hex therefore lands on the target at every orientation, which is what keeps a
rotating piece under the cursor instead of swinging away.

- [ ] **Step 1: Write the failing tests**

```gdscript
const SIZES := {
	Footprint.Shape.SINGLE: 1,
	Footprint.Shape.PAIR: 2,
	Footprint.Shape.STRAIGHT: 3,
	Footprint.Shape.BEND: 3,
	Footprint.Shape.TRIANGLE: 3,
}


func _canonical(hexes: Array[Vector2i]) -> Array:
	var best: Array = []
	for anchor: Vector2i in hexes:
		var form: Array[Vector2i] = []
		for hex: Vector2i in hexes:
			form.append(hex - anchor)
		form.sort()
		if best.is_empty() or form < best:
			best = form
	return best


func test_the_vocabulary_is_five_shapes_and_no_more() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/51 — the complete set
	# of polyhexes up to size 3. A sixth entry is a design change, not a feature.
	assert_eq(Footprint.Shape.size(), 5)


func test_each_shape_has_its_decided_hex_count() -> void:
	for shape: Footprint.Shape in SIZES:
		assert_eq(Footprint.offsets_for(shape).size(), SIZES[shape])


func test_every_shape_is_edge_connected() -> void:
	for shape: Footprint.Shape in SIZES:
		for offset: Vector2i in Footprint.offsets_for(shape):
			var touches := offset == Vector2i.ZERO
			for neighbor: Vector2i in HexCoordinates.neighbors(offset):
				touches = touches or Footprint.offsets_for(shape).has(neighbor)
			assert_true(touches, "%s has a detached hex" % shape)


func test_the_triangle_is_three_mutually_adjacent_hexes() -> void:
	var offsets := Footprint.offsets_for(Footprint.Shape.TRIANGLE)
	for a: Vector2i in offsets:
		for b: Vector2i in offsets:
			assert_lte(HexCoordinates.distance(a, b), 1)


func test_the_bend_is_a_chain_whose_ends_are_two_apart_and_not_in_line() -> void:
	var offsets := Footprint.offsets_for(Footprint.Shape.BEND)
	assert_eq(HexCoordinates.distance(offsets[0], offsets[2]), 2)
	assert_ne(
		_canonical(offsets), _canonical(Footprint.offsets_for(Footprint.Shape.STRAIGHT)),
		"the bend must not be the straight in disguise"
	)


func test_each_shape_has_its_decided_number_of_distinct_footprints() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/56
	var expected := {
		Footprint.Shape.SINGLE: 1, Footprint.Shape.PAIR: 3, Footprint.Shape.STRAIGHT: 3,
		Footprint.Shape.BEND: 6, Footprint.Shape.TRIANGLE: 2,
	}
	for shape: Footprint.Shape in expected:
		var forms := {}
		for orientation in 6:
			forms[_canonical(
				Footprint.occupied(shape, orientation, Vector2i.ZERO, Vector2i.ZERO)
			)] = true
		assert_eq(forms.size(), expected[shape], "%s" % shape)


func test_the_grabbed_hex_lands_on_the_target() -> void:
	# The pivot is the grab hex, at every orientation.
	for orientation in 6:
		var occupied := Footprint.occupied(
			Footprint.Shape.STRAIGHT, orientation, Vector2i(2, -1), Vector2i(2, 0)
		)
		assert_true(occupied.has(Vector2i(2, -1)), "orientation %d" % orientation)


func test_a_rotated_footprint_keeps_its_hex_count_and_stays_connected() -> void:
	for orientation in 6:
		var occupied := Footprint.occupied(
			Footprint.Shape.BEND, orientation, Vector2i.ZERO, Vector2i(1, 0)
		)
		assert_eq(occupied.size(), 3)
		assert_eq(occupied.size(), {occupied[0]: 0, occupied[1]: 0, occupied[2]: 0}.size())


func test_orientation_wraps_and_six_steps_is_a_full_turn() -> void:
	assert_eq(
		Footprint.occupied(Footprint.Shape.BEND, 6, Vector2i.ZERO, Vector2i.ZERO),
		Footprint.occupied(Footprint.Shape.BEND, 0, Vector2i.ZERO, Vector2i.ZERO)
	)
	assert_eq(
		Footprint.occupied(Footprint.Shape.BEND, -1, Vector2i.ZERO, Vector2i.ZERO),
		Footprint.occupied(Footprint.Shape.BEND, 5, Vector2i.ZERO, Vector2i.ZERO)
	)
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm/test_footprint.gd`
Expected: FAIL — `Footprint` does not exist.

- [ ] **Step 3: Implement `Footprint` in `realm/footprint.gd`**

`class_name Footprint extends RefCounted`, the enum, a `const` dictionary of offsets keyed by
shape, and the two statics. `offsets_for` returns a duplicate so a caller cannot mutate the
vocabulary.

- [ ] **Step 4: Rebuild the class cache, then run the tests**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_footprint.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/footprint.gd realm/footprint.gd.uid test/unit/realm/test_footprint.gd
git commit -m "feat: add the five footprint shapes and orientation"
```

---

### Task 2.2 — The zone a piece projects

**Files:**
- Modify: `realm/influence_zone.gd`
- Modify: `test/unit/realm/test_influence_zone.gd`

**Interfaces:**
- Consumes: `HexCoordinates.disc` (Task 1.1).
- Produces: `InfluenceZone.project(domain: Domain.Kind, occupied: Array[Vector2i],
  radius: int) -> InfluenceZone`, `zone.coordinates() -> Array[Vector2i]`

**One zone per piece whatever its footprint**
([decided](https://github.com/snackpackgames/cosmicparade/issues/51)) — a zone per occupied hex
would make a multi-hex piece burgeon with itself. `project` is the union of radius-`radius` discs
around every occupied hex ([decided](https://github.com/snackpackgames/cosmicparade/issues/52)),
computed **with no reference to the board**, so the coordinates that land in the void are in the
set like any others ([decided](https://github.com/snackpackgames/cosmicparade/issues/59)).

`coordinates()` exists for the spill display in Task 5.2, which needs the off-board part. No
consumer gets a clipped zone; consumers that need real hexes intersect with the board themselves,
and `Elevation.depth_at()` is only ever asked about hexes that exist.

Derived sizes at radius 1, which the tests pin: single 7, pair 10, straight 13, bend 13,
triangle 12. See *One factual correction to a closed ticket* for the bend.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_a_single_hex_piece_projects_a_seven_hex_disc() -> void:
	var zone := InfluenceZone.project(
		Domain.Kind.FOREST, [Vector2i.ZERO] as Array[Vector2i], 1
	)
	assert_eq(zone.hex_count(), 7)
	assert_true(zone.covers(Vector2i.ZERO), "a piece always stands inside its own influence")


func test_each_footprint_projects_its_derived_zone_size() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/52 — grown from every
	# occupied hex, so the five footprints are five zone shapes.
	var expected := {
		Footprint.Shape.SINGLE: 7, Footprint.Shape.PAIR: 10, Footprint.Shape.STRAIGHT: 13,
		Footprint.Shape.BEND: 13, Footprint.Shape.TRIANGLE: 12,
	}
	for shape: Footprint.Shape in expected:
		var occupied := Footprint.occupied(shape, 0, Vector2i.ZERO, Vector2i.ZERO)
		assert_eq(
			InfluenceZone.project(Domain.Kind.STONE, occupied, 1).hex_count(),
			expected[shape], "%s" % shape
		)


func test_radius_zero_influences_only_the_hexes_the_piece_stands_on() -> void:
	var occupied := Footprint.occupied(
		Footprint.Shape.PAIR, 0, Vector2i.ZERO, Vector2i.ZERO
	)
	assert_eq(InfluenceZone.project(Domain.Kind.GALE, occupied, 0).hex_count(), 2)


func test_a_zone_is_one_set_however_much_its_discs_overlap() -> void:
	var occupied := Footprint.occupied(
		Footprint.Shape.TRIANGLE, 0, Vector2i.ZERO, Vector2i.ZERO
	)
	var zone := InfluenceZone.project(Domain.Kind.FLAME, occupied, 1)
	assert_eq(zone.coordinates().size(), zone.hex_count())


func test_a_projected_zone_keeps_its_domain() -> void:
	assert_eq(
		InfluenceZone.project(Domain.Kind.WETLAND, [Vector2i.ZERO] as Array[Vector2i], 1).domain,
		Domain.Kind.WETLAND
	)


func test_a_zone_projects_into_the_void_rather_than_clipping() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/59 — a set of
	# coordinates, not of board hexes. project() takes no board at all.
	var zone := InfluenceZone.project(
		Domain.Kind.FOREST, [Vector2i(3, 0)] as Array[Vector2i], 1
	)
	assert_eq(zone.hex_count(), 7)
	assert_true(zone.covers(Vector2i(4, 0)), "one hex past the rim of a radius-3 board")


func test_coordinates_lists_every_hex_the_zone_covers() -> void:
	var zone := InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO, Vector2i(1, 0)])
	var coordinates := zone.coordinates()
	coordinates.sort()
	assert_eq(coordinates, [Vector2i.ZERO, Vector2i(1, 0)] as Array[Vector2i])
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm/test_influence_zone.gd`
Expected: FAIL — `project` and `coordinates` do not exist.

- [ ] **Step 3: Implement `project()` and `coordinates()`**

`project` as a static returning `InfluenceZone.new(domain, union)`, where the union is built in a
`Dictionary` so set semantics hold by construction as they already do in `_init`. `coordinates()`
returns the keys of `_hexes` as `Array[Vector2i]`.

- [ ] **Step 4: Run the tests**

Run: `bash scripts/test.sh realm/test_influence_zone.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/influence_zone.gd test/unit/realm/test_influence_zone.gd
git commit -m "feat: project a piece's influence zone from its occupied hexes"
```

---

### Task 2.3 — The furniture resource and the committed board

**Files:**
- Create: `realm/placement_criterion.gd`
- Create: `realm/furniture.gd`
- Create: `realm/furniture_placement.gd`
- Create: `realm/realm_state.gd`
- Create: `data/realm/furniture/mushroom_stool.tres`
- Create: `data/realm/furniture/standing_stone.tres`
- Create: `data/realm/furniture/fern_bench.tres`
- Test: `test/unit/realm/test_furniture.gd`
- Test: `test/unit/realm/test_furniture_placement.gd`
- Test: `test/unit/realm/test_realm_state.gd`

**Interfaces:**
- Consumes: `GameData` (Task 1.2), `Footprint` (Task 2.1), `InfluenceZone.project` (Task 2.2),
  `RealmGeometry` (Task 1.3).
- Produces: `PlacementCriterion extends GameData` with `failing_hexes(context) ->
  Array[Vector2i]` and `describe() -> String`;
  `Furniture extends GameData` with `piece_name: String`, `domain: Domain.Kind`,
  `shape: Footprint.Shape`, `anchor: Vector2i`, `zone_radius: int`,
  `criteria: Array[PlacementCriterion]`;
  `FurniturePlacement.new(furniture: Furniture, orientation: int, hexes: Array[Vector2i])`,
  `placement.zone() -> InfluenceZone`, `placement.furniture`, `placement.orientation`,
  `placement.hexes`;
  `RealmState.new(geometry: RealmGeometry)`, `state.geometry`,
  `state.placements: Array[FurniturePlacement]`, `state.zones() -> Array[InfluenceZone]`,
  `state.occupant_at(hex: Vector2i) -> FurniturePlacement`,
  `state.place(placement) -> void`, `state.remove(placement) -> void`,
  `state.placements_within(hexes: Array[Vector2i]) -> Array[FurniturePlacement]`,
  `state.placements_touching(hexes: Array[Vector2i]) -> Array[FurniturePlacement]`

`criteria` is typed `Array[PlacementCriterion]`, so the **empty base** comes in here rather than
in Phase 3 — one `class_name PlacementCriterion extends GameData` with
`failing_hexes(context: PlacementContext) -> Array[Vector2i]` and `describe() -> String`, both
returning empty values, and a doc comment saying the five concrete criteria are the whole
vocabulary and a sixth is a design change. `PlacementContext` does not exist yet, so type the
parameter loosely here and tighten it in Task 3.1 when the context lands. The five criteria
themselves are Phase 3's.

**Orientation is per-placed-piece board state, one integer 0–5**
([decided](https://github.com/snackpackgames/cosmicparade/issues/56)); the sticky last-used value
is carry state and is not stored here. A placement stores the hexes it occupies rather than
recomputing them from a target and a grab offset: the occupied set is the thing the board cares
about, and it is what every criterion and the zone read.

`RealmState.zones()` recomputes from `placements` on every call
([decided](https://github.com/snackpackgames/cosmicparade/issues/59)). **Nothing caches it.**

The three `.tres` are placeholder content, authored to exercise the system rather than to be
game design — one single-hex piece, one with a bigger reach, one three-hex piece. Criteria are
added to them in Task 3.3.

| `.tres` | `domain` | `shape` | `anchor` | `zone_radius` |
|---|---|---|---|---|
| `mushroom_stool` | `FOREST` | `SINGLE` | `(0, 0)` | 1 |
| `standing_stone` | `STONE` | `SINGLE` | `(0, 0)` | 2 |
| `fern_bench` | `FOREST` | `STRAIGHT` | `(1, 0)` | 1 |

`fern_bench`'s anchor is its middle hex, which is the hex the piece arrives under when taken
from inventory ([decided](https://github.com/snackpackgames/cosmicparade/issues/54)).

- [ ] **Step 1: Write the failing tests**

`test/unit/realm/test_furniture.gd`:

```gdscript
func test_every_authored_piece_is_loadable_and_has_a_name_and_a_shape() -> void:
	for file: String in DirAccess.get_files_at("res://data/realm/furniture"):
		var piece: Furniture = load("res://data/realm/furniture/%s" % file.trim_suffix(".remap"))
		assert_false(piece.piece_name.is_empty(), file)
		assert_true(piece.zone_radius >= 0, file)
		assert_true(Footprint.offsets_for(piece.shape).has(piece.anchor), "%s anchor" % file)


func test_zone_radius_defaults_to_one() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/52 — radius 1 is the
	# baseline, authored per piece.
	assert_eq(Furniture.new().zone_radius, 1)
```

`test/unit/realm/test_furniture_placement.gd`:

```gdscript
func _piece(shape: Footprint.Shape, domain: Domain.Kind, radius: int) -> Furniture:
	var piece := Furniture.new()
	piece.shape = shape
	piece.domain = domain
	piece.zone_radius = radius
	return piece


func test_a_placement_projects_one_zone_from_all_its_hexes() -> void:
	var hexes := Footprint.occupied(
		Footprint.Shape.STRAIGHT, 0, Vector2i.ZERO, Vector2i.ZERO
	)
	var placement := FurniturePlacement.new(
		_piece(Footprint.Shape.STRAIGHT, Domain.Kind.FOREST, 1), 0, hexes
	)
	assert_eq(placement.zone().hex_count(), 13)
	assert_eq(placement.zone().domain, Domain.Kind.FOREST)


func test_a_placement_remembers_its_orientation() -> void:
	var placement := FurniturePlacement.new(
		_piece(Footprint.Shape.SINGLE, Domain.Kind.GALE, 1), 4, [Vector2i.ZERO] as Array[Vector2i]
	)
	assert_eq(placement.orientation, 4)
```

`test/unit/realm/test_realm_state.gd`:

```gdscript
func test_a_fresh_realm_has_no_placements_and_no_zones() -> void:
	var state := RealmState.new(RealmGeometry.new())
	assert_eq(state.placements.size(), 0)
	assert_eq(state.zones().size(), 0)


func test_zones_are_recomputed_from_the_placements_every_call() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/59 — never stored.
	var state := RealmState.new(RealmGeometry.new())
	var placement := _stool_at(Vector2i.ZERO)
	state.place(placement)
	assert_eq(state.zones().size(), 1)
	state.remove(placement)
	assert_eq(state.zones().size(), 0)


func test_every_hex_of_a_footprint_is_occupied() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var bench := _bench_at(Vector2i.ZERO, 0)
	state.place(bench)
	for hex: Vector2i in bench.hexes:
		assert_eq(state.occupant_at(hex), bench, "%s" % hex)
	assert_null(state.occupant_at(Vector2i(0, 2)))


func test_placements_within_finds_only_pieces_wholly_inside_the_hexes() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var bench := _bench_at(Vector2i.ZERO, 0)
	state.place(bench)
	assert_eq(state.placements_within(bench.hexes), [bench])
	assert_eq(state.placements_within([Vector2i.ZERO] as Array[Vector2i]), [])


func test_placements_touching_finds_a_piece_overlapping_the_hexes_at_all() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var bench := _bench_at(Vector2i.ZERO, 0)
	state.place(bench)
	assert_eq(state.placements_touching([Vector2i.ZERO] as Array[Vector2i]), [bench])
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm`
Expected: FAIL — `Furniture`, `FurniturePlacement` and `RealmState` do not exist.

- [ ] **Step 3: Implement the three scripts and author the three `.tres`**

`Furniture extends GameData` with the six `@export`s. `FurniturePlacement extends RefCounted`
with `zone()` calling `InfluenceZone.project(furniture.domain, hexes, furniture.zone_radius)` —
derived on demand, nothing stored. `RealmState extends RefCounted` holding the geometry and the
placements, with an occupancy `Dictionary` keyed by hex maintained in `place`/`remove` so
`occupant_at` is a lookup rather than a scan.

- [ ] **Step 4: Rebuild the class cache, then run the suite and the linter**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/placement_criterion.gd realm/placement_criterion.gd.uid \
        realm/furniture.gd realm/furniture.gd.uid \
        realm/furniture_placement.gd realm/furniture_placement.gd.uid \
        realm/realm_state.gd realm/realm_state.gd.uid \
        data/realm/furniture test/unit/realm/test_furniture.gd \
        test/unit/realm/test_furniture_placement.gd test/unit/realm/test_realm_state.gd
git commit -m "feat: add the furniture resource and the committed board state"
```

---

## Phase 3 — Criteria, and the verdict on a target

### Task 3.1 — The context, the criterion base, height and level footprint

**Files:**
- Create: `realm/placement_context.gd`
- Modify: `realm/placement_criterion.gd` (the base arrived in Task 2.3)
- Create: `realm/height_criterion.gd`
- Create: `realm/level_footprint_criterion.gd`
- Test: `test/unit/realm/test_placement_context.gd`
- Test: `test/unit/realm/test_height_criterion.gd`
- Test: `test/unit/realm/test_level_footprint_criterion.gd`

**Interfaces:**
- Consumes: `RealmState`, `FurniturePlacement` (Task 2.3), `InfluenceZone` (Task 2.2),
  `Elevation.depth_at(hex, zones)`, `Elevation.MAX_DEPTH` (both exist), `RealmGeometry`
  (Task 1.3).
- Produces: `PlacementContext.new(state: RealmState, occupied: Array[Vector2i],
  zones: Array[InfluenceZone])`, `context.occupied`, `context.has_hex(hex) -> bool`,
  `context.is_edge_hex(hex) -> bool`, `context.depth_at(hex) -> int`,
  `context.zone_count(domain: Domain.Kind, hex: Vector2i) -> int`,
  `context.occupant_at(hex) -> FurniturePlacement`;
  `PlacementCriterion.failing_hexes(context: PlacementContext) -> Array[Vector2i]` tightened
  from Task 2.3's loose signature;
  `HeightCriterion` with `min_depth: int`, `max_depth: int`;
  `LevelFootprintCriterion` with no fields

**One interface for all five criteria, and it returns hexes rather than a bool.** A criterion
answers "which hexes are the problem" — empty means it passes. That single shape is what lets
[#62](https://github.com/snackpackgames/cosmicparade/issues/62)'s two channels stay unpaired: the
union of every criterion's hexes is marked on the board, and the criteria themselves are marked
on the piece, with nothing pairing them. It also carries **level footprint**, which belongs to no
single hex and so returns the whole footprint, without a special case anywhere else.

`zones` already contains the candidate's own projected zone when `PlacementRules` builds the
context (Task 3.3) — criteria read the board **as it will be with the piece on it**
([decided](https://github.com/snackpackgames/cosmicparade/issues/41), left unqualified by
[#55](https://github.com/snackpackgames/cosmicparade/issues/55)). The Height criterion's "absolute"
in #55's table distinguishes it from level footprint's *relative* comparison; it is not a
different snapshot of the board.

**Height is expressed in depth, 0–4**, not in world units: depth is the integer the rule
produces and the risers the player counts, `height = depth × step` is a presentation detail, and
a float bound would be authored against a constant the board is allowed to rescale
(`HexCoordinates.CIRCUMRADIUS`). `max_depth` defaults to `Elevation.MAX_DEPTH`, so authoring only
`min_depth` gives "at least this high".

- [ ] **Step 1: Write the failing tests**

`test/unit/realm/test_placement_context.gd`:

```gdscript
func _context(occupied: Array[Vector2i], zones: Array[InfluenceZone]) -> PlacementContext:
	return PlacementContext.new(RealmState.new(RealmGeometry.new()), occupied, zones)


func test_the_context_reads_board_membership_from_the_geometry() -> void:
	var context := _context([Vector2i.ZERO] as Array[Vector2i], [] as Array[InfluenceZone])
	assert_true(context.has_hex(Vector2i(3, 0)))
	assert_false(context.has_hex(Vector2i(4, 0)))
	assert_true(context.is_edge_hex(Vector2i(3, 0)))


func test_depth_comes_from_the_zones_it_was_given() -> void:
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
	]
	assert_eq(_context([Vector2i.ZERO] as Array[Vector2i], zones).depth_at(Vector2i.ZERO), 1)


func test_zone_count_counts_zones_of_one_domain_over_a_hex() -> void:
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
	]
	var context := _context([Vector2i.ZERO] as Array[Vector2i], zones)
	assert_eq(context.zone_count(Domain.Kind.FOREST, Vector2i.ZERO), 2)
	assert_eq(context.zone_count(Domain.Kind.STONE, Vector2i.ZERO), 1)
	assert_eq(context.zone_count(Domain.Kind.GALE, Vector2i.ZERO), 0)
```

`test/unit/realm/test_height_criterion.gd`:

```gdscript
func test_a_minimum_depth_refuses_flat_ground() -> void:
	var criterion := HeightCriterion.new()
	criterion.min_depth = 1
	var context := PlacementContext.new(
		RealmState.new(RealmGeometry.new()),
		[Vector2i.ZERO] as Array[Vector2i],
		[] as Array[InfluenceZone]
	)
	assert_eq(criterion.failing_hexes(context), [Vector2i.ZERO] as Array[Vector2i])


func test_a_minimum_depth_passes_on_raised_ground() -> void:
	var criterion := HeightCriterion.new()
	criterion.min_depth = 1
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
	]
	var context := PlacementContext.new(
		RealmState.new(RealmGeometry.new()), [Vector2i.ZERO] as Array[Vector2i], zones
	)
	assert_eq(criterion.failing_hexes(context), [] as Array[Vector2i])


func test_a_maximum_depth_refuses_ground_that_is_too_high() -> void:
	# Authoring a piece that may only sit on flat ground: max_depth = 0.
	var criterion := HeightCriterion.new()
	criterion.max_depth = 0
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
	]
	var context := PlacementContext.new(
		RealmState.new(RealmGeometry.new()), [Vector2i.ZERO] as Array[Vector2i], zones
	)
	assert_eq(criterion.failing_hexes(context), [Vector2i.ZERO] as Array[Vector2i])


func test_it_fails_only_the_hexes_that_are_wrong() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/55 — every criterion is
	# evaluated against every hex of the footprint.
	var criterion := HeightCriterion.new()
	criterion.min_depth = 1
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
	]
	var context := PlacementContext.new(
		RealmState.new(RealmGeometry.new()),
		[Vector2i.ZERO, Vector2i(1, 0)] as Array[Vector2i],
		zones
	)
	assert_eq(criterion.failing_hexes(context), [Vector2i(1, 0)] as Array[Vector2i])


func test_the_default_range_passes_anything_the_rule_can_produce() -> void:
	assert_eq(HeightCriterion.new().min_depth, 0)
	assert_eq(HeightCriterion.new().max_depth, Elevation.MAX_DEPTH)


func test_it_describes_itself_without_naming_a_hex() -> void:
	var criterion := HeightCriterion.new()
	criterion.min_depth = 2
	assert_string_contains(criterion.describe(), "2")
```

`test/unit/realm/test_level_footprint_criterion.gd`:

```gdscript
func _context(occupied: Array[Vector2i], zones: Array[InfluenceZone]) -> PlacementContext:
	return PlacementContext.new(RealmState.new(RealmGeometry.new()), occupied, zones)


func test_a_single_hex_footprint_is_always_level() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/55 — only meaningful at size >= 2.
	assert_eq(
		LevelFootprintCriterion.new().failing_hexes(
			_context([Vector2i.ZERO] as Array[Vector2i], [] as Array[InfluenceZone])
		),
		[] as Array[Vector2i]
	)


func test_a_footprint_on_flat_ground_is_level() -> void:
	var occupied: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0)]
	assert_eq(
		LevelFootprintCriterion.new().failing_hexes(
			_context(occupied, [] as Array[InfluenceZone])
		),
		[] as Array[Vector2i]
	)


func test_a_footprint_crossing_a_step_fails_on_its_whole_footprint() -> void:
	# The criterion is a property of the footprint as a whole and belongs to no
	# single hex: https://github.com/snackpackgames/cosmicparade/issues/62
	var occupied: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0)]
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
	]
	assert_eq(
		LevelFootprintCriterion.new().failing_hexes(_context(occupied, zones)).size(), 2
	)
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm`
Expected: FAIL — `PlacementContext`, `PlacementCriterion`, `HeightCriterion` and
`LevelFootprintCriterion` do not exist.

- [ ] **Step 3: Implement the context, the base and the two criteria**

`PlacementContext extends RefCounted`, holding the three constructor arguments and delegating:
`has_hex`/`is_edge_hex` to `state.geometry`, `depth_at` to `Elevation.depth_at(hex, zones)`,
`occupant_at` to `state`. `zone_count` counts the zones of that domain which cover the hex.

Tighten `PlacementCriterion.failing_hexes`'s parameter to `PlacementContext` now that the type
exists. `HeightCriterion` compares `context.depth_at(hex)` against the authored range per occupied hex.
`LevelFootprintCriterion` returns `[]` when every occupied hex has the same depth and
`context.occupied.duplicate()` otherwise.

- [ ] **Step 4: Rebuild the class cache, then run the tests**

Run: `bash scripts/import.sh && bash scripts/test.sh realm`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/placement_context.gd realm/placement_context.gd.uid \
        realm/placement_criterion.gd \
        realm/height_criterion.gd realm/height_criterion.gd.uid \
        realm/level_footprint_criterion.gd realm/level_footprint_criterion.gd.uid \
        test/unit/realm/test_placement_context.gd \
        test/unit/realm/test_height_criterion.gd \
        test/unit/realm/test_level_footprint_criterion.gd
git commit -m "feat: add the placement context, the height and level-footprint criteria"
```

---

### Task 3.2 — Domain influence, clearance and board position

**Files:**
- Create: `realm/domain_influence_criterion.gd`
- Create: `realm/clearance_criterion.gd`
- Create: `realm/board_position_criterion.gd`
- Test: `test/unit/realm/test_domain_influence_criterion.gd`
- Test: `test/unit/realm/test_clearance_criterion.gd`
- Test: `test/unit/realm/test_board_position_criterion.gd`

**Interfaces:**
- Consumes: `PlacementContext`, `PlacementCriterion` (Task 3.1).
- Produces: `DomainInfluenceCriterion` with `domain: Domain.Kind`, `minimum: int`;
  `ClearanceCriterion` with `distance: int`;
  `BoardPositionCriterion` with `require_edge: bool`

**Domain criteria are counts, and the piece counts itself**
([decided](https://github.com/snackpackgames/cosmicparade/issues/55)) — the candidate's own zone
is in the context's zones, so `Forest ≥ 2` means "a Forest neighbour" and, since
`depth = zones − 1`, also "Forest ground raised here". `describe()` reads
`"Forest ≥ 2"`, built from `Domain.Kind.keys()`, because that string is the one
[#62](https://github.com/snackpackgames/cosmicparade/issues/62) puts in front of the player.

**Clearance is the placing piece's own condition**, which is the only reason it survives
[#30](https://github.com/snackpackgames/cosmicparade/issues/30)'s off-screen-refusal objection:
the blocking hexes are within `distance` of the cursor and are returned so they can be marked.
The piece's own hexes are excluded, and **off-board hexes count as clear** — off-board means
nothing is there.

**Board position drifts, and nothing re-checks it**
([decided](https://github.com/snackpackgames/cosmicparade/issues/55)). An edge hex is a board hex
with at least one absent neighbour; a wing can make it interior later, which is accepted.

- [ ] **Step 1: Write the failing tests**

`test/unit/realm/test_domain_influence_criterion.gd`:

```gdscript
func test_a_minimum_of_two_refuses_a_hex_the_piece_only_covers_itself() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/55 — Forest >= 2 is
	# "a Forest neighbour", because the piece's own zone is one of the two.
	var criterion := DomainInfluenceCriterion.new()
	criterion.domain = Domain.Kind.FOREST
	criterion.minimum = 2
	var own: Array[InfluenceZone] = [InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO])]
	var context := PlacementContext.new(
		RealmState.new(RealmGeometry.new()), [Vector2i.ZERO] as Array[Vector2i], own
	)
	assert_eq(criterion.failing_hexes(context), [Vector2i.ZERO] as Array[Vector2i])


func test_a_second_zone_of_the_same_domain_satisfies_it() -> void:
	var criterion := DomainInfluenceCriterion.new()
	criterion.domain = Domain.Kind.FOREST
	criterion.minimum = 2
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
	]
	var context := PlacementContext.new(
		RealmState.new(RealmGeometry.new()), [Vector2i.ZERO] as Array[Vector2i], zones
	)
	assert_eq(criterion.failing_hexes(context), [] as Array[Vector2i])


func test_another_domain_does_not_count() -> void:
	var criterion := DomainInfluenceCriterion.new()
	criterion.domain = Domain.Kind.FOREST
	criterion.minimum = 1
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
	]
	var context := PlacementContext.new(
		RealmState.new(RealmGeometry.new()), [Vector2i.ZERO] as Array[Vector2i], zones
	)
	assert_eq(criterion.failing_hexes(context).size(), 1)


func test_it_must_hold_on_every_hex_of_the_footprint() -> void:
	var criterion := DomainInfluenceCriterion.new()
	criterion.domain = Domain.Kind.FOREST
	criterion.minimum = 1
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
	]
	var context := PlacementContext.new(
		RealmState.new(RealmGeometry.new()),
		[Vector2i.ZERO, Vector2i(1, 0)] as Array[Vector2i],
		zones
	)
	assert_eq(criterion.failing_hexes(context), [Vector2i(1, 0)] as Array[Vector2i])


func test_it_describes_itself_as_the_player_reads_it() -> void:
	var criterion := DomainInfluenceCriterion.new()
	criterion.domain = Domain.Kind.FOREST
	criterion.minimum = 2
	assert_eq(criterion.describe(), "Forest >= 2")
```

`test/unit/realm/test_clearance_criterion.gd`:

```gdscript
func _context(occupied: Array[Vector2i], state: RealmState) -> PlacementContext:
	return PlacementContext.new(state, occupied, [] as Array[InfluenceZone])


func test_clearance_passes_on_an_empty_board() -> void:
	var criterion := ClearanceCriterion.new()
	criterion.distance = 1
	assert_eq(
		criterion.failing_hexes(
			_context([Vector2i.ZERO] as Array[Vector2i], RealmState.new(RealmGeometry.new()))
		),
		[] as Array[Vector2i]
	)


func test_clearance_returns_the_blocking_hexes_so_they_can_be_marked() -> void:
	var state := RealmState.new(RealmGeometry.new())
	state.place(_stool_at(Vector2i(1, 0)))
	var criterion := ClearanceCriterion.new()
	criterion.distance = 1
	assert_eq(
		criterion.failing_hexes(_context([Vector2i.ZERO] as Array[Vector2i], state)),
		[Vector2i(1, 0)] as Array[Vector2i]
	)


func test_a_piece_two_hexes_away_does_not_break_clearance_of_one() -> void:
	var state := RealmState.new(RealmGeometry.new())
	state.place(_stool_at(Vector2i(2, 0)))
	var criterion := ClearanceCriterion.new()
	criterion.distance = 1
	assert_eq(
		criterion.failing_hexes(_context([Vector2i.ZERO] as Array[Vector2i], state)),
		[] as Array[Vector2i]
	)


func test_the_pieces_own_hexes_never_break_its_own_clearance() -> void:
	var criterion := ClearanceCriterion.new()
	criterion.distance = 1
	var occupied: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0)]
	assert_eq(
		criterion.failing_hexes(_context(occupied, RealmState.new(RealmGeometry.new()))),
		[] as Array[Vector2i]
	)


# Review Focus 4: off-board means nothing is there.
func test_off_board_hexes_count_as_clear() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/55
	var criterion := ClearanceCriterion.new()
	criterion.distance = 2
	assert_eq(
		criterion.failing_hexes(
			_context([Vector2i(3, 0)] as Array[Vector2i], RealmState.new(RealmGeometry.new()))
		),
		[] as Array[Vector2i]
	)
```

`test/unit/realm/test_board_position_criterion.gd`:

```gdscript
func _context(occupied: Array[Vector2i]) -> PlacementContext:
	return PlacementContext.new(
		RealmState.new(RealmGeometry.new()), occupied, [] as Array[InfluenceZone]
	)


func test_requiring_the_edge_passes_on_the_rim_and_fails_in_the_middle() -> void:
	var criterion := BoardPositionCriterion.new()
	criterion.require_edge = true
	assert_eq(criterion.failing_hexes(_context([Vector2i(3, 0)] as Array[Vector2i])), [])
	assert_eq(
		criterion.failing_hexes(_context([Vector2i.ZERO] as Array[Vector2i])),
		[Vector2i.ZERO] as Array[Vector2i]
	)


func test_requiring_the_interior_is_the_same_test_inverted() -> void:
	var criterion := BoardPositionCriterion.new()
	criterion.require_edge = false
	assert_eq(criterion.failing_hexes(_context([Vector2i.ZERO] as Array[Vector2i])), [])
	assert_eq(
		criterion.failing_hexes(_context([Vector2i(3, 0)] as Array[Vector2i])).size(), 1
	)


func test_every_hex_of_the_footprint_must_satisfy_it() -> void:
	var criterion := BoardPositionCriterion.new()
	criterion.require_edge = true
	var occupied: Array[Vector2i] = [Vector2i(3, 0), Vector2i(2, 0)]
	assert_eq(criterion.failing_hexes(_context(occupied)), [Vector2i(2, 0)] as Array[Vector2i])
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm`
Expected: FAIL — the three criteria do not exist.

- [ ] **Step 3: Implement the three criteria**

Each `extends PlacementCriterion` with its own `@export`s and nothing shared beyond the base.
`ClearanceCriterion` walks `HexCoordinates.disc(hex, distance)` for every occupied hex, skips the
occupied set itself, and collects hexes whose `context.occupant_at()` is not null.
`BoardPositionCriterion` compares `context.is_edge_hex(hex)` against `require_edge`.
`DomainInfluenceCriterion.describe()` returns `"%s >= %d"` with the domain's enum key capitalised.

- [ ] **Step 4: Rebuild the class cache, then run the tests**

Run: `bash scripts/import.sh && bash scripts/test.sh realm`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/domain_influence_criterion.gd realm/domain_influence_criterion.gd.uid \
        realm/clearance_criterion.gd realm/clearance_criterion.gd.uid \
        realm/board_position_criterion.gd realm/board_position_criterion.gd.uid \
        test/unit/realm/test_domain_influence_criterion.gd \
        test/unit/realm/test_clearance_criterion.gd \
        test/unit/realm/test_board_position_criterion.gd
git commit -m "feat: add the domain influence, clearance and board position criteria"
```

---

### Task 3.3 — The verdict on a target

**Files:**
- Create: `realm/placement_verdict.gd`
- Create: `realm/placement_rules.gd`
- Modify: `data/realm/furniture/standing_stone.tres`
- Modify: `data/realm/furniture/fern_bench.tres`
- Test: `test/unit/realm/test_placement_rules.gd`
- Modify: `test/unit/realm/test_furniture.gd`

**Interfaces:**
- Consumes: `Footprint.occupied` (Task 2.1), `InfluenceZone.project` (Task 2.2), `RealmState`,
  `Furniture` (Task 2.3), `PlacementContext`, the five criteria (Tasks 3.1–3.2).
- Produces: `PlacementVerdict.new(allowed: bool, failing_hexes: Array[Vector2i],
  failing_criteria: Array[PlacementCriterion])`, `verdict.allowed`, `verdict.failing_hexes`,
  `verdict.failing_criteria`;
  `PlacementRules.verdict(piece: Furniture, orientation: int, target: Vector2i,
  grab_offset: Vector2i, state: RealmState) -> PlacementVerdict`,
  `PlacementRules.zone_for(piece, orientation, target, grab_offset) -> InfluenceZone`

Two gates, in order:

1. **Siting.** Every occupied hex must be a board hex — they are board hexes *by definition*
   ([#59](https://github.com/snackpackgames/cosmicparade/issues/59)) — and unoccupied, because
   footprints never overlap ([#51](https://github.com/snackpackgames/cosmicparade/issues/51)). A
   siting failure returns the offending hexes and **names no criterion**: an off-board or
   occupied hex explains itself, and the criteria are only meaningful on a legally sited
   footprint, which is also why they are not evaluated in that case.
2. **Criteria.** Every criterion, each against every occupied hex, all must pass — one
   quantifier, no `OR` ([#55](https://github.com/snackpackgames/cosmicparade/issues/55)). The
   union of their hexes and the list of the criteria that failed come back **unpaired**
   ([#62](https://github.com/snackpackgames/cosmicparade/issues/62)).

The context's zones are `state.zones()` plus the candidate's own projected zone, which is the
whole of [#41](https://github.com/snackpackgames/cosmicparade/issues/41) in one line.

This task also authors the criteria onto two placeholder pieces, so the data path is exercised:
`standing_stone` gets `BoardPositionCriterion(require_edge = true)`, and `fern_bench` gets
`DomainInfluenceCriterion(FOREST, 2)` and `LevelFootprintCriterion`, authored **inline as
sub-resources** in the `.tres` rather than as shared files
([decided](https://github.com/snackpackgames/cosmicparade/issues/55) — a criterion has no
identity apart from the piece holding it).

- [ ] **Step 1: Write the failing tests**

```gdscript
extends GutTest
## The verdict on a target: siting first, then every criterion on every hex.

func _state() -> RealmState:
	return RealmState.new(RealmGeometry.new())


func _stool() -> Furniture:
	return load("res://data/realm/furniture/mushroom_stool.tres")


func _bench() -> Furniture:
	return load("res://data/realm/furniture/fern_bench.tres")


func test_an_unencumbered_piece_is_allowed_on_an_empty_board() -> void:
	var verdict := PlacementRules.verdict(_stool(), 0, Vector2i.ZERO, Vector2i.ZERO, _state())
	assert_true(verdict.allowed)
	assert_eq(verdict.failing_hexes, [] as Array[Vector2i])
	assert_eq(verdict.failing_criteria, [])


# Review Focus 1: occupied hexes are board hexes by definition.
func test_a_footprint_hanging_off_the_board_is_refused() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/59
	var verdict := PlacementRules.verdict(_bench(), 0, Vector2i(3, 0), Vector2i(1, 0), _state())
	assert_false(verdict.allowed)
	assert_true(verdict.failing_hexes.has(Vector2i(4, 0)), "the hex in the void is marked")
	assert_eq(verdict.failing_criteria, [], "no criterion is named for a siting failure")


func test_a_footprint_overlapping_another_piece_is_refused() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/51 — footprints never overlap.
	var state := _state()
	state.place(FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	var verdict := PlacementRules.verdict(_stool(), 0, Vector2i.ZERO, Vector2i.ZERO, state)
	assert_false(verdict.allowed)
	assert_eq(verdict.failing_hexes, [Vector2i.ZERO] as Array[Vector2i])


func test_influence_may_overlap_even_though_footprints_may_not() -> void:
	var state := _state()
	state.place(FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	assert_true(
		PlacementRules.verdict(_stool(), 0, Vector2i(1, 0), Vector2i.ZERO, state).allowed
	)


func test_a_failing_criterion_is_named_and_its_hexes_are_marked() -> void:
	# fern_bench authors Forest >= 2, which an empty board cannot satisfy.
	var verdict := PlacementRules.verdict(_bench(), 0, Vector2i.ZERO, Vector2i(1, 0), _state())
	assert_false(verdict.allowed)
	assert_eq(verdict.failing_hexes.size(), 3, "every hex of the footprint is short")
	assert_eq(verdict.failing_criteria.size(), 1)
	assert_eq(verdict.failing_criteria[0].describe(), "Forest >= 2")


func test_a_criterion_reads_the_board_as_it_will_be_with_the_piece_on_it() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/41 — two flanking
	# Forest stools plus the bench's own zone make Forest >= 2 on all three hexes,
	# and all three sit at depth 1, so level footprint passes too.
	var state := _state()
	_flank_the_centre_line_with_forest(state)
	assert_true(
		PlacementRules.verdict(_bench(), 0, Vector2i.ZERO, Vector2i(1, 0), state).allowed
	)


func test_rotation_is_a_second_axis_of_escape_from_a_refusal() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/56 — turning changes
	# the occupied set, so one orientation can be refused and another allowed.
	var state := _state()
	state.place(FurniturePlacement.new(_stool(), 0, [Vector2i(2, 0)] as Array[Vector2i]))
	var blocked := PlacementRules.verdict(
		_bench(), 0, Vector2i(1, 0), Vector2i(1, 0), state
	)
	var turned := PlacementRules.verdict(
		_bench(), 1, Vector2i(1, 0), Vector2i(1, 0), state
	)
	assert_false(blocked.allowed, "straight along the row it collides")
	assert_true(turned.allowed or not turned.failing_hexes.has(Vector2i(2, 0)))


func test_several_failing_criteria_are_all_named_at_once() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/62 — never one at a time.
	var piece := Furniture.new()
	piece.shape = Footprint.Shape.PAIR
	piece.domain = Domain.Kind.GALE
	piece.zone_radius = 1
	var influence := DomainInfluenceCriterion.new()
	influence.domain = Domain.Kind.FLAME
	influence.minimum = 1
	var height := HeightCriterion.new()
	height.min_depth = 2
	piece.criteria = [influence, height] as Array[PlacementCriterion]
	var verdict := PlacementRules.verdict(piece, 0, Vector2i.ZERO, Vector2i.ZERO, _state())
	assert_eq(verdict.failing_criteria.size(), 2)


func test_zone_for_grows_the_candidate_zone_from_its_occupied_hexes() -> void:
	assert_eq(
		PlacementRules.zone_for(_bench(), 0, Vector2i.ZERO, Vector2i(1, 0)).hex_count(), 13
	)
```

Add to `test/unit/realm/test_furniture.gd`:

```gdscript
func test_no_authored_piece_requires_one_zone_of_its_own_domain() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/55 — "domain X >= 1"
	# where X is the piece's own domain is always true, because the piece's own
	# zone covers all of its own hexes. Harmless, but a no-op.
	for file: String in DirAccess.get_files_at("res://data/realm/furniture"):
		var piece: Furniture = load("res://data/realm/furniture/%s" % file.trim_suffix(".remap"))
		for criterion: PlacementCriterion in piece.criteria:
			if criterion is DomainInfluenceCriterion:
				var influence := criterion as DomainInfluenceCriterion
				assert_false(
					influence.domain == piece.domain and influence.minimum <= 1,
					"%s authors a no-op criterion" % file
				)
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm`
Expected: FAIL — `PlacementRules` does not exist.

- [ ] **Step 3: Implement `PlacementVerdict` and `PlacementRules`, then author the criteria**

Both `extends RefCounted`; `PlacementRules` is statics only. `verdict()` returns early on a
siting failure with the offending hexes and an empty criteria list. Author the criteria into the
two `.tres` as inline sub-resources.

- [ ] **Step 4: Rebuild the class cache, then run the suite and the linter**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/placement_verdict.gd realm/placement_verdict.gd.uid \
        realm/placement_rules.gd realm/placement_rules.gd.uid \
        data/realm/furniture test/unit/realm/test_placement_rules.gd \
        test/unit/realm/test_furniture.gd
git commit -m "feat: judge a target against siting and every criterion"
```

---

## Phase 4 — The carry verb

### Task 4.1 — One targeted hex, every input

**Files:**
- Modify: `project.godot`
- Create: `realm/hex_cursor.gd`
- Test: `test/unit/realm/test_hex_cursor.gd`
- Modify: `test/unit/test_project_settings.gd`

**Interfaces:**
- Consumes: `HexCoordinates.DIRECTIONS`, `HexCoordinates.center_of`, `HexCoordinates.neighbors`
  (Task 1.1).
- Produces: InputMap actions `realm_lift_or_place`, `realm_cancel`, `realm_rotate`,
  `realm_target_left`, `realm_target_right`, `realm_target_forward`, `realm_target_back`;
  `HexCursor extends Node3D` with `signal targeted_hex_changed(hex: Vector2i)`,
  `cursor.targeted_hex: Vector2i`, `cursor.aim_at(hex: Vector2i) -> void`,
  `cursor.step(push: Vector2) -> void`,
  `HexCursor.nearest_direction(push: Vector2) -> Vector2i`,
  `cursor.hex_under_pointer(camera: Camera3D, screen_point: Vector2) -> Variant`

**The verb reads one value** ([decided](https://github.com/snackpackgames/cosmicparade/issues/54)),
so the cursor is the only thing that knows how a device moves it, and lift/place/cancel/rotate are
InputMap actions rather than mouse events. Gamepad is first-class now, not an M7 port.

- **Mouse** warps the value: a raycast against `realm_space` (bit 1, `collision_mask = 1`) picks a
  hex directly. The mask deliberately omits `furniture` so a piece standing on a hex does not
  shadow it — what is on a hex is a question for `RealmState.occupant_at()`, not for the ray.
- **Gamepad / keyboard** steps it to the neighbour nearest the pushed direction. A flat-top hex
  has six, so the push is compared against the six directions' world offsets
  (`HexCoordinates.center_of(direction)` flattened to XZ) and the closest by angle wins. A
  free-floating virtual pointer was rejected outright — it never snaps to spaces.

Action bindings: `realm_lift_or_place` ← left mouse button, `Space`, gamepad A;
`realm_cancel` ← right mouse button, `Escape`, gamepad B; `realm_rotate` ← `R`, mouse wheel up,
gamepad right shoulder; the four `realm_target_*` ← arrow keys, `WASD`, left stick axes.

- [ ] **Step 1: Write the failing tests**

`test/unit/realm/test_hex_cursor.gd`:

```gdscript
func test_the_cursor_starts_on_the_origin() -> void:
	assert_eq(HexCursor.new().targeted_hex, Vector2i.ZERO)


func test_aiming_moves_the_target_and_announces_it() -> void:
	var cursor: HexCursor = add_child_autofree(HexCursor.new())
	watch_signals(cursor)
	cursor.aim_at(Vector2i(2, -1))
	assert_eq(cursor.targeted_hex, Vector2i(2, -1))
	assert_signal_emitted_with_parameters(cursor, "targeted_hex_changed", [Vector2i(2, -1)])


func test_aiming_at_the_same_hex_announces_nothing() -> void:
	var cursor: HexCursor = add_child_autofree(HexCursor.new())
	cursor.aim_at(Vector2i(2, -1))
	watch_signals(cursor)
	cursor.aim_at(Vector2i(2, -1))
	assert_signal_not_emitted(cursor, "targeted_hex_changed")


func test_every_push_resolves_to_one_of_the_six_directions() -> void:
	for degrees in 360:
		var push := Vector2.RIGHT.rotated(deg_to_rad(degrees))
		assert_true(
			HexCoordinates.DIRECTIONS.has(HexCursor.nearest_direction(push)),
			"%d degrees" % degrees
		)


func test_a_push_straight_at_a_direction_picks_that_direction() -> void:
	for direction: Vector2i in HexCoordinates.DIRECTIONS:
		var center := HexCoordinates.center_of(direction)
		assert_eq(HexCursor.nearest_direction(Vector2(center.x, center.z)), direction)


func test_a_zero_push_does_not_move_the_target() -> void:
	var cursor: HexCursor = add_child_autofree(HexCursor.new())
	cursor.step(Vector2.ZERO)
	assert_eq(cursor.targeted_hex, Vector2i.ZERO)


func test_stepping_moves_one_hex_at_a_time() -> void:
	var cursor: HexCursor = add_child_autofree(HexCursor.new())
	var center := HexCoordinates.center_of(Vector2i(1, 0))
	cursor.step(Vector2(center.x, center.z))
	assert_eq(cursor.targeted_hex, Vector2i(1, 0))
	assert_eq(HexCoordinates.distance(Vector2i.ZERO, cursor.targeted_hex), 1)
```

Add to `test/unit/test_project_settings.gd`:

```gdscript
const EXPECTED_REALM_ACTIONS := [
	"realm_lift_or_place", "realm_cancel", "realm_rotate",
	"realm_target_left", "realm_target_right", "realm_target_forward", "realm_target_back",
]


func test_the_carry_verb_is_input_map_actions_not_mouse_events() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/54 — one abstraction,
	# so mouse and gamepad are the same path.
	for action: String in EXPECTED_REALM_ACTIONS:
		assert_true(
			ProjectSettings.has_setting("input/%s" % action), "%s should be bound" % action
		)
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm/test_hex_cursor.gd`
Expected: FAIL — `HexCursor` does not exist.

- [ ] **Step 3: Add the actions to `project.godot` and implement `HexCursor`**

Add an `[input]` section with the seven actions and the bindings above. `HexCursor extends
Node3D` keeps `targeted_hex`, emits only on a change, and positions itself at
`HexCoordinates.center_of(targeted_hex)` so the view has something to follow.
`nearest_direction` is a static comparing the push's angle against the six directions' XZ
offsets. `hex_under_pointer` builds a `PhysicsRayQueryParameters3D` from the camera's projection
with `collision_mask = 1`, and returns the hit collider's `hex` or `null`.

- [ ] **Step 4: Run the tests**

Run: `bash scripts/test.sh realm/test_hex_cursor.gd && bash scripts/test.sh test_project_settings.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add project.godot realm/hex_cursor.gd realm/hex_cursor.gd.uid \
        test/unit/realm/test_hex_cursor.gd test/unit/test_project_settings.gd
git commit -m "feat: add the realm input actions and the hex cursor"
```

---

### Task 4.2 — The carry state machine

**Files:**
- Create: `realm/carried.gd`
- Create: `realm/carried_furniture.gd`
- Create: `realm/carry.gd`
- Test: `test/unit/realm/test_carried_furniture.gd`
- Test: `test/unit/realm/test_carry.gd`

**Interfaces:**
- Consumes: `PlacementRules`, `PlacementVerdict` (Task 3.3), `RealmState`, `FurniturePlacement`
  (Task 2.3), `Footprint` (Task 2.1).
- Produces: `Carried extends RefCounted` with `hexes_at(target, orientation) ->
  Array[Vector2i]`, `orientation_count() -> int`, `verdict_at(target, orientation, state) ->
  PlacementVerdict`, `zone_at(target, orientation) -> InfluenceZone`, `detach(state) -> void`,
  `commit(target, orientation, state) -> void`, `restore(state) -> void`,
  `describe_requirements() -> Array[PlacementCriterion]`;
  `CarriedFurniture.new(furniture: Furniture, grab_offset: Vector2i,
  origin: FurniturePlacement)`;
  `Carry extends Node` with `signal lifted(carried: Carried)`,
  `signal aimed(hexes: Array[Vector2i], verdict: PlacementVerdict)`,
  `signal placed(hexes: Array[Vector2i])`, `signal cancelled()`,
  `carry.configure(state: RealmState) -> void`, `carry.carried: Carried`,
  `carry.orientation: int`, `carry.target: Vector2i`, `carry.is_carrying() -> bool`,
  `carry.lift(thing: Carried, at: Vector2i) -> void`, `carry.aim(hex: Vector2i) -> void`,
  `carry.rotate_once() -> void`, `carry.place() -> bool`, `carry.cancel() -> void`,
  `carry.verdict() -> PlacementVerdict`

**`Carried` is the seam that stops wings being a second verb.** Everything the state machine
needs from the thing in hand is on this interface, so Task 6.1 adds `CarriedWing` and changes
nothing here ([decided](https://github.com/snackpackgames/cosmicparade/issues/54) — "it is not a
second verb to design").

The rules, each one decided:

- **Lifting vacates the board.** `detach` removes the origin placement from the state, so the
  piece's old influence *and* its old footprint are gone for the whole carry
  ([#54](https://github.com/snackpackgames/cosmicparade/issues/54)). This is what lets a
  straight-three shift one hex along its own axis, and what makes the preview honest about the
  ground the piece was holding up.
- **Cancel restores the origin hex and the original orientation**, exactly
  ([#54](https://github.com/snackpackgames/cosmicparade/issues/54)), or returns the piece to
  inventory if that is where it came from. The origin is guaranteed legal, because the board was
  legal before the lift — which is the mechanism by which
  [#41](https://github.com/snackpackgames/cosmicparade/issues/41)'s "refusals are always
  escapable" holds.
- **Place is inert while refused** and returns `false`; the player keeps carrying
  ([#54](https://github.com/snackpackgames/cosmicparade/issues/54)). There is no error state.
- **`rotate_once()` steps `(orientation + 1) % carried.orientation_count()`.** Furniture answers
  6 ([#56](https://github.com/snackpackgames/cosmicparade/issues/56)); a wing answers its distinct
  count ([#61](https://github.com/snackpackgames/cosmicparade/issues/61)). Steps `0..n-1` are
  always the distinct ones, because every stabiliser in a six-fold cyclic group is generated by
  one of 1, 2, 3 or 6.
- **Orientation is sticky for a piece from inventory** and the piece's own when lifted from the
  board ([#56](https://github.com/snackpackgames/cosmicparade/issues/56)). The remembered value is
  carry state and is never written to the board.
- **Rotate while idle auto-lifts a hovered piece, turned one step** — furniture only; see
  *Two rulings derived from the map*, ruling 2. The controller in Task 4.4 owns that gesture;
  `Carry.lift` plus `rotate_once` is all it needs.

- [ ] **Step 1: Write the failing tests**

`test/unit/realm/test_carried_furniture.gd`:

```gdscript
func test_the_grabbed_hex_stays_under_the_target() -> void:
	var carried := CarriedFurniture.new(_bench(), Vector2i(1, 0), null)
	for orientation in 6:
		assert_true(carried.hexes_at(Vector2i(1, -1), orientation).has(Vector2i(1, -1)))


func test_furniture_always_offers_six_orientations() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/56 — the art has a
	# facing even where the footprint has no asymmetry.
	assert_eq(CarriedFurniture.new(_stool(), Vector2i.ZERO, null).orientation_count(), 6)


func test_detaching_a_piece_lifted_from_the_board_vacates_its_hexes() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var origin := FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i])
	state.place(origin)
	CarriedFurniture.new(_stool(), Vector2i.ZERO, origin).detach(state)
	assert_null(state.occupant_at(Vector2i.ZERO))
	assert_eq(state.zones().size(), 0, "its influence is gone for the whole carry")


func test_restoring_puts_the_origin_placement_back_unchanged() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var origin := FurniturePlacement.new(_stool(), 3, [Vector2i.ZERO] as Array[Vector2i])
	state.place(origin)
	var carried := CarriedFurniture.new(_stool(), Vector2i.ZERO, origin)
	carried.detach(state)
	carried.restore(state)
	assert_eq(state.occupant_at(Vector2i.ZERO), origin)
	assert_eq(state.occupant_at(Vector2i.ZERO).orientation, 3)


func test_committing_places_a_piece_at_the_target_with_the_carried_orientation() -> void:
	var state := RealmState.new(RealmGeometry.new())
	CarriedFurniture.new(_stool(), Vector2i.ZERO, null).commit(Vector2i(1, 0), 4, state)
	assert_eq(state.placements.size(), 1)
	assert_eq(state.occupant_at(Vector2i(1, 0)).orientation, 4)
```

`test/unit/realm/test_carry.gd`:

```gdscript
func _carry(state: RealmState) -> Carry:
	var carry: Carry = add_child_autofree(Carry.new())
	carry.configure(state)
	return carry


func test_a_fresh_carry_is_idle() -> void:
	var carry := _carry(RealmState.new(RealmGeometry.new()))
	assert_false(carry.is_carrying())
	assert_null(carry.carried)


func test_lifting_enters_the_carry_and_announces_the_first_target() -> void:
	var carry := _carry(RealmState.new(RealmGeometry.new()))
	watch_signals(carry)
	carry.lift(CarriedFurniture.new(_stool(), Vector2i.ZERO, null), Vector2i.ZERO)
	assert_true(carry.is_carrying())
	assert_signal_emitted(carry, "lifted")
	assert_signal_emitted(carry, "aimed")


func test_aiming_re_evaluates_validity_on_every_target() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/54 — valid/refused is a
	# property of the current target, not a state of the verb.
	var state := RealmState.new(RealmGeometry.new())
	var carry := _carry(state)
	carry.lift(CarriedFurniture.new(_bench(), Vector2i(1, 0), null), Vector2i.ZERO)
	carry.aim(Vector2i(3, 0))
	assert_false(carry.verdict().allowed, "the far end hangs off the board")
	carry.aim(Vector2i.ZERO)
	assert_eq(carry.verdict().failing_hexes.size(), 3, "sited, but Forest >= 2 is short")


func test_placing_a_refused_target_is_inert_and_the_player_keeps_carrying() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var carry := _carry(state)
	carry.lift(CarriedFurniture.new(_bench(), Vector2i(1, 0), null), Vector2i(3, 0))
	assert_false(carry.place())
	assert_true(carry.is_carrying())
	assert_eq(state.placements.size(), 0)


func test_placing_an_allowed_target_commits_and_returns_to_idle() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var carry := _carry(state)
	watch_signals(carry)
	carry.lift(CarriedFurniture.new(_stool(), Vector2i.ZERO, null), Vector2i(1, 0))
	assert_true(carry.place())
	assert_false(carry.is_carrying())
	assert_eq(state.placements.size(), 1)
	assert_signal_emitted(carry, "placed")


func test_cancel_returns_the_piece_to_its_origin_hex_and_orientation() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var origin := FurniturePlacement.new(_stool(), 2, [Vector2i.ZERO] as Array[Vector2i])
	state.place(origin)
	var carry := _carry(state)
	carry.lift(CarriedFurniture.new(_stool(), Vector2i.ZERO, origin), Vector2i.ZERO)
	carry.aim(Vector2i(2, 0))
	carry.rotate_once()
	carry.cancel()
	assert_false(carry.is_carrying())
	assert_eq(state.occupant_at(Vector2i.ZERO), origin)
	assert_eq(state.occupant_at(Vector2i.ZERO).orientation, 2)


func test_a_carried_piece_occupies_nothing() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var origin := FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i])
	state.place(origin)
	var carry := _carry(state)
	carry.lift(CarriedFurniture.new(_stool(), Vector2i.ZERO, origin), Vector2i.ZERO)
	assert_null(state.occupant_at(Vector2i.ZERO))


# Review Focus 2: a carried piece occupies nothing, including its own old hexes.
func test_a_straight_three_can_shift_one_hex_along_its_own_axis() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/54
	var state := RealmState.new(RealmGeometry.new())
	state.place(FurniturePlacement.new(_stool(), 0, [Vector2i(0, 1)] as Array[Vector2i]))
	var hexes := Footprint.occupied(Footprint.Shape.STRAIGHT, 0, Vector2i.ZERO, Vector2i(1, 0))
	var origin := FurniturePlacement.new(_bench(), 0, hexes)
	state.place(origin)
	var carry := _carry(state)
	carry.lift(CarriedFurniture.new(_bench(), Vector2i(1, 0), origin), Vector2i.ZERO)
	carry.aim(Vector2i(1, 0))
	assert_false(
		carry.verdict().failing_hexes.has(Vector2i.ZERO), "it must not collide with itself"
	)


func test_rotating_in_place_does_not_collide_with_itself() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var hexes := Footprint.occupied(Footprint.Shape.STRAIGHT, 0, Vector2i.ZERO, Vector2i(1, 0))
	var origin := FurniturePlacement.new(_bench(), 0, hexes)
	state.place(origin)
	var carry := _carry(state)
	carry.lift(CarriedFurniture.new(_bench(), Vector2i(1, 0), origin), Vector2i.ZERO)
	for orientation in 6:
		carry.rotate_once()
		assert_eq(carry.verdict().failing_hexes.size(), 3, "short on Forest, never blocked")


func test_rotation_wraps_through_the_carried_things_orientation_count() -> void:
	var carry := _carry(RealmState.new(RealmGeometry.new()))
	carry.lift(CarriedFurniture.new(_stool(), Vector2i.ZERO, null), Vector2i.ZERO)
	for _step in 6:
		carry.rotate_once()
	assert_eq(carry.orientation, 0)


func test_a_piece_from_inventory_arrives_at_the_last_orientation_placed() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/56 — sticky, and carry
	# state rather than board state.
	var state := RealmState.new(RealmGeometry.new())
	var carry := _carry(state)
	carry.lift(CarriedFurniture.new(_stool(), Vector2i.ZERO, null), Vector2i.ZERO)
	carry.rotate_once()
	carry.rotate_once()
	assert_true(carry.place())
	carry.lift(CarriedFurniture.new(_stool(), Vector2i.ZERO, null), Vector2i(1, 0))
	assert_eq(carry.orientation, 2)


func test_a_piece_lifted_from_the_board_keeps_its_own_orientation() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var origin := FurniturePlacement.new(_stool(), 5, [Vector2i.ZERO] as Array[Vector2i])
	state.place(origin)
	var carry := _carry(state)
	carry.lift(CarriedFurniture.new(_stool(), Vector2i.ZERO, origin), Vector2i.ZERO)
	assert_eq(carry.orientation, 5)
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm`
Expected: FAIL — `Carried`, `CarriedFurniture` and `Carry` do not exist.

- [ ] **Step 3: Implement the three scripts**

`Carried` declares every method with an empty body and a doc comment naming the two subclasses.
`CarriedFurniture` delegates `hexes_at`, `verdict_at` and `zone_at` to `Footprint` and
`PlacementRules` with its own `grab_offset`, and `describe_requirements()` returns
`furniture.criteria`. `Carry extends Node` holds `carried`, `orientation`, `target` and the
sticky `_last_placed_orientation`, caches the current `PlacementVerdict` on every `aim`/`rotate`,
and emits `aimed` with the occupied hexes and that verdict.

- [ ] **Step 4: Rebuild the class cache, then run the suite and the linter**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/carried.gd realm/carried.gd.uid \
        realm/carried_furniture.gd realm/carried_furniture.gd.uid \
        realm/carry.gd realm/carry.gd.uid \
        test/unit/realm/test_carried_furniture.gd test/unit/realm/test_carry.gd
git commit -m "feat: add the carry state machine"
```

---

### Task 4.3 — Furniture on the board, and the ghost in hand

**Files:**
- Create: `realm/furniture_view.gd`
- Test: `test/unit/realm/test_furniture_view.gd`

**Interfaces:**
- Consumes: `RealmState`, `FurniturePlacement` (Task 2.3), `HexCoordinates.center_of`,
  `HexCoordinates.corner_offsets` (exist), `Elevation.height_at` (exists), `BoardMaterial`
  (exists).
- Produces: `FurnitureView extends Node3D` with
  `view.show_placements(placements: Array[FurniturePlacement], zones: Array[InfluenceZone])
  -> void`, `view.show_ghost(hexes: Array[Vector2i], allowed: bool,
  zones: Array[InfluenceZone]) -> void`, `view.clear_ghost() -> void`,
  `view.body_for(placement) -> StaticBody3D`

One `StaticBody3D` per placement on the **`furniture` layer, bit 2**
(`CLAUDE.md → 3D Physics Layers`), with a low prism per occupied hex sitting on that hex's top
face — `adr/0001` makes furniture a volume, and the placement verb needs something in the world
to look at. **Entirely placeholder geometry**, in the same spirit as `BoardMaterial`: the authored
models are art direction and on the map's *Out of scope*.

The ghost is the same geometry at the carried position, with no collision at all, so it is never
picked by the cursor's ray. `allowed` is passed in but only reaches the placeholder material's
tint — how a refusal *reads* is art.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_it_builds_one_body_per_placement() -> void:
	var view: FurnitureView = add_child_autofree(FurnitureView.new())
	var placement := FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i])
	view.show_placements([placement], [] as Array[InfluenceZone])
	assert_not_null(view.body_for(placement))


func test_a_body_sits_on_the_furniture_layer_and_detects_nothing() -> void:
	var view: FurnitureView = add_child_autofree(FurnitureView.new())
	var placement := FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i])
	view.show_placements([placement], [] as Array[InfluenceZone])
	assert_eq(view.body_for(placement).collision_layer, 2)


func test_a_body_rides_the_height_of_the_ground_under_it() -> void:
	var view: FurnitureView = add_child_autofree(FurnitureView.new())
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
	]
	var placement := FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i])
	view.show_placements([placement], zones)
	assert_almost_eq(
		view.body_for(placement).position.y, Elevation.height_for_depth(1), 0.0001
	)


func test_showing_a_new_set_of_placements_drops_the_old_bodies() -> void:
	var view: FurnitureView = add_child_autofree(FurnitureView.new())
	var placement := FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i])
	view.show_placements([placement], [] as Array[InfluenceZone])
	view.show_placements([], [] as Array[InfluenceZone])
	await wait_frames(1)
	assert_null(view.body_for(placement))


func test_the_ghost_has_no_collision_so_the_cursor_ray_passes_through_it() -> void:
	var view: FurnitureView = add_child_autofree(FurnitureView.new())
	view.show_ghost([Vector2i.ZERO] as Array[Vector2i], true, [] as Array[InfluenceZone])
	for child in view.get_children():
		if child is CollisionObject3D:
			assert_eq((child as CollisionObject3D).collision_layer, 0, "the ghost is not solid")


func test_clearing_the_ghost_leaves_the_placed_bodies_alone() -> void:
	var view: FurnitureView = add_child_autofree(FurnitureView.new())
	var placement := FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i])
	view.show_placements([placement], [] as Array[InfluenceZone])
	view.show_ghost([Vector2i(1, 0)] as Array[Vector2i], true, [] as Array[InfluenceZone])
	view.clear_ghost()
	await wait_frames(1)
	assert_not_null(view.body_for(placement))
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm/test_furniture_view.gd`
Expected: FAIL — `FurnitureView` does not exist.

- [ ] **Step 3: Implement `FurnitureView`**

`class_name FurnitureView extends Node3D`. Build a prism per occupied hex with `SurfaceTool`,
following `HexSpace._build_mesh()`'s approach but shorter and inset, and reuse
`BoardMaterial.create()` for the placeholder look with a different tint per state. Keep bodies in
a `Dictionary` keyed by placement so `body_for` is a lookup.

- [ ] **Step 4: Run the tests**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_furniture_view.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/furniture_view.gd realm/furniture_view.gd.uid \
        test/unit/realm/test_furniture_view.gd
git commit -m "feat: render placed furniture and the carried ghost"
```

---

### Task 4.4 — The realm scene: targeting, preview, commit

**Files:**
- Modify: `realm/realm.gd`
- Modify: `realm/realm.tscn`
- Test: `test/unit/realm/test_realm.gd`

**Interfaces:**
- Consumes: everything from Tasks 1.4, 3.3, 4.1, 4.2, 4.3.
- Produces: `Realm` with `realm.state: RealmState`, `realm.carry: Carry`,
  `realm.lift_from_inventory(piece: Furniture) -> void`,
  `realm.lift_under_cursor() -> void`, `realm.swell() -> void`,
  `signal piece_returned(piece: Furniture)`

This is where [#31](https://github.com/snackpackgames/cosmicparade/issues/31)'s preview finally
becomes buildable, and it is one path:

```
cursor.targeted_hex_changed → carry.aim(hex) → carry.aimed(hexes, verdict)
    → board.zones = state.zones() + [candidate zone]
    → board.rebuild(previous preview coordinates ∪ new ones)
    → view.show_ghost(hexes, verdict.allowed, board.zones)
```

**The terrain preview resolves on every target, valid or refused**
([decided](https://github.com/snackpackgames/cosmicparade/issues/54), upheld by
[#62](https://github.com/snackpackgames/cosmicparade/issues/62)) — one read path, so no flicker as
the cursor sweeps across a mix of legal and illegal hexes. `rebuild` is already a no-op for a hex
the board does not hold, so the off-board part of the previewed zone costs nothing.

**Commit is the only write** ([#31](https://github.com/snackpackgames/cosmicparade/issues/31)): on
`placed`, recompute `board.zones` from `state.zones()` alone and rebuild the committed delta. On
`cancelled`, the same, which is why nothing has to be undone.

The scene stays the **stub** it already declares itself to be: the camera, the lighting and the
pieces it hands the player are placeholders, and `lift_from_inventory` is the seam the real
inventory (`adr/0011`, out of scope) will attach to. `swell()` calls
`geometry.swell()`/`attach`, applies `board.set_hexes()` and rebuilds only the hexes that
arrived — the economy that pays for it is M1's third map. Bind both to debug-only actions in the
scene and say so in the script's doc comment.

- [ ] **Step 1: Write the failing tests**

```gdscript
extends GutTest
## The realm scene: one targeted hex in, a previewed board out.

const REALM_SCENE := preload("res://realm/realm.tscn")


func _realm() -> Node3D:
	var realm: Node3D = add_child_autofree(REALM_SCENE.instantiate())
	await wait_frames(1)
	return realm


func test_the_scene_boots_with_a_board_a_cursor_and_a_carry() -> void:
	var realm := await _realm()
	assert_eq(realm.state.geometry.hexes().size(), 37)
	assert_not_null(realm.carry)
	assert_false(realm.carry.is_carrying())


func test_aiming_while_carrying_previews_the_ground_the_target_would_make() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/31
	var realm := await _realm()
	realm.state.place(FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	realm.lift_from_inventory(_stool())
	realm.carry.aim(Vector2i(1, 0))
	assert_gt(
		realm.get_node("RealmBoard").hex_space(Vector2i.ZERO).top_height(), 0.0,
		"two Forest zones over the origin raise it while the piece is only targeted"
	)


func test_the_preview_resolves_on_a_refused_target_too() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/62 — one read path.
	var realm := await _realm()
	realm.state.place(FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	realm.lift_from_inventory(_stool())
	realm.carry.aim(Vector2i.ZERO)
	assert_false(realm.carry.verdict().allowed, "that hex is occupied")
	assert_gt(realm.get_node("RealmBoard").hex_space(Vector2i.ZERO).top_height(), 0.0)


func test_cancelling_puts_the_previewed_ground_back() -> void:
	var realm := await _realm()
	realm.lift_from_inventory(_stool())
	realm.carry.aim(Vector2i.ZERO)
	realm.carry.cancel()
	assert_almost_eq(
		realm.get_node("RealmBoard").hex_space(Vector2i.ZERO).top_height(), 0.0, 0.0001
	)


func test_placing_commits_the_piece_and_the_ground_it_raised() -> void:
	var realm := await _realm()
	realm.state.place(FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	realm.lift_from_inventory(_stool())
	realm.carry.aim(Vector2i(1, 0))
	assert_true(realm.carry.place())
	assert_eq(realm.state.placements.size(), 2)
	assert_gt(realm.get_node("RealmBoard").hex_space(Vector2i.ZERO).top_height(), 0.0)


func test_a_swell_adds_the_ring_and_its_spaces() -> void:
	var realm := await _realm()
	realm.swell()
	await wait_frames(1)
	assert_eq(realm.state.geometry.hexes().size(), 61)
	assert_eq(realm.get_node("RealmBoard").get_child_count(), 61)


func test_a_swell_raises_ground_under_influence_that_was_spilling_into_nothing() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/59 — the realm floods
	# into the space it just gained, with nothing newly placed.
	var realm := await _realm()
	for hex: Vector2i in [Vector2i(3, 0), Vector2i(3, -1)] as Array[Vector2i]:
		realm.state.place(FurniturePlacement.new(_stool(), 0, [hex] as Array[Vector2i]))
	realm.swell()
	await wait_frames(1)
	assert_gt(
		realm.get_node("RealmBoard").hex_space(Vector2i(4, -1)).top_height(), 0.0,
		"both rim pieces' zones already covered it"
	)


func test_the_realm_scene_is_still_not_the_main_scene() -> void:
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene"), "res://ui/title/title.tscn"
	)
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm/test_realm.gd`
Expected: FAIL — `Realm` has no `state`, `carry` or `lift_from_inventory`.

- [ ] **Step 3: Rewrite `realm/realm.gd` and add the nodes to `realm/realm.tscn`**

Add `HexCursor`, `Carry` and `FurnitureView` to the scene beside the existing `RealmBoard`.
`Realm` owns the `RealmState`, wires the four signals above, keeps the previously previewed
coordinates in a field so the rebuild set is the union, and reads `realm_lift_or_place`,
`realm_cancel`, `realm_rotate` and the four `realm_target_*` actions in `_unhandled_input`.
`lift_under_cursor` lifts the piece at the cursor with the cursor's hex as the grab offset;
rotate while idle over a piece does the same and then `rotate_once()`.

- [ ] **Step 4: Run the whole suite and the linter**

Run: `bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/realm.gd realm/realm.tscn test/unit/realm/test_realm.gd
git commit -m "feat: carry furniture in the realm scene with a live preview"
```

---

## Phase 5 — What the player is told

### Task 5.1 — The refusal: marked hexes and a marked requirement list

**Files:**
- Create: `realm/refusal_display.gd`
- Create: `realm/requirement_list.gd`
- Modify: `realm/realm.gd`
- Modify: `realm/realm.tscn`
- Test: `test/unit/realm/test_refusal_display.gd`
- Test: `test/unit/realm/test_requirement_list.gd`

**Interfaces:**
- Consumes: `PlacementVerdict` (Task 3.3), `PlacementCriterion` (Task 2.3),
  `Carried.describe_requirements` and `Carry.aimed` / `Carry.lifted` / `Carry.placed` /
  `Carry.cancelled` (Task 4.2),
  `HexCoordinates.center_of`, `Elevation.height_at`.
- Produces: `RefusalDisplay extends Node3D` with
  `display.mark(hexes: Array[Vector2i], zones: Array[InfluenceZone]) -> void`,
  `display.clear() -> void`, `display.marked_hexes() -> Array[Vector2i]`;
  `RequirementList extends Control` with
  `list.show_requirements(criteria: Array[PlacementCriterion]) -> void`,
  `list.mark_failing(criteria: Array[PlacementCriterion]) -> void`,
  `list.hide_requirements() -> void`, `list.lines() -> Array[String]`,
  `list.failing_lines() -> Array[String]`

**The knowledge lives on the piece; the board stays quiet until a target fails**
([decided](https://github.com/snackpackgames/cosmicparade/issues/62)). So: on `lifted`, the
requirement list shows the carried thing's requirements and the board marks nothing. On `aimed`,
the board marks `verdict.failing_hexes` and the list marks `verdict.failing_criteria` — **both at
once, and unpaired**. On `placed` and `cancelled`, both clear.

**Lighting every legal hex is not an option here and must not be added**: it answers the question
the player is meant to be answering, and it would put a third full-board layer over the terrain
preview and the spill.

A line is `criterion.describe()`; a marked line is the same line flagged. Where it is drawn is
layout and deferred ([#62](https://github.com/snackpackgames/cosmicparade/issues/62)), which is
why it is one `Control` with a two-method interface and a placeholder `VBoxContainer` of
`Label`s inside.

- [ ] **Step 1: Write the failing tests**

`test/unit/realm/test_refusal_display.gd`:

```gdscript
func test_a_fresh_display_marks_nothing() -> void:
	assert_eq(RefusalDisplay.new().marked_hexes(), [] as Array[Vector2i])


func test_marking_shows_exactly_the_hexes_it_was_given() -> void:
	var display: RefusalDisplay = add_child_autofree(RefusalDisplay.new())
	display.mark([Vector2i.ZERO, Vector2i(1, 0)] as Array[Vector2i], [] as Array[InfluenceZone])
	var marked := display.marked_hexes()
	marked.sort()
	assert_eq(marked, [Vector2i.ZERO, Vector2i(1, 0)] as Array[Vector2i])


func test_marking_again_replaces_the_previous_marks() -> void:
	var display: RefusalDisplay = add_child_autofree(RefusalDisplay.new())
	display.mark([Vector2i.ZERO] as Array[Vector2i], [] as Array[InfluenceZone])
	display.mark([Vector2i(2, 0)] as Array[Vector2i], [] as Array[InfluenceZone])
	assert_eq(display.marked_hexes(), [Vector2i(2, 0)] as Array[Vector2i])


func test_clearing_removes_every_mark() -> void:
	var display: RefusalDisplay = add_child_autofree(RefusalDisplay.new())
	display.mark([Vector2i.ZERO] as Array[Vector2i], [] as Array[InfluenceZone])
	display.clear()
	assert_eq(display.marked_hexes(), [] as Array[Vector2i])


func test_a_mark_is_not_solid_so_it_never_shadows_the_cursor_ray() -> void:
	var display: RefusalDisplay = add_child_autofree(RefusalDisplay.new())
	display.mark([Vector2i.ZERO] as Array[Vector2i], [] as Array[InfluenceZone])
	for child in display.get_children():
		assert_false(child is CollisionObject3D, "marks carry no collision")
```

`test/unit/realm/test_requirement_list.gd`:

```gdscript
func _forest_two() -> DomainInfluenceCriterion:
	var criterion := DomainInfluenceCriterion.new()
	criterion.domain = Domain.Kind.FOREST
	criterion.minimum = 2
	return criterion


func test_a_carried_piece_shows_its_own_requirements() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/62
	var list: RequirementList = add_child_autofree(RequirementList.new())
	list.show_requirements([_forest_two(), LevelFootprintCriterion.new()])
	assert_eq(list.lines(), ["Forest >= 2", LevelFootprintCriterion.new().describe()])
	assert_eq(list.failing_lines(), [], "nothing fails until a target does")


func test_marking_flags_only_the_requirements_that_failed() -> void:
	var list: RequirementList = add_child_autofree(RequirementList.new())
	var influence := _forest_two()
	list.show_requirements([influence, LevelFootprintCriterion.new()])
	list.mark_failing([influence])
	assert_eq(list.failing_lines(), ["Forest >= 2"])


func test_marking_an_empty_list_clears_every_flag() -> void:
	var list: RequirementList = add_child_autofree(RequirementList.new())
	var influence := _forest_two()
	list.show_requirements([influence])
	list.mark_failing([influence])
	list.mark_failing([])
	assert_eq(list.failing_lines(), [])


func test_a_piece_with_no_requirements_shows_an_empty_list() -> void:
	var list: RequirementList = add_child_autofree(RequirementList.new())
	list.show_requirements([])
	assert_eq(list.lines(), [])


func test_hiding_drops_the_lines() -> void:
	var list: RequirementList = add_child_autofree(RequirementList.new())
	list.show_requirements([_forest_two()])
	list.hide_requirements()
	assert_eq(list.lines(), [])
```

Add to `test/unit/realm/test_realm.gd`:

```gdscript
func test_the_board_says_nothing_until_a_target_fails() -> void:
	var realm := await _realm()
	realm.lift_from_inventory(_stool())
	assert_eq(realm.get_node("RefusalDisplay").marked_hexes(), [] as Array[Vector2i])
	assert_eq(realm.get_node("%RequirementList").lines(), [])


func test_a_refusal_marks_the_hexes_and_the_requirements_at_once() -> void:
	var realm := await _realm()
	realm.lift_from_inventory(_bench())
	realm.carry.aim(Vector2i.ZERO)
	assert_eq(realm.get_node("RefusalDisplay").marked_hexes().size(), 3)
	assert_eq(realm.get_node("%RequirementList").failing_lines(), ["Forest >= 2"])


func test_both_channels_clear_when_the_carry_ends() -> void:
	var realm := await _realm()
	realm.lift_from_inventory(_bench())
	realm.carry.aim(Vector2i.ZERO)
	realm.carry.cancel()
	assert_eq(realm.get_node("RefusalDisplay").marked_hexes(), [] as Array[Vector2i])
	assert_eq(realm.get_node("%RequirementList").lines(), [])
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm`
Expected: FAIL — `RefusalDisplay` and `RequirementList` do not exist.

- [ ] **Step 3: Implement both, then wire them in `realm.gd` and `realm.tscn`**

`RefusalDisplay` builds one flat placeholder `MeshInstance3D` per marked hex at that hex's top
face, with no collision. `RequirementList extends Control` wraps a `VBoxContainer` of `Label`s,
accessed with `%RequirementList` (`CLAUDE.md → Conventions`), and keeps the criteria it was given
so `mark_failing` can match by identity. Both are driven only by the four `Carry` signals.

- [ ] **Step 4: Run the suite and the linter**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/refusal_display.gd realm/refusal_display.gd.uid \
        realm/requirement_list.gd realm/requirement_list.gd.uid \
        realm/realm.gd realm/realm.tscn \
        test/unit/realm/test_refusal_display.gd test/unit/realm/test_requirement_list.gd \
        test/unit/realm/test_realm.gd
git commit -m "feat: mark a refusal on the board and on the carried piece"
```

---

### Task 5.2 — The spill: influence falling off the rock

**Files:**
- Create: `realm/spill_display.gd`
- Modify: `realm/realm.gd`
- Modify: `realm/realm.tscn`
- Test: `test/unit/realm/test_spill_display.gd`
- Modify: `test/unit/realm/test_realm.gd`

**Interfaces:**
- Consumes: `InfluenceZone.coordinates` (Task 2.2), `RealmGeometry.has_hex` (Task 1.3),
  `Carry.aimed` (Task 4.2).
- Produces: `SpillDisplay extends Node3D` with
  `display.show_spill(zone: InfluenceZone, geometry: RealmGeometry) -> void`,
  `display.clear() -> void`, `display.spilled_hexes() -> Array[Vector2i]`

**The preview draws the whole disc, including the coordinates with no hex under them**
([decided](https://github.com/snackpackgames/cosmicparade/issues/59)). This is what keeps the rim
gradient a feature rather than the quiet trap it was decided not to be: the player *sees* reach
falling off the rock instead of inferring it from a zone that looks slightly smaller.

The coordinate representation pays for itself twice: the off-board part is already in the zone, so
this needs no second query — just the complement of `geometry.has_hex`.

**It must not share a visual language with the refusal**
([#62](https://github.com/snackpackgames/cosmicparade/issues/62)) — they are opposites, a spilled
rim placement being perfectly legal and merely weaker. Enforced here by them being different
nodes with different placeholder meshes; how each *looks* is art direction.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_a_zone_wholly_on_the_board_spills_nothing() -> void:
	var display: SpillDisplay = add_child_autofree(SpillDisplay.new())
	display.show_spill(
		InfluenceZone.project(Domain.Kind.FOREST, [Vector2i.ZERO] as Array[Vector2i], 1),
		RealmGeometry.new()
	)
	assert_eq(display.spilled_hexes(), [] as Array[Vector2i])


func test_a_rim_placement_spills_the_coordinates_with_no_hex_under_them() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/59 — 7 from the centre,
	# 5 from a rim hex, so two coordinates fall into the void.
	var display: SpillDisplay = add_child_autofree(SpillDisplay.new())
	display.show_spill(
		InfluenceZone.project(Domain.Kind.FOREST, [Vector2i(3, 0)] as Array[Vector2i], 1),
		RealmGeometry.new()
	)
	assert_eq(display.spilled_hexes().size(), 2)


func test_a_corner_placement_spills_more_than_a_rim_one() -> void:
	# 4 of 7 land on a radius-3 board from a corner hex.
	var display: SpillDisplay = add_child_autofree(SpillDisplay.new())
	display.show_spill(
		InfluenceZone.project(Domain.Kind.FOREST, [Vector2i(3, -3)] as Array[Vector2i], 1),
		RealmGeometry.new()
	)
	assert_eq(display.spilled_hexes().size(), 3)


func test_a_swell_leaves_less_to_spill() -> void:
	var geometry := RealmGeometry.new()
	geometry.swell()
	var display: SpillDisplay = add_child_autofree(SpillDisplay.new())
	display.show_spill(
		InfluenceZone.project(Domain.Kind.FOREST, [Vector2i(3, 0)] as Array[Vector2i], 1),
		geometry
	)
	assert_eq(display.spilled_hexes(), [] as Array[Vector2i], "ring 4 fills it in")


func test_clearing_removes_the_spill() -> void:
	var display: SpillDisplay = add_child_autofree(SpillDisplay.new())
	display.show_spill(
		InfluenceZone.project(Domain.Kind.FOREST, [Vector2i(3, 0)] as Array[Vector2i], 1),
		RealmGeometry.new()
	)
	display.clear()
	assert_eq(display.spilled_hexes(), [] as Array[Vector2i])
```

Add to `test/unit/realm/test_realm.gd`:

```gdscript
func test_carrying_over_the_rim_draws_the_spill_without_refusing_the_placement() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/59 — legal, and it
	# costs you reach. The two signals must not collapse into each other.
	var realm := await _realm()
	realm.lift_from_inventory(_stool())
	realm.carry.aim(Vector2i(3, 0))
	assert_true(realm.carry.verdict().allowed)
	assert_eq(realm.get_node("SpillDisplay").spilled_hexes().size(), 2)
	assert_eq(realm.get_node("RefusalDisplay").marked_hexes(), [] as Array[Vector2i])
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm`
Expected: FAIL — `SpillDisplay` does not exist.

- [ ] **Step 3: Implement `SpillDisplay` and wire it to `Carry.aimed`**

One flat placeholder mesh per spilled coordinate, at `HexCoordinates.center_of` and no collision,
visibly not a hex space. `realm.gd` passes the candidate zone it already computes for the
preview, so no zone is projected twice.

- [ ] **Step 4: Run the suite and the linter**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/spill_display.gd realm/spill_display.gd.uid \
        realm/realm.gd realm/realm.tscn \
        test/unit/realm/test_spill_display.gd test/unit/realm/test_realm.gd
git commit -m "feat: draw influence spilling off the board's edge"
```

---

### Task 5.3 — The impossible piece says so on lift, and names the blocker

**Files:**
- Create: `realm/placement_survey.gd`
- Modify: `realm/placement_rules.gd`
- Modify: `realm/realm.gd`
- Test: `test/unit/realm/test_placement_survey.gd`
- Modify: `test/unit/realm/test_realm.gd`

**Interfaces:**
- Consumes: `PlacementRules.verdict` (Task 3.3), the five criteria, `RealmState`,
  `Carried.describe_requirements` (Task 4.2).
- Produces: `PlacementSurvey.new(placeable: bool, unsatisfiable: Array[PlacementCriterion])`,
  `survey.placeable`, `survey.unsatisfiable`;
  `PlacementRules.survey(piece: Furniture, grab_offset: Vector2i, state: RealmState)
  -> PlacementSurvey`;
  `Realm.signal nothing_satisfies(criteria: Array[PlacementCriterion])`

**The single most valuable thing the system can say**
([decided](https://github.com/snackpackgames/cosmicparade/issues/62)): when no hex satisfies the
piece in any orientation, say so on lift and name the requirement nothing satisfies — "nothing on
your realm has Forest ≥ 2 yet". A piece the player cannot yet place is *normal*
([#55](https://github.com/snackpackgames/cosmicparade/issues/55) makes better pieces want more
specific neighbourhoods), so the useful response is an errand, not a "no".

**It falls out of one sweep.** Compute a **pass mask per criterion** over every legally sited
(hex, orientation) pair; the intersection non-empty is `placeable`, and every criterion whose own
mask is empty is named. Where several are individually unsatisfiable, **all** of them are named —
the player should see the whole errand, not its first leg.

**The sweep runs on lift, not per frame**: it is a function of the committed board, which cannot
change during a carry ([#54](https://github.com/snackpackgames/cosmicparade/issues/54) — a carried
piece occupies nothing and nothing else writes). 91 hexes × 6 orientations is the worst case.

Note the two distinct answers the sweep separates: `placeable == false` with an empty
`unsatisfiable` means every criterion is satisfiable *somewhere* but no single placement satisfies
them all — a real state under `AND`, and not one to announce as "nothing on your realm has…".

- [ ] **Step 1: Write the failing tests**

```gdscript
func _piece(criteria: Array[PlacementCriterion]) -> Furniture:
	var piece := Furniture.new()
	piece.shape = Footprint.Shape.SINGLE
	piece.domain = Domain.Kind.GALE
	piece.zone_radius = 1
	piece.criteria = criteria
	return piece


func test_an_unencumbered_piece_is_placeable_on_an_empty_board() -> void:
	var survey := PlacementRules.survey(
		_piece([] as Array[PlacementCriterion]), Vector2i.ZERO,
		RealmState.new(RealmGeometry.new())
	)
	assert_true(survey.placeable)
	assert_eq(survey.unsatisfiable, [])


func test_a_requirement_nothing_satisfies_is_named() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/62
	var influence := DomainInfluenceCriterion.new()
	influence.domain = Domain.Kind.FOREST
	influence.minimum = 2
	var survey := PlacementRules.survey(
		_piece([influence] as Array[PlacementCriterion]), Vector2i.ZERO,
		RealmState.new(RealmGeometry.new())
	)
	assert_false(survey.placeable)
	assert_eq(survey.unsatisfiable.size(), 1)
	assert_eq(survey.unsatisfiable[0].describe(), "Forest >= 2")


func test_every_individually_unsatisfiable_requirement_is_named_not_just_the_first() -> void:
	var influence := DomainInfluenceCriterion.new()
	influence.domain = Domain.Kind.FOREST
	influence.minimum = 2
	var height := HeightCriterion.new()
	height.min_depth = 1
	var survey := PlacementRules.survey(
		_piece([influence, height] as Array[PlacementCriterion]), Vector2i.ZERO,
		RealmState.new(RealmGeometry.new())
	)
	assert_eq(survey.unsatisfiable.size(), 2, "the whole errand, not its first leg")


func test_a_satisfiable_requirement_is_not_named() -> void:
	var state := RealmState.new(RealmGeometry.new())
	state.place(FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	var influence := DomainInfluenceCriterion.new()
	influence.domain = Domain.Kind.FOREST
	influence.minimum = 2
	var survey := PlacementRules.survey(
		_piece([influence] as Array[PlacementCriterion]), Vector2i.ZERO, state
	)
	assert_true(survey.placeable, "the stool's zone gives six hexes Forest >= 2")
	assert_eq(survey.unsatisfiable, [])


func test_requirements_satisfiable_apart_but_not_together_name_nothing() -> void:
	# placeable == false with an empty list is a real state under AND, and it is
	# not the "nothing on your realm has..." message.
	var state := RealmState.new(RealmGeometry.new())
	state.place(FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	var influence := DomainInfluenceCriterion.new()
	influence.domain = Domain.Kind.FOREST
	influence.minimum = 2
	var position := BoardPositionCriterion.new()
	position.require_edge = true
	var survey := PlacementRules.survey(
		_piece([influence, position] as Array[PlacementCriterion]), Vector2i.ZERO, state
	)
	assert_false(survey.placeable, "the stool's reach never touches the rim")
	assert_eq(survey.unsatisfiable, [], "each one passes somewhere, just not together")


func test_the_sweep_considers_every_hex_and_every_orientation() -> void:
	# A bench that fits in exactly one place must still come back placeable.
	var state := RealmState.new(RealmGeometry.new())
	_flank_the_centre_line_with_forest(state)
	assert_true(PlacementRules.survey(_bench(), Vector2i(1, 0), state).placeable)
```

Add to `test/unit/realm/test_realm.gd`:

```gdscript
func test_lifting_an_unplaceable_piece_announces_the_requirement_nothing_satisfies() -> void:
	var realm := await _realm()
	watch_signals(realm)
	realm.lift_from_inventory(_bench())
	assert_signal_emitted(realm, "nothing_satisfies")
	assert_true(realm.carry.is_carrying(), "the player still gets to carry it and look")


func test_lifting_a_placeable_piece_announces_nothing() -> void:
	var realm := await _realm()
	watch_signals(realm)
	realm.lift_from_inventory(_stool())
	assert_signal_not_emitted(realm, "nothing_satisfies")
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm`
Expected: FAIL — `PlacementSurvey` and `PlacementRules.survey` do not exist.

- [ ] **Step 3: Implement `PlacementSurvey`, `PlacementRules.survey()` and the announcement**

`survey` iterates `state.geometry.hexes()` × 6 orientations, skips sitings that fail, and for each
remaining placement builds the context once and records which criteria passed. Track one bool per
criterion ("passed somewhere") and one bool for "some placement passed all of them"; that is the
whole sweep. `realm.gd` calls it in `lift_from_inventory`/`lift_under_cursor` and emits
`nothing_satisfies(survey.unsatisfiable)` when the list is non-empty. **The lift still happens** —
the player may carry an unplaceable piece and look around.

- [ ] **Step 4: Run the suite and the linter**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/placement_survey.gd realm/placement_survey.gd.uid \
        realm/placement_rules.gd realm/realm.gd \
        test/unit/realm/test_placement_survey.gd test/unit/realm/test_realm.gd
git commit -m "feat: name the requirement nothing on the realm satisfies"
```

---

## Phase 6 — Wings through the same verb, and the record

### Task 6.1 — A wing is carried like anything else

**Files:**
- Create: `realm/carried_wing.gd`
- Modify: `realm/realm.gd`
- Test: `test/unit/realm/test_carried_wing.gd`
- Modify: `test/unit/realm/test_realm.gd`

**Interfaces:**
- Consumes: `Carried` (Task 4.2), `RealmGeometry` (Task 1.3), `WingShape` (Task 1.2),
  `RealmState.placements_within` / `placements_touching` (Task 2.3), `PlacementVerdict`
  (Task 3.3).
- Produces: `CarriedWing.new(shape: WingShape, grab_offset: Vector2i, origin_index: int)`,
  `wing.displaced: Array[Furniture]`;
  `Realm.attach_wing(shape: WingShape) -> void`,
  `Realm.lift_wing_under_cursor() -> void`

`CarriedWing` implements the same `Carried` interface and the state machine does not change
([decided](https://github.com/snackpackgames/cosmicparade/issues/54) — "it is not a second verb
to design"). What differs:

- **`orientation_count()` is the shape's `distinct_orientations`**, not 6
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/61)) — a deliberate break from
  furniture, because a wing has no art and six presses would do nothing on the disc.
- **`zone_at()` returns `null`.** A wing projects no influence; it *is* board.
- **`verdict_at()` is `geometry.can_attach`**, surfaced as a verdict whose failing hexes are the
  wing's own hexes when it cannot land. A wing has no criteria, so `failing_criteria` is always
  empty and the requirement list stays hidden.
- **`detach()` lifts the wing with its contents.** Every placement **wholly** on the wing travels
  with it; every placement **straddling** the seam is lifted off and returned to the player,
  which costs nothing ([decided](https://github.com/snackpackgames/cosmicparade/issues/53)). The
  move is never refused for a straddler — displacement, not a new constraint, so
  [#51](https://github.com/snackpackgames/cosmicparade/issues/51) gains nothing.
  `can_lift_wing` is still consulted: a lift that would disconnect the board is refused (see
  *Two rulings derived from the map*, ruling 1).
- **`commit()` re-attaches the wing and re-places the travelling furniture** at the same offsets
  relative to the wing, so the pieces land where they stood. **Hexes are never lost**: relocation
  is not a refund.

- [ ] **Step 1: Write the failing tests**

```gdscript
func _disc() -> WingShape:
	return load("res://data/realm/wing_shape/disc.tres")


func _board_with_a_wing() -> Array:
	var geometry := RealmGeometry.new()
	geometry.swell()
	geometry.swell()
	geometry.attach(_disc(), 0, Vector2i(7, -1))
	return [geometry, RealmState.new(geometry)]


# (7, -1) and (1, 6) are legal disc anchors against a radius-5 core, and most hexes
# are not: a disc centred in ring 6 always reaches a ring-5 hex and so overlaps the
# core, while one centred further out does not touch it at all. These two sit in ring
# 7 with their inner pair in ring 6, edge-adjacent to ring 5. If a test here fails,
# fix the code — do not move the anchor.


func test_a_wing_cycles_only_its_distinct_orientations() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/61
	assert_eq(CarriedWing.new(_disc(), Vector2i.ZERO, -1).orientation_count(), 1)
	assert_eq(
		CarriedWing.new(
			load("res://data/realm/wing_shape/trapezoid.tres"), Vector2i.ZERO, -1
		).orientation_count(),
		6
	)


func test_a_wing_projects_no_influence() -> void:
	assert_null(CarriedWing.new(_disc(), Vector2i.ZERO, -1).zone_at(Vector2i.ZERO, 0))


func test_a_wing_must_land_edge_adjacent_to_the_board() -> void:
	var parts := _board_with_a_wing()
	var carried := CarriedWing.new(_disc(), Vector2i.ZERO, -1)
	assert_false(carried.verdict_at(Vector2i(20, 0), 0, parts[1]).allowed)
	assert_true(carried.verdict_at(Vector2i(1, 6), 0, parts[1]).allowed)


func test_a_wing_may_not_land_on_the_board() -> void:
	var parts := _board_with_a_wing()
	assert_false(
		CarriedWing.new(_disc(), Vector2i.ZERO, -1).verdict_at(
			Vector2i.ZERO, 0, parts[1]
		).allowed
	)


func test_a_wing_carries_the_furniture_standing_wholly_on_it() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/53
	var parts := _board_with_a_wing()
	var state: RealmState = parts[1]
	state.place(FurniturePlacement.new(_stool(), 0, [Vector2i(7, -1)] as Array[Vector2i]))
	var carried := CarriedWing.new(_disc(), Vector2i(7, -1), 0)
	carried.detach(state)
	assert_null(state.occupant_at(Vector2i(7, -1)))
	carried.commit(Vector2i(1, 6), 0, state)
	assert_not_null(state.occupant_at(Vector2i(1, 6)), "it travelled with the wing")
	assert_eq(carried.displaced, [], "nothing was straddling")


func test_a_piece_straddling_the_seam_is_returned_to_the_player() -> void:
	var parts := _board_with_a_wing()
	var state: RealmState = parts[1]
	var hexes := Footprint.occupied(Footprint.Shape.PAIR, 0, Vector2i(6, -1), Vector2i(1, 0))
	state.place(FurniturePlacement.new(_bench(), 0, hexes))
	var carried := CarriedWing.new(_disc(), Vector2i(7, -1), 0)
	carried.detach(state)
	carried.commit(Vector2i(1, 6), 0, state)
	assert_eq(carried.displaced.size(), 1, "lifted off rather than forbidden")
	assert_null(state.occupant_at(Vector2i(6, -1)))


func test_relocating_a_wing_never_loses_hexes() -> void:
	var parts := _board_with_a_wing()
	var geometry: RealmGeometry = parts[0]
	var before := geometry.hexes().size()
	var carried := CarriedWing.new(_disc(), Vector2i(7, -1), 0)
	carried.detach(parts[1])
	carried.commit(Vector2i(1, 6), 0, parts[1])
	assert_eq(geometry.hexes().size(), before)


# Review Focus 5: criteria are a gate checked once, never re-checked.
func test_a_wing_landing_beside_a_rim_piece_leaves_it_exactly_where_it_is() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/30 — the board can
	# legally hold states it cannot produce.
	var geometry := RealmGeometry.new()
	geometry.swell()
	geometry.swell()
	var state := RealmState.new(geometry)
	var stone: Furniture = load("res://data/realm/furniture/standing_stone.tres")
	var placement := FurniturePlacement.new(stone, 0, [Vector2i(5, 0)] as Array[Vector2i])
	state.place(placement)
	assert_true(geometry.is_edge_hex(Vector2i(5, 0)), "placed on the rim under require_edge")
	geometry.attach(_disc(), 0, Vector2i(7, -1))
	assert_eq(state.occupant_at(Vector2i(5, 0)), placement, "still there, never re-validated")
```

Add to `test/unit/realm/test_realm.gd`:

```gdscript
func test_attaching_a_wing_goes_through_the_same_carry() -> void:
	var realm := await _realm()
	realm.swell()
	realm.swell()
	realm.attach_wing(load("res://data/realm/wing_shape/disc.tres"))
	assert_true(realm.carry.is_carrying())
	realm.carry.aim(Vector2i(7, -1))
	assert_true(realm.carry.place())
	await wait_frames(1)
	assert_eq(realm.state.geometry.hexes().size(), 98)
	assert_eq(realm.get_node("RealmBoard").get_child_count(), 98)


func test_cancelling_a_wing_attachment_leaves_the_board_as_it_was() -> void:
	var realm := await _realm()
	realm.swell()
	realm.swell()
	realm.attach_wing(load("res://data/realm/wing_shape/disc.tres"))
	realm.carry.aim(Vector2i(7, -1))
	realm.carry.cancel()
	await wait_frames(1)
	assert_eq(realm.state.geometry.hexes().size(), 91)
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm`
Expected: FAIL — `CarriedWing` does not exist.

- [ ] **Step 3: Implement `CarriedWing` and the two `Realm` entry points**

`CarriedWing extends Carried`. `detach` records the travelling placements and their offsets
relative to the grab hex, removes them and the wing from state and geometry, and collects
straddlers into `displaced`. `commit` attaches the wing and re-places the travellers at the same
offsets. `restore` re-attaches at the original anchor and orientation and re-places everything,
including the straddlers, since cancel means nothing happened. `realm.gd` gains the two entry
points and rebuilds the board's spaces on `placed`/`cancelled` from
`geometry.hexes()`, emitting `piece_returned` per displaced piece.

- [ ] **Step 4: Run the suite and the linter**

Run: `bash scripts/import.sh && bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/carried_wing.gd realm/carried_wing.gd.uid realm/realm.gd \
        test/unit/realm/test_carried_wing.gd test/unit/realm/test_realm.gd
git commit -m "feat: attach and relocate wings through the carry verb"
```

---

### Task 6.2 — Record the decisions, and correct the README

**Files:**
- Create: `documentation/adr/0015-the-realm-grows-by-rings-then-wings.md`
- Create: `documentation/adr/0016-furniture-is-carried-onto-gated-spaces.md`
- Modify: `README.md`

**Interfaces:** none — documentation.

`README.md` is the authoritative design document and two of its lines are now wrong. The map
recorded this as a **standing preference**: the amendment is a task inside the plan, not a
follow-up ([#50](https://github.com/snackpackgames/cosmicparade/issues/50),
[#53](https://github.com/snackpackgames/cosmicparade/issues/53)).

Two ADRs rather than one, because the map decided two separable things: what the board *is* and
how furniture *gets onto it*. `README.md → Related Docs` asks for an ADR per *Settled Decisions*
entry that was hard to reverse and the result of a real trade-off; both are.

- [ ] **Step 1: Write `documentation/adr/0015-the-realm-grows-by-rings-then-wings.md`**

Following `adr/0014`'s form — short paragraphs, each citing the ticket that settled it, then
*Alternatives rejected* and *Consequences*. It must carry: the radial hexagon of radius 3 and why
radial ([#50](https://github.com/snackpackgames/cosmicparade/issues/50)); generated from a radius
rather than stored; two ring Swells to radius 5 — 91, the README's original number — and the core
never growing concentrically again ([#53](https://github.com/snackpackgames/cosmicparade/issues/53));
wings from a closed vocabulary of four figures of six or seven hexes, edge-adjacent to any board
hex, chaining, orientation cycling only the distinct rotations
([#61](https://github.com/snackpackgames/cosmicparade/issues/61)); **a wing is just more board**;
the origin never moving; relocation with contents and displacement of straddlers; and influence
projecting into the void with the rim gradient kept as a feature
([#59](https://github.com/snackpackgames/cosmicparade/issues/59)). Alternatives rejected: a
rhombus or rectangle board, concentric growth forever, wings as semi-separate islets,
redistributing spilled influence inward, an unbuildable margin, and reaching one-wide wings —
measured at +0 full-reach hexes in `test/prototypes/61-wing-vocabulary/`.

- [ ] **Step 2: Write `documentation/adr/0016-furniture-is-carried-onto-gated-spaces.md`**

Must carry: footprints from a closed vocabulary of five polyhexes, footprints never overlapping
while influence does, one zone per piece
([#51](https://github.com/snackpackgames/cosmicparade/issues/51)); the zone as a radius-1 disc
grown from every occupied hex, authored per piece, with
`test/prototypes/52-influence-zone-size/` as the evidence
([#52](https://github.com/snackpackgames/cosmicparade/issues/52)); rotation as six steps on every
piece, pivoting on the grab hex, sticky from inventory
([#56](https://github.com/snackpackgames/cosmicparade/issues/56)); the five criteria, `AND` over
every hex, gates only, counts that include the piece's own zone
([#55](https://github.com/snackpackgames/cosmicparade/issues/55)); carry as the verb, validity as a
property of the target, the place action inert while refused, lifting as the same verb
([#54](https://github.com/snackpackgames/cosmicparade/issues/54)); and the three signals with the
refusal's unpaired channels and the on-lift naming of what nothing satisfies
([#62](https://github.com/snackpackgames/cosmicparade/issues/62)). Alternatives rejected:
one hex per piece, free-form polyhex packing, radius-2 zones, origin-anchored zones, strength
modifiers, `OR` across criteria, per-criterion quantifiers, hold-drag and select-then-confirm,
lighting every legal hex, and naming one failure at a time.

- [ ] **Step 3: Amend `README.md`**

- **`Scenes → Realm`, first line:** "A floating rock of fixed tile size, starting at **10×10 hex
  spaces**" becomes a radial hexagon of **radius 3 — 37 hex spaces, 7 across** — centred on the
  board's origin, with **2 shrine slots**. Say that the board is generated from its radius.
- **`Scenes → Realm`, the Swell paragraph:** add the two-phase rule — the first two Swells add a
  whole ring, taking the core to **radius 5, 91 spaces** (where the original "10×10" lands on a
  hex lattice), and every Swell after that attaches a **wing** the player places, which is just
  more board.
- **`Scenes → Realm`, the Furniture paragraph:** furniture occupies a footprint of one to three
  hexes from a closed set, projects one zone grown from every hex it occupies, turns in six
  steps, and is **carried**: lift, aim, place, cancel. "Placeable on any tile whose criteria it
  meets" becomes the five criteria, all of which must pass on every hex of the footprint.
- **`Settled Decisions`:** add two entries matching the two ADRs, in the form the section already
  uses — bold lead, then the reasoning in two or three sentences.
- Leave `Open Design Questions` alone: no question there is answered by this map. *Communicating
  domain influence* stays open and now has the spill and the refusal as its first two concrete
  cases.

- [ ] **Step 4: Verify the old numbers are gone**

Run: `grep -n "10×10" README.md`
Expected: the only remaining mention is the historical note that radius 5's 91 spaces is where
that number lands on a hex lattice.

Run: `bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add documentation/adr/0015-the-realm-grows-by-rings-then-wings.md \
        documentation/adr/0016-furniture-is-carried-onto-gated-spaces.md README.md
git commit -m "docs: record the realm board's growth and the arrangement puzzle"
```

---

## What is finished when this plan is done

The realm board is a radial hexagon of 37 spaces generated from a radius, it grows by two rings
to 91 and then by wings the player places, and the origin never moves. A furniture piece occupies
one of five footprints at one of six orientations, projects one influence zone grown from every
hex it occupies, and is gated by any of five authored criteria evaluated against the board as it
will be with the piece on it. The player carries pieces with one verb over one targeted hex,
sees the ground each target would make, sees influence spilling off the rim, and is told which
requirement failed where — or, on lift, that nothing on the realm satisfies the piece at all.
Wings go through the same verb. `adr/0015` and `adr/0016` record why, and `README.md` no longer
describes a 10×10 board. That is the map's destination.

What the map settled that is deliberately **not** built here, each waiting on an effort this plan
does not touch:

- **What an overlap produces** — `adr/0004`'s fusion table and `adr/0008`'s interior fill and
  boundary features. M2. This plan decides where influence falls; the zones it produces are the
  input.
- **Swell's price, shrine slots and the Altar** — M1's third map. `RealmGeometry.swell()` and
  `Realm.attach_wing()` are the seams it attaches to; the debug actions are placeholders for
  whatever buys a Swell.
- **Furniture supply** — `adr/0011`'s designs and blueprints. `Realm.lift_from_inventory()` is
  the seam, and `piece_returned` is where a displaced piece goes once there is somewhere to put
  it.
- **Every visual** — the placement UI's layout, the refusal's and the spill's look, the seam's
  visibility, authored furniture models, the per-domain and depth-4 ground reads. `BoardMaterial`
  and the placeholder prisms in `FurnitureView`, `RefusalDisplay` and `SpillDisplay` are what the
  art replaces, and `RequirementList` is one `Control` so the layout has one seam.
