# The Cosmic Parade

*Our Divine Pageantry, or: How I Woke Up as a Godling and Used Fruit to Make Friends with Spirits to Defeat the Darkness.*

You wake as a nascent god with no memory of what earned your ascendance. You have a
floating rock, a few sticks of furniture, some fruit, and four tiles. The cosmic
expanse is rotting from neglect. You are going to fix it by gardening, befriending
spirits, and throwing the most compelling parade anyone has ever seen.

> **Status:** design document. There is no Godot project in this repo yet — see
> `CLAUDE.md → Status` and `CONTRIBUTING.md → Repo setup`. Nothing below is
> implemented.

## Genre

Mosaic deckbuilding · pet management · cozy sandbox room decorator · crafting.

Two halves that feed each other: a **cozy realm-tending half** where you decorate,
grow, cook, and befriend, and a **competitive tile-laying half** where the things you
made become a deck you play against other gods for influence and loot.

## Influences

- **Sonic Chao Garden** — entities you raise, gift, and watch wander
- **Viva Piñata** — a garden whose arrangement determines who shows up
- **Pokémon** — collection and bonding
- **Spelljammer (D&D)** — cosmic sailing ships, floating rock realms
- **Magic: The Gathering** — tile effects that fuse and combo

## Art Direction

Pixel art **in the style of mosaics** — a higher pixel count per sprite than
classic pixel art, but still styled so everything reads as laid tile. Your realm is
a cluster of floating rocks against a shifting skybox of cosmic dust and plasma, its
style and palette set by your chosen avatar.

Neon magical gnomes in space. Very groovy. Science, tech, and magic meet in high
fantasy.

**This is a 3D game.** The pixel-mosaic look sits on 3D geometry: the hex board has
real dimension, and **terrain grows up out of it**. Tiles are volumes, not flat
sprites on a plane.

## The Core Loop

```
          ┌──────────────────────── REALM ────────────────────────┐
          │                                                       │
   arrange furniture ──► domain influence zones ──► fused biomes & terrain
          │                         │                             │
          │                         ▼                             ▼
          │                    fruit & flowers ──► offerings,  clay dyes
          │                         │              cooking
          │                         ▼
          │                  shrines (offer fruit)
          │                         │
          │                         ▼
          │                  entities arrive, wander, bond
          │                         │
          │                         ▼
          │              Altar: SUMMON entities / FIRE tiles
          │                         │   (entities GLAZE tiles,
          │                         │    lending their effect + presence)
          │                         ▼
          │                  tiles ──► bags ──► decks
          │                         │
          └─────────────────────────┼───────────────────────────────┘
                                    ▼
                        Shipyard Mooring: PARADE
                                    │
          ┌───────────────── COSMIC PARADE ──────────────────┐
          │  play a PAGEANT on the parade grounds:           │
          │  draw from bag, place a tile, tiles interact,     │
          │  flip, fuse, score attention                      │
          │  ──► adherents, materials, furniture designs      │
          └───────────────────┬──────────────────────────────┘
                              ▼
                    Swell the realm, unlock recipes,
                    attract stronger entities ──► loop
```

Progression pressure comes from the top end: stronger entities demand better
offerings, which demand more specific fused domains, which demand more furniture and
a bigger realm, which demands more pageant winnings.

## Terminology

These words are easy to confuse and they will end up as class names, so they are
pinned here.

