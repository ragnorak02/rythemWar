shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform float pulse_speed : hint_range(1.0, 8.0) = 3.0;
uniform float glow_width : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	float dist = abs(UV.x - 0.5) * 2.0;
	float pulse = 0.7 + 0.3 * sin(TIME * pulse_speed);
	float core = smoothstep(0.3, 0.0, dist);
	float outer = smoothstep(1.0, 0.2, dist) * glow_width;
	float alpha = (core + outer) * pulse * glow_color.a;
	COLOR = vec4(glow_color.rgb, alpha);
}
