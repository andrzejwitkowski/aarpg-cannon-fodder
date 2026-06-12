class_name WaterCompute extends RefCounted

const SHADER_DIR := "res://assets/shaders/water/"

var rd: RenderingDevice
var n: int
var log_n: int
var ready := false

var noise_buffer: RID
var h0k_buffer: RID
var h0_buffer: RID
var waves_buffer: RID
var dx_dz: RID
var dy_dxz: RID
var dyx_dyz: RID
var dxx_dzz: RID
var scratch: Array[RID] = []
var turbulence_buffer: RID
var butterfly_buffer: RID
var displacement_tex: RID
var derivatives_tex: RID

var spectrum_ubo: RID
var grid_ubo: RID
var time_ubo: RID
var assemble_ubo: RID
var fft_ubo: RID

var shader_init: RID
var shader_conj: RID
var shader_time: RID
var shader_fft: RID
var shader_permute: RID
var shader_assemble: RID

var pipe_init: RID
var pipe_conj: RID
var pipe_time: RID
var pipe_fft: RID
var pipe_permute: RID
var pipe_assemble: RID

var uset_init: RID
var uset_conj: RID
var uset_time: RID
var uset_assemble: RID
var _fft_usets: Array[RID] = []
var _permute_usets: Array[RID] = []

var displacement_view: RID
var derivatives_view: RID

var _dispatch_xy: Vector2i

func setup(params: WaterParams) -> bool:
	rd = RenderingServer.get_rendering_device()
	if rd == null:
		return false
	n = params.fft_resolution
	log_n = WaterFft.log2_int(n)
	_dispatch_xy = Vector2i(maxi(1, n / 8), maxi(1, n / 8))
	_alloc_buffers()
	if not _load_pipelines():
		teardown()
		return false
	_build_uniform_sets(params)
	ready = true
	return true

func teardown() -> void:
	if rd == null:
		return
	if displacement_view.is_valid():
		RenderingServer.free_rid(displacement_view)
	if derivatives_view.is_valid():
		RenderingServer.free_rid(derivatives_view)
	for rid in [noise_buffer, h0k_buffer, h0_buffer, waves_buffer, dx_dz, dy_dxz, dyx_dyz, dxx_dzz, turbulence_buffer, butterfly_buffer, spectrum_ubo, grid_ubo, time_ubo, assemble_ubo, fft_ubo, displacement_tex, derivatives_tex]:
		if rid.is_valid():
			rd.free_rid(rid)
	for s in scratch:
		if s.is_valid():
			rd.free_rid(s)
	for rid in [shader_init, shader_conj, shader_time, shader_fft, shader_permute, shader_assemble, pipe_init, pipe_conj, pipe_time, pipe_fft, pipe_permute, pipe_assemble, uset_init, uset_conj, uset_time, uset_assemble]:
		if rid.is_valid():
			rd.free_rid(rid)
	for rid in _fft_usets + _permute_usets:
		if rid.is_valid():
			rd.free_rid(rid)
	_fft_usets.clear()
	_permute_usets.clear()
	ready = false

func regenerate_noise(seed: int) -> void:
	var data := WaterFft.gaussian_noise(n, seed)
	rd.buffer_update(noise_buffer, 0, data.size() * 4, data.to_byte_array())

func update_initial_spectrum(params: WaterParams) -> void:
	if not ready:
		return
	_update_spectrum_ubo(params)
	_reset_turbulence()
	_dispatch_init()
	_dispatch_conj()

func evolve(params: WaterParams, time: float, dt: float) -> void:
	if not ready:
		return
	_update_time_ubo(time)
	_update_assemble_ubo(params, dt)
	_dispatch_time()
	_run_fft_on_field(dx_dz, scratch[0], 0)
	_run_fft_on_field(dy_dxz, scratch[1], 1)
	_run_fft_on_field(dyx_dyz, scratch[2], 2)
	_run_fft_on_field(dxx_dzz, scratch[3], 3)
	_dispatch_assemble()

func get_displacement_texture() -> RID:
	return displacement_view

func get_derivatives_texture() -> RID:
	return derivatives_view

func get_displacement_rd_texture() -> RID:
	return displacement_tex

