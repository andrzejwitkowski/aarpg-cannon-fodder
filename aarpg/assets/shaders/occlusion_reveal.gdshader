shader_type spatial;
render_mode cull_back, depth_draw_opaque;

global uniform vec3 occlusion_reveal_player_pos;
global uniform float occlusion_reveal_time;

uniform float reveal_strength : hint_range(0.0, 1.0) = 0.0;
uniform float reveal_discard_threshold : hint_range(0.0, 0.2) = 0.01;
uniform float hole_radius : hint_range(0.1, 5.0) = 1.2;
uniform float melt_width : hint_range(0.05, 2.0) = 0.35;
uniform float melt_outer_scale : hint_range(1.0, 4.0) = 2.0;
uniform vec4 albedo_tint : source_color = vec4(0.6, 0.55, 0.5, 1.0);
uniform sampler2D albedo_tex : filter_linear_mipmap, repeat_enable;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fire_color_hot : source_color = vec4(1.0, 0.45, 0.05, 1.0);
uniform vec4 fire_color_cool : source_color = vec4(0.85, 0.15, 0.02, 1.0);
uniform float fire_flicker_min : hint_range(0.0, 1.0) = 0.65;
uniform float fire_flicker_amplitude : hint_range(0.0, 1.0) = 0.35;
uniform float fire_flicker_speed : hint_range(0.0, 30.0) = 9.0;
uniform float fire_flicker_wave_scale : hint_range(0.0, 20.0) = 6.0;
uniform float fire_noise_scale : hint_range(0.0, 10.0) = 2.5;
uniform float fire_noise_speed : hint_range(0.0, 5.0) = 0.4;

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

	if (reveal_strength > reveal_discard_threshold && dist_xz < effective_radius) {
		discard;
	}

	vec4 base = texture(albedo_tex, UV) * albedo_tint;
	ALBEDO = base.rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;

	float melt_outer = effective_radius + melt_width;
	float melt_far = melt_outer + melt_width * melt_outer_scale;
	float edge = smoothstep(effective_radius, melt_outer, dist_xz)
		* (1.0 - smoothstep(melt_outer, melt_far, dist_xz));
	float flicker = fire_flicker_min + fire_flicker_amplitude * sin(
		occlusion_reveal_time * fire_flicker_speed + dist_xz * fire_flicker_wave_scale
	);
	float fire_noise = hash21(v_world_pos.xz * fire_noise_scale + occlusion_reveal_time * fire_noise_speed);
	vec3 fire = mix(fire_color_cool.rgb, fire_color_hot.rgb, fire_noise) * edge * reveal_strength * flicker;
	EMISSION = fire;
}
