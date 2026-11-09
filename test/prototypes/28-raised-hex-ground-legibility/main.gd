extends Node3D

# Throwaway prototype for wayfinder ticket #28: does raised hex ground read at a glance?
# Height comes from burgeon depth only (three overlapping same-domain zones), per the
# resolution of #27. One uniform material on purpose: colour-coding influence is a
# separate open question, so geometry has to carry height on its own here.

const SIZE := 1.0
const BOARD_RADIUS := 5
const FLOOR_Y := -2.0
const UV_SCALE := 0.5

const ZONES := [
	[Vector2i(-2, 1), 3],
	[Vector2i(2, -1), 3],
	[Vector2i(0, 2), 3],
	[Vector2i(1, -3), 2],
]

var out_dir := "/tmp/out"
var cells := {}
var mat: ShaderMaterial


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	_build_cells()
	mat = _make_material()
	_setup_world()
	await _render_variants()
	get_tree().quit()


func _hex_dist(a: Vector2i, b: Vector2i) -> int:
	var dq := a.x - b.x
	var dr := a.y - b.y
	return int((absi(dq) + absi(dr) + absi(dq + dr)) / 2)


func _build_cells() -> void:
	var histogram := {}
	for q in range(-BOARD_RADIUS, BOARD_RADIUS + 1):
		for r in range(-BOARD_RADIUS, BOARD_RADIUS + 1):
			var c := Vector2i(q, r)
			if _hex_dist(c, Vector2i.ZERO) > BOARD_RADIUS:
				continue
			var depth := 0
			for z in ZONES:
				if _hex_dist(c, z[0]) <= int(z[1]):
					depth += 1
			cells[c] = depth
			histogram[depth] = histogram.get(depth, 0) + 1
	print("cells=", cells.size(), " burgeon-depth histogram=", histogram)


func _center(c: Vector2i) -> Vector2:
	return Vector2(SIZE * 1.5 * float(c.x), SIZE * sqrt(3.0) * (float(c.y) + float(c.x) * 0.5))


func _corner(ctr: Vector2, i: int) -> Vector2:
	var a := deg_to_rad(60.0 * float(i))
	return ctr + Vector2(SIZE * cos(a), SIZE * sin(a))


func _key(p: Vector2) -> String:
	return "%.3f_%.3f" % [p.x, p.y]


func _make_material() -> ShaderMaterial:
	var n := 32
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var grout := Color(0.20, 0.24, 0.18)
	var rng := RandomNumberGenerator.new()
	for y in n:
		for x in n:
			if x % 4 == 0 or y % 4 == 0:
				img.set_pixel(x, y, grout)
			else:
				rng.seed = 20261108 + (y / 4) * 8 + (x / 4)
				var v := rng.randf_range(-0.07, 0.07)
				img.set_pixel(x, y, Color(0.42 + v, 0.55 + v, 0.35 + v))
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


func _build_mesh(smooth: bool, step: float) -> ArrayMesh:
	var h := {}
	for c in cells:
		h[c] = float(cells[c]) * step

	var csum := {}
	var ccnt := {}
	if smooth:
		for c in cells:
			var ctr0 := _center(c)
			for i in 6:
				var k := _key(_corner(ctr0, i))
				csum[k] = csum.get(k, 0.0) + h[c]
				ccnt[k] = ccnt.get(k, 0) + 1

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for c in cells:
		var ctr := _center(c)
		var own: float = h[c]
		var cps: Array[Vector3] = []
		for i in 6:
			var p2 := _corner(ctr, i)
			var y := own
			if smooth:
				var k := _key(p2)
				y = csum[k] / float(ccnt[k])
			cps.append(Vector3(p2.x, y, p2.y))
		var mid3 := Vector3(ctr.x, own, ctr.y)
		for i in 6:
			_tri(st, mid3, cps[i], cps[(i + 1) % 6], Vector3.UP)
		for i in 6:
			var a: Vector3 = cps[i]
			var b: Vector3 = cps[(i + 1) % 6]
			var af := Vector3(a.x, FLOOR_Y, a.z)
			var bf := Vector3(b.x, FLOOR_Y, b.z)
			var e := ((a + b) * 0.5) - Vector3(ctr.x, 0.0, ctr.y)
			var outward := Vector3(e.x, 0.0, e.z).normalized()
			_tri(st, a, af, b, outward)
			_tri(st, b, af, bf, outward)
	st.index()
	return st.commit()


func _place_camera(cam: Camera3D, pitch_deg: float) -> void:
	var yaw := deg_to_rad(35.0)
	var pitch := deg_to_rad(pitch_deg)
	var target := Vector3(0.0, -0.2, 0.0)
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	cam.position = target + dir * 25.0
	cam.look_at(target, Vector3.UP)


func _render_variants() -> void:
	var cam := Camera3D.new()
	cam.fov = 45.0
	add_child(cam)
	var holder := MeshInstance3D.new()
	holder.material_override = mat
	add_child(holder)

	var variants := [
		{"name": "1-riser-shallow-0.15", "smooth": false, "step": 0.15, "pitch": 50.0},
		{"name": "2-riser-medium-0.35", "smooth": false, "step": 0.35, "pitch": 50.0},
		{"name": "3-riser-tall-0.70", "smooth": false, "step": 0.70, "pitch": 50.0},
		{"name": "4-riser-medium-loweye", "smooth": false, "step": 0.35, "pitch": 22.0},
		{"name": "5-slope-medium-0.35", "smooth": true, "step": 0.35, "pitch": 50.0},
		{"name": "6-slope-tall-0.70", "smooth": true, "step": 0.70, "pitch": 50.0},
	]
	for v in variants:
		holder.mesh = _build_mesh(v["smooth"], v["step"])
		_place_camera(cam, v["pitch"])
		for _i in 4:
			await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path: String = out_dir + "/" + String(v["name"]) + ".png"
		var err := img.save_png(path)
		print("saved ", path, " err=", err)
