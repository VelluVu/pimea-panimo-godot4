shader_type canvas_item;

// Snow the wind blows in through the open winter door. Each flake leaves the doorway on a
// gust, arcs down onto a stair tread (mostly the top ones), lies there and melts into a wet
// spot within a few seconds. Positions are floored to whole pixels, so flakes step pixel by
// pixel like the art. WinterDoor restarts `elapsed` each time the door opens.

uniform vec4 snow_color : source_color = vec4(0.86, 0.92, 0.97, 1.0);
uniform vec4 slush_color : source_color = vec4(0.55, 0.64, 0.72, 1.0);
uniform vec4 wet_color : source_color = vec4(0.04, 0.03, 0.06, 1.0);
// One pixel per tread from the top, in rect pixels: red * 255 = top row, green * 255 =
// left end, blue * 255 = right end (make_winter_door.py).
uniform sampler2D tread_map : filter_nearest, repeat_disable;
uniform int tread_count = 12;
uniform vec2 rect_size = vec2(100.0, 200.0);
// The doorway in rect pixels, where flakes start.
uniform vec2 door_min = vec2(80.0, 24.0);
uniform vec2 door_max = vec2(90.0, 58.0);
uniform float elapsed = 100.0;
// Flakes set off while the door is open.
uniform float open_seconds : hint_range(0.1, 5.0) = 1.2;
uniform float flight_speed : hint_range(5.0, 200.0) = 45.0;
// Above 1 most flakes land near the door, fewer further down the stairs.
uniform float near_door_bias : hint_range(1.0, 5.0) = 2.2;
// Rows of a tread's top face a flake can lie on, below its lit edge.
uniform float tread_depth : hint_range(1.0, 6.0) = 4.0;
uniform float flutter_px : hint_range(0.0, 4.0) = 1.5;
// Flakes are squares this many pixels across, picked per flake; from 3 up the corners are
// cut, so they read round.
uniform float min_flake_px : hint_range(1.0, 4.0, 1.0) = 2.0;
uniform float max_flake_px : hint_range(1.0, 4.0, 1.0) = 3.0;
uniform float melt_seconds : hint_range(0.5, 10.0) = 3.0;
uniform float wet_strength : hint_range(0.0, 1.0) = 0.45;

const int FLAKES = 64;

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

// 1 where `pixel` is part of a flake `size` pixels across centred on `pos`.
float covers(vec2 pixel, vec2 pos, float size) {
	vec2 d = pixel - floor(pos - (size - 1.0) * 0.5);
	float inside = step(0.0, d.x) * step(0.0, d.y) * step(d.x, size - 1.0) * step(d.y, size - 1.0);
	vec2 edge = min(d, size - 1.0 - d);
	float corner = step(edge.x, 0.5) * step(edge.y, 0.5) * step(2.5, size);
	return inside * (1.0 - corner);
}

void fragment() {
	vec2 pixel = floor(UV * rect_size);
	vec4 snow = vec4(0.0);
	float wet = 0.0;
	for (int i = 0; i < FLAKES; i++) {
		float seed = float(i) + 1.0;
		float t = elapsed - hash(seed) * open_seconds;
		vec2 start = vec2(mix(door_min.x, door_max.x, hash(seed + 0.31)),
				mix(door_min.y, door_max.y, hash(seed + 0.57)));
		int tread_index = min(int(pow(hash(seed + 0.71), near_door_bias) * float(tread_count)), tread_count - 1);
		vec3 tread = texelFetch(tread_map, ivec2(tread_index, 0), 0).rgb * 255.0;
		vec2 land = vec2(floor(mix(tread.g + 1.0, tread.b - 1.0, hash(seed + 0.83))),
				tread.r + floor(hash(seed + 0.13) * tread_depth));
		float flight = 0.3 + distance(start, land) / flight_speed;

		// The gust carries a flake out first, then it drops: x eases out, y eases in.
		float s = clamp(t / flight, 0.0, 1.0);
		float flutter = sin(t * 6.0 + hash(seed + 0.19) * 6.283) * flutter_px * s * (1.0 - s) * 4.0;
		vec2 pos = vec2(mix(start.x, land.x, 1.0 - (1.0 - s) * (1.0 - s)) + flutter,
				mix(start.y, land.y, mix(s, s * s, 0.6)));

		float started = step(0.0, t);
		float flying = started * (1.0 - step(flight, t));
		float melt = clamp((t - flight) / melt_seconds, 0.0, 1.0);
		float lying = step(flight, t) * (1.0 - step(1.0, melt));

		float size = floor(mix(min_flake_px, max_flake_px + 0.999, hash(seed + 0.47)));
		float in_air = flying * covers(pixel, pos, size);
		float on_tread = lying * covers(pixel, land, size);
		vec4 settled = vec4(mix(snow_color.rgb, slush_color.rgb, melt), 1.0 - melt * melt);
		snow = mix(snow, snow_color, in_air);
		snow = mix(snow, settled, on_tread * (1.0 - snow.a));
		// The melt water darkens the tread under the flake and beside it.
		vec2 spot = abs(pixel - land);
		float under = (1.0 - step(size * 0.5 + 1.0, spot.x)) * (1.0 - step(size * 0.5, spot.y));
		wet = max(wet, lying * under * melt * (1.0 - melt) * 4.0);
	}
	float wet_alpha = min(wet, 1.0) * wet_strength * (1.0 - snow.a);
	COLOR = vec4(mix(wet_color.rgb, snow.rgb, snow.a), max(snow.a, wet_alpha));
}
