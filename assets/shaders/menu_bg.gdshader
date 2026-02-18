shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.03, 0.02, 0.07, 1.0);
uniform vec4 color_mid : source_color = vec4(0.06, 0.04, 0.12, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.04, 0.02, 0.08, 1.0);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	// Three-point vertical gradient
	vec4 col;
	if (UV.y < 0.5) {
		col = mix(color_top, color_mid, UV.y * 2.0);
	} else {
		col = mix(color_mid, color_bottom, (UV.y - 0.5) * 2.0);
	}

	// Subtle stars
	vec2 grid = floor(UV * vec2(100.0, 50.0));
	float h = hash(grid);
	if (h > 0.92) {
		float twinkle = 0.4 + 0.6 * sin(TIME * (0.5 + h * 2.0) + h * 6.28);
		vec2 cell_uv = fract(UV * vec2(100.0, 50.0));
		float d = length(cell_uv - vec2(0.5));
		float star = smoothstep(0.12, 0.0, d) * twinkle * 0.3;
		col.rgb += vec3(star);
	}

	// Vignette
	vec2 vig_uv = UV * 2.0 - 1.0;
	float vig = 1.0 - dot(vig_uv, vig_uv) * vignette_strength;
	col.rgb *= vig;

	COLOR = col;
}
