shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float distortion_strength : hint_range(0.0, 0.05) = 0.015;
uniform float speed : hint_range(0.0, 5.0) = 1.8;
uniform float frequency : hint_range(1.0, 30.0) = 14.0;
uniform float noise_scale : hint_range(1.0, 40.0) = 10.0;
uniform bool edge_feather = true;

// Fast noise hash
vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// 2D Gradient noise
float gnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(mix(dot(hash2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
	               dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
	           mix(dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
	               dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	float t = TIME * speed;

	// Sine wave combined with ascending procedural noise
	vec2 moving_uv = UV * noise_scale + vec2(0.0, -t);
	float n = gnoise(moving_uv);
	
	// Transverse sine wave displacement
	float sine_wave = sin((UV.y * frequency) - (t * 2.5) + n * 2.0);
	
	// Distortion offset vector (horizontal shimmering + vertical turbulence)
	vec2 distortion = vec2(sine_wave * 0.7 + n * 0.3, n * 0.5) * distortion_strength;

	// Edge feathering to blend seamlessly with surroundings
	float mask = 1.0;
	if (edge_feather) {
		float feather_x = smoothstep(0.0, 0.2, UV.x) * smoothstep(1.0, 0.8, UV.x);
		float feather_y = smoothstep(0.0, 0.2, UV.y) * smoothstep(1.0, 0.8, UV.y);
		mask = feather_x * feather_y;
	}

	// Apply distortion to SCREEN_UV
	vec2 distorted_screen_uv = SCREEN_UV + distortion * mask;
	
	// Sample background screen texture
	vec4 screen_col = texture(screen_texture, distorted_screen_uv);

	// Subtle warm tint in the heat column
	vec3 warm_tint = vec3(1.04, 1.01, 0.97);
	screen_col.rgb *= mix(vec3(1.0), warm_tint, mask * 0.3);

	COLOR = screen_col;
}
