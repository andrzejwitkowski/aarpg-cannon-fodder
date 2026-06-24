@tool
class_name GrassField extends Node3D

const GROUP := &"grass_field"
const BLADE_SHADER_PATH := "res://assets/shaders/grass/grass_blade.gdshader"
const SketchMeshUV := preload("res://addons/godot_a_sketch/godot_a_sketch_mesh_uv.gd")
const SplatMapAssign := preload("res://addons/godot_a_sketch/godot_a_sketch_splat_map_assign.gd")
const SPLAT_MAP_META := &"godot_a_sketch_splat_map_path"
const SPLAT_ATTEMPT_FACTOR := 12

@export var params: GrassParams:
	set(v):
		_disconnect_params()
		params = v if v != null else GrassParams.new()
		if _params_ready():
			_connect_params()
## Paint surface. Leave empty when GrassField is a direct child of the MeshInstance3D.
@export var surface: NodePath = NodePath():
	set(v):
		if surface == v:
			return
		surface = v
		if is_inside_tree():
			_request_rebuild()
@export_category("Editor Preview")
@export var editor_preview_enabled: bool = false:
	set(v):
		if editor_preview_enabled == v:
			return
		editor_preview_enabled = v
		if not is_inside_tree() or not Engine.is_editor_hint():
			return
		if v:
			_request_rebuild()
		else:
			call_deferred("_clear_preview_grass")
@export_range(100, 20000, 100) var editor_preview_max_instances: int = 1000:
	set(v):
		editor_preview_max_instances = maxi(v, 100)
		if is_inside_tree() and Engine.is_editor_hint() and editor_preview_enabled:
			_request_rebuild()
@export var editor_preview_wind: bool = true:
	set(v):
		if editor_preview_wind == v:
			return
		editor_preview_wind = v
		if is_inside_tree():
			_push_static_shader_uniforms()
@export var editor_preview_interaction: bool = false
@export var editor_max_fps: float = 30.0
@export_category("Runtime")
@export var runtime_wind_enabled: bool = false
@export var runtime_interaction_enabled: bool = false
@export_category("Godot-a-Sketch mask")
@export var use_surface_splat_mask: bool = true
@export_range(0.0, 1.0, 0.01) var splat_mask_threshold: float = 0.05
@export_range(0, 3) var splat_mask_channel: int = 0

var _surface_mesh: MeshInstance3D
var _multimesh_inst: MultiMeshInstance3D
var _material: ShaderMaterial
var _splat_image: Image
var _time_elapsed: float = 0.0
var _editor_tick: float = 0.0
var _rebuild_pending := false
var _built := false
var _blade_mesh: Mesh
var _pool_transforms: Array[Transform3D] = []
var _pool_height_scales: PackedFloat32Array = PackedFloat32Array()

func _ready() -> void:
	add_to_group(GROUP)
	if params == null:
		params = GrassParams.new()
	_ensure_material()
	if _params_ready():
		_connect_params()
	_resolve_surface()
	_recover_multimesh_if_present()
	if not Engine.is_editor_hint():
		_queue_rebuild()
	elif _has_live_blades():
		_built = true
		_refresh_material_shader()
		_push_static_shader_uniforms()
		_push_dynamic_shader_uniforms()
	elif editor_preview_enabled:
		_queue_rebuild()


func _queue_rebuild() -> void:
	_rebuild_pending = true
	call_deferred("_run_rebuild")


func _recover_multimesh_if_present() -> void:
	if _multimesh_inst != null:
		return
	for parent in [_surface_mesh, self]:
		if parent == null:
			continue
		for child in parent.get_children():
			if child is MultiMeshInstance3D and child.name == "GrassBlades":
				_multimesh_inst = child as MultiMeshInstance3D
				return


func _has_live_blades() -> bool:
	return (
		_multimesh_inst != null
		and is_instance_valid(_multimesh_inst)
		and _multimesh_inst.multimesh != null
		and _multimesh_inst.multimesh.instance_count > 0
	)


func _refresh_material_shader() -> void:
	_ensure_material()
	if _multimesh_inst != null:
		_multimesh_inst.material_override = _material


func _exit_tree() -> void:
	_disconnect_params()
	if _multimesh_inst != null and is_instance_valid(_multimesh_inst):
		_multimesh_inst.multimesh = null
		_multimesh_inst = null

