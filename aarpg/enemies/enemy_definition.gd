class_name EnemyDefinition extends Resource

enum BodyKind { STATIC, CHARACTER }

const _SHARED_ANIMS: Array[StringName] = [
	EnemyAnimNames.IDLE,
	EnemyAnimNames.WALK,
	EnemyAnimNames.ATTACK,
	EnemyAnimNames.HIT,
	EnemyAnimNames.DEATH,
]

@export var id: StringName = &""
@export var body_kind: BodyKind = BodyKind.STATIC
@export var extra_anim_names: PackedStringArray = []
@export var weapon_definitions: Array[WeaponDefinition] = []

func resolve_anim(requested: StringName) -> StringName:
	if extra_anim_names.has(requested):
		return requested
	if requested in _SHARED_ANIMS:
		return requested
	return EnemyAnimNames.IDLE
