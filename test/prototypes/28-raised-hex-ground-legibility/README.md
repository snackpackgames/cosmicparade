# Does raised hex ground read at a glance?

Built to resolve [Does raised hex ground read at a glance?](https://github.com/snackpackgames/cosmicparade/issues/28),
a `wayfinder:prototype` ticket on the map
[Map: what generates elevation in the realm](https://github.com/snackpackgames/cosmicparade/issues/26).
The resolution comment on #28 is the authoritative record; this file says what the code
does and how to re-run it.

## What it builds

A radius-5 flat-top hex board, 91 cells. Four overlapping same-domain influence zones
give each cell a **burgeon depth** — how many zones cover it — and height is depth times
a step, per the resolution of
[Decide what raises the realm's ground](https://github.com/snackpackgames/cosmicparade/issues/27).
The zone layout is fixed, so the depth histogram is deterministic and printed on every
run: `{0: 12, 1: 43, 2: 23, 3: 11, 4: 2}`. If that line changes, the geometry changed.

One uniform mosaic material on every surface, on purpose. Colour-coding domains is a
separate open question, so geometry had to carry height unaided — tinting each depth
would have answered an easier question than the one asked.

Six renders, varying only step size, step form and camera pitch:

| | form | step | pitch |
|---|---|---|---|
| 1 | riser | 0.15 | 50° |
| 2 | riser | 0.35 | 50° |
| 3 | riser | 0.70 | 50° |
| 4 | riser | 0.35 | 22° |
| 5 | slope | 0.35 | 50° |
| 6 | slope | 0.70 | 50° |

**Riser** gives every corner of a hex its own cell's height, so each height change is a
vertical wall on the hex boundary. **Slope** averages each corner across the three cells
sharing it, so the surface is continuous. Both are the same mesh builder; the only
difference is that corner height.

## What it showed

- **Discrete risers read; slopes do not.** At the same 0.35 step, render 2 is plainly
  terraced and render 5 is nearly flat — averaging corners both halves the apparent
  height change and erases the hex boundary the eye was using to measure it.
- **Step size has a usable band.** 0.15 is too subtle to notice, 0.35 is unambiguous,
  0.70 is emphatic. The number itself belongs to
  [Decide elevation's step size and ceiling](https://github.com/snackpackgames/cosmicparade/issues/29).
- **Occlusion is not a constraint.** Render 4 drops the camera to 22° and raised ground
  still hides almost nothing behind it.
- **The mosaic has a legibility floor**, found by tripping over it: the first pass used a
  UV scale that put tesserae under one screen pixel and the whole board dissolved into
  moiré shimmer, elevation or not. It needs mipmaps on the shared shader's
  `filter_nearest_mipmap` sampler and roughly eight tesserae per hex before it reads as
  laid tile. Not elevation-specific — a flat board at the same distance shimmers
  identically — so it is recorded under *Out of scope* on the map as a realm camera and
  art-direction concern.

## Running it

```bash
GODOT="$(grep '^GODOT=' ../../../.env | cut -d'"' -f2)"
OUT=/tmp/elev-proto-out && mkdir -p "$OUT"
"$GODOT" --path . --resolution 1280x720 -- "$OUT"
```

From the repo root, swap `--path .` for `--path test/prototypes/28-raised-hex-ground-legibility`.
The output directory is read from `OS.get_cmdline_user_args()` — the argument after `--`
— and must be absolute. It takes about ten seconds and writes the six PNGs named above.
They are not committed; see `../README.md`.

`surface.gdshader` is a copy of `common/surface.gdshader` taken 2026-11-08, not a
reference to it.
