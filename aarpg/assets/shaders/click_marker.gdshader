shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded, depth_draw_never;

uniform vec4 color_center : source_color = vec4(1.0, 0.8, 1.0, 0.9);
uniform vec4 color_edge : source_color = vec4(1.0, 0.4, 0.8, 0.0);
uniform float expand : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.0, 0.5) = 0.08;

void fragment() {
	float dist = length(UV - vec2(0.5)) * 2.0;
	if (dist > expand || dist < dissolve || expand <= 0.0) {
		discard;
	}
	float ring_width = expand - dissolve;
	float t = (dist - dissolve) / max(ring_width, 0.001);
	vec4 col = mix(color_center, color_edge, t);
	float outer_fade = 1.0 - smoothstep(expand - softness, expand, dist);
	float inner_fade = dissolve <= 0.0 ? 1.0 : smoothstep(dissolve, dissolve + softness, dist);
	ALBEDO = col.rgb;
	ALPHA = col.a * outer_fade * inner_fade;
}
