@tool
class_name GrassParams extends Resource

static func is_instance_ready(resource: Resource) -> bool:
	if resource == null or not resource is GrassParams:
		return false
	return resource.get_script() != null

signal params_changed

@export_category("Field")
@export var max_instances: int = 40000:
	set(v):
		max_instances = maxi(v, 1)
		params_changed.emit()
@export_range(0.05, 3.0, 0.01) var height_min: float = 0.35:
	set(v):
		height_min = clampf(v, 0.05, 3.0)
		height_max = maxf(height_max, height_min)
		params_changed.emit()
@export_range(0.05, 3.0, 0.01) var height_max: float = 0.65:
	set(v):
		height_max = clampf(maxf(v, height_min), 0.05, 3.0)
		params_changed.emit()
@export var random_yaw: bool = true:
	set(v):
		random_yaw = v
		params_changed.emit()
@export var random_height: bool = true:
	set(v):
		random_height = v
		params_changed.emit()

@export_category("Blade")
@export var blade_width: float = 0.08:
	set(v):
		blade_width = maxf(v, 0.01)
		params_changed.emit()
@export var base_color: Color = Color(0.15, 0.45, 0.12):
	set(v):
		base_color = v
		params_changed.emit()
@export var tip_color: Color = Color(0.45, 0.75, 0.2):
	set(v):
		tip_color = v
		params_changed.emit()

@export_category("Ambient Wind")
@export var wind_strength: float = 0.15:
	set(v):
		wind_strength = maxf(v, 0.0)
		params_changed.emit()
@export var wind_speed: float = 1.5:
	set(v):
		wind_speed = maxf(v, 0.0)
		params_changed.emit()
@export var wind_direction_deg: float = 30.0:
	set(v):
		wind_direction_deg = v
		params_changed.emit()

@export_category("Interactors")
@export var interactor_radius: float = 0.9:
	set(v):
		interactor_radius = maxf(v, 0.1)
		params_changed.emit()
@export var interactor_strength: float = 0.55:
	set(v):
		interactor_strength = maxf(v, 0.0)
		params_changed.emit()
@export var max_enemy_interactors: int = 7:
	set(v):
		max_enemy_interactors = clampi(v, 0, 7)
		params_changed.emit()
