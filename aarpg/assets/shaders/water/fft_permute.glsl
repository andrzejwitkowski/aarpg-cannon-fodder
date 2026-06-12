#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) buffer Field { vec2 data[]; } field;

layout(set = 0, binding = 1, std140) uniform GridUBO {
	int N;
} grid;

void main() {
	ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
	if (coord.x >= grid.N || coord.y >= grid.N) {
		return;
	}
	int id = coord.y * grid.N + coord.x;
	float sign = 1.0 - float((coord.x + coord.y) % 2) * 2.0;
	field.data[id] *= sign;
}