func _process(delta: float) -> void:
	if not _params_ready():
		return
	if Engine.is_editor_hint():
		_editor_process(delta)
		return
	if not _has_live_blades() or not _needs_dynamic_shader_updates():
		return
	if _wind_strength_for_shader(false) > 0.0:
		_time_elapsed += delta
	_push_dynamic_shader_uniforms()


func _editor_process(delta: float) -> void:
	if not _editor_shader_tick_active() or not _has_live_blades():
		return
	_editor_tick += delta
	var interval := 1.0 / maxf(editor_max_fps, 1.0)
	if _editor_tick < interval:
		return
	var step_dt := _editor_tick
	_editor_tick = 0.0
	_push_static_shader_uniforms()
	if not _needs_dynamic_shader_updates():
		return
	if _wind_strength_for_shader(true) > 0.0:
		_time_elapsed += step_dt
	_push_dynamic_shader_uniforms()

func _params_ready() -> bool:
	return GrassParams.is_instance_ready(params)

func _ensure_material() -> void:
	if _material == null:
		_material = ShaderMaterial.new()
	var shader := load(BLADE_SHADER_PATH) as Shader
	if shader and _material.shader != shader:
		_material.shader = shader

func _ensure_multimesh() -> void:
	_ensure_material()
	_cleanup_orphan_blades()
	if _multimesh_inst == null:
		_multimesh_inst = MultiMeshInstance3D.new()
		# Created on first scatter; splat paint also triggers rebuild via GodotASketchBrushable.
		_multimesh_inst.name = "GrassBlades"
	_multimesh_inst.material_override = _material
	# ponytail: parent blades under the paint surface so mesh gizmo moves carry grass
	var parent: Node = _surface_mesh if _surface_mesh != null else self
	if _multimesh_inst.get_parent() == parent:
		return
	if _multimesh_inst.get_parent() != null:
		_multimesh_inst.reparent(parent)
	else:
		parent.add_child(_multimesh_inst)
	# ponytail: no owner — GrassBlades is editor/runtime ephemeral; setting owner bloats .tscn to MB+

func _cleanup_orphan_blades() -> void:
	for node: Node in get_children():
		if node is MultiMeshInstance3D and node.name == "GrassBlades" and node != _multimesh_inst:
			(node as MultiMeshInstance3D).multimesh = null
			node.queue_free()
	if _surface_mesh == null:
		return
	for node: Node in _surface_mesh.get_children():
		if node is MultiMeshInstance3D and node.name == "GrassBlades" and node != _multimesh_inst:
			(node as MultiMeshInstance3D).multimesh = null
			node.queue_free()

func _resolve_surface() -> void:
	_surface_mesh = null
	if not surface.is_empty():
		var node := get_node_or_null(surface)
		if node is MeshInstance3D:
			_surface_mesh = node
		return
	# ponytail: child-of-mesh setup — parent MeshInstance3D is the paint surface when surface is empty
	var parent := get_parent()
	if parent is MeshInstance3D:
		_surface_mesh = parent

func _connect_params() -> void:
	if not _params_ready():
		return
	if not params.params_changed.is_connected(_on_params_layout_changed):
		params.params_changed.connect(_on_params_layout_changed)
	if not params.density_changed.is_connected(_on_density_changed):
		params.density_changed.connect(_on_density_changed)
	if not params.shader_visuals_changed.is_connected(_on_shader_visuals_changed):
		params.shader_visuals_changed.connect(_on_shader_visuals_changed)
	if not params.mesh_visuals_changed.is_connected(_on_mesh_visuals_changed):
		params.mesh_visuals_changed.connect(_on_mesh_visuals_changed)
	if not params.changed.is_connected(_on_params_resource_changed):
		params.changed.connect(_on_params_resource_changed)

func _disconnect_params() -> void:
	if params == null:
		return
	if params.params_changed.is_connected(_on_params_layout_changed):
		params.params_changed.disconnect(_on_params_layout_changed)
	if params.density_changed.is_connected(_on_density_changed):
		params.density_changed.disconnect(_on_density_changed)
	if params.shader_visuals_changed.is_connected(_on_shader_visuals_changed):
		params.shader_visuals_changed.disconnect(_on_shader_visuals_changed)
	if params.mesh_visuals_changed.is_connected(_on_mesh_visuals_changed):
		params.mesh_visuals_changed.disconnect(_on_mesh_visuals_changed)
	if params.changed.is_connected(_on_params_resource_changed):
		params.changed.disconnect(_on_params_resource_changed)

