extends GdUnitTestSuite

const GRASS_FIELD_SCENE := "res://world/grass/grass_field.tscn"
const BLADE_SHADER := "res://assets/shaders/grass/grass_blade.gdshader"

func test_grass_params_rejects_placeholder() -> void:
	var raw := Resource.new()
	assert_bool(GrassParams.is_instance_ready(raw)).is_false()

func test_grass_params_accepts_instance() -> void:
	var p := GrassParams.new()
	assert_bool(GrassParams.is_instance_ready(p)).is_true()

func test_blade_shader_loads() -> void:
	var shader := load(BLADE_SHADER) as Shader
	assert_object(shader).is_not_null()

func test_grass_field_has_no_external_fan_api() -> void:
	var packed := load(GRASS_FIELD_SCENE) as PackedScene
	var field := packed.instantiate() as GrassField
	auto_free(field)
	assert_bool(field.has_method("register_fan")).is_false()
	assert_bool(field.has_method("unregister_fan")).is_false()
	assert_bool(field.has_method("get_fan_count")).is_false()

func test_grass_params_have_no_external_fan_properties() -> void:
	var property_names := _property_names(GrassParams.new())
	assert_bool(property_names.has("bend_map_resolution")).is_false()
	assert_bool(property_names.has("max_fans")).is_false()

func test_blade_shader_has_no_external_bend_map_sampling() -> void:
	var source := FileAccess.get_file_as_string(BLADE_SHADER)
	assert_bool(source.contains("bend_map")).is_false()
	assert_bool(source.contains("fan_push")).is_false()

func test_grass_field_placement_on_plane() -> void:
	var packed := load(GRASS_FIELD_SCENE) as PackedScene
	var field := packed.instantiate() as GrassField
	auto_free(field)
	var surface := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(10.0, 10.0)
	surface.mesh = plane
	field.add_child(surface)
	field.surface = field.get_path_to(surface)
	field.params = GrassParams.new()
	field.params.max_instances = 37
	add_child(field)
	await _wait_for_grass_rebuild(field, 37)
	var mm := field.get_node("GrassBlades") as MultiMeshInstance3D
	assert_object(mm.multimesh).is_not_null()
	assert_int(mm.multimesh.instance_count).is_equal(37)
	assert_float(mm.custom_aabb.size.length()).is_greater(0.0)
	var world_pos := field.global_transform * mm.multimesh.get_instance_transform(0).origin
	var half_size := plane.size * 0.5
	assert_float(world_pos.x).is_greater_equal(-half_size.x)
	assert_float(world_pos.x).is_less_equal(half_size.x)
	assert_float(world_pos.z).is_greater_equal(-half_size.y)
	assert_float(world_pos.z).is_less_equal(half_size.y)

func test_grass_blades_are_owned_by_field() -> void:
	var packed := load(GRASS_FIELD_SCENE) as PackedScene
	var root := Node3D.new()
	auto_free(root)
	add_child(root)
	var surface := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(4.0, 4.0)
	surface.mesh = plane
	root.add_child(surface)
	var field := packed.instantiate() as GrassField
	root.add_child(field)
	field.surface = field.get_path_to(surface)
	field.params = GrassParams.new()
	field.params.max_instances = 64
	await _wait_for_grass_rebuild(field, 64)
	var mm := field.get_node("GrassBlades") as MultiMeshInstance3D
	assert_object(mm).is_not_null()
	assert_object(mm.get_parent()).is_same(field)

func test_grass_field_placement_spreads_instances_across_plane() -> void:
	var packed := load(GRASS_FIELD_SCENE) as PackedScene
	var field := packed.instantiate() as GrassField
	auto_free(field)
	var surface := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(4.0, 4.0)
	surface.mesh = plane
	field.add_child(surface)
	field.surface = field.get_path_to(surface)
	field.params = GrassParams.new()
	field.params.max_instances = 400
	add_child(field)
	await _wait_for_grass_rebuild(field, 400)
	var mm := field.get_node("GrassBlades") as MultiMeshInstance3D
	assert_int(mm.multimesh.instance_count).is_equal(400)
	var world_pos := field.global_transform * mm.multimesh.get_instance_transform(0).origin
	var half_size := plane.size * 0.5
	assert_float(world_pos.x).is_greater_equal(-half_size.x)
	assert_float(world_pos.x).is_less_equal(half_size.x)
	assert_float(world_pos.z).is_greater_equal(-half_size.y)
	assert_float(world_pos.z).is_less_equal(half_size.y)