func validate_fft() -> Dictionary:
	if not ready:
		return {"pass": false, "err1": 1.0, "err2": 1.0}
	var err1 := _validate_impulse()
	var err2 := _validate_sinusoid()
	return {"pass": err1 < 1.0e-3 and err2 < 1.0e-3, "err1": err1, "err2": err2}

func _alloc_buffers() -> void:
	var n2 := n * n
	var vec2_bytes := n2 * 8
	noise_buffer = _make_storage_buffer(vec2_bytes)
	regenerate_noise(1)
	h0k_buffer = _make_storage_buffer(vec2_bytes)
	h0_buffer = _make_storage_buffer(n2 * 16)
	waves_buffer = _make_storage_buffer(n2 * 16)
	dx_dz = _make_storage_buffer(vec2_bytes)
	dy_dxz = _make_storage_buffer(vec2_bytes)
	dyx_dyz = _make_storage_buffer(vec2_bytes)
	dxx_dzz = _make_storage_buffer(vec2_bytes)
	scratch = [_make_storage_buffer(vec2_bytes), _make_storage_buffer(vec2_bytes), _make_storage_buffer(vec2_bytes), _make_storage_buffer(vec2_bytes)]
	var turb := PackedFloat32Array()
	turb.resize(n2)
	turb.fill(1.0)
	turbulence_buffer = _make_storage_buffer(n2 * 4, turb.to_byte_array())
	var butterfly := WaterFft.fill_butterfly(n)
	butterfly_buffer = _make_storage_buffer(butterfly.size() * 4, butterfly.to_byte_array())
	displacement_tex = _make_storage_tex()
	derivatives_tex = _make_storage_tex()
	grid_ubo = _make_int_uniform(n)
	time_ubo = _make_uniform_buffer(PackedFloat32Array([0.0, 0.0, 0.0, 0.0]).to_byte_array())
	assemble_ubo = _make_uniform_buffer(PackedFloat32Array([1.3, 1.0 / 60.0, 0.4, 0.0]).to_byte_array())
	var fft_pad := PackedByteArray()
	fft_pad.resize(16)
	fft_ubo = rd.uniform_buffer_create(16, fft_pad)
	var spec_pad := PackedFloat32Array()
	spec_pad.resize(32)
	spectrum_ubo = _make_storage_buffer(128, spec_pad.to_byte_array())

func _make_storage_buffer(size: int, data: PackedByteArray = PackedByteArray()) -> RID:
	if data.is_empty():
		return rd.storage_buffer_create(size)
	return rd.storage_buffer_create(size, data)

func _make_uniform_buffer(data: PackedByteArray) -> RID:
	return rd.uniform_buffer_create(data.size(), data)

func _make_int_uniform(value: int) -> RID:
	var bytes := PackedByteArray()
	bytes.resize(16)
	bytes.encode_s32(0, value)
	return rd.uniform_buffer_create(16, bytes)

