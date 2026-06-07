class_name HitBox
extends Area3D

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	collision_mask = PhysicsLayers.COMBAT_TARGET_MASK
	monitoring = false
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func set_shape(shape: Shape3D) -> void:
	if collision_shape != null:
		collision_shape.shape = shape

func _on_body_entered(body: Node3D) -> void:
	if not monitoring:
		return
	EventBus.hit_received.emit(_attacker(), body, 0.0)

func _on_area_entered(area: Area3D) -> void:
	if not monitoring:
		return
	if area is HurtBox:
		print('Trafiono!')
	EventBus.hit_received.emit(_attacker(), area, 0.0)

func _attacker() -> Node:
	var node: Node = self
	while node != null:
		if node.is_in_group(PlayerUtils.GROUP):
			return node
		node = node.get_parent()
	return get_parent()
