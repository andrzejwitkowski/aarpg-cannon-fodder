#[compute]
#version 450

#include "water_common.glslinc"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) readonly buffer H0Buf {
	vec4 h0[];
} h0_buf;

layout(set = 0, binding = 1, std430) readonly buffer WavesBuf {
	vec4 waves[];
} waves_buf;

layout(set = 0, binding = 2, std430) buffer DxDzBuf { vec2 data[]; } dx_dz;
layout(set = 0, binding = 3, std430) buffer DyDxzBuf { vec2 data[]; } dy_dxz;
layout(set = 0, binding = 4, std430) buffer DyxDyzBuf { vec2 data[]; } dyx_dyz;
layout(set = 0, binding = 5, std430) buffer DxxDzzBuf { vec2 data[]; } dxx_dzz;

layout(set = 0, binding = 6, std140) uniform TimeUBO {
	float time;
} time_ubo;

layout(set = 0, binding = 7, std140) uniform GridUBO {
	int N;
} grid;

void main() {
	ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
	if (coord.x >= grid.N || coord.y >= grid.N) {
		return;
	}
	int id = coord.y * grid.N + coord.x;
	vec4 wave = waves_buf.waves[id];
	float phase = wave.w * time_ubo.time;
	vec2 ex = vec2(cos(phase), sin(phase));
	vec4 h0v = h0_buf.h0[id];
	vec2 h = cmul(h0v.xy, ex) + cmul(h0v.zw, vec2(ex.x, -ex.y));
	vec2 ih = vec2(-h.y, h.x);
	vec2 disp_x = ih * wave.x * wave.y;
	vec2 disp_y = h;
	vec2 disp_z = ih * wave.z * wave.y;
	vec2 disp_xdx = -h * wave.x * wave.x * wave.y;
	vec2 disp_ydx = ih * wave.x;
	vec2 disp_zdx = -h * wave.x * wave.z * wave.y;
	vec2 disp_ydz = ih * wave.z;
	vec2 disp_zdz = -h * wave.z * wave.z * wave.y;
	dx_dz.data[id] = vec2(disp_x.x - disp_z.y, disp_x.y + disp_z.x);
	dy_dxz.data[id] = vec2(disp_y.x - disp_zdx.y, disp_y.y + disp_zdx.x);
	dyx_dyz.data[id] = vec2(disp_ydx.x - disp_ydz.y, disp_ydx.y + disp_ydz.x);
	dxx_dzz.data[id] = vec2(disp_xdx.x - disp_zdz.y, disp_xdx.y + disp_zdz.x);
}
