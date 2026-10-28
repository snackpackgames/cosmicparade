# Godot 4.6 rendering and import defaults for a pixel-mosaic 3D look

Research asset for [Research: Godot 4.6 renderers and import defaults for a
pixel-mosaic 3D look](https://github.com/snackpackgames/cosmicparade/issues/4), a
ticket on [Map: bootstrap the Godot
project](https://github.com/snackpackgames/cosmicparade/issues/2).

**This note gathers facts; it does not pick anything.** The choice belongs to [Pick the
renderer and project-wide rendering
defaults](https://github.com/snackpackgames/cosmicparade/issues/5).

Compiled 2026-10-28 against the **4.6** docs (`docs.godotengine.org/en/4.6/`), which is
what CI pins via `chickensoft-games/setup-godot@v2`. Note that `/en/stable/` now serves
**4.7**, so a stray stable link can report features 4.6 does not have — one of the
findings below is exactly that.

## 1. The three rendering methods

`rendering/renderer/rendering_method` defaults to `"forward_plus"`, with
`rendering_method.mobile` (`"mobile"`) and `rendering_method.web`
(`"gl_compatibility"`) as per-platform overrides.

| Feature | Compatibility | Mobile | Forward+ |
|---|---|---|---|
| Volumetric fog | no | no | **yes** |
| SDFGI / VoxelGI | no | no | **yes** |
| Screen-space reflections, SSIL | no | no | **yes** |
| SSAO | yes | no | yes |
| Decals | no | yes | yes |
| MSAA 3D | yes | yes | yes |
| MSAA 2D | no | yes | yes |
| FXAA / SMAA | no | yes | yes |
| TAA | no | no | **yes** |
| FSR2 | no | no | **yes** |
| Subsurface scattering | no | no | yes |
| Directional light PCSS | no | no | yes |
| Reflection probes per mesh | 2 | 8 | unlimited |
| Compute shaders | no | yes (penalty on old devices) | yes |

Cost shape, per the docs: Forward+ has the **highest base cost but low scaling cost**
and is slowest on old/low-end hardware; Mobile is medium/medium; Compatibility has
**low base cost but high scaling cost**. The docs' own "choose Forward+ if" list is
desktop target, 3D game, hardware with Vulkan/D3D12/Metal, and wanting the advanced
features.

**Bearing on this project.** The art direction wants a shifting skybox of cosmic dust
and plasma, neon, and terrain that grows up out of a board. Volumetric fog, SSR, SSIL
and SDFGI are Forward+ only, and so are TAA and FSR2. Against that, nothing in ADR 0001
needs global illumination, and a mosaic look is flat-shaded by nature — so the
Forward+ feature list is mostly about the *skybox and neon glow*, not about the tiles.
Compatibility additionally caps reflection probes at 2 per mesh and has no decals,
which matters if domain influence ever reads as a projected decal on the ground.

## 2. Texture filtering in 3D — the main finding

**There is no project-wide 3D texture filter setting in Godot 4.6.**

- Image import exposes **no filter option at all**. Import options cover compression,
  mipmaps, normal maps and channel packing.
- In **2D**, filtering is a CanvasItem property, defaulted project-wide by
  `rendering/textures/canvas_textures/default_texture_filter` (int, default `1` =
  linear). This setting is **2D only**.
- In **3D**, filtering is per material: `BaseMaterial3D.texture_filter`, default `3` =
  `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`. Custom shaders set it with hints on the
  `sampler2D` uniform.
- `Viewport` has no 3D default-filter property either; its only such property is
  `canvas_item_default_texture_filter`.

`BaseMaterial3D.TextureFilter` values:

| Constant | Value | Behaviour |
|---|---|---|
| `TEXTURE_FILTER_NEAREST` | 0 | nearest texel, no mipmaps — pixelated close, **grainy at distance** |
| `TEXTURE_FILTER_LINEAR` | 1 | 4-texel blend, no mipmaps — smooth close, grainy at distance |
| `TEXTURE_FILTER_NEAREST_WITH_MIPMAPS` | 2 | nearest texel, blends 2 mipmaps — **pixelated close, smooth at distance** |
| `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS` | 3 | the default — smooth everywhere |
| `TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC` | 4 | as 2, plus angle-dependent mipmap selection |
| `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC` | 5 | as 3, plus the same |

So the mosaic-preserving value is **2** (`NEAREST_WITH_MIPMAPS`), or **4** if surfaces
viewed at a grazing angle — a board seen from a low camera — need the extra quality.
Plain `NEAREST` (0) is the wrong choice for a board that recedes from the camera: with
no mipmaps it goes grainy at distance, which on a tessera grid means shimmer.

**Consequence for the scaffold:** "project-wide nearest filtering in 3D" is not a
setting that can be flipped. It has to be carried by convention or by construction —
a shared base material resource, a shared shader, an `@tool` check, or a documented
rule — and whichever it is, it is a scaffold-shaped decision, not a `project.godot`
line.

## 3. Mipmaps and anisotropy

- `rendering/textures/default_filters/use_nearest_mipmap_filter` (bool, default
  `false`): when true, the `_WITH_MIPMAPS` modes pick the **nearest** mipmap instead of
  blending two. Read only at project start.
- `rendering/textures/default_filters/anisotropic_filtering_level` (int, default `2`):
  the level used by the two `_ANISOTROPIC` filter modes. Applies to 2D and 3D, but
  **only when a material actually selects an anisotropic mode**. Read only at project
  start.
- `rendering/textures/default_filters/texture_mipmap_bias` (float, default `0.0`):
  shifts which mipmap level is sampled; negative is sharper and grainier, positive
  blurs. Also available per-viewport as `Viewport.texture_mipmap_bias`. The import docs
  recommend a negative bias for sharpness in high-resolution 2D; they do not discuss
  the 3D case.
- Import-side: the docs recommend **enabling mipmaps for 3D** generally, and give no
  pixel-art-specific mipmap advice.

## 4. Low-resolution 3D viewport upscaled — not viable the obvious way in 4.6

This was the most promising route to a *consistent tessera size on screen*, and 4.6
cannot do it crisply through the built-in path.

`Viewport.Scaling3DMode` in **4.6** has exactly: `BILINEAR` (0, default), `FSR` (1),
`FSR2` (2), `METALFX_SPATIAL` (3), `METALFX_TEMPORAL` (4). **There is no
nearest-neighbour mode.** `rendering/scaling_3d/mode` defaults to `0` and
`rendering/scaling_3d/scale` to `1.0`; FSR of either generation requires Forward+ and
falls back to bilinear otherwise, and MetalFX temporal requires the Metal driver, so
macOS/iOS only.

A nearest-neighbour 3D scaling mode **does** appear in the `latest`/`stable` (4.7)
`RenderingServer` docs, described as crisper than bilinear at no extra cost with
recommended scales like 0.5 or 0.25. On 4.6 it is simply absent, so:

- Scaling below 1.0 on 4.6 means a **bilinear** upscale — blur, which is the one thing
  a tessera grid cannot survive.
- The 4.6-compatible way to get a crisp low-res 3D image is the manual one: render the
  3D world into a `SubViewport` and display it through a CanvasItem (`TextureRect` /
  `Sprite2D`) whose texture filter is nearest — at which point
  `rendering/textures/canvas_textures/default_texture_filter` *does* apply, because the
  display node is 2D.
- Resolution scaling is 3D-only either way: it never affects 2D or UI, and the docs
  point at the viewport stretch mode for the 2D equivalent.

Both routes have consequences well beyond `project.godot` — a SubViewport pipeline
changes how UI composites, how mouse picking maps into the 3D world, and what the
camera does on window resize.

## 5. Antialiasing

| Technique | Renderers | Cost | Effect on hard edges |
|---|---|---|---|
| MSAA 3D (2×/4×/8×) | all | medium | smooths **geometry** edges, **adds no blur** |
| SMAA 1x | Forward+, Mobile | low | blurs less than FXAA; helps most at ≤1080p |
| FXAA | Forward+, Mobile | very low | moderate blur |
| TAA | Forward+ only | medium | blur, worse in motion, ghosting |
| FSR2 at scale 1.0 | Forward+ only | high | temporal AA, less blur than TAA |
| SSAA (`scale` > 1.0) | all | very high | no ghosting; integer scale 2.0 minimises downscale blur |

The docs recommend MSAA for a cartoon art style with few reflective surfaces and for
projects where blur and temporal artefacts must be avoided, and note TAA, FSR2 and FXAA
all add blur. For a mosaic look that means **MSAA 3D is the only antialiasing that
fits**: it cleans the silhouettes of 3D tiles and terrain without touching texel
detail. Recommended levels are 2× or 4×; 8× is called usually too demanding.

Keys: `rendering/anti_aliasing/quality/msaa_3d` (int, `0`),
`msaa_2d` (int, `0`, Forward+/Mobile only — the docs warn against changing this one by
mistake), `screen_space_aa` (int, `0`, Forward+/Mobile only, FXAA or SMAA),
`use_taa` (bool, `false`, Forward+ only), `use_debanding` (bool, `false`). All are read
**only at project start**; each has a runtime `Viewport` equivalent.

## 6. Import settings for pixel-mosaic textures

- **Compression: Lossless.** The docs call this "the recommended setting for pixel art"
  and state explicitly that **even in 3D, pixel art textures should have VRAM
  compression disabled**. This is the single most important import fact here — VRAM
  compression is block-based and destroys hard tessera edges.
- **Fix Alpha Border** is on by default and should stay on unless it causes trouble; it
  exists to stop outline artefacts under bilinear filtering. **Premult Alpha** is the
  alternative and requires a matching premultiplied blend mode on the material.
- **Mipmaps**: recommended on for 3D; no pixel-art-specific guidance.
- **Import Defaults** (Project Settings → Import Defaults, or the Import dock's
  `Preset…` menu) sets per-importer defaults project-wide, so "lossless, mipmaps on"
  can be the default for every image without touching each asset. The docs do **not**
  say whether changing a default reimports already-imported assets; they only say an
  asset's chosen parameters apply to it and to future reimports, and that Godot
  reimports automatically when a source file's MD5 changes.
- `.import` sidecars hold each asset's configuration and the docs say to **commit them**
  — which `CLAUDE.md → Common Gotchas` already requires.

## 7. Exact keys and defaults, as verified

| Key | Type | Default | Scope / notes |
|---|---|---|---|
| `rendering/renderer/rendering_method` | String | `"forward_plus"` | `.mobile` → `"mobile"`, `.web` → `"gl_compatibility"` |
| `rendering/textures/canvas_textures/default_texture_filter` | int | `1` (linear) | **2D only** |
| `rendering/textures/default_filters/use_nearest_mipmap_filter` | bool | `false` | start-only |
| `rendering/textures/default_filters/anisotropic_filtering_level` | int | `2` | 2D+3D, anisotropic modes only; start-only |
| `rendering/textures/default_filters/texture_mipmap_bias` | float | `0.0` | negative = sharper |
| `rendering/anti_aliasing/quality/msaa_3d` | int | `0` | start-only |
| `rendering/anti_aliasing/quality/msaa_2d` | int | `0` | Forward+/Mobile only; start-only |
| `rendering/anti_aliasing/quality/screen_space_aa` | int | `0` | Forward+/Mobile only; start-only |
| `rendering/anti_aliasing/quality/use_taa` | bool | `false` | Forward+ only; start-only |
| `rendering/anti_aliasing/quality/use_debanding` | bool | `false` | start-only |
| `rendering/scaling_3d/mode` | int | `0` (bilinear) | 3D only; FSR needs Forward+ |
| `rendering/scaling_3d/scale` | float | `1.0` | 3D only; `> 1.0` is bilinear-only |
| `rendering/scaling_3d/fsr_sharpness` | float | `0.2` | FSR only; `0.0` sharpest, max `2.0` |
| `rendering/environment/defaults/default_environment` | String | `""` | fallback env, loaded at scene load |

`BaseMaterial3D.texture_filter` default: `3` (`LINEAR_WITH_MIPMAPS`). There is no
project setting that changes it.

## 8. What the decision ticket still has to settle

Gathered, not decided:

1. **Renderer.** Forward+ buys volumetric fog, SSR/SSIL and GI for the cosmic skybox
   and the neon; Mobile is lighter and keeps decals and MSAA; Compatibility is the
   widest reach and loses decals and most of the atmosphere.
2. **How nearest filtering is actually enforced in 3D**, given no setting exists —
   shared base material, shared shader, convention, or a test.
3. **Whether tessera size is pinned on screen at all**, and if so whether that is worth
   a SubViewport pipeline on 4.6 or is deferred until the engine pin moves to 4.7,
   where a nearest 3D scaling mode exists.
4. **MSAA level**, and confirmation that no screen-space AA is wanted.
5. **Which import defaults the scaffold writes** — lossless compression and mipmaps at
   minimum — and whether Import Defaults is trusted or each asset carries its own
   `.import`.

## Sources

- [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
  (served as 4.7; feature table cross-checked against 4.6 class refs)
- [Importing images (4.6)](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/importing_images.html)
- [Import process (4.6)](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/import_process.html)
- [BaseMaterial3D (4.6)](https://docs.godotengine.org/en/4.6/classes/class_basematerial3d.html)
- [Viewport (4.6)](https://docs.godotengine.org/en/4.6/classes/class_viewport.html)
- [ProjectSettings (4.6)](https://docs.godotengine.org/en/4.6/classes/class_projectsettings.html)
- [Resolution scaling (4.6)](https://docs.godotengine.org/en/4.6/tutorials/3d/resolution_scaling.html)
- [3D antialiasing (4.6)](https://docs.godotengine.org/en/4.6/tutorials/3d/3d_antialiasing.html)
- [RenderingServer (latest)](https://docs.godotengine.org/en/latest/classes/class_renderingserver.html)
  — source for the 4.7-only nearest 3D scaling mode
