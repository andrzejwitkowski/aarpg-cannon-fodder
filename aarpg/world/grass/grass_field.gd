@tool
class_name GrassField extends Node3D

const GROUP := &"grass_field"
const BLADE_SHADER := preload("res://assets/shaders/grass/grass_blade.gdshader")

@export var params: GrassParams:
	set(v):
		_disconnect_params()
		params = v if v != null else GrassParams.new()
		if _params_ready():
			_connect_params()
		_request_rebuild()
@export var surface: NodePath = NodePath():
	set(v):
		if surface == v:
			return
		surface = v
		_request_rebuild()
@export_category("Editor Preview")
@export var editor_preview_enabled: bool = true
@export var editor_preview_wind: bool = true
@export var editor_preview_interaction: bool = false
@export var editor_max_fps: float = 30.0
@export_category("Runtime")
@export var runtime_wind_enabled: bool = false
@export var runtime_interaction_enabled: bool = false

var _surface_mesh: MeshInstance3D
var _multimesh_inst: MultiMeshInstance3D
var _material: ShaderMaterial
var _time_elapsed: float = 0.0
var _editor_tick: float = 0.0
var _rebuild_pending := false
var _built := false

func _ready() -> void:
	add_to_group(GROUP)
	if params == null:
		params = GrassParams.new()
	_ensure_material()
	if _params_ready():
		_connect_params()
	_resolve_surface()
	_rebuild_pending = true
	_run_rebuild()

func _exit_tree() -> void:
	_disconnect_params()

func _process(delta: float) -> void:
	if not _params_ready():
		return
	if not _built:
		return
	var run := not Engine.is_editor_hint() or editor_preview_enabled
	if not run:
		return
	var step_dt := delta
	if Engine.is_editor_hint():
		_editor_tick += delta
		var interval := 1.0 / maxf(editor_max_fps, 1.0)
		if _editor_tick < interval:
			return
		step_dt = _editor_tick
		_editor_tick = 0.0
	if editor_preview_wind or not Engine.is_editor_hint():
		_time_elapsed += step_dt
	_push_shader_uniforms()

func _params_ready() -> bool:
	return GrassParams.is_instance_ready(params)

func _ensure_material() -> void:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = BLADE_SHADER

func _ensure_multimesh() -> void:
	_ensure_material()
	_cleanup_orphan_blades()
	if _multimesh_inst == null:
		_multimesh_inst = MultiMeshInstance3D.new()
		_multimesh_inst.name = "GrassBlades"
	_multimesh_inst.material_override = _material
	_multimesh_inst.extra_cull_margin = 4096.0
	if _multimesh_inst.get_parent() == self:
		return
	if _multimesh_inst.get_parent() != null:
		_multimesh_inst.reparent(self)
	else:
		add_child(_multimesh_inst)

func _cleanup_orphan_blades() -> void:
	for node: Node in get_children():
		if node is MultiMeshInstance3D and node.name == "GrassBlades" and node != _multimesh_inst:
			node.queue_free()
	if _surface_mesh == null:
		return
	for node: Node in _surface_mesh.get_children():
		if node is MultiMeshInstance3D and node.name == "GrassBlades" and node != _multimesh_inst:
			node.queue_free()

func _resolve_surface() -> void:
	_surface_mesh = null
	if surface.is_empty():
		return
	var node := get_node_or_null(surface)
	if node is MeshInstance3D:
		_surface_mesh = node

func _connect_params() -> void:
	if not _params_ready():
		return
	if not params.params_changed.is_connected(_on_params_changed):
		params.params_changed.connect(_on_params_changed)

func _disconnect_params() -> void:
	if params != null and params.params_changed.is_connected(_on_params_changed):
		params.params_changed.disconnect(_on_params_changed)

func _on_params_changed() -> void:
	_request_rebuild()

func _request_rebuild() -> void:
	_rebuild_pending = true
	if is_inside_tree():
		call_deferred("_run_rebuild")

func _run_rebuild() -> void:
	if not _rebuild_pending:
		return
	_rebuild_pending = false
	_rebuild_instances()

