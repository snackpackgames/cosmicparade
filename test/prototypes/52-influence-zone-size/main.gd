extends Node3D

# Throwaway prototype for wayfinder ticket #52: what size and shape is the zone of domain
# influence a furniture piece projects?
#
# Everything except zone extent and anchoring is already settled and is held fixed here:
# the board is a radial hexagon of radius 3 (#50), footprints come from the five-shape
# polyhex vocabulary (#51), one piece projects exactly one zone (#51), elevation is
# discrete risers of 0.35 per burgeon depth with the per-domain maximum rather than a sum
# (#28, #29, #40), and the first zone of a domain raises nothing (#37).
#
# Colour here is a readability crutch for this one question, not a proposal: domain tinting
# is its own open question. Bare board is grey, each domain a tint, fused hexes a third.

const SIZE := 1.0
const BOARD_RADIUS := 3
const FLOOR_Y := -1.6
const STEP := 0.35
const DEPTH_CAP := 4
const UV_SCALE := 0.5

const DIRS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]

# The five-shape footprint vocabulary from #51, as offsets from the piece's origin hex.
const FOOTPRINTS := {
	"single": [Vector2i(0, 0)],
	"pair": [Vector2i(0, 0), Vector2i(1, 0)],
	"straight-three": [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)],
	"bend-three": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1)],
	"triangle-three": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
}

const BARE := Color(0.40, 0.44, 0.38)
const DOMAIN_A := Color(0.30, 0.52, 0.66)
const DOMAIN_B := Color(0.66, 0.46, 0.26)
const FUSED := Color(0.52, 0.34, 0.62)
const FURNITURE := Color(0.88, 0.86, 0.80)

var out_dir := "/tmp/out"
var board: Array[Vector2i] = []
var materials := {}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	_build_board()
	for tint in [BARE, DOMAIN_A, DOMAIN_B, FUSED, FURNITURE]:
		materials[tint] = _make_material(tint)
	_setup_world()
	await _render_scenarios()
	get_tree().quit()


func _hex_dist(a: Vector2i, b: Vector2i) -> int:
	var d := a - b
	@warning_ignore("integer_division")
	return (absi(d.x) + absi(d.y) + absi(d.x + d.y)) / 2


func _build_board() -> void:
	for q in range(-BOARD_RADIUS, BOARD_RADIUS + 1):
		for r in range(-BOARD_RADIUS, BOARD_RADIUS + 1):
			var c := Vector2i(q, r)
			if _hex_dist(c, Vector2i.ZERO) <= BOARD_RADIUS:
				board.append(c)


