shader_type spatial;
render_mode cull_back, depth_draw_opaque;

global uniform vec3 occlusion_reveal_player_pos;
global uniform float occlusion_reveal_time;

uniform float reveal_strength : hint_range(0.0, 1.0) = 0.0;
uniform float hole_radius : hint_range(0.1, 5.0) = 1.2;
uniform float melt_width : hint_range(0.05, 2.0) = 0.35;
uniform vec4 albedo_tint : source_color = vec4(0.6, 0.55, 0.5, 1.0);
uniform sampler2D albedo_tex : filter_linear_mipmap, repeat_enable;
uniform vec4 fire_color_hot : source_color = vec4(1.0, 0.45, 0.05, 1.0);
uniform vec4 fire_color_cool : source_color = vec4(0.85, 0.15, 0.02, 1.0);

varying vec3 v_world_pos;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float dist_xz = length(v_world_pos.xz - occlusion_reveal_player_pos.xz);
	float effective_radius = hole_radius * reveal_strength;

	if (reveal_strength > 0.01 && dist_xz < effective_radius) {
		discard;
	}

	vec4 base = texture(albedo_tex, UV) * albedo_tint;
	ALBEDO = base.rgb;
	ROUGHNESS = 0.85;
	METALLIC = 0.0;

	float edge = smoothstep(effective_radius, effective_radius + melt_width, dist_xz)
		* (1.0 - smoothstep(effective_radius + melt_width, effective_radius + melt_width * 2.0, dist_xz));
	float flicker = 0.65 + 0.35 * sin(occlusion_reveal_time * 9.0 + dist_xz * 6.0);
	float fire_noise = hash21(v_world_pos.xz * 2.5 + occlusion_reveal_time * 0.4);
	vec3 fire = mix(fire_color_cool.rgb, fire_color_hot.rgb, fire_noise) * edge * reveal_strength * flicker;
	EMISSION = fire;
}
