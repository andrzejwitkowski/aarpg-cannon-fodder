shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float rain_intensity = 0.0;
uniform float time = 0.0;
uniform float drop_density = 1.0;
uniform float streak_speed = 1.0;
uniform float distortion_strength = 0.06;
uniform float blur_lod = 3.0;
uniform float condensation_strength = 0.85;
uniform float impact_rate = 1.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash22(vec2 p) {
	float n = hash21(p);
	return vec2(n, hash21(p + n + 17.0));
}

float fine_condensation(vec2 uv, float scale) {
	float a = hash21(uv * scale);
	float b = hash21(uv * scale * 1.73 + 4.1);
	float c = hash21(uv * scale * 2.41 + 9.7);
	return (a + b * 0.55 + c * 0.3) / 1.85;
}

float static_drop(vec2 uv, float scale, out vec2 lens_offset, out float specular) {
	vec2 grid = floor(uv * scale);
	vec2 cell = fract(uv * scale);
	vec2 rnd = hash22(grid);
	vec2 center = rnd * 0.62 + 0.19;
	float size_roll = rnd.x;
	float radius = mix(0.018, 0.09, size_roll) * mix(0.55, 1.0, drop_density);
	float d = length(cell - center);
	float body = smoothstep(radius, radius * 0.42, d);
	float rim = smoothstep(radius * 1.08, radius * 0.92, d) * smoothstep(radius * 0.55, radius * 0.78, d);
	vec2 to_center = cell - center;
	lens_offset = to_center * body * radius * 3.8;
	vec2 light_dir = normalize(vec2(0.55, -0.82));
	vec2 normal_xy = normalize(to_center + vec2(0.0001));
	specular = pow(max(dot(normal_xy, light_dir), 0.0), mix(8.0, 28.0, size_roll)) * body;
	return body + rim * 0.45;
}

float impact_drop(vec2 uv, float scale, float t, out vec2 lens_offset, out float flash) {
	vec2 grid = floor(uv * scale);
	vec2 cell = fract(uv * scale);
	float seed = hash21(grid);
	float cycle = mix(2.8, 7.5, seed) / max(impact_rate, 0.05);
	float phase = hash21(grid + 31.7) * cycle;
	float local_t = mod(t + phase, cycle);
	float impact_dur = mix(0.12, 0.22, seed);
	float age = local_t / impact_dur;
	lens_offset = vec2(0.0);
	flash = 0.0;
	if (age > 1.0) {
		return 0.0;
	}
	vec2 center = hash22(grid + 5.3) * 0.58 + 0.21;
	float max_radius = mix(0.025, 0.07, seed);
	float radius = max_radius * smoothstep(0.0, 0.35, age) * smoothstep(1.0, 0.72, age);
	float d = length(cell - center);
	float body = smoothstep(radius, radius * 0.55, d);
	float ring = smoothstep(radius * 1.15, radius * 0.98, d) * smoothstep(radius * 0.72, radius * 0.9, d);
	vec2 to_center = cell - center;
	lens_offset = to_center * body * radius * 5.5;
	flash = ring * smoothstep(0.05, 0.0, abs(age - 0.12));
	return body + ring * 1.4;
}

float streak_layer(vec2 uv, float scale, out float clear_path, out vec2 streak_offset) {
	vec2 p = uv * vec2(scale * 0.85, scale * 0.28);
	p.y += time * streak_speed * 0.42;
	float row = floor(p.y);
	float n = hash21(vec2(row, floor(p.x * 0.35)));
	float lane_x = fract(p.x + sin(p.y * 6.283 + n * 12.0) * 0.04 + n * 0.37);
	float streak = smoothstep(0.93, 0.985, lane_x) * smoothstep(0.0, 0.32, fract(p.y));
	streak *= step(0.42, n);
	float trail_body = streak * smoothstep(0.0, 0.18, fract(p.y));
	clear_path = trail_body;
	vec2 tangent = vec2(sin(p.y * 9.0 + n * 5.0) * 0.003, 0.002);
	streak_offset = tangent * trail_body;
	return trail_body;
}

void fragment() {
	float intensity = clamp(rain_intensity, 0.0, 1.0);
	if (intensity <= 0.001) {
		discard;
	}
	vec2 uv = SCREEN_UV;
	float density = max(drop_density, 0.05);
	vec3 background = texture(SCREEN_TEXTURE, uv).rgb;
	vec3 base_blur = textureLod(SCREEN_TEXTURE, uv, blur_lod * 0.5 * intensity).rgb;
	vec3 cool_tint = vec3(0.76, 0.84, 0.95);
	vec3 scene = mix(background, base_blur, condensation_strength * intensity * 0.8);
	scene = mix(scene, cool_tint, condensation_strength * intensity * 0.14);
	float cond = fine_condensation(uv, 220.0 * density);
	cond += fine_condensation(uv + 0.17, 340.0 * density) * 0.45;
	cond = clamp(cond * condensation_strength, 0.0, 1.0);
	vec2 lens_large = vec2(0.0);
	vec2 lens_medium = vec2(0.0);
	vec2 lens_small = vec2(0.0);
	vec2 lens_impact = vec2(0.0);
	float spec_large = 0.0;
	float spec_medium = 0.0;
	float spec_small = 0.0;
	float flash = 0.0;
	float drops_large = static_drop(uv, 9.0 * density, lens_large, spec_large);
	float drops_medium = static_drop(uv + 0.31, 16.0 * density, lens_medium, spec_medium);
	float drops_small = static_drop(uv + 0.57, 28.0 * density, lens_small, spec_small);
	float drops_impact = impact_drop(uv, 14.0 * density, time, lens_impact, flash);
	float clear_path = 0.0;
	vec2 streak_offset = vec2(0.0);
	float streaks = streak_layer(uv, 20.0 * density, clear_path, streak_offset);
	float static_wet = clamp(drops_large + drops_medium * 0.85 + drops_small * 0.55, 0.0, 1.0);
	float wet = clamp(static_wet + drops_impact * 1.1 + streaks * 0.95, 0.0, 1.0);
	float fog = cond * (1.0 - clear_path * 0.92);
	vec2 distortion = (lens_large + lens_medium * 0.75 + lens_small * 0.45 + lens_impact) * distortion_strength;
	distortion += streak_offset * distortion_strength * 2.5;
	vec2 distorted_uv = uv + distortion * intensity;
	float blur_weight = clamp(fog * 0.65 + wet * 0.85 + intensity * 0.25, 0.0, 1.0);
	vec3 wet_sample = textureLod(SCREEN_TEXTURE, distorted_uv, blur_lod * blur_weight).rgb;
	wet_sample = mix(wet_sample, cool_tint, fog * 0.22 + wet * 0.1);
	float coat = clamp(fog * 0.55 + wet * 0.95, 0.0, 1.0) * intensity;
	scene = mix(scene, wet_sample, coat);
	float specular = (spec_large + spec_medium * 0.7 + spec_small * 0.4) * intensity;
	scene += vec3(specular * 0.75 + flash * intensity * 0.45);
	COLOR = vec4(scene, 1.0);
}
