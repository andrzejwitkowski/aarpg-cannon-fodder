extends GdUnitTestSuite

const PLAYER_SCENE = "res://player/player.tscn"

func test_player_has_hitbox_child() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	assert_bool(scene.has_node("HitBox")).is_true()

func test_player_has_navigation_agent() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	assert_bool(scene.has_node("NavigationAgent3D")).is_true()

func test_player_has_collision_shape() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	assert_bool(scene.has_node("CollisionShape3D")).is_true()

func test_player_has_mesh() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	assert_bool(scene.has_node("MeshInstance3D")).is_true()

func test_player_is_in_player_group() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	add_child(scene)
	assert_bool(scene.is_in_group("player")).is_true()

func test_default_speed() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene: CharacterBody3D = packed.instantiate()
	auto_free(scene)
	assert_float(scene.speed).is_equal(5.0)

func test_default_gravity() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene: CharacterBody3D = packed.instantiate()
	auto_free(scene)
	assert_float(scene.gravity).is_equal(9.8)

func test_move_to_sets_nav_target() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene: CharacterBody3D = packed.instantiate()
	auto_free(scene)
	add_child(scene)
	var target := Vector3(10, 0, 5)
	scene.move_to(target)
	var nav: NavigationAgent3D = scene.get_node("NavigationAgent3D")
	assert_vector(nav.target_position).is_equal(target)

func test_ready_sets_target_position() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene: CharacterBody3D = packed.instantiate()
	auto_free(scene)
	add_child(scene)
	assert_vector(scene._target_position).is_equal(scene.global_position)

func test_hitbox_shape_copied_from_collision() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene: CharacterBody3D = packed.instantiate()
	auto_free(scene)
	add_child(scene)
	var hitbox: HitBox = scene.get_node("HitBox")
	var body_collider: CollisionShape3D = scene.get_node("CollisionShape3D")
	assert_object(hitbox.get_node("CollisionShape3D").shape).is_same(body_collider.shape)