func _on_params_layout_changed() -> void:
	_blade_mesh = null
	_pool_transforms.clear()
	_pool_height_scales = PackedFloat32Array()
	_request_rebuild()

func _on_density_changed() -> void:
	var target := _effective_max_instances()
	if not _has_live_blades() or _pool_transforms.is_empty():
		_request_rebuild()
		return
	if target <= _pool_transforms.size():
		_set_visible_instance_count(target)
		return
	_request_rebuild()

func _on_shader_visuals_changed() -> void:
	call_deferred("_apply_shader_visual_refresh")

func _on_params_resource_changed() -> void:
	call_deferred("_apply_shader_visual_refresh")

func _on_mesh_visuals_changed() -> void:
	call_deferred("_apply_visual_refresh", true)

func owns_surface(mesh: Node3D) -> bool:
	if mesh == null or not mesh is MeshInstance3D:
		return false
	_resolve_surface()
	return _surface_mesh == mesh


func _request_rebuild(force: bool = false) -> void:
	# ponytail: editor preview off skips scatter until splat paint forces a refresh
	if Engine.is_editor_hint() and not editor_preview_enabled and not force:
		return
	_rebuild_pending = true
	if is_inside_tree():
		call_deferred("_run_rebuild")

func _run_rebuild() -> void:
	if not _rebuild_pending:
		return
	_rebuild_pending = false
	_rebuild_instances()

func _clear_multimesh() -> void:
	if _multimesh_inst == null:
		return
	var mm := _multimesh_inst.multimesh
	if mm != null:
		mm.instance_count = 0


func _clear_preview_grass() -> void:
	_clear_multimesh()
	_built = false
	_splat_image = null
	_pool_transforms.clear()
	_pool_height_scales = PackedFloat32Array()

func _rebuild_instances() -> void:
	_resolve_surface()
	if _surface_mesh == null or not _params_ready():
		_clear_multimesh()
		_built = false
		return
	_ensure_multimesh()
	_refresh_splat_image()
	if _splat_mask_active():
		SketchMeshUV.cache(_surface_mesh)
	var scatter_result := _scatter_blades()
	var transforms: Array[Transform3D] = scatter_result["transforms"]
	var height_scales: PackedFloat32Array = scatter_result["height_scales"]
	if transforms.is_empty():
		_clear_multimesh()
		_built = false
		if use_surface_splat_mask and _splat_mask_active():
			push_warning(
				"GrassField '%s': splat mask rejected all blade positions — paint on this mesh in Godot-a-Sketch, widen strokes, or lower Splat Mask Threshold"
				% name
			)
		return
	_apply_multimesh_instances(transforms, height_scales)
	_pool_transforms = transforms.duplicate()
	_pool_height_scales = height_scales.duplicate()
	_multimesh_inst.custom_aabb = _compute_instance_aabb(transforms)
	_built = true
	_push_static_shader_uniforms()
	_push_dynamic_shader_uniforms()


func _apply_shader_visual_refresh() -> void:
	if not _params_ready():
		return
	if Engine.is_editor_hint() and not _editor_shader_tick_active():
		return
	if not _has_live_blades():
		_request_rebuild()
		return
	_ensure_multimesh()
	_refresh_material_shader()
	var mm := _multimesh_inst.multimesh
	if mm != null:
		_ensure_unit_blade_mesh(mm)
		_refresh_aabb_from_multimesh()
	_push_static_shader_uniforms()
	_built = true


func _apply_visual_refresh(rebuild_blade_mesh: bool = false) -> void:
	if not _params_ready():
		return
	if Engine.is_editor_hint() and not _editor_shader_tick_active():
		return
	if not _has_live_blades():
		_request_rebuild()
		return
	_ensure_multimesh()
	_refresh_material_shader()
	if rebuild_blade_mesh:
		_blade_mesh = null
		var mm := _multimesh_inst.multimesh
		if mm != null:
			mm.mesh = _get_blade_mesh()
			_refresh_aabb_from_multimesh()
	_push_static_shader_uniforms()
	_built = true


func _editor_shader_tick_active() -> bool:
	return editor_preview_enabled or _has_live_blades()

