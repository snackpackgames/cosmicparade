# Influence effects are matched greedily from a sparse table

`adr/0004` settled that fusion looks are authored, not computed. This records the shape that
authoring takes, which 0004 left open.

An influence effect is an authored `GameData` Resource, purely visual, and `Domain.Kind` stays at
exactly six. A meld produces no new mechanical type and nothing gates on its result
([#108](https://github.com/snackpackgames/cosmicparade/issues/108), `adr/0005`).

An entry is keyed by an unordered set of domains. The table is sparse and ordered, and matching is
greedy subset containment: the largest authored subset wins and consumes the domains it claims,
ties going to authored file order ([#107](https://github.com/snackpackgames/cosmicparade/issues/107)).
A table of pairs therefore covers every arity, which is the authoring reduction that motivated the
shape. Nothing is blended, averaged or derived, so `adr/0004` holds.

A one-domain entry is the fallback for an unclaimed domain. That is why there is no array indexed by
`Domain.Kind`, and why the enum's order is not load-bearing
([#113](https://github.com/snackpackgames/cosmicparade/issues/113)).

Depth amplifies an effect and never keys a lookup; intensity is read per effect from its own
domains ([#113](https://github.com/snackpackgames/cosmicparade/issues/113)). One authored ceiling
effect is the single exception, preserving the limit-versus-count signal
[#42](https://github.com/snackpackgames/cosmicparade/issues/42) argued for.

Meld never touches height. The two are orthogonal by construction, because there is no shared input
to arbitrate ([#109](https://github.com/snackpackgames/cosmicparade/issues/109)). `adr/0014` is
unchanged.

A hex's effects are derived from the zones on every call and stored nowhere. A region is contiguous
hexes whose effect sets agree ([#106](https://github.com/snackpackgames/cosmicparade/issues/106)).

## Alternatives rejected

All 57 combinations authored with no fallback rule: an authoring explosion, once greedy consumption
was seen to need only pairs. A six-slot per-domain array beside the entries: a second mechanism for
one job. A per-depth or per-domain "maxed" effect: amplification needs no new data, and this needed
six or twelve more authored effects plus a membership rule. Suppressing a consumed domain's height:
the authored art table would become balance data, since `realm/placement_context.gd:30` feeds
`HeightCriterion` and `LevelFootprintCriterion`.

## Consequences

Reordering the authored file is a gameplay change, not layout. A region straddling the depth-4
contour is two regions, so `adr/0008`'s biome fill sees two interiors. Set equality is instance
equality while an effect is shared authored data, and breaks if an effect is ever instanced per hex.
What an effect's intensity does (particle count, a shader uniform) is art work still deferred, as is
what any combination actually fuses into.
