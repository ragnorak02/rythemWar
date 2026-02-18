shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.94, 0.78, 0.31, 1.0);
uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform float border_width : hint_range(0.0, 0.1) = 0.02;

void fragment() {
	float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);

	// Soft fill
	float fill_alpha = 0.08 + 0.07 * pulse;

	// Border glow on edges
	float edge_l = smoothstep(border_width, 0.0, UV.x);
	float edge_r = smoothstep(1.0 - border_width, 1.0, UV.x);
	float edge_t = smoothstep(border_width, 0.0, UV.y);
	float edge_b = smoothstep(1.0 - border_width, 1.0, UV.y);
	float edge = max(max(edge_l, edge_r), max(edge_t, edge_b));
	float border_alpha = edge * (0.4 + 0.3 * pulse);

	float alpha = fill_alpha + border_alpha;
	COLOR = vec4(glow_color.rgb, alpha);
}
