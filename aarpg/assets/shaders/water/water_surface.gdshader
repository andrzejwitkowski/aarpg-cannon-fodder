shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D displacement_tex : repeat_enable, filter_linear;
uniform sampler2D derivatives_tex : repeat_enable, filter_linear;
uniform sampler2D detail_tex : repeat_enable, filter_linear_mipmap;
uniform float length_scale = 100.0;
uniform float time_elapsed = 0.0;
uniform float detail_strength = 0.1;
uniform float foam_threshold = 0.4;
uniform float foam_scale = 2.5;
uniform float sss_strength = 1.0;
uniform vec3 deep_color : source_color;
uniform vec3 scatter_color : source_color;
uniform vec3 foam_color : source_color;

varying vec3 v_world_pos;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 uv = wp.xz / length_scale;
	vec4 disp = texture(displacement_tex, uv);
	wp += vec3(disp.r, disp.g, disp.b);
	v_world_pos = wp;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(wp, 1.0)).xyz;
}

void fragment() {
	vec2 uv = v_world_pos.xz / length_scale;
	vec4 d = texture(derivatives_tex, uv);
	float slope_x = d.x / (1.0 + d.z);
	float slope_z = d.y / (1.0 + d.w);
	vec3 N = normalize(vec3(-slope_x, 1.0, -slope_z));
	vec2 det1 = texture(detail_tex, v_world_pos.xz * 0.06 + vec2(time_elapsed * 0.012, time_elapsed * 0.008)).xy * 2.0 - 1.0;
	vec2 det2 = texture(detail_tex, v_world_pos.xz * 0.17 + vec2(time_elapsed * -0.02, time_elapsed * 0.015)).xy * 2.0 - 1.0;
	vec2 detail = (det1 + det2 * 0.5) * detail_strength;
	N = normalize(N + vec3(detail.x, 0.0, detail.y));
	vec3 V = normalize(CAMERA_POSITION_WORLD - v_world_pos);
	float fresnel = 0.02 + 0.98 * pow(1.0 - max(dot(N, V), 0.0), 5.0);
	vec3 R = reflect(-V, N);
	vec3 sky_ref = mix(vec3(0.62, 0.72, 0.8), vec3(0.16, 0.36, 0.61), clamp(R.y * 0.5 + 0.5, 0.0, 1.0));
	float height_factor = clamp(v_world_pos.y * 0.5 + 0.4, 0.0, 1.0);
	vec3 sun_dir = normalize(vec3(0.5, 0.8, 0.3));
	vec3 H = normalize(-N + sun_dir);
	float sss = pow(clamp(dot(V, -H), 0.0, 1.0), 4.0) * sss_strength * height_factor;
	vec3 body = mix(deep_color, scatter_color, clamp(0.12 + sss, 0.0, 1.0));
	vec3 water = mix(body, sky_ref, fresnel);
	vec4 disp = texture(displacement_tex, uv);
	float foam_raw = clamp((foam_threshold - disp.a) * foam_scale, 0.0, 1.0);
	float coverage = smoothstep(0.2, 0.9, foam_raw);
	float fb1 = texture(detail_tex, v_world_pos.xz * 0.45 + vec2(time_elapsed * 0.03, time_elapsed * 0.02)).b;
	float fb2 = texture(detail_tex, v_world_pos.xz * 1.6 + vec2(time_elapsed * -0.05, time_elapsed * 0.04)).a;
	float bubbles = clamp(fb1 * 0.7 + fb2 * 0.5 + 0.2, 0.0, 1.0);
	float foam_light = 0.55 + clamp(dot(N, sun_dir), 0.0, 1.0) * 0.6;
	vec3 foam_shaded = foam_color * foam_light * bubbles;
	ALBEDO = mix(water, foam_shaded, coverage);
	ROUGHNESS = mix(0.05, 0.25, coverage);
	METALLIC = 0.0;
	NORMAL = normalize((VIEW_MATRIX * vec4(N, 0.0)).xyz);
	SPECULAR = 0.5;
}
