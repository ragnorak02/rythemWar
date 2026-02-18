shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.5, 0.5, 0.7, 0.6);
uniform float glow_radius : hint_range(0.0, 1.0) = 0.3;
uniform float shimmer_speed : hint_range(0.0, 5.0) = 1.5;

void fragment() {
	float dist = abs(UV.y - 0.5) * 2.0;

	// Core line
	float core = smoothstep(0.15, 0.0, dist);

	// Outer glow
	float glow = smoothstep(1.0, 0.0, dist) * glow_radius;

	// Horizontal shimmer
	float shimmer = 0.7 + 0.3 * sin(UV.x * 10.0 + TIME * shimmer_speed);

	float alpha = (core + glow) * shimmer * line_color.a;
	COLOR = vec4(line_color.rgb, alpha);
}
