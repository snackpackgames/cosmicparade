# Biomes fill interiors; features spawn on boundaries

Terrain generation separates **area** from **event**. Where domain influences overlap,
the *interior* of the overlap becomes fused biome ground — walkable, plantable, a new
terrain type. Distinct **features** — a waterfall, an arch, a geyser — spawn only
where a *boundary* meets that feature's conditions, which for a waterfall includes a
height drop.

## Consequences

Two generation systems rather than one. In exchange, blocking geometry stays off zone
interiors, so a decorated garden remains walkable, and a waterfall gets both the edge
and the fall it needs. Per-feature spawn conditions are authoring work. Note that
nothing in the design yet generates elevation — features require height that no system
currently produces, which remains open.