func _ensure_unit_blade_mesh(mm: MultiMesh) -> void:
	if mm == null:
		return
	if mm.mesh != null and mm.mesh.get_aabb().size.y <= 1.1:
		return
	_blade_mesh = null
	mm.mesh = _get_blade_mesh()


func _refresh_aabb_from_multimesh() -> void:
	if _multimesh_inst == null:
		return
	var mm := _multimesh_inst.multimesh
	if mm == null or mm.instance_count <= 0:
		return
	var transforms: Array[Transform3D] = []
	transforms.resize(mm.instance_count)
	for i in mm.instance_count:
		transforms[i] = mm.get_instance_transform(i)
	_multimesh_inst.custom_aabb = _compute_instance_aabb(transforms)


func _apply_multimesh_instances(transforms: Array[Transform3D], height_scales: PackedFloat32Array) -> void:
	_ensure_multimesh()
	var blade := _get_blade_mesh()
	var mm := _multimesh_inst.multimesh
	if mm == null:
		mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		_multimesh_inst.multimesh = mm
	if mm.mesh != blade:
		mm.mesh = blade
	var count := transforms.size()
	if mm.instance_count != count:
		mm.instance_count = count
	for i in count:
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_custom_data(i, Color(height_scales[i], 0.0, 0.0, 1.0))


func _set_visible_instance_count(count: int) -> void:
	if _multimesh_inst == null:
		return
	var mm := _multimesh_inst.multimesh
	if mm == null:
		return
	count = clampi(count, 0, _pool_transforms.size())
	if mm.instance_count != count:
		mm.instance_count = count
	if count <= 0:
		_built = false
		return
	var visible: Array[Transform3D] = []
	visible.resize(count)
	for i in count:
		visible[i] = _pool_transforms[i]
	_multimesh_inst.custom_aabb = _compute_instance_aabb(visible)
	_built = true
	_push_static_shader_uniforms()

func _effective_max_instances() -> int:
	if Engine.is_editor_hint():
		return mini(params.max_instances, editor_preview_max_instances)
	return params.max_instances


func _scatter_blades() -> Dictionary:
	var max_count := _effective_max_instances()
	var mesh := _surface_mesh.mesh if _surface_mesh != null else null
	if mesh is PlaneMesh or (mesh != null and mesh.get_class() == "PlaneMesh"):
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
	var placed := 0
	for attempt in max_count * SPLAT_ATTEMPT_FACTOR:
		if placed >= max_count:
			break
		var area_pick := _halton(attempt + 1, 11) * total_area
		var triangle: Dictionary = triangles[_pick_scatter_triangle(cumulative_area, area_pick)]
		var normal: Vector3 = triangle["normal"]
		var local_pos := _sample_triangle_position(
			triangle["a"],
			triangle["b"],
			triangle["c"],
			_halton(attempt + 1, 2),
			_halton(attempt + 1, 3)
		) + normal * 0.01
		if not _splat_allows_on_face(int(triangle.get("face_index", -1)), local_pos, normal):
			continue
		var height := height_max
		if params.random_height:
			height = params.height_min + _halton(placed + 1, 5) * height_span
		var height_scale := height / maxf(height_max, 0.001)
		var yaw := 0.0
		if params.random_yaw:
			yaw = _halton(placed + 1, 7) * TAU
		transforms.append(_blade_instance_transform(local_pos, yaw, true, normal))
		height_scales.append(height_scale)
		placed += 1
	return {"transforms": transforms, "height_scales": height_scales}

func _axis_aligned_plane_size() -> Vector2:
	if _surface_mesh == null or _surface_mesh.mesh == null:
		return Vector2.ZERO
	var mesh := _surface_mesh.mesh
	if mesh is PlaneMesh:
		return (mesh as PlaneMesh).size
	if mesh.get_class() == "PlaneMesh":
		return mesh.size
	return Vector2.ZERO