func _encode_int_uniform(values: PackedInt32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(maxi(16, values.size() * 4))
	for i in values.size():
		bytes.encode_s32(i * 4, values[i])
	return bytes

func _make_storage_tex() -> RID:
	var tf := RDTextureFormat.new()
	tf.width = n
	tf.height = n
	tf.format = RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT
	tf.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	var tv := RDTextureView.new()
	return rd.texture_create(tf, tv)

func _load_pipelines() -> bool:
	shader_init = _shader(SHADER_DIR + "spectrum_init.glsl")
	shader_conj = _shader(SHADER_DIR + "spectrum_conjugate.glsl")
	shader_time = _shader(SHADER_DIR + "spectrum_time.glsl")
	shader_fft = _shader(SHADER_DIR + "fft_butterfly.glsl")
	shader_permute = _shader(SHADER_DIR + "fft_permute.glsl")
	shader_assemble = _shader(SHADER_DIR + "assemble_maps.glsl")
	if not shader_init.is_valid() \
	or not shader_conj.is_valid() \
	or not shader_time.is_valid() \
	or not shader_fft.is_valid() \
	or not shader_permute.is_valid() \
	or not shader_assemble.is_valid():
		return false
	pipe_init = rd.compute_pipeline_create(shader_init)
	pipe_conj = rd.compute_pipeline_create(shader_conj)
	pipe_time = rd.compute_pipeline_create(shader_time)
	pipe_fft = rd.compute_pipeline_create(shader_fft)
	pipe_permute = rd.compute_pipeline_create(shader_permute)
	pipe_assemble = rd.compute_pipeline_create(shader_assemble)
	if not pipe_init.is_valid() \
	or not pipe_conj.is_valid() \
	or not pipe_time.is_valid() \
	or not pipe_fft.is_valid() \
	or not pipe_permute.is_valid() \
	or not pipe_assemble.is_valid():
		return false
	return true

func _shader(path: String) -> RID:
	if not ResourceLoader.exists(path):
		push_error("WaterCompute: missing shader %s" % path)
		return RID()
	var file: RDShaderFile = load(path)
	if file == null:
		push_error("WaterCompute: failed to load %s" % path)
		return RID()
	return rd.shader_create_from_spirv(file.get_spirv())

func _build_uniform_sets(params: WaterParams) -> void:
	_update_spectrum_ubo(params)
	displacement_view = RenderingServer.texture_rd_create(displacement_tex)
	derivatives_view = RenderingServer.texture_rd_create(derivatives_tex)
	uset_init = rd.uniform_set_create([
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 0, [noise_buffer]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 1, [h0k_buffer]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 2, [waves_buffer]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 3, [spectrum_ubo]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER, 4, [grid_ubo]),
	], shader_init, 0)
	uset_conj = rd.uniform_set_create([
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 0, [h0k_buffer]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 1, [h0_buffer]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER, 2, [grid_ubo]),
	], shader_conj, 0)
	uset_time = rd.uniform_set_create([
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 0, [h0_buffer]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 1, [waves_buffer]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 2, [dx_dz]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 3, [dy_dxz]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 4, [dyx_dyz]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 5, [dxx_dzz]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER, 6, [time_ubo]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER, 7, [grid_ubo]),
	], shader_time, 0)
	uset_assemble = rd.uniform_set_create([
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 0, [dx_dz]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 1, [dy_dxz]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 2, [dyx_dyz]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 3, [dxx_dzz]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 4, [turbulence_buffer]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 5, [displacement_tex]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 6, [derivatives_tex]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER, 7, [assemble_ubo]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER, 8, [grid_ubo]),
	], shader_assemble, 0)
	_fft_usets = [
		_make_fft_uset(dx_dz, scratch[0]),
		_make_fft_uset(dy_dxz, scratch[1]),
		_make_fft_uset(dyx_dyz, scratch[2]),
		_make_fft_uset(dxx_dzz, scratch[3]),
	]
	_permute_usets = [
		_make_permute_uset(dx_dz),
		_make_permute_uset(dy_dxz),
		_make_permute_uset(dyx_dyz),
		_make_permute_uset(dxx_dzz),
	]

func _make_fft_uset(field_a: RID, field_b: RID) -> RID:
	return rd.uniform_set_create([
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 0, [field_a]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 1, [field_b]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 2, [butterfly_buffer]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER, 3, [fft_ubo]),
	], shader_fft, 0)

func _make_permute_uset(field: RID) -> RID:
	return rd.uniform_set_create([
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 0, [field]),
		_rd_uniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER, 1, [grid_ubo]),
	], shader_permute, 0)

func _rd_uniform(utype: RenderingDevice.UniformType, binding: int, rids: Array) -> RDUniform:
	var u := RDUniform.new()
	u.uniform_type = utype
	u.binding = binding
	u.add_id(rids[0])
	return u

func _update_spectrum_ubo(params: WaterParams) -> void:
	var data := params.fill_spectrum_uniforms()
	var bytes := PackedByteArray()
	bytes.resize(128)
	for i in mini(data.size(), 32):
		bytes.encode_float(i * 4, data[i])
	rd.buffer_update(spectrum_ubo, 0, bytes.size(), bytes)

func _update_time_ubo(time: float) -> void:
	rd.buffer_update(time_ubo, 0, 4, PackedFloat32Array([time]).to_byte_array())

func _update_assemble_ubo(params: WaterParams, dt: float) -> void:
	rd.buffer_update(assemble_ubo, 0, 16, PackedFloat32Array([params.choppiness, dt, params.foam_decay, 0.0]).to_byte_array())

