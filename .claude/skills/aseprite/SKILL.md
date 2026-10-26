---
name: aseprite
description: Answer questions about Aseprite (aseprite.org), the animated sprite editor and pixel art tool. Use whenever the user asks about Aseprite workflow, tools, layers, animation, tilemaps, slices, palette, sprite-sheet export, CLI, keyboard shortcuts, or Lua scripting / API. Trigger on "aseprite" (and common misspellings like "aesprite", "asesprite"), mentions of .aseprite/.ase files, or sprite-animation workflow questions in a pixel-art context.
---

# Aseprite Assistant

Aseprite is the de facto pixel-art / sprite-animation editor. Supports frame-based animation, layers, tilemaps, slices, palettes, sprite-sheet export, CLI, Lua scripting, and extensions.

## How to answer Aseprite questions

1. **Fetch fresh — don't answer from memory.** Aseprite ships updates; the Lua API in particular grows. Always WebFetch the relevant page before answering.
2. **Cite the URL** so the user can verify and dig deeper.
3. **For scripting questions**, start at the API page for the relevant class/namespace (`https://www.aseprite.org/api/<name>`).
4. **For workflow questions**, start with the specific docs section (`https://www.aseprite.org/docs/<topic>/`) and supplement with the tutorial or community forum.
5. **Batch WebFetches** in parallel when multiple pages are relevant.

## Documentation map

**Root:** https://www.aseprite.org/docs/

### Core sections (all under `/docs/`)
| Topic | URL |
|---|---|
| Basics | https://www.aseprite.org/docs/basics/ |
| Workspace | https://www.aseprite.org/docs/workspace/ |
| Sprite | https://www.aseprite.org/docs/sprite/ |
| Color | https://www.aseprite.org/docs/color/ |
| Drawing | https://www.aseprite.org/docs/drawing/ |
| Selecting | https://www.aseprite.org/docs/selecting/ |
| Transformations | https://www.aseprite.org/docs/transformations/ |
| Layers | https://www.aseprite.org/docs/layers/ |
| Animation | https://www.aseprite.org/docs/animation/ |
| Tilemap | https://www.aseprite.org/docs/tilemap/ |
| Slices | https://www.aseprite.org/docs/slices/ |
| Files | https://www.aseprite.org/docs/files/ |
| Save | https://www.aseprite.org/docs/save/ |
| Exporting | https://www.aseprite.org/docs/exporting/ |
| Sprite-sheet | https://www.aseprite.org/docs/sprite-sheet/ |
| CLI | https://www.aseprite.org/docs/cli/ |
| Customization | https://www.aseprite.org/docs/customization/ |
| Preferences | https://www.aseprite.org/docs/preferences/ |
| Keyboard shortcuts | https://www.aseprite.org/docs/keyboard-shortcuts/ |
| Workspace layout | https://www.aseprite.org/docs/workspace-layout/ |
| Extensions | https://www.aseprite.org/docs/extensions/ |
| Scripting | https://www.aseprite.org/docs/scripting/ |

### Quick links
- **Quick Reference (shortcuts):** https://www.aseprite.org/quickref/
- **FAQ:** https://www.aseprite.org/faq/
- **Tutorial (getting started):** https://www.aseprite.org/tutorial/
- **Blog:** https://blog.aseprite.org/
- **Roadmap:** https://www.aseprite.org/roadmap/

## Lua API map

**Root:** https://www.aseprite.org/api/ (Aseprite v1.2.10+, Lua 5.3)

### Global namespaces
- `app` — https://www.aseprite.org/api/app (primary entry point; active sprite, tools, events)
- `app.clipboard` — https://www.aseprite.org/api/app_clipboard
- `app.command` — https://www.aseprite.org/api/app_command (trigger UI commands)
- `app.fs` — https://www.aseprite.org/api/app_fs (filesystem)
- `app.os` — https://www.aseprite.org/api/app_os
- `app.theme` — https://www.aseprite.org/api/app_theme
- `pixelColor` — https://www.aseprite.org/api/pixelcolor
- `json` — https://www.aseprite.org/api/json

### Key object types (40+ total — fetch the specific class page for method lists)
Sprite, Image, Layer, Cel, Frame, Tag, Slice, Palette, Color, Rectangle, Point, Size, Selection, Tileset, Tile, Brush, Tool, Dialog, Editor, Timer, WebSocket, Plugin — plus constants like `Align`, `BlendMode`, `ColorMode`, `FlipType`, `Ink`, `SelectionMode`.

### Common starting points for scripts
1. Mutate active sprite: `app.sprite`
2. Create new: `Sprite(w, h, colorMode)`
3. Open file: `app.open(filename)`
4. Save: `Sprite:saveCopyAs(filename)`
5. Show UI: `Dialog{ title = "..." }`
6. Package as plugin: `plugin.preferences`, event hooks

Lua 5.3 stdlib is available (`string`, `table`, `math`) with some OS restrictions requiring user permission prompts.

## Community resources

- **Community forum:** https://community.aseprite.org/
- **Discord:** https://discord.gg/Yb2CeX8
- **Reddit:** https://www.reddit.com/r/aseprite/
- **Steam Community:** https://steamcommunity.com/app/431730
- **YouTube:** https://www.youtube.com/user/aseprite
- **GitHub (source, issues):** https://github.com/aseprite/aseprite/
- **Dev blog:** https://dev.aseprite.org/

## Answering workflow

1. Parse the question — is it workflow (docs/) or scripting (api/)?
2. Pick the specific URL from the map. If unknown, fetch the relevant index.
3. WebFetch. Batch in parallel if multiple pages apply.
4. Answer concisely with a URL citation.
5. For tricky questions, point to the forum or Discord as follow-up.

## Project context

Cosmic Parade is a **3D** Godot 4.6 project, so Aseprite output here is usually a
*texture*, not a sprite sheet: albedo/emission maps for `StandardMaterial3D`, UI
and HUD art, decals, billboarded effects, and flipbook strips driven by a shader.

Aseprite files (`.aseprite`, `.ase`) feed Godot via:
- Aseprite CLI for batch export (`aseprite -b input.aseprite --sheet out.png --data out.json`)
- Direct import (community importers) — output `.png` + `.json` sprite sheets
- PXC (Pixel Composer) has Aseprite IO nodes for round-tripping

For pixel-art textures on 3D meshes, the import settings matter more than the
export: in the `.import` sidecar, turn **filter off** (nearest-neighbour) and
decide mipmaps deliberately — mipmapping is what smears pixel art at distance,
but turning it off trades that for shimmer. Say which trade-off applies rather
than recommending one blindly. `SpriteFrames` and the 2D tilemap importers are
**not** the target in this project; a flipbook animation on a 3D surface is a
sheet plus UV offset in a shader.
