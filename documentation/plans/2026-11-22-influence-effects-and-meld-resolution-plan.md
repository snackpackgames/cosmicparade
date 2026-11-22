# Influence Effects and Meld Resolution Implementation Plan

> **For agentic workers:** Implement this plan task-by-task, committing after each task as it
> directs. Steps use checkbox (`- [ ]`) syntax for tracking. **Do not create a git worktree** —
> `CLAUDE.md → Claude Code Configuration` forbids them in this repo; work on a topic branch in
> the main working directory. The usual sub-skill for inline execution is
> `superpowers:executing-plans`; `superpowers:subagent-driven-development` is not used here
> because it provisions a worktree.

**Goal:** Overlapping domain influence resolves into an authored set of **influence effects** per
hex — derived from the zones on every call and stored nowhere — and a debug probe shows the whole
derivation for the hex under the cursor.

**Architecture:** One authored table holds every effect the board can show, keyed by the domain
influence that produces it. Resolution is a `static func` over `(hex, zones, table)` in the shape
of `Elevation.depth_at`: greedy subset matching takes the largest authored subset of a hex's
domains first and **consumes** what it claims, so a table of pairs covers every arity and a
one-domain entry is the unclaimed-domain fallback. Depth never keys a lookup — it is a scalar that
**amplifies** an effect, read per effect from its own domains — with exactly one exception, the
authored `ceiling_effect` that joins the set at `Elevation.MAX_DEPTH`. A region is not built: it is
what you see when neighbouring hexes agree. Nothing caches, nothing is stored on `RealmState`, and
`realm/elevation.gd` keeps its shipped behaviour exactly.

**Tech Stack:** Godot 4.7.2-stable, GDScript, GUT 9.7.1.

**Spec:** [Map: what overlapping domains meld into, and where that
lives](https://github.com/snackpackgames/cosmicparade/issues/105) — eight closed decision tickets.
Every rule below links the ticket that settled it. **Where this plan says "decided", the linked
ticket holds the reasoning: do not re-derive it, and do not substitute a different answer because
it looks better in context.** Several tickets carry later *amendment* comments that supersede parts
of their own resolution; the constraints below are the amended state, so prefer this plan's
statement of a rule and read the ticket for why.

This plan builds on
[`2026-11-16-swell-shrines-and-the-altar-plan.md`](2026-11-16-swell-shrines-and-the-altar-plan.md)
and [`2026-11-11-realm-ground-elevation-plan.md`](2026-11-11-realm-ground-elevation-plan.md), both
merged. `Domain`, `InfluenceZone`, `Elevation`, `RealmState`, `HexCursor`, `HexCoordinates`,
`DebugReadout`, `GameData` and the `realm.tscn` wiring all exist and are the inputs here.

## Global Constraints

- **The per-hex answer is a *set* of influence effects, derived from the zones and stored nowhere**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/106), as amended there). A
  `static func` over `(hex, zones, table)` holding no board reference, matching
  `Elevation.depth_at` and `RealmState.zones()`. **No cache, and no hex-to-effects dictionary on
  `RealmState`** — removing furniture must change the answer with no invalidation path to
  maintain. Answers for any coordinate including the void, per `InfluenceZone`'s own convention;
  clipping stays at consumption.
- **An entry is keyed by an unordered set of one or more `Domain.Kind` values; the table is sparse
  and ordered** ([decided](https://github.com/snackpackgames/cosmicparade/issues/107), singletons
  allowed by the amendment from
  [#113](https://github.com/snackpackgames/cosmicparade/issues/113)). Matching is greedy subset
  containment: **the largest authored subset wins and consumes the domains it claims**, ties break
  on **order in the authored file**, and there are **no empty entries**. Reordering the authored
  file is a gameplay change, not layout.
- **A one-domain entry *is* the unclaimed-domain fallback**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/113)). There is **no** six-slot
  array indexed by `Domain.Kind`; do not add one "for symmetry". Consequently `Domain.Kind`'s
  *order* is **not** load-bearing data.
- **No cascading.** Matching runs over domains and a produced effect never re-enters the loop, so a
  fused result cannot itself be fused ([decided](https://github.com/snackpackgames/cosmicparade/issues/107)).
  This falls out of the key's type; do not implement a guard for it.
- **An influence effect is an authored `GameData` Resource, purely visual, and `Domain.Kind` stays
  at exactly six** ([decided](https://github.com/snackpackgames/cosmicparade/issues/108)).
  `test/unit/realm/test_domain.gd:5` asserts `Domain.Kind.size() == 6` and `adr/0005` is the cap —
  **no enum member is added anywhere in this plan**. An effect carries no mechanics, so nothing
  gates placement on it.
- **Depth amplifies; it never keys a lookup**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/113)). Intensity is read **per
  effect from its own domains**: a one-domain entry's effect at that domain's depth, a multi-domain
  entry's at the **maximum among the domains it consumed**. The hex's own depth (the max across all
  domains) drives the risers and the ceiling, **not** each effect's intensity. There are no
  per-depth and no per-domain "maxed" variants.
- **One authored `ceiling_effect` joins the set at `Elevation.MAX_DEPTH`**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/113), preserving what
  [#42](https://github.com/snackpackgames/cosmicparade/issues/42) required). It is the only
  depth-keyed thing in the table, and it cannot be consumed: matching runs over domains and it is
  not a domain.
- **Meld never touches height**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/109)). `Elevation.depth_at`
  keeps reading the whole zone array, and a consumed domain still raises its hex. "Consumed" is a
  statement about effects and only about effects. **No task changes what `realm/elevation.gd`
  returns**; Phase 2 adds reads beside it and the existing elevation tests stay green unchanged.
  `adr/0014` is untouched, and so is the board's geometry.
- **A region is contiguous hexes whose effect *sets* agree** — membership, not intensity
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/106), amended;
  [#109](https://github.com/snackpackgames/cosmicparade/issues/109) records the consequence). Depth
  enters region identity **only** through the `ceiling_effect`, which is why a melded area
  straddling the depth-4 contour is two regions. Intensities differing across a riser contour do
  **not** split a region — if they did, #109's recorded consequence would name every contour rather
  than the depth-4 one. Interior and boundary fall out of adjacency with nothing extra stored.
- **A region carries no provenance** ([decided](https://github.com/snackpackgames/cosmicparade/issues/106)).
  The effect set already names what is there.
- **Every authored effect carries an authored `effect_name: String`**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/114)), the fifth of five such
  fields beside `SwellTier.tier_name`, `Fruit.fruit_name`, `BoardPiece.piece_name` and
  `WingShape.shape_name`. **Never** `Resource.resource_name`, and never derived from a `.tres`
  path. **Entries carry no name** — the probe's `Forest+Flame` label derives from the entry's own
  domains via `Domain.Kind.find_key`, as `realm/debug_readout.gd:82` already does.
- **The vocabulary is "influence effect"**
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/114)): `InfluenceEffect`,
  `InfluenceEffectTable`, `InfluenceEffectEntry`, `ceiling_effect`. The words "look",
  `DomainLook`, `DomainLookTable`, `FusionTable` and `FusionEntry` appear in the tickets' own
  history and **must not appear in shipped code**. `adr/0004` keeps its title and its text, because
  an ADR records what was decided when it was decided.
- **The table's entries ship as placeholders** (map *Notes*, and the map's *Out of scope*). Naming
  what Forest and Flame actually fuse into is content work with its own effort. Author the six
  one-domain entries, **one** placeholder combination entry and the ceiling effect — nothing more.
