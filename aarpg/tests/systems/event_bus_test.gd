extends GdUnitTestSuite

func test_signals_exist() -> void:
	var bus := get_tree().root.get_node_or_null("EventBus")
	assert_object(bus).is_not_null()
	assert_signal(bus).is_signal_exists("character_moved")
	assert_signal(bus).is_signal_exists("hit_received")
	assert_signal(bus).is_signal_exists("enemy_hit")
