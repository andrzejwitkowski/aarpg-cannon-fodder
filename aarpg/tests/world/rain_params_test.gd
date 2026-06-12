extends GdUnitTestSuite

func test_rain_params_rejects_placeholder() -> void:
	var raw := Resource.new()
	assert_bool(RainParams.is_instance_ready(raw)).is_false()

func test_rain_params_accepts_instance() -> void:
	var p := RainParams.new()
	assert_bool(RainParams.is_instance_ready(p)).is_true()

func test_rain_params_setters_emit_params_changed() -> void:
	var p := RainParams.new()
	var spy := monitor_signals(p)
	p.max_view_distance = 60.0
	await assert_signal(spy).is_emitted("params_changed")
