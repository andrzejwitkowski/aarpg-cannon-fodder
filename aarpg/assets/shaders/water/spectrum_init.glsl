#[compute]
#version 450

#include "water_common.glslinc"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) readonly buffer NoiseBuf {
	vec2 noise[];
} noise_buf;

layout(set = 0, binding = 1, std430) buffer H0kBuf {
	vec2 h0k[];
} h0k_buf;

layout(set = 0, binding = 2, std430) buffer WavesBuf {
	vec4 waves[];
} waves_buf;

layout(set = 0, binding = 3, std430) readonly buffer SpectrumUBO {
	float data[32];
} ubo;

SpectrumSet read_set(int offset) {
	SpectrumSet s;
	s.scale = ubo.data[offset];
	s.angle = ubo.data[offset + 1];
	s.spread_blend = ubo.data[offset + 2];
	s.swell = ubo.data[offset + 3];
	s.alpha = ubo.data[offset + 4];
	s.peak_omega = ubo.data[offset + 5];
	s.gamma = ubo.data[offset + 6];
	s.short_waves_fade = ubo.data[offset + 7];
	return s;
}

layout(set = 0, binding = 4, std140) uniform GridUBO {
	int N;
} grid;

void main() {
	ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
	int id = coord.y * grid.N + coord.x;
	if (coord.x >= grid.N || coord.y >= grid.N) {
		return;
	}
	float nx = float(int(coord.x) - grid.N / 2);
	float nz = float(int(coord.y) - grid.N / 2);
	float g = ubo.data[0];
	float depth = ubo.data[1];
	float delta_k = ubo.data[2];
	float cutoff_low = ubo.data[3];
	float cutoff_high = ubo.data[4];
	SpectrumSet local_set = read_set(8);
	SpectrumSet swell_set = read_set(24);
	vec2 k = vec2(nx, nz) * delta_k;
	float k_len = length(k);
	float k_safe = max(k_len, cutoff_low);
	float angle = atan(k.y, k.x + 1e-9);
	float omega = wave_frequency(k_safe, g, depth);
	float d_omega = wave_frequency_derivative(k_safe, g, depth);
	float spectrum = jonswap(omega, g, depth, local_set) * direction_spectrum(angle, omega, local_set) * short_waves_fade(k_safe, local_set)
		+ jonswap(omega, g, depth, swell_set) * direction_spectrum(angle, omega, swell_set) * short_waves_fade(k_safe, swell_set);
	float in_band = step(cutoff_low, k_len) * step(k_len, cutoff_high);
	float amplitude = sqrt(spectrum * 2.0 * abs(d_omega) / k_safe * delta_k * delta_k);
	h0k_buf.h0k[id] = noise_buf.noise[id] * amplitude * in_band;
	waves_buf.waves[id] = vec4(k.x, 1.0 / k_safe, k.y, omega);
}
