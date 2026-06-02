class_name HitBox
extends Area3D

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func set_shape(shape: Shape3D) -> void:
	if collision_shape != null:
		collision_shape.shape = shape

func _on_body_entered(body: Node3D) -> void:
	EventBus.hit_received.emit(get_parent(), body, 0.0)

func _on_area_entered(area: Area3D) -> void:
	EventBus.hit_received.emit(get_parent(), area, 0.0)