func _scatter_plane_stratified(max_count: int, plane_size: Vector2) -> Dictionary:
	var transforms: Array[Transform3D] = []
	var height_scales := PackedFloat32Array()
	var half := plane_size * 0.5
	var height_max := _effective_height_max()
	var height_span := maxf(height_max - params.height_min, 0.001)
	var per_quadrant := max_count / 4
	var remainder := max_count - per_quadrant * 4
	var index := 0
	for quadrant in 4:
		var count := per_quadrant + (1 if quadrant < remainder else 0)
		var placed := 0
		var tries := 0
		while placed < count and tries < count * SPLAT_ATTEMPT_FACTOR:
			tries += 1
			var u := _halton(index + 1, 2)
			var v := _halton(index + 1, 3)
			index += 1
			var x_min := 0.0 if (quadrant & 1) != 0 else -half.x
			var x_max := half.x if (quadrant & 1) != 0 else 0.0
			var z_min := 0.0 if (quadrant & 2) != 0 else -half.y
			var z_max := half.y if (quadrant & 2) != 0 else 0.0
			var local_x := lerpf(x_min, x_max, u)
			var local_z := lerpf(z_min, z_max, v)
			var local_pos := Vector3(local_x, 0.01, local_z)
			if not _splat_allows_at(local_pos, Vector3.UP):
				continue
			var height := height_max
			if params.random_height:
				height = params.height_min + _halton(placed + 1, 5) * height_span
			var height_scale := height / maxf(height_max, 0.001)
			var yaw := 0.0
			if params.random_yaw:
				yaw = _halton(placed + 1, 7) * TAU
			transforms.append(_blade_instance_transform(local_pos, yaw, false))
			height_scales.append(height_scale)
			placed += 1
	return {"transforms": transforms, "height_scales": height_scales}

func _blade_instance_transform(local_pos: Vector3, yaw: float, align_to_normal: bool, normal: Vector3 = Vector3.UP) -> Transform3D:
	var basis := _blade_basis(normal, yaw) if align_to_normal else Basis.from_euler(Vector3(0.0, yaw, 0.0))
	var surface_transform := Transform3D(basis, local_pos)
	var xf := surface_transform
	if _surface_mesh != null and _multimesh_inst != null:
		if _multimesh_inst.get_parent() != _surface_mesh and _surface_mesh.get_parent() != self:
			xf = _surface_transform_to_field(surface_transform)
	return _orthonormalize_transform(xf)

func _surface_scatter_data() -> Dictionary:
	var triangles: Array = []
	var cumulative_area := PackedFloat32Array()
	var total_area := 0.0
	var faces := _scatter_faces()
	var face_count := faces.size() - faces.size() % 3
	for i in range(0, face_count, 3):
		var a := faces[i]
		var b := faces[i + 1]
		var c := faces[i + 2]
		var cross := (b - a).cross(c - a)
		var area := cross.length() * 0.5
		if area <= 0.000001:
			continue
		var centroid := (a + b + c) / 3.0
		var normal := _orient_normal_outward(cross.normalized(), centroid)
		total_area += area
		cumulative_area.append(total_area)
		triangles.append({
			"a": a,
			"b": b,
			"c": c,
			"normal": normal,
			"face_index": i / 3,
		})
	return {
		"triangles": triangles,
		"cumulative_area": cumulative_area,
		"total_area": total_area,
	}


func _scatter_faces() -> PackedVector3Array:
	if _surface_mesh == null or _surface_mesh.mesh == null:
		return PackedVector3Array()
	# ponytail: splat sampling uses the same triangle order as GodotASketchMeshUV cache
	if _splat_mask_active():
		var triangle_mesh := _surface_mesh.mesh.generate_triangle_mesh()
		if triangle_mesh != null:
			var tm_faces := triangle_mesh.get_faces()
			if tm_faces.size() >= 3:
				return tm_faces
	return _surface_faces()

func _surface_faces() -> PackedVector3Array:
	if _surface_mesh.mesh == null:
		return PackedVector3Array()
	var mesh := _surface_mesh.mesh
	if mesh is BoxMesh or mesh.get_class() == "BoxMesh":
		var box_size: Vector3 = (mesh as BoxMesh).size if mesh is BoxMesh else mesh.size
		return _box_mesh_faces(box_size)
	var mesh_size = mesh.get("size")
	if mesh_size is Vector3:
		var box_size: Vector3 = mesh_size
		if box_size != Vector3.ZERO:
			return _box_mesh_faces(box_size)
	if mesh is PlaneMesh:
		return _plane_mesh_faces(mesh as PlaneMesh)
	if mesh.get_class() == "PlaneMesh":
		return _plane_mesh_faces_from_size(mesh.size)
	if mesh is PrimitiveMesh:
		var arrays := (mesh as PrimitiveMesh).get_mesh_arrays()
		var primitive_faces := _faces_from_mesh_arrays(arrays)
		if primitive_faces.size() > 0:
			return primitive_faces
	var faces := mesh.get_faces()
	if faces.size() > 0:
		return faces
	var triangle_mesh := mesh.generate_triangle_mesh()
	if triangle_mesh != null:
		return triangle_mesh.get_faces()
	return PackedVector3Array()

