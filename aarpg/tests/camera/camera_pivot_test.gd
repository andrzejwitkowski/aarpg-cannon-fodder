extends GdUnitTestSuite

func test_rig_has_spring_arm_camera_hierarchy() -> void:
	var packed := load(CameraRigPaths.RIG_SCENE) as PackedScene
	var rig := packed.instantiate()
	auto_free(rig)
	assert_bool(rig.has_node(CameraRigPaths.CAMERA_RELATIVE)).is_true()

func test_has_exported_follow_speed() -> void:
	var packed := load(CameraRigPaths.RIG_SCENE) as PackedScene
	var pivot: CameraPivot = packed.instantiate()
	auto_free(pivot)
	assert_float(pivot.follow_speed).is_equal(5.0)

func test_spring_arm_uses_isometric_orientation() -> void:
	var packed := load(CameraRigPaths.RIG_SCENE) as PackedScene
	var rig: CameraPivot = packed.instantiate()
	auto_free(rig)
	add_child(rig)
	await await_idle_frame()
	var spring: SpringArm3D = rig.get_node("SpringArm3D")
	assert_float(spring.rotation_degrees.x).is_equal_approx(-60.0, 0.01)
	assert_float(spring.rotation_degrees.y).is_equal_approx(180.0, 0.01)
	assert_float(spring.spring_length).is_equal_approx(16.0, 0.01)

func test_spring_length_setter_updates_arm_at_runtime() -> void:
	var packed := load(CameraRigPaths.RIG_SCENE) as PackedScene
	var rig: CameraPivot = packed.instantiate()
	auto_free(rig)
	add_child(rig)
	await await_idle_frame()
	rig.spring_length = 20.0
	var spring: SpringArm3D = rig.get_node("SpringArm3D")
	assert_float(spring.spring_length).is_equal_approx(20.0, 0.01)

func test_pivot_stays_without_player_target() -> void:
	var packed := load(CameraRigPaths.RIG_SCENE) as PackedScene
	var rig: CameraPivot = packed.instantiate()
	auto_free(rig)
	add_child(rig)
	var start := rig.global_position
	await await_idle_frame()
	await await_idle_frame()
	assert_vector(rig.global_position).is_equal(start)

func test_pivot_snaps_to_player_on_ready_in_world_scene() -> void:
	var packed := load("res://world/test_scene.tscn") as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	add_child(scene)
	await await_idle_frame()
	var pivot: CameraPivot = scene.get_node(CameraRigPaths.RIG_ROOT_NAME)
	var player: CharacterBody3D = scene.get_node("Player")
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	assert_vector(pivot.global_position).is_equal_approx(player.global_position, Vector3(0.01, 0.01, 0.01))

func test_pivot_follows_player_in_world_scene() -> void:
	var packed := load("res://world/test_scene.tscn") as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	add_child(scene)
	await await_idle_frame()
	var pivot: CameraPivot = scene.get_node(CameraRigPaths.RIG_ROOT_NAME)
	var player: Node3D = scene.get_node("Player")
	pivot.follow_speed = 12.0
	pivot.global_position = player.global_position + Vector3(30.0, 0.0, 30.0)
	for _i in 60:
		await await_idle_frame()
	var distance_sq := pivot.global_position.distance_squared_to(player.global_position)
	assert_float(distance_sq).is_less(4.0)

func test_viewport_camera_is_rig_camera() -> void:
	var packed := load("res://world/test_scene.tscn") as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	add_child(scene)
	await await_idle_frame()
	var rig_camera: Camera3D = scene.get_node(CameraRigPaths.camera_path_from_world())
	assert_object(get_viewport().get_camera_3d()).is_same(rig_camera)

func test_camera_is_in_camera_group() -> void:
	var packed := load(CameraRigPaths.RIG_SCENE) as PackedScene
	var rig := packed.instantiate()
	auto_free(rig)
	var camera: Camera3D = rig.get_node(CameraRigPaths.CAMERA_RELATIVE)
	assert_bool(camera.is_in_group(CameraRigPaths.CAMERA_GROUP)).is_true()
