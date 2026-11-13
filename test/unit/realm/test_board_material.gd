extends GutTest
## The board's placeholder material. Art is deferred; this only has to render.

func test_it_uses_the_shared_surface_shader() -> void:
	var material := BoardMaterial.create()
	assert_eq(material.shader, load("res://common/surface.gdshader"))


func test_it_supplies_the_albedo_texture_the_shader_samples() -> void:
	assert_not_null(BoardMaterial.create().get_shader_parameter("albedo_texture"))
