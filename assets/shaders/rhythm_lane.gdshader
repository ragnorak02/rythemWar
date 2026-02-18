shader_type canvas_item;

uniform vec4 lane_color : source_color = vec4(0.1, 0.1, 0.18, 0.6);
uniform vec4 beat_color : source_color = vec4(0.3, 0.3, 0.45, 0.3);
uniform float scroll_speed : hint_range(0.0, 200.0) = 80.0;
uniform float beat_spacing : hint_range(10.0, 200.0) = 100.0;
uniform float edge_glow : hint_range(0.0, 1.0) = 0.15;

void fragment() {
	// Base lane color with vertical gradient
	float vert_grad = smoothstep(0.0, 0.15, UV.y) * smoothstep(1.0, 0.85, UV.y);
	vec4 base = lane_color;
	base.a *= vert_grad;

	// Scrolling beat markers
	float world_x = UV.x * 800.0 + TIME * scroll_speed;
	float beat_line = smoothstep(2.0, 0.0, mod(world_x, beat_spacing));
	vec4 beats = beat_color * beat_line;

	// Top/bottom edge glow
	float edge_top = smoothstep(0.15, 0.0, UV.y);
	float edge_bot = smoothstep(0.85, 1.0, UV.y);
	float edge = (edge_top + edge_bot) * edge_glow;

	COLOR = base + beats + vec4(vec3(0.4, 0.5, 0.8) * edge, edge * 0.3);
}
