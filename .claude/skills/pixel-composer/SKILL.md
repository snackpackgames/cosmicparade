---
name: pixel-composer
description: Answer questions about Pixel Composer (pixel-composer.com), a node-based VFX compositor for pixel art. Use whenever the user asks about PXC nodes, panels, particle systems, 3D rendering, shaders, Lua scripting, GameMaker/Aseprite/Krita I/O, or any feature in docs.pixel-composer.com. Trigger on: "pixel composer", "PXC", mentions of specific node names (e.g. "the noise node"), or questions about how to build a VFX graph.
---

# Pixel Composer Assistant

Pixel Composer (PXC) is a node-based VFX compositor for pixel art by MakhamDev. Users build effects by connecting 300+ nodes in a visual programming graph: patterns, fluid sims, particles, 3D, shaders, animation curves, exports to sprite sheets / GameMaker / Aseprite.

## How to answer PXC questions

1. **Fetch fresh — don't answer from memory.** PXC ships new nodes often; training data rots. Always WebFetch the relevant doc page before answering.
2. **Cite the URL** you pulled from so the user can verify and dig deeper.
3. **Prefer the specific node page over the category index.** URLs are predictable: `https://docs.pixel-composer.com/nodes/<category>/<node_name>.html`. If you don't know the exact node name, fetch the category index first.
4. **For conceptual questions** (workflow, "what's the best way to…"), supplement docs with the forum or YouTube — the reference describes *what* nodes do, not always *why* or *when*.
5. **Batch WebFetches** in parallel when multiple pages are relevant.

## Documentation map

**Root:** https://docs.pixel-composer.com

### Top-level
- **Getting Started:** https://docs.pixel-composer.com/getting_started.html
- **Interfaces:** https://docs.pixel-composer.com/interfaces/index.html
  - Panels: Animation, Collection, Color Selector, Graph, Inspector, Nodes, Preview (2D), Preview 3D, Tunnels
- **Nodes index:** https://docs.pixel-composer.com/nodes/index.html

### Node categories (all under `/nodes/<category>/`)
| Category | Covers |
|---|---|
| **IO** | Image import/export, Aseprite, Krita, Ora, Pxc, GameMaker, Tileset, Canvas, File, External, Device, Network |
| **Transform** | Crop, warp, scale, align, flip, mirror, offset, background |
| **Filter** | Blur, color adjust, effects, warping, convolution, analysis |
| **3D** | Scenes, materials, meshes, lights, ray marching, point ops |
| **Generate** | Color, drawer, noise, pattern, population, simulation, region, UV, effects |
| **Compose** | Armature, blending, compositing, sprite packing |
| **Values** | Structs, mesh, atlas, buffers, numbers, vectors, matrices, text, arrays, paths, boolean |
| **Animation** | Curves, audio, loops, delays, rate remapping |
| **Particle** | 2D/3D particle systems, VFX, affectors |
| **Utility** | Control flow, groups, Lua, shaders, caching, debug, project, system |

### Specialized workflow pages
- **Pixel Builder:** https://docs.pixel-composer.com/nodes/pixel_builder/index.html
- **Mk Tree:** https://docs.pixel-composer.com/nodes/mk_tree/index.html
- **Iteration:** https://docs.pixel-composer.com/nodes/iteration/index.html
- **Particle Systems:** https://docs.pixel-composer.com/nodes/particle/index.html
- **Pcx programming:** https://docs.pixel-composer.com/nodes/pcx/index.html

## Community resources

- **Forum:** https://forum.pixel-composer.com/
- **Discord:** https://discord.gg/aHGbYjQh63
- **YouTube (MakhamDev):** https://www.youtube.com/@makhamdev
- **GitHub (source, issues):** https://github.com/Ttanasart-pt/Pixel-Composer
- **Patreon:** https://www.patreon.com/MakhamDev

## Answering workflow

1. Parse the user's question — identify node name, category, or concept.
2. Pick the most specific URL from the map. If unknown, fetch the category index.
3. WebFetch the page(s). Batch in parallel if multiple.
4. Answer concisely, cite the URL(s).
5. If docs are thin on the topic, point to the forum or a YouTube search as a follow-up.

## Notes on the app itself

- Developer: MakhamDev (Ttanasart-pt on GitHub), first released 2023.
- Targets pixel artists doing VFX — explosions, auras, particles, animated sprites, tilesets.
- Outputs can feed directly into **GameMaker** projects (dedicated IO nodes) and standard image formats.
- Supports **Lua scripting**, custom **shaders**, and **feedback loops** for simulations.
