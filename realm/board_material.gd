class_name BoardMaterial
extends RefCounted
## The board's material. A deliberate placeholder for deferred art: the authored per-domain
## look and the authored depth-4 "maxed" look both replace this. It only has to render.

const TEXTURE_SIZE := 8


static func create() -> ShaderMaterial:
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	for y in TEXTURE_SIZE:
		for x in TEXTURE_SIZE:
			var shade := 0.62 if (x + y) % 2 == 0 else 0.55
			image.set_pixel(x, y, Color(shade, shade * 0.95, shade * 0.9))
	image.generate_mipmaps()
	var material := ShaderMaterial.new()
	material.shader = load("res://common/surface.gdshader")
	material.set_shader_parameter("albedo_texture", ImageTexture.create_from_image(image))
	return material
