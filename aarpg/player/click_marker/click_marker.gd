class_name ClickMarker
extends Node3D

@export_category("Appearance")
@export var color_center: Color = Color(0.925, 0.012, 0.216, 0.902)
@export var color_edge: Color = Color(0.961, 0.357, 0.016, 0.0)
@export var max_radius: float = 1.2
@export var ground_offset: float = 0.05

@export_category("Animation")
@export var duration: float = 1.0
@export var dissolve_duration: float = 0.8
@export var cancel_duration: float = 0.12

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _material: ShaderMaterial = _mesh.material_override as ShaderMaterial

var _tween: Tween
var _pending_position: Vector3

func _ready() -> void:
	_material.set_shader_parameter("color_center", color_center)
	_material.set_shader_parameter("color_edge", color_edge)
	_set_expand(0.0)
	_set_dissolve(0.0)
	var diameter := max_radius * 2.0
	_mesh.scale = Vector3(diameter, 1.0, diameter)

func play(world_position: Vector3) -> void:
	_pending_position = world_position
	_stop_tween()
	if _is_visible():
		var dissolve_now: float = _material.get_shader_parameter("dissolve")
		_tween = create_tween()
		_tween.tween_method(_set_dissolve, dissolve_now, 1.0, cancel_duration)
		_tween.tween_callback(_start_cycle)
	else:
		_start_cycle()

func _start_cycle() -> void:
	global_position = Vector3(
		_pending_position.x,
		_pending_position.y + ground_offset,
		_pending_position.z
	)
	_set_expand(0.0)
	_set_dissolve(0.0)
	_tween = create_tween()
	_tween.tween_method(_set_expand, 0.0, 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_dissolve, 0.0, 1.0, dissolve_duration).set_trans(Tween.TRANS_LINEAR)

func _is_visible() -> bool:
	var expand: float = _material.get_shader_parameter("expand")
	var dissolve: float = _material.get_shader_parameter("dissolve")
	return expand > dissolve + 0.01

func _stop_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null

func _set_expand(value: float) -> void:
	_material.set_shader_parameter("expand", value)

func _set_dissolve(value: float) -> void:
	_material.set_shader_parameter("dissolve", value)
