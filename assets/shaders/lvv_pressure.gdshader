shader_type canvas_item;

// LVV pressure over the cellar, drawn by a full-screen ColorRect under the GUI.
// As the risk nears the raid threshold the edges go cold, grey and dark, and breathe
// close to the limit; during a raid red and blue siren light swaps between the sides.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec4 cold_tint_color : source_color = vec4(0.45, 0.55, 0.85, 1.0);
uniform vec4 siren_red_color : source_color = vec4(1.0, 0.12, 0.08, 1.0);
uniform vec4 siren_blue_color : source_color = vec4(0.12, 0.3, 1.0, 1.0);
uniform float pressure : hint_range(0.0, 1.0) = 0.0;
uniform float siren : hint_range(0.0, 1.0) = 0.0;
uniform float max_darkening : hint_range(0.0, 1.0) = 0.45;
uniform float max_desaturation : hint_range(0.0, 1.0) = 0.6;
uniform float siren_strength : hint_range(0.0, 1.0) = 0.35;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.2;
uniform float siren_speed : hint_range(0.0, 10.0) = 1.6;
// Gradients step through this many dithered levels, so they read like the pixel art.
uniform float dither_levels : hint_range(1.0, 16.0, 1.0) = 4.0;

const float BAYER_4X4[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

// The game renders at its base resolution, so FRAGCOORD steps one game pixel at a time.
float dithered(float value, vec2 pixel) {
	ivec2 cell = ivec2(mod(pixel, 4.0));
	float threshold = (BAYER_4X4[cell.y * 4 + cell.x] + 0.5) / 16.0;
	return clamp(floor(value * dither_levels + threshold) / dither_levels, 0.0, 1.0);
}

void fragment() {
	vec3 scene = texture(screen_texture, SCREEN_UV).rgb;
	// Aspect-corrected, so the vignette is round on the wide screen.
	vec2 centered = (SCREEN_UV - 0.5) * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float edge = smoothstep(0.3, 0.95, length(centered));
	// The breathing only starts near the threshold, so moderate risk stays still.
	float pulse = 1.0 + 0.25 * sin(TIME * pulse_speed) * smoothstep(0.7, 1.0, pressure);
	float amount = dithered(clamp(edge * pressure * pulse, 0.0, 1.0), FRAGCOORD.xy);

	float grey = dot(scene, vec3(0.299, 0.587, 0.114));
	vec3 result = mix(scene, vec3(grey), amount * max_desaturation);
	result = mix(result, result * cold_tint_color.rgb, amount);
	result *= 1.0 - amount * max_darkening;

	float swap = 0.5 + 0.5 * sin(TIME * siren_speed * TAU);
	float left = 1.0 - smoothstep(0.0, 0.5, SCREEN_UV.x);
	float right = smoothstep(0.5, 1.0, SCREEN_UV.x);
	float red_side = dithered(mix(left, right, swap), FRAGCOORD.xy);
	float blue_side = dithered(mix(right, left, swap), FRAGCOORD.xy);
	// Colour from the siren, brightness from the pixel: where red and blue overlap the
	// light turns purple instead of adding up to white.
	float weight = max(red_side, blue_side) * siren;
	vec3 hue = (siren_red_color.rgb * red_side + siren_blue_color.rgb * blue_side) / max(red_side + blue_side, 0.0001);
	float darkness = (1.0 - grey) * (1.0 - grey);
	result = mix(result, grey * 1.5 * hue, weight * 0.6) + hue * weight * siren_strength * darkness;

	COLOR = vec4(result, 1.0);
}
