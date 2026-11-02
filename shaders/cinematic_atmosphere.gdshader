shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_radius : hint_range(0.1, 1.5) = 0.85;
uniform vec4 biome_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float biome_tint_strength : hint_range(0.0, 1.0) = 0.0;
uniform float grain_amount : hint_range(0.0, 0.1) = 0.02;
uniform float ca_offset : hint_range(0.0, 0.03) = 0.0;
uniform float low_hp_pulse : hint_range(0.0, 1.0) = 0.0;

// High-frequency pseudo-random generator for film grain
float random(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	vec2 diff = SCREEN_UV - center;
	float dist = length(diff);

	// 1. Radial Chromatic Aberration
	vec2 ca_dir = dist > 0.0001 ? normalize(diff) : vec2(0.0);
	float r = texture(screen_texture, SCREEN_UV + ca_dir * ca_offset * dist).r;
	float g = texture(screen_texture, SCREEN_UV).g;
	float b = texture(screen_texture, SCREEN_UV - ca_dir * ca_offset * dist).b;
	vec3 color = vec3(r, g, b);

	// 2. Dynamic Biome Tint
	color = mix(color, color * biome_tint.rgb, biome_tint_strength);

	// 3. Cinematic Vignette
	float vignette = smoothstep(vignette_radius, max(0.0, vignette_radius - 0.45), dist);
	color *= mix(1.0 - vignette_intensity, 1.0, vignette);

	// 4. Low HP Heartbeat Pulsing Border
	if (low_hp_pulse > 0.001) {
		float heartbeat = pow(max(0.0, sin(TIME * 5.0)), 3.0) + 0.5 * pow(max(0.0, sin(TIME * 5.0 + 1.2)), 4.0);
		float pulse_factor = heartbeat * low_hp_pulse;
		float edge_mask = smoothstep(0.3, 0.85, dist);
		vec3 blood_red = vec3(1.4, 0.05, 0.05); // Pulsing HDR red vignette
		color = mix(color, blood_red * color + blood_red * 0.15, edge_mask * pulse_factor);
	}

	// 5. Film Grain
	if (grain_amount > 0.0) {
		float grain = (random(SCREEN_UV + vec2(TIME * 13.7, TIME * 41.3)) - 0.5) * 2.0;
		color += grain * grain_amount;
	}

	COLOR = vec4(color, 1.0);
}
