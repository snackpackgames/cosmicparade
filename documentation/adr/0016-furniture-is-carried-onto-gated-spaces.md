# Furniture is carried onto gated spaces

A piece's **footprint** is a per-piece property drawn from a closed vocabulary of five
polyhexes — single, pair, straight-three, bend-three, triangle-three — which is the complete
set up to size 3, so the vocabulary is closed by arithmetic rather than by taste
([#51](https://github.com/snackpackgames/cosmicparade/issues/51)).

**Footprints never overlap; influence does.** `README.md → Settled Decisions` already fixes
this for fixtures — shrine tiles may not collide while their projected influence overlaps
freely — and `adr/0001` makes furniture a volume on the same board. A piece is a solid object;
its influence is not ([#51](https://github.com/snackpackgames/cosmicparade/issues/51)).

**One piece projects exactly one zone**, whatever its footprint. This is forced rather than
chosen: elevation counts how many zones of a domain cover a hex and two make a riser
([#37](https://github.com/snackpackgames/cosmicparade/issues/37)), so a three-hex piece
projecting one zone per occupied hex would burgeon with itself and raise ground underneath
itself the instant it landed ([#51](https://github.com/snackpackgames/cosmicparade/issues/51)).

A **zone is the union of radius-`r` discs grown from every hex the piece occupies**, with `r`
authored per piece and **1** the default. Growing from every occupied hex turns the five
footprints into five zone shapes for free. `test/prototypes/52-influence-zone-size/` is the
evidence ([#52](https://github.com/snackpackgames/cosmicparade/issues/52)).

**Furniture rotates: six 60° steps on every piece**, orientation a single integer 0–5,
regardless of the footprint's symmetry, because the **art** has a facing even where the
footprint has none — this is a decorator, and a single-hex chair wants to face six ways. The
zone rotates with the footprint by necessity, since it is derived from the occupied hexes, so
rotation **steers influence** rather than being cosmetic. **The pivot is the grab hex**, not
the authored anchor, so a turning piece never swings out from under the cursor. Orientation is
**sticky** for pieces arriving from inventory; a piece lifted from the board keeps its own
([#56](https://github.com/snackpackgames/cosmicparade/issues/56)).

**Placement criteria are a closed vocabulary of five gate types** — height, level footprint,
domain influence count, clearance, board position. A piece carries a list; **every criterion
must pass on every hex of the footprint**. One quantifier, no `OR`
([#55](https://github.com/snackpackgames/cosmicparade/issues/55)).

**Gates only.** What a piece projects is a property of the piece, never of where it sits: no
criterion may modify a zone, a radius or a depth
([#55](https://github.com/snackpackgames/cosmicparade/issues/55)).

Criteria read the board **as it will be with the piece on it, own influence included**, so a
domain criterion counts the piece's own zone and `Forest ≥ 2` means "a Forest neighbour" — and,
since depth is zones minus one, also "Forest ground raised here"
([#41](https://github.com/snackpackgames/cosmicparade/issues/41),
[#55](https://github.com/snackpackgames/cosmicparade/issues/55)). Criteria name only
`adr/0005`'s six base domains; a criterion naming a fused biome would need meld resolution and
is deferred with it.

**The verb is carry**: click to lift, the piece rides one targeted hex, click to place,
right-click or Esc to cancel back to its origin. No button is held, because the targeting state
has to be inhabitable — the terrain preview *is* the arrangement puzzle's feedback loop, and a
player needs to hold a piece over three hexes and change their mind. **Validity is a property
of the current target**, re-evaluated whenever the occupied set changes, and the place action is
**inert** while refused. **Lifting a placed piece is the same verb**, and a carried piece
occupies nothing — its influence is gone for the whole carry. The verb reads one targeted hex,
so mouse and gamepad are the same path, and lift, place, cancel and rotate are InputMap actions
([#54](https://github.com/snackpackgames/cosmicparade/issues/54)).

**Three signals, three jobs, no shared language**: the terrain preview resolves on every
target, valid or not; the influence spill says "legal, and it costs you reach"; the refusal
marks failing **hexes** on the board and failing **requirements** on the piece, **unpaired**.
If no legal hex exists anywhere, the game says so when the piece is lifted and names the
requirement nothing satisfies ([#62](https://github.com/snackpackgames/cosmicparade/issues/62)).

## Alternatives rejected

**One hex per piece** was the simplest board and would have made rotation meaningless and the
five zone shapes impossible; **free-form polyhex packing** is a set neither the player can
learn nor the designer can tune
([#51](https://github.com/snackpackgames/cosmicparade/issues/51)).

**Radius-2 zones** were rejected on the board, not in the abstract: one such piece claims 19 of
37 hexes and four fuse 29, leaving no arrangement to make
([#52](https://github.com/snackpackgames/cosmicparade/issues/52)).

**Origin-anchored zones** — one disc grown from the authored anchor rather than from every
occupied hex — would have made all five footprints project the same shape
([#52](https://github.com/snackpackgames/cosmicparade/issues/52)).

**Strength modifiers**, where a criterion grants a piece more reach or a deeper riser for
sitting in the right place, were rejected to keep projection a property of the piece: it is the
one rule that makes "a straight-three turned this way covers these hexes" a statement about
the piece rather than about the board
([#55](https://github.com/snackpackgames/cosmicparade/issues/55)).

**`OR` across criteria and per-criterion quantifiers** ("any hex" variants) were both rejected
for one quantifier and one connective, so a requirement list reads the same way every time
([#55](https://github.com/snackpackgames/cosmicparade/issues/55)).

**Hold-drag** puts the targeting state behind a held mouse button, turning "study the board"
into "don't move your hand"; **select-then-confirm** adds a mode to a verb that already has
one ([#54](https://github.com/snackpackgames/cosmicparade/issues/54)).

**Lighting every legal hex** was the serious alternative to the refusal and it loses the game:
a solved heatmap replaces judging a spot with picking from a lit set, and arranging furniture
is the central mechanic of the realm half
([#62](https://github.com/snackpackgames/cosmicparade/issues/62)).

**Naming one failure at a time** would have the player fix a refusal, target again, and meet a
second, never seeing how many layers remain — a real possibility with `AND` over five
requirements, not a theoretical one. **Pairing hexes to requirements** cannot represent level
footprint, which is a property of the footprint as a whole and belongs to no single hex
([#62](https://github.com/snackpackgames/cosmicparade/issues/62)).

## Consequences

Fixtures reuse all of it: shrines and the Altar author from the same five criteria and get no
second placement path ([#30](https://github.com/snackpackgames/cosmicparade/issues/30),
[#55](https://github.com/snackpackgames/cosmicparade/issues/55)). A **wing** answers the same
carried interface, which is why relocating board is not a second verb
([#53](https://github.com/snackpackgames/cosmicparade/issues/53),
[#61](https://github.com/snackpackgames/cosmicparade/issues/61)).

**Rotation is a second axis of escape from a refusal**, because turning changes the occupied
set. It bites hardest on level footprint, where turning a straight-three can find three hexes
of equal height, and on domain influence count, where turning changes the piece's own
contribution to its own count
([#56](https://github.com/snackpackgames/cosmicparade/issues/56)).

**The player can never be stuck holding a piece**: cancel is always available and the origin is
guaranteed legal, because the board was legal before the lift. That is the mechanism by which
"refusals are always escapable" holds for the verb rather than being bolted onto it
([#41](https://github.com/snackpackgames/cosmicparade/issues/41),
[#54](https://github.com/snackpackgames/cosmicparade/issues/54)).

Naming the blocking requirement **costs nothing beyond the sweep** that answering "is it
placeable at all" already needs: a pass mask per criterion over the candidate placements,
intersected, yields both the verdict and the blocker
([#62](https://github.com/snackpackgames/cosmicparade/issues/62)).

**Where the requirement list is drawn** — panel, tooltip, text on the ghost — and how a
refusal, a spill or a ghost *looks* are art direction, deferred with the rest of the placement
UI ([#62](https://github.com/snackpackgames/cosmicparade/issues/62)). **Furniture supply** is
`adr/0011`'s inventory: pieces enter a carry through an API that takes a piece resource, and a
displaced piece is announced on a signal rather than put anywhere.