func _reset_turbulence() -> void:
	var turb := PackedFloat32Array()
	turb.resize(n * n)
	turb.fill(1.0)
	rd.buffer_update(turbulence_buffer, 0, turb.size() * 4, turb.to_byte_array())

func _dispatch_init() -> void:
	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, pipe_init)
	rd.compute_list_bind_uniform_set(cl, uset_init, 0)
	rd.compute_list_dispatch(cl, _dispatch_xy.x, _dispatch_xy.y, 1)
	rd.compute_list_end()

func _dispatch_conj() -> void:
	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, pipe_conj)
	rd.compute_list_bind_uniform_set(cl, uset_conj, 0)
	rd.compute_list_dispatch(cl, _dispatch_xy.x, _dispatch_xy.y, 1)
	rd.compute_list_end()

func _dispatch_time() -> void:
	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, pipe_time)
	rd.compute_list_bind_uniform_set(cl, uset_time, 0)
	rd.compute_list_dispatch(cl, _dispatch_xy.x, _dispatch_xy.y, 1)
	rd.compute_list_end()

func _dispatch_assemble() -> void:
	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, pipe_assemble)
	rd.compute_list_bind_uniform_set(cl, uset_assemble, 0)
	rd.compute_list_dispatch(cl, _dispatch_xy.x, _dispatch_xy.y, 1)
	rd.compute_list_end()

func _run_fft_on_field(field: RID, field_scratch: RID, field_index: int) -> void:
	var ping := 0
	for step in log_n:
		_dispatch_fft(field_index, step, 0, ping)
		ping = 1 - ping
	for step in log_n:
		_dispatch_fft(field_index, step, 1, ping)
		ping = 1 - ping
	_dispatch_permute(field_index)
	if ping == 1:
		_copy_buffer(field_scratch, field)

func _dispatch_fft(field_index: int, step: int, axis: int, ping: int) -> void:
	rd.buffer_update(fft_ubo, 0, 16, _encode_int_uniform(PackedInt32Array([n, step, axis, ping])))
	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, pipe_fft)
	rd.compute_list_bind_uniform_set(cl, _fft_usets[field_index], 0)
	rd.compute_list_dispatch(cl, _dispatch_xy.x, _dispatch_xy.y, 1)
	rd.compute_list_end()

func _dispatch_permute(field_index: int) -> void:
	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, pipe_permute)
	rd.compute_list_bind_uniform_set(cl, _permute_usets[field_index], 0)
	rd.compute_list_dispatch(cl, _dispatch_xy.x, _dispatch_xy.y, 1)
	rd.compute_list_end()

func _copy_buffer(from: RID, to: RID) -> void:
	var data := rd.buffer_get_data(from)
	rd.buffer_update(to, 0, data.size(), data)

func _validate_impulse() -> float:
	var n2 := n * n
	var data := PackedFloat32Array()
	data.resize(n2 * 2)
	var c := ((n / 2) * n + n / 2) * 2
	data[c] = 1.0
	rd.buffer_update(dx_dz, 0, data.size() * 4, data.to_byte_array())
	_run_fft_on_field(dx_dz, scratch[0], 0)
	var out := rd.buffer_get_data(dx_dz)
	var err := 0.0
	var floats := out.to_float32_array()
	for i in n2:
		err = maxf(err, absf(floats[i * 2] - 1.0))
		err = maxf(err, absf(floats[i * 2 + 1]))
	return err

func _validate_sinusoid() -> float:
	var n2 := n * n
	var data := PackedFloat32Array()
	data.resize(n2 * 2)
	var c := ((n / 2) * n + (n / 2 + 1)) * 2
	data[c] = 1.0
	rd.buffer_update(dx_dz, 0, data.size() * 4, data.to_byte_array())
	_run_fft_on_field(dx_dz, scratch[0], 0)
	var out := rd.buffer_get_data(dx_dz)
	var floats := out.to_float32_array()
	var err := 0.0
	for y in n:
		for x in n:
			var o := (y * n + x) * 2
			err = maxf(err, absf(floats[o] - cos(TAU * x / n)))
			err = maxf(err, absf(floats[o + 1] - sin(TAU * x / n)))
	return err
