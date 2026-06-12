class_name WaterParams extends Resource

signal spectrum_changed
signal runtime_changed
signal noise_regenerate_requested

@export_category("Grid")
@export var fft_resolution: int = 256:
	set(v):
		fft_resolution = maxi(16, nearest_po2(v))
		spectrum_changed.emit()
@export var length_scale: float = 100.0:
	set(v):
		length_scale = maxf(v, 1.0)
		spectrum_changed.emit()

@export_category("Physics")
@export var gravity: float = 9.81:
	set(v):
		gravity = v
		spectrum_changed.emit()
@export var depth: float = 500.0:
	set(v):
		depth = maxf(v, 1.0)
		spectrum_changed.emit()
@export var choppiness: float = 1.3:
	set(v):
		choppiness = v
		runtime_changed.emit()

@export_category("Wind Sea")
@export var wind_speed: float = 16.0:
	set(v):
		wind_speed = maxf(v, 0.1)
		spectrum_changed.emit()
@export var wind_direction_deg: float = 45.0:
	set(v):
		wind_direction_deg = v
		spectrum_changed.emit()
@export var fetch: float = 100000.0:
	set(v):
		fetch = maxf(v, 1.0)
		spectrum_changed.emit()
@export var spread_blend: float = 1.0:
	set(v):
		spread_blend = clampf(v, 0.0, 1.0)
		spectrum_changed.emit()
@export var swell_blend: float = 0.2:
	set(v):
		swell_blend = clampf(v, 0.0, 1.0)
		spectrum_changed.emit()
@export var peak_enhancement: float = 3.3:
	set(v):
		peak_enhancement = v
		spectrum_changed.emit()
@export var short_waves_fade: float = 0.02:
	set(v):
		short_waves_fade = v
		spectrum_changed.emit()
@export var local_scale: float = 1.0:
	set(v):
		local_scale = v
		spectrum_changed.emit()

@export_category("Swell")
@export var swell_scale: float = 0.8:
	set(v):
		swell_scale = v
		spectrum_changed.emit()
@export var swell_wind_speed: float = 2.0:
	set(v):
		swell_wind_speed = maxf(v, 0.1)
		spectrum_changed.emit()
@export var swell_direction_deg: float = 70.0:
	set(v):
		swell_direction_deg = v
		spectrum_changed.emit()
@export var swell_fetch: float = 300000.0:
	set(v):
		swell_fetch = maxf(v, 1.0)
		spectrum_changed.emit()
@export var swell_spread_blend: float = 1.0:
	set(v):
		swell_spread_blend = clampf(v, 0.0, 1.0)
		spectrum_changed.emit()
@export var swell_amount: float = 1.0:
	set(v):
		swell_amount = clampf(v, 0.01, 1.0)
		spectrum_changed.emit()
@export var swell_short_waves_fade: float = 0.01:
	set(v):
		swell_short_waves_fade = v
		spectrum_changed.emit()

@export_category("Animation")
@export var time_scale: float = 1.0:
	set(v):
		time_scale = v
		runtime_changed.emit()

@export_category("Foam")
@export var foam_threshold: float = 0.4:
	set(v):
		foam_threshold = v
		runtime_changed.emit()
@export var foam_scale: float = 2.5:
	set(v):
		foam_scale = v
		runtime_changed.emit()
@export var foam_decay: float = 0.4:
	set(v):
		foam_decay = v
		runtime_changed.emit()

@export_category("Shading")
@export var sss_strength: float = 1.0:
	set(v):
		sss_strength = v
		runtime_changed.emit()
@export var detail_strength: float = 0.1:
	set(v):
		detail_strength = v
		runtime_changed.emit()
@export var deep_color: Color = Color(0.027, 0.102, 0.149):
	set(v):
		deep_color = v
		runtime_changed.emit()
@export var scatter_color: Color = Color(0.18, 0.561, 0.561):
	set(v):
		scatter_color = v
		runtime_changed.emit()
@export var foam_color: Color = Color(0.863, 0.906, 0.918):
	set(v):
		foam_color = v
		runtime_changed.emit()

@export_category("Spray")
@export var spray_enabled: bool = true:
	set(v):
		spray_enabled = v
		runtime_changed.emit()
@export var spray_count: int = 4096:
	set(v):
		spray_count = clampi(v, 256, 24000)
		runtime_changed.emit()

@export_category("Actions")
@export var regenerate_noise: bool = false:
	set(v):
		if v:
			regenerate_noise = false
			noise_regenerate_requested.emit()
			spectrum_changed.emit()

func delta_k() -> float:
	return TAU / length_scale

func cutoff_low() -> float:
	return 1.0e-4

func cutoff_high() -> float:
	return 9999.0

func wind_direction_rad() -> float:
	return deg_to_rad(wind_direction_deg)

func swell_direction_rad() -> float:
	return deg_to_rad(swell_direction_deg)

func fill_spectrum_uniforms() -> PackedFloat32Array:
	var data := PackedFloat32Array()
	data.resize(64)
	data[0] = gravity
	data[1] = depth
	data[2] = delta_k()
	data[3] = cutoff_low()
	data[4] = cutoff_high()
	_fill_spectrum_set(data, 8, local_scale, wind_direction_rad(), spread_blend, swell_blend, wind_speed, fetch, peak_enhancement, short_waves_fade)
	_fill_spectrum_set(data, 24, swell_scale, swell_direction_rad(), swell_spread_blend, swell_amount, swell_wind_speed, swell_fetch, peak_enhancement, swell_short_waves_fade)
	return data

func _fill_spectrum_set(data: PackedFloat32Array, offset: int, scale: float, angle: float, spread: float, swell: float, ws: float, fetch_km: float, gamma: float, fade: float) -> void:
	data[offset + 0] = scale
	data[offset + 1] = angle
	data[offset + 2] = spread
	data[offset + 3] = clampf(swell, 0.01, 1.0)
	data[offset + 4] = 0.076 * pow((gravity * fetch_km) / (ws * ws), -0.22)
	data[offset + 5] = 22.0 * pow((ws * fetch_km) / (gravity * gravity), -0.33)
	data[offset + 6] = gamma
	data[offset + 7] = fade
