# The board never asks what is standing on it

The realm board decides behaviour from the components a piece carries, not from what kind of
piece it is. This records the rule that keeps type tests out of the board, which the placement
seam map settled ([#126](https://github.com/snackpackgames/cosmicparade/issues/126)).

[#104](https://github.com/snackpackgames/cosmicparade/issues/104) found three sites in `realm/`
that asked what a **piece** is in order to decide something about a **placement**. All three were
wrong for the same reason: the behaviour that varies belongs to the object that varies, and
asking a collaborator's type couples the board to every piece class that will ever exist.

## The criterion

Test the type of the object whose behaviour varies. Never reach through to ask a collaborator's
type. A type test applied to the object that owns the varying behaviour is fine; the same test
applied to something it holds, or something that holds it, is a reach-through.

The criterion sorts all seven type tests in `realm/` with no exemption clause.

## The stopping rule

An implementer greps for it: a type test on `piece` or `<something>.piece` that governs a
placement is a reach-through. Replace it with a question the component answers about itself
(`adr/0018` follows the capability-question shape of
[#135](https://github.com/snackpackgames/cosmicparade/issues/135)).

## What is not governed

Engine-boundary narrowings are legitimate: `$Node as Type` and `load(...) as Type` convert what
the engine hands back, and say nothing about game objects. Assertions in `test/unit/` are not
governed either; a test may check what a thing is.

## Reading authored data is not a reach-through

`piece.criteria`, `piece.zone_source` and `piece.reading` are field reads of authored data, not
type tests ([#135](https://github.com/snackpackgames/cosmicparade/issues/135)). The rule forbids
asking what something *is*, not reading what it *carries*. Without this clarification the rule
would be over-applied and the component slots could not be read at all.

## Alternatives rejected

An exemption clause for "obviously fine" type tests: the criterion already sorts every existing
site without one, and an exemption is where the next reach-through would hide. Banning `is` and
`as` outright: engine-boundary narrowings need them.

## Consequences

A new piece kind adds components, not branches in the board. Where a question has no component
to answer it yet, the answer is to add a default-false capability method to the component base,
not a type test.