| Term | Meaning |
|---|---|
| **Realm** | Your own floating-rock plane. The sandbox/decorator scene. |
| **Parade** | The *act of travelling* — sailing your ship out of the realm into the cosmic expanse. Also the unit of time that offerings and visits are measured in. |
| **Cosmic Parade** | The scene you arrive in after parading. |
| **Pageant** | A single match played on a parade ground. 1 player (vs. the blight) or 2–4 players. |
| **Parade ground** | The board a pageant is played on. Its space layout varies by player count. |
| **Tile** | The single playable unit, and the only one. Crafted in the realm, kept in bags, played in pageants. Two-faced. Tiles fill the role cards play in a deckbuilder — there is no separate card object. |
| **Bag** | Everything you own. Tiles are drawn from a bag during a pageant. |
| **Deck** | A chosen loadout assembled from your bag, picked before a pageant. |
| **Domain** | One of six themed influence types: Forest, Grassland, Wetland, Stone, Flame, Gale. Projected as an area. |
| **Avatar** | The player's chosen look and skybox palette. Purely cosmetic. *Also used in the design for a summoned entity's manifested form — see open questions.* |
| **Kit** | A starting loadout, one per domain: typed furniture and designs, fruit, seeds, early reward weighting. Chosen separately from the avatar. |
| **Domain influence** | The area a furniture piece, shrine, or tile projects its domain over. Always qualified as *domain* influence to keep it distinct from the pageant currency. |
| **Meld** | What happens when *different* domain influences overlap — produces a new type. |
| **Burgeon** | What happens when the *same* domain influence overlaps itself — it intensifies. The counterpart to Meld. |
| **Swell** | Spending adherents to enlarge your realm and gain shrine slots. |
| **Adherents** | The currency. The audience a pageant wins you, spent on Swell. |
| **Entity** | A spirit you attract, feed, bond with, summon, and who glazes your tiles. |
| **Glaze** | An ability an entity imparts into a tile when fired, drawn from its bond-gated list. Carries the entity's presence as well as its effect. |
| **Biome** | Fused terrain filling the *interior* of a domain-influence overlap. An area. |
| **Feature** | A distinct terrain object — waterfall, arch, geyser — spawning on a domain *boundary* where its conditions are met. An event, not an area. |
| **Viewer demand** | A structure a pageant's audience rewards (a meld, a chain, a burgeon stack). Domain-agnostic. The source of all points. |
| **Blight** | In solo play, a board condition that spreads each round and is pushed back by placing tiles. Not an opponent. |

## Scenes

The game is structured as these scenes:

### Title

- **New Awakening** → Character Creation
- **Load Realm** → load save state, open Realm
- **Settings** → tabs for sound and controls
- **Quit**

### Character Creation

Two independent picks: **who you look like** and **what you start with**.

#### Avatar — purely visual

Pick the one whose art you like. An avatar sets your appearance and the style and
colour of your realm's skybox, and nothing else. There is no mechanical reason to
prefer one, and no wrong choice.

| Avatar | Base look |
|---|---|
| Nurture | Gnome |
| Meander | Cat |
| Saturate | Frog / slime / salamander |
| Storm | Nuthatch / woodpecker |
| Tide | Octopus / cephalopod |
| Bogle | Shapeshifter / fox |
| Crest | Sheep / ram |
| Sunder | Elephant / rhino |
| Song | Whale |
| Wander | Horse / ox |
| Hibernate | Bear / wolf |
| Scorch | Lizard |

#### Starting kit — one of six domains

Chosen separately from a small set, one per domain. A kit gives typed starting
furniture and its designs, starting fruit and seeds, and a weighting on early reward
rolls.

| Kit | Domain |
|---|---|
| Forest | woodland, canopy, boreal |
| Grassland | plains, steppe, scrubland |
| Wetland | bog, tidepool, marsh, open water |
| Stone | rock, mountain, scree |
| Flame | desert, ember, ash |
| Gale | wind, storm, high air |

A starting kit **seeds the first few hours; it is not a class.** Nothing locks a
player to their opening domain — bags, furniture and friends can be steered wherever
they like, and a Forest start is a beginning, not an identity.

Twelve avatars against six kits gives 72 distinct openings from very little content.

### Realm

A floating rock of fixed tile size, starting at **10×10 hex spaces**, with **2
shrine slots**.

**Shrine slots** — a fixed *number* of slots, freely positioned by the player so long
as no two shrines overlap. Fruit placed in a shrine's offering slot produces an
effect. An offering sits there for a set number of parades and is then consumed.
Offerings may be pulled out and swapped early; a partly-consumed offering can be
replaced later.

**Swell** — spend adherents accrued from pageants to grow the realm's size and its
number of shrine slots.

**Furniture** — placeable on any tile whose criteria it meets. Each piece projects a
**zone of domain influence**. These zones affect shrines, and where zones overlap
they either **meld** (different types → a new type) or **burgeon** (same type →
greater strength).

**Altar** — every realm must have one; it can be moved. Unlike furniture, the Altar
is affected by the influence of **shrines**, which further shapes the outcome of
everything done here. Two actions:

- **Summon** — burn offerings to summon the avatar of a lesser entity. It wanders
  your garden for a set number of parades, then returns.
- **Fire** — load unfired tiles and fuel into the great grail to create new tiles.
  Summoned entities can **glaze** a tile, imparting both an effect and their own
  presence into it — consenting to a future summoning in exchange for a place in the
  pageantry.

