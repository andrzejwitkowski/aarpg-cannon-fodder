@tool
class_name RainEmitter extends Node3D

const GROUP := &"rain_emitter"
const PARTICLE_SHADER := preload("res://assets/shaders/rain/rain_particle.gdshader")

@export var params: RainParams:
	set(v):
		_disconnect_params()
		params = v if v != null else RainParams.new()
		if _params_ready():
			_connect_params()
		_request_particle_refresh()
@export_category("Editor Preview")
@export var editor_preview_enabled: bool = true
@export var editor_max_fps: float = 30.0

var _particles: GPUParticles3D
var _volume_gizmo: MeshInstance3D
var _particle_material: ShaderMaterial
var _process_material: ParticleProcessMaterial
var _editor_tick: float = 0.0
var _shelter_factor: float = 1.0
var _player_inside := false
var _particle_intensity: float = 0.0
var _overlay_intensity: float = 0.0
var _particle_refresh_pending := false
var _overlay: RainGlassOverlay

func _ready() -> void:
	add_to_group(GROUP)
	if params == null:
		params = RainParams.new()
	_ensure_nodes()
	if _params_ready():
		_connect_params()
	_request_particle_refresh()
	_run_particle_refresh()

func _exit_tree() -> void:
	_unregister_overlay_intensity()
	_disconnect_params()

func _process(delta: float) -> void:
	if not _params_ready():
		return
	var run := not Engine.is_editor_hint() or editor_preview_enabled
	if not run:
		_particle_intensity = 0.0
		_overlay_intensity = 0.0
		_set_particle_intensity(0.0)
		_register_overlay_intensity()
		return
	var step_dt := delta
	if Engine.is_editor_hint():
		_editor_tick += delta
		var interval := 1.0 / maxf(editor_max_fps, 1.0)
		if _editor_tick < interval:
			return
		step_dt = _editor_tick
		_editor_tick = 0.0
	_update_intensities(step_dt)
	_set_particle_intensity(_particle_intensity)
	_register_overlay_intensity()

func get_effective_intensity() -> float:
	return _particle_intensity

func get_overlay_intensity() -> float:
	return _overlay_intensity

func get_volume_aabb() -> AABB:
	var half := params.volume_size * 0.5
	return global_transform * AABB(-half, params.volume_size)

func is_global_point_inside_volume(point: Vector3) -> bool:
	var local := global_transform.affine_inverse() * point
	var half := params.volume_size * 0.5
	return absf(local.x) <= half.x and absf(local.y) <= half.y and absf(local.z) <= half.z

func is_global_point_under_rain_column(point: Vector3) -> bool:
	var local := global_transform.affine_inverse() * point
	var half := params.volume_size * 0.5
	if absf(local.x) > half.x or absf(local.z) > half.z:
		return false
	return local.y >= -half.y

func _params_ready() -> bool:
	return RainParams.is_instance_ready(params)

func _ensure_nodes() -> void:
	_particles = get_node_or_null("RainParticles") as GPUParticles3D
	if _particles == null:
		_particles = GPUParticles3D.new()
		_particles.name = "RainParticles"
		add_child(_particles)
	_volume_gizmo = get_node_or_null("VolumeGizmo") as MeshInstance3D
	if _volume_gizmo == null:
		_volume_gizmo = MeshInstance3D.new()
		_volume_gizmo.name = "VolumeGizmo"
		add_child(_volume_gizmo)
	_refresh_volume_gizmo()

func _connect_params() -> void:
	if not _params_ready():
		return
	if not params.params_changed.is_connected(_on_params_changed):
		params.params_changed.connect(_on_params_changed)

func _disconnect_params() -> void:
	if params != null and params.params_changed.is_connected(_on_params_changed):
		params.params_changed.disconnect(_on_params_changed)

func _on_params_changed() -> void:
	_request_particle_refresh()
	_refresh_volume_gizmo()

func _request_particle_refresh() -> void:
	_particle_refresh_pending = true
	if is_inside_tree():
		call_deferred("_run_particle_refresh")

func _run_particle_refresh() -> void:
	if not _particle_refresh_pending or not _params_ready():
		return
	_particle_refresh_pending = false
	if _process_material == null:
		_process_material = ParticleProcessMaterial.new()
	if _particle_material == null:
		_particle_material = ShaderMaterial.new()
		_particle_material.shader = PARTICLE_SHADER
	var amount := params.particle_amount
	if Engine.is_editor_hint():
		amount = mini(amount, params.editor_preview_particle_cap)
	_particles.amount = amount
	_particles.lifetime = params.particle_lifetime
	_process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_process_material.emission_box_extents = params.volume_size * 0.5
	_process_material.direction = Vector3.DOWN
	_process_material.spread = 0.05
	_process_material.gravity = Vector3(0.0, -params.fall_speed, 0.0)
	_process_material.initial_velocity_min = params.fall_speed * 0.85
	_process_material.initial_velocity_max = params.fall_speed * 1.1
	_particles.process_material = _process_material
	var quad := QuadMesh.new()
	quad.size = Vector2(0.04, 0.35)
	_particles.draw_pass_1 = quad
	_particles.material_override = _particle_material
	_refresh_volume_gizmo()

