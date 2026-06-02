extends GdUnitTestSuite

func test_instance_returns_null_when_no_player() -> void:
	assert_object(PlayerUtils.instance()).is_null()

func test_global_position_returns_zero_when_no_player() -> void:
	assert_vector(PlayerUtils.global_position()).is_equal(Vector3.ZERO)
