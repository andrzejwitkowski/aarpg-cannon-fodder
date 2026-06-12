#[compute]
#version 450

#include "water_common.glslinc"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) buffer FieldA { vec2 data[]; } field_a;
layout(set = 0, binding = 1, std430) buffer FieldB { vec2 data[]; } field_b;
layout(set = 0, binding = 2, std430) readonly buffer Butterfly { vec4 data[]; } butterfly;

layout(set = 0, binding = 3, std140) uniform FftUBO {
	int N;
	int step;
	int axis;
	int ping;
} fft;

void main() {
	ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
	if (coord.x >= fft.N || coord.y >= fft.N) {
		return;
	}
	int id = coord.y * fft.N + coord.x;
	int idx = fft.axis == 0 ? coord.x : coord.y;
	vec4 bf = butterfly.data[fft.step * fft.N + idx];
	vec2 tw = vec2(bf.x, -bf.y);
	int ia;
	int ib;
	if (fft.axis == 0) {
		ia = coord.y * fft.N + int(bf.z);
		ib = coord.y * fft.N + int(bf.w);
	} else {
		ia = int(bf.z) * fft.N + coord.x;
		ib = int(bf.w) * fft.N + coord.x;
	}
	vec2 a = fft.ping == 0 ? field_a.data[ia] : field_b.data[ia];
	vec2 b = fft.ping == 0 ? field_a.data[ib] : field_b.data[ib];
	vec2 result = a + cmul(tw, b);
	if (fft.ping == 0) {
		field_b.data[id] = result;
	} else {
		field_a.data[id] = result;
	}
}
