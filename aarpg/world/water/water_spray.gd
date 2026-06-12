class_name WaterSpray extends RefCounted

const SHADER_PATH := "res://assets/shaders/water/spray_simulate.glsl"

var rd: RenderingDevice
var compute: WaterCompute
var params: WaterParams
var shader: RID
var pipeline: RID
var pos_life: RID
var vel_life: RID
var spray_ubo: RID
var multimesh: MultiMeshInstance3D
var _parent: Node3D
var _uset: RID
var count: int
var frame: int
var ready := false

func setup(parent: Node3D, water_compute: WaterCompute, water_params: WaterParams) -> void:
	_parent = parent
	compute = water_compute
	params = water_params
	rd = water_compute.rd
	count = params.spray_count
	if rd == null:
		return
	var file: RDShaderFile = load(SHADER_PATH)
	if file == null:
		return
	shader = rd.shader_create_from_spirv(file.get_spirv())
	pipeline = rd.compute_pipeline_create(shader)
	pos_life = rd.storage_buffer_create(count * 16)
	vel_life = rd.storage_buffer_create(count * 16)
	spray_ubo = rd.storage_buffer_create(64)
	multimesh = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = count
	mm.mesh = SphereMesh.new()
	(mm.mesh as SphereMesh).radius = 0.08
	(mm.mesh as SphereMesh).height = 0.16
	multimesh.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = params.foam_color
	mat.emission_enabled = true
	mat.emission = params.foam_color
	mat.emission_energy_multiplier = 0.5
	mat.vertex_color_use_as_albedo = true
	multimesh.material_override = mat
	parent.add_child(multimesh)
	_uset = rd.uniform_set_create([
		_make_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 0, pos_life),
		_make_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 1, vel_life),
		_make_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 2, compute.get_displacement_rd_texture()),
		_make_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 3, spray_ubo),
	], shader, 0)
	ready = _uset.is_valid()

func teardown() -> void:
	if multimesh != null and is_instance_valid(multimesh):
		multimesh.queue_free()
	if rd == null:
		return
	for rid in [shader, pipeline, pos_life, vel_life, spray_ubo, _uset]:
		if rid.is_valid():
			rd.free_rid(rid)
	_uset = RID()
	ready = false

func update(dt: float, cam_pos: Vector3, wind: Vector3) -> void:
	if not ready or not params.spray_enabled:
		if multimesh != null:
			multimesh.visible = false
		return
	multimesh.visible = true
	frame = (frame + 1) % 100000
	var ubo := PackedFloat32Array([
		minf(dt, 0.05), float(frame) * 1.7, cam_pos.x, cam_pos.z,
		wind.x, wind.y, wind.z, 130.0,
		0.85, 0.3, 2.5, params.foam_threshold,
		_parent.global_position.y, params.length_scale, float(params.fft_resolution), float(count),
	])
	rd.buffer_update(spray_ubo, 0, ubo.size() * 4, ubo.to_byte_array())
	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, pipeline)
	rd.compute_list_bind_uniform_set(cl, _uset, 0)
	rd.compute_list_dispatch(cl, maxi(1, (count + 63) / 64), 1, 1)
	rd.compute_list_end()
	rd.submit()
	rd.sync()
	_sync_multimesh()

func _sync_multimesh() -> void:
	var data := rd.buffer_get_data(pos_life).to_float32_array()
	var mm := multimesh.multimesh
	for i in count:
		var life := data[i * 4 + 3]
		var alive := clampf(life * 1000.0, 0.0, 1.0)
		var world_pos := Vector3(data[i * 4], data[i * 4 + 1], data[i * 4 + 2])
		var pos := _parent.to_local(world_pos)
		var xform := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * alive * 0.5), pos)
		mm.set_instance_transform(i, xform)
		mm.set_instance_color(i, Color(1.0, 1.0, 1.0, alive))

func _make_uniform(utype: RenderingDevice.UniformType, binding: int, rid: RID) -> RDUniform:
	var u := RDUniform.new()
	u.uniform_type = utype
	u.binding = binding
	u.add_id(rid)
	return u
