class_name WaterHeightQuery extends RefCounted

const SHADER_PATH := "res://assets/shaders/water/height_query.glsl"
const MAX_POINTS := 64

var rd: RenderingDevice
var compute: WaterCompute
var params: WaterParams
var shader: RID
var pipeline: RID
var query_in: RID
var query_out: RID
var query_ubo: RID
var _uset: RID
var ready := false

func setup(water_compute: WaterCompute, water_params: WaterParams) -> bool:
	compute = water_compute
	params = water_params
	rd = water_compute.rd
	if rd == null:
		return false
	var file: RDShaderFile = load(SHADER_PATH)
	if file == null:
		return false
	shader = rd.shader_create_from_spirv(file.get_spirv())
	pipeline = rd.compute_pipeline_create(shader)
	query_in = rd.storage_buffer_create(MAX_POINTS * 8)
	query_out = rd.storage_buffer_create(MAX_POINTS * 16)
	var ubo_bytes := PackedByteArray()
	ubo_bytes.resize(16)
	ubo_bytes.encode_float(0, params.length_scale)
	ubo_bytes.encode_s32(4, params.fft_resolution)
	query_ubo = rd.uniform_buffer_create(16, ubo_bytes)
	_uset = rd.uniform_set_create([
		_make_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 0, query_in),
		_make_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 1, query_out),
		_make_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 2, compute.get_displacement_rd_texture()),
		_make_uniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER, 3, query_ubo),
	], shader, 0)
	ready = shader.is_valid() and pipeline.is_valid() and _uset.is_valid()
	return ready

func teardown() -> void:
	if rd == null:
		return
	for rid in [shader, pipeline, query_in, query_out, query_ubo, _uset]:
		if rid.is_valid():
			rd.free_rid(rid)
	_uset = RID()
	ready = false

func sample_height(world_xz: Vector2) -> float:
	var heights := sample_heights(PackedVector2Array([world_xz]))
	return heights[0] if heights.size() > 0 else 0.0

func sample_heights(positions: PackedVector2Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	if not ready or positions.is_empty():
		return out
	var count := mini(positions.size(), MAX_POINTS)
	var data := PackedFloat32Array()
	data.resize(count * 2)
	for i in count:
		data[i * 2] = positions[i].x
		data[i * 2 + 1] = positions[i].y
	rd.buffer_update(query_in, 0, count * 8, data.to_byte_array())
	rd.buffer_update(query_ubo, 0, 16, _query_ubo_bytes(count))
	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, pipeline)
	rd.compute_list_bind_uniform_set(cl, _uset, 0)
	rd.compute_list_dispatch(cl, maxi(1, (count + 63) / 64), 1, 1)
	rd.compute_list_end()
	rd.submit()
	rd.sync()
	var raw := rd.buffer_get_data(query_out).to_float32_array()
	out.resize(count)
	for i in count:
		out[i] = raw[i * 4 + 1]
	return out

func _query_ubo_bytes(point_count: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(16)
	bytes.encode_float(0, params.length_scale)
	bytes.encode_s32(4, params.fft_resolution)
	bytes.encode_s32(8, point_count)
	return bytes

func _make_uniform(utype: RenderingDevice.UniformType, binding: int, rid: RID) -> RDUniform:
	var u := RDUniform.new()
	u.uniform_type = utype
	u.binding = binding
	u.add_id(rid)
	return u