**Shipyard Mooring** — where you build and customise your Spelljammer-style ship and
manage deck loadouts.

- **Parade** → transition animation of your ship leaving the realm for the expanse,
  then the Cosmic Parade scene.
- **Decks** → manage which loadouts are available to choose from on arrival.

### Cosmic Parade

Where bags of crafted tiles are played in pageants for crafting materials,
influence, and adherents.

Each parade ground has its own pattern of spaces. **Space shapes need not be equal in
size or shape within a ground** — a 4-player map might use a repeating
octagon-and-diamond combination, while a 2-player map uses plain repeating hexes.
Shapes should generally be regular and the layout pattern should repeat.

Whether grounds are plain hex or a mixed-polygon tiling is still undecided; see open
questions.

When the pageant ends, each player rolls dice — a number of dice determined by the
goals they achieved — for their rewards. Reward weighting comes from the arena, final
tile influence, and any effects granted by tiles.

## Pageant Rules

- A pageant is played by up to the maximum number of players the parade ground allows.
- Players take turns placing tiles, in **rounds**. A round is one turn per player and
  ends once every player has taken their turn.
- **Each turn:** draw tiles from your bag, choose one, place it in a valid position on
  the parade ground.
- Every tile states plainly what effect it has on the board and the **trigger state
  that flips it**.
- Tiles are two-faced. **After a tile flips twice** — back to its starting face — it
  is removed from the board and returned to its owner's bag, unless the tile says
  otherwise.
