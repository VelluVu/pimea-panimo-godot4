shader_type canvas_item;

// The cellar's constant mood over the world, under the GUI: a faint dithered vignette and
// a film grain that changes a few times a second instead of every frame, so the pixel art
// doesn't crawl. Kept light, so the LVV pressure edges still read as a warning.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.22;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.025;
uniform float grain_fps : hint_range(1.0, 30.0) = 8.0;
uniform float dither_levels : hint_range(1.0, 16.0, 1.0) = 3.0;

const float BAYER_4X4[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

// FRAGCOORD steps one game pixel at a time, the game renders at its base resolution.
float dithered(float value, vec2 pixel) {
	ivec2 cell = ivec2(mod(pixel, 4.0));
	float threshold = (BAYER_4X4[cell.y * 4 + cell.x] + 0.5) / 16.0;
	return clamp(floor(value * dither_levels + threshold) / dither_levels, 0.0, 1.0);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 scene = texture(screen_texture, SCREEN_UV).rgb;
	vec2 pixel = floor(FRAGCOORD.xy);
	vec2 centered = (SCREEN_UV - 0.5) * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float vignette = dithered(smoothstep(0.45, 1.05, length(centered)), pixel) * vignette_strength;
	float grain = (hash(pixel + floor(TIME * grain_fps) * 17.0) - 0.5) * grain_strength;
	COLOR = vec4(scene * (1.0 - vignette) + grain, 1.0);
}
