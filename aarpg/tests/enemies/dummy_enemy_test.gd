extends GdUnitTestSuite

const DUMMY_SCENE := "res://enemies/types/dummy/dummy_enemy.tscn"
const WORLD_SCENE := "res://world/test_scene.tscn"
const PLAYER_SCENE := "res://player/player.tscn"

func test_dummy_scene_loads() -> void:
	var scene := load(DUMMY_SCENE)
	assert_object(scene).is_not_null()

func test_dummy_has_hurt_box_and_fsm() -> void:
	var packed := load(DUMMY_SCENE) as PackedScene
	var enemy: EnemyBase = packed.instantiate()
	auto_free(enemy)
	assert_bool(enemy.has_node(EnemyPaths.hurt_box_relative())).is_true()
	assert_bool(enemy.has_node("EnemyFsm")).is_true()

func test_dummy_in_enemies_group() -> void:
	var packed := load(DUMMY_SCENE) as PackedScene
	var enemy: EnemyBase = packed.instantiate()
	auto_free(enemy)
	add_child(enemy)
	await await_idle_frame()
	assert_bool(enemy.is_in_group(EnemyPaths.GROUP)).is_true()

func test_hit_flash_triggers_on_hurt() -> void:
	var packed := load(DUMMY_SCENE) as PackedScene
	var enemy: EnemyBase = packed.instantiate()
	auto_free(enemy)
	add_child(enemy)
	await await_idle_frame()
	var flash: HitFlash = enemy.hit_flash
	flash.trigger()
	assert_object(enemy.mesh.get_surface_override_material(0)).is_not_null()

func test_world_scene_has_dummy_enemy() -> void:
	var packed := load(WORLD_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	assert_bool(scene.has_node("DummyEnemy")).is_true()

func test_player_hit_box_overlap_enters_hit_state() -> void:
	var dummy_packed := load(DUMMY_SCENE) as PackedScene
	var player_packed := load(PLAYER_SCENE) as PackedScene
	var enemy: EnemyBase = dummy_packed.instantiate()
	var player: CharacterBody3D = player_packed.instantiate()
	auto_free(enemy)
	auto_free(player)
	var root := Node3D.new()
	auto_free(root)
	add_child(root)
	root.add_child(enemy)
	root.add_child(player)
	enemy.global_position = Vector3(6.0, 0.8, 2.0)
	player.global_position = enemy.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_str(enemy.fsm.current_state_name).is_equal(EnemyFsm.STATE_HIT)

func test_hurt_notifies_fsm() -> void:
	var packed := load(DUMMY_SCENE) as PackedScene
	var enemy: EnemyBase = packed.instantiate()
	auto_free(enemy)
	add_child(enemy)
	await await_idle_frame()
	var player := CharacterBody3D.new()
	player.add_to_group(PlayerUtils.GROUP)
	add_child(player)
	enemy.hurt_box.hurt_received.emit(player, 1.0)
	assert_str(enemy.fsm.current_state_name).is_equal(EnemyFsm.STATE_HIT)