- **Player interaction happens through tiles, never through combat.** Entities do not
  fight each other. Choose a tile to advance your own goal, to create interactions
  with tiles on the board (including opponents'), or to disrupt an opponent's plan.
- The pageant ends once at least one player's **game end condition** triggers. End
  conditions are secret goals, drafted from a selection of options at the start of the
  pageant.

### Single player

A **blight** is spreading through the cosmic expanse, causing realms to decay. You
overcome its influence by playing tiles that cast spells and summon friendly
entities. Summoned entities act as **seeds**, affecting the landscape in
predetermined ways — you are building a mosaic.

The interest is in how lingering effects **fuse and influence each other** to create
new biomes and types, which in turn unlock new tile recipes. Tiles also flip when
their criteria are met.

### Multiplayer (2–4)

Realms are balanced to the intended player count. Each player holds a hidden
objective that triggers the game end.

The conflict is not combat — it is **competing for the appeal of a distant audience**
in a bid to win new adherents. Play is **not strictly zero-sum**: some tiles are
synergistic and a fusion can improve *both* players' scores. Scoring reflects this:

- Bonus score to the winning player.
- A separate award for the **percentage of a player's points that were earned through
  interaction with another player's tiles**.
- Total points represent **attention captured from different types of viewers**. The
  higher the table's total, the better everyone's rolls on crafting materials and loot
  tables.

So players are pushed to tangle their mosaics together even while racing secret goals.

## Systems

### Domain Influence

The central mechanic of *both* halves of the game: the area an object projects its
influence over.

In the realm, players should be **incentivised to rearrange** the furniture they have
collected. Influence creates a biome; fused with other influence, the domain
**generates terrain** from the overlap. For example, a mountain domain + a river
valley domain + an air domain might generate a **waterfall** in that area.

The goal is a cosmically-influenced garden where terrain is *grown* and customisable,
so that players want to decorate their realm and hang out in it. Because the realm is
3D, generated terrain has real height — it grows up out of the hex board rather than
recolouring it.

### Cosmic Fruits and Seeds

Feeding and offering fruit to entities is how you attract them into your realm
through shrines.

- Fruit-bearing flora **grows from seeds**, provided the realm currently has the
  domain influences that plant requires.
- More advanced entities are attracted by **combinations** of fruit — a fruit salad.
  **Cooking** may be the system that turns ingredients into the specific food an
  entity prefers.
- **Flowers** grow too, as a material for **dyeing the earth used in tile firing**.
  Dye either grants a tile an intrinsic effect or fuses with glaze to determine which
  domain the tile represents.

### Clay and Tile Firing

Tiles are fired from materials gathered in your realm and won as pageant rewards.
**Different clays represent different domains and carry their effects**, and clays can
be combined for combined effects.

### Entities and Bonds

You can see your entity friends roaming the garden and interact with them. **Divine
gifts** grow their power and your bond with them, unlocking new abilities and
attracting new entity friends who see the effort and want to contribute to your
growing cosmic influence.

## First-Pass Scope

Called out explicitly in the design: **only one arena / parade ground is needed for
the first pass.**

## Settled Decisions

Decided; the document above reflects them. These are ADR candidates.

- **3D.** The pixel-mosaic art style sits on 3D geometry. The hex board has real
  dimension and terrain grows up out of it, so board spaces and tiles are volumes —
  `Node3D`/`Area3D` territory, and the repo's 3D skill set and
  `[layer_names] 3d_physics/*` conventions apply as written.
- **Tiles are the only playable object.** There is no separate card class. Tiles
  *occupy the role* cards play in the deckbuilding genre — drafted, drawn, acquired,
  combined — but everything is a tile. The four starting items are tiles. "Card" is
  retired as a noun in this project, and "deck" survives only as the name for a
  loadout drawn from a bag.
- **"Influence" means domain projection, not currency.** The area a furniture piece,
  shrine, or tile projects over is *domain influence*, and keeps the name.
- **The currency is Adherents** — the audience a pageant wins you. It is what Swell
  costs.
- **Meld and Burgeon are the two overlap mechanics.** Different domain influences
  overlapping **meld** into a new type; the same domain influence overlapping itself
  **burgeons**, intensifying. These are the project's words for the pair.
- **Swell** remains the name for spending adherents to enlarge the realm.
- **Scoring is continuous and visible, with no printed tile values.** A tile has no
  intrinsic number; points come from what its *placement* achieves. The running score
  per player is shown and ticks up as tiles land, so players always have feedback on
  how a strategy is going. What stays secret is the drafted **objective**, not the
  score.
- **Viewer demands are domain-agnostic.** Each pageant's audience wants *structures* —
  a meld of any two domains, a chain of four, a burgeon stack of three, a flip
  triggered off a rival's tile — never a named domain. This is deliberate: a player's
  bag can never be locked out of scoring, which matters most early, when they hold
  only their avatar's starting domain. Domain-specific demands may layer on later as a
  bonus, once collections are wide enough to support them.
- **Fusion looks are authored, not computed.** Each domain combination gets a
  hand-picked colour and animated glaze pattern from a lookup table — never an
  arithmetic colour blend. Arithmetic mixing muddies precisely where the game needs
  clarity (a three-way overlap averages to brown), and flat bounded colour is what the
  mosaic art style is made of. The table is `.tres`-shaped, matching the project's
  data-in-Resources convention.
- **A glaze's effect comes from a bond-gated ability list per entity.** Each entity
  owns a tiered list of glazes; giving gifts raises bond and unlocks the higher tiers,
  and the player chooses which unlocked glaze to apply when firing. This follows the
  design's own line that gifts "grow their power and your bond, unlocking new
  abilities" — plural and bond-tied — and it keeps entities characterful individuals
  rather than interchangeable reagents, which the pet-raising pillar needs. The cost
  is content: an ability list per entity.
- **Tiles are assembled from slots, not from a recipe list.** A tile *is* its
  components: **clay** sets the domain, **dye** sets the effect, an optional **glaze**
  adds the bonded entity's ability and presence, and **fuel** sets quality. There is
  no authored recipe table, a tile's parts are readable as its rules, and this is what
  the design means by dye "fusing with glaze to determine what domain the tile
  represents". Progression unlocks **new clays and dyes**, not recipes — so the word
  *recipe* should be retired from the design, since nothing looks one up. Discovery
  lives in the realm, where growing new biomes yields new materials; the kiln is where
  plans are executed, not where surprises happen.
- **Furniture: pageants teach, the realm builds.** Pageant rewards drop *designs* for
  new furniture; the pieces themselves are built from realm materials — wood from the
  fruit trees you grow, clay, dye. Once a design is known it can be built again
  freely. This keeps the cozy half self-sufficient, since furniture is what projects
  domain influence and gating it behind wins would stall the whole realm, while
  parading still governs how much *variety* you have access to. It also closes the
  orchard loop: the trees grown for offerings supply the wood for the furniture that
  grows the trees. A name for "design" is still open — *cartoon* is the real
  mosaicist's term for a preparatory drawing and fits the craft, though *pattern* is
  the safer read.
- **Biomes are areas; features are events on edges.** Where domain influences overlap,
  the **interior** of the overlap becomes fused biome ground — walkable, planted,
  the new terrain type. Distinct **features** — a waterfall, an arch, a geyser — spawn
  only where a *boundary* meets that feature's conditions, which for a waterfall
  includes a height drop. This separates area from event the way real terrain reads,
  gives the waterfall its edge and its fall, and keeps blocking geometry out of zone
  interiors so a decorated garden stays walkable. Per-feature spawn conditions are
  authoring work still to be done.
- **The parade is the only unit of time.** Offerings last a number of parades, entity
  visits last a number of parades, plants grow over parades. **Nothing advances while
  the player is in their realm** — decorating, rearranging, replanting and watching
  your friends are all free, and the clock ticks only when you choose to sail out.
  This protects the activity the game is built to encourage: a realm you want to hang
  around in cannot also punish you for hanging around. *Day* is retired as a unit.
  Note that this removes idle **decay**, not idle **motion** — the shifting skybox and
  roaming entities animate continuously as cosmetic life, decoupled from the clock.
- **The blight is a spreading board condition, not an opponent.** A solo parade ground
  starts blighted and the rot creeps outward each round by a fixed rule; your tiles
  cleanse and claim it back. **No AI opponent is written** — which matters, because an
  AI that plays a spatial mosaic deckbuilder competently with hidden objectives is one
  of the hardest things this design could ask for, and a bad one would feel worse than
  none. Difficulty tunes through the spread rate. Failing a cleansing means
  withdrawing with a weak reward, not a game over; the blight presses without
  punishing, which the cozy framing needs.
- **Shrine slots: a fixed count, freely placed, footprints must not collide.** You own
  a number of slots — two at the start, more from Swell — and may put each anywhere on
  the realm. Only the shrine tiles themselves may not collide; their **projected
  influence overlaps freely**, and overlapping shrine influence is a tool rather than a
  violation. "Fixed" describes the count, not the positions.
- **Avatar and starting domain are separate choices.** The avatar is **purely
  visual** — a look and a skybox palette, picked because you like the art, with no
  mechanical weight whatsoever. The starting **kit** is a separate pick from a small
  set and carries the typed furniture, designs, fruit and seeds. This makes "mostly
  cosmetic" literally true instead of nearly true, and it dissolves the Bogle problem:
  a shapeshifter fox needs no special rule once avatars carry no rules.
- **Six domains: Forest, Grassland, Wetland, Stone, Flame, Gale** (working names).
  The original twelve collapsed — Forest absorbed Boreal Forest, Grassland absorbed
  Steppe and Scrubland, Wetland absorbed Bog, Tidepools and Deep Ocean. Six is driven
  by the authored-fusion decision: six domains make **every** possible overlap
  authorable, from 15 pairs through 20 triples to a single six-way, 57 combinations in
  all, against 286 for twelve domains counting only pairs and triples. It also matches
  the hex's six sides. All twelve avatars survive as art.
- **A starting kit seeds the opening hours; it is not a class.** Players steer their
  bags, furniture and friendships wherever they want. Nothing is locked to the domain
  you began with.

## Open Design Questions

Unresolved. Do not implement against these — they need decisions first.

**Parade ground geometry — hex, or a mixed-polygon tiling?** *Decision: prototype both
before committing.* Build two static 3D boards — geometry and a camera, no rules, no
tiles, no scoring — and compare whether the pattern reads at a glance, whether grown
terrain occludes neighbours, and whether the small interstitial shapes feel like
*places* or like *gaps*.

The trade-off being tested is player legibility. Plain repeating hexes are instantly
readable, share one grid system with the realm, and only need terrain generation
written once. A repeating pattern of different regular convex polygons gives **small
shapes at regular intervals that can denote fusing of domain influences** — a
dedicated physical home for interaction, which takes load off *communicating domain
influence* below, since fusion would not have to be communicated by tinting the main
spaces. It costs a second grid system: two sets of neighbour math, two
placement-validity systems, terrain generation twice.

**Viewer demand tuning.** The shape of scoring is settled, the numbers are not. How
many demands are active per pageant? Are they revealed on landing, before deck
selection? Are they shared by the table or one per player? Do they refresh mid-match?
Does satisfying a demand consume it, or does it keep paying?

**Communicating domain influence.** How is it shown on parade tiles and in the realm?
The sketch: colours, with fused domains mixing into new colours, plus swirling effects
— moving glaze emulating space dust or the domain's attributes. In 3D this question
also covers how influence reads on terrain that has height and may occlude itself.

**Glaze economy.** The ability list is settled; its supply is not. How many tiles can
an entity glaze per summoned visit? Does glazing spend the visit, or can one entity
glaze several tiles before returning? Can a single tile carry two glazes? How long is
the bond ladder, and how many glazes sit on it? These decide whether a glazed tile is
commonplace or precious, and the whole firing economy keys off that.

**The second face.** Slot assembly produces one set of tile properties, but every
tile is two-faced with a flip trigger, and the pageant rules lean on it — a tile that
flips twice returns to its owner's bag. Nothing yet says what is on the reverse or
which component decides the trigger. Candidates: the dye carries both faces as a
paired effect; the clay sets the trigger condition while the dye sets both effects;
or the reverse face is derived from the front by a fixed rule (inverted, spent,
exhausted). This needs answering before a tile can be built at all.

**What generates elevation?** Features now require height — a waterfall must have a
drop to fall down — but the realm is a flat hex board and no system raises or lowers
ground. Height-driven generation was considered and rejected as too unpredictable to
decorate on, so elevation needs another source. The strongest candidate is **burgeon**:
if stacking the same domain raises terrain, burgeon gains a physical meaning and
intensity becomes visible, without surrendering player control the way fully emergent
height would. Alternatives: elevation is a property of specific furniture; or the
floating rock ships with authored relief that the player works around.

**"Avatar" is overloaded.** It now formally means the player's cosmetic look, but the
Summon action also describes burning offerings to call "the **avatar** of a lesser
entity" — its manifested form. Two different things in one word, in a project where
both appear in the same save file. One of them needs a different name; *vessel*,
*aspect*, *effigy* or *shade* all fit the entity side.

**What ends a solo pageant?** Multiplayer ends when a drafted secret objective
triggers. Solo has no equivalent: options are a cleansing threshold (restore X% of the
board), a round limit, an objective draft of its own, or the blight being fully pushed
off the board. Related: does the blight spread purely deterministically, or react to
where the player has been strongest? And is there a campaign structure across
successive polluted realms, or are solo pageants standalone?

### Parked

Deferred, not blocking. Recorded so the reasoning is not lost.

**The four starting tiles** — *Meld, Evolve, Extend, Burgeon*, where the Meld tile was
meant to **force a meld to happen**. Named for the overlap mechanics they trigger, so
the set is a coherent pattern rather than a collision, but whether it is *interesting*
is unsettled and Evolve and Extend name no mechanic in this document yet.

The question underneath it is **where meld and burgeon fire**. In the realm they
happen automatically from how you arrange furniture — that is the whole arrangement
puzzle, and nothing needs forcing. A tile that forces a meld only earns its slot if
melding also happens **on the parade ground**, where you do not control adjacency and
an opponent may have placed the neighbour you need. Scoring settles part of this:
viewer demands reward melds and burgeon stacks on the parade ground, so overlap
mechanics **do** fire there, and a tile that forces one has something to do.

Glazing then largely settles the rest. Bond-gated glazes can include effects like
*meld without adjacency* — forcing a meld becomes something a player **earns by
bonding with an entity**, which is a better home for it than a tile everyone starts
with. That points at retiring the Meld starting tile rather than defining it.

## Related Docs

- `CLAUDE.md` — repo conventions and tooling. Its *Project Overview*, *Architecture*,
  and *3D Physics Layers* sections are still TODO and should be filled from this
  document.
- `CONTRIBUTING.md` — branching, PR, and commit conventions.
- `documentation/adr/` — architecture decision records. Every entry under *Settled
  Decisions* that was hard to reverse, surprising without context, and the result of a
  real trade-off has one; the pure naming decisions do not, since renaming is
  mechanical. Open questions should graduate into ADRs as they are decided.

  | ADR | Decision |
  |---|---|
  | 0001 | 3D geometry with a pixel-mosaic art style |
  | 0002 | Tiles are the only playable object |
  | 0003 | Scoring is positional, continuous, and demand-driven |
  | 0004 | Fusion looks are authored, not computed |
  | 0005 | Six domains |
  | 0006 | Tiles are assembled from slots, not from recipes |
  | 0007 | Glazes come from bond-gated per-entity ability lists |
  | 0008 | Biomes fill interiors; features spawn on boundaries |
  | 0009 | The parade is the only unit of time |
  | 0010 | The blight is a board condition, not an AI opponent |
  | 0011 | Furniture: pageants teach, the realm builds |
  | 0012 | Avatar and starting kit are separate choices |
- `documentation/plans/` — implementation plans for features in progress.
- `notes/` — working material. Not authoritative.
