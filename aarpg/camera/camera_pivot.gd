class_name CameraPivot extends Node3D

@export_category("Follow")
@export var follow_speed: float = 5.0

@export_category("Spring arm")
@export_range(0.1, 500.0) var spring_length: float = 16.0:
	get:
		return _spring_length_value
	set(value):
		_spring_length_value = clampf(value, 0.1, 500.0)
		_sync_spring_arm_length()

@export var pitch_degrees: float = -60.0
@export var yaw_degrees: float = 180.0
@export_flags_3d_physics var spring_arm_collision_mask: int = 0

@onready var _spring_arm: SpringArm3D = $SpringArm3D
@onready var _camera: Camera3D = $SpringArm3D/Camera3D

var _spring_length_value: float = 16.0
var _target: Node3D

func _ready() -> void:
	_apply_spring_arm_settings()
	_camera.make_current()
	EventBus.character_moved.connect(_on_character_moved)
	call_deferred("_snap_to_target")

func _snap_to_target() -> void:
	_resolve_target()
	if is_instance_valid(_target):
		global_position = _target.global_position

func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		_resolve_target()
		if _target == null:
			return
	var desired: Vector3 = _target.global_position
	global_position = global_position.lerp(desired, clampf(follow_speed * delta, 0.0, 1.0))

func _on_character_moved(_pos: Vector3) -> void:
	if not is_instance_valid(_target):
		_resolve_target()

func _apply_spring_arm_settings() -> void:
	_sync_spring_arm_length()
	_spring_arm.rotation_degrees = Vector3(pitch_degrees, yaw_degrees, 0.0)
	_spring_arm.collision_mask = spring_arm_collision_mask

func _sync_spring_arm_length() -> void:
	if not is_node_ready() or not is_instance_valid(_spring_arm):
		return
	_spring_arm.spring_length = _spring_length_value

func _resolve_target() -> void:
	_target = PlayerUtils.instance()