func _refresh_volume_gizmo() -> void:
	if _volume_gizmo == null or not _params_ready():
		return
	var box := BoxMesh.new()
	box.size = params.volume_size
	_volume_gizmo.mesh = box
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.35, 0.65, 0.95, 0.18)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_volume_gizmo.material_override = mat
	_volume_gizmo.visible = Engine.is_editor_hint()

func _update_intensities(delta: float) -> void:
	_particle_intensity = _compute_particle_intensity(delta)
	_overlay_intensity = _compute_overlay_intensity()

func _compute_particle_intensity(delta: float) -> float:
	var player := PlayerUtils.instance() if not Engine.is_editor_hint() else null
	var inside := false
	if player != null and is_instance_valid(player):
		inside = is_global_point_inside_volume(player.global_position)
	elif Engine.is_editor_hint():
		inside = true
	_handle_zone_edges(inside)
	var visibility := 0.0
	if Engine.is_editor_hint() and editor_preview_enabled:
		visibility = 1.0
	elif inside:
		var camera := _resolve_camera()
		if camera != null and player != null and is_instance_valid(player):
			var dist_factor := RainVisibility.distance_factor(
				camera.global_position,
				player.global_position,
				params.max_view_distance
			)
			var aabb := get_volume_aabb()
			if RainVisibility.is_aabb_in_frustum(camera, aabb):
				visibility = dist_factor
			elif is_global_point_inside_volume(camera.global_position):
				visibility = dist_factor
	var target_shelter := 1.0
	if inside and player != null and is_instance_valid(player):
		var space := get_world_3d().direct_space_state if get_world_3d() != null else null
		target_shelter = RainShelterQuery.compute_shelter_factor(
			space,
			player.global_position,
			params.shelter_ray_height,
			params.shelter_collision_mask
		)
	elif Engine.is_editor_hint():
		target_shelter = 1.0
	var fade := clampf(params.shelter_fade_speed * delta, 0.0, 1.0)
	_shelter_factor = lerpf(_shelter_factor, target_shelter, fade)
	return params.strength * visibility * _shelter_factor

func _compute_overlay_intensity() -> float:
	if Engine.is_editor_hint() and editor_preview_enabled:
		return params.strength
	var camera := _resolve_camera()
	if camera == null:
		return 0.0
	if not is_global_point_under_rain_column(camera.global_position):
		return 0.0
	var dist_factor := RainVisibility.distance_factor(
		camera.global_position,
		get_volume_aabb().get_center(),
		params.max_view_distance
	)
	var space := get_world_3d().direct_space_state if get_world_3d() != null else null
	var shelter := RainShelterQuery.compute_shelter_factor(
		space,
		camera.global_position,
		params.shelter_ray_height,
		params.shelter_collision_mask
	)
	return params.strength * dist_factor * shelter

func _handle_zone_edges(inside: bool) -> void:
	if Engine.is_editor_hint():
		_player_inside = inside
		return
	if inside and not _player_inside:
		EventBus.rain_zone_entered.emit(self)
	elif not inside and _player_inside:
		EventBus.rain_zone_exited.emit(self)
	_player_inside = inside

func _resolve_camera() -> Camera3D:
	if not is_inside_tree():
		return null
	return get_viewport().get_camera_3d()

func _resolve_overlay() -> RainGlassOverlay:
	if _overlay != null and is_instance_valid(_overlay):
		return _overlay
	if not is_inside_tree():
		return null
	var nodes := get_tree().get_nodes_in_group(RainGlassOverlay.GROUP)
	if nodes.is_empty():
		return null
	_overlay = nodes[0] as RainGlassOverlay
	return _overlay

func _register_overlay_intensity() -> void:
	var overlay := _resolve_overlay()
	if overlay == null:
		return
	overlay.register_emitter_intensity(get_instance_id(), _overlay_intensity)

func _unregister_overlay_intensity() -> void:
	var overlay := _resolve_overlay()
	if overlay == null:
		return
	overlay.register_emitter_intensity(get_instance_id(), 0.0)

func _set_particle_intensity(value: float) -> void:
	if _particles == null:
		return
	var intensity := clampf(value, 0.0, 1.0)
	_particles.amount_ratio = intensity
	_particles.emitting = intensity > 0.001
	if _particle_material != null:
		_particle_material.set_shader_parameter("streak_color", Color(0.75, 0.82, 0.9, 0.35 * intensity))
