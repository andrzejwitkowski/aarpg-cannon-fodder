extends Camera3D

@export var offset := Vector3(0.0, 14.0, 8.0)
@export var follow_speed: float = 5.0

var _target: Node3D

func _ready() -> void:
	EventBus.character_moved.connect(_on_character_moved)

func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		_target = null
		return
	var desired := _target.global_position + offset
	global_position = global_position.lerp(desired, follow_speed * delta)
	if global_position.distance_squared_to(_target.global_position) > 0.01:
		look_at(_target.global_position)

func _on_character_moved(_pos: Vector3) -> void:
	if not is_instance_valid(_target):
		_target = PlayerUtils.instance()
