# Realm Ground Elevation Implementation Plan

> **For agentic workers:** Implement this plan task-by-task, committing after each task as
> it directs. Steps use checkbox (`- [ ]`) syntax for tracking. **Do not create a git
> worktree** — `CLAUDE.md → Claude Code Configuration` forbids them in this repo; work on a
> topic branch in the main working directory. The usual sub-skill for inline execution is
> `superpowers:executing-plans`; `superpowers:subagent-driven-development` is not used here
> because it provisions a worktree.

**Goal:** Arranging same-domain influence over a hex raises that hex's ground, as real data
on the board, rendered as discrete risers with per-hex collision.

**Architecture:** One pure rule derives a hex's burgeon depth and height from the influence
zones covering it — nothing stores height. The board is a collection of per-hex column nodes,
each owning its own mesh and collision shape, so a change recomputes only the hexes whose
depth moved rather than the whole board.

**Tech Stack:** Godot 4.7.2-stable, GDScript, GUT 9.7.1, `common/surface.gdshader`.

**Spec:** [Map: what generates elevation in the realm](https://github.com/snackpackgames/cosmicparade/issues/26)
— twelve closed decision tickets. Every rule below is linked to the ticket that settled it.
**Where this plan says "decided", the linked ticket holds the reasoning: do not re-derive it,
and do not substitute a different answer because it looks better in context.**

## Global Constraints

- **The rule, complete and verbatim from the map:**
  ```
  depth_d = max(0, zones_of_domain_d_covering(hex) - 1)   # per domain, capped at 4
  depth   = max over all domains d of depth_d
  height  = depth × 0.35 × hex_circumradius               # at most 1.40 radii
  ```
- **The step is a ratio of hex size, never a world-space constant**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/29)). One constant holds
  the hex circumradius and the step derives from it.
- **The cap of 4 lands on depth, at the source — not on rendered height**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/29)). Clamping height
  instead would leave the data counting upward under level-looking ground.
- **No hex stores a height, and there is no cache**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/33)). Every consumer reads
  through one accessor, which takes the zone collection as a parameter so a *hypothetical*
  arrangement can be evaluated without mutating anything
  ([required by](https://github.com/snackpackgames/cosmicparade/issues/31)).
- **One height rule for all six domains — no per-domain step, ceiling or branch**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/32)).
- **Ground is discrete risers, never smoothed slopes**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/28)). Corner heights are
  never averaged between neighbours.
- **Raised ground stays on `realm_space` (bit 1); no layer table change**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/39)). One body per hex
  space, collision shaped as a prism from that hex's own top face down to the board base.
  Every hex gets a body regardless of depth.
- Godot **4.7.2-stable**; GDScript indented with **tabs**; `max-line-length: 100` per
  `.gdlintrc`.
- Every script declares a `class_name`. After adding one, run `bash scripts/import.sh`.
- **Commit `.uid` sidecars** for every new script (`CLAUDE.md → Common Gotchas`).
- Tests are GUT, extend `GutTest`, and mirror the source tree under `test/unit/realm/`.

### Why `realm/` and not `terrain/`

