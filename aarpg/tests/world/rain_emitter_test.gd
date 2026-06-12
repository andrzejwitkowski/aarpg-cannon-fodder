extends GdUnitTestSuite

const EMITTER_SCENE := "res://world/rain/rain_emitter.tscn"
const OVERLAY_SCENE := "res://world/rain/rain_glass_overlay.tscn"

func test_emitter_joins_rain_emitter_group() -> void:
	var packed := load(EMITTER_SCENE) as PackedScene
	var emitter := packed.instantiate() as RainEmitter
	auto_free(emitter)
	add_child(emitter)
	assert_bool(emitter.is_in_group(RainEmitter.GROUP)).is_true()

func test_effective_intensity_zero_when_player_outside() -> void:
	var packed := load(EMITTER_SCENE) as PackedScene
	var emitter := packed.instantiate() as RainEmitter
	auto_free(emitter)
	emitter.params = RainParams.new()
	emitter.params.volume_size = Vector3(4.0, 4.0, 4.0)
	add_child(emitter)
	var player := _spawn_test_player(Vector3(20.0, 0.0, 20.0))
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(emitter.get_effective_intensity()).is_equal(0.0)
	player.remove_from_group(PlayerUtils.GROUP)

func test_effective_intensity_positive_when_player_inside() -> void:
	var packed := load(EMITTER_SCENE) as PackedScene
	var emitter := packed.instantiate() as RainEmitter
	auto_free(emitter)
	emitter.params = RainParams.new()
	emitter.params.volume_size = Vector3(20.0, 12.0, 20.0)
	emitter.params.strength = 1.0
	emitter.params.shelter_ray_height = 0.0
	add_child(emitter)
	var overlay_packed := load(OVERLAY_SCENE) as PackedScene
	var overlay := overlay_packed.instantiate() as RainGlassOverlay
	auto_free(overlay)
	add_child(overlay)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 40.0
	camera.far = 200.0
	camera.position = Vector3(0.0, 25.0, 0.0)
	camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	add_child(camera)
	camera.current = true
	var player := _spawn_test_player(Vector3.ZERO)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(emitter.get_effective_intensity()).is_greater(0.0)
	player.remove_from_group(PlayerUtils.GROUP)

func test_overlay_intensity_zero_when_camera_outside_column() -> void:
	var packed := load(EMITTER_SCENE) as PackedScene
	var emitter := packed.instantiate() as RainEmitter
	auto_free(emitter)
	emitter.params = RainParams.new()
	emitter.params.volume_size = Vector3(10.0, 10.0, 10.0)
	emitter.params.strength = 1.0
	emitter.params.shelter_ray_height = 0.0
	add_child(emitter)
	var camera := Camera3D.new()
	camera.current = true
	add_child(camera)
	camera.global_position = Vector3(40.0, 8.0, 0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(emitter.get_overlay_intensity()).is_equal(0.0)

func test_overlay_intensity_positive_when_camera_in_column() -> void:
	var packed := load(EMITTER_SCENE) as PackedScene
	var emitter := packed.instantiate() as RainEmitter
	auto_free(emitter)
	emitter.params = RainParams.new()
	emitter.params.volume_size = Vector3(20.0, 8.0, 20.0)
	emitter.params.strength = 1.0
	emitter.params.shelter_ray_height = 0.0
	add_child(emitter)
	var camera := Camera3D.new()
	camera.current = true
	add_child(camera)
	camera.global_position = Vector3(0.0, 22.0, 0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(emitter.get_overlay_intensity()).is_greater(0.0)

func test_is_global_point_inside_volume() -> void:
	var emitter := RainEmitter.new()
	auto_free(emitter)
	emitter.params = RainParams.new()
	emitter.params.volume_size = Vector3(10.0, 10.0, 10.0)
	add_child(emitter)
	assert_bool(emitter.is_global_point_inside_volume(Vector3.ZERO)).is_true()
	assert_bool(emitter.is_global_point_inside_volume(Vector3(20.0, 0.0, 0.0))).is_false()

func after() -> void:
	_cleanup_test_players()

func _spawn_test_player(position: Vector3) -> CharacterBody3D:
	var player := CharacterBody3D.new()
	auto_free(player)
	player.add_to_group(PlayerUtils.GROUP)
	player.global_position = position
	add_child(player)
	return player

func _cleanup_test_players() -> void:
	for node in get_tree().get_nodes_in_group(PlayerUtils.GROUP):
		if node is CharacterBody3D:
			node.remove_from_group(PlayerUtils.GROUP)