func _disc(centre: Vector2i, radius: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in board:
		if _hex_dist(c, centre) <= radius:
			out.append(c)
	return out


# A piece's single zone. "origin" puts it at the origin hex only; "grown" unions a disc
# around every occupied hex, so a bigger piece reaches further.
func _zone_of(piece: Dictionary, radius: int, anchoring: String) -> Array[Vector2i]:
	var origin: Vector2i = piece["origin"]
	var shape: Array = FOOTPRINTS[piece["footprint"]]
	if anchoring == "origin":
		return _disc(origin, radius)
	var out: Array[Vector2i] = []
	for offset in shape:
		for c in _disc(origin + offset, radius):
			if not out.has(c):
				out.append(c)
	return out


func _footprint_hexes(piece: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for offset in FOOTPRINTS[piece["footprint"]]:
		out.append(piece["origin"] + offset)
	return out


func _interior_of(region: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in region:
		var enclosed := true
		for d in DIRS:
			if not region.has(c + d):
				enclosed = false
				break
		if enclosed:
			out.append(c)
	return out


# Per-hex counts of how many zones of each domain cover it, then the settled elevation
# rule: depth is the per-domain maximum minus the first zone, capped at 4.
func _evaluate(scenario: Dictionary) -> Dictionary:
	var radius: int = scenario["radius"]
	var anchoring: String = scenario["anchoring"]
	var counts := {}
	for c in board:
		counts[c] = {"A": 0, "B": 0}
	var feet: Array[Vector2i] = []
	for piece in scenario["pieces"]:
		var domain: String = piece["domain"]
		for c in _zone_of(piece, radius, anchoring):
			counts[c][domain] += 1
		for c in _footprint_hexes(piece):
			feet.append(c)

	var depth := {}
	var tint := {}
	var fused_region: Array[Vector2i] = []
	var histogram := {}
	for c in board:
		var a: int = counts[c]["A"]
		var b: int = counts[c]["B"]
		depth[c] = clampi(maxi(a, b) - 1, 0, DEPTH_CAP)
		histogram[depth[c]] = histogram.get(depth[c], 0) + 1
		if a > 0 and b > 0:
			tint[c] = FUSED
			fused_region.append(c)
		elif a > 0:
			tint[c] = DOMAIN_A
		elif b > 0:
			tint[c] = DOMAIN_B
		else:
			tint[c] = BARE
	return {
		"depth": depth,
		"tint": tint,
		"feet": feet,
		"fused": fused_region,
		"interior": _interior_of(fused_region),
		"histogram": histogram,
		"covered": _covered(tint),
	}


func _covered(tint: Dictionary) -> int:
	var n := 0
	for c in tint:
		if tint[c] != BARE:
			n += 1
	return n


func _centre_of(c: Vector2i) -> Vector2:
	return Vector2(SIZE * 1.5 * float(c.x), SIZE * sqrt(3.0) * (float(c.y) + float(c.x) * 0.5))


func _corner(ctr: Vector2, i: int) -> Vector2:
	var a := deg_to_rad(60.0 * float(i))
	return ctr + Vector2(SIZE * cos(a), SIZE * sin(a))


func _make_material(tint: Color) -> ShaderMaterial:
	var n := 32
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var grout := tint.darkened(0.55)
	var rng := RandomNumberGenerator.new()
	for y in n:
		for x in n:
			if x % 4 == 0 or y % 4 == 0:
				img.set_pixel(x, y, grout)
			else:
				@warning_ignore("integer_division")
				rng.seed = 20261113 + (y / 4) * 8 + (x / 4)
				var v := rng.randf_range(-0.06, 0.06)
				img.set_pixel(x, y, Color(tint.r + v, tint.g + v, tint.b + v))
	img.generate_mipmaps()
	var m := ShaderMaterial.new()
	m.shader = load("res://surface.gdshader")
	m.set_shader_parameter("albedo_texture", ImageTexture.create_from_image(img))
	return m


func _setup_world() -> void:
	var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = Color(0.17, 0.15, 0.33)
	pm.sky_horizon_color = Color(0.46, 0.33, 0.50)
	pm.ground_bottom_color = Color(0.09, 0.08, 0.15)
	pm.ground_horizon_color = Color(0.30, 0.22, 0.34)
	var sky := Sky.new()
	sky.sky_material = pm
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.5
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46.0, -38.0, 0.0)
	sun.light_energy = 1.7
	sun.shadow_enabled = true
	add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18.0, 142.0, 0.0)
	fill.light_energy = 0.45
	fill.light_color = Color(0.72, 0.78, 1.0)
	add_child(fill)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	for p in [a, b, c]:
		st.set_normal(n)
		st.set_uv(_uv(p, n))
		st.add_vertex(p)


func _uv(p: Vector3, n: Vector3) -> Vector2:
	if absf(n.y) > 0.5:
		return Vector2(p.x, p.z) * UV_SCALE
	return Vector2(p.x * n.z - p.z * n.x, -p.y) * UV_SCALE


# One prism per hex, riser form: every corner takes its own cell's height, so each height
# change is a vertical wall on the hex boundary (#28's finding).
func _column(st: SurfaceTool, c: Vector2i, top: float) -> void:
	var ctr := _centre_of(c)
	var cps: Array[Vector3] = []
	for i in 6:
		var p2 := _corner(ctr, i)
		cps.append(Vector3(p2.x, top, p2.y))
	var mid := Vector3(ctr.x, top, ctr.y)
	for i in 6:
		_tri(st, mid, cps[i], cps[(i + 1) % 6], Vector3.UP)
	for i in 6:
		var a: Vector3 = cps[i]
		var b: Vector3 = cps[(i + 1) % 6]
		var af := Vector3(a.x, FLOOR_Y, a.z)
		var bf := Vector3(b.x, FLOOR_Y, b.z)
		var e := ((a + b) * 0.5) - Vector3(ctr.x, 0.0, ctr.y)
		var outward := Vector3(e.x, 0.0, e.z).normalized()
		_tri(st, a, af, b, outward)
		_tri(st, b, af, bf, outward)


func _board_meshes(result: Dictionary) -> Dictionary:
	var by_tint := {}
	for c in board:
		var tint: Color = result["tint"][c]
		if not by_tint.has(tint):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			by_tint[tint] = st
		_column(by_tint[tint], c, float(result["depth"][c]) * STEP)
	var out := {}
	for tint in by_tint:
		by_tint[tint].index()
		out[tint] = by_tint[tint].commit()
	return out


# A plain block standing on each occupied hex, so footprint cost reads against zone reach.
func _furniture_mesh(result: Dictionary) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for c in result["feet"]:
		var top: float = float(result["depth"][c]) * STEP
		var ctr := _centre_of(c)
		var half := SIZE * 0.42
		var lo := top + 0.02
		var hi := top + 0.75
		var corners := [
			Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)
		]
		var top_ring: Array[Vector3] = []
		for p in corners:
			top_ring.append(Vector3(ctr.x + p.x, hi, ctr.y + p.y))
		_tri(st, top_ring[0], top_ring[1], top_ring[2], Vector3.UP)
		_tri(st, top_ring[0], top_ring[2], top_ring[3], Vector3.UP)
		for i in 4:
			var a: Vector3 = top_ring[i]
			var b: Vector3 = top_ring[(i + 1) % 4]
			var al := Vector3(a.x, lo, a.z)
			var bl := Vector3(b.x, lo, b.z)
			var e := ((a + b) * 0.5) - Vector3(ctr.x, hi, ctr.y)
			var outward := Vector3(e.x, 0.0, e.z).normalized()
			_tri(st, a, al, b, outward)
			_tri(st, b, al, bl, outward)
	st.index()
	return st.commit()


