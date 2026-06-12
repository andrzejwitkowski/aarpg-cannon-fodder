@tool
class_name WaterPlane extends Node3D

@export var params: WaterParams:
	set(v):
		_disconnect_params()
		params = v if v != null else WaterParams.new()
		_init_failed = false
		if _params_ready():
			_connect_params()
		if _initialized:
			_teardown_simulation()
		_request_init_simulation()
@export_category("Mesh")
@export var plane_size: float = 400.0:
	set(v):
		plane_size = maxf(v, 1.0)
		_rebuild_mesh()
@export var mesh_subdivisions: int = 256:
	set(v):
		mesh_subdivisions = clampi(v, 16, 512)
		_rebuild_mesh()
@export_category("Editor Preview")
@export var editor_preview_enabled: bool = true
@export var editor_max_fps: float = 30.0
@export var editor_show_spray: bool = true

var _mesh_instance: MeshInstance3D
var _compute: WaterCompute
var _height_query: WaterHeightQuery
var _spray: WaterSpray
var _material: ShaderMaterial
var _detail_tex: ImageTexture
var _sim_time: float = 0.0
var _editor_accum: float = 0.0
var _editor_tick: float = 0.0
var _initialized := false
var _init_failed := false
var _sim_n := -1

func _ready() -> void:
	if params == null:
		params = WaterParams.new()
	_ensure_mesh()
	if _params_ready():
		_connect_params()
	_request_init_simulation()

func _exit_tree() -> void:
	_teardown_simulation()
	_disconnect_params()

func _process(delta: float) -> void:
	if not _params_ready():
		if _initialized:
			_teardown_simulation()
		return
	if not _initialized:
		_request_init_simulation()
		return
	var run := not Engine.is_editor_hint() or editor_preview_enabled
	if not run:
		return
	if Engine.is_editor_hint():
		_editor_tick += delta
		var interval := 1.0 / maxf(editor_max_fps, 1.0)
		if _editor_tick < interval:
			return
		var step_dt := _editor_tick
		_editor_accum += step_dt
		_editor_tick = 0.0
		_step(_editor_accum, step_dt)
	else:
		_sim_time += delta * params.time_scale
		_step(_sim_time, delta)

func sample_height(world_pos: Vector3) -> float:
	if _height_query == null or not _height_query.ready:
		return 0.0
	var local_pos := to_local(world_pos)
	return global_position.y + _height_query.sample_height(Vector2(local_pos.x, local_pos.z))

func sample_heights(world_positions: PackedVector3Array) -> PackedFloat32Array:
	if _height_query == null or not _height_query.ready:
		var empty := PackedFloat32Array()
		empty.resize(world_positions.size())
		return empty
	var xz := PackedVector2Array()
	xz.resize(world_positions.size())
	for i in world_positions.size():
		var local_pos := to_local(world_positions[i])
		xz[i] = Vector2(local_pos.x, local_pos.z)
	var heights := _height_query.sample_heights(xz)
	for i in heights.size():
		heights[i] += global_position.y
	return heights

func _request_init_simulation() -> void:
	if not is_inside_tree():
		return
	if Engine.is_editor_hint() and not editor_preview_enabled:
		return
	if _init_failed:
		return
	if not _params_ready():
		return
	_init_simulation()

func _init_simulation() -> void:
	if not is_inside_tree() or not _params_ready():
		return
	_ensure_mesh()
	if _mesh_instance == null:
		return
	var rd := RenderingServer.get_rendering_device()
	if rd == null:
		_init_failed = true
		return
	_teardown_simulation()
	_compute = WaterCompute.new()
	if not _compute.setup(params):
		_compute.teardown()
		_compute = null
		_init_failed = true
		return
	_compute.update_initial_spectrum(params)
	_material = _mesh_instance.get_surface_override_material(0) as ShaderMaterial
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load("res://assets/shaders/water/water_surface.gdshader")
		_mesh_instance.set_surface_override_material(0, _material)
	_detail_tex = ImageTexture.create_from_image(WaterDetail.bake())
	_push_shader_uniforms()
	if not Engine.is_editor_hint():
		_height_query = WaterHeightQuery.new()
		_height_query.setup(_compute, params)
	_spray = WaterSpray.new()
	_spray.setup(self, _compute, params)
	_sim_n = params.fft_resolution
	_initialized = true
	_step(0.0, 1.0 / 60.0)

