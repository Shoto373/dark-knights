shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 burn_color : source_color = vec4(2.5, 0.9, 0.1, 1.0); // HDR glow for Vulkan bloom!
uniform float burn_size : hint_range(0.0, 0.2) = 0.06;
uniform float noise_scale : hint_range(1.0, 50.0) = 14.0;
uniform sampler2D noise_texture : hint_default_white;
uniform bool use_noise_texture = false;

// Pseudo-random gradient hash
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

// Procedural multi-octave FBM noise
float fbm(vec2 p) {
	float total = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 3; i++) {
		total += amp * (gnoise(p) * 0.5 + 0.5);
		p *= 2.05;
		amp *= 0.5;
	}
	return total;
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Skip transparent pixels
	if (tex_color.a <= 0.001) {
		discard;
	}

	// Calculate noise value normalized to 0.0 - 1.0
	float noise_val = 0.0;
	if (use_noise_texture) {
		noise_val = texture(noise_texture, UV).r;
	} else {
		noise_val = fbm(UV * noise_scale);
	}

	// Discard dissolved pixels
	if (noise_val < progress) {
		discard;
	}

	// Blazing HDR burn edge
	if (noise_val < progress + burn_size) {
		float edge = (noise_val - progress) / max(0.0001, burn_size); // 0.0 at edge, 1.0 inward
		vec3 fiery_edge = mix(vec3(3.5, 3.2, 2.0), burn_color.rgb, edge);
		tex_color.rgb = mix(fiery_edge, tex_color.rgb, edge * edge);
	}

	COLOR = tex_color;
}
