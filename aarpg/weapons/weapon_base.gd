class_name WeaponBase extends Node3D

@export var definition: WeaponDefinition

var _cooldown_left: float = 0.0

func _process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(_cooldown_left - delta, 0.0)

func attack(context: EnemyContext) -> void:
	if _cooldown_left > 0.0 or definition == null:
		return
	_cooldown_left = definition.cooldown
	_perform_attack(context)

func _perform_attack(_context: EnemyContext) -> void:
	pass

func can_attack() -> bool:
	return _cooldown_left <= 0.0
