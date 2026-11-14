extends Node3D

# Throwaway prototype for wayfinder ticket #61: what shapes belong in the wing vocabulary,
# how many hexes is each, and does a wing's orientation matter?
#
# Everything else is held fixed at what is already settled. The core is the radial hexagon
# at its post-Swell ceiling of radius 5 (#50, #53). Wings attach edge-adjacent to any board
# hex and are all the same hex count (#53). Zones are radius-1 discs grown from every
# occupied hex (#52), and influence that falls off the board is inert (#59) — which is what
# makes "full reach" below the metric that matters.
#
# A hex is FULL when a radius-1 disc centred on it lies entirely on the board: a piece
# there loses none of its reach. Otherwise it is RIM. The core alone has 61 full of 91.
# A wing's worth is therefore not how many hexes it adds but how many FULL hexes the board
# gains — and a wing can upgrade core rim hexes as well as supply its own.
#
# Colour is a readability crutch for this question only, as in the #52 prototype: core and
# wing are tinted apart so the join is visible, which the geometry alone cannot show.

const SIZE := 1.0
const CORE_RADIUS := 5
const FLOOR_Y := -1.6
const UV_SCALE := 0.5

const DIRS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]

# Candidate wing shapes, as offsets from the shape's own origin hex. The 7-hex entries are
# the roster under consideration; small-4 and big-10 exist only to show what the single
# hex-count dial does.
const SHAPES := {
	"flower-7": [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(1, -1),
		Vector2i(0, -1),
		Vector2i(-1, 0),
		Vector2i(-1, 1),
		Vector2i(0, 1),
	],
	"line-7": [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(3, 0),
		Vector2i(4, 0),
		Vector2i(5, 0),
		Vector2i(6, 0),
	],
	"arm-7": [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(3, 0),
		Vector2i(3, 1),
		Vector2i(3, 2),
		Vector2i(3, 3),
	],
	"fan-7": [
		Vector2i(0, 0),
		Vector2i(0, 1),
		Vector2i(0, 2),
		Vector2i(0, 3),
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(1, 2),
	],
	"triangle-6": [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(0, 2),
	],
	"rhombus-6": [
		Vector2i(0, 0),
		Vector2i(0, 1),
		Vector2i(0, 2),
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(1, 2),
	],
	"small-4": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"big-10": [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(1, -1),
		Vector2i(0, -1),
		Vector2i(-1, 0),
		Vector2i(-1, 1),
		Vector2i(0, 1),
		Vector2i(2, 0),
		Vector2i(2, -1),
		Vector2i(2, -2),
	],
}

const CORE_FULL := Color(0.42, 0.46, 0.40)
const CORE_RIM := Color(0.27, 0.29, 0.26)
const WING_FULL := Color(0.34, 0.56, 0.68)
const WING_RIM := Color(0.20, 0.33, 0.42)

var out_dir := "/tmp/out"
var core: Array[Vector2i] = []
var materials := {}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	core = _radial_hexagon(CORE_RADIUS)
	for tint in [CORE_FULL, CORE_RIM, WING_FULL, WING_RIM]:
		materials[tint] = _make_material(tint)
	_setup_world()
	_report_rotations()
	await _render_scenarios()
	get_tree().quit()


func _hex_dist(a: Vector2i, b: Vector2i) -> int:
	var d := a - b
	@warning_ignore("integer_division")
	return (absi(d.x) + absi(d.y) + absi(d.x + d.y)) / 2


