@tool
class_name RainParams extends Resource

static func is_instance_ready(resource: Resource) -> bool:
	if resource == null or not resource is RainParams:
		return false
	return resource.get_script() != null

signal params_changed

@export_category("Volume")
@export var volume_size: Vector3 = Vector3(20.0, 12.0, 20.0):
	set(v):
		volume_size = Vector3(maxf(v.x, 0.1), maxf(v.y, 0.1), maxf(v.z, 0.1))
		params_changed.emit()
@export_range(0.0, 1.0, 0.01) var strength: float = 1.0:
	set(v):
		strength = clampf(v, 0.0, 1.0)
		params_changed.emit()
@export var max_view_distance: float = 80.0:
	set(v):
		max_view_distance = maxf(v, 1.0)
		params_changed.emit()

@export_category("Particles")
@export var particle_amount: int = 4000:
	set(v):
		particle_amount = maxi(v, 1)
		params_changed.emit()
@export var particle_lifetime: float = 1.2:
	set(v):
		particle_lifetime = maxf(v, 0.1)
		params_changed.emit()
@export var fall_speed: float = 14.0:
	set(v):
		fall_speed = maxf(v, 0.1)
		params_changed.emit()
@export var editor_preview_particle_cap: int = 500:
	set(v):
		editor_preview_particle_cap = maxi(v, 1)
		params_changed.emit()

@export_category("Glass")
@export var drop_density: float = 1.0:
	set(v):
		drop_density = maxf(v, 0.0)
		params_changed.emit()
@export var streak_speed: float = 1.0:
	set(v):
		streak_speed = maxf(v, 0.0)
		params_changed.emit()
@export var distortion_strength: float = 0.06:
	set(v):
		distortion_strength = maxf(v, 0.0)
		params_changed.emit()
@export var blur_lod: float = 3.0:
	set(v):
		blur_lod = maxf(v, 0.0)
		params_changed.emit()
@export_range(0.0, 1.0, 0.01) var condensation_strength: float = 0.85:
	set(v):
		condensation_strength = clampf(v, 0.0, 1.0)
		params_changed.emit()
@export var impact_rate: float = 1.0:
	set(v):
		impact_rate = maxf(v, 0.05)
		params_changed.emit()
@export var overlay_fade_speed: float = 5.0:
	set(v):
		overlay_fade_speed = maxf(v, 0.1)
		params_changed.emit()

@export_category("Shelter")
@export var shelter_ray_height: float = 30.0:
	set(v):
		shelter_ray_height = maxf(v, 0.1)
		params_changed.emit()
@export var shelter_collision_mask: int = 1:
	set(v):
		shelter_collision_mask = v
		params_changed.emit()
@export var shelter_fade_speed: float = 6.0:
	set(v):
		shelter_fade_speed = maxf(v, 0.1)
		params_changed.emit()