func _rebuild_instances() -> void:
	_resolve_surface()
	if _surface_mesh == null or not _params_ready():
		_built = false
		return
	_ensure_multimesh()
	var scatter_result := _scatter_blades()
	var transforms: Array[Transform3D] = scatter_result["transforms"]
	var height_scales: PackedFloat32Array = scatter_result["height_scales"]
	if transforms.is_empty():
		_built = false
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _build_blade_mesh()
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_custom_data(i, Color(height_scales[i], 0.0, 0.0, 1.0))
	_multimesh_inst.multimesh = mm
	_multimesh_inst.custom_aabb = _compute_instance_aabb(transforms)
	_built = true
	_push_shader_uniforms()

func _scatter_blades() -> Dictionary:
	var max_count := params.max_instances
	var plane_size := _axis_aligned_plane_size()
	if plane_size != Vector2.ZERO:
		return _scatter_plane_stratified(max_count, plane_size)
	var transforms: Array[Transform3D] = []
	var height_scales := PackedFloat32Array()
	var scatter_data := _surface_scatter_data()
	var triangles: Array = scatter_data["triangles"]
	if triangles.is_empty():
		return {"transforms": transforms, "height_scales": height_scales}
	var cumulative_area: PackedFloat32Array = scatter_data["cumulative_area"]
	var total_area: float = scatter_data["total_area"]
	var height_max := _effective_height_max()
	var height_span := maxf(height_max - params.height_min, 0.001)
	height_scales.resize(max_count)
	for i in max_count:
		var area_pick := ((float(i) + 0.5) / float(max_count)) * total_area
		var triangle: Dictionary = triangles[_pick_scatter_triangle(cumulative_area, area_pick)]
		var normal: Vector3 = triangle["normal"]
		var local_pos := _sample_triangle_position(
			triangle["a"],
			triangle["b"],
			triangle["c"],
			_halton(i + 1, 2),
			_halton(i + 1, 3)
		) + normal * 0.01
		var height := height_max
		if params.random_height:
			height = params.height_min + _halton(i + 1, 5) * height_span
		var height_scale := height / maxf(height_max, 0.001)
		var yaw := 0.0
		if params.random_yaw:
			yaw = _halton(i + 1, 7) * TAU
		var surface_transform := Transform3D(_blade_basis(normal, yaw), local_pos)
		transforms.append(_surface_transform_to_field(surface_transform))
		height_scales[i] = height_scale
	return {"transforms": transforms, "height_scales": height_scales}

func _axis_aligned_plane_size() -> Vector2:
	if _surface_mesh == null or _surface_mesh.mesh == null:
		return Vector2.ZERO
	var mesh := _surface_mesh.mesh
	if mesh is PlaneMesh:
		return (mesh as PlaneMesh).size
	return Vector2.ZERO

func _scatter_plane_stratified(max_count: int, plane_size: Vector2) -> Dictionary:
	var transforms: Array[Transform3D] = []
	var height_scales := PackedFloat32Array()
	height_scales.resize(max_count)
	var half := plane_size * 0.5
	var height_max := _effective_height_max()
	var height_span := maxf(height_max - params.height_min, 0.001)
	var per_quadrant := maxi(max_count / 4, 1)
	var remainder := max_count - per_quadrant * 4
	var index := 0
	for quadrant in 4:
		var count := per_quadrant + (1 if quadrant < remainder else 0)
		for i in count:
			var u := _halton(index + 1, 2)
			var v := _halton(index + 1, 3)
			var x_min := 0.0 if (quadrant & 1) != 0 else -half.x
			var x_max := half.x if (quadrant & 1) != 0 else 0.0
			var z_min := 0.0 if (quadrant & 2) != 0 else -half.y
			var z_max := half.y if (quadrant & 2) != 0 else 0.0
			var local_x := lerpf(x_min, x_max, u)
			var local_z := lerpf(z_min, z_max, v)
			var local_pos := Vector3(local_x, 0.01, local_z)
			var height := height_max
			if params.random_height:
				height = params.height_min + _halton(index + 1, 5) * height_span
			var height_scale := height / maxf(height_max, 0.001)
			var yaw := 0.0
			if params.random_yaw:
				yaw = _halton(index + 1, 7) * TAU
			var surface_transform := Transform3D(Basis.from_euler(Vector3(0.0, yaw, 0.0)), local_pos)
			transforms.append(_surface_transform_to_field(surface_transform))
			height_scales[index] = height_scale
			index += 1
	return {"transforms": transforms, "height_scales": height_scales}

