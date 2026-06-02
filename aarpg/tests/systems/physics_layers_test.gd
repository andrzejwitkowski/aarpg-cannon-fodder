extends GdUnitTestSuite

func test_world_mask_matches_world_layer() -> void:
	assert_int(PhysicsLayers.WORLD_MASK).is_equal(PhysicsLayers.WORLD)