func _teardown_simulation() -> void:
	_initialized = false
	if _spray != null:
		_spray.teardown()
		_spray = null
	if _height_query != null:
		_height_query.teardown()
		_height_query = null
	if _compute != null:
		_compute.teardown()
		_compute = null

func _step(time: float, dt: float) -> void:
	if _compute == null or not _params_ready():
		return
	_compute.evolve(params, time, dt)
	_push_shader_uniforms()
	if _spray != null and (not Engine.is_editor_hint() or editor_show_spray):
		var cam := _get_camera_pos()
		var wind_dir := deg_to_rad(params.wind_direction_deg)
		var wind := Vector3(cos(wind_dir), 0.0, sin(wind_dir)) * params.wind_speed * 0.1
		_spray.update(dt, cam, wind)

func _push_shader_uniforms() -> void:
	if _material == null or _compute == null or not _params_ready():
		return
	_material.set_shader_parameter("displacement_tex", _compute.get_displacement_texture())
	_material.set_shader_parameter("derivatives_tex", _compute.get_derivatives_texture())
	_material.set_shader_parameter("detail_tex", _detail_tex)
	_material.set_shader_parameter("length_scale", params.length_scale)
	_material.set_shader_parameter("time_elapsed", _sim_time if not Engine.is_editor_hint() else _editor_accum)
	_material.set_shader_parameter("detail_strength", params.detail_strength)
	_material.set_shader_parameter("foam_threshold", params.foam_threshold)
	_material.set_shader_parameter("foam_scale", params.foam_scale)
	_material.set_shader_parameter("sss_strength", params.sss_strength)
	_material.set_shader_parameter("deep_color", params.deep_color)
	_material.set_shader_parameter("scatter_color", params.scatter_color)
	_material.set_shader_parameter("foam_color", params.foam_color)

func _ensure_mesh() -> void:
	if _mesh_instance != null and is_instance_valid(_mesh_instance):
		return
	for child in get_children():
		if child is MeshInstance3D:
			_mesh_instance = child
			return
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "WaterMesh"
	add_child(_mesh_instance)
	if Engine.is_editor_hint():
		_mesh_instance.owner = get_tree().edited_scene_root if get_tree() != null else self
	_rebuild_mesh()

func _rebuild_mesh() -> void:
	if _mesh_instance == null:
		return
	var plane := PlaneMesh.new()
	plane.size = Vector2(plane_size, plane_size)
	plane.subdivide_width = mesh_subdivisions
	plane.subdivide_depth = mesh_subdivisions
	_mesh_instance.mesh = plane

func _params_ready() -> bool:
	return WaterParams.is_instance_ready(params)

func _connect_params() -> void:
	if not _params_ready():
		return
	if not params.spectrum_changed.is_connected(_on_spectrum_changed):
		params.spectrum_changed.connect(_on_spectrum_changed)
	if not params.runtime_changed.is_connected(_on_runtime_changed):
		params.runtime_changed.connect(_on_runtime_changed)
	if not params.noise_regenerate_requested.is_connected(_on_noise_regenerate):
		params.noise_regenerate_requested.connect(_on_noise_regenerate)

func _disconnect_params() -> void:
	if not _params_ready():
		return
	if params.spectrum_changed.is_connected(_on_spectrum_changed):
		params.spectrum_changed.disconnect(_on_spectrum_changed)
	if params.runtime_changed.is_connected(_on_runtime_changed):
		params.runtime_changed.disconnect(_on_runtime_changed)
	if params.noise_regenerate_requested.is_connected(_on_noise_regenerate):
		params.noise_regenerate_requested.disconnect(_on_noise_regenerate)

func _on_spectrum_changed() -> void:
	if not is_inside_tree() or not _params_ready():
		return
	_init_failed = false
	if _sim_n != params.fft_resolution:
		_teardown_simulation()
		_request_init_simulation()
		return
	if _compute != null and _compute.ready:
		_compute.update_initial_spectrum(params)
	else:
		_request_init_simulation()

func _on_runtime_changed() -> void:
	_push_shader_uniforms()

func _on_noise_regenerate() -> void:
	if _compute == null or not _params_ready():
		return
	_compute.regenerate_noise(randi())
	_compute.update_initial_spectrum(params)

func _get_camera_pos() -> Vector3:
	var vp := get_viewport()
	if vp == null:
		return global_position + Vector3(0.0, 10.0, 20.0)
	var cam := vp.get_camera_3d()
	return cam.global_position if cam != null else global_position + Vector3(0.0, 10.0, 20.0)
