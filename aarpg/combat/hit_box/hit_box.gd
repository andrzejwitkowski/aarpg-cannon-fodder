class_name HitBox
extends Area3D

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	collision_mask = PhysicsLayers.COMBAT_TARGET_MASK
	set_active(false)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func set_active(active: bool) -> void:
	monitoring = active
	collision_layer = PhysicsLayers.COMBAT if active else 0

func set_shape(shape: Shape3D) -> void:
	if collision_shape != null:
		collision_shape.shape = shape

func _on_body_entered(body: Node3D) -> void:
	EventBus.hit_received.emit(body, _attacker(), 0.0)

func _on_area_entered(area: Area3D) -> void:
	EventBus.hit_received.emit(area, _attacker(), 0.0)

func _attacker() -> Node:
	var player := PlayerUtils.from_node(self)
	return player if player else get_parent()
