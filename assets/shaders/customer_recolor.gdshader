shader_type canvas_item;

// Palette-swap recolor for pixel-art customer sprites. For each region, pixels
// whose hue/saturation are close to *_base_color get remapped to *_target_color's
// hue/saturation while keeping the pixel's own value (so painted shading/highlights
// are preserved). *_base_color must match the actual color painted in the sprite
// for that region; *_target_color is set per customer instance for variety.

group_uniforms skin;
uniform vec4 skin_base_color : source_color = vec4(0.918, 0.831, 0.667, 1.0);
uniform vec4 skin_target_color : source_color = vec4(0.918, 0.831, 0.667, 1.0);

group_uniforms hair;
uniform vec4 hair_base_color : source_color = vec4(0.722, 0.435, 0.314, 1.0);
uniform vec4 hair_target_color : source_color = vec4(0.722, 0.435, 0.314, 1.0);

group_uniforms clothes;
uniform vec4 clothes_base_color : source_color = vec4(0.0, 0.6, 0.859, 1.0);
uniform vec4 clothes_target_color : source_color = vec4(0.0, 0.6, 0.859, 1.0);

group_uniforms shoes;
uniform vec4 shoes_base_color : source_color = vec4(0.451, 0.243, 0.224, 1.0);
uniform vec4 shoes_target_color : source_color = vec4(0.451, 0.243, 0.224, 1.0);

group_uniforms match_tuning;
uniform float hue_tolerance : hint_range(0.0, 0.5) = 0.05;
uniform float saturation_tolerance : hint_range(0.0, 1.0) = 0.35;

varying vec3 skin_base_hsv;
varying vec3 skin_target_hsv;
varying vec3 hair_base_hsv;
varying vec3 hair_target_hsv;
varying vec3 clothes_base_hsv;
varying vec3 clothes_target_hsv;
varying vec3 shoes_base_hsv;
varying vec3 shoes_target_hsv;

vec3 rgb2hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
	return c.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), c.y);
}

float hue_distance(float a, float b) {
	float d = abs(a - b);
	return min(d, 1.0 - d);
}

vec3 apply_region_recolor(vec3 color, vec3 base_hsv, vec3 target_hsv, float hue_tol, float sat_tol, inout float consumed_mask) {
	vec3 pixel_hsv = rgb2hsv(color);
	float hd = hue_distance(pixel_hsv.x, base_hsv.x);
	float sd = abs(pixel_hsv.y - base_hsv.y);
	float matched = (1.0 - step(hue_tol, hd)) * (1.0 - step(sat_tol, sd)) * (1.0 - consumed_mask);
	vec3 recolored = hsv2rgb(vec3(target_hsv.x, target_hsv.y, pixel_hsv.z));
	consumed_mask = max(consumed_mask, matched);
	return mix(color, recolored, matched);
}

void vertex() {
	skin_base_hsv = rgb2hsv(skin_base_color.rgb);
	skin_target_hsv = rgb2hsv(skin_target_color.rgb);
	hair_base_hsv = rgb2hsv(hair_base_color.rgb);
	hair_target_hsv = rgb2hsv(hair_target_color.rgb);
	clothes_base_hsv = rgb2hsv(clothes_base_color.rgb);
	clothes_target_hsv = rgb2hsv(clothes_target_color.rgb);
	shoes_base_hsv = rgb2hsv(shoes_base_color.rgb);
	shoes_target_hsv = rgb2hsv(shoes_target_color.rgb);
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec3 result = tex_color.rgb;
	float consumed = 0.0;
	result = apply_region_recolor(result, skin_base_hsv, skin_target_hsv, hue_tolerance, saturation_tolerance, consumed);
	result = apply_region_recolor(result, hair_base_hsv, hair_target_hsv, hue_tolerance, saturation_tolerance, consumed);
	result = apply_region_recolor(result, clothes_base_hsv, clothes_target_hsv, hue_tolerance, saturation_tolerance, consumed);
	result = apply_region_recolor(result, shoes_base_hsv, shoes_target_hsv, hue_tolerance, saturation_tolerance, consumed);
	COLOR = vec4(result, tex_color.a);
}
