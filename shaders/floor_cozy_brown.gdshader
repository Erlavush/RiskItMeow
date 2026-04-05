shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D floor_texture : source_color, repeat_enable, filter_nearest;
uniform vec2 uv_scale = vec2(8.0, 8.0);
uniform vec4 side_color : source_color = vec4(0.133, 0.051, 0.016, 1.0);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.98;

varying vec3 local_normal;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

void vertex() {
	local_normal = NORMAL;
}

void fragment() {
	vec3 color = side_color.rgb;

	if (local_normal.y > 0.5) {
		vec2 tiled_uv = UV * uv_scale;
		vec2 tile_id = floor(tiled_uv);
		vec2 tile_uv = fract(tiled_uv);
		float rotation_step = floor(hash21(tile_id + vec2(17.0, 53.0)) * 4.0);
		vec2 rotated_uv = tile_uv;

		if (rotation_step < 1.0) {
			rotated_uv = tile_uv;
		} else if (rotation_step < 2.0) {
			rotated_uv = vec2(1.0 - tile_uv.y, tile_uv.x);
		} else if (rotation_step < 3.0) {
			rotated_uv = vec2(1.0 - tile_uv.x, 1.0 - tile_uv.y);
		} else {
			rotated_uv = vec2(tile_uv.y, 1.0 - tile_uv.x);
		}

		color = texture(floor_texture, rotated_uv).rgb;
	}

	ALBEDO = color;
	ALPHA = 1.0;
	ROUGHNESS = roughness_value;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
