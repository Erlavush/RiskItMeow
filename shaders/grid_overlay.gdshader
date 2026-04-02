shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec4 grid_color : source_color = vec4(0.95, 0.97, 1.0, 0.82);
uniform float grid_size = 1.0;
uniform float line_width = 0.05;
uniform float dot_length = 0.24;
uniform float dot_gap = 0.18;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float line_mask(float axis_value) {
	float distance_to_line = abs((fract((axis_value / grid_size) + 0.5) - 0.5) * grid_size);
	return 1.0 - step(line_width, distance_to_line);
}

float dash_mask(float along_value) {
	float period = max(0.001, dot_length + dot_gap);
	float repeated = mod(along_value + period * 4096.0, period);
	return 1.0 - step(dot_length, repeated);
}

void fragment() {
	float vertical = line_mask(local_pos.x) * dash_mask(local_pos.z);
	float horizontal = line_mask(local_pos.z) * dash_mask(local_pos.x);
	float alpha = max(vertical, horizontal) * grid_color.a;

	ALBEDO = grid_color.rgb;
	ALPHA = alpha;
}
