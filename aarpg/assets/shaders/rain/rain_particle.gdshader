shader_type spatial;
render_mode blend_add, depth_draw_disabled, cull_disabled, unshaded;

uniform vec4 streak_color : source_color = vec4(0.75, 0.82, 0.9, 0.35);

void fragment() {
	float alpha = streak_color.a * (1.0 - abs(UV.x - 0.5) * 2.0);
	ALBEDO = streak_color.rgb;
	ALPHA = alpha;
}