func _surface_scatter_data() -> Dictionary:
	var triangles: Array = []
	var cumulative_area := PackedFloat32Array()
	var total_area := 0.0
	var faces := _surface_faces()
	var face_count := faces.size() - faces.size() % 3
	for i in range(0, face_count, 3):
		var a := faces[i]
		var b := faces[i + 1]
		var c := faces[i + 2]
		var cross := (b - a).cross(c - a)
		var area := cross.length() * 0.5
		if area <= 0.000001:
			continue
		var normal := cross.normalized()
		if normal.dot(Vector3.UP) < 0.0:
			normal = -normal
		total_area += area
		cumulative_area.append(total_area)
		triangles.append({
			"a": a,
			"b": b,
			"c": c,
			"normal": normal,
		})
	return {
		"triangles": triangles,
		"cumulative_area": cumulative_area,
		"total_area": total_area,
	}

func _surface_faces() -> PackedVector3Array:
	if _surface_mesh.mesh == null:
		return PackedVector3Array()
	var faces := _surface_mesh.mesh.get_faces()
	if faces.size() > 0:
		return faces
	if _surface_mesh.mesh is PlaneMesh:
		return _plane_mesh_faces(_surface_mesh.mesh as PlaneMesh)
	return PackedVector3Array()

func _plane_mesh_faces(plane: PlaneMesh) -> PackedVector3Array:
	var half := plane.size * 0.5
	return PackedVector3Array([
		Vector3(-half.x, 0.0, -half.y),
		Vector3(half.x, 0.0, -half.y),
		Vector3(half.x, 0.0, half.y),
		Vector3(-half.x, 0.0, -half.y),
		Vector3(half.x, 0.0, half.y),
		Vector3(-half.x, 0.0, half.y),
	])

func _pick_scatter_triangle(cumulative_area: PackedFloat32Array, area_pick: float) -> int:
	var low := 0
	var high := cumulative_area.size() - 1
	while low < high:
		var mid := floori(float(low + high) * 0.5)
		if area_pick <= cumulative_area[mid]:
			high = mid
		else:
			low = mid + 1
	return low

func _sample_triangle_position(a: Vector3, b: Vector3, c: Vector3, u: float, v: float) -> Vector3:
	var sqrt_u := sqrt(clampf(u, 0.0, 0.999999))
	return a * (1.0 - sqrt_u) + b * (sqrt_u * (1.0 - v)) + c * (sqrt_u * v)

func _blade_basis(normal: Vector3, yaw: float) -> Basis:
	var up := normal.normalized()
	if up.length_squared() <= 0.000001:
		up = Vector3.UP
	var tangent := Vector3.FORWARD.cross(up)
	if tangent.length_squared() <= 0.000001:
		tangent = Vector3.RIGHT.cross(up)
	tangent = tangent.normalized()
	var bitangent := tangent.cross(up).normalized()
	return Basis(tangent, up, bitangent) * Basis(Vector3.UP, yaw)

func _halton(index: int, base: int) -> float:
	var result := 0.0
	var fraction := 1.0 / float(base)
	var value := index
	while value > 0:
		result += fraction * float(value % base)
		value = floori(float(value) / float(base))
		fraction /= float(base)
	return result

func _surface_transform_to_field(surface_transform: Transform3D) -> Transform3D:
	return global_transform.affine_inverse() * (_surface_mesh.global_transform * surface_transform)

