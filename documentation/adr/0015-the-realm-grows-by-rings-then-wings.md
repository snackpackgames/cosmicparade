# The realm grows by rings, then wings

The realm board is a **radial hexagon of radius 3 — 37 hex spaces, 7 across** — centred on
axial `(0, 0)`, chosen over a rhombus or a rectangle because domain influence is the board's
whole purpose and a radial board treats every placement alike: a zone behaves the same near
any edge, where a rhombus has two sharp corners and two blunt ones. It is also an object
rather than a grid — `adr/0001` floats it against the skybox, and a sheared rhombus reads as
a cut-out of graph paper where a hexagon reads as an island
([#50](https://github.com/snackpackgames/cosmicparade/issues/50)).

Radius 3 is a deliberately cramped start, so the arrangement puzzle bites from the first
piece rather than after an hour of accumulation
([#50](https://github.com/snackpackgames/cosmicparade/issues/50)).

The board is **generated from its radius, never stored as a hex set**, so growth increments
one number instead of authoring a coordinate list
([#50](https://github.com/snackpackgames/cosmicparade/issues/50)).

Growth is **two-phase**. The first two Swells add a whole ring — radius 3 → 4 (61) → 5 (91) —
and the core never grows concentrically again. Phase 1 has no placement decision in it, which
keeps "no privileged direction" literally true for the whole period in which the player is
still learning what influence does. **91 is the README's original "10×10"** landing on a hex
lattice: concentric growth ends at the size the design first imagined, and everything past it
is the player's own shape ([#53](https://github.com/snackpackgames/cosmicparade/issues/53)).

Every Swell after that attaches a **wing**, from a closed vocabulary of four geometric figures
of six or seven hexes — disc (7), trapezoid (7), triangle (6), rhombus 2×3 (6). A wing shares
at least one edge with any hex the board already has — core or another wing, indifferently —
and wings may chain. The player chooses the orientation, and the rotate input steps through
**only the orientations that differ**: 1 for the disc, 2 the triangle, 3 the rhombus, 6 the
trapezoid. That breaks furniture's six-steps-always rule
([#56](https://github.com/snackpackgames/cosmicparade/issues/56)) on purpose, because that
rule's justification was *art facing* and a wing has no art — it is board, so six presses
would visibly do nothing on the disc, the entry a player reaches for most. What does transfer
is the pivot on the grab hex ([#61](https://github.com/snackpackgames/cosmicparade/issues/61)).

Orientation is worth as much as shape: the same seven hexes gain +0 full-reach hexes pointing
outward and +4 laid along the rim, measured in `test/prototypes/61-wing-vocabulary/`
([#61](https://github.com/snackpackgames/cosmicparade/issues/61)).

**A wing is just more board.** Wings sit on the same flat-top axial lattice as the core and no
rule knows a hex is on a wing: influence crosses the seam, elevation reads across it,
footprints may span it. There is no second coordinate space, no seam flag, and no sub-board
([#53](https://github.com/snackpackgames/cosmicparade/issues/53)).

**The origin never moves**, so placed furniture keeps its coordinates through every Swell and
every influence zone stays where it was
([#53](https://github.com/snackpackgames/cosmicparade/issues/53)).

A placed wing is **relocatable with its contents**: furniture standing wholly on it travels
and lands at the same offsets. A piece **straddling** the seam is lifted off and returned to
the player, which costs nothing — displacement rather than a new constraint, so the move is
never refused for a straddler. **Hexes are never lost**; relocation is not a refund
([#53](https://github.com/snackpackgames/cosmicparade/issues/53)).

Influence is a set of **coordinates**, not of board hexes, so a zone projects into the void and
the void is inert; clipping happens at consumption, never in the data. The rim gradient that
follows — 7 hexes covered from the centre, 5 from a rim hex, 4 from a corner at zone radius 1 —
**stands as a feature**: the rim is cheap land, the middle is contested, and Swell gains a
second reward beyond room, because your rim pieces become central ones
([#59](https://github.com/snackpackgames/cosmicparade/issues/59)).

## Alternatives rejected

A **rhombus or rectangle board** lost on privileged direction and on silhouette, above
([#50](https://github.com/snackpackgames/cosmicparade/issues/50)).

**Concentric growth forever** would have made the realm a target rather than a place, and the
24- and 30-hex ring lurches that are tolerable as opening moves are not a shape for a whole
game ([#53](https://github.com/snackpackgames/cosmicparade/issues/53)).

**Wings as semi-separate islets**, with influence stopping at the water, would have doubled
every board question on this map and split the edge rule in two
([#53](https://github.com/snackpackgames/cosmicparade/issues/53)).

**Reaching wings** — a one-wide strip of seven, a bent arm of seven — were built and measured
at **+0 full-reach hexes**, because every hex of a single-file strip has an off-board
neighbour. Width, not size, is what gives a wing an interior, which is why the roster is four
compact figures ([#61](https://github.com/snackpackgames/cosmicparade/issues/61)).

**Redistributing spilled influence inward** would have made a zone's shape depend on the
board's shape, and both the zone decision and the rotation decision lean on a zone being
derived from the footprint alone
([#59](https://github.com/snackpackgames/cosmicparade/issues/59)).

**An unbuildable margin** — only hexes whose whole zone fits — leaves 19 buildable hexes of
37, on a board made cramped on purpose
([#59](https://github.com/snackpackgames/cosmicparade/issues/59)).

## Consequences

The board is a **core radius plus an ordered set of placed wings**, each a vocabulary entry, an
orientation and an anchor; still generated, still no authored coordinate list. **A wing lift
that would leave the board in two patches is refused** — wings chain, so lifting the one
another hangs off would orphan hexes, and `adr/0001`'s floating rock stays one object. Read as
a board invariant rather than an attach-time check, one rule covers both directions.

**Ring Swells buy contested land; wing Swells buy room.** The core alone is 61 full-reach
hexes of 91; after six wings the board is 74 of 131, because 34 of the 40 hexes added are rim
([#61](https://github.com/snackpackgames/cosmicparade/issues/61)). A player chasing burgeon
depth wants the core, and once the core caps at radius 5 that avenue closes.

A board change costs elevation work proportional to the hexes **added or removed** — nothing
else, because a zone's coverage of existing hexes cannot change when no footprint moved
([#59](https://github.com/snackpackgames/cosmicparade/issues/59)). A wing move is the largest
such delta: its old hexes, its new hexes, and the zones touching either.

Because criteria are a gate checked once and never re-checked
([#30](https://github.com/snackpackgames/cosmicparade/issues/30)), a wing landing beside a rim
piece placed under `board position = edge` leaves that piece exactly where it is. The board can
legally hold states it cannot produce.

**What a Swell costs**, whether a wing Swell costs the same as a ring Swell, and how many
shrine slots each grants are economy, and belong to M1's third map
([#73](https://github.com/snackpackgames/cosmicparade/issues/73)). The near-equal wing sizes
were chosen precisely so this decision does not pre-empt it.
