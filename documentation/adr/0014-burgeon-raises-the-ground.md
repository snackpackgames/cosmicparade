# Burgeon raises the ground

Burgeon is what raises a hex, so a lone zone raises nothing and the second overlapping zone
of the same domain is the first riser ([#27](https://github.com/snackpackgames/cosmicparade/issues/27), [#37](https://github.com/snackpackgames/cosmicparade/issues/37)).

Depth is capped at 4, and the step is `0.35 × hex circumradius` — a ratio of hex size, never
a world-space constant. The cap lands on depth at the source, not on rendered height
([#29](https://github.com/snackpackgames/cosmicparade/issues/29)).

Where several domains burgeon on one hex the depths are compared, not added: the hex takes
the maximum ([#40](https://github.com/snackpackgames/cosmicparade/issues/40)).

Height is derived from the influence zones on demand and never stored, which is what lets a
hypothetical arrangement be evaluated without mutating the board
([#33](https://github.com/snackpackgames/cosmicparade/issues/33), [#31](https://github.com/snackpackgames/cosmicparade/issues/31)).

The rise is discrete risers, never a smoothed slope. The prototype in
`test/prototypes/28-raised-hex-ground-legibility/` is the evidence ([#28](https://github.com/snackpackgames/cosmicparade/issues/28)).

One rule for all six domains; nothing branches per domain ([#32](https://github.com/snackpackgames/cosmicparade/issues/32)).

Raised ground stays on `realm_space` and the layer table does not change, because a raised
hex is still a hex space of the realm board ([#39](https://github.com/snackpackgames/cosmicparade/issues/39)).

Removing furniture lowers the ground it raised, immediately and with no high-water mark
([#38](https://github.com/snackpackgames/cosmicparade/issues/38)).

## Alternatives rejected

Height-driven generation was rejected before this map was charted as too unpredictable to
decorate on. Elevation as a property of specific furniture, and authored relief shipped with
the floating rock, were the other candidates. Burgeon won because it gives an existing
mechanic a physical meaning and makes intensity visible without taking height out of the
player's hands.

## Consequences

Height becomes a per-piece placement criterion, read against the board including the placing
piece's own influence ([#30](https://github.com/snackpackgames/cosmicparade/issues/30), [#41](https://github.com/snackpackgames/cosmicparade/issues/41)). The per-domain read and the depth-4
"maxed" read are authored art on a raised hex, deferred ([#32](https://github.com/snackpackgames/cosmicparade/issues/32), [#42](https://github.com/snackpackgames/cosmicparade/issues/42)). Whether
a depth of 4 is reachable in play depends on influence zone size, which the realm board map
owns.