func _radial_hexagon(radius: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		for r in range(-radius, radius + 1):
			var c := Vector2i(q, r)
			if _hex_dist(c, Vector2i.ZERO) <= radius:
				out.append(c)
	return out


# One 60 degree step on the flat-top axial lattice: cube (x,y,z) -> (-z,-x,-y).
func _rotate(c: Vector2i, steps: int) -> Vector2i:
	var out := c
	for _i in posmod(steps, 6):
		out = Vector2i(-out.y, out.x + out.y)
	return out


func _placed(shape_name: String, steps: int, at: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for offset in SHAPES[shape_name]:
		out.append(_rotate(offset, steps) + at)
	return out


# How many of the six rotations of a shape are distinct, ignoring translation. This is the
# whole of the "do wings rotate" question expressed as a number.
func _distinct_rotations(shape_name: String) -> int:
	var seen := {}
	for steps in 6:
		var pts: Array[Vector2i] = []
		for offset in SHAPES[shape_name]:
			pts.append(_rotate(offset, steps))
		pts.sort()
		var base: Vector2i = pts[0]
		var key := ""
		for p in pts:
			key += str(p - base)
		seen[key] = true
	return seen.size()


func _report_rotations() -> void:
	for shape_name in SHAPES:
		print("shape ", shape_name, ": hexes=", SHAPES[shape_name].size(),
			" distinct_rotations=", _distinct_rotations(shape_name))


func _is_full(c: Vector2i, board: Dictionary) -> bool:
	for d in DIRS:
		if not board.has(c + d):
			return false
	return true


# Off-board hexes that touch three or more board hexes: pockets a later wing can nest into.
func _notches(board: Dictionary) -> int:
	var candidates := {}
	for c in board:
		for d in DIRS:
			var n: Vector2i = c + d
			if not board.has(n):
				candidates[n] = int(candidates.get(n, 0)) + 1
	var count := 0
	for c in candidates:
		if int(candidates[c]) >= 3:
			count += 1
	return count


func _evaluate(scenario: Dictionary) -> Dictionary:
	var board := {}
	for c in core:
		board[c] = "core"
	var wing_hexes: Array[Vector2i] = []
	var overlaps := 0
	var detached := 0
	for wing in scenario["wings"]:
		var hexes := _placed(wing["shape"], int(wing["steps"]), wing["at"])
		var touches := false
		for c in hexes:
			if board.has(c):
				overlaps += 1
			for d in DIRS:
				if board.has(c + d):
					touches = true
		if not touches:
			detached += 1
		for c in hexes:
			board[c] = "wing"
			wing_hexes.append(c)

	var seam_hexes := 0
	var seam_edges := 0
	for c in wing_hexes:
		var adjacent := 0
		for d in DIRS:
			if board.has(c + d) and board[c + d] == "core":
				adjacent += 1
		if adjacent > 0:
			seam_hexes += 1
		seam_edges += adjacent

	var tint := {}
	var full_total := 0
	var full_wing := 0
	for c in board:
		var full := _is_full(c, board)
		if full:
			full_total += 1
		if board[c] == "core":
			tint[c] = CORE_FULL if full else CORE_RIM
		else:
			tint[c] = WING_FULL if full else WING_RIM
			if full:
				full_wing += 1

	var core_board := {}
	for c in core:
		core_board[c] = "core"
	var full_before := 0
	for c in core:
		if _is_full(c, core_board):
			full_before += 1

	return {
		"tint": tint,
		"hexes": board.keys(),
		"added": wing_hexes.size(),
		"seam_hexes": seam_hexes,
		"seam_edges": seam_edges,
		"full_total": full_total,
		"full_before": full_before,
		"full_wing": full_wing,
		"notches": _notches(board),
		"overlaps": overlaps,
		"detached": detached,
	}


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


func _column(st: SurfaceTool, c: Vector2i) -> void:
	var ctr := _centre_of(c)
	var cps: Array[Vector3] = []
	for i in 6:
		var p2 := _corner(ctr, i)
		cps.append(Vector3(p2.x, 0.0, p2.y))
	var mid := Vector3(ctr.x, 0.0, ctr.y)
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
	for c in result["hexes"]:
		var tint: Color = result["tint"][c]
		if not by_tint.has(tint):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			by_tint[tint] = st
		_column(by_tint[tint], c)
	var out := {}
	for tint in by_tint:
		by_tint[tint].index()
		out[tint] = by_tint[tint].commit()
	return out


# Fit the camera to whatever the scenario drew, so a sprawling board is not cropped.
func _place_camera(cam: Camera3D, hexes: Array) -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for c in hexes:
		var p := _centre_of(c)
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	var mid := (lo + hi) * 0.5
	var extent := maxf(hi.x - lo.x, hi.y - lo.y) * 0.5 + SIZE * 2.0
	var yaw := deg_to_rad(35.0)
	var pitch := deg_to_rad(55.0)
	var target := Vector3(mid.x, 0.0, mid.y)
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	cam.position = target + dir * (extent / tan(deg_to_rad(cam.fov * 0.5)) * 1.15)
	cam.look_at(target, Vector3.UP)


func _scenarios() -> Array[Dictionary]:
	return [
		{"name": "1-core-only-radius-5", "wings": []},
		{
			"name": "2-flower-7",
			"wings": [{"shape": "flower-7", "steps": 0, "at": Vector2i(7, -2)}],
		},
		{
			"name": "3-fan-7",
			"wings": [{"shape": "fan-7", "steps": 0, "at": Vector2i(6, -3)}],
		},
		{
			"name": "4-triangle-6",
			"wings": [{"shape": "triangle-6", "steps": 0, "at": Vector2i(6, -2)}],
		},
		{
			"name": "5-rhombus-6",
			"wings": [{"shape": "rhombus-6", "steps": 0, "at": Vector2i(6, -2)}],
		},
		{
			"name": "6-line-7-pointing-out",
			"wings": [{"shape": "line-7", "steps": 0, "at": Vector2i(6, -2)}],
		},
		{
			"name": "7-line-7-along-the-rim",
			"wings": [{"shape": "line-7", "steps": 4, "at": Vector2i(6, 0)}],
		},
		{
			"name": "8-arm-7",
			"wings": [{"shape": "arm-7", "steps": 0, "at": Vector2i(6, -2)}],
		},
		{
			"name": "9-small-4",
			"wings": [{"shape": "small-4", "steps": 0, "at": Vector2i(6, -2)}],
		},
		{
			"name": "10-big-10",
			"wings": [{"shape": "big-10", "steps": 0, "at": Vector2i(7, -2)}],
		},
		{
			"name": "11-roster-four-figures",
			"wings": [
				{"shape": "flower-7", "steps": 0, "at": Vector2i(7, -2)},
				{"shape": "fan-7", "steps": 3, "at": Vector2i(-6, 4)},
				{"shape": "triangle-6", "steps": 3, "at": Vector2i(2, -6)},
				{"shape": "rhombus-6", "steps": 0, "at": Vector2i(-3, 6)},
			],
		},
		{
			"name": "12-sprawl-six-figures",
			"wings": [
				{"shape": "flower-7", "steps": 0, "at": Vector2i(7, -2)},
				{"shape": "flower-7", "steps": 0, "at": Vector2i(10, -2)},
				{"shape": "fan-7", "steps": 3, "at": Vector2i(-6, 4)},
				{"shape": "triangle-6", "steps": 3, "at": Vector2i(2, -6)},
				{"shape": "rhombus-6", "steps": 0, "at": Vector2i(-3, 6)},
				{"shape": "flower-7", "steps": 0, "at": Vector2i(-5, -2)},
			],
		},
	]


func _render_scenarios() -> void:
	var cam := Camera3D.new()
	cam.fov = 45.0
	add_child(cam)
	print("core cells=", core.size())
	for scenario in _scenarios():
		var result := _evaluate(scenario)
		_place_camera(cam, result["hexes"])
		var holders: Array[MeshInstance3D] = []
		var meshes := _board_meshes(result)
		for tint in meshes:
			var mi := MeshInstance3D.new()
			mi.mesh = meshes[tint]
			mi.material_override = materials[tint]
			add_child(mi)
			holders.append(mi)

		for _i in 4:
			await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path: String = out_dir + "/" + String(scenario["name"]) + ".png"
		var err := img.save_png(path)
		print(
			String(scenario["name"]),
			": board=", result["hexes"].size(),
			" added=", result["added"],
			" seam_hexes=", result["seam_hexes"],
			" seam_edges=", result["seam_edges"],
			" full=", result["full_total"], " (was ", result["full_before"], ")",
			" full_on_wing=", result["full_wing"],
			" notches=", result["notches"],
			" overlaps=", result["overlaps"],
			" detached=", result["detached"],
			" err=", err
		)
		for mi in holders:
			mi.queue_free()
		await get_tree().process_frame
