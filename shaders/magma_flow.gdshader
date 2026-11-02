shader_type canvas_item;

uniform float speed : hint_range(0.01, 2.0) = 0.25;
uniform float noise_scale : hint_range(1.0, 50.0) = 8.0;
uniform vec4 crust_color : source_color = vec4(0.09, 0.07, 0.08, 1.0);
uniform vec4 lava_color_hot : source_color = vec4(3.5, 1.4, 0.3, 1.0); // Blazing HDR bloom emission > 1.2
uniform vec4 lava_color_dark : source_color = vec4(1.5, 0.3, 0.05, 1.0); // Rich glowing ember red
uniform float crust_threshold : hint_range(0.1, 0.9) = 0.52;
uniform float crust_softness : hint_range(0.01, 0.3) = 0.08;
uniform float pulse_speed : hint_range(0.1, 10.0) = 2.0;
uniform float bubble_strength : hint_range(0.0, 2.0) = 0.6;

// Fast pseudo-random gradient hash
vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// 2D Gradient Noise
float gnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(mix(dot(hash2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
	               dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
	           mix(dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
	               dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
}

// Fractal Brownian Motion (FBM)
float fbm(vec2 p) {
	float total = 0.0;
	float amp = 0.5;
	vec2 shift = vec2(100.0);
	mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.5)));
	for (int i = 0; i < 4; i++) {
		total += amp * gnoise(p);
		p = rot * p * 2.0 + shift;
		amp *= 0.5;
	}
	return total;
}

// Voronoi / cellular for crust plate fracturing
vec2 voronoi(vec2 p) {
	vec2 n = floor(p);
	vec2 f = fract(p);
	float md = 8.0;
	vec2 mr = vec2(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = hash2(n + g) * 0.5 + 0.5;
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < md) {
				md = d;
				mr = r;
			}
		}
	}
	return vec2(sqrt(md), length(mr));
}

void fragment() {
	vec2 uv = UV * noise_scale;
	float t = TIME * speed;

	// Viscous fluid domain warping
	vec2 q = vec2(fbm(uv + vec2(t * 0.4, -t * 0.2)), fbm(uv + vec2(-t * 0.3, t * 0.5)));
	vec2 r = vec2(fbm(uv + 3.0 * q + vec2(1.7, 9.2) + t * 0.15),
	              fbm(uv + 3.0 * q + vec2(8.3, 2.8) - t * 0.2));
	float flow_noise = fbm(uv + 2.5 * r);

	// Plate cracks (Voronoi cell edges warped by flow)
	vec2 v = voronoi(uv * 0.6 + q * 1.5 + vec2(t * 0.1, t * 0.05));
	float cell_dist = v.x;

	// Blend cellular cracks and warped fluid rivers
	float crack_val = mix(cell_dist, (flow_noise * 0.5 + 0.5), 0.45);

	// Edge pulsing heat glow
	float pulse = 0.85 + 0.25 * sin(TIME * pulse_speed + uv.x * 2.0 + uv.y * 2.0);

	// Magma bubbling: small bursting incandescent spots
	vec2 bubble_uv = uv * 2.2 + vec2(t * 0.6, -t * 0.4);
	float b_noise = gnoise(bubble_uv);
	float bubble = smoothstep(0.55, 0.8, b_noise * sin(TIME * 4.0 + b_noise * 6.28)) * bubble_strength;

	// Lava molten gradient (dark lava -> blistering hot HDR core)
	float lava_heat = clamp((1.0 - crack_val * 1.3) + bubble, 0.0, 1.0);
	vec4 molten_color = mix(lava_color_dark, lava_color_hot, lava_heat) * pulse;

	// Basalt crust mask
	float crust_mask = smoothstep(crust_threshold - crust_softness, crust_threshold + crust_softness, crack_val);

	// Crust basalt texture with subtle roughness
	float crust_grain = gnoise(uv * 3.0) * 0.05;
	vec4 crust = crust_color + vec4(crust_grain, crust_grain, crust_grain, 0.0);

	// Blending crust over glowing molten magma
	vec4 final_color = mix(molten_color, crust, crust_mask);

	// Glowing heat seam along crust borders
	float edge_heat = smoothstep(0.0, 0.15, abs(crack_val - crust_threshold));
	final_color.rgb += lava_color_hot.rgb * (1.0 - edge_heat) * 0.4 * pulse;

	COLOR = vec4(final_color.rgb, 1.0);
}
