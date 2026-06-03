extends GdUnitTestSuite

func test_world_mask_matches_world_layer() -> void:
	assert_int(PhysicsLayers.WORLD_MASK).is_equal(PhysicsLayers.WORLD)

func test_enemy_layer_is_bit_four() -> void:
	assert_int(PhysicsLayers.ENEMY).is_equal(8)

func test_combat_target_mask_includes_world_combat_enemy() -> void:
	assert_int(PhysicsLayers.COMBAT_TARGET_MASK).is_equal(
		PhysicsLayers.WORLD | PhysicsLayers.COMBAT | PhysicsLayers.ENEMY
	)
