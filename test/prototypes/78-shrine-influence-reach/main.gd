extends Node3D

# Throwaway prototype for wayfinder ticket #78: how much shrine influence can actually
# reach one hex?
#
# Everything a shrine is has already been decided and is held fixed here: a shrine is a
# single hex projecting a radius-2 disc (#74), grown from its one occupied hex (#52), and
# it projects the domain of the offering in its vessel — an empty vessel projects nothing
# at all (#75). The Altar is a triangle-three at the origin projecting nothing (#77).
# Depth is same-domain zones minus one, capped at 4 (#37, adr/0014), drawn as discrete
# risers of 0.35 (#28, #29). Footprints never collide; influence overlaps freely.
#
# The only variable is how many shrines are standing and what is in their vessels. The
# census printed before the renders is the real answer; the renders are there to judge
# whether the result is a board a player can read.
#
# Colour is a readability crutch for this one question, not a proposal.

const SIZE := 1.0
const FLOOR_Y := -1.6
const STEP := 0.35
const DEPTH_CAP := 4
const UV_SCALE := 0.5
const ZONE_RADIUS := 2
const FURNITURE_RADIUS := 1

# The Altar's triangle-three at the origin in its default orientation (#77).
const ALTAR_HEXES: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1)]

const BARE := Color(0.40, 0.44, 0.38)
const DOMAIN_A := Color(0.30, 0.52, 0.66)
const DOMAIN_B := Color(0.66, 0.46, 0.26)
const FUSED := Color(0.52, 0.34, 0.62)
const FIXTURE := Color(0.88, 0.86, 0.80)
const ALTAR_TINT := Color(0.94, 0.80, 0.42)

var out_dir := "/tmp/out"
var board: Array[Vector2i] = []
var materials := {}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	for tint in [BARE, DOMAIN_A, DOMAIN_B, FUSED, FIXTURE, ALTAR_TINT]:
		materials[tint] = _make_material(tint)
	_census()
	_setup_world()
	await _render_scenarios()
	get_tree().quit()


func _hex_dist(a: Vector2i, b: Vector2i) -> int:
	var d := a - b
	@warning_ignore("integer_division")
	return (absi(d.x) + absi(d.y) + absi(d.x + d.y)) / 2


