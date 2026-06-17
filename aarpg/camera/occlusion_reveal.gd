class_name OcclusionReveal extends Node

const GLOBAL_PLAYER_POS := &"occlusion_reveal_player_pos"
const GLOBAL_TIME := &"occlusion_reveal_time"

@export_category("Detection")
@export_flags_3d_physics var collision_mask: int = PhysicsLayers.WORLD_MASK

@onready var _camera: Camera3D = $"../SpringArm3D/Camera3D"

var _globals_registered := false

func _ready() -> void:
	RenderingServer.global_shader_parameter_add(GLOBAL_PLAYER_POS, RenderingServer.GLOBAL_VAR_TYPE_VEC3, Vector3.ZERO)
	RenderingServer.global_shader_parameter_add(GLOBAL_TIME, RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0)
	_globals_registered = true

func _exit_tree() -> void:
	if not _globals_registered:
		return
	RenderingServer.global_shader_parameter_remove(GLOBAL_PLAYER_POS)
	RenderingServer.global_shader_parameter_remove(GLOBAL_TIME)
	_globals_registered = false

func _physics_process(_delta: float) -> void:
	var player_pos := PlayerUtils.global_position()
	RenderingServer.global_shader_parameter_set(GLOBAL_PLAYER_POS, player_pos)
	RenderingServer.global_shader_parameter_set(GLOBAL_TIME, Time.get_ticks_msec() / 1000.0)
	if not is_instance_valid(_camera):
		return
	var blockers := OcclusionRevealQuery.collect_blockers(
		get_world_3d().direct_space_state,
		_camera.global_position,
		player_pos,
		collision_mask
	)
	var active: Dictionary = {}
	for collider in blockers:
		active[collider] = true
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(OccluderReveal.GROUP):
		if node is not OccluderReveal:
			continue
		var reveal := node as OccluderReveal
		var collider := reveal.get_collider()
		reveal.set_reveal_target(1.0 if collider != null and active.has(collider) else 0.0)
