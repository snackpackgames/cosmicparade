# The repo layout follows the `area:` labels

The project has one system vocabulary: the `area:` label set — `realm`, `parade`,
`tiles`, `entities`, `terrain`, `scoring`, `save`, `ui`, `audio`, `multiplayer`. A
system directory is named after a label, and the same name runs across the issue label,
the source directory, `test/unit/<name>/`, `data/<name>/` and `assets/<name>/`. Someone
who knows what to call a system already knows where its code, tests, authored data and
art live.

Scenes that are screens (Title, Character Creation) belong to `ui`; only Realm and
Cosmic Parade are systems with a scene of their own.

## Two kinds of top-level directory

The label rule alone does not describe the tree. `addons/`, `data/`, `assets/`, `test/`,
`scripts/`, `documentation/` and `notes/` are not systems, and neither is the shared
surface shader, which every system's meshes use and no label names. So there are two
categories:

- **System directories** are named after an `area:` label and hold gameplay code.
- **Structural directories** are named for what they hold, and membership is a closed,
  enumerated list. Adding one is a documented decision, not a judgement call made in a
  PR. Without the list, nothing stands between the tree and `utils/`, `helpers/` and
  `misc/`.

`common/` is the structural directory for cross-cutting source. A thing is admitted
only if more than one system uses it *and* no system owns it. Anything used by a single
system stays with that system until a second one needs it.

`test/unit/` mirrors system directories and `common/`, the places holding testable
logic, and nothing else.

## Rejected alternatives

- **Grouping by node kind** (`scenes/`, `scripts/`, `resources/`). It splits every
  system across directories, so working on tiles means touching four trees. It also
  gives `.tscn`/`.gd` pairing no natural home, and `test/unit/` could no longer mirror
  the source tree mechanically.
- **A `src/` umbrella.** It adds a path segment that carries no information, since
  the repo root already holds nothing but source and the structural directories. It
  would also break `bash scripts/test.sh <system>` and the `res://test/unit/` mirror
  rule for no gain.

## Consequences

Several conventions are consequences of the shared vocabulary, not independent
decisions, and are recorded where they are used:

- **Physics layers** are numbered in blocks of eight aligned to the labels, so each
  block is one inspector row and a new role never shoves another system's bit. Domain
  influence gets no layer, because it is hex-grid data.
- **Autoloads** need to outlive a scene change and be needed by more than one system.
  Cross-system events share one project-wide `SignalBus`, not one bus per label.
- **`GameData`** is the shared base for authored resources, living in `common/`. Resource
  scripts stay with their system and instances live at `data/<system>/<type>/<instance>.tres`.

`CLAUDE.md → Architecture` holds the directory table and these rules. This ADR holds
only the reasoning. A separate `documentation/ARCHITECTURE.md` waits until a second
system needs cross-referencing.
