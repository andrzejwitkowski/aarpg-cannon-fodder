class_name HurtBox
extends Area3D

signal hurt_received(by: Node, damage: float)

@export_category("Combat")
@export var hit_cooldown: float = 0.35

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _cooldown_left: float = 0.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(_cooldown_left - delta, 0.0)

func set_shape(shape: Shape3D) -> void:
	if collision_shape != null:
		collision_shape.shape = shape

func _on_area_entered(area: Area3D) -> void:
	if not area is HitBox:
		return
	var attacker := area.get_parent()
	if attacker == null:
		return
	_emit_hurt(attacker, 0.0)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(PlayerUtils.GROUP):
		return
	_emit_hurt(body, 0.0)

func _emit_hurt(by: Node, damage: float) -> void:
	if _cooldown_left > 0.0:
		return
	_cooldown_left = hit_cooldown
	hurt_received.emit(by, damage)
	var enemy := _enemy_root()
	if enemy != null:
		EventBus.enemy_hit.emit(enemy, by, damage)

func _enemy_root() -> Node3D:
	var node: Node = self
	while node != null:
		if node.is_in_group(EnemyPaths.GROUP):
			return node as Node3D
		node = node.get_parent()
	return null
