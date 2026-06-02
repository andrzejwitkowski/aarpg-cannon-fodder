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
	assert_bool(scene.has_node("NavigationRegion3D/Ground")).is_true()

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
	var ground: Node3D = scene.get_node("NavigationRegion3D/Ground")
	assert_bool(ground.has_node("GroundStaticBody")).is_true()

func test_navigation_region_exists() -> void:
	var packed := load(TEST_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	assert_bool(scene.has_node("NavigationRegion3D")).is_true()

func test_ground_on_world_physics_layer() -> void:
	var packed := load(TEST_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	var ground_body: StaticBody3D = scene.get_node("NavigationRegion3D/Ground/GroundStaticBody")
	assert_int(ground_body.collision_layer).is_equal(PhysicsLayers.WORLD)

func test_navigation_mesh_has_polygons_after_ready() -> void:
	var packed := load(TEST_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	add_child(scene)
	await await_idle_frame()
	var region: NavigationRegion3D = scene.get_node("NavigationRegion3D")
	assert_int(region.navigation_mesh.get_polygon_count()).is_greater(0)
