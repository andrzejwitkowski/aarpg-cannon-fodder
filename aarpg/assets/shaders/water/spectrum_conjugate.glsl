#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) readonly buffer H0kBuf {
	vec2 h0k[];
} h0k_buf;

layout(set = 0, binding = 1, std430) buffer H0Buf {
	vec4 h0[];
} h0_buf;

layout(set = 0, binding = 2, std140) uniform GridUBO {
	int N;
} grid;

void main() {
	ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
	if (coord.x >= grid.N || coord.y >= grid.N) {
		return;
	}
	int id = coord.y * grid.N + coord.x;
	int xm = (grid.N - coord.x) % grid.N;
	int ym = (grid.N - coord.y) % grid.N;
	int id_conj = ym * grid.N + xm;
	vec2 a = h0k_buf.h0k[id];
	vec2 b = h0k_buf.h0k[id_conj];
	h0_buf.h0[id] = vec4(a.x, a.y, b.x, -b.y);
}
