class_name CameraPivot extends Node3D

@export_category("Follow")
@export var follow_speed: float = 5.0

@export_category("Spring arm")
@export_range(0.1, 500.0) var spring_length: float = 16.0:
	set(value):
		spring_length = clampf(value, 0.1, 500.0)
		if is_node_ready() and is_instance_valid(_spring_arm):
			_spring_arm.spring_length = spring_length

@export var pitch_degrees: float = -60.0
@export var yaw_degrees: float = 180.0

@onready var _spring_arm: SpringArm3D = $SpringArm3D
@onready var _camera: Camera3D = $SpringArm3D/Camera3D

var _target: Node3D

func _ready() -> void:
	_apply_spring_arm_settings()
	_camera.make_current()
	EventBus.character_moved.connect(_on_character_moved)
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
	_spring_arm.spring_length = spring_length
	_spring_arm.rotation_degrees = Vector3(pitch_degrees, yaw_degrees, 0.0)
	_spring_arm.collision_mask = 0

func _resolve_target() -> void:
	_target = PlayerUtils.instance()
