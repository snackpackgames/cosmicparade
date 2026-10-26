# Tiles are assembled from slots, not from recipes

A fired tile *is* its components: **clay** sets the domain, **dye** sets the effect, an
optional **glaze** adds a bonded entity's ability and presence, and **fuel** sets
quality. There is no authored recipe table and nothing is looked up.

## Consequences

The word **recipe** is retired from the design — earlier notes spoke of "unlocking new
tile recipes", but progression unlocks new *clays and dyes* instead. Discovery
therefore lives in the realm, where growing new biomes yields new materials; the kiln
executes plans rather than producing surprises. A tile is Resource references with no
per-tile authoring, and a tile's parts are readable as its rules.
