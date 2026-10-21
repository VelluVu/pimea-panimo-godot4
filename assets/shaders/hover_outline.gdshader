shader_type canvas_item;
render_mode unshaded;

// 1-pixel outline around a CanvasGroup's combined silhouette, for clickable props.
// It fades in with the hover glow the props already tween: a modulate above 1
// (HOVER_GLOW_COLOR) reaches this shader as COLOR, so no script has to know about it.
// Unshaded, because the children were already lit when the group drew them.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 outline_color : source_color = vec4(1.0, 0.86, 0.5, 1.0);
uniform float glow_for_full_outline : hint_range(0.01, 1.0) = 0.3;

void fragment() {
	vec4 group = textureLod(screen_texture, SCREEN_UV, 0.0);
	// The group buffer is premultiplied.
	group.rgb /= max(group.a, 0.0001);
	float hover = clamp((max(COLOR.r, max(COLOR.g, COLOR.b)) - 1.0) / glow_for_full_outline, 0.0, 1.0);

	vec2 px = SCREEN_PIXEL_SIZE;
	float neighbours = max(
		max(textureLod(screen_texture, SCREEN_UV + vec2(px.x, 0.0), 0.0).a, textureLod(screen_texture, SCREEN_UV - vec2(px.x, 0.0), 0.0).a),
		max(textureLod(screen_texture, SCREEN_UV + vec2(0.0, px.y), 0.0).a, textureLod(screen_texture, SCREEN_UV - vec2(0.0, px.y), 0.0).a));
	float edge = step(0.5, neighbours) * (1.0 - step(0.5, group.a)) * hover;

	COLOR = mix(group, outline_color, edge);
}
