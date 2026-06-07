extends GdUnitTestSuite

func test_attack_action_exists() -> void:
	assert_bool(InputMap.has_action("attack")).is_true()

func test_attack_bound_to_right_mouse() -> void:
	var rmb := InputEventMouseButton.new()
	rmb.button_index = MOUSE_BUTTON_RIGHT
	assert_bool(InputMap.event_is_action(rmb, "attack")).is_true()
