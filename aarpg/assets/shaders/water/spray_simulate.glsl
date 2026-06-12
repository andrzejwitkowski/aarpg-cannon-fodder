#[compute]
#version 450

#include "water_common.glslinc"

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) buffer PosLife { vec4 data[]; } pos_life;
layout(set = 0, binding = 1, std430) buffer VelLife { vec4 data[]; } vel_life;

layout(set = 0, binding = 2, rgba16f) uniform readonly image2D displacement;

layout(set = 0, binding = 3, std430) readonly buffer SprayUBO {
	float dt;
	float seed;
	vec2 cam_xz;
	vec3 wind;
	float emit_radius;
	float break_threshold;
	float emit_chance;
	float burst;
	float foam_threshold;
	float plane_y;
	float length_scale;
	int N;
	int count;
} spray;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

vec4 sample_ocean(vec2 xz) {
	vec2 tex = (xz / spray.length_scale) * float(spray.N);
	ivec2 i = wrap_texel(ivec2(floor(tex)), spray.N);
	return imageLoad(displacement, i);
}

void main() {
	uint i = gl_GlobalInvocationID.x;
	if (int(i) >= spray.count) {
		return;
	}
	vec4 pl = pos_life.data[i];
	vec4 vl = vel_life.data[i];
	vec3 pos = pl.xyz;
	float life = pl.w;
	vec3 vel = vl.xyz;
	float total = vl.w;
	if (life <= 0.0) {
		float s = float(i) * 2.17 + spray.seed;
		float r1 = hash(s);
		float r2 = hash(s + 11.0);
		float r3 = hash(s + 23.0);
		float r4 = hash(s + 37.0);
		float ang = r1 * 6.2831853;
		float rad = sqrt(r2) * spray.emit_radius;
		vec2 xz = spray.cam_xz + vec2(cos(ang), sin(ang)) * rad;
		vec4 d = sample_ocean(xz);
		float brk = spray.foam_threshold - d.w;
		if (brk > spray.break_threshold && r3 < spray.emit_chance) {
			pos = vec3(xz.x, spray.plane_y + d.y + 0.3, xz.y);
			float up = spray.burst * (0.5 + brk * 0.4) * (0.6 + r4 * 0.8);
			vec3 downwind = spray.wind * (1.0 + r2 * 1.8);
			vec3 jit = vec3(r1 - 0.5, r3 * 0.4, r4 - 0.5) * 2.0;
			vel = vec3(0.0, up, 0.0) + downwind + jit;
			total = 0.8 + r2 * 1.4;
			life = total;
		} else {
			life = 0.0;
		}
	} else {
		vel.y -= 9.8 * spray.dt;
		vel += spray.wind * 0.35 * spray.dt;
		vel *= max(1.0 - 0.6 * spray.dt, 0.0);
		pos += vel * spray.dt;
		life -= spray.dt;
	}
	pos_life.data[i] = vec4(pos, life);
	vel_life.data[i] = vec4(vel, total);
}
