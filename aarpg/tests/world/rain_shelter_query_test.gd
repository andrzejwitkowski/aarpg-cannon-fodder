extends GdUnitTestSuite

func test_compute_shelter_factor_no_hit() -> void:
	var query := func(_origin: Vector3, _height: float, _mask: int) -> float:
		return 1.0
	assert_float(
		RainShelterQuery.compute_shelter_factor(null, Vector3.ZERO, 10.0, 1, query)
	).is_equal(1.0)

func test_compute_shelter_factor_immediate_hit() -> void:
	var query := func(_origin: Vector3, _height: float, _mask: int) -> float:
		return 0.0
	assert_float(
		RainShelterQuery.compute_shelter_factor(null, Vector3.ZERO, 10.0, 1, query)
	).is_equal(0.0)

func test_overhead_ceiling_blocks_rain() -> void:
	var factor := RainShelterQuery._shelter_from_hit(
		Vector3.ZERO,
		{"position": Vector3(0.0, 3.0, 0.0), "normal": Vector3.DOWN}
	)
	assert_float(factor).is_equal(0.0)

func test_distant_hit_does_not_block_rain() -> void:
	var factor := RainShelterQuery._shelter_from_hit(
		Vector3.ZERO,
		{"position": Vector3(0.0, 25.0, 0.0), "normal": Vector3.DOWN}
	)
	assert_float(factor).is_equal(1.0)
