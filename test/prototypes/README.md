# Prototypes

Throwaway Godot projects built to answer one design question, kept after the fact so the
evidence behind a decision stays reproducible.

**Nothing here is authoritative and nothing here ships.** A prototype is a record of what
was true at the moment a question was asked — the same standing as `notes/`. It is not a
spec, not a reference implementation, and not a starting point for the real system. When
the real system arrives it is written fresh against `README.md` and the ADRs; a prototype
that contradicts them is simply out of date, and no one is expected to update it.

## Layout

One directory per prototype, named `<issue-number>-<slug>/`, each a **self-contained Godot
project** with its own `project.godot`. The issue number is the identity — the question
lives on the tracker, and the directory is the artifact linked from its resolution.

Being its own project is what keeps a prototype from rotting the game: it has no
`res://` path into the real tree, so it cannot be imported by accident and the real
project's refactors cannot break it. Files it needs from the game — the surface shader,
for instance — are **copied in**, deliberately, as a snapshot.

`.gdignore` in this directory keeps the main project from scanning any of it. Godot
already skips a folder holding its own `project.godot`, but it warns on every import when
it does; the ignore file silences that and covers any future prototype that has no
`project.godot` of its own. Because nothing here is imported, these files have no `.uid`
or `.import` sidecars, and the usual rule about committing those does not apply.

GDScript here **is** linted — `scripts/lint.sh` finds every `*.gd` outside `addons/`.
Rough is fine, unparseable is not.

## Running one

Each prototype's own README gives its exact command. The shape is always:

```bash
source .env   # or read GODOT from it
"$GODOT" --path test/prototypes/<dir> --resolution 1280x720 -- /abs/path/to/output
```

Rendered output is not committed — it is regenerable in seconds, and `out/` directories
are gitignored. Write renders somewhere outside the repo.
