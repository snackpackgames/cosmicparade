class_name HexCursor
extends Node3D
## The one targeted hex the carry verb reads. A mouse warps it with a raycast against
## `realm_space`; a gamepad or keyboard steps it to the neighbour nearest the pushed direction.
## Nothing downstream knows which device moved it.
## https://github.com/snackpackgames/cosmicparade/issues/54

signal targeted_hex_changed(hex: Vector2i)

const REALM_SPACE_MASK := 1
const RAY_LENGTH := 200.0

var targeted_hex := Vector2i.ZERO


func _ready() -> void:
	position = HexCoordinates.center_of(targeted_hex)


func aim_at(hex: Vector2i) -> void:
	if hex == targeted_hex:
		return
	targeted_hex = hex
	position = HexCoordinates.center_of(hex)
	targeted_hex_changed.emit(hex)


## Steps one hex toward the push. A push of zero length leaves the target where it is.
func step(push: Vector2) -> void:
	if push.is_zero_approx():
		return
	aim_at(targeted_hex + nearest_direction(push))


## The direction whose world offset, flattened to XZ, lies closest in angle to the push.
static func nearest_direction(push: Vector2) -> Vector2i:
	var best := HexCoordinates.DIRECTIONS[0]
	var best_angle := INF
	for direction in HexCoordinates.DIRECTIONS:
		var center := HexCoordinates.center_of(direction)
		var angle := absf(push.angle_to(Vector2(center.x, center.z)))
		if angle < best_angle:
			best_angle = angle
			best = direction
	return best


## The hex under a screen point, or null. The mask is `realm_space` alone, so a piece standing
## on a hex does not shadow it; what stands there is `RealmState.occupant_at()`'s business.
func hex_under_pointer(camera: Camera3D, screen_point: Vector2) -> Variant:
	var origin := camera.project_ray_origin(screen_point)
	var query := PhysicsRayQueryParameters3D.create(
		origin, origin + camera.project_ray_normal(screen_point) * RAY_LENGTH
	)
	query.collision_mask = REALM_SPACE_MASK
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var collider: Object = hit["collider"]
	return collider.get("hex") if collider is HexSpace else null
