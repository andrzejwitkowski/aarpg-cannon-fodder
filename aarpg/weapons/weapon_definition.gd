class_name WeaponDefinition extends Resource

enum Kind { MELEE, RANGED, THROWN }

@export var id: StringName = &""
@export var kind: Kind = Kind.MELEE
@export var scene: PackedScene
@export var socket_name: StringName = EnemyPaths.SOCKET_WEAPON_MAIN
@export var attack_anim: StringName = EnemyAnimNames.ATTACK
@export var cooldown: float = 1.0
@export var damage: float = 1.0
