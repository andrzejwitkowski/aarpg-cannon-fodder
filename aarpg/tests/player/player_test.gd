extends GdUnitTestSuite

const PLAYER_SCENE = "res://player/player.tscn"

func test_player_has_club() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	assert_bool(scene.has_node("Club")).is_true()

func test_player_has_click_input() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	assert_bool(scene.has_node("ClickInput")).is_true()

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
	assert_float(scene._target_position.y).is_equal(scene.global_position.y)

func test_reached_move_target_uses_horizontal_distance() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene: CharacterBody3D = packed.instantiate()
	auto_free(scene)
	add_child(scene)
	scene.global_position = Vector3(0.0, 4.0, 0.0)
	scene._target_position = Vector3(0.4, 0.0, 0.0)
	assert_bool(scene._reached_move_target()).is_true()

func test_ready_sets_target_position() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene: CharacterBody3D = packed.instantiate()
	auto_free(scene)
	add_child(scene)
	assert_vector(scene._target_position).is_equal(scene.global_position)

func test_club_centered_on_capsule() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene: CharacterBody3D = packed.instantiate()
	auto_free(scene)
	var club: Club = scene.get_node("Club")
	assert_float(club.transform.origin.y).is_equal_approx(0.9, 0.01)