- **Nothing renders an effect in this plan.** `realm/board_material.gd` stays the board's
  placeholder material, and the shader and particle work it stands in for is `area:ui` and art
  direction — out of scope on the map. The debug probe exposes **the inputs and the match**, never
  the rendered result ([decided](https://github.com/snackpackgames/cosmicparade/issues/110)).
- **The probe is DEBUG ONLY**, hidden outside a debug build like `DebugReadout`, and lives in its
  own node ([decided](https://github.com/snackpackgames/cosmicparade/issues/110)) — **not** an
  extension of `DebugReadout`, whose `refresh(reading, balance, swell)` is recomposed from
  realm-wide values on a different cadence.
- **Conventions that apply throughout** (`CLAUDE.md`): every script declares a `class_name`;
  authored data extends `GameData` and lives at `data/realm/<type>/<instance>.tres`; full
  `snake_case` words, no cryptic abbreviations; run `bash scripts/import.sh` after adding a
  `class_name` and before running tests; commit the `.uid` sidecars Godot generates; `bash
  scripts/lint.sh` must pass.

## Review Focus

Five conditions the spec implies that no task's happy path exercises, most likely to bite first.
Each has a test pinned to the task that owns the code.

1. **A domain covers a hex and no entry claims it.** It contributes nothing and the hex renders
   less than the player's influence implies — the exact failure the six-slot array could not have.
   Pinned: Task 1.4 (the authored table is complete for `Domain.Kind.values()`) and Task 2.3 (an
   unclaimed domain is simply absent from the matches, with no crash and no null member).
2. **An entry is authored empty, or with a null effect.** `domains = []` is a subset of every
   remaining set, so a naive loop matches it forever. Pinned: Task 2.3 (a zero-domain entry never
   matches and never loops) and Task 1.4 (the authored file has none).
3. **A hex reaches `Elevation.MAX_DEPTH` and the table has no `ceiling_effect` authored.** The set
   must not gain a null member, and the probe must still report the hex as at its ceiling. Pinned:
   Task 2.5.
4. **A hex nothing covers.** It has no effects at all, belongs to no region, and the probe must say
   so explicitly rather than render empty — `DebugReadout`'s own `NOTHING_READ` precedent, on the
   stated grounds that a readout of nothing is not read as a missing Altar. Pinned: Task 2.2, Task
   3.4 and Task 4.2.
5. **Zones covering the void.** `InfluenceZone` keeps off-board coordinates in the set and clips at
   consumption, so resolution and regions answer for them. Pinned: Task 3.5.

---

## Phase 1 — The authored table and its placeholder data

Three authored types and one authored table, with the guards that stand in for what a fixed-length
array gave for free.

**Files:**
- Create: `realm/influence_effect.gd`, `realm/influence_effect_entry.gd`,
  `realm/influence_effect_table.gd`
- Create: `data/realm/influence_effect/{forest,grassland,wetland,stone,flame,gale}.tres`,
  `data/realm/influence_effect/fused_placeholder.tres`,
  `data/realm/influence_effect/ceiling.tres`,
  `data/realm/influence_effect_table/board.tres`
- Test: `test/unit/realm/test_influence_effect_entry.gd`,
  `test/unit/realm/test_influence_effect_table.gd`

**Interfaces:**
- Consumes: `GameData` (`common/game_data.gd`), `Domain.Kind` (`realm/domain.gd`).
- Produces: `InfluenceEffect.effect_name`; `InfluenceEffectEntry.domains`,
  `InfluenceEffectEntry.effect`, `InfluenceEffectEntry.claims_within(available: Dictionary) ->
  bool`; `InfluenceEffectTable.entries`, `InfluenceEffectTable.ceiling_effect`,
  `InfluenceEffectTable.BOARD_PATH`.

### Task 1.1: `InfluenceEffect`

- [ ] **Step 1: Write the failing test**

Add to a new `test/unit/realm/test_influence_effect_table.gd` (the authored data and the three
types are tested together, as `test_swell_tier.gd` tests the authored ladder):

```gdscript
extends GutTest
## The authored influence effect table: the shape of the data and the guards on what is authored.


func test_an_effect_extends_the_game_data_base() -> void:
	assert_is(InfluenceEffect.new(), GameData)


func test_an_effect_carries_an_authored_name() -> void:
	var effect := InfluenceEffect.new()
	effect.effect_name = "Forest"
	assert_eq(effect.effect_name, "Forest")
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_influence_effect_table.gd`
Expected: FAIL — `InfluenceEffect` is not a known class.

- [ ] **Step 3: Create `realm/influence_effect.gd`**

```gdscript
class_name InfluenceEffect
extends GameData
## One authored visual effect that projected domain influence produces — a shader or a particle
## effect, carrying no mechanics. Amplified by depth, so the intensity it is shown at is derived
## per hex and nothing about the amplification is authored here.
## https://github.com/snackpackgames/cosmicparade/issues/108
## https://github.com/snackpackgames/cosmicparade/issues/113
## https://github.com/snackpackgames/cosmicparade/issues/114

## Printed by the debug probe. Authored rather than taken from `Resource.resource_name`, which the
## engine never requires, or derived from the `.tres` path, which a rename breaks.
@export var effect_name: String = ""
```

- [ ] **Step 4: Rebuild the class cache and run the test**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_influence_effect_table.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/influence_effect.gd realm/influence_effect.gd.uid \
  test/unit/realm/test_influence_effect_table.gd test/unit/realm/test_influence_effect_table.gd.uid
git commit -m "feat: add the authored influence effect resource"
```

### Task 1.2: `InfluenceEffectEntry` and its subset predicate

The predicate is the only logic an entry owns, and it is where greedy matching asks "could this
entry fire here" — so it belongs to the entry rather than to the matcher.

- [ ] **Step 1: Write the failing test**

`test/unit/realm/test_influence_effect_entry.gd`:

```gdscript
extends GutTest
## One row of the table: a set of domains and the effect they produce.


func _entry(domains: Array[int]) -> InfluenceEffectEntry:
	var entry := InfluenceEffectEntry.new()
	entry.domains = domains
	entry.effect = InfluenceEffect.new()
	return entry


func test_an_entry_claims_a_hex_whose_domains_contain_all_of_its_own() -> void:
	var entry := _entry([Domain.Kind.FOREST, Domain.Kind.FLAME])
	var available := {Domain.Kind.FOREST: true, Domain.Kind.FLAME: true, Domain.Kind.STONE: true}
	assert_true(entry.claims_within(available))


func test_an_entry_missing_one_domain_claims_nothing() -> void:
	var entry := _entry([Domain.Kind.FOREST, Domain.Kind.FLAME])
	assert_false(entry.claims_within({Domain.Kind.FOREST: true}))


func test_a_one_domain_entry_claims_that_domain() -> void:
	assert_true(_entry([Domain.Kind.STONE]).claims_within({Domain.Kind.STONE: true}))


# https://github.com/snackpackgames/cosmicparade/issues/107 — no empty entries. An entry claiming
# no domains is a subset of everything, so without this it would match every hex forever.
func test_an_entry_claiming_no_domains_never_claims_anything() -> void:
	assert_false(_entry([]).claims_within({Domain.Kind.STONE: true}))
	assert_false(_entry([]).claims_within({}))
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_influence_effect_entry.gd`
Expected: FAIL — `InfluenceEffectEntry` is not a known class.

- [ ] **Step 3: Create `realm/influence_effect_entry.gd`**

```gdscript
class_name InfluenceEffectEntry
extends GameData
## One or more domains and the influence effect they produce. The domains are a set: order here is
## irrelevant, so Forest-then-Flame and Flame-then-Forest are the same entry.
## https://github.com/snackpackgames/cosmicparade/issues/107
## https://github.com/snackpackgames/cosmicparade/issues/113

## `Domain.Kind` values. `Array[int]` rather than `Array[Domain.Kind]` because GDScript has no
## enum-typed arrays.
@export var domains: Array[int] = []
@export var effect: InfluenceEffect


## True when every domain this entry needs is among `available`, whose keys are `Domain.Kind`
## values. An entry claiming no domains claims nothing: the empty set is a subset of every set, so
## without that case greedy matching would never terminate.
func claims_within(available: Dictionary) -> bool:
	if domains.is_empty():
		return false
	for domain: int in domains:
		if not available.has(domain):
			return false
	return true
```

- [ ] **Step 4: Rebuild the class cache and run the test**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_influence_effect_entry.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/influence_effect_entry.gd realm/influence_effect_entry.gd.uid \
  test/unit/realm/test_influence_effect_entry.gd test/unit/realm/test_influence_effect_entry.gd.uid
git commit -m "feat: add an influence effect table entry keyed by a domain set"
```

### Task 1.3: `InfluenceEffectTable`

- [ ] **Step 1: Write the failing test**

Append to `test/unit/realm/test_influence_effect_table.gd`:

```gdscript
func test_a_table_holds_ordered_entries_and_one_ceiling_effect() -> void:
	var table := InfluenceEffectTable.new()
	var entry := InfluenceEffectEntry.new()
	entry.domains = [Domain.Kind.STONE]
	table.entries = [entry] as Array[InfluenceEffectEntry]
	table.ceiling_effect = InfluenceEffect.new()
	assert_eq(table.entries.size(), 1)
	assert_not_null(table.ceiling_effect)
	assert_is(table, GameData)
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_influence_effect_table.gd`
Expected: FAIL — `InfluenceEffectTable` is not a known class.

- [ ] **Step 3: Create `realm/influence_effect_table.gd`**

`BOARD_PATH` follows `Swell.TIER_PATHS`: the authored path lives with the type that reads it, so
tests and `realm.gd` do not each spell it out.

```gdscript
class_name InfluenceEffectTable
extends GameData
## Every influence effect the board can show, keyed by the domain influence that produces it.
## https://github.com/snackpackgames/cosmicparade/issues/107
## https://github.com/snackpackgames/cosmicparade/issues/113

## The realm's one authored table.
const BOARD_PATH := "res://data/realm/influence_effect_table/board.tres"

## Ordered, and sparse. Greedy matching takes the largest subset of a hex's domains first and
## consumes what it claims; ties break on the order here, so reordering this list is a gameplay
## change and not layout. A one-domain entry is the unclaimed-domain fallback.
@export var entries: Array[InfluenceEffectEntry] = []

## Added to a hex's effect set when a burgeon stack is at `Elevation.MAX_DEPTH` — the only thing
## here keyed on depth rather than on domains, and the only reason a melded area can be split by
## the depth-4 contour. Depth otherwise amplifies an effect instead of selecting one.
## https://github.com/snackpackgames/cosmicparade/issues/42
@export var ceiling_effect: InfluenceEffect
```

- [ ] **Step 4: Rebuild the class cache and run the test**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_influence_effect_table.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/influence_effect_table.gd realm/influence_effect_table.gd.uid \
  test/unit/realm/test_influence_effect_table.gd
git commit -m "feat: add the influence effect table resource"
```

### Task 1.4: The authored placeholder table, and the guards on it

Eight effect files and one table. The entries are authored **inline** as `[sub_resource]` blocks
in `board.tres` rather than as separate `.tres` files, because file order is the tie-break and the
probe prints an entry's index in it — precedence has to be readable in one place. The effects are
separate files: they are the authored content the deferred art replaces, and more than one entry
may come to share one.

**The six one-domain effects are named for their domains** (`Forest`, `Grassland`, `Wetland`,
`Stone`, `Flame`, `Gale`), which is what the probe's decided block prints for an unclaimed domain.
**The combination entry and the ceiling effect are named as placeholders** — the map rules the
content out of scope, so do not invent a fused name.

- [ ] **Step 1: Write the failing test**

Append to `test/unit/realm/test_influence_effect_table.gd`:

```gdscript
const AUTHORED := InfluenceEffectTable.BOARD_PATH


func _authored() -> InfluenceEffectTable:
	return load(AUTHORED)


# https://github.com/snackpackgames/cosmicparade/issues/113 — the completeness guard that replaces
# what a fixed six-slot array gave for free. A domain with no one-domain entry renders nothing.
func test_every_domain_has_a_one_domain_entry() -> void:
	var claimed: Dictionary = {}
	for entry: InfluenceEffectEntry in _authored().entries:
		if entry.domains.size() == 1:
			claimed[entry.domains[0]] = true
	for domain: Domain.Kind in Domain.Kind.values():
		assert_true(claimed.has(domain), "no one-domain entry for %s" % Domain.Kind.find_key(domain))


# https://github.com/snackpackgames/cosmicparade/issues/114 — an unnamed effect prints empty in the
# probe with nothing to catch it.
func test_every_authored_effect_is_named() -> void:
	var table := _authored()
	for entry: InfluenceEffectEntry in table.entries:
		assert_not_null(entry.effect)
		assert_ne(entry.effect.effect_name, "")
	assert_not_null(table.ceiling_effect)
	assert_ne(table.ceiling_effect.effect_name, "")


# https://github.com/snackpackgames/cosmicparade/issues/107 — no empty entries, and no duplicate
# key: a second entry claiming the same set could never win a tie, so it is dead data.
func test_no_entry_is_empty_and_no_domain_set_repeats() -> void:
	var seen: Dictionary = {}
	for entry: InfluenceEffectEntry in _authored().entries:
		assert_false(entry.domains.is_empty())
		var sorted := entry.domains.duplicate()
		sorted.sort()
		assert_eq(sorted.size(), entry.domains.size())
		var key := ",".join(sorted.map(func(domain: int) -> String: return str(domain)))
		assert_false(seen.has(key), "two entries claim %s" % key)
		seen[key] = true


# The placeholder set the map's scope allows: six one-domain entries plus one combination.
func test_the_authored_table_ships_one_placeholder_combination() -> void:
	var combinations := 0
	for entry: InfluenceEffectEntry in _authored().entries:
		if entry.domains.size() > 1:
			combinations += 1
	assert_eq(combinations, 1)
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_influence_effect_table.gd`
Expected: FAIL — the authored resource does not exist, so `load()` returns `null`.

- [ ] **Step 3: Author the eight effects**

Six one-domain effects at `data/realm/influence_effect/<domain>.tres`, on the shape
`data/realm/swell_tier/01_first_ring.tres` already uses:

```
[gd_resource type="Resource" script_class="InfluenceEffect" load_steps=2 format=3]

[ext_resource type="Script" path="res://realm/influence_effect.gd" id="1_effect"]

[resource]
script = ExtResource("1_effect")
effect_name = "Forest"
```

Then `fused_placeholder.tres` with `effect_name = "fused placeholder"` and `ceiling.tres` with
`effect_name = "at ceiling"`.

- [ ] **Step 4: Author `data/realm/influence_effect_table/board.tres`**

The combination entry first, then the six one-domain entries in `Domain.Kind` order. Order is only
a tie-break between entries of equal size, so the combination's position is readability rather than
rule — specific before general. Its domains are `[Domain.Kind.FOREST, Domain.Kind.FLAME]` as
integers `[0, 4]`, matching the probe's decided example.

```
[gd_resource type="Resource" script_class="InfluenceEffectTable" load_steps=11 format=3]

[ext_resource type="Script" path="res://realm/influence_effect_table.gd" id="1_table"]
[ext_resource type="Script" path="res://realm/influence_effect_entry.gd" id="2_entry"]
[ext_resource type="Resource" path="res://data/realm/influence_effect/fused_placeholder.tres" id="3_fused"]
[ext_resource type="Resource" path="res://data/realm/influence_effect/forest.tres" id="4_forest"]
...
[ext_resource type="Resource" path="res://data/realm/influence_effect/ceiling.tres" id="10_ceiling"]

[sub_resource type="Resource" id="Entry_fused"]
script = ExtResource("2_entry")
domains = Array[int]([0, 4])
effect = ExtResource("3_fused")

...

[resource]
script = ExtResource("1_table")
entries = Array[InfluenceEffectEntry]([SubResource("Entry_fused"), SubResource("Entry_forest"), ...])
ceiling_effect = ExtResource("10_ceiling")
```

Open the project once in the editor (or run `bash scripts/import.sh`) so Godot writes the `.uid`
sidecars and validates the `script_class` names. If the editor rewrites `load_steps` or re-orders
the `ext_resource` ids, commit its version — the engine owns that bookkeeping.

- [ ] **Step 5: Run the test**

Run: `bash scripts/test.sh realm/test_influence_effect_table.gd`
Expected: PASS, all tests.

- [ ] **Step 6: Lint and commit**

```bash
bash scripts/lint.sh
git add realm/influence_effect*.gd realm/influence_effect*.gd.uid data/realm/influence_effect \
  data/realm/influence_effect_table test/unit/realm/test_influence_effect_table.gd
git commit -m "feat: author the placeholder influence effect table"
```

---

## Phase 2 — The resolution rule

The whole of meld resolution: a per-domain read exposed on `Elevation`, the greedy matcher, and
per-effect intensity. **`Elevation`'s shipped behaviour does not change** — `depth_at` returns what
it returns today, and `test/unit/realm/test_elevation.gd` passes unmodified.

**Files:**
- Modify: `realm/elevation.gd`
- Create: `realm/effect_match.gd`, `realm/meld_resolution.gd`, `realm/meld.gd`
- Test: `test/unit/realm/test_elevation.gd` (add), `test/unit/realm/test_meld.gd` (create)

**Interfaces:**
- Consumes: `InfluenceEffectTable`, `InfluenceEffectEntry.claims_within`, `InfluenceZone.covers`,
  `Domain.Kind`, `Elevation.MAX_DEPTH`.
- Produces: `Elevation.zone_counts(hex, zones) -> Dictionary`,
  `Elevation.depth_for_count(count: int) -> int`,
  `Elevation.depths_by_domain(hex, zones) -> Dictionary`;
  `EffectMatch` with `entry_index: int`, `domains: Array[int]`, `effect: InfluenceEffect`,
  `intensity: int`, `intensity_domain: Domain.Kind`;
  `MeldResolution` with `zone_counts: Dictionary`, `matches: Array[EffectMatch]`, `depth: int`,
  `depth_domain: Domain.Kind`, `at_ceiling: bool`, `ceiling_effect: InfluenceEffect`,
  `is_empty() -> bool`, `effects() -> Array[InfluenceEffect]`,
  `agrees_with(other: MeldResolution) -> bool`;
  `Meld.resolve(hex, zones, table) -> MeldResolution`.

### Task 2.1: Expose the per-domain read on `Elevation`

`depth_at` already builds the per-domain counts internally and discards all but the maximum. This
is additive: the maximum still drives height, and the breakdown exists because an influence effect
takes the depth of **its own** domains
([decided](https://github.com/snackpackgames/cosmicparade/issues/113)).

- [ ] **Step 1: Write the failing test**

Append to `test/unit/realm/test_elevation.gd`, reusing that file's existing zone helper:

```gdscript
func test_zone_counts_tally_the_zones_per_domain() -> void:
	var zones: Array[InfluenceZone] = [
		_zone(Domain.Kind.FOREST, [Vector2i.ZERO]),
		_zone(Domain.Kind.FOREST, [Vector2i.ZERO]),
		_zone(Domain.Kind.STONE, [Vector2i.ZERO]),
		_zone(Domain.Kind.FLAME, [Vector2i(5, 0)]),
	]
	var counts := Elevation.zone_counts(Vector2i.ZERO, zones)
	assert_eq(counts[Domain.Kind.FOREST], 2)
	assert_eq(counts[Domain.Kind.STONE], 1)
	assert_false(counts.has(Domain.Kind.FLAME))


func test_a_depth_is_one_less_than_the_count_capped_at_the_maximum() -> void:
	assert_eq(Elevation.depth_for_count(0), 0)
	assert_eq(Elevation.depth_for_count(1), 0)
	assert_eq(Elevation.depth_for_count(3), 2)
	assert_eq(Elevation.depth_for_count(99), Elevation.MAX_DEPTH)


func test_depths_by_domain_keeps_each_domain_separate_where_depth_at_takes_the_maximum() -> void:
	var zones: Array[InfluenceZone] = []
	for _i in 5:
		zones.append(_zone(Domain.Kind.STONE, [Vector2i.ZERO]))
	for _i in 2:
		zones.append(_zone(Domain.Kind.FOREST, [Vector2i.ZERO]))
	var depths := Elevation.depths_by_domain(Vector2i.ZERO, zones)
	assert_eq(depths[Domain.Kind.STONE], Elevation.MAX_DEPTH)
	assert_eq(depths[Domain.Kind.FOREST], 1)
	assert_eq(Elevation.depth_at(Vector2i.ZERO, zones), Elevation.MAX_DEPTH)


func test_a_hex_nothing_covers_has_no_domains_at_all() -> void:
	var zones: Array[InfluenceZone] = []
	assert_true(Elevation.zone_counts(Vector2i.ZERO, zones).is_empty())
	assert_true(Elevation.depths_by_domain(Vector2i.ZERO, zones).is_empty())
	assert_eq(Elevation.depth_at(Vector2i.ZERO, zones), 0)
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_elevation.gd`
Expected: FAIL — `zone_counts`, `depth_for_count` and `depths_by_domain` do not exist. The file's
existing tests pass.

- [ ] **Step 3: Add the three reads to `realm/elevation.gd`**

Refactor `depth_at` to take the maximum of `depths_by_domain` so the `count - 1` rule lives in
exactly one place. Keep `MAX_DEPTH`, `STEP_RATIO`, `height_for_depth` and `height_at` exactly as
they are. Each new function gets a doc comment saying the maximum is height's and the breakdown is
the effects', pointing at
[#113](https://github.com/snackpackgames/cosmicparade/issues/113), and the class doc comment gains
a line that `adr/0014` is unchanged by the addition.

- [ ] **Step 4: Run the whole elevation suite**

Run: `bash scripts/test.sh realm/test_elevation.gd`
Expected: PASS, including every pre-existing test unmodified.

- [ ] **Step 5: Commit**

```bash
git add realm/elevation.gd test/unit/realm/test_elevation.gd
git commit -m "feat: expose elevation's per-domain depth read"
```

### Task 2.2: The resolution types, and a hex nothing covers

- [ ] **Step 1: Write the failing test**

`test/unit/realm/test_meld.gd`. The helpers here are used by every later task in this phase, so
write them now:

```gdscript
extends GutTest
## Meld resolution: which authored influence effects a hex shows, and at what intensity.


func _effect(name: String) -> InfluenceEffect:
	var effect := InfluenceEffect.new()
	effect.effect_name = name
	return effect


func _entry(domains: Array[int], effect: InfluenceEffect) -> InfluenceEffectEntry:
	var entry := InfluenceEffectEntry.new()
	entry.domains = domains
	entry.effect = effect
	return entry


# A table of one-domain entries for every domain, named for the domain, plus whatever extra
# entries a test wants in front of them — in front, because order is the tie-break.
func _table(extra: Array[InfluenceEffectEntry] = []) -> InfluenceEffectTable:
	var table := InfluenceEffectTable.new()
	var entries: Array[InfluenceEffectEntry] = []
	entries.assign(extra)
	for domain: Domain.Kind in Domain.Kind.values():
		entries.append(_entry([domain], _effect(Domain.Kind.find_key(domain) as String)))
	table.entries = entries
	table.ceiling_effect = _effect("ceiling")
	return table


func _zones(counts: Dictionary, hex: Vector2i = Vector2i.ZERO) -> Array[InfluenceZone]:
	var zones: Array[InfluenceZone] = []
	for domain: int in counts:
		for _i in counts[domain] as int:
			zones.append(InfluenceZone.new(domain, [hex] as Array[Vector2i]))
	return zones


func _names(effects: Array[InfluenceEffect]) -> Array[String]:
	var names: Array[String] = []
	for effect in effects:
		names.append(effect.effect_name)
	return names


# https://github.com/snackpackgames/cosmicparade/issues/107 — a hex nothing covers has no effects
# at all. The table holds nothing for it, by construction.
func test_a_hex_nothing_covers_resolves_to_nothing() -> void:
	var resolution := Meld.resolve(Vector2i.ZERO, [] as Array[InfluenceZone], _table())
	assert_true(resolution.is_empty())
	assert_eq(resolution.matches.size(), 0)
	assert_eq(resolution.effects().size(), 0)
	assert_eq(resolution.depth, 0)
	assert_false(resolution.at_ceiling)


func test_one_domain_fires_its_own_entry() -> void:
	var resolution := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.STONE: 1}), _table()
	)
	assert_false(resolution.is_empty())
	assert_eq(_names(resolution.effects()), ["STONE"] as Array[String])
	assert_eq(resolution.matches[0].domains, [Domain.Kind.STONE] as Array[int])
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_meld.gd`
Expected: FAIL — `Meld` is not a known class.

- [ ] **Step 3: Create `realm/effect_match.gd` and `realm/meld_resolution.gd`**

```gdscript
class_name EffectMatch
extends RefCounted
## One entry firing on one hex: which entry it was, the domains it consumed, the effect it
## produced, and the intensity that effect is shown at.
## https://github.com/snackpackgames/cosmicparade/issues/110
## https://github.com/snackpackgames/cosmicparade/issues/113

## The entry's index in the authored file. Ties break on that order, so "why did this entry win
## here" is answerable only when the index survives into the answer.
var entry_index: int
var domains: Array[int] = []
var effect: InfluenceEffect
## The depth this effect is amplified by: the maximum depth among `domains`, which is the same max
## rule height applies, asked of a narrower set.
var intensity: int
## Which of `domains` set the intensity. Ties go to the lowest `Domain.Kind` value, so the probe's
## text is stable.
var intensity_domain: Domain.Kind
```

```gdscript
class_name MeldResolution
extends RefCounted
## What one hex shows, derived and stored nowhere: the entries that fired, in match order, the
## depth beneath them, and whether the hex is at its burgeon ceiling.
## https://github.com/snackpackgames/cosmicparade/issues/106
## https://github.com/snackpackgames/cosmicparade/issues/109

## Zones covering the hex, per domain — the counts `Elevation` reads, carried because the debug
## probe cannot check the depth line without them.
var zone_counts: Dictionary = {}
var matches: Array[EffectMatch] = []
## The hex's own depth: the maximum across domains, which is what the risers follow.
var depth: int = 0
var depth_domain: Domain.Kind = Domain.Kind.FOREST
var at_ceiling: bool = false
## The table's ceiling effect when `at_ceiling`, and null otherwise — including when the hex is at
## its ceiling and the table authors no ceiling effect.
var ceiling_effect: InfluenceEffect


func is_empty() -> bool:
	return zone_counts.is_empty()


## The set a region compares and the renderer draws: one effect per entry that fired, with the
## ceiling effect last when the hex is at its ceiling.
func effects() -> Array[InfluenceEffect]:
	...


## True when both hexes show the same effects. Membership only: two hexes showing the same effects
## at different intensities agree, because depth enters region identity through the ceiling effect
## alone — otherwise every riser contour would split a region, which is not the consequence
## #109 recorded.
func agrees_with(other: MeldResolution) -> bool:
	...
```

- [ ] **Step 4: Create `realm/meld.gd` with `resolve` returning the empty and single-domain cases**

Write the class doc comment, `resolve`'s signature, and enough of the body for these two tests —
the greedy loop arrives in Task 2.3.

```gdscript
class_name Meld
extends RefCounted
## Meld resolution: the influence effects a hex shows, derived from the zones covering it and the
## authored table on every call. A `static func` over `(hex, zones, table)` holding no board
## reference, exactly as `Elevation.depth_at` and `RealmState.zones()` do, so removing furniture
## changes the answer with no invalidation path to maintain. Answers for any coordinate including
## the void; clipping stays at consumption.
## https://github.com/snackpackgames/cosmicparade/issues/106
## https://github.com/snackpackgames/cosmicparade/issues/107

static func resolve(
	hex: Vector2i, zones: Array[InfluenceZone], table: InfluenceEffectTable
) -> MeldResolution:
	...
```

- [ ] **Step 5: Rebuild the class cache and run the test**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_meld.gd`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add realm/effect_match.gd realm/effect_match.gd.uid realm/meld_resolution.gd \
  realm/meld_resolution.gd.uid realm/meld.gd realm/meld.gd.uid \
  test/unit/realm/test_meld.gd test/unit/realm/test_meld.gd.uid
git commit -m "feat: derive a hex's influence effects from the zones covering it"
```

### Task 2.3: Greedy matching — largest wins, consumes, ties on file order

The heart of the rule ([decided](https://github.com/snackpackgames/cosmicparade/issues/107)).

- [ ] **Step 1: Write the failing test**

Append to `test/unit/realm/test_meld.gd`:

```gdscript
func test_a_pair_entry_wins_and_consumes_both_its_domains() -> void:
	var fused := _effect("fused")
	var table := _table([_entry([Domain.Kind.FOREST, Domain.Kind.FLAME], fused)])
	var resolution := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.FOREST: 1, Domain.Kind.FLAME: 1}), table
	)
	assert_eq(_names(resolution.effects()), ["fused"] as Array[String])
	assert_eq(resolution.matches.size(), 1)
	assert_eq(resolution.matches[0].entry_index, 0)


