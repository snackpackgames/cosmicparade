# What shapes belong in the wing vocabulary, and does orientation matter?

Built to resolve [Decide the wing vocabulary and whether wings rotate](https://github.com/snackpackgames/cosmicparade/issues/61),
a `wayfinder:prototype` ticket on the map
[Map: the realm board and the arrangement puzzle](https://github.com/snackpackgames/cosmicparade/issues/49).
The resolution comment on #61 is the authoritative record; this file says what the code
does and how to re-run it.

## What it builds

The core at its post-Swell ceiling — the radial hexagon of radius 5, 91 spaces, settled by
[Decide the realm board's shape and extent](https://github.com/snackpackgames/cosmicparade/issues/50)
and [Decide how the board's geometry changes when the realm grows](https://github.com/snackpackgames/cosmicparade/issues/53)
— with candidate **wings** attached edge-adjacent to it. Everything else is held fixed:
wings are all one hex count, they attach to any board hex, and a wing is just more board on
the same lattice (#53).

The metric is **full reach**. A hex is *full* when a radius-1 disc centred on it lies
entirely on the board, so a piece standing there loses none of the zone
[#52](https://github.com/snackpackgames/cosmicparade/issues/52) gives it; otherwise it is
*rim*, and some of its influence falls into the void where
[#59](https://github.com/snackpackgames/cosmicparade/issues/59) leaves it inert. **The core
alone is 61 full of 91.** A wing's worth is not the hexes it adds but the *full* hexes the
board gains — and a wing can upgrade core rim hexes as well as supply its own.

Core and wing are tinted apart, light for full and dark for rim. As in the #52 prototype,
colour is a readability crutch for this question, not a proposal.

Twelve scenarios. Every count is deterministic and printed on each run:

| scenario | hexes | distinct rotations | seam hexes | full after | gain | full on wing | notches |
|---|---|---|---|---|---|---|---|
| core only | — | — | — | 61 | — | — | 0 |
| flower-7 (disc) | 7 | **1** | 2 | 63 | +2 | 1 | 2 |
| fan-7 (trapezoid) | 7 | 6 | 4 | 65 | **+4** | 2 | 2 |
| triangle-6 | 6 | 2 | 3 | 63 | +2 | 1 | 2 |
| rhombus-6 (2×3) | 6 | 3 | 3 | 63 | +2 | 1 | 2 |
| line-7, pointing out | 7 | 3 | 1 | 61 | **+0** | 0 | 2 |
| line-7, along the rim | 7 | 3 | 7 | 65 | **+4** | 0 | 2 |
| arm-7 (bent) | 7 | 6 | 1 | 61 | +0 | 0 | 3 |
| small-4 | 4 | 3 | 2 | 62 | +1 | 0 | 2 |
| big-10 | 10 | 6 | 2 | 63 | +2 | 1 | 4 |
| the four-figure roster | 26 | — | 11 | 71 | +10 | 4 | 7 |
| sprawl, six wings | 40 | — | 13 | 74 | +13 | 6 | 11 |

*Seam hexes* counts wing hexes touching the core. *Notches* counts off-board hexes touching
three or more board hexes — pockets a later wing can nest into. *Distinct rotations* is how
many of a shape's six rotations differ, ignoring translation.

## What it showed

- **Orientation is worth as much as shape.** `line-7` pointing outward adds **0** full
  hexes — seven hexes of pure rim on a one-wide spike. The *same seven hexes* laid along
  the rim adds **4**, and touches the core at 7 hexes instead of 1. One shape, one size, two
  orientations, and the entire difference between a useful wing and a decorative whisker.
- **Rotation matters per entry, and not at all for one of them.** A disc has exactly
  **one** distinct rotation, so turning a `flower-7` can never do anything; `triangle-6` has
  2, `rhombus-6` 3, `fan-7` 6. A rotate input that always offered six steps would be dead on
  the entry players reach for most.
- **Shape and orientation beat the size dial.** Across compact shapes, hex count barely
  moves the needle: 4 hexes gains +1, 7 gains +2, 10 gains +2. At a fixed 7 hexes, shape and
  orientation swing the gain from +0 to +4. Choosing the number is the least consequential
  part of this ticket.
- **The 6-hex figures are the most efficient entries in the set.** `triangle-6` and
  `rhombus-6` both gain +2 and both carry 1 full hex of their own — matching `flower-7`
  with one hex fewer. A one-hex spread in the vocabulary costs nothing measurable.
- **Width, not size, is what gives a wing its own interior.** `flower-7` carries exactly 1
  full hex and `big-10` — pointing outward — also carries 1. `fan-7`, two rows deep against
  the rim, carries 2. A one-wide entry of any length carries none, ever: every hex of a
  single-file strip has an off-board neighbour.
- **Wings add cheap land, and that is consistent rather than a defect.** The core alone is
  67% full (61/91). After six wings it is 56% (74/131) — 34 of the 40 added hexes are rim.
  [#59](https://github.com/snackpackgames/cosmicparade/issues/59) settled that the rim
  gradient is a feature, so wing growth expands decorating room without diluting the
  contested middle. It does mean a player chasing burgeon depth should Swell the core, not
  bolt on wings.
- **Chaining reads as an archipelago, not as sprawl** (render 12). Discs chained off discs
  look like satellite rocks; the rejected one-wide `arm-7` reads as a whisker, which is
  exactly the legibly-bad buy #53 was willing to allow and this vocabulary chooses not to
  stock.

### Hex arithmetic that constrained the roster

Rhombi exist at a×b — 2×3 = 6, 2×4 = 8, 3×3 = 9 — and triangular numbers are 1, 3, 6, 10.
**Seven is prime and non-triangular, so there is no rhombus and no triangle at seven**; the
2-3-2 column arrangement that most resembles a diamond *is* the radius-1 disc. The disc (7)
and the trapezoid (7) are the only clean figures at that count, which is what forced the
6–7 spread the resolution settles on.

## Running it

```bash
GODOT="$(grep '^GODOT=' ../../../.env | cut -d'"' -f2)"
OUT=/tmp/wing-proto-out && mkdir -p "$OUT"
"$GODOT" --path . --resolution 1280x720 -- "$OUT"
```

From the repo root, swap `--path .` for `--path test/prototypes/61-wing-vocabulary`. The
output directory is read from `OS.get_cmdline_user_args()` — the argument after `--` — and
must be absolute. It writes the twelve PNGs named in the table. They are not committed; see
`../README.md`.

`surface.gdshader` is a copy of `common/surface.gdshader` taken 2026-11-13, not a
reference to it.
