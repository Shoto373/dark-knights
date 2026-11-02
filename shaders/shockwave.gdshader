shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec2 center = vec2(0.5, 0.5);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float wave_size : hint_range(0.0, 0.8) = 0.25;
uniform float wave_thickness : hint_range(0.0, 0.2) = 0.04;
uniform float wave_force : hint_range(0.0, 0.2) = 0.05;

void fragment() {
	if (progress <= 0.0 || progress >= 1.0) {
		COLOR = texture(screen_texture, SCREEN_UV);
	} else {
		// Aspect ratio correction so the shockwave ring is circular on all screen resolutions
		vec2 diff = SCREEN_UV - center;
		float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
		vec2 scaled_diff = vec2(diff.x * aspect, diff.y);
		float dist = length(scaled_diff);

		float current_radius = progress * wave_size;
		float half_thickness = wave_thickness * 0.5;

		// Check if fragment is within the ring of the shockwave
		if (dist >= current_radius - half_thickness && dist <= current_radius + half_thickness && dist > 0.0001) {
			// Smooth sine curve across the thickness of the wave
			float wave_dist = (dist - current_radius) / half_thickness; // Normalized -1.0 to 1.0
			float wave = cos(wave_dist * 1.57079632679); // Peak at 1.0 in the center of the ring
			
			// Normalized refraction direction pointing radially outward
			vec2 dir = normalize(diff);
			
			// Wave force fades out gracefully as progress reaches 1.0
			float fade = 1.0 - smoothstep(0.0, 1.0, progress);
			vec2 offset = dir * wave * wave_force * fade;
			
			// Subtle chromatic aberration for explosive impact
			float r = texture(screen_texture, SCREEN_UV - offset * 1.15).r;
			float g = texture(screen_texture, SCREEN_UV - offset).g;
			float b = texture(screen_texture, SCREEN_UV - offset * 0.85).b;
			
			// Specular optical compression highlight at wavefront
			vec3 col = vec3(r, g, b) + vec3(0.1) * wave * fade;
			COLOR = vec4(col, 1.0);
		} else {
			COLOR = texture(screen_texture, SCREEN_UV);
		}
	}
}
