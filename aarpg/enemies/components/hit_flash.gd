class_name HitFlash extends Node

@export_category("Flash")
@export var flash_duration: float = 0.12
@export var flash_color: Color = Color.WHITE

var _mesh: MeshInstance3D
var _original_material: Material
var _flash_material: StandardMaterial3D
var _timer: float = 0.0

func setup(mesh: MeshInstance3D) -> void:
	_mesh = mesh
	if _mesh == null:
		return
	_original_material = _mesh.get_active_material(0)
	_flash_material = StandardMaterial3D.new()
	_flash_material.albedo_color = flash_color
	_flash_material.emission_enabled = true
	_flash_material.emission = flash_color
	_flash_material.emission_energy_multiplier = 2.0

func trigger() -> void:
	if _mesh == null or _flash_material == null:
		return
	_mesh.set_surface_override_material(0, _flash_material)
	_timer = flash_duration

func _process(delta: float) -> void:
	if _timer <= 0.0:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	if _mesh != null and _original_material != null:
		_mesh.set_surface_override_material(0, _original_material)
	elif _mesh != null:
		_mesh.set_surface_override_material(0, null)
