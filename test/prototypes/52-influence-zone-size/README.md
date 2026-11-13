# What size and shape is a furniture piece's influence zone?

Built to resolve [Decide the size and shape of a furniture piece's influence zone](https://github.com/snackpackgames/cosmicparade/issues/52),
a `wayfinder:prototype` ticket on the map
[Map: the realm board and the arrangement puzzle](https://github.com/snackpackgames/cosmicparade/issues/49).
The resolution comment on #52 is the authoritative record; this file says what the code
does and how to re-run it.

## What it builds

The radial hexagon of radius 3 settled by
[Decide the realm board's shape and extent](https://github.com/snackpackgames/cosmicparade/issues/50)
— 37 spaces — with furniture pieces drawn from the five-shape polyhex vocabulary settled by
[Decide how much of the board a furniture piece occupies](https://github.com/snackpackgames/cosmicparade/issues/51).
Each piece projects exactly one zone of domain influence, and the board is tinted by what
covers each hex: bare, domain A, domain B, or fused where both reach.

Every rule downstream of the zone is held fixed at what it was already decided to be, so
the only variables are zone extent and anchoring: discrete risers of 0.35 per burgeon depth
([#28](https://github.com/snackpackgames/cosmicparade/issues/28),
[#29](https://github.com/snackpackgames/cosmicparade/issues/29)), depth taken as the
per-domain **maximum** rather than a sum ([#40](https://github.com/snackpackgames/cosmicparade/issues/40)),
and a domain's first zone raising nothing ([#37](https://github.com/snackpackgames/cosmicparade/issues/37)).

Colour-coding domains is still an open question elsewhere; it is used here because the
question *is* which hexes are covered by what, which geometry alone cannot show.

Eight scenarios. Every count is deterministic and printed on each run, so a changed line
means changed geometry:

| | zone | anchoring | pieces | covered | fused | interior |
|---|---|---|---|---|---|---|
| 1 | radius 1 | origin | 1 single | 7/37 | 0 | 0 |
| 2 | radius 2 | origin | 1 single | 19/37 | 0 | 0 |
| 3 | radius 1 | origin | 1 straight-three | 7/37 | 0 | 0 |
| 4 | radius 1 | grown | 1 straight-three | 13/37 | 0 | 0 |
| 5 | radius 1 | origin | 6 singles, two domains | 20/37 | 14 | 4 |
| 6 | radius 2 | origin | 4 singles, two domains | 29/37 | 29 | 13 |
| 7 | radius 1 | origin | 5 singles, one domain | 16/37 | 0 | 0 |
| 8 | radius 1 | grown | 4 mixed, two domains | 24/37 | 13 | 1 |

**Origin** anchoring puts a piece's single zone at its origin hex only. **Grown** unions a
disc around every hex the piece occupies, so a larger piece reaches further and its zone
takes the footprint's shape. *Fused* counts hexes two domains both reach; *interior* counts
fused hexes whose six neighbours are all fused — what `adr/0008` fills with biome ground,
as opposed to the boundary where it spawns features.

Scenarios 5 and 6 are not typical arrangements: both are the **best** interior achievable
at that zone size, found by exhaustive search over the board (`zones2.py`, not committed —
the search is restated in the resolution comment). They are upper bounds, which is what
makes the comparison fair.

## What it showed

- **Radius 2 leaves no puzzle.** One piece claims 19 of 37 hexes, the whole middle of the
  board (render 2). Four pieces across two domains fuse 29 of 37 and the board is a single
  sheet of colour (render 6) — overlap stops being something a player aims for and becomes
  something they cannot avoid.
- **Radius 1 makes interiors earned rather than absent.** A *pair* of radius-1 zones
  overlaps in at most 4 hexes and never encloses one, so a first reading was that
  `adr/0008` would have nothing to fill. That is wrong for the region that actually
  matters — "where two domains both reach", across all pieces — which reaches a 2-hex
  interior at four pieces and 4 hexes at six (render 5).
- **Origin anchoring makes footprint pure cost.** A three-hex piece projects the same 7
  hexes as a single tile and stands on 3 of them, leaving 4 hexes of reach past itself
  (render 3). Grown anchoring gives it 13, shaped along the piece's orientation (render 4),
  so the five footprints become five zone shapes with nothing extra authored.
- **Elevation's ceiling is reachable without being routine.** Five same-domain pieces
  ringing one hex produce a terraced mound carrying every depth from 1 to 4 (render 7).
  This retires the question
  [Map: what generates elevation in the realm](https://github.com/snackpackgames/cosmicparade/issues/26)
  parked about whether depth 4 is inert.
- **The two dials multiply, and the product has a ceiling.** Grown from every occupied hex,
  a straight-three at radius 2 covers 29 of 37 hexes — 78% of the board from one piece.
  With radius authored per piece, that combination is the practical top of the range, not a
  tuning knob:

  | footprint | radius 0 | radius 1 | radius 2 |
  |---|---|---|---|
  | single | 1 (3%) | 7 (19%) | 19 (51%) |
  | pair | 2 (5%) | 10 (27%) | 24 (65%) |
  | straight-three | 3 (8%) | 13 (35%) | 29 (78%) |
  | bend-three | 3 (8%) | 12 (32%) | 27 (73%) |
  | triangle-three | 3 (8%) | 12 (32%) | 27 (73%) |

## Running it

```bash
GODOT="$(grep '^GODOT=' ../../../.env | cut -d'"' -f2)"
OUT=/tmp/zone-proto-out && mkdir -p "$OUT"
"$GODOT" --path . --resolution 1280x720 -- "$OUT"
```

From the repo root, swap `--path .` for `--path test/prototypes/52-influence-zone-size`.
The output directory is read from `OS.get_cmdline_user_args()` — the argument after `--` —
and must be absolute. It writes the eight PNGs named in the table. They are not committed;
see `../README.md`.

`surface.gdshader` is a copy of `common/surface.gdshader` taken 2026-11-13, not a
reference to it.