# The worked example from #107: Forest, Flame and Wetland, with the pair authored and no triple.
func test_a_domain_no_entry_claimed_fires_its_own_one_domain_entry() -> void:
	var table := _table([_entry([Domain.Kind.FOREST, Domain.Kind.FLAME], _effect("fused"))])
	var resolution := Meld.resolve(
		Vector2i.ZERO,
		_zones({Domain.Kind.FOREST: 1, Domain.Kind.FLAME: 1, Domain.Kind.WETLAND: 1}),
		table
	)
	assert_eq(_names(resolution.effects()), ["fused", "WETLAND"] as Array[String])


func test_the_largest_subset_wins_over_a_pair_it_contains() -> void:
	var table := _table([
		_entry([Domain.Kind.FOREST, Domain.Kind.FLAME], _effect("pair")),
		_entry([Domain.Kind.FOREST, Domain.Kind.FLAME, Domain.Kind.STONE], _effect("triple")),
	])
	var resolution := Meld.resolve(
		Vector2i.ZERO,
		_zones({Domain.Kind.FOREST: 1, Domain.Kind.FLAME: 1, Domain.Kind.STONE: 1}),
		table
	)
	assert_eq(_names(resolution.effects()), ["triple"] as Array[String])


func test_a_tie_between_equal_sized_entries_goes_to_the_earlier_in_the_file() -> void:
	var table := _table([
		_entry([Domain.Kind.FOREST, Domain.Kind.FLAME], _effect("first")),
		_entry([Domain.Kind.FOREST, Domain.Kind.STONE], _effect("second")),
	])
	var resolution := Meld.resolve(
		Vector2i.ZERO,
		_zones({Domain.Kind.FOREST: 1, Domain.Kind.FLAME: 1, Domain.Kind.STONE: 1}),
		table
	)
	assert_eq(_names(resolution.effects()), ["first", "STONE"] as Array[String])