func _place_camera(cam: Camera3D) -> void:
	var yaw := deg_to_rad(35.0)
	var pitch := deg_to_rad(50.0)
	var target := Vector3(0.0, 0.1, 0.0)
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	cam.position = target + dir * 17.0
	cam.look_at(target, Vector3.UP)


func _scenarios() -> Array[Dictionary]:
	return [
		{
			"name": "1-r1-one-single-piece",
			"radius": 1,
			"anchoring": "origin",
			"pieces": [{"domain": "A", "footprint": "single", "origin": Vector2i(0, 0)}],
		},
		{
			"name": "2-r2-one-single-piece",
			"radius": 2,
			"anchoring": "origin",
			"pieces": [{"domain": "A", "footprint": "single", "origin": Vector2i(0, 0)}],
		},
		{
			"name": "3-r1-origin-anchored-straight-three",
			"radius": 1,
			"anchoring": "origin",
			"pieces": [{"domain": "A", "footprint": "straight-three", "origin": Vector2i(0, 0)}],
		},
		{
			"name": "4-r1-grown-straight-three",
			"radius": 1,
			"anchoring": "grown",
			"pieces": [{"domain": "A", "footprint": "straight-three", "origin": Vector2i(0, 0)}],
		},
		{
			"name": "5-r1-two-domains-six-singles",
			"radius": 1,
			"anchoring": "origin",
			"pieces": [
				{"domain": "A", "footprint": "single", "origin": Vector2i(2, 0)},
				{"domain": "A", "footprint": "single", "origin": Vector2i(0, 0)},
				{"domain": "A", "footprint": "single", "origin": Vector2i(0, 2)},
				{"domain": "B", "footprint": "single", "origin": Vector2i(2, 1)},
				{"domain": "B", "footprint": "single", "origin": Vector2i(0, 1)},
				{"domain": "B", "footprint": "single", "origin": Vector2i(2, -1)},
			],
		},
		{
			"name": "6-r2-two-domains-four-singles",
			"radius": 2,
			"anchoring": "origin",
			"pieces": [
				{"domain": "A", "footprint": "single", "origin": Vector2i(-2, 0)},
				{"domain": "A", "footprint": "single", "origin": Vector2i(1, 0)},
				{"domain": "B", "footprint": "single", "origin": Vector2i(-1, 0)},
				{"domain": "B", "footprint": "single", "origin": Vector2i(2, 0)},
			],
		},
		{
			"name": "7-r1-five-same-domain-depth-four",
			"radius": 1,
			"anchoring": "origin",
			"pieces": [
				{"domain": "A", "footprint": "single", "origin": Vector2i(0, 0)},
				{"domain": "A", "footprint": "single", "origin": Vector2i(1, 0)},
				{"domain": "A", "footprint": "single", "origin": Vector2i(1, -1)},
				{"domain": "A", "footprint": "single", "origin": Vector2i(0, -1)},
				{"domain": "A", "footprint": "single", "origin": Vector2i(-1, 0)},
			],
		},
		{
			"name": "8-r1-grown-mixed-fleet",
			"radius": 1,
			"anchoring": "grown",
			"pieces": [
				{"domain": "A", "footprint": "straight-three", "origin": Vector2i(-1, 1)},
				{"domain": "A", "footprint": "single", "origin": Vector2i(1, -2)},
				{"domain": "B", "footprint": "triangle-three", "origin": Vector2i(0, -1)},
				{"domain": "B", "footprint": "pair", "origin": Vector2i(-2, 0)},
			],
		},
	]


func _render_scenarios() -> void:
	var cam := Camera3D.new()
	cam.fov = 45.0
	add_child(cam)
	_place_camera(cam)
	print("board cells=", board.size())
	for scenario in _scenarios():
		var result := _evaluate(scenario)
		var holders: Array[MeshInstance3D] = []
		var meshes := _board_meshes(result)
		for tint in meshes:
			var mi := MeshInstance3D.new()
			mi.mesh = meshes[tint]
			mi.material_override = materials[tint]
			add_child(mi)
			holders.append(mi)
		var furniture := MeshInstance3D.new()
		furniture.mesh = _furniture_mesh(result)
		furniture.material_override = materials[FURNITURE]
		add_child(furniture)
		holders.append(furniture)

		for _i in 4:
			await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path: String = out_dir + "/" + String(scenario["name"]) + ".png"
		var err := img.save_png(path)
		print(
			String(scenario["name"]),
			": pieces=", scenario["pieces"].size(),
			" covered=", result["covered"], "/", board.size(),
			" fused=", result["fused"].size(),
			" interior=", result["interior"].size(),
			" depth=", result["histogram"],
			" err=", err
		)
		for mi in holders:
			mi.queue_free()
		await get_tree().process_frame
