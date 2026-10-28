# Godot rendering and import defaults for a pixel-mosaic 3D look

Research asset for [Research: Godot 4.6 renderers and import defaults for a
pixel-mosaic 3D look](https://github.com/snackpackgames/cosmicparade/issues/4), a
ticket on [Map: bootstrap the Godot
project](https://github.com/snackpackgames/cosmicparade/issues/2).

**This note gathers facts; it does not pick a renderer.** That choice belongs to [Pick
the renderer and project-wide rendering
defaults](https://github.com/snackpackgames/cosmicparade/issues/5).

Compiled 2026-10-28. The engine pin is **`4.7.2-stable`**, settled in [Which Godot
version the project pins](https://github.com/snackpackgames/cosmicparade/issues/13) —
that decision came *out of* this research, because one answer here turned out to be
version-dependent. Facts below are verified against the **4.7** docs, with the 4.6
behaviour kept where the difference is the reason the pin moved.

A note on sourcing: `docs.godotengine.org/en/stable/` currently serves 4.7, so a link
that looks generic may be reporting the pinned version or not. Everything here uses an
explicit `/en/4.7/` or `/en/4.6/` path.

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

Note also that FSR of either generation requires Forward+ and silently falls back to
bilinear elsewhere — but see §4: FSR is not the scaling mode this project wants anyway.

## 2. Texture filtering in 3D — the main finding

**There is no project-wide 3D texture filter setting. This is true in both 4.6 and
4.7**, so the pin moving did not change it.

- Image import exposes **no filter option at all**. Import options cover compression,
  mipmaps, normal maps and channel packing.
- In **2D**, filtering is a CanvasItem property, defaulted project-wide by
  `rendering/textures/canvas_textures/default_texture_filter` (int, default `1` =
  linear). This setting is **2D only**.
- In **3D**, filtering is per material: `BaseMaterial3D.texture_filter`, default `3` =
  `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`. Custom shaders set it with hints on the
  `sampler2D` uniform.
- `Viewport` has no 3D default-filter property in either version; its only such
  property is `canvas_item_default_texture_filter`.

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

Keys and defaults are identical in 4.6 and 4.7.

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

## 4. Low-resolution 3D viewport upscaled — viable on 4.7, and the reason for the pin

This is the most promising route to a *consistent tessera size on screen*, and whether
it is cheap depends entirely on the engine version. It is why the pin moved.

**On 4.7 (pinned):** `Viewport.Scaling3DMode` is `BILINEAR` (0, default), `FSR` (1),
`FSR2` (2), `METALFX_SPATIAL` (3), `METALFX_TEMPORAL` (4), **`NEAREST` (5)**. The
nearest mode:

- uses nearest-neighbour filtering on the 3D buffer and **"looks crisper than"**
  bilinear
- has **no additional rendering cost**
- is driven by `scaling_3d_scale`; **values above 1.0 are unsupported** and fall back to
  bilinear downsampling, and 1.0 disables scaling
- wants **integer-divisor scales — 0.5, 0.3333, 0.25, 0.2** — to avoid uneven pixel
  scaling

So pinning tessera size on screen is two settings: `rendering/scaling_3d/mode` = 5 and
`rendering/scaling_3d/scale` = an integer divisor. 4.7 also exposes `mode.ios` and
`mode.macos` platform overrides.

**On 4.6 (not pinned, kept for the record):** the enum stops at `METALFX_TEMPORAL` (4)
— there is **no nearest mode**. Scaling below 1.0 therefore means a bilinear upscale,
i.e. blur, which is the one thing a tessera grid cannot survive. The only crisp route
on 4.6 was manual: render the 3D world into a `SubViewport` and display it through a
nearest-filtered CanvasItem (`TextureRect` / `Sprite2D`), which drags in UI compositing
and mouse-picking consequences well beyond `project.godot`. Avoiding that is what the
4.7 pin bought.

Either way, resolution scaling is **3D-only**: it never affects 2D or UI, and the docs
point at the viewport stretch mode for the 2D equivalent.

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
**only at project start**; each has a runtime `Viewport` equivalent. These five were
verified on the 4.6 reference; the rest of the table in §7 was re-verified on 4.7.

Note the interaction with §4: SSAA via `scale` > 1.0 is **not available in nearest
mode**, which rejects scales above 1.0 outright. Supersampling and crisp tesserae are
mutually exclusive choices here.

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

Verified on the **4.7** `ProjectSettings` reference except where noted; every key in
this table that was also checked on 4.6 had an identical type and default.

| Key | Type | Default | Scope / notes |
|---|---|---|---|
| `rendering/renderer/rendering_method` | String | `"forward_plus"` | `.mobile` → `"mobile"`, `.web` → `"gl_compatibility"` |
| `rendering/textures/canvas_textures/default_texture_filter` | int | `1` (linear) | **2D only** |
| `rendering/textures/default_filters/use_nearest_mipmap_filter` | bool | `false` | start-only |
| `rendering/textures/default_filters/anisotropic_filtering_level` | int | `2` | 2D+3D, anisotropic modes only; start-only |
| `rendering/textures/default_filters/texture_mipmap_bias` | float | `0.0` | negative = sharper |
| `rendering/anti_aliasing/quality/msaa_3d` | int | `0` | start-only *(4.6-verified)* |
| `rendering/anti_aliasing/quality/msaa_2d` | int | `0` | Forward+/Mobile only; start-only *(4.6-verified)* |
| `rendering/anti_aliasing/quality/screen_space_aa` | int | `0` | Forward+/Mobile only; start-only *(4.6-verified)* |
| `rendering/anti_aliasing/quality/use_taa` | bool | `false` | Forward+ only; start-only *(4.6-verified)* |
| `rendering/anti_aliasing/quality/use_debanding` | bool | `false` | start-only *(4.6-verified)* |
| `rendering/scaling_3d/mode` | int | `0` (bilinear) | 3D only; **`5` = nearest, 4.7+**; `.ios` / `.macos` overrides exist |
| `rendering/scaling_3d/scale` | float | `1.0` | 3D only; `> 1.0` bilinear-only, rejected by nearest mode |
| `rendering/scaling_3d/fsr_sharpness` | float | `0.2` | FSR only; `0.0` sharpest, max `2.0` |
| `rendering/environment/defaults/default_environment` | String | `""` | fallback env, loaded at scene load *(4.6-verified)* |

`BaseMaterial3D.texture_filter` default: `3` (`LINEAR_WITH_MIPMAPS`). There is no
project setting that changes it, in either version.

## 8. What the decision ticket still has to settle

Gathered, not decided:

1. **Renderer.** Forward+ buys volumetric fog, SSR/SSIL and GI for the cosmic skybox
   and the neon; Mobile is lighter and keeps decals and MSAA; Compatibility is the
   widest reach and loses decals and most of the atmosphere. Note that the nearest
   scaling mode in §4 works on **all** renderers, so it does not force Forward+.
2. **How nearest filtering is actually enforced in 3D**, given no setting exists —
   shared base material, shared shader, convention, or a test.
3. **Whether tessera size is pinned on screen at all**, and at what integer-divisor
   scale. Cheap on the pinned 4.7.2, but it rules out SSAA and fixes an effective
   render resolution.
4. **MSAA level**, and confirmation that no screen-space AA is wanted.
5. **Which import defaults the scaffold writes** — lossless compression and mipmaps at
   minimum — and whether Import Defaults is trusted or each asset carries its own
   `.import`.

The engine version is no longer among these: it is `4.7.2-stable`.

## Sources

- [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
  (served as 4.7, the pinned line)
- [Viewport (4.7)](https://docs.godotengine.org/en/4.7/classes/class_viewport.html) —
  `SCALING_3D_MODE_NEAREST`
- [ProjectSettings (4.7)](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html)
- [Viewport (4.6)](https://docs.godotengine.org/en/4.6/classes/class_viewport.html) —
  the enum without a nearest mode
- [ProjectSettings (4.6)](https://docs.godotengine.org/en/4.6/classes/class_projectsettings.html)
- [BaseMaterial3D (4.6)](https://docs.godotengine.org/en/4.6/classes/class_basematerial3d.html)
- [Importing images (4.6)](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/importing_images.html)
- [Import process (4.6)](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/import_process.html)
- [Resolution scaling (4.6)](https://docs.godotengine.org/en/4.6/tutorials/3d/resolution_scaling.html)
- [3D antialiasing (4.6)](https://docs.godotengine.org/en/4.6/tutorials/3d/3d_antialiasing.html)
- [Godot releases](https://github.com/godotengine/godot/releases) — `4.7.2-stable`,
  published 2026-08-18, is the latest 4.7
