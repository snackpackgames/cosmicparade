class_name Title
extends Control
## Stub title screen, and the project's main scene.
##
## Replaced by the real title screen. Until there is 3D geometry, the
## environment line below is the only thing that would reveal a degraded boot.

@onready var _environment_line: Label = %EnvironmentLine


func _ready() -> void:
	_environment_line.text = _describe_environment()


## Reads the live environment rather than ProjectSettings. Godot's
## rendering/rendering_device/fallback_to_* settings let a Forward+ project come
## up in Compatibility on hardware that cannot serve it, so reading the settings
## back would echo what was requested instead of what happened.
func _describe_environment() -> String:
	var version := Engine.get_version_info()
	var viewport_size := get_viewport_rect().size
	return "%s · %d.%d.%d.%s · %d×%d" % [
		RenderingServer.get_current_rendering_method(),
		version.major,
		version.minor,
		version.patch,
		version.status,
		int(viewport_size.x),
		int(viewport_size.y),
	]