Derived, not chosen. [Decide whether raised ground needs its own physics
layer](https://github.com/snackpackgames/cosmicparade/issues/39) kept raised ground on
`realm_space` — realm's own bit — on the grounds that it is still "each hex space of the realm
board". `area:terrain` names `adr/0008`'s biome fill and feature spawning, which are M2 and
out of scope on the map. The map sits in **M1: Realm and domain influence**, which owns
"whatever generates elevation".

### What this plan does not decide, and must not invent

- **Board extent.** The set of hex coordinates the board holds is *injected*. `README.md`
  says the realm starts at 10×10 spaces and Swell grows it, but board shape and growth belong
  to the realm board map. `RealmBoard.build()` takes the hexes it is given.
- **Where influence zones come from.** Zone size, shape and furniture footprints belong to the
  realm board map. This plan consumes zones as data.
- **Any art.** Final art and shader treatment of raised ground — including the authored
  per-domain look and the authored depth-4 "maxed" look — is on the map's *Out of scope* as
  deferred work. This plan uses one flat placeholder material and says so in the code.
- **Placement criteria and the placement gate.** [#30](https://github.com/snackpackgames/cosmicparade/issues/30)
  and [#41](https://github.com/snackpackgames/cosmicparade/issues/41) settled the rules, but
  they ship with furniture placement on the realm board map. The accessor this plan builds is
  what they will read.
- **Any player-facing interaction.** [#31](https://github.com/snackpackgames/cosmicparade/issues/31)
  deliberately left the input verb unsettled, so there is no targeting, preview or pointer code
  here. The accessor's purity is what makes the preview possible later.

## Review Focus

Five failure modes the map's rules imply that a straightforward reading of the tasks would
not exercise. Each has a test in the task that owns the code.

1. **Odd and negative axial coordinates.** The flat-top centre formula halves `q`; integer
   division would misplace every hex with an odd `q` and every negative one. Task 1.1.
2. **A zone listing the same hex twice.** Influence is a *set* of hex coordinates, so a
   duplicate must count once — an `Array` that is counted naively would inflate depth. Task 1.3.
3. **`rebuild()` naming a hex the board does not hold.** Zone edges and Swell will do this
   routinely; it must be a no-op, not a crash. Task 3.3.
4. **A zone entirely off the board.** Contributes nothing anywhere and must not raise. Task 2.2.
5. **The cap boundary.** Five same-domain zones reach exactly depth 4 and six must still be 4,
   with the cap applied per domain *before* the maximum. Task 2.2.

---

## Phases

| Phase | Delivers | Blocked by |
|---|---|---|
| 1 | Hex coordinates, the six domains, and the influence-zone input | — |
| 2 | The elevation rule as a pure derived accessor | Phase 1 |
| 3 | The board: per-hex columns, discrete risers, prism collision, then `adr/0014` | Phase 2 |

One issue per phase. Commit after each task.

---

## Phase 1 — The inputs

### Task 1.1 — Flat-top axial hex coordinates

**Files:**
- Create: `realm/hex_coordinates.gd`
- Test: `test/unit/realm/test_hex_coordinates.gd`

**Interfaces:**
- Produces: `HexCoordinates.CIRCUMRADIUS: float`, `HexCoordinates.distance(a: Vector2i,
  b: Vector2i) -> int`, `HexCoordinates.center_of(hex: Vector2i) -> Vector3`,
  `HexCoordinates.corner_offsets() -> PackedVector3Array`

Flat-top axial, matching the parked prototype at
`test/prototypes/28-raised-hex-ground-legibility/main.gd` so the measured step of 0.35
([decided](https://github.com/snackpackgames/cosmicparade/issues/29)) means here what it meant
there. `CIRCUMRADIUS := 1.0`, the prototype's value — it is the single source of truth for hex
size, and because the step is a ratio, changing it rescales the board and nothing else.

- [ ] **Step 1: Write the failing tests**

```gdscript
extends GutTest
## Flat-top axial hex geometry.

func test_distance_is_zero_to_itself() -> void:
	assert_eq(HexCoordinates.distance(Vector2i(2, -3), Vector2i(2, -3)), 0)


func test_distance_counts_steps_between_neighbours() -> void:
	assert_eq(HexCoordinates.distance(Vector2i.ZERO, Vector2i(1, 0)), 1)
	assert_eq(HexCoordinates.distance(Vector2i.ZERO, Vector2i(1, -1)), 1)
	assert_eq(HexCoordinates.distance(Vector2i.ZERO, Vector2i(2, -1)), 2)
	assert_eq(HexCoordinates.distance(Vector2i(-2, 1), Vector2i(2, -1)), 4)


func test_origin_sits_at_the_world_origin() -> void:
	assert_eq(HexCoordinates.center_of(Vector2i.ZERO), Vector3.ZERO)


func test_centres_lie_flat_on_the_xz_plane() -> void:
	assert_eq(HexCoordinates.center_of(Vector2i(3, -2)).y, 0.0)


# Review Focus 1: an odd q must be halved as a float. Integer division would
# put this hex a full half-row out of place, and every other column with it.
func test_odd_q_offsets_the_row_by_half_a_step() -> void:
	var center := HexCoordinates.center_of(Vector2i(1, 0))
	assert_almost_eq(center.x, 1.5, 0.0001)
	assert_almost_eq(center.z, sqrt(3.0) * 0.5, 0.0001)


func test_negative_coordinates_mirror_positive_ones() -> void:
	var positive := HexCoordinates.center_of(Vector2i(3, -1))
	var negative := HexCoordinates.center_of(Vector2i(-3, 1))
	assert_almost_eq(negative.x, -positive.x, 0.0001)
	assert_almost_eq(negative.z, -positive.z, 0.0001)


func test_there_are_six_corner_offsets_at_the_circumradius() -> void:
	var offsets := HexCoordinates.corner_offsets()
	assert_eq(offsets.size(), 6)
	for offset: Vector3 in offsets:
		assert_almost_eq(Vector2(offset.x, offset.z).length(), HexCoordinates.CIRCUMRADIUS, 0.0001)
		assert_eq(offset.y, 0.0)
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm/test_hex_coordinates.gd`
Expected: FAIL — the `HexCoordinates` class does not exist, reported by
`test_all_test_scripts_load` (see `CLAUDE.md → Running and Testing`).

- [ ] **Step 3: Implement `HexCoordinates` in `realm/hex_coordinates.gd`**

`class_name HexCoordinates extends RefCounted`, all members static. The three formulas,
which the signatures and tests do not determine:

```gdscript
distance  = (absi(dq) + absi(dr) + absi(dq + dr)) / 2
center_of = Vector3(CIRCUMRADIUS * 1.5 * q, 0.0, CIRCUMRADIUS * sqrt(3.0) * (r + q * 0.5))
corner i  = Vector3(CIRCUMRADIUS * cos(deg_to_rad(60.0 * i)), 0.0,
                    CIRCUMRADIUS * sin(deg_to_rad(60.0 * i)))
```

Note `q * 0.5`, not `q / 2` — Review Focus 1.

- [ ] **Step 4: Rebuild the class cache, then run the tests**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_hex_coordinates.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/hex_coordinates.gd realm/hex_coordinates.gd.uid \
        test/unit/realm/test_hex_coordinates.gd test/unit/realm/test_hex_coordinates.gd.uid
git commit -m "feat: add flat-top axial hex coordinates"
```

### Task 1.2 — The six domains

**Files:**
- Create: `realm/domain.gd`
- Test: `test/unit/realm/test_domain.gd`

**Interfaces:**
- Produces: `Domain.Kind` — `FOREST`, `GRASSLAND`, `WETLAND`, `STONE`, `FLAME`, `GALE`

The six are settled in `README.md → Terminology`. Nothing else goes in this file: there is no
per-domain elevation data of any kind
([decided](https://github.com/snackpackgames/cosmicparade/issues/32)), and adding a field in
anticipation of one would contradict that decision.

- [ ] **Step 1: Write the failing test**

```gdscript
extends GutTest
## The six domains, and nothing per-domain beyond their names.

func test_there_are_exactly_six_domains() -> void:
	assert_eq(Domain.Kind.size(), 6)


func test_every_domain_in_the_design_document_is_present() -> void:
	for name: String in ["FOREST", "GRASSLAND", "WETLAND", "STONE", "FLAME", "GALE"]:
		assert_true(Domain.Kind.has(name), "Domain.Kind should have %s" % name)
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `bash scripts/test.sh realm/test_domain.gd`
Expected: FAIL — `Domain` does not exist.

- [ ] **Step 3: Implement `Domain` in `realm/domain.gd`**

`class_name Domain extends RefCounted` holding only
`enum Kind {FOREST, GRASSLAND, WETLAND, STONE, FLAME, GALE}`.

- [ ] **Step 4: Rebuild the class cache, then run the test**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_domain.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/domain.gd realm/domain.gd.uid \
        test/unit/realm/test_domain.gd test/unit/realm/test_domain.gd.uid
git commit -m "feat: add the six realm domains"
```

### Task 1.3 — The influence zone

**Files:**
- Create: `realm/influence_zone.gd`
- Test: `test/unit/realm/test_influence_zone.gd`

**Interfaces:**
- Produces: `InfluenceZone.new(domain: Domain.Kind, hexes: Array[Vector2i]) -> InfluenceZone`,
  `zone.domain: Domain.Kind`, `zone.covers(hex: Vector2i) -> bool`

**One zone, not one set per domain.** `CLAUDE.md → 3D Physics Layers` describes influence as
"sets of hex coordinates per domain", but the rule counts *how many zones* of a domain cover a
hex ([decided](https://github.com/snackpackgames/cosmicparade/issues/37):
`depth = max(0, zones - 1)`). A single merged set per domain throws that count away, so
per-zone granularity is forced by the rule rather than chosen here.

Zones are projected by furniture, shrines and tiles — not by fused biomes
(`README.md → Terminology`, which is why nothing cascades, per
[#31](https://github.com/snackpackgames/cosmicparade/issues/31)). What projects a zone, and how
big it is, belongs to the realm board map; this type is just the input.

- [ ] **Step 1: Write the failing tests**

```gdscript
extends GutTest
## A single influence zone: one domain over a set of hexes.

func test_a_zone_covers_the_hexes_it_was_given() -> void:
	var zone := InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO, Vector2i(1, 0)])
	assert_true(zone.covers(Vector2i.ZERO))
	assert_true(zone.covers(Vector2i(1, 0)))


func test_a_zone_does_not_cover_a_hex_outside_it() -> void:
	var zone := InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO])
	assert_false(zone.covers(Vector2i(5, -5)))


func test_an_empty_zone_covers_nothing() -> void:
	assert_false(InfluenceZone.new(Domain.Kind.GALE, []).covers(Vector2i.ZERO))


func test_a_zone_keeps_its_domain() -> void:
	assert_eq(InfluenceZone.new(Domain.Kind.WETLAND, []).domain, Domain.Kind.WETLAND)


# Review Focus 2: influence is a set. A hex listed twice is covered once,
# or the zone would contribute two levels of depth on its own.
func test_a_hex_listed_twice_is_covered_once() -> void:
	var zone := InfluenceZone.new(Domain.Kind.FLAME, [Vector2i.ZERO, Vector2i.ZERO])
	assert_true(zone.covers(Vector2i.ZERO))
	assert_eq(zone.hex_count(), 1)
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm/test_influence_zone.gd`
Expected: FAIL — `InfluenceZone` does not exist.

- [ ] **Step 3: Implement `InfluenceZone` in `realm/influence_zone.gd`**

`class_name InfluenceZone extends RefCounted`, with `_init(domain, hexes)` storing the hexes in
a `Dictionary` keyed by `Vector2i` so set semantics hold by construction rather than by a
de-duplication pass. Also expose `hex_count() -> int`, which the test above needs and Task 3.3
does not.

- [ ] **Step 4: Rebuild the class cache, then run the tests**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_influence_zone.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/influence_zone.gd realm/influence_zone.gd.uid \
        test/unit/realm/test_influence_zone.gd test/unit/realm/test_influence_zone.gd.uid
git commit -m "feat: add the influence zone input type"
```

---

## Phase 2 — The rule

### Task 2.1 — Depth from a hex's influence zones

**Files:**
- Create: `realm/elevation.gd`
- Test: `test/unit/realm/test_elevation.gd`

**Interfaces:**
- Consumes: `InfluenceZone`, `Domain.Kind` (Phase 1)
- Produces: `Elevation.MAX_DEPTH: int`, `Elevation.STEP_RATIO: float`,
  `Elevation.depth_at(hex: Vector2i, zones: Array[InfluenceZone]) -> int`

`MAX_DEPTH := 4` and `STEP_RATIO := 0.35`, both
[decided](https://github.com/snackpackgames/cosmicparade/issues/29). The function is static and
takes `zones` as a parameter — that is the whole of what makes a hypothetical arrangement
evaluable ([#31](https://github.com/snackpackgames/cosmicparade/issues/31)) and what
[#33](https://github.com/snackpackgames/cosmicparade/issues/33) means by "the accessor is the
seam". It stores nothing.

- [ ] **Step 1: Write the failing tests**

```gdscript
extends GutTest
## The elevation rule: depth per domain, maximum across domains, height from depth.

func _zones(domain: Domain.Kind, count: int, hex: Vector2i) -> Array[InfluenceZone]:
	var zones: Array[InfluenceZone] = []
	for _i in count:
		zones.append(InfluenceZone.new(domain, [hex]))
	return zones


func test_a_hex_with_no_influence_is_flat() -> void:
	var none: Array[InfluenceZone] = []
	assert_eq(Elevation.depth_at(Vector2i.ZERO, none), 0)


# The off-by-one: burgeon is the same domain overlapping itself, so one zone
# raises nothing. https://github.com/snackpackgames/cosmicparade/issues/37
func test_a_single_zone_leaves_its_hex_flat() -> void:
	assert_eq(Elevation.depth_at(Vector2i.ZERO, _zones(Domain.Kind.STONE, 1, Vector2i.ZERO)), 0)


func test_two_zones_of_one_domain_raise_the_hex_one_level() -> void:
	assert_eq(Elevation.depth_at(Vector2i.ZERO, _zones(Domain.Kind.STONE, 2, Vector2i.ZERO)), 1)


func test_depth_is_one_less_than_the_zones_covering_the_hex() -> void:
	assert_eq(Elevation.depth_at(Vector2i.ZERO, _zones(Domain.Kind.FOREST, 4, Vector2i.ZERO)), 3)
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm/test_elevation.gd`
Expected: FAIL — `Elevation` does not exist.

- [ ] **Step 3: Implement `Elevation.depth_at()` in `realm/elevation.gd`**

`class_name Elevation extends RefCounted`, static. Count the covering zones per domain, apply
`mini(MAX_DEPTH, maxi(0, count - 1))` per domain, and return the largest — the per-domain cap
goes on **before** the maximum
([decided](https://github.com/snackpackgames/cosmicparade/issues/40)).

- [ ] **Step 4: Run the tests and verify they pass**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_elevation.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/elevation.gd realm/elevation.gd.uid \
        test/unit/realm/test_elevation.gd test/unit/realm/test_elevation.gd.uid
git commit -m "feat: derive burgeon depth from influence zones"
```

### Task 2.2 — The cap, and multiple domains on one hex

**Files:**
- Modify: `realm/elevation.gd`
- Test: `test/unit/realm/test_elevation.gd`

**Interfaces:** unchanged from Task 2.1.

If Task 2.1's implementation already satisfies these, the tests pass on the first run — that is
a correct outcome and the point of writing them separately. They pin the two rules most likely
to be "simplified" by a later change.

- [ ] **Step 1: Write the tests**

```gdscript
# Review Focus 5: the cap boundary. https://github.com/snackpackgames/cosmicparade/issues/29
func test_five_zones_of_one_domain_reach_the_ceiling() -> void:
	assert_eq(Elevation.depth_at(Vector2i.ZERO, _zones(Domain.Kind.GALE, 5, Vector2i.ZERO)), 4)


func test_a_sixth_zone_adds_nothing() -> void:
	assert_eq(Elevation.depth_at(Vector2i.ZERO, _zones(Domain.Kind.GALE, 6, Vector2i.ZERO)), 4)


# The maximum, not the sum. https://github.com/snackpackgames/cosmicparade/issues/40
func test_the_strongest_single_domain_sets_the_depth() -> void:
	var zones := _zones(Domain.Kind.STONE, 4, Vector2i.ZERO)
	zones.append_array(_zones(Domain.Kind.WETLAND, 2, Vector2i.ZERO))
	assert_eq(Elevation.depth_at(Vector2i.ZERO, zones), 3)


func test_two_maxed_domains_still_cap_at_four() -> void:
	var zones := _zones(Domain.Kind.STONE, 5, Vector2i.ZERO)
	zones.append_array(_zones(Domain.Kind.WETLAND, 5, Vector2i.ZERO))
	assert_eq(Elevation.depth_at(Vector2i.ZERO, zones), 4)


func test_mixing_domains_buys_no_height() -> void:
	var zones := _zones(Domain.Kind.FLAME, 1, Vector2i.ZERO)
	zones.append_array(_zones(Domain.Kind.GALE, 1, Vector2i.ZERO))
	assert_eq(Elevation.depth_at(Vector2i.ZERO, zones), 0)


# One rule for all six domains: no per-domain step, ceiling or branch.
# https://github.com/snackpackgames/cosmicparade/issues/32
func test_every_domain_raises_ground_identically() -> void:
	for domain: int in Domain.Kind.values():
		assert_eq(
			Elevation.depth_at(Vector2i.ZERO, _zones(domain, 3, Vector2i.ZERO)),
			2,
			"domain %d should raise like every other" % domain
		)


# Review Focus 4: a zone that covers nothing on the hex under test.
func test_a_zone_elsewhere_does_not_raise_this_hex() -> void:
	assert_eq(Elevation.depth_at(Vector2i.ZERO, _zones(Domain.Kind.STONE, 3, Vector2i(9, -4))), 0)
```

- [ ] **Step 2: Run the tests**

Run: `bash scripts/test.sh realm/test_elevation.gd`
Expected: PASS, or a failure naming exactly which of the two rules Task 2.1 got wrong.

- [ ] **Step 3: Fix `depth_at()` only if a test failed**

A sum where the rule says maximum, or a cap applied after the maximum instead of per domain,
are the two failures to expect.

- [ ] **Step 4: Re-run the tests**

Run: `bash scripts/test.sh realm/test_elevation.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/elevation.gd test/unit/realm/test_elevation.gd
git commit -m "test: pin the depth cap and the multi-domain maximum"
```

### Task 2.3 — Height from depth

**Files:**
- Modify: `realm/elevation.gd`
- Test: `test/unit/realm/test_elevation.gd`

**Interfaces:**
- Produces: `Elevation.height_for_depth(depth: int) -> float`,
  `Elevation.height_at(hex: Vector2i, zones: Array[InfluenceZone]) -> float`

Two entry points on one formula: Task 3.2 renders a column from a depth it already has, and
future placement criteria read a height from an arrangement.

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_a_flat_hex_is_at_board_level() -> void:
	assert_almost_eq(Elevation.height_for_depth(0), 0.0, 0.0001)


func test_one_level_is_the_step_ratio_of_the_circumradius() -> void:
	assert_almost_eq(
		Elevation.height_for_depth(1), 0.35 * HexCoordinates.CIRCUMRADIUS, 0.0001
	)


func test_the_ceiling_is_one_point_four_circumradii() -> void:
	assert_almost_eq(
		Elevation.height_for_depth(Elevation.MAX_DEPTH), 1.40 * HexCoordinates.CIRCUMRADIUS, 0.0001
	)


func test_every_level_is_the_same_height_as_every_other() -> void:
	# Uniform, not diminishing: a drop's size has to tell you its depth.
	# https://github.com/snackpackgames/cosmicparade/issues/29
	for depth in range(1, Elevation.MAX_DEPTH + 1):
		var rise := Elevation.height_for_depth(depth) - Elevation.height_for_depth(depth - 1)
		assert_almost_eq(rise, 0.35 * HexCoordinates.CIRCUMRADIUS, 0.0001)


func test_height_at_reads_the_arrangement() -> void:
	assert_almost_eq(
		Elevation.height_at(Vector2i.ZERO, _zones(Domain.Kind.STONE, 3, Vector2i.ZERO)),
		2.0 * 0.35 * HexCoordinates.CIRCUMRADIUS,
		0.0001
	)


func test_evaluating_an_arrangement_does_not_change_anything() -> void:
	# Derived, no cache, no stored height: calling twice with a different
	# arrangement in between must not carry anything over.
	# https://github.com/snackpackgames/cosmicparade/issues/33
	var raised := _zones(Domain.Kind.STONE, 3, Vector2i.ZERO)
	var none: Array[InfluenceZone] = []
	assert_gt(Elevation.height_at(Vector2i.ZERO, raised), 0.0)
	assert_almost_eq(Elevation.height_at(Vector2i.ZERO, none), 0.0, 0.0001)
	assert_gt(Elevation.height_at(Vector2i.ZERO, raised), 0.0)
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm/test_elevation.gd`
Expected: FAIL — `height_for_depth` not declared.

- [ ] **Step 3: Implement both functions in `realm/elevation.gd`**

`height_for_depth` is `depth * STEP_RATIO * HexCoordinates.CIRCUMRADIUS`; `height_at` is
`height_for_depth(depth_at(hex, zones))`. The ratio must not be reduced to a world-space
constant ([decided](https://github.com/snackpackgames/cosmicparade/issues/29)).

- [ ] **Step 4: Run the whole suite**

Run: `bash scripts/import.sh && bash scripts/test.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/elevation.gd test/unit/realm/test_elevation.gd
git commit -m "feat: derive hex height from burgeon depth"
```

---

## Phase 3 — The board

### Task 3.1 — The placeholder surface material

**Files:**
- Create: `realm/board_material.gd`
- Test: `test/unit/realm/test_board_material.gd`

**Interfaces:**
- Produces: `BoardMaterial.create() -> ShaderMaterial`

A deliberate placeholder. Final art and shader treatment of raised ground — including the
authored per-domain look ([#32](https://github.com/snackpackgames/cosmicparade/issues/32)) and
the authored depth-4 look that makes a maxed stack legible
([#42](https://github.com/snackpackgames/cosmicparade/issues/42)) — is on the map's *Out of
scope* as deferred work the design depends on. This exists so the board is visible, and the
file's doc comment must say so. It is not authored data and does not belong in `data/`.

- [ ] **Step 1: Write the failing test**

```gdscript
extends GutTest
## The board's placeholder material. Art is deferred; this only has to render.

func test_it_uses_the_shared_surface_shader() -> void:
	var material := BoardMaterial.create()
	assert_eq(material.shader, load("res://common/surface.gdshader"))


func test_it_supplies_the_albedo_texture_the_shader_samples() -> void:
	assert_not_null(BoardMaterial.create().get_shader_parameter("albedo_texture"))
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `bash scripts/test.sh realm/test_board_material.gd`
Expected: FAIL — `BoardMaterial` does not exist.

- [ ] **Step 3: Implement `BoardMaterial.create()` in `realm/board_material.gd`**

`class_name BoardMaterial extends RefCounted`, static. A `ShaderMaterial` on
`res://common/surface.gdshader` with `albedo_texture` set to a small `ImageTexture` built in
code. `common/surface.gdshader` writes only `ALBEDO` and samples
`filter_nearest_mipmap`, so generate mipmaps on the image or the board shimmers at distance.

- [ ] **Step 4: Run the test**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_board_material.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/board_material.gd realm/board_material.gd.uid \
        test/unit/realm/test_board_material.gd test/unit/realm/test_board_material.gd.uid
git commit -m "feat: add a placeholder board material on the shared shader"
```

### Task 3.2 — One hex space: its own column, mesh and collision

**Files:**
- Create: `realm/hex_space.gd`
- Test: `test/unit/realm/test_hex_space.gd`

**Interfaces:**
- Consumes: `HexCoordinates`, `Elevation.height_for_depth()`, `BoardMaterial.create()`
- Produces: `HexSpace.BASE_Y: float`, `HexSpace.new()`,
  `space.configure(hex: Vector2i, material: Material) -> void`,
  `space.set_depth(depth: int) -> void`, `space.top_height() -> float`

**One body per hex space, each owning its own mesh.** The body is
[decided](https://github.com/snackpackgames/cosmicparade/issues/39). The *mesh* split is this
plan's call, which #39 explicitly delegated: a single stitched board mesh would rebuild
O(board) geometry on every change and throw away the per-zone bound
[#31](https://github.com/snackpackgames/cosmicparade/issues/31) established. Per-hex meshes keep
geometry and collision on the same bound, and they are also the shape the deferred per-hex
authored looks will need. The cost is one draw call per hex; merging or a `MultiMesh` is a later
optimisation to make against a measurement, not now.

`collision_layer` is bit 1 (`realm_space`) and `collision_mask` is **0** — a passive target with
no mask of its own, per `CLAUDE.md → 3D Physics Layers`.

`BASE_Y := -2.0`, the prototype's floor. It only has to sit below the deepest ground; how the
board's underside looks is deferred art.

- [ ] **Step 1: Write the failing tests**

```gdscript
extends GutTest
## A single hex space: a prism from its own top face down to the board base.

func _space(hex: Vector2i, depth: int) -> HexSpace:
	var space: HexSpace = add_child_autofree(HexSpace.new())
	space.configure(hex, BoardMaterial.create())
	space.set_depth(depth)
	return space


func test_it_is_a_passive_target_on_realm_space() -> void:
	var space := _space(Vector2i.ZERO, 0)
	assert_eq(space.collision_layer, 1, "realm_space is bit 1")
	assert_eq(space.collision_mask, 0, "the board detects nothing")


func test_it_sits_at_its_hex_centre() -> void:
	var space := _space(Vector2i(2, -1), 0)
	assert_eq(space.position, HexCoordinates.center_of(Vector2i(2, -1)))


# Every hex has a body regardless of depth: a flat hex is a zero-rise column.
# https://github.com/snackpackgames/cosmicparade/issues/39
func test_a_flat_hex_still_has_a_body_with_a_top_face_at_board_level() -> void:
	var space := _space(Vector2i.ZERO, 0)
	assert_almost_eq(space.top_height(), 0.0, 0.0001)
	assert_eq(space.get_shape_owners().size(), 1)


func test_its_top_face_rises_with_its_depth() -> void:
	assert_almost_eq(_space(Vector2i.ZERO, 3).top_height(), Elevation.height_for_depth(3), 0.0001)


func test_the_collision_prism_spans_the_top_face_to_the_board_base() -> void:
	var space := _space(Vector2i.ZERO, 2)
	var shape: ConvexPolygonShape3D = space.get_node("CollisionShape3D").shape
	assert_eq(shape.points.size(), 12, "six top corners and six base corners")
	var heights: Array[float] = []
	for point: Vector3 in shape.points:
		if not heights.has(point.y):
			heights.append(point.y)
	heights.sort()
	assert_eq(heights.size(), 2)
	assert_almost_eq(heights[0], HexSpace.BASE_Y, 0.0001)
	assert_almost_eq(heights[1], Elevation.height_for_depth(2), 0.0001)


func test_the_top_face_is_level_so_the_riser_is_vertical() -> void:
	# Discrete risers, never smoothed slopes: every top corner is at the hex's
	# own height. https://github.com/snackpackgames/cosmicparade/issues/28
	var space := _space(Vector2i.ZERO, 1)
	var mesh: ArrayMesh = space.get_node("MeshInstance3D").mesh
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var top := Elevation.height_for_depth(1)
	for vertex: Vector3 in vertices:
		assert_true(
			is_equal_approx(vertex.y, top) or is_equal_approx(vertex.y, HexSpace.BASE_Y),
			"a vertex at y=%f is neither the top face nor the base" % vertex.y
		)


func test_changing_depth_replaces_the_geometry_rather_than_adding_to_it() -> void:
	var space := _space(Vector2i.ZERO, 1)
	var before: int = space.get_child_count()
	space.set_depth(4)
	assert_eq(space.get_child_count(), before)
	assert_almost_eq(space.top_height(), Elevation.height_for_depth(4), 0.0001)
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm/test_hex_space.gd`
Expected: FAIL — `HexSpace` does not exist.

- [ ] **Step 3: Implement `HexSpace` in `realm/hex_space.gd`**

`class_name HexSpace extends StaticBody3D`, with one `MeshInstance3D` and one
`CollisionShape3D` child created in `configure()` and *reused* by every `set_depth()` call.
Build the mesh with `SurfaceTool`: a six-triangle fan from the top centre, then a quad per
edge down to `BASE_Y`, top normals `Vector3.UP` and side normals pointing outward from the hex
centre.

UVs must be computed from **world** position, not local: each mesh sits at its own hex centre,
so local UVs would restart the tessera pattern on every hex. Add `HexCoordinates.center_of(hex)`
into the UV before scaling by `0.5` — the prototype's `UV_SCALE`.

- [ ] **Step 4: Run the tests**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_hex_space.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/hex_space.gd realm/hex_space.gd.uid \
        test/unit/realm/test_hex_space.gd test/unit/realm/test_hex_space.gd.uid
git commit -m "feat: build a hex space as a prism from its top face to the board base"
```

### Task 3.3 — The board, and rebuilding only what changed

**Files:**
- Create: `realm/realm_board.gd`
- Test: `test/unit/realm/test_realm_board.gd`

**Interfaces:**
- Consumes: `HexSpace`, `Elevation.depth_at()`, `BoardMaterial.create()`
- Produces: `board.build(hexes: Array[Vector2i]) -> void`,
  `board.zones: Array[InfluenceZone]`,
  `board.rebuild(changed_hexes: Array[Vector2i]) -> void`,
  `board.hex_space(hex: Vector2i) -> HexSpace`

**The board's extent is injected.** `build()` takes the hexes it is given and holds no opinion
about the board's shape or size — those belong to the realm board map, and Swell will change
them.

`rebuild()` takes the hexes whose coverage changed, which is how the per-zone bound from
[#31](https://github.com/snackpackgames/cosmicparade/issues/31) reaches the geometry: a moved
piece changes `old zone ∪ new zone` and nothing else, because only furniture, shrines and tiles
project influence — a fused biome does not, so nothing cascades.

- [ ] **Step 1: Write the failing tests**

```gdscript
extends GutTest
## The realm board: one hex space per coordinate it was given.

const HEXES: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(0, 1)]


func _board(zones: Array[InfluenceZone]) -> RealmBoard:
	var board: RealmBoard = add_child_autofree(RealmBoard.new())
	board.zones = zones
	board.build(HEXES)
	return board


func test_it_builds_one_hex_space_per_coordinate_it_was_given() -> void:
	var board := _board([] as Array[InfluenceZone])
	for hex: Vector2i in HEXES:
		assert_not_null(board.hex_space(hex), "no space built for %s" % hex)


func test_a_fresh_realm_is_flat() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/27
	var board := _board([] as Array[InfluenceZone])
	for hex: Vector2i in HEXES:
		assert_almost_eq(board.hex_space(hex).top_height(), 0.0, 0.0001)


func test_it_raises_a_hex_two_same_domain_zones_cover() -> void:
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO, Vector2i(1, 0)]),
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
	]
	var board := _board(zones)
	assert_almost_eq(board.hex_space(Vector2i.ZERO).top_height(), Elevation.height_for_depth(1), 0.0001)
	assert_almost_eq(board.hex_space(Vector2i(1, 0)).top_height(), 0.0, 0.0001)


func test_removing_a_zone_lowers_the_ground_it_raised() -> void:
	# Height always equals current depth; there is no high-water mark.
	# https://github.com/snackpackgames/cosmicparade/issues/38
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
	]
	var board := _board(zones)
	assert_gt(board.hex_space(Vector2i.ZERO).top_height(), 0.0)
	board.zones = [zones[0]] as Array[InfluenceZone]
	board.rebuild([Vector2i.ZERO] as Array[Vector2i])
	assert_almost_eq(board.hex_space(Vector2i.ZERO).top_height(), 0.0, 0.0001)


func test_rebuild_touches_only_the_hexes_it_was_given() -> void:
	var board := _board([] as Array[InfluenceZone])
	board.zones = [
		InfluenceZone.new(Domain.Kind.GALE, [Vector2i.ZERO, Vector2i(1, 0)]),
		InfluenceZone.new(Domain.Kind.GALE, [Vector2i.ZERO, Vector2i(1, 0)]),
	] as Array[InfluenceZone]
	board.rebuild([Vector2i.ZERO] as Array[Vector2i])
	assert_gt(board.hex_space(Vector2i.ZERO).top_height(), 0.0, "the named hex rebuilt")
	assert_almost_eq(
		board.hex_space(Vector2i(1, 0)).top_height(), 0.0, 0.0001,
		"an unnamed hex must be left alone even when its coverage changed"
	)


# Review Focus 3: zone edges and Swell will name hexes off the board.
func test_rebuilding_a_hex_the_board_does_not_hold_is_a_no_op() -> void:
	var board := _board([] as Array[InfluenceZone])
	board.rebuild([Vector2i(99, -99)] as Array[Vector2i])
	assert_null(board.hex_space(Vector2i(99, -99)))
	assert_eq(board.get_child_count(), HEXES.size())
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bash scripts/test.sh realm/test_realm_board.gd`
Expected: FAIL — `RealmBoard` does not exist.

- [ ] **Step 3: Implement `RealmBoard` in `realm/realm_board.gd`**

`class_name RealmBoard extends Node3D`, holding a `Dictionary` of `Vector2i` to `HexSpace`.
`build()` creates one configured `HexSpace` per hex with one shared material from
`BoardMaterial.create()` and sets each one's depth from `Elevation.depth_at()`. `rebuild()`
looks each hex up and skips the ones it does not hold.

Note what `test_rebuild_touches_only_the_hexes_it_was_given` pins: `rebuild()` must not
recompute the whole board as a convenience. The bound is the point.

- [ ] **Step 4: Run the tests**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_realm_board.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/realm_board.gd realm/realm_board.gd.uid \
        test/unit/realm/test_realm_board.gd test/unit/realm/test_realm_board.gd.uid
git commit -m "feat: add the realm board with per-hex rebuilds"
```

### Task 3.4 — The realm scene

**Files:**
- Create: `realm/realm.tscn`
- Modify: `test/unit/realm/test_realm_board.gd`

**Interfaces:**
- Consumes: `RealmBoard`

`CLAUDE.md → Architecture` gives `realm/realm.tscn` its own system directory as one of the two
scenes that are systems rather than screens. It is **not** the main scene — `ui/title/title.tscn`
stays that, and this scene is reached with F6 in the editor until the realm is wired up. The
camera and environment are placeholders in the same spirit as the title screen's stub, and the
scene's root script must say so.

There is no interaction of any kind here: no pointer, no targeting, no preview.
[#31](https://github.com/snackpackgames/cosmicparade/issues/31) deliberately left the input verb
unsettled, so adding one would be inventing a decision the map declined to make.

- [ ] **Step 1: Write the failing test**

```gdscript
const REALM_SCENE := preload("res://realm/realm.tscn")


func test_the_realm_scene_instantiates_with_a_board() -> void:
	var realm: Node3D = add_child_autofree(REALM_SCENE.instantiate())
	assert_not_null(realm.get_node_or_null("RealmBoard"), "the scene should hold a RealmBoard")


func test_the_realm_scene_is_not_the_main_scene() -> void:
	# The title screen stays the boot scene until the realm is wired up.
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene"), "res://ui/title/title.tscn"
	)
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `bash scripts/test.sh realm/test_realm_board.gd`
Expected: FAIL — `res://realm/realm.tscn` does not exist, reported by
`test_all_test_scripts_load` because the `preload` cannot resolve.

- [ ] **Step 3: Build `realm/realm.tscn`**

A `Node3D` root with a `RealmBoard` child named `RealmBoard`, a `Camera3D` and a
`WorldEnvironment`. The prototype's framing is a reasonable starting point — a 35° yaw and a
50° pitch read the risers clearly at both camera heights it tested — but camera and lighting
here are placeholders, not decisions.

- [ ] **Step 4: Run the whole suite and the linter**

Run: `bash scripts/import.sh && bash scripts/lint.sh && bash scripts/test.sh`
Expected: PASS, with no gdlint findings.

- [ ] **Step 5: Commit**

```bash
git add realm/realm.tscn test/unit/realm/test_realm_board.gd
git commit -m "feat: add the realm scene with a board, camera and environment"
```

### Task 3.5 — Record the decision as an ADR

**Files:**
- Create: `documentation/adr/0014-burgeon-raises-the-ground.md`
- Modify: `README.md` — the *What generates elevation?* entry under *Open Design Questions*

**Interfaces:** none. This task writes prose, and no task consumes it.

The map carries this as a standing preference for the whole effort: the elevation reasoning
lands in `documentation/adr/` where the rest of M1 can cite it. `0014` is the next free
number. It comes last because the ADR records the shape that shipped, the no-new-layer call
included.

Every decision the ADR states is already settled, and the ticket that settled it is linked
below. **Write them down; do not re-derive, soften or extend them.** `adr/0005` and
`adr/0009` are the house shape at the right length: a `#` title, prose giving the decision and
why it beat the alternatives, then `## Consequences`.

- [ ] **Step 1: Write `documentation/adr/0014-burgeon-raises-the-ground.md`**

Title: `# Burgeon raises the ground`. The body states each of the following, one or two
sentences each, in this order:

- Burgeon is what raises a hex, so a lone zone raises nothing and the second overlapping zone
  of the same domain is the first riser
  ([#27](https://github.com/snackpackgames/cosmicparade/issues/27), [#37](https://github.com/snackpackgames/cosmicparade/issues/37)).
- Depth is capped at 4, and the step is `0.35 × hex circumradius` — a ratio of hex size, never
  a world-space constant. The cap lands on depth at the source, not on rendered height
  ([#29](https://github.com/snackpackgames/cosmicparade/issues/29)).
- Where several domains burgeon on one hex the depths are compared, not added: the hex takes
  the maximum ([#40](https://github.com/snackpackgames/cosmicparade/issues/40)).
- Height is derived from the influence zones on demand and never stored, which is what lets a
  hypothetical arrangement be evaluated without mutating the board
  ([#33](https://github.com/snackpackgames/cosmicparade/issues/33), [#31](https://github.com/snackpackgames/cosmicparade/issues/31)).
- The rise is discrete risers, never a smoothed slope. The prototype in
  `test/prototypes/28-raised-hex-ground-legibility/` is the evidence
  ([#28](https://github.com/snackpackgames/cosmicparade/issues/28)).
- One rule for all six domains; nothing branches per domain
  ([#32](https://github.com/snackpackgames/cosmicparade/issues/32)).
- Raised ground stays on `realm_space` and the layer table does not change, because a raised
  hex is still a hex space of the realm board
  ([#39](https://github.com/snackpackgames/cosmicparade/issues/39)).
- Removing furniture lowers the ground it raised, immediately and with no high-water mark
  ([#38](https://github.com/snackpackgames/cosmicparade/issues/38)).

Rejected alternatives, taken from `README.md → Open Design Questions` as it reads before Step
2 edits it: height-driven generation, rejected before this map was charted as too unpredictable
to decorate on; elevation as a property of specific furniture; and authored relief shipped with
the floating rock. Burgeon won because it gives an existing mechanic a physical meaning and
makes intensity visible without taking height out of the player's hands.

`## Consequences` records what this leaves open rather than what it builds: height becomes a
per-piece placement criterion, read against the board including the placing piece's own
influence ([#30](https://github.com/snackpackgames/cosmicparade/issues/30), [#41](https://github.com/snackpackgames/cosmicparade/issues/41));
the per-domain read and the depth-4 "maxed" read are authored art on a raised hex, deferred
([#32](https://github.com/snackpackgames/cosmicparade/issues/32), [#42](https://github.com/snackpackgames/cosmicparade/issues/42));
and whether a depth of 4 is reachable in play depends on influence zone size, which the
realm board map owns.

- [ ] **Step 2: Move the question out of `README.md → Open Design Questions`**

Delete the whole **What generates elevation?** paragraph from *Open Design Questions*, and add
one bullet to *Settled Decisions* in that section's style — a bold lede then prose, with no ADR
link, since no bullet there carries one:

> - **Burgeon raises the ground.** The same domain's influence overlapping itself lifts the
>   hexes it covers, one discrete riser per overlap past the first, to a ceiling of four. A
>   hex's height is derived from the influence on it, so removing furniture lowers the ground
>   it raised.

- [ ] **Step 3: Verify the question is gone and the ADR is in place**

Run: `! grep -q 'What generates elevation' README.md && ls documentation/adr/0014-*.md`
Expected: the ADR path printed. Any output from `grep` instead means Step 2 is incomplete.

- [ ] **Step 4: Commit**

```bash
git add documentation/adr/0014-burgeon-raises-the-ground.md README.md
git commit -m "docs: record burgeon as what raises the realm's ground"
```

---

## What is finished when this plan is done

The rule is implemented and pinned by tests; a hex's height is derived from the influence zones
covering it with nothing stored; and the board renders it as discrete risers with per-hex prism
collision on `realm_space`. `documentation/adr/0014` records why, and `README.md` no longer
lists elevation as an open question. That is the map's destination.

Three things the map settled that are **deliberately not built here**, each waiting on a system
this plan does not touch:

- **The placement gate** ([#30](https://github.com/snackpackgames/cosmicparade/issues/30),
  [#41](https://github.com/snackpackgames/cosmicparade/issues/41)) — height as a per-piece
  placement criterion, read against the board *including* the placing piece's own influence.
  Ships with furniture placement. `Elevation.height_at()` is what it will call.
- **The terrain preview** ([#31](https://github.com/snackpackgames/cosmicparade/issues/31)) —
  terrain responding while a placement is targeted, committing on landing. Needs an input model
  that is not settled. The accessor taking `zones` as a parameter is what makes it free.
- **The authored looks** ([#32](https://github.com/snackpackgames/cosmicparade/issues/32),
  [#42](https://github.com/snackpackgames/cosmicparade/issues/42)) — the per-domain read and the
  depth-4 "maxed" read, both carried by authored art on a raised hex. `BoardMaterial` is the
  placeholder they replace.
