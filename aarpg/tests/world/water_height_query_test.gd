extends GdUnitTestSuite

func test_height_query_after_evolve() -> void:
	var rd := RenderingServer.get_rendering_device()
	if rd == null:
		push_warning("Skipping height query test: no RenderingDevice")
		return
	var packed := load("res://world/water/water_plane.tscn") as PackedScene
	assert_object(packed).is_not_null()
	var plane: WaterPlane = packed.instantiate()
	auto_free(plane)
	add_child(plane)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(absf(plane.sample_height(Vector3.ZERO))).is_less(50.0)

func test_water_plane_scene_loads() -> void:
	assert_object(load("res://world/water/water_plane.tscn")).is_not_null()
