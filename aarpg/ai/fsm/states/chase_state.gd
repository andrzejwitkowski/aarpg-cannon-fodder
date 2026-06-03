class_name EnemyChaseState extends EnemyState

func tick(context: EnemyContext, _delta: float) -> StringName:
	if not is_instance_valid(context.target):
		return EnemyFsm.STATE_IDLE
	return &""