func _box_mesh_faces(size: Vector3) -> PackedVector3Array:
	var h := size * 0.5
	var v := [
		Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z),
		Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z),
	]
	var tri := [
		0, 2, 1, 0, 3, 2,
		4, 5, 6, 4, 6, 7,
		0, 1, 5, 0, 5, 4,
		2, 3, 7, 2, 7, 6,
		0, 4, 7, 0, 7, 3,
		1, 2, 6, 1, 6, 5,
	]
	var faces := PackedVector3Array()
	faces.resize(tri.size())
	for i in tri.size():
		faces[i] = v[tri[i]]
	return faces

func _faces_from_mesh_arrays(arrays: Array) -> PackedVector3Array:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if verts.is_empty():
		return PackedVector3Array()
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if not indices.is_empty():
		var faces := PackedVector3Array()
		faces.resize(indices.size())
		for i in indices.size():
			faces[i] = verts[indices[i]]
		return faces
	if verts.size() >= 3:
		return verts
	return PackedVector3Array()

func _plane_mesh_faces_from_size(plane_size: Vector2) -> PackedVector3Array:
	var half := plane_size * 0.5
	return PackedVector3Array([
		Vector3(-half.x, 0.0, -half.y),
		Vector3(half.x, 0.0, -half.y),
		Vector3(half.x, 0.0, half.y),
		Vector3(-half.x, 0.0, -half.y),
		Vector3(half.x, 0.0, half.y),
		Vector3(-half.x, 0.0, half.y),
	])

func _plane_mesh_faces(plane: PlaneMesh) -> PackedVector3Array:
	return _plane_mesh_faces_from_size(plane.size)

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

func _mesh_local_center() -> Vector3:
	if _surface_mesh == null or _surface_mesh.mesh == null:
		return Vector3.ZERO
	return _surface_mesh.mesh.get_aabb().get_center()

func _orient_normal_outward(normal: Vector3, centroid: Vector3) -> Vector3:
	var outward := centroid - _mesh_local_center()
	if outward.length_squared() > 0.000001 and normal.dot(outward) < 0.0:
		return -normal
	return normal

func _orthonormalize_transform(xf: Transform3D) -> Transform3D:
	return Transform3D(xf.basis.orthonormalized(), xf.origin)

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
	if _multimesh_inst == null or _surface_mesh == null:
		return surface_transform
	if _surface_mesh.get_parent() == self and _multimesh_inst.get_parent() == self:
		return _multimesh_inst.transform.affine_inverse() * _surface_mesh.transform * surface_transform
	var mm_parent := _multimesh_inst.get_parent() as Node3D
	var surface_parent := _surface_mesh.get_parent() as Node3D
	if mm_parent != null and surface_parent != null:
		var surface_world := surface_parent.transform * _surface_mesh.transform * surface_transform
		return mm_parent.transform.affine_inverse() * surface_world
	if is_inside_tree():
		return global_transform.affine_inverse() * (_surface_mesh.global_transform * surface_transform)
	return surface_transform

func _compute_instance_aabb(transforms: Array[Transform3D]) -> AABB:
	if transforms.is_empty():
		return AABB()
	var height_max := _effective_height_max()
	var pad_xz := params.blade_width * 4.0
	var min_p := transforms[0].origin
	var max_p := transforms[0].origin
	for xf in transforms:
		min_p = min_p.min(xf.origin)
		max_p = max_p.max(xf.origin)
		var tip := xf.origin + xf.basis.y * height_max
		min_p = min_p.min(tip)
		max_p = max_p.max(tip)
	var padded_min := min_p - Vector3(pad_xz, pad_xz, pad_xz)
	var padded_max := max_p + Vector3(pad_xz, pad_xz, pad_xz)
	return AABB(padded_min, padded_max - padded_min)

func _effective_height_max() -> float:
	return clampf(params.height_max, params.height_min, 3.0)


func _get_blade_mesh() -> Mesh:
	if _blade_mesh != null:
		return _blade_mesh
	_blade_mesh = _build_blade_mesh()
	return _blade_mesh

