extends GdUnitTestSuite

func test_fft_impulse_and_sinusoid() -> void:
	var rd := RenderingServer.get_rendering_device()
	if rd == null:
		push_warning("Skipping FFT test: no RenderingDevice")
		return
	var params := WaterParams.new()
	params.fft_resolution = 64
	var compute := WaterCompute.new()
	assert_bool(compute.setup(params)).is_true()
	var result: Dictionary = compute.validate_fft()
	assert_bool(result.pass).override_failure_message("FFT validation failed err1=%s err2=%s" % [result.err1, result.err2]).is_true()
	compute.teardown()

func test_gaussian_noise_size() -> void:
	var data := WaterFft.gaussian_noise(64, 42)
	assert_int(data.size()).is_equal(64 * 64 * 2)

func test_water_params_resource() -> void:
	var params := WaterParams.new()
	params.wind_speed = 20.0
	var uniforms := params.fill_spectrum_uniforms()
	assert_float(uniforms[0]).is_equal_approx(9.81, 0.001)
	assert_float(uniforms[2]).is_greater(0.0)
