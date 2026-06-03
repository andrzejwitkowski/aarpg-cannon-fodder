extends GdUnitTestSuite

const HURT_BOX_SCENE := "res://combat/hurt_box/hurt_box.tscn"
const HIT_BOX_SCENE := "res://combat/hit_box/hit_box.tscn"

func test_set_shape() -> void:
	var packed := load(HURT_BOX_SCENE) as PackedScene
	var hurt_box: HurtBox = packed.instantiate()
	auto_free(hurt_box)
	add_child(hurt_box)
	await await_idle_frame()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5
	hurt_box.set_shape(capsule)
	var shape: Shape3D = hurt_box.get_node("CollisionShape3D").shape
	assert_float((shape as CapsuleShape3D).radius).is_equal(0.5)

func test_hurt_box_on_enemy_layer() -> void:
	var packed := load(HURT_BOX_SCENE) as PackedScene
	var hurt_box: HurtBox = packed.instantiate()
	auto_free(hurt_box)
	assert_int(hurt_box.collision_layer).is_equal(PhysicsLayers.ENEMY)

func test_hit_cooldown_blocks_rapid_hits() -> void:
	var hurt_box: HurtBox = (load(HURT_BOX_SCENE) as PackedScene).instantiate()
	auto_free(hurt_box)
	hurt_box.hit_cooldown = 0.5
	add_child(hurt_box)
	await await_idle_frame()
	var hit_count := [0]
	hurt_box.hurt_received.connect(func(_by, _dmg): hit_count[0] += 1)
	var player := CharacterBody3D.new()
	hurt_box._emit_hurt(player, 0.0)
	hurt_box._emit_hurt(player, 0.0)
	assert_int(hit_count[0]).is_equal(1)

func test_hit_box_overlap_triggers_hurt() -> void:
	var hurt_packed := load(HURT_BOX_SCENE) as PackedScene
	var hit_packed := load(HIT_BOX_SCENE) as PackedScene
	var hurt_box: HurtBox = hurt_packed.instantiate()
	var hit_box: HitBox = hit_packed.instantiate()
	auto_free(hurt_box)
	auto_free(hit_box)
	var root := Node3D.new()
	auto_free(root)
	add_child(root)
	root.add_child(hurt_box)
	var attacker := CharacterBody3D.new()
	attacker.add_to_group(PlayerUtils.GROUP)
	root.add_child(attacker)
	attacker.add_child(hit_box)
	var shape := SphereShape3D.new()
	shape.radius = 0.6
	hurt_box.set_shape(shape)
	hit_box.set_shape(shape)
	hurt_box.global_position = Vector3.ZERO
	attacker.global_position = Vector3.ZERO
	var hit_count := [0]
	hurt_box.hurt_received.connect(func(_by, _dmg): hit_count[0] += 1)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_int(hit_count[0]).is_greater_equal(1)
