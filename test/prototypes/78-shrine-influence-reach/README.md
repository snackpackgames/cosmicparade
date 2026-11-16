# How much shrine influence can reach one hex?

Built to resolve [How much shrine influence can reach one hex?](https://github.com/snackpackgames/cosmicparade/issues/78),
a `wayfinder:prototype` ticket on the map
[Map: what a Swell costs, and where shrines and the Altar stand](https://github.com/snackpackgames/cosmicparade/issues/73).
The resolution comment on #78 is the authoritative record; this file says what the code
does and how to re-run it.

## What it builds

The radial hexagon settled by
[Decide the realm board's shape and extent](https://github.com/snackpackgames/cosmicparade/issues/50)
at radius 3 (37 spaces) and at the radius-5 ceiling (91) from
[Decide how the board's geometry changes when the realm grows](https://github.com/snackpackgames/cosmicparade/issues/53),
with shrines standing on it.

Everything a shrine *is* was already decided and is held fixed, so the only variable is how
many shrines are standing and what is in their vessels:

- a shrine is a **single hex** projecting a **radius-2 disc** grown from that hex
  ([#74](https://github.com/snackpackgames/cosmicparade/issues/74),
  [#52](https://github.com/snackpackgames/cosmicparade/issues/52));
- it projects the domain of the **offering in its vessel**, and an **empty vessel projects
  nothing at all** ([#75](https://github.com/snackpackgames/cosmicparade/issues/75));
- the Altar is a **triangle-three at the origin projecting nothing**
  ([#77](https://github.com/snackpackgames/cosmicparade/issues/77));
- depth is same-domain zones minus one, capped at 4
  ([#37](https://github.com/snackpackgames/cosmicparade/issues/37), `adr/0014`), drawn as
  discrete risers of 0.35 ([#28](https://github.com/snackpackgames/cosmicparade/issues/28),
  [#29](https://github.com/snackpackgames/cosmicparade/issues/29));
- footprints never collide; influence overlaps freely (`README.md → Settled Decisions`).

Colour-coding domains is still an open question elsewhere; it is used here because the
question *is* which hexes are covered by what. Bare board is grey, each domain a tint,
fused hexes a third. Shrines are white blocks, the Altar a taller gold one.

### The census

Printed before the renders, and the real answer to the ticket. Every number is exhaustive
rather than sampled — the coverage search tries every placement of `n` shrines on the
board.

```
how many board hexes can host a shrine that reaches one target
  radius 3 (37 hexes): centre 19, max 19, min 9, median 14
  radius 4 (61 hexes): centre 19, max 19, min 9, median 16
  radius 5 (91 hexes): centre 19, max 19, min 9, median 16

most hexes n shrines can cover between them, exhaustive
  radius 3 (37 hexes): 1:19 (51%)  2:29 (78%)  3:37 (100%)  4:37 (100%)
  radius 5 (91 hexes): 1:19 (21%)  2:38 (42%)  3:57 (63%)

what the Altar's triangle-three can be reached from
  radius 3: 12 hexes reach all three (9 of them free of the Altar itself), 27 reach one
  radius 5: 12 hexes reach all three (9 of them free of the Altar itself), 27 reach one

depth from n same-domain shrines over one hex
  0:0  1:0  2:1  3:2  4:3  5:4  6:4
```

The radius-5 coverage search stops at three shrines: four is 2.7 million placements, past
what is worth spending a prototype run on. The figure quoted in #78's resolution for four
shrines at radius 5 (72 of 91) comes from the same search written in Python, not committed,
the way `zones2.py` was for [#52](https://github.com/snackpackgames/cosmicparade/issues/52).

### The renders

| | board | shrines | covered | depth | Altar reads |
|---|---|---|---|---|---|
| 1 | radius 3 | 2 fed, one domain | 29/37 | 1 on 3 hexes | 2, 1, 1 |
| 2 | radius 3 | 3 fed, one domain | **37/37** | 2 on 1 hex, 1 on 9 | 3, 2, 2 |
| 3 | radius 3 | 5 fed, one domain, piled | 25/37 | 4 on 6 hexes | 5, 1, 2 |
| 4 | radius 3 | the same 5, all vessels empty | **0/37** | flat | 0, 0, 0 |
| 5 | radius 5 | the same 5, piled | 35/91 | 4 on 6 hexes | 5, 1, 2 |
| 6 | radius 3 | 2 fed, over 6 furniture pieces | **37/37 fused** | 1 on 10 hexes | 2, 1, 1 |

Scenario 2 uses the covering triple an exhaustive search found, so it is an upper bound
rather than a typical arrangement — which is what makes it a fair test. Scenarios 3 and 5
share the same five shrine positions so the two boards can be compared directly.

## What it showed

- **Three shrines blanket the starting board.** Not "most of" — every one of the 37 hexes,
  from three single-hex pieces (render 2). Two already reach 78%.
- **Growth dilutes the fraction, never the reach.** Any interior hex has exactly 19 hexes
  that could host a shrine reaching it, identically at radius 3, 4 and 5. A bigger board
  does not make a hex harder to pile influence onto; it only makes one shrine a smaller
  share of the whole, 51% → 21%.
- **Depth 4 needs five same-domain shrines and no skill.** There are 19 hosts to choose 5
  from, so 11,628 arrangements reach the ceiling over a given hex — against 21 for
  radius-1 furniture, where the five pieces must ring the target exactly. Shrine depth is
  gated by fruit supply, as [#75](https://github.com/snackpackgames/cosmicparade/issues/75)
  found, and not by geometry at all.
- **Fed shrines drown out furniture arrangement.** Two shrines — the starting capacity —
  over six furniture pieces of another domain leaves the board **37/37 fused**, with the
  furniture's own domain surviving in two rim patches (render 6). The arrangement is still
  there; it stops being *visible* as arrangement.
- **The swing is total.** The same five shrines with empty vessels raise nothing and tint
  nothing: 0 of 37 (render 4). Shrine influence is all-or-nothing per shrine, so a realm
  returned to between parades can look entirely different with nothing moved.
- **A shrine's radius decides whether the Altar can be read evenly.** 12 hexes lie within
  distance 2 of all three of the Altar's hexes, 9 of them free to stand on. At radius 1 the
  only three hexes within distance 1 of all three are **the Altar's own**, so no shrine
  could ever cover it uniformly. The triangle-three footprint
  ([#77](https://github.com/snackpackgames/cosmicparade/issues/77)) and the radius-2 zone
  ([#74](https://github.com/snackpackgames/cosmicparade/issues/74)) are entangled in a way
  neither ticket could have seen alone.
- **Shrines can raise ground out from under a legally-placed Altar.** In render 3 the
  Altar's three hexes stand at depths 4, 0 and 1 — a footprint that is not level, and so
  one the Altar could not have been placed on under #77's gate. Criteria are never
  re-checked ([#55](https://github.com/snackpackgames/cosmicparade/issues/55)), so it
  stands; it is visible in the render as the Altar straddling a terrace.

## Running it

```bash
GODOT="$(grep '^GODOT=' ../../../.env | cut -d'"' -f2)"
OUT=/tmp/shrine-proto-out && mkdir -p "$OUT"
"$GODOT" --path . --resolution 1280x720 -- "$OUT"
```

From the repo root, swap `--path .` for `--path test/prototypes/78-shrine-influence-reach`.
The output directory is read from `OS.get_cmdline_user_args()` — the argument after `--` —
and must be absolute. It writes the six PNGs named in the table. They are not committed;
see `../README.md`.

`surface.gdshader` is a copy of `common/surface.gdshader` taken 2026-11-15, not a
reference to it.
