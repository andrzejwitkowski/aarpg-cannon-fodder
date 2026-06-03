class_name EnemyHitState extends EnemyState

@export var hit_duration: float = 0.2

var _elapsed: float = 0.0

func enter(_context: EnemyContext) -> void:
	_elapsed = 0.0

func tick(_context: EnemyContext, delta: float) -> StringName:
	_elapsed += delta
	if _elapsed >= hit_duration:
		return EnemyFsm.STATE_IDLE
	return &""
