class_name EnemyDeathState extends EnemyState

func enter(context: EnemyContext) -> void:
	context.hp = 0.0
