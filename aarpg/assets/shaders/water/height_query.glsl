#[compute]
#version 450

#include "water_common.glslinc"

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) readonly buffer QueryIn {
	vec2 positions[];
} query_in;

layout(set = 0, binding = 1, std430) buffer QueryOut {
	vec4 results[];
} query_out;

layout(set = 0, binding = 2, rgba16f) uniform readonly image2D displacement;

layout(set = 0, binding = 3, std140) uniform QueryUBO {
	float length_scale;
	int N;
	int count;
} query;

vec4 sample_displacement(vec2 world_xz) {
	vec2 uv = world_xz / query.length_scale;
	vec2 tex = uv * float(query.N);
	ivec2 i0 = wrap_texel(ivec2(floor(tex)), query.N);
	ivec2 i1 = wrap_texel(i0 + ivec2(1, 0), query.N);
	ivec2 i2 = wrap_texel(i0 + ivec2(0, 1), query.N);
	ivec2 i3 = wrap_texel(i0 + ivec2(1, 1), query.N);
	vec2 f = fract(tex);
	vec4 s00 = imageLoad(displacement, i0);
	vec4 s10 = imageLoad(displacement, i1);
	vec4 s01 = imageLoad(displacement, i2);
	vec4 s11 = imageLoad(displacement, i3);
	return mix(mix(s00, s10, f.x), mix(s01, s11, f.x), f.y);
}

void main() {
	uint id = gl_GlobalInvocationID.x;
	if (int(id) >= query.count) {
		return;
	}
	vec2 xz = query_in.positions[id];
	vec4 d = sample_displacement(xz);
	query_out.results[id] = vec4(d.x, d.y, d.z, d.w);
}