func _board_of(radius: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		for r in range(-radius, radius + 1):
			var c := Vector2i(q, r)
			if _hex_dist(c, Vector2i.ZERO) <= radius:
				out.append(c)
	return out


func _disc(centre: Vector2i, radius: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in board:
		if _hex_dist(c, centre) <= radius:
			out.append(c)
	return out


# How many board hexes could host a single shrine that still reaches `target`. This is the
# ceiling on depth at that hex: nothing but the supply of shrines limits it further.
func _hosts_reaching(cells: Array[Vector2i], target: Vector2i) -> int:
	var n := 0
	for c in cells:
		if _hex_dist(c, target) <= ZONE_RADIUS:
			n += 1
	return n


# The largest number of hexes `count` shrines can cover between them, by exhaustive search
# over every placement. Returns early once the whole board is covered.
#
# Coverage is a bit per board hex, held in two 63-bit words rather than one: a radius-5
# board is 91 hexes and `1 << i` silently wraps past 63 on a 64-bit int, which quietly
# inflated every radius-5 number on the first run of this prototype.
func _max_union(cells: Array[Vector2i], count: int) -> int:
	var low: Array[int] = []
	var high: Array[int] = []
	for c in cells:
		var low_word := 0
		var high_word := 0
		for i in cells.size():
			if _hex_dist(cells[i], c) <= ZONE_RADIUS:
				if i < 63:
					low_word |= 1 << i
				else:
					high_word |= 1 << (i - 63)
		low.append(low_word)
		high.append(high_word)
	var best := 0
	var indices: Array[int] = []
	for i in count:
		indices.append(i)
	while true:
		var union_low := 0
		var union_high := 0
		for i in indices:
			union_low |= low[i]
			union_high |= high[i]
		var covered := 0
		for i in cells.size():
			if i < 63:
				if union_low & (1 << i) != 0:
					covered += 1
			elif union_high & (1 << (i - 63)) != 0:
				covered += 1
		best = maxi(best, covered)
		if best == cells.size():
			return best
		var pivot := count - 1
		while pivot >= 0 and indices[pivot] == cells.size() - count + pivot:
			pivot -= 1
		if pivot < 0:
			return best
		indices[pivot] += 1
		for i in range(pivot + 1, count):
			indices[i] = indices[i - 1] + 1
	return best


func _median(values: Array[int]) -> int:
	var sorted_values := values.duplicate()
	sorted_values.sort()
	return sorted_values[sorted_values.size() / 2]


func _census() -> void:
	print("--- how many board hexes can host a shrine that reaches one target ---")
	for radius in [3, 4, 5]:
		var cells := _board_of(radius)
		var counts: Array[int] = []
		for c in cells:
			counts.append(_hosts_reaching(cells, c))
		print(
			"radius ", radius, " (", cells.size(), " hexes): centre ",
			_hosts_reaching(cells, Vector2i.ZERO), ", max ", counts.max(),
			", min ", counts.min(), ", median ", _median(counts)
		)

	print("--- most hexes `n` shrines can cover between them, exhaustive ---")
	for radius in [3, 5]:
		var cells := _board_of(radius)
		var limit := 4 if radius == 3 else 3
		var parts: Array[String] = []
		for count in range(1, limit + 1):
			var covered := _max_union(cells, count)
			parts.append(
				"%d:%d (%d%%)" % [count, covered, roundi(100.0 * covered / cells.size())]
			)
		print("radius ", radius, " (", cells.size(), " hexes): ", " ".join(parts))

	print("--- what the Altar's triangle-three can be reached from ---")
	for radius in [3, 5]:
		var cells := _board_of(radius)
		var all_three := 0
		var any_of_three := 0
		for c in cells:
			var reached := 0
			for hex in ALTAR_HEXES:
				if _hex_dist(c, hex) <= ZONE_RADIUS:
					reached += 1
			if reached == 3:
				all_three += 1
			if reached > 0:
				any_of_three += 1
		var usable := 0
		for c in cells:
			if ALTAR_HEXES.has(c):
				continue
			var covers_all := true
			for hex in ALTAR_HEXES:
				covers_all = covers_all and _hex_dist(c, hex) <= ZONE_RADIUS
			if covers_all:
				usable += 1
		print(
			"radius ", radius, ": ", all_three, " hexes reach all three (", usable,
			" of them free of the Altar itself), ", any_of_three, " reach at least one"
		)

	print("--- depth from `n` same-domain shrines over one hex ---")
	var depths: Array[String] = []
	for n in range(0, 7):
		depths.append("%d:%d" % [n, clampi(n - 1, 0, DEPTH_CAP)])
	print(" ".join(depths))


# Per-hex counts of how many shrine zones of each domain cover it, then the settled
# elevation rule. A shrine whose vessel is empty contributes nothing.
func _evaluate(scenario: Dictionary) -> Dictionary:
	var counts := {}
	for c in board:
		counts[c] = {"A": 0, "B": 0}
	var shrine_hexes: Array[Vector2i] = []
	for shrine in scenario["shrines"]:
		var hex: Vector2i = shrine["hex"]
		shrine_hexes.append(hex)
		var domain: String = shrine["domain"]
		if domain == "":
			continue
		for c in _disc(hex, ZONE_RADIUS):
			counts[c][domain] += 1
	var furniture_hexes: Array[Vector2i] = []
	for piece in scenario.get("furniture", []):
		var hex: Vector2i = piece["hex"]
		furniture_hexes.append(hex)
		for c in _disc(hex, FURNITURE_RADIUS):
			counts[c][piece["domain"]] += 1

	var depth := {}
	var tint := {}
	var histogram := {}
	for c in board:
		var a: int = counts[c]["A"]
		var b: int = counts[c]["B"]
		depth[c] = clampi(maxi(a, b) - 1, 0, DEPTH_CAP)
		histogram[depth[c]] = histogram.get(depth[c], 0) + 1
		if a > 0 and b > 0:
			tint[c] = FUSED
		elif a > 0:
			tint[c] = DOMAIN_A
		elif b > 0:
			tint[c] = DOMAIN_B
		else:
			tint[c] = BARE
	var altar_reading: Array[int] = []
	for hex in ALTAR_HEXES:
		altar_reading.append(maxi(counts[hex]["A"], counts[hex]["B"]))
	return {
		"depth": depth,
		"tint": tint,
		"shrines": shrine_hexes,
		"furniture": furniture_hexes,
		"histogram": histogram,
		"covered": _covered(tint),
		"altar": altar_reading,
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
				rng.seed = 20261115 + (y / 4) * 8 + (x / 4)
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


# A plain block on each named hex, tall enough to read as a fixture against the board.
func _block_mesh(result: Dictionary, hexes: Array[Vector2i], height: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for c in hexes:
		var top: float = float(result["depth"][c]) * STEP
		var ctr := _centre_of(c)
		var half := SIZE * 0.42
		var lo := top + 0.02
		var hi := top + height
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


func _place_camera(cam: Camera3D, radius: int) -> void:
	var yaw := deg_to_rad(35.0)
	var pitch := deg_to_rad(50.0)
	var target := Vector3(0.0, 0.1, 0.0)
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	cam.position = target + dir * (11.0 + 2.0 * float(radius))
	cam.look_at(target, Vector3.UP)


# The five positions a search found best for piling same-domain influence on the origin
# while leaving the Altar's own three hexes clear. Restated in #78's resolution.
func _piled_five() -> Array[Dictionary]:
	return [
		{"hex": Vector2i(-2, 0), "domain": "A"},
		{"hex": Vector2i(-2, 1), "domain": "A"},
		{"hex": Vector2i(-2, 2), "domain": "A"},
		{"hex": Vector2i(-1, -1), "domain": "A"},
		{"hex": Vector2i(-1, 0), "domain": "A"},
	]


func _lapsed(shrines: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for shrine in shrines:
		out.append({"hex": shrine["hex"], "domain": ""})
	return out


func _scenarios() -> Array[Dictionary]:
	return [
		{
			"name": "1-r3-capacity-two-fed",
			"radius": 3,
			"shrines": [
				{"hex": Vector2i(-2, 1), "domain": "A"},
				{"hex": Vector2i(2, -1), "domain": "A"},
			],
		},
		{
			# The triple an exhaustive search found: three shrines, no board hex left bare.
			"name": "2-r3-three-shrines-blanket",
			"radius": 3,
			"shrines": [
				{"hex": Vector2i(-2, 1), "domain": "A"},
				{"hex": Vector2i(1, -2), "domain": "A"},
				{"hex": Vector2i(1, 1), "domain": "A"},
			],
		},
		{
			"name": "3-r3-five-same-domain-piled",
			"radius": 3,
			"shrines": _piled_five(),
		},
		{
			"name": "4-r3-five-shrines-lapsed",
			"radius": 3,
			"shrines": _lapsed(_piled_five()),
		},
		{
			"name": "5-r5-five-same-domain-piled",
			"radius": 5,
			"shrines": _piled_five(),
		},
		{
			"name": "6-r3-two-shrines-over-six-furniture",
			"radius": 3,
			"shrines": [
				{"hex": Vector2i(-2, 1), "domain": "A"},
				{"hex": Vector2i(2, -1), "domain": "A"},
			],
			"furniture": [
				{"hex": Vector2i(0, 2), "domain": "B"},
				{"hex": Vector2i(-1, 2), "domain": "B"},
				{"hex": Vector2i(2, 0), "domain": "B"},
				{"hex": Vector2i(-2, 0), "domain": "B"},
				{"hex": Vector2i(0, -2), "domain": "B"},
				{"hex": Vector2i(2, -3), "domain": "B"},
			],
		},
	]


func _render_scenarios() -> void:
	var cam := Camera3D.new()
	cam.fov = 45.0
	add_child(cam)
	for scenario in _scenarios():
		var radius: int = scenario["radius"]
		board = _board_of(radius)
		_place_camera(cam, radius)
		var result := _evaluate(scenario)
		var holders: Array[MeshInstance3D] = []
		var meshes := _board_meshes(result)
		for tint in meshes:
			var mi := MeshInstance3D.new()
			mi.mesh = meshes[tint]
			mi.material_override = materials[tint]
			add_child(mi)
			holders.append(mi)
		for pair in [
			[result["shrines"], 0.9, FIXTURE],
			[result["furniture"], 0.5, FIXTURE],
			[ALTAR_HEXES, 1.4, ALTAR_TINT],
		]:
			var hexes: Array[Vector2i] = pair[0]
			if hexes.is_empty():
				continue
			var mi := MeshInstance3D.new()
			mi.mesh = _block_mesh(result, hexes, pair[1])
			mi.material_override = materials[pair[2]]
			add_child(mi)
			holders.append(mi)

		for _i in 4:
			await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path: String = out_dir + "/" + String(scenario["name"]) + ".png"
		var err := img.save_png(path)
		print(
			String(scenario["name"]),
			": board=", board.size(),
			" shrines=", scenario["shrines"].size(),
			" covered=", result["covered"], "/", board.size(),
			" depth=", result["histogram"],
			" altar_reading=", result["altar"],
			" err=", err
		)
		for mi in holders:
			mi.queue_free()
		await get_tree().process_frame
