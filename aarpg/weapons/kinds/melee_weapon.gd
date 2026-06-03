class_name MeleeWeapon extends WeaponBase

func _perform_attack(context: EnemyContext) -> void:
	if context == null or not is_instance_valid(context.target):
		return
