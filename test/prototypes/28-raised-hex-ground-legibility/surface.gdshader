// Shared surface shader for every textured 3D mesh in the project.
//
// Godot has no project-wide 3D texture filter -- it is BaseMaterial3D.texture_filter,
// per material -- so baking the filter into the sampler hint here is what stops the
// pixel-mosaic look drifting one material at a time.
//
// Writes only ALBEDO: a spatial shader with no light() function still gets Godot's
// built-in lighting, shadows and ambient contribution, which terrain growing out of
// the board needs in order to read its height. Deliberately not unshaded.
shader_type spatial;

uniform sampler2D albedo_texture : source_color, filter_nearest_mipmap;


void fragment() {
	ALBEDO = texture(albedo_texture, UV).rgb;
}
