shader_type canvas_item;

uniform vec4 sky_top : source_color = vec4(0.02, 0.01, 0.06, 1.0);
uniform vec4 sky_bottom : source_color = vec4(0.08, 0.05, 0.15, 1.0);
uniform vec4 ground_color : source_color = vec4(0.04, 0.03, 0.08, 1.0);
uniform float ground_line : hint_range(0.0, 1.0) = 0.6;
uniform float star_density : hint_range(0.0, 1.0) = 0.5;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	// Sky gradient
	vec4 sky = mix(sky_top, sky_bottom, UV.y);

	// Stars (only in sky area)
	float stars = 0.0;
	if (UV.y < ground_line) {
		vec2 grid = floor(UV * vec2(120.0, 60.0));
		float h = hash(grid);
		if (h > (1.0 - star_density * 0.15)) {
			float twinkle = 0.5 + 0.5 * sin(TIME * (1.0 + h * 3.0) + h * 6.28);
			vec2 cell_uv = fract(UV * vec2(120.0, 60.0));
			float d = length(cell_uv - vec2(0.5));
			stars = smoothstep(0.15, 0.0, d) * twinkle * h;
		}
	}

	// Ground plane with subtle horizon glow
	float ground_mask = smoothstep(ground_line - 0.02, ground_line + 0.02, UV.y);
	vec4 ground = ground_color * ground_mask;
	float horizon_glow = smoothstep(0.05, 0.0, abs(UV.y - ground_line)) * 0.15;
	vec4 horizon = vec4(0.3, 0.2, 0.5, horizon_glow);

	COLOR = sky * (1.0 - ground_mask) + ground + horizon + vec4(vec3(stars), stars * 0.8);
}
