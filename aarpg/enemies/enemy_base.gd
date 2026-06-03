class_name EnemyBase extends Node3D

@export var definition: EnemyDefinition

@onready var body: StaticBody3D = $Body
@onready var hurt_box: HurtBox = $Body/HurtBox
@onready var mesh: MeshInstance3D = $Body/MeshInstance3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var fsm: EnemyFsm = $EnemyFsm
@onready var weapon_mount: WeaponMount = $WeaponMounts
@onready var hit_flash: HitFlash = $HitFlash
@onready var sockets: Node3D = $Sockets

var context: EnemyContext

func _ready() -> void:
	add_to_group(EnemyPaths.GROUP)
	context = EnemyContext.new()
	context.hp = 1.0
	var collision := body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null and collision.shape != null:
		hurt_box.set_shape(collision.shape)
	hit_flash.setup(mesh)
	EventBus.enemy_hit.connect(_on_enemy_hit)
	fsm.setup(self, context)
	_equip_weapons()

func play_animation(anim_name: StringName) -> void:
	if animation_player == null:
		return
	var resolved := definition.resolve_anim(anim_name) if definition != null else anim_name
	if animation_player.has_animation(str(resolved)):
		animation_player.play(str(resolved))

func trigger_hit_flash() -> void:
	hit_flash.trigger()

func _on_enemy_hit(enemy: Node, by: Node, damage: float) -> void:
	if enemy != self:
		return
	fsm.notify_hurt(by, damage)

func _exit_tree() -> void:
	if EventBus.enemy_hit.is_connected(_on_enemy_hit):
		EventBus.enemy_hit.disconnect(_on_enemy_hit)

func _equip_weapons() -> void:
	if definition == null or weapon_mount == null:
		return
	for weapon_def: WeaponDefinition in definition.weapon_definitions:
		var weapon := weapon_mount.equip(weapon_def, sockets)
		if weapon != null and context.current_weapon == null:
			context.current_weapon = weapon
