shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

const int MAX_INTERACTORS = 8;

uniform vec4 base_color : source_color = vec4(0.15, 0.45, 0.12, 1.0);
uniform vec4 tip_color : source_color = vec4(0.45, 0.75, 0.2, 1.0);
uniform float blade_height = 0.5;

uniform float wind_strength = 0.15;
uniform float wind_speed = 1.5;
uniform float wind_direction_rad = 0.0;
uniform float time_elapsed = 0.0;

uniform int interactor_count = 0;
uniform vec3 interactor_pos[MAX_INTERACTORS];
uniform float interactor_radius[MAX_INTERACTORS];
uniform float interactor_strength = 0.55;

varying float v_height_frac;

vec3 world_offset_to_local(vec3 world_offset, mat4 model_mat) {
	return (inverse(model_mat) * vec4(world_offset, 0.0)).xyz;
}

void vertex() {
	float height_scale = max(INSTANCE_CUSTOM.r, 0.05);
	VERTEX.y *= height_scale;
	vec3 world_v = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_height_frac = clamp(VERTEX.y / max(blade_height * height_scale, 0.001), 0.0, 1.0);

	vec2 wind_dir = vec2(cos(wind_direction_rad), sin(wind_direction_rad));
	float wind_phase = sin(time_elapsed * wind_speed + world_v.x * 0.35 + world_v.z * 0.35);
	vec3 wind_offset = vec3(wind_dir.x, 0.0, wind_dir.y) * wind_strength * wind_phase * v_height_frac;

	vec3 push = vec3(0.0);
	for (int i = 0; i < MAX_INTERACTORS; i++) {
		if (i >= interactor_count) {
			break;
		}
		vec2 delta = world_v.xz - interactor_pos[i].xz;
		float dist = length(delta);
		float radius = max(interactor_radius[i], 0.001);
		if (dist < radius) {
			float t = 1.0 - dist / radius;
			t *= t;
			vec2 away = dist > 0.001 ? normalize(delta) : vec2(0.0);
			push.x += away.x * t * interactor_strength * v_height_frac;
			push.z += away.y * t * interactor_strength * v_height_frac;
			push.y -= t * interactor_strength * 0.35 * v_height_frac;
		}
	}

	VERTEX += world_offset_to_local(wind_offset + push, MODEL_MATRIX);
}

void fragment() {
	ALBEDO = mix(base_color, tip_color, v_height_frac).rgb;
}
