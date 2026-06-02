extends GdUnitTestSuite

const TEST_SCENE = "res://world/test_scene.tscn"

func test_scene_loads_without_error() -> void:
	var scene := load(TEST_SCENE)
	assert_object(scene).is_not_null()

func test_player_node_exists() -> void:
	var packed := load(TEST_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	assert_bool(scene.has_node("Player")).is_true()

func test_ground_node_exists() -> void:
	var packed := load(TEST_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	assert_bool(scene.has_node("Ground")).is_true()

func test_camera_node_exists() -> void:
	var packed := load(TEST_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	assert_bool(scene.has_node("Camera3D")).is_true()

func test_player_in_group() -> void:
	var packed := load(TEST_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	var player: Node3D = scene.get_node("Player")
	assert_bool(player.is_in_group("player")).is_true()

func test_ground_has_static_body() -> void:
	var packed := load(TEST_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	var ground: Node3D = scene.get_node("Ground")
	assert_bool(ground.has_node("GroundStaticBody")).is_true()
