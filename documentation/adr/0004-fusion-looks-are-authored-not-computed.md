# Fusion looks are authored, not computed

When domain influences overlap, the resulting look — colour and animated glaze
pattern — is read from an authored lookup table, one entry per combination. It is
**never** an arithmetic blend of the component domains' colours.

Arithmetic mixing is the obvious implementation and it fails precisely where the game
needs clarity: a three-way overlap averages to brown, and fusion is the whole point of
the board. Flat, bounded, deliberate colour is also what the mosaic art style is made
of — real mosaics are discrete tesserae, not gradients.

## Consequences

The table is `.tres` Resource data, matching the project's data-in-Resources
convention. Authoring cost scales with the number of domains, which is why the roster
is capped at six — see ADR-0005. Do not "fix" this by blending colours
programmatically.
