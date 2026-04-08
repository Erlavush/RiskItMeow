shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 light_color : source_color = vec4(0.68, 0.68, 0.68, 1.0);
uniform vec4 dark_color : source_color = vec4(0.12, 0.12, 0.12, 1.0);
uniform float checker_size = 1.0;
uniform vec2 checker_offset = vec2(0.0, 0.0);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.96;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 cell = floor((local_pos.xz + checker_offset + vec2(checker_size * 512.0)) / checker_size);
	float parity = mod(cell.x + cell.y, 2.0);
	vec4 color = mix(dark_color, light_color, parity);

	ALBEDO = color.rgb;
	ALPHA = color.a;
	ROUGHNESS = roughness_value;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