# Review Focus 1: a domain covers the hex and the table claims it nowhere. It contributes nothing
# — no match, no null member — and the hex renders less than the player's influence implies, which
# is what Task 1.4's completeness guard exists to prevent in the authored file.
func test_a_domain_no_entry_claims_at_all_contributes_nothing() -> void:
	var table := InfluenceEffectTable.new()
	table.entries = [_entry([Domain.Kind.STONE], _effect("Stone"))] as Array[InfluenceEffectEntry]
	var resolution := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.STONE: 1, Domain.Kind.GALE: 2}), table
	)
	assert_eq(_names(resolution.effects()), ["Stone"] as Array[String])
	assert_eq(resolution.matches.size(), 1)
	assert_eq(resolution.depth, 1, "Gale still raises the hex it shows nothing on")


# Review Focus 2: the empty set is a subset of everything, so an authored zero-domain entry must
# never match and must never hang the loop.
func test_an_entry_claiming_no_domains_is_skipped() -> void:
	var table := _table([_entry([], _effect("empty"))])
	var resolution := Meld.resolve(Vector2i.ZERO, _zones({Domain.Kind.GALE: 1}), table)
	assert_eq(_names(resolution.effects()), ["GALE"] as Array[String])
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_meld.gd`
Expected: FAIL — only the one-domain path exists.

- [ ] **Step 3: Implement the greedy loop in `Meld.resolve`**

The algorithm is the one
[#107](https://github.com/snackpackgames/cosmicparade/issues/107) settled; the code block is here
because neither the signature nor the tests determine it:

```
remaining = the domains covering the hex, as a set
loop:
    best = -1, best_size = 0
    for index, entry in table.entries:          # file order
        if entry.claims_within(remaining) and entry.domains.size() > best_size:
            best, best_size = index, entry.domains.size()   # strict >, so the first of a tie wins
    if best < 0:
        break
    append an EffectMatch for table.entries[best]
    erase every domain of that entry from remaining
```

Scanning the whole list per round is deliberate: the table is at most 57 entries plus six, and a
sorted index would have to be rebuilt whenever the authored order changed — the order that *is*
the tie-break. Termination is guaranteed because every round erases at least one domain, which the
zero-domain guard in `claims_within` is what secures.

- [ ] **Step 4: Run the test**

Run: `bash scripts/test.sh realm/test_meld.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/meld.gd test/unit/realm/test_meld.gd
git commit -m "feat: match influence effect entries greedily, largest subset first"
```

### Task 2.4: Intensity per effect, from its own domains

- [ ] **Step 1: Write the failing test**

Append to `test/unit/realm/test_meld.gd`. The first test is
[#113](https://github.com/snackpackgames/cosmicparade/issues/113)'s worked example verbatim, and it
is the bug that decision exists to rule out:

```gdscript
func test_a_fused_effect_is_amplified_by_its_own_domains_not_by_the_hex() -> void:
	var table := _table([_entry([Domain.Kind.FOREST, Domain.Kind.FLAME], _effect("fused"))])
	var resolution := Meld.resolve(
		Vector2i.ZERO,
		_zones({Domain.Kind.STONE: 4, Domain.Kind.FOREST: 2, Domain.Kind.FLAME: 1}),
		table
	)
	assert_eq(resolution.depth, 3, "the hex's depth comes from Stone")
	assert_eq(resolution.depth_domain, Domain.Kind.STONE)
	var fused := resolution.matches[0]
	assert_eq(fused.effect.effect_name, "fused")
	assert_eq(fused.intensity, 1, "Forest's depth, the max of Forest's 1 and Flame's 0")
	assert_eq(fused.intensity_domain, Domain.Kind.FOREST)
	var stone := resolution.matches[1]
	assert_eq(stone.intensity, 3)
	assert_eq(stone.intensity_domain, Domain.Kind.STONE)


func test_a_one_domain_effect_is_amplified_by_that_domain() -> void:
	var resolution := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.WETLAND: 3}), _table()
	)
	assert_eq(resolution.matches[0].intensity, 2)
	assert_eq(resolution.matches[0].intensity_domain, Domain.Kind.WETLAND)


