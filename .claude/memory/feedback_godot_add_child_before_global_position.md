---
name: feedback-godot-add-child-before-global-position
description: In Godot 4, always call add_child() before setting global_position on a newly instantiated node
metadata:
  type: feedback
---

Always call `add_child(node)` before setting `node.global_position`. In Godot 4, setting `global_position` on a node not yet in the scene tree sets its local `position` instead (no parent transform context). When `add_child` is then called, the parent's world transform is applied on top, producing the wrong final world position.

**Why:** A spawner that set `global_position` before `add_child` placed everything it spawned at the wrong world position, because the parent offset was applied twice. The symptom looks like a bad spawn-position calculation, so it costs real time to track down.

**How to apply:** Any time a node is instantiated and needs a specific world position, follow this pattern:
```gdscript
var node = scene.instantiate()
add_child(node)
node.global_position = desired_world_pos
```
Never set `global_position` before `add_child`. Setting `position` (local) before `add_child` is fine if you intend local coordinates.
