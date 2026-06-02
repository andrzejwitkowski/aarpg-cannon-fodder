extends CharacterBody3D

@export_category("Physics variables")
@export var speed: float = 5.0
@export var rotation_speed: float = 12.0
@export var gravity: float = 9.8

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var hit_box: HitBox = $HitBox

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _target_position: Vector3
var _is_moving_to_target: bool = false

func _ready() -> void:
	_target_position = global_position
	hit_box.set_shape(collision_shape.shape)

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_dir.x, 0.0, input_dir.y).normalized()

	if not is_on_floor():
		velocity.y -= gravity * delta

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		_is_moving_to_target = false
	elif _is_moving_to_target:
		var next_point := navigation_agent.get_next_path_position()
		direction = (next_point - global_position).normalized()
		if global_position.distance_to(_target_position) < 0.5:
			velocity.x = 0.0
			velocity.z = 0.0
			_is_moving_to_target = false
		else:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

	if velocity.x * velocity.x + velocity.z * velocity.z > 0.01:
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)

	EventBus.character_moved.emit(global_position)

func move_to(target: Vector3) -> void:
	navigation_agent.target_position = target
	_target_position = target
	_is_moving_to_target = true
