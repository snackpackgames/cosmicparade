extends GutTest
## The realm scene's lighting, which `adr/0014` depends on.
##
## Its own file rather than a case in `test_realm.gd`: the subject here is `realm.tscn`'s
## authored lighting, not the realm's behaviour, in the same way `test_project_settings.gd`
## takes `project.godot` as its subject. Keeping it separate also leaves `test_realm.gd` under
## the public-method cap in `.gdlintrc`.

const REALM_SCENE := preload("res://realm/realm.tscn")


func _realm() -> Realm:
	var realm: Realm = REALM_SCENE.instantiate()
	add_child_autofree(realm)
	return realm


func test_the_key_light_casts_shadows_and_a_fill_answers_it_from_the_other_side() -> void:
	# `adr/0014`'s "discrete risers read" is a lighting finding as much as a geometric one. The
	# prototype that proved it (`test/prototypes/28-raised-hex-ground-legibility/`) cast shadows
	# and lit from two sides; the scene shipped with neither, so a raised hex read as a trench
	# cut into the board. https://github.com/snackpackgames/cosmicparade/issues/159
	var realm := _realm()
	var sun: DirectionalLight3D = realm.get_node("Sun")
	var fill: DirectionalLight3D = realm.get_node("Fill")

	assert_true(sun.shadow_enabled, "a riser that casts no shadow has nothing to read against")
	assert_false(fill.shadow_enabled, "one caster, so the terraces keep one shadow direction")
	assert_lt(fill.light_energy, sun.light_energy, "the fill lifts the risers, it does not key them")

	var sun_heading := Vector2(sun.global_basis.z.x, sun.global_basis.z.z).normalized()
	var fill_heading := Vector2(fill.global_basis.z.x, fill.global_basis.z.z).normalized()
	assert_lt(sun_heading.dot(fill_heading), 0.0, "the two come from opposite sides of the board")


func test_ambient_does_not_wash_the_risers_flat() -> void:
	# Full-strength flat ambient lights a riser wall and the ground above it almost equally,
	# which is what left the step reading as a crack.
	# https://github.com/snackpackgames/cosmicparade/issues/159
	var environment: Environment = _realm().get_node("WorldEnvironment").environment
	assert_lt(environment.ambient_light_energy, 1.0, "ambient at full strength flattens the step")
