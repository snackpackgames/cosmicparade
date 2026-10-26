# Tiles are the only playable object

Early design notes referred to both "cards" and "tiles". There is only one playable
object: the **tile**. Tiles occupy the role cards play in the deckbuilding genre —
acquired, drafted, drawn, combined — but there is no separate card class, and "card"
is retired as a noun in this project.

## Consequences

"Deck" survives only as the name for a loadout assembled from a bag; it is not a
container of cards. Anyone reading older notes, or the genre label "mosaic
deckbuilding", should expect no `Card` type to exist.
