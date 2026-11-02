# 3D geometry with a pixel-mosaic art style

Cosmic Parade is a 3D Godot project, but its art direction is pixel art styled to look
like laid mosaic tile, which usually implies a 2D project. The two coexist
deliberately: the hex board has real dimension and grown terrain has real height, so
board spaces, tiles and terrain features are volumes.

## Consequences

Tiles and board spaces are `Node3D`/`Area3D`, not `Node2D`. The project's 3D physics
layers (`[layer_names] 3d_physics/*`) are the relevant set. The plugin's 2D-only
skills (`godot-2d-physics`, `godot-characterbody-2d`, `godot-2d-animation`,
`godot-tilemap-mastery`) do not apply and are deliberately excluded from the skill
table in `CLAUDE.md` — a pixel-art look is not a reason to reach for them.
