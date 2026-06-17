extends GdUnitTestSuite

func test_collect_blockers_no_hits() -> void:
	var query := func(_origin: Vector3, _target: Vector3) -> Dictionary:
		return {}
	var blockers := OcclusionRevealQuery.collect_blockers(
		null, Vector3(0, 5, 0), Vector3(0, 1, 0), PhysicsLayers.WORLD_MASK, query
	)
	assert_int(blockers.size()).is_equal(0)

func test_collect_blockers_single_hit() -> void:
	var body := StaticBody3D.new()
	var query := func(origin: Vector3, _target: Vector3) -> Dictionary:
		if origin.is_equal_approx(Vector3(0, 5, 0)):
			return {"collider": body, "position": Vector3(0, 3, 0)}
		return {}
	var blockers := OcclusionRevealQuery.collect_blockers(
		null, Vector3(0, 5, 0), Vector3(0, 1, 0), PhysicsLayers.WORLD_MASK, query
	)
	assert_int(blockers.size()).is_equal(1)
	assert_object(blockers[0]).is_same(body)
	body.free()

func test_collect_blockers_two_hits() -> void:
	var wall_a := StaticBody3D.new()
	var wall_b := StaticBody3D.new()
	var query := func(origin: Vector3, _target: Vector3) -> Dictionary:
		if origin.y > 9.5:
			return {"collider": wall_a, "position": Vector3(0, 7, 0)}
		if origin.y > 6.5:
			return {"collider": wall_b, "position": Vector3(0, 4, 0)}
		return {}
	var blockers := OcclusionRevealQuery.collect_blockers(
		null, Vector3(0, 10, 0), Vector3(0, 1, 0), PhysicsLayers.WORLD_MASK, query
	)
	assert_int(blockers.size()).is_equal(2)
	assert_object(blockers[0]).is_same(wall_a)
	assert_object(blockers[1]).is_same(wall_b)
	wall_a.free()
	wall_b.free()

func test_collect_blockers_zero_length_segment() -> void:
	var query := func(_origin: Vector3, _target: Vector3) -> Dictionary:
		return {"collider": StaticBody3D.new(), "position": Vector3.ZERO}
	var blockers := OcclusionRevealQuery.collect_blockers(
		null, Vector3.ONE, Vector3.ONE, PhysicsLayers.WORLD_MASK, query
	)
	assert_int(blockers.size()).is_equal(0)