func test_a_lone_zone_amplifies_nothing() -> void:
	var resolution := Meld.resolve(Vector2i.ZERO, _zones({Domain.Kind.GALE: 1}), _table())
	assert_eq(resolution.matches[0].intensity, 0)
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_meld.gd`
Expected: FAIL — intensity is unset or zero.

- [ ] **Step 3: Fill in intensity, `depth` and `depth_domain` in `Meld.resolve`**

Read the per-domain depths once with `Elevation.depths_by_domain`, take the hex's `depth` and
`depth_domain` as the maximum over all of them, and each match's `intensity` and
`intensity_domain` as the maximum over that entry's own `domains`. Break both ties on the lowest
`Domain.Kind` value.

- [ ] **Step 4: Run the test**

Run: `bash scripts/test.sh realm/test_meld.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/meld.gd test/unit/realm/test_meld.gd
git commit -m "feat: amplify each influence effect by its own domains' depth"
```

### Task 2.5: The ceiling effect, and the pin that meld never touches height

- [ ] **Step 1: Write the failing test**

Append to `test/unit/realm/test_meld.gd`:

```gdscript
func test_the_ceiling_effect_joins_the_set_at_the_maximum_depth() -> void:
	var table := _table()
	var resolution := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.STONE: Elevation.MAX_DEPTH + 1}), table
	)
	assert_true(resolution.at_ceiling)
	assert_eq(_names(resolution.effects()), ["STONE", "ceiling"] as Array[String])


func test_below_the_maximum_depth_the_ceiling_effect_is_absent() -> void:
	var resolution := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.STONE: Elevation.MAX_DEPTH}), _table()
	)
	assert_false(resolution.at_ceiling)
	assert_eq(_names(resolution.effects()), ["STONE"] as Array[String])


# Review Focus 3: the ceiling is a fact about depth, not about what is authored. A table with no
# ceiling effect still reports the hex as at its ceiling, and must not put a null in the set.
func test_an_unauthored_ceiling_effect_leaves_the_set_clean() -> void:
	var table := _table()
	table.ceiling_effect = null
	var resolution := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.STONE: Elevation.MAX_DEPTH + 1}), table
	)
	assert_true(resolution.at_ceiling)
	assert_eq(_names(resolution.effects()), ["STONE"] as Array[String])


# https://github.com/snackpackgames/cosmicparade/issues/109 — the pin that decision asked for.
# "Consumed" is a statement about effects and only about effects: a consumed domain still raises
# its hex, so the authored table can never change what can legally be placed.
func test_depth_is_identical_with_and_without_a_matching_entry() -> void:
	var zones := _zones({Domain.Kind.FOREST: 3, Domain.Kind.FLAME: 2})
	var bare := _table()
	var fused := _table([_entry([Domain.Kind.FOREST, Domain.Kind.FLAME], _effect("fused"))])
	assert_eq(Meld.resolve(Vector2i.ZERO, zones, bare).depth, 2)
	assert_eq(Meld.resolve(Vector2i.ZERO, zones, fused).depth, 2)
	assert_eq(Elevation.depth_at(Vector2i.ZERO, zones), 2)
	assert_eq(Elevation.height_at(Vector2i.ZERO, zones), Elevation.height_for_depth(2))
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_meld.gd`
Expected: FAIL on the ceiling tests; the depth pin passes already, which is the point of it.

- [ ] **Step 3: Set `at_ceiling` and `ceiling_effect` in `Meld.resolve`, and include it in `effects()`**

`at_ceiling` is `depth == Elevation.MAX_DEPTH`. `ceiling_effect` is the table's, and only when
`at_ceiling`. `effects()` appends it last, and only when it is not null.

- [ ] **Step 4: Run the test**

Run: `bash scripts/test.sh realm/test_meld.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/meld.gd realm/meld_resolution.gd test/unit/realm/test_meld.gd
git commit -m "feat: compose the ceiling effect into a maxed hex's effect set"
```

### Task 2.6: `agrees_with`, the comparison a region is built on

- [ ] **Step 1: Write the failing test**

Append to `test/unit/realm/test_meld.gd`:

```gdscript
func test_two_hexes_with_the_same_effects_agree_whatever_their_intensities() -> void:
	var table := _table()
	var shallow := Meld.resolve(Vector2i.ZERO, _zones({Domain.Kind.STONE: 1}), table)
	var deep := Meld.resolve(Vector2i.ZERO, _zones({Domain.Kind.STONE: 3}), table)
	assert_true(shallow.agrees_with(deep))
	assert_true(deep.agrees_with(shallow))


func test_hexes_differing_by_the_ceiling_effect_alone_disagree() -> void:
	var table := _table()
	var below := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.STONE: Elevation.MAX_DEPTH}), table
	)
	var at := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.STONE: Elevation.MAX_DEPTH + 1}), table
	)
	assert_false(below.agrees_with(at))


func test_different_domains_disagree_and_two_bare_hexes_agree() -> void:
	var table := _table()
	var stone := Meld.resolve(Vector2i.ZERO, _zones({Domain.Kind.STONE: 1}), table)
	var gale := Meld.resolve(Vector2i.ZERO, _zones({Domain.Kind.GALE: 1}), table)
	var nothing := Meld.resolve(Vector2i.ZERO, [] as Array[InfluenceZone], table)
	assert_false(stone.agrees_with(gale))
	assert_false(stone.agrees_with(nothing))
	assert_true(nothing.agrees_with(Meld.resolve(Vector2i(9, 9), [] as Array[InfluenceZone], table)))
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_meld.gd`
Expected: FAIL — `agrees_with` is unimplemented.

- [ ] **Step 3: Implement `MeldResolution.agrees_with`**

Compare `effects()` as unordered sets of instances. Godot caches resources by path, so every read
of the authored table yields the same `InfluenceEffect` instances and instance identity is the
right comparison — which holds only while an effect is shared authored data. Say so in the doc
comment: if an effect is ever instanced per hex to carry per-hex shader parameters, this comparison
silently reports every hex as its own region
([#108](https://github.com/snackpackgames/cosmicparade/issues/108)).

- [ ] **Step 4: Run the whole realm suite**

Run: `bash scripts/test.sh realm`
Expected: PASS — nothing in the existing suite changes behaviour.

- [ ] **Step 5: Lint and commit**

```bash
bash scripts/lint.sh
git add realm/meld_resolution.gd test/unit/realm/test_meld.gd
git commit -m "feat: compare two hexes' influence effects as sets"
```

---

## Phase 3 — Regions

A region is not a thing the system builds — it is what you see when neighbouring hexes agree
([decided](https://github.com/snackpackgames/cosmicparade/issues/106)). The grouping is built on
the per-hex rule and is never a second source of truth.

**Files:**
- Create: `realm/meld_region.gd`
- Modify: `realm/meld.gd`
- Test: `test/unit/realm/test_meld_region.gd` (create), `test/unit/realm/test_meld.gd` (add)

**Interfaces:**
- Consumes: `Meld.resolve`, `MeldResolution.agrees_with`, `MeldResolution.effects`,
  `InfluenceZone.coordinates`, `HexCoordinates.neighbors`.
- Produces: `MeldRegion` with `effects: Array[InfluenceEffect]`, `hexes: Array[Vector2i]`,
  `size() -> int`, `contains(hex) -> bool`, `interior() -> Array[Vector2i]`,
  `boundary() -> Array[Vector2i]`; `Meld.region_at(hex, zones, table) -> MeldRegion`;
  `Meld.regions(zones, table) -> Array[MeldRegion]`.

### Task 3.1: `MeldRegion`, with interior and boundary derived

`adr/0008` takes a region's interior for biome fill and walks its boundary for feature spawning.
That is M2 and out of this map's scope as a *system*; the classification itself is what
[#106](https://github.com/snackpackgames/cosmicparade/issues/106) settled falls out of adjacency,
so it lives here and stores nothing.

- [ ] **Step 1: Write the failing test**

`test/unit/realm/test_meld_region.gd`:

```gdscript
extends GutTest
## A region: contiguous hexes whose influence effects agree. Interior and boundary fall out of
## adjacency, with nothing extra stored.


func _region(hexes: Array[Vector2i]) -> MeldRegion:
	return MeldRegion.new([] as Array[InfluenceEffect], hexes)


func test_a_region_knows_its_size_and_its_members() -> void:
	var region := _region([Vector2i.ZERO, Vector2i(1, 0)])
	assert_eq(region.size(), 2)
	assert_true(region.contains(Vector2i(1, 0)))
	assert_false(region.contains(Vector2i(5, 5)))


# A disc of radius 1 is seven hexes: the centre has all six neighbours inside, the ring does not.
func test_the_centre_of_a_radius_one_disc_is_its_only_interior_hex() -> void:
	var region := _region(HexCoordinates.disc(Vector2i.ZERO, 1))
	assert_eq(region.interior(), [Vector2i.ZERO] as Array[Vector2i])
	assert_eq(region.boundary().size(), 6)


func test_a_single_hex_is_all_boundary() -> void:
	var region := _region([Vector2i.ZERO])
	assert_true(region.interior().is_empty())
	assert_eq(region.boundary(), [Vector2i.ZERO] as Array[Vector2i])
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_meld_region.gd`
Expected: FAIL — `MeldRegion` is not a known class.

- [ ] **Step 3: Create `realm/meld_region.gd`**

```gdscript
class_name MeldRegion
extends RefCounted
## A maximal contiguous run of hexes whose influence effects agree. Carries no provenance: the
## effect set already names what is there, and two combinations authored to the same effect are
## one region that could not name its domains anyway.
## https://github.com/snackpackgames/cosmicparade/issues/106
## https://github.com/snackpackgames/cosmicparade/issues/108

var effects: Array[InfluenceEffect] = []
var hexes: Array[Vector2i] = []


func _init(region_effects: Array[InfluenceEffect], region_hexes: Array[Vector2i]) -> void:
	...


func size() -> int:
	return hexes.size()


func contains(hex: Vector2i) -> bool:
	...


## The hexes whose six neighbours are all in this region — `adr/0008`'s biome fill.
func interior() -> Array[Vector2i]:
	...


## The hexes with at least one neighbour outside it — `adr/0008`'s feature spawning.
func boundary() -> Array[Vector2i]:
	...
```

- [ ] **Step 4: Rebuild the class cache and run the test**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_meld_region.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/meld_region.gd realm/meld_region.gd.uid \
  test/unit/realm/test_meld_region.gd test/unit/realm/test_meld_region.gd.uid
git commit -m "feat: add a meld region with interior and boundary derived from adjacency"
```

### Task 3.2: `Meld.region_at`

The probe asks about one hex, so this is a flood fill from that hex rather than a whole-board walk.

- [ ] **Step 1: Write the failing test**