func _build_blade_mesh() -> ArrayMesh:
	var width := params.blade_width
	# ponytail: unit-height blade; blade_height uniform scales in shader (no respawn on height_max)
	var height := 1.0
	var half_w := width * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := params.blade_segments
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

func _needs_dynamic_shader_updates() -> bool:
	var is_editor := Engine.is_editor_hint()
	if _wind_strength_for_shader(is_editor) > 0.0:
		return true
	return _should_collect_interactors(is_editor)

func _push_static_shader_uniforms() -> void:
	_ensure_material()
	_refresh_material_shader()
	if _material == null or not _params_ready():
		return
	_material.set_shader_parameter("blade_height", _effective_height_max())
	_material.set_shader_parameter("base_color", params.base_color)
	_material.set_shader_parameter("tip_color", params.tip_color)
	_material.set_shader_parameter("wind_strength", _wind_strength_for_shader(Engine.is_editor_hint()))
	_material.set_shader_parameter("wind_speed", params.wind_speed)
	var wind_rad := deg_to_rad(params.wind_direction_deg)
	_material.set_shader_parameter("wind_direction_xz", Vector2(cos(wind_rad), sin(wind_rad)))
	_material.set_shader_parameter("interactor_strength", params.interactor_strength)

func _push_dynamic_shader_uniforms() -> void:
	if _material == null or not _params_ready():
		return
	_material.set_shader_parameter("time_elapsed", _time_elapsed)
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

func _push_shader_uniforms() -> void:
	_push_static_shader_uniforms()
	_push_dynamic_shader_uniforms()


func _refresh_splat_image() -> void:
	_splat_image = null
	if not _splat_mask_active():
		return
	var map := SplatMapAssign.latest_map(_surface_mesh)
	if map == null or map.image == null or map.image.is_empty():
		return
	map.ensure_rgba8()
	# ponytail: read-only during scatter — skip duplicate() of 1024² mask in editor
	_splat_image = map.image


func _splat_mask_active() -> bool:
	if not use_surface_splat_mask or _surface_mesh == null:
		return false
	return SplatMapAssign.latest_map(_surface_mesh) != null


func _splat_mask_channel_index() -> int:
	# Per-layer Godot-a-Sketch maps store weight in R; legacy RGBA atlases use splat_mask_channel.
	if _surface_mesh != null and _surface_mesh.has_meta(&"godot_a_sketch_shader_stack_path"):
		return 0
	return clampi(splat_mask_channel, 0, 3)


func _splat_allows_at(local_pos: Vector3, local_normal: Vector3) -> bool:
	if not _splat_mask_active():
		return true
	if _splat_image == null:
		_refresh_splat_image()
	if _splat_image == null:
		return true
	var hit := SketchMeshUV.resolve_uv(_surface_mesh, local_pos, local_normal)
	return _splat_allows_uv(hit["uv"] as Vector2)


func _splat_allows_on_face(face_index: int, local_pos: Vector3, local_normal: Vector3) -> bool:
	if not _splat_mask_active():
		return true
	if _splat_image == null:
		_refresh_splat_image()
	if _splat_image == null:
		return true
	var uv := Vector2(-1.0, -1.0)
	if face_index >= 0:
		uv = SketchMeshUV.hit_uv(_surface_mesh, face_index, local_pos, local_normal)
	elif _surface_mesh != null:
		uv = SketchMeshUV.resolve_uv(_surface_mesh, local_pos, local_normal)["uv"] as Vector2
	return _splat_allows_uv(uv)


func _splat_allows_uv(uv: Vector2) -> bool:
	if not _splat_mask_active():
		return true
	if _splat_image == null:
		_refresh_splat_image()
	if _splat_image == null:
		return true
	if uv.x < 0.0 or uv.y < 0.0:
		return false
	var w := _splat_image.get_width()
	var h := _splat_image.get_height()
	if w <= 0 or h <= 0:
		return false
	var px := clampi(int(uv.x * float(w)), 0, w - 1)
	var py := clampi(int(uv.y * float(h)), 0, h - 1)
	var c := _splat_image.get_pixel(px, py)
	var ch := _splat_mask_channel_index()
	var v: float = [c.r, c.g, c.b, c.a][ch]
	return v >= splat_mask_threshold
