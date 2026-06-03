extends GdUnitTestSuite

func test_signals_exist() -> void:
	assert_signal(EventBus).is_signal_exists("character_moved")
	assert_signal(EventBus).is_signal_exists("hit_received")
	assert_signal(EventBus).is_signal_exists("enemy_hit")