Append to `test/unit/realm/test_meld.gd`. `_zones` places every zone on one hex, so these tests
build zones directly with `InfluenceZone.new` over a patch of hexes:

```gdscript
func _patch(domain: Domain.Kind, hexes: Array[Vector2i]) -> InfluenceZone:
	return InfluenceZone.new(domain, hexes)


func test_a_region_is_every_contiguous_hex_whose_effects_agree() -> void:
	var zones: Array[InfluenceZone] = [
		_patch(Domain.Kind.STONE, [Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0)])
	]
	var region := Meld.region_at(Vector2i.ZERO, zones, _table())
	assert_eq(region.size(), 3)
	assert_eq(_names(region.effects), ["STONE"] as Array[String])


func test_hexes_that_do_not_touch_are_two_regions() -> void:
	var zones: Array[InfluenceZone] = [
		_patch(Domain.Kind.STONE, [Vector2i.ZERO, Vector2i(4, 0)])
	]
	assert_eq(Meld.region_at(Vector2i.ZERO, zones, _table()).size(), 1)
	assert_eq(Meld.region_at(Vector2i(4, 0), zones, _table()).size(), 1)


func test_a_neighbour_showing_different_effects_ends_the_region() -> void:
	var zones: Array[InfluenceZone] = [
		_patch(Domain.Kind.STONE, [Vector2i.ZERO, Vector2i(1, 0)]),
		_patch(Domain.Kind.GALE, [Vector2i(1, 0)]),
	]
	var table := _table()
	assert_eq(Meld.region_at(Vector2i.ZERO, zones, table).size(), 1)
	assert_eq(_names(Meld.region_at(Vector2i(1, 0), zones, table).effects),
		["STONE", "GALE"] as Array[String])
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_meld.gd`
Expected: FAIL — `region_at` does not exist.

- [ ] **Step 3: Implement `Meld.region_at`**

Resolve the hex, then flood-fill over `HexCoordinates.neighbors`, keeping a neighbour when its own
resolution `agrees_with` the seed's. The fill terminates on its own: a hex nothing covers resolves
empty and an empty resolution never agrees with a non-empty one, so the frontier cannot escape the
zones' coverage.

- [ ] **Step 4: Run the test**

Run: `bash scripts/test.sh realm/test_meld.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/meld.gd test/unit/realm/test_meld.gd
git commit -m "feat: find the region of agreeing hexes around one hex"
```

### Task 3.3: `Meld.regions`

- [ ] **Step 1: Write the failing test**

Append to `test/unit/realm/test_meld.gd`:

```gdscript
func test_every_region_on_the_board_is_grouped_once() -> void:
	var zones: Array[InfluenceZone] = [
		_patch(Domain.Kind.STONE, [Vector2i.ZERO, Vector2i(1, 0)]),
		_patch(Domain.Kind.GALE, [Vector2i(6, 0)]),
	]
	var regions := Meld.regions(zones, _table())
	assert_eq(regions.size(), 2)
	var total := 0
	for region in regions:
		total += region.size()
	assert_eq(total, 3)


func test_regions_agrees_with_region_at_for_the_same_hex() -> void:
	var zones: Array[InfluenceZone] = [
		_patch(Domain.Kind.STONE, HexCoordinates.disc(Vector2i.ZERO, 2))
	]
	var table := _table()
	var one := Meld.region_at(Vector2i(1, 0), zones, table)
	for region in Meld.regions(zones, table):
		if region.contains(Vector2i(1, 0)):
			assert_eq(region.size(), one.size())


func test_no_region_covers_a_hex_nothing_covers() -> void:
	var regions := Meld.regions([] as Array[InfluenceZone], _table())
	assert_true(regions.is_empty())
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_meld.gd`
Expected: FAIL — `regions` does not exist.

- [ ] **Step 3: Implement `Meld.regions`**

The candidate hexes are the **union of the zones' coordinates**, because a hex no zone covers shows
nothing and so belongs to no region — which is also what keeps the walk finite over an unbounded
plane. Visit each candidate once, flood-filling as `region_at` does and marking what it absorbs.
Say in the doc comment that it answers for off-board coordinates too, since clipping to the board
stays at consumption.

- [ ] **Step 4: Run the test**

Run: `bash scripts/test.sh realm/test_meld.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/meld.gd test/unit/realm/test_meld.gd
git commit -m "feat: group the board into meld regions"
```

### Task 3.4: The depth-4 contour splits a region

