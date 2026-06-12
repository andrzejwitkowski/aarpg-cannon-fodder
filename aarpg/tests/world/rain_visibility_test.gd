extends GdUnitTestSuite

func test_is_aabb_in_frustum_with_orthographic_camera() -> void:
	var root := Node3D.new()
	auto_free(root)
	add_child(root)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 20.0
	camera.far = 100.0
	camera.near = 0.1
	camera.position = Vector3(0.0, 20.0, 0.0)
	camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	root.add_child(camera)
	await get_tree().process_frame
	var visible_aabb := AABB(Vector3(-2.0, -1.0, -2.0), Vector3(4.0, 2.0, 4.0))
	assert_bool(RainVisibility.is_aabb_in_frustum(camera, visible_aabb)).is_true()

func test_is_aabb_in_frustum_rejects_far_aabb() -> void:
	var root := Node3D.new()
	auto_free(root)
	add_child(root)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.0
	camera.far = 20.0
	camera.near = 0.1
	camera.position = Vector3(0.0, 5.0, 0.0)
	camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	root.add_child(camera)
	await get_tree().process_frame
	var far_aabb := AABB(Vector3(0.0, -50.0, 0.0), Vector3(2.0, 2.0, 2.0))
	assert_bool(RainVisibility.is_aabb_in_frustum(camera, far_aabb)).is_false()

func test_distance_factor_at_origin() -> void:
	assert_float(RainVisibility.distance_factor(Vector3.ZERO, Vector3.ZERO, 80.0)).is_equal(1.0)

func test_distance_factor_beyond_max() -> void:
	assert_float(RainVisibility.distance_factor(Vector3.ZERO, Vector3(100.0, 0.0, 0.0), 80.0)).is_equal(0.0)
