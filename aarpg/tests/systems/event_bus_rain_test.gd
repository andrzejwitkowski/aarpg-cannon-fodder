extends GdUnitTestSuite

func test_rain_signals_exist() -> void:
	assert_signal(EventBus).is_signal_exists("rain_intensity_changed")
	assert_signal(EventBus).is_signal_exists("rain_zone_entered")
	assert_signal(EventBus).is_signal_exists("rain_zone_exited")

func test_rain_signals_emit() -> void:
	var intensity_spy := monitor_signals(EventBus)
	var entered_spy := monitor_signals(EventBus)
	var exited_spy := monitor_signals(EventBus)
	var zone := Node.new()
	auto_free(zone)
	EventBus.rain_intensity_changed.emit(0.5)
	EventBus.rain_zone_entered.emit(zone)
	EventBus.rain_zone_exited.emit(zone)
	await assert_signal(intensity_spy).is_emitted("rain_intensity_changed", [0.5])
	await assert_signal(entered_spy).is_emitted("rain_zone_entered", [zone])
	await assert_signal(exited_spy).is_emitted("rain_zone_exited", [zone])