The cost
[#109](https://github.com/snackpackgames/cosmicparade/issues/109) accepted deliberately, and the
one place region identity is depth-aware. It is tested because a future reader will otherwise read
it as a bug.

- [ ] **Step 1: Write the failing test**

Append to `test/unit/realm/test_meld.gd`:

```gdscript
# https://github.com/snackpackgames/cosmicparade/issues/109 — a melded area straddling the depth-4
# contour is two regions, because the ceiling effect is in the set a region compares. Stacking
# MAX_DEPTH + 1 zones on one hex of a patch puts that hex alone at its ceiling.
func test_a_patch_straddling_the_ceiling_contour_is_two_regions() -> void:
	var patch: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0)]
	var zones: Array[InfluenceZone] = [_patch(Domain.Kind.STONE, patch)]
	for _i in Elevation.MAX_DEPTH:
		zones.append(_patch(Domain.Kind.STONE, [Vector2i(1, 0)]))
	var table := _table()
	assert_eq(Elevation.depth_at(Vector2i(1, 0), zones), Elevation.MAX_DEPTH)
	assert_eq(Meld.regions(zones, table).size(), 3, "the maxed hex severs the patch")
	assert_eq(Meld.region_at(Vector2i(1, 0), zones, table).size(), 1)
	assert_eq(Meld.region_at(Vector2i.ZERO, zones, table).size(), 1)


# Review Focus 4: a hex nothing covers is in no region at all, and asking is not an error.
func test_region_at_a_hex_nothing_covers_is_null() -> void:
	assert_null(Meld.region_at(Vector2i(3, 3), [] as Array[InfluenceZone], _table()))
```

- [ ] **Step 2: Run it to verify it fails or passes**

Run: `bash scripts/test.sh realm/test_meld.gd`
Expected: the contour test PASSES already if Tasks 2.5 and 3.3 are right — it is a pin, not a new
behaviour. `region_at` returning null may need the guard added. If the contour test *fails*, the
ceiling effect is not reaching `effects()`; fix Task 2.5's code rather than this test.

- [ ] **Step 3: Add the null guard to `Meld.region_at`**

Return `null` when the seed hex resolves empty.

- [ ] **Step 4: Run the test**

Run: `bash scripts/test.sh realm/test_meld.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/meld.gd test/unit/realm/test_meld.gd
git commit -m "test: pin that the ceiling contour severs a region"
```

### Task 3.5: Off-board coordinates

- [ ] **Step 1: Write the failing test**

Append to `test/unit/realm/test_meld.gd`. Radius 5 is the starting core, so `(40, 0)` is far
outside any board this project will have:

```gdscript
# Review Focus 5: InfluenceZone keeps the coordinates that land in the void and clips at
# consumption, so resolution and regions answer for them like any other hex.
func test_resolution_and_regions_answer_for_coordinates_in_the_void() -> void:
	var void_hexes: Array[Vector2i] = [Vector2i(40, 0), Vector2i(41, 0)]
	var zones: Array[InfluenceZone] = [_patch(Domain.Kind.FLAME, void_hexes)]
	var table := _table()
	assert_eq(_names(Meld.resolve(Vector2i(40, 0), zones, table).effects()),
		["FLAME"] as Array[String])
	assert_eq(Meld.regions(zones, table).size(), 1)
	assert_eq(Meld.region_at(Vector2i(40, 0), zones, table).size(), 2)
```

- [ ] **Step 2: Run it to verify it passes**

Run: `bash scripts/test.sh realm/test_meld.gd`
Expected: PASS — nothing in `Meld` references the board, which is what this test pins.

- [ ] **Step 3: Run the whole realm suite and lint**

Run: `bash scripts/test.sh realm && bash scripts/lint.sh`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add test/unit/realm/test_meld.gd
git commit -m "test: pin that meld answers for coordinates in the void"
```

---

## Phase 4 — The debug probe

A per-hex derivation probe in its own node, fed by `HexCursor.targeted_hex_changed`
([decided](https://github.com/snackpackgames/cosmicparade/issues/110), with the two lines
[#113](https://github.com/snackpackgames/cosmicparade/issues/113) and
[#114](https://github.com/snackpackgames/cosmicparade/issues/114) adjusted). Every line is
load-bearing; none is decoration. The block, exactly:

```
Meld at (2,-1)
  covering   Forest x3, Flame x1, Stone x2
  entry 4    Forest+Flame   intensity 2, from Forest
  entry 9    Stone          intensity 1
  depth 2    from Forest, not at ceiling
  effects    fused placeholder, Stone
  region     9 hexes agree
```

**Files:**
- Create: `realm/meld_readout.gd`
- Modify: `realm/realm.tscn`, `realm/realm.gd`
- Test: `test/unit/realm/test_meld_readout.gd` (create)

**Interfaces:**
- Consumes: `Meld.resolve`, `Meld.region_at`, `MeldResolution`, `EffectMatch`,
  `InfluenceEffectTable`, `HexCursor.targeted_hex_changed`, `RealmState.zones`.
- Produces: `MeldReadout.refresh(hex: Vector2i, zones: Array[InfluenceZone], table:
  InfluenceEffectTable) -> void`, `MeldReadout.text() -> String`, `MeldReadout.NOTHING_COVERS`;
  `Realm.meld` and `Realm.INFLUENCE_EFFECTS`.

### Task 4.1: `MeldReadout` composes the block

- [ ] **Step 1: Write the failing test**

`test/unit/realm/test_meld_readout.gd`. The helpers mirror `test_meld.gd`'s; the assertions are on
whole lines, because the format *is* the decision this ticket made:

```gdscript
extends GutTest
## The meld probe: the whole derivation for one hex, as text.


func _effect(name: String) -> InfluenceEffect:
	var effect := InfluenceEffect.new()
	effect.effect_name = name
	return effect


func _entry(domains: Array[int], effect: InfluenceEffect) -> InfluenceEffectEntry:
	var entry := InfluenceEffectEntry.new()
	entry.domains = domains
	entry.effect = effect
	return entry


func _table(extra: Array[InfluenceEffectEntry] = []) -> InfluenceEffectTable:
	var table := InfluenceEffectTable.new()
	var entries: Array[InfluenceEffectEntry] = []
	entries.assign(extra)
	for domain: Domain.Kind in Domain.Kind.values():
		entries.append(_entry([domain], _effect((Domain.Kind.find_key(domain) as String).capitalize())))
	table.entries = entries
	table.ceiling_effect = _effect("at ceiling")
	return table


func _zones(counts: Dictionary, hexes: Array[Vector2i]) -> Array[InfluenceZone]:
	var zones: Array[InfluenceZone] = []
	for domain: int in counts:
		for _i in counts[domain] as int:
			zones.append(InfluenceZone.new(domain, hexes))
	return zones


func _readout() -> MeldReadout:
	return add_child_autofree(MeldReadout.new())


func _lines(readout: MeldReadout) -> Array:
	return readout.text().split("\n")


# The decided block, over the arrangement it was decided on: a three-hex patch so the region line
# has something to say, with Forest x3, Flame x1 and Stone x2 on the probed hex.
func test_it_prints_the_whole_derivation_for_the_hex() -> void:
	var patch: Array[Vector2i] = [Vector2i(2, -1), Vector2i(3, -1), Vector2i(1, -1)]
	var table := _table([_entry([Domain.Kind.FOREST, Domain.Kind.FLAME], _effect("fused placeholder"))])
	var zones := _zones({Domain.Kind.FOREST: 3, Domain.Kind.FLAME: 1, Domain.Kind.STONE: 2}, patch)
	var readout := _readout()
	readout.refresh(Vector2i(2, -1), zones, table)
	var lines := _lines(readout)
	assert_eq(lines[0], "Meld at (2,-1)")
	assert_eq(lines[1], "  covering   Forest x3, Stone x2, Flame x1")
	assert_eq(lines[2], "  entry 0    Forest+Flame   intensity 2, from Forest")
	assert_eq(lines[3], "  entry 4    Stone          intensity 1")
	assert_eq(lines[4], "  depth 2    from Forest, not at ceiling")
	assert_eq(lines[5], "  effects    fused placeholder, Stone")
	assert_eq(lines[6], "  region     3 hexes agree")
	assert_eq(lines.size(), 7)


# The entry index is the authored file order, which is the tie-break — so it has to be the index
# and not a counter of what fired.
func test_an_entry_line_carries_its_index_in_the_authored_file() -> void:
	var table := _table()
	var readout := _readout()
	readout.refresh(Vector2i.ZERO, _zones({Domain.Kind.GALE: 1}, [Vector2i.ZERO]), table)
	assert_eq(_lines(readout)[2], "  entry 5    Gale           intensity 0")


# "from <domain>" is what reveals an effect amplified by the wrong domain, which is the bug #113
# ruled out — so it is printed only where it can go wrong, on a multi-domain entry.
func test_a_one_domain_entry_states_no_provenance_for_its_intensity() -> void:
	var readout := _readout()
	readout.refresh(Vector2i.ZERO, _zones({Domain.Kind.STONE: 3}, [Vector2i.ZERO]), _table())
	assert_eq(_lines(readout)[2], "  entry 3    Stone          intensity 2")


func test_at_the_ceiling_the_depth_line_says_so_and_the_effect_joins_the_set() -> void:
	var readout := _readout()
	var zones := _zones({Domain.Kind.STONE: Elevation.MAX_DEPTH + 1}, [Vector2i.ZERO])
	readout.refresh(Vector2i.ZERO, zones, _table())
	var lines := _lines(readout)
	assert_eq(lines[3], "  depth 4    from Stone, at ceiling")
	assert_eq(lines[4], "  effects    Stone, at ceiling")
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_meld_readout.gd`
Expected: FAIL — `MeldReadout` is not a known class.

- [ ] **Step 3: Create `realm/meld_readout.gd`**

Follows `DebugReadout` exactly in form: a `CanvasLayer` with one placeholder-layout `Label`, a
`_lines: Array[String]` recomposed on every `refresh`, a `text()` returning what is displayed so a
test reads the lines without scraping the `Label`, and an `_ensure_label()`. Place it in the
**bottom-right**: `DebugReadout` already owns the top-right and `%RequirementList` the top-left.

```gdscript
class_name MeldReadout
extends CanvasLayer
## DEBUG ONLY. The whole derivation of one hex's influence effects: what covers it and in what
## numbers, which authored entries fired, at what index and intensity, the depth beneath them,
## the resulting effects, and how many neighbouring hexes agree. It shows the **inputs and the
## match**, never the rendered result — the rendered result is the game rendering, not a debug
## view. PLACEHOLDER LAYOUT: a single Label in a corner. `text()` returns what is displayed.
## https://github.com/snackpackgames/cosmicparade/issues/110

## Stated rather than left blank, on `DebugReadout`'s own grounds: a readout of nothing is
## indistinguishable from a broken one.
const NOTHING_COVERS := "  nothing covers this hex"
```

Composition rules, in order:
- The header is `"Meld at (%d,%d)"`.
- `covering` walks `Domain.Kind.values()` so the order is stable whatever order the zones arrive
  in, printing `"%s x%d"` per domain present, joined with `", "`. The names come from
  `Domain.Kind.find_key(domain).capitalize()`, as `realm/debug_readout.gd:82` does.
- One `entry` line per match, in match order: the index, then the entry's domain label — its own
  domains named and joined with `+`, right-padded to 15 so the intensities line up — then
  `"intensity %d"`, then `", from %s"` **only when the entry has more than one domain**.
- `depth` is the hex's own depth with the domain that set it, then `"at ceiling"` or
  `"not at ceiling"`.
- `effects` joins each member of `resolution.effects()` by `effect_name`, `", "`-separated.
- `region` is `Meld.region_at(...).size()`, as `"%d hexes agree"`.

- [ ] **Step 4: Rebuild the class cache and run the test**

Run: `bash scripts/import.sh && bash scripts/test.sh realm/test_meld_readout.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/meld_readout.gd realm/meld_readout.gd.uid \
  test/unit/realm/test_meld_readout.gd test/unit/realm/test_meld_readout.gd.uid
git commit -m "feat: show a hex's whole meld derivation in a debug probe"
```

### Task 4.2: A hex with no influence on it says so

- [ ] **Step 1: Write the failing test**

Append to `test/unit/realm/test_meld_readout.gd`:

```gdscript
# Review Focus 4. An empty probe would be indistinguishable from a broken one, which is why
# DebugReadout carries NOTHING_READ and NO_FURTHER_SWELL.
func test_a_hex_nothing_covers_says_so_and_prints_no_other_line() -> void:
	var readout := _readout()
	readout.refresh(Vector2i(2, -1), [] as Array[InfluenceZone], _table())
	var lines := _lines(readout)
	assert_eq(lines[0], "Meld at (2,-1)")
	assert_eq(lines[1], MeldReadout.NOTHING_COVERS)
	assert_eq(lines.size(), 2)


func test_it_recovers_when_the_cursor_moves_back_onto_influence() -> void:
	var readout := _readout()
	var zones := _zones({Domain.Kind.GALE: 1}, [Vector2i.ZERO])
	readout.refresh(Vector2i.ZERO, zones, _table())
	readout.refresh(Vector2i(9, 9), zones, _table())
	assert_eq(_lines(readout)[1], MeldReadout.NOTHING_COVERS)
	readout.refresh(Vector2i.ZERO, zones, _table())
	assert_eq(_lines(readout).size(), 7)
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_meld_readout.gd`
Expected: FAIL — the empty resolution composes a block of empty lines.

- [ ] **Step 3: Return the header plus `NOTHING_COVERS` when the resolution `is_empty()`**

- [ ] **Step 4: Run the test**

Run: `bash scripts/test.sh realm/test_meld_readout.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add realm/meld_readout.gd test/unit/realm/test_meld_readout.gd
git commit -m "feat: state explicitly that nothing covers the probed hex"
```

### Task 4.3: Wire the probe into the realm scene

`HexCursor` is **unchanged**: it gains a second listener on an existing signal
([decided](https://github.com/snackpackgames/cosmicparade/issues/110)).

- [ ] **Step 1: Write the failing test**

Append to `test/unit/realm/test_meld_readout.gd`, following `test_debug_readout.gd`'s
scene-driven tests:

```gdscript
const REALM_SCENE := preload("res://realm/realm.tscn")


func _realm() -> Realm:
	var realm: Realm = add_child_autofree(REALM_SCENE.instantiate())
	await wait_frames(1)
	return realm


func test_the_realm_feeds_the_probe_from_the_cursor() -> void:
	var realm := await _realm()
	realm.state.place(BoardPlacement.new(
		load("res://data/realm/furniture/mushroom_stool.tres"), 0, [Vector2i(2, 0)] as Array[Vector2i]
	))
	realm.cursor.aim_at(Vector2i(2, 0))
	assert_string_contains(realm.meld.text(), "Meld at (2,0)")
	assert_string_contains(realm.meld.text(), "Forest")


func test_the_probe_is_hidden_outside_a_debug_build() -> void:
	var realm := await _realm()
	assert_eq(realm.meld.visible, OS.is_debug_build())
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test.sh realm/test_meld_readout.gd`
Expected: FAIL — `Realm` has no `meld`.

- [ ] **Step 3: Add the node to `realm/realm.tscn`**

A `MeldReadout` `CanvasLayer` beside `DebugReadout`, with `realm/meld_readout.gd` as its script and
a new `ext_resource` id.

- [ ] **Step 4: Wire it in `realm/realm.gd`**

- `const INFLUENCE_EFFECTS := preload("res://data/realm/influence_effect_table/board.tres")`,
  beside `ALTAR` and `STOCK_SHRINE`.
- `@onready var meld: MeldReadout = $MeldReadout`.
- In `_ready`: `meld.visible = OS.is_debug_build()`, and
  `cursor.targeted_hex_changed.connect(_on_hex_targeted)` **in addition to** the existing
  `cursor.targeted_hex_changed.connect(carry.aim)` — do not replace it.
- `_on_hex_targeted(hex)` calls a `_refresh_meld()` guarded by `OS.is_debug_build()`, as
  `_refresh_readout` is. Call `_refresh_meld()` from `_refresh_view()` too, so committing a piece
  updates the probe under a cursor that did not move.
- The probe reads **committed** zones (`state.zones()`), not the carry's candidate zone. State why
  in a comment: the probe diagnoses the authored table against the board as it stands, and
  previewing what a carried piece *would* do is already `board.zones`' job.

- [ ] **Step 5: Run the test, then the whole suite**

Run: `bash scripts/test.sh realm/test_meld_readout.gd && bash scripts/test.sh`
Expected: PASS — in particular `test_realm.gd` and `test_debug_readout.gd`, which drive the same
scene.

- [ ] **Step 6: Lint and commit**

```bash
bash scripts/lint.sh
git add realm/realm.gd realm/realm.tscn test/unit/realm/test_meld_readout.gd
git commit -m "feat: feed the meld probe from the realm's cursor"
```

### Task 4.4: The acceptance test, over the authored table

The probe consumes the table, the zones and a hex, so one assertion on its block for a hand-built
arrangement exercises greedy matching, consumption, file-order tie-breaks, per-effect intensity and
depth composition together — which is why
[#110](https://github.com/snackpackgames/cosmicparade/issues/110) called it the natural acceptance
surface for this whole map.

- [ ] **Step 1: Write the failing test**

Append to `test/unit/realm/test_meld_readout.gd`, using the **authored** table rather than a
built one:

```gdscript
# The whole map, end to end, against the data that ships: the authored Forest+Flame placeholder
# fires and consumes both domains, Stone falls through to its own one-domain entry, each effect
# carries its own intensity, and the region is the patch all three hexes share.
func test_the_authored_table_resolves_a_hand_built_arrangement() -> void:
	var patch: Array[Vector2i] = [Vector2i(2, -1), Vector2i(3, -1), Vector2i(1, -1)]
	var table: InfluenceEffectTable = load(InfluenceEffectTable.BOARD_PATH)
	var zones := _zones({Domain.Kind.FOREST: 3, Domain.Kind.FLAME: 1, Domain.Kind.STONE: 2}, patch)
	var readout := _readout()
	readout.refresh(Vector2i(2, -1), zones, table)
	var lines := _lines(readout)
	assert_eq(lines[1], "  covering   Forest x3, Stone x2, Flame x1")
	assert_string_contains(lines[2], "Forest+Flame")
	assert_string_contains(lines[2], "intensity 2, from Forest")
	assert_string_contains(lines[3], "Stone")
	assert_string_contains(lines[3], "intensity 1")
	assert_eq(lines[4], "  depth 2    from Forest, not at ceiling")
	assert_eq(lines[5], "  effects    fused placeholder, Stone")
	assert_eq(lines[6], "  region     3 hexes agree")
```

The entry indices are deliberately not asserted here: they are the authored file's order, and
Task 1.4's own tests guard that file. Asserting them twice would make re-ordering the placeholder
data fail in two places for one reason.

- [ ] **Step 2: Run it to verify it fails or passes**

Run: `bash scripts/test.sh realm/test_meld_readout.gd`
Expected: PASS if Phases 1–3 and Task 4.1 are right. A failure here is a real defect in one of
them — read the block it printed against the block in this phase's heading and fix the phase that
owns the wrong line, not this test.

- [ ] **Step 3: Run the whole suite and lint**

Run: `bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add test/unit/realm/test_meld_readout.gd
git commit -m "test: accept the authored table through the meld probe"
```

---

## Phase 5 — The ADR, the README and the renamed placeholder

The vocabulary change is a documentation deliverable of its own: `README.md → Terminology` exists
to stop exactly this drift, and three places in the repo currently mean "influence effect" and say
something else ([decided](https://github.com/snackpackgames/cosmicparade/issues/114)).

**Files:**
- Create: `documentation/adr/0017-influence-effects-are-matched-greedily.md`
- Modify: `README.md` (*Terminology*, *Settled Decisions*, *Related Docs*), `CLAUDE.md`
  (*Architecture*), `realm/board_material.gd`
- Test: `test/unit/realm/test_board_material.gd` (unchanged — it asserts behaviour, not wording)

### Task 5.1: ADR 0017

`adr/0004` settled that fusion looks are **authored, not computed**, and keeps its title and its
text — an ADR records what was decided when it was decided. 0017 records the **shape** that
authoring takes, which 0004 left open.

- [ ] **Step 1: Write `documentation/adr/0017-influence-effects-are-matched-greedily.md`**

Follow `0014-burgeon-raises-the-ground.md`'s form: short paragraphs, each ending in the issue
links that settled it, then *Alternatives rejected*, then *Consequences*. The content, one
paragraph each:

- An influence effect is an authored `GameData` Resource, purely visual, and `Domain.Kind` stays at
  exactly six ([#108](https://github.com/snackpackgames/cosmicparade/issues/108),
  [adr/0005](0005-six-domains.md)).
- An entry is keyed by an **unordered set** of domains; the table is **sparse** and **ordered**;
  matching is greedy subset containment, largest first, **consuming** what it claims, ties on
  authored file order ([#107](https://github.com/snackpackgames/cosmicparade/issues/107)). A table
  of pairs therefore covers every arity, which is the authoring reduction that motivated the
  shape — and nothing is blended, averaged or derived, so `adr/0004` holds.
- A one-domain entry is the unclaimed-domain fallback, which is why there is no array indexed by
  `Domain.Kind` and why the enum's order is not load-bearing
  ([#113](https://github.com/snackpackgames/cosmicparade/issues/113)).
- Depth **amplifies** an effect and never keys a lookup; intensity is read per effect from its own
  domains ([#113](https://github.com/snackpackgames/cosmicparade/issues/113)). One authored
  ceiling effect is the single exception, preserving the limit-versus-count signal
  [#42](https://github.com/snackpackgames/cosmicparade/issues/42) argued for.
- Meld never touches height; the two are orthogonal by construction, because there is no shared
  input to arbitrate ([#109](https://github.com/snackpackgames/cosmicparade/issues/109)).
  `adr/0014` is unchanged.
- A hex's effects are derived from the zones on every call and stored nowhere, and a region is
  contiguous hexes whose effect sets agree
  ([#106](https://github.com/snackpackgames/cosmicparade/issues/106)).
- *Alternatives rejected*: all 57 combinations authored with no fallback rule (rejected as an
  authoring explosion once greedy consumption was seen to need only pairs); a six-slot per-domain
  array beside the entries (rejected as a second mechanism for one job); a per-depth or per-domain
  "maxed" effect (rejected — amplification needs no new data, and the alternative needed six or
  twelve more authored effects plus a membership rule); suppressing a consumed domain's height
  (rejected because the authored art table would become balance data, since
  `realm/placement_context.gd:30` feeds `HeightCriterion` and `LevelFootprintCriterion`).
- *Consequences*: reordering the authored file is a gameplay change; a region straddling the
  depth-4 contour is two regions, so `adr/0008`'s biome fill sees two interiors; set equality is
  instance equality while an effect is shared authored data, and breaks if an effect is ever
  instanced per hex; what an effect's intensity *does* — particle count, a shader uniform — is art
  work still deferred, as is what any combination actually fuses into.

- [ ] **Step 2: Commit**

```bash
git add documentation/adr/0017-influence-effects-are-matched-greedily.md
git commit -m "docs: record how influence effects are matched"
```

### Task 5.2: `README.md`

- [ ] **Step 1: Add the term to *Terminology***

A new row immediately after **Domain influence**, so the pair reads together:

```markdown
| **Influence effect** | What projected domain influence makes a hex show — an authored, purely visual effect (a shader or particle effect), read from a lookup table keyed by the domains covering the hex. `adr/0004`'s "fusion look" is an influence effect. |
```

- [ ] **Step 2: Amend the **Meld** row in the same table**

It currently says meld "produces a new type". A meld produces an authored influence effect, and no
new mechanical type: `Domain.Kind` stays at six and nothing gates on the result
([#108](https://github.com/snackpackgames/cosmicparade/issues/108)).

- [ ] **Step 3: Amend the *Settled Decisions* bullet**

The bullet currently titled **"Fusion looks are authored, not computed."** keeps its argument —
hand-picked rather than arithmetically blended — and gains the vocabulary and the shape: the
authored thing is an **influence effect**, the table is sparse and ordered, matching is greedy and
consuming, a one-domain entry is the fallback, and depth amplifies rather than selecting. Point it
at `adr/0017` beside `adr/0004`.

- [ ] **Step 4: Add the ADR index row in *Related Docs***

```markdown
  | 0017 | Influence effects are matched greedily from a sparse table |
```

- [ ] **Step 5: Verify no stale "look" wording remains in the places this plan names**

Run: `grep -n -i "fusion look\|domain look\|fusion table" README.md CLAUDE.md realm/`
Expected: matches only inside `documentation/adr/0004`'s own title where the README cites it. The
ADR file itself is **not** edited.

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: name the influence effect in the design document"
```

### Task 5.3: `CLAUDE.md` and the board material's doc comment

- [ ] **Step 1: Update `CLAUDE.md → Architecture`**

The `GameData` paragraph says "Fusion table (`adr/0004`)". It is the **influence effect table**,
and it now has a second ADR: cite `adr/0004` and `adr/0017`.

- [ ] **Step 2: Reword `realm/board_material.gd`'s doc comment**

It currently reads *"A deliberate placeholder for deferred art: the authored per-domain look and
the authored depth-4 'maxed' look both replace this."* Both halves are now wrong in wording and
the second in substance — there is no depth-4 authored look. It is the authored **influence
effects** and the authored **ceiling effect** that replace this. Keep the last sentence: it only
has to render.

- [ ] **Step 3: Run the suite and lint**

Run: `bash scripts/test.sh && bash scripts/lint.sh`
Expected: PASS. `test_board_material.gd` asserts the shader and the texture, not the prose, so it
is untouched.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md realm/board_material.gd
git commit -m "docs: adopt the influence effect vocabulary in the placeholder material"
```

---

## What this plan deliberately does not build

Each is ruled out on the map, and an implementer who adds it is widening the scope:

- **What any combination actually fuses into.** Content and art direction, with its own effort.
  One placeholder combination entry ships; naming Forest+Flame does not.
- **Rendering.** No shader, no particle system, no change to what `realm/board_material.gd`
  produces. What an intensity *does* is art work.
- **A board-wide region view.** `Meld.regions` is the grouping
  [#106](https://github.com/snackpackgames/cosmicparade/issues/106) decided, not a second debug
  surface: [#110](https://github.com/snackpackgames/cosmicparade/issues/110) rejected a region
  table outright, because the probe already diagnoses the ceiling seam by being moved across it
  and comparing two effect sets that differ by one member.
- **Player-facing presentation of fusion.** `README.md → Open Design Questions → Communicating
  domain influence` is `area:ui` work with no map. The probe is a debug affordance, not a
  presentation decision.
- **Biome fill and feature spawning.** `adr/0008`'s two systems are M2 and consume this; they are
  not its content. `MeldRegion.interior()` and `boundary()` are the classification `adr/0008` will
  read, and nothing in this plan calls them from gameplay.
- **Terrain as a placement criterion.** Closed as out of scope
  ([#112](https://github.com/snackpackgames/cosmicparade/issues/112)): an influence effect is
  visual, so there is nothing to gate on, and `DomainInfluenceCriterion` and `HeightCriterion`
  already ship the mechanical gating.
- **Save persistence**, **melding on the parade ground**, and **anything about burgeon itself** —
  `adr/0014` and `Elevation` are settled and shipped.
