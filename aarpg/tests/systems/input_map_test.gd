extends GdUnitTestSuite

func test_attack_action_exists() -> void:
	assert_bool(InputMap.has_action("attack")).is_true()
