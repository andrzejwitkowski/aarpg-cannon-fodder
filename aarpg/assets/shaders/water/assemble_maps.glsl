#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) readonly buffer DxDzBuf { vec2 data[]; } dx_dz;
layout(set = 0, binding = 1, std430) readonly buffer DyDxzBuf { vec2 data[]; } dy_dxz;
layout(set = 0, binding = 2, std430) readonly buffer DyxDyzBuf { vec2 data[]; } dyx_dyz;
layout(set = 0, binding = 3, std430) readonly buffer DxxDzzBuf { vec2 data[]; } dxx_dzz;
layout(set = 0, binding = 4, std430) buffer TurbulenceBuf { float data[]; } turbulence;

layout(set = 0, binding = 5, rgba16f) uniform writeonly image2D displacement;
layout(set = 0, binding = 6, rgba16f) uniform writeonly image2D derivatives;

layout(set = 0, binding = 7, std140) uniform AssembleUBO {
	float lambda;
	float dt;
	float foam_decay;
} assemble;

layout(set = 0, binding = 8, std140) uniform GridUBO {
	int N;
} grid;

void main() {
	ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
	if (coord.x >= grid.N || coord.y >= grid.N) {
		return;
	}
	int id = coord.y * grid.N + coord.x;
	vec2 dx_dz_v = dx_dz.data[id];
	vec2 dy_dxz_v = dy_dxz.data[id];
	vec2 dyx_dyz_v = dyx_dyz.data[id];
	vec2 dxx_dzz_v = dxx_dzz.data[id];
	float jxx = 1.0 + assemble.lambda * dxx_dzz_v.x;
	float jzz = 1.0 + assemble.lambda * dxx_dzz_v.y;
	float jxz = assemble.lambda * dy_dxz_v.y;
	float J = jxx * jzz - jxz * jxz;
	float prev = turbulence.data[id];
	float turb = min(J, prev + assemble.dt * assemble.foam_decay / max(J, 0.5));
	turbulence.data[id] = turb;
	imageStore(displacement, coord, vec4(dx_dz_v.x * assemble.lambda, dy_dxz_v.x, dx_dz_v.y * assemble.lambda, turb));
	imageStore(derivatives, coord, vec4(dyx_dyz_v.x, dyx_dyz_v.y, dxx_dzz_v.x * assemble.lambda, dxx_dzz_v.y * assemble.lambda));
}
