shader_type canvas_item;

// Steam rising off the brew day's kettle, kept pixel-strict: worked out per whole
// pixel of the rect, moving at a stepped frame rate, and shown only as solid pixels
// picked by a 4x4 Bayer dither instead of a smooth alpha fade. The rect's bottom edge
// sits on the liquid; intensity is set from the boil.

uniform vec4 steam_color : source_color = vec4(0.82, 0.84, 0.88, 0.85);
uniform vec4 steam_light : source_color = vec4(0.95, 0.96, 0.98, 0.9);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec2 rect_size = vec2(232.0, 170.0);
uniform float pixel_fps : hint_range(1.0, 30.0) = 10.0;
uniform float rise_speed : hint_range(0.0, 80.0) = 22.0;
uniform float noise_scale : hint_range(2.0, 64.0) = 14.0;
// The noise range stretched to full: the steam's puffs and the gaps between them.
uniform float puff_low : hint_range(0.0, 1.0) = 0.42;
uniform float puff_high : hint_range(0.0, 1.0) = 0.78;
// How far past the dither threshold a pixel must be to take the light colour.
uniform float light_margin : hint_range(0.0, 1.0) = 0.35;

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(cell);
	float b = hash(cell + vec2(1.0, 0.0));
	float c = hash(cell + vec2(0.0, 1.0));
	float d = hash(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 pixel = floor(UV * rect_size);
	float t = floor(TIME * pixel_fps) / pixel_fps;
	vec2 uv = pixel / rect_size;
	// 0 at the liquid, 1 at the top of the rect.
	float height = 1.0 - uv.y;
	// The pattern scrolls up and sways a little as it rises.
	vec2 p = vec2(pixel.x + sin(height * 6.0 + t * 1.5) * 4.0, pixel.y + t * rise_speed) / noise_scale;
	float n = value_noise(p) * 0.65 + value_noise(p * 2.1 + 17.0) * 0.35;
	// Puffs with gaps between them, not an even haze: the dither then draws clouds.
	n = smoothstep(puff_low, puff_high, n);
	float sides = 1.0 - smoothstep(0.32, 0.5, abs(uv.x - 0.5));
	float rise = smoothstep(0.0, 0.12, height) * (1.0 - smoothstep(0.15, 1.0, height));
	float density = n * sides * rise * intensity * 1.6;
	int index = int(mod(pixel.x, 4.0)) + int(mod(pixel.y, 4.0)) * 4;
	float threshold = (BAYER[index] + 0.5) / 16.0;
	float on = step(threshold, density);
	float light = step(threshold + light_margin, density);
	COLOR = mix(steam_color, steam_light, light) * on;
}