func _compute_instance_aabb(transforms: Array[Transform3D]) -> AABB:
	if transforms.is_empty():
		return AABB()
	var first := transforms[0]
	var min_p := first.origin
	var max_p := first.origin
	for xf in transforms:
		min_p = min_p.min(xf.origin)
		max_p = max_p.max(xf.origin)
	var pad_y := _effective_height_max() * 2.0
	var pad_xz := params.blade_width * 4.0
	var padded_min := min_p - Vector3(pad_xz, 0.0, pad_xz)
	var padded_max := max_p + Vector3(pad_xz, pad_y, pad_xz)
	return AABB(padded_min, padded_max - padded_min)

func _effective_height_max() -> float:
	return clampf(params.height_max, params.height_min, 3.0)

func _build_blade_mesh() -> ArrayMesh:
	var width := params.blade_width
	var height := _effective_height_max()
	var half_w := width * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 3
	for cross in 2:
		var yaw := float(cross) * TAU * 0.5
		for s in segments:
			var t0 := float(s) / float(segments)
			var t1 := float(s + 1) / float(segments)
			var y0 := t0 * height
			var y1 := t1 * height
			var w0 := half_w * (1.0 - t0 * 0.65)
			var w1 := half_w * (1.0 - t1 * 0.65)
			_add_blade_quad(st, y0, y1, w0, w1, yaw)
	return st.commit()

func _add_blade_quad(st: SurfaceTool, y0: float, y1: float, w0: float, w1: float, yaw: float) -> void:
	var rot := Basis.from_euler(Vector3(0.0, yaw, 0.0))
	var n := rot * Vector3(0.0, 0.0, 1.0)
	st.set_normal(n)
	st.add_vertex(rot * Vector3(-w0, y0, 0.0))
	st.add_vertex(rot * Vector3(w0, y0, 0.0))
	st.add_vertex(rot * Vector3(w1, y1, 0.0))
	st.add_vertex(rot * Vector3(-w0, y0, 0.0))
	st.add_vertex(rot * Vector3(w1, y1, 0.0))
	st.add_vertex(rot * Vector3(-w1, y1, 0.0))

func _should_collect_interactors(is_editor: bool) -> bool:
	if is_editor:
		return editor_preview_interaction
	return runtime_interaction_enabled

func _empty_interactor_data() -> Dictionary:
	return {
		"count": 0,
		"positions": PackedVector3Array(),
		"radii": PackedFloat32Array(),
	}

func _interactor_data(is_editor: bool) -> Dictionary:
	if not _should_collect_interactors(is_editor):
		return _empty_interactor_data()
	return GrassInteractors.collect(
		params,
		global_position,
		get_tree(),
		is_editor,
		global_position
	)

func _wind_strength_for_shader(is_editor: bool) -> float:
	if is_editor:
		return params.wind_strength if editor_preview_wind else 0.0
	return params.wind_strength if runtime_wind_enabled else 0.0

func _push_shader_uniforms() -> void:
	if _material == null or not _params_ready():
		return
	_material.set_shader_parameter("blade_height", _effective_height_max())
	_material.set_shader_parameter("base_color", params.base_color)
	_material.set_shader_parameter("tip_color", params.tip_color)
	_material.set_shader_parameter("wind_strength", _wind_strength_for_shader(Engine.is_editor_hint()))
	_material.set_shader_parameter("wind_speed", params.wind_speed)
	_material.set_shader_parameter("wind_direction_rad", deg_to_rad(params.wind_direction_deg))
	_material.set_shader_parameter("time_elapsed", _time_elapsed)
	_material.set_shader_parameter("interactor_strength", params.interactor_strength)
	var interactor_data := _interactor_data(Engine.is_editor_hint())
	var positions: PackedVector3Array = interactor_data["positions"]
	var radii: PackedFloat32Array = interactor_data["radii"]
	while positions.size() < GrassInteractors.MAX_INTERACTORS:
		positions.append(Vector3.ZERO)
	while radii.size() < GrassInteractors.MAX_INTERACTORS:
		radii.append(0.0)
	_material.set_shader_parameter("interactor_count", interactor_data["count"])
	_material.set_shader_parameter("interactor_pos", positions)
	_material.set_shader_parameter("interactor_radius", radii)