func test_mesh_surface_sampling_stays_inside_triangle_mesh() -> void:
	var packed := load(GRASS_FIELD_SCENE) as PackedScene
	var field := packed.instantiate() as GrassField
	auto_free(field)
	var surface := MeshInstance3D.new()
	surface.mesh = _build_triangle_mesh()
	field.add_child(surface)
	field.surface = field.get_path_to(surface)
	field.params = GrassParams.new()
	field.params.max_instances = 37
	add_child(field)
	await _wait_for_grass_rebuild(field, 37)
	var mm := field.get_node("GrassBlades") as MultiMeshInstance3D
	assert_int(mm.multimesh.instance_count).is_equal(37)
	for i in mm.multimesh.instance_count:
		var origin := mm.multimesh.get_instance_transform(i).origin
		assert_float(origin.x).is_greater_equal(-0.001)
		assert_float(origin.z).is_greater_equal(-0.001)
		assert_float(origin.x + origin.z).is_less_equal(4.001)

func test_max_instances_respects_plane_instance_cap() -> void:
	var packed := load(GRASS_FIELD_SCENE) as PackedScene
	var field := packed.instantiate() as GrassField
	auto_free(field)
	var surface := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(10.0, 10.0)
	surface.mesh = plane
	field.add_child(surface)
	field.surface = field.get_path_to(surface)
	field.params = GrassParams.new()
	field.params.max_instances = 100
	add_child(field)
	await _wait_for_grass_rebuild(field, 100)
	var mm := field.get_node("GrassBlades") as MultiMeshInstance3D
	assert_int(mm.multimesh.instance_count).is_equal(100)

func test_runtime_without_interaction_uses_no_interactors() -> void:
	var packed := load(GRASS_FIELD_SCENE) as PackedScene
	var field := packed.instantiate() as GrassField
	auto_free(field)
	add_child(field)
	var player := _spawn_test_player()
	field.runtime_interaction_enabled = false
	assert_int(field._interactor_data(false)["count"]).is_equal(0)
	player.remove_from_group(PlayerUtils.GROUP)

func test_runtime_with_interaction_collects_player() -> void:
	var packed := load(GRASS_FIELD_SCENE) as PackedScene
	var field := packed.instantiate() as GrassField
	auto_free(field)
	add_child(field)
	var player := _spawn_test_player()
	field.runtime_interaction_enabled = true
	assert_int(field._interactor_data(false)["count"]).is_equal(1)
	player.remove_from_group(PlayerUtils.GROUP)

func test_runtime_without_wind_uses_zero_wind_strength() -> void:
	var packed := load(GRASS_FIELD_SCENE) as PackedScene
	var field := packed.instantiate() as GrassField
	auto_free(field)
	field.params = GrassParams.new()
	field.runtime_wind_enabled = false
	assert_float(field._wind_strength_for_shader(false)).is_equal(0.0)

func test_runtime_with_wind_uses_param_wind_strength() -> void:
	var packed := load(GRASS_FIELD_SCENE) as PackedScene
	var field := packed.instantiate() as GrassField
	auto_free(field)
	field.params = GrassParams.new()
	field.params.wind_strength = 0.25
	field.runtime_wind_enabled = true
	assert_float(field._wind_strength_for_shader(false)).is_equal(0.25)

func test_editor_preview_wind_controls_wind_strength() -> void:
	var packed := load(GRASS_FIELD_SCENE) as PackedScene
	var field := packed.instantiate() as GrassField
	auto_free(field)
	field.params = GrassParams.new()
	field.params.wind_strength = 0.25
	field.editor_preview_wind = false
	assert_float(field._wind_strength_for_shader(true)).is_equal(0.0)
	field.editor_preview_wind = true
	assert_float(field._wind_strength_for_shader(true)).is_equal(0.25)

func after() -> void:
	_cleanup_test_players()

func _wait_for_grass_rebuild(field: GrassField, expected_count: int) -> void:
	for _i in 120:
		await await_idle_frame()
		var mm := field.get_node_or_null("GrassBlades") as MultiMeshInstance3D
		if mm != null and mm.multimesh != null and mm.multimesh.instance_count == expected_count:
			return

func _cleanup_test_players() -> void:
	for node in get_tree().get_nodes_in_group(PlayerUtils.GROUP):
		if node is CharacterBody3D:
			node.remove_from_group(PlayerUtils.GROUP)

func _spawn_test_player() -> CharacterBody3D:
	var player := CharacterBody3D.new()
	auto_free(player)
	player.add_to_group(PlayerUtils.GROUP)
	add_child(player)
	return player

func _build_triangle_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_vertex(Vector3(0.0, 0.0, 0.0))
	st.add_vertex(Vector3(4.0, 0.0, 0.0))
	st.add_vertex(Vector3(0.0, 0.0, 4.0))
	return st.commit()

func _property_names(resource: Resource) -> Array[StringName]:
	var names: Array[StringName] = []
	for property in resource.get_property_list():
		names.append(StringName(property["name"]))
	return names
