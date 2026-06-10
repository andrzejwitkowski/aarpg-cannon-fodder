extends GdUnitTestSuite

const MARKER_SCENE := "res://player/click_marker/click_marker.tscn"

func test_play_positions_marker_and_finishes_invisible() -> void:
	var root := Node3D.new()
	auto_free(root)
	add_child(root)
	var marker := (load(MARKER_SCENE) as PackedScene).instantiate() as ClickMarker
	marker.duration = 0.2
	marker.dissolve_duration = 0.1
	root.add_child(marker)
	marker.play(Vector3(3.0, 0.0, 5.0))
	assert_vector(marker.global_position).is_equal(Vector3(3.0, marker.ground_offset, 5.0))
	await await_millis(400)
	assert_bool(is_instance_valid(marker)).is_true()
	var mat := marker.get_node("MeshInstance3D").material_override as ShaderMaterial
	assert_float(mat.get_shader_parameter("dissolve")).is_equal_approx(1.0, 0.05)

func test_expand_reaches_one_before_dissolve() -> void:
	var root := Node3D.new()
	auto_free(root)
	add_child(root)
	var marker := (load(MARKER_SCENE) as PackedScene).instantiate() as ClickMarker
	marker.duration = 0.1
	marker.dissolve_duration = 0.5
	root.add_child(marker)
	var mat := marker.get_node("MeshInstance3D").material_override as ShaderMaterial
	marker.play(Vector3.ZERO)
	await await_millis(120)
	assert_float(mat.get_shader_parameter("expand")).is_equal_approx(1.0, 0.05)
	assert_float(mat.get_shader_parameter("dissolve")).is_equal_approx(0.0, 0.05)

func test_dissolve_clears_circle() -> void:
	var root := Node3D.new()
	auto_free(root)
	add_child(root)
	var marker := (load(MARKER_SCENE) as PackedScene).instantiate() as ClickMarker
	marker.duration = 0.05
	marker.dissolve_duration = 0.1
	root.add_child(marker)
	var mat := marker.get_node("MeshInstance3D").material_override as ShaderMaterial
	marker.play(Vector3.ZERO)
	await await_millis(int((marker.duration + marker.dissolve_duration) * 1000.0) + 50)
	assert_float(mat.get_shader_parameter("dissolve")).is_equal_approx(1.0, 0.05)

func test_play_replaces_running_animation() -> void:
	var root := Node3D.new()
	auto_free(root)
	add_child(root)
	var marker := (load(MARKER_SCENE) as PackedScene).instantiate() as ClickMarker
	marker.duration = 1.0
	marker.dissolve_duration = 1.0
	marker.cancel_duration = 0.05
	root.add_child(marker)
	marker.play(Vector3(1.0, 0.0, 1.0))
	await await_millis(50)
	marker.play(Vector3(9.0, 0.0, 9.0))
	await await_millis(80)
	assert_vector(marker.global_position).is_equal(Vector3(9.0, marker.ground_offset, 9.0))
	var mat := marker.get_node("MeshInstance3D").material_override as ShaderMaterial
	assert_float(mat.get_shader_parameter("expand")).is_less(0.5)
