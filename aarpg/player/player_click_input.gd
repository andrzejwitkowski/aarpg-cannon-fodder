extends Node

const GROUND_PICK_GROUP := &"ground_pick"

@export_category("Click navigation")
@export var click_ray_length: float = 1000.0
@export_flags_3d_physics var ground_collision_mask: int = PhysicsLayers.WORLD_MASK
@export var nav_snap_max_distance: float = 2.0

var _player: CharacterBody3D
var _nav_snap_max_distance_sq: float

func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	_nav_snap_max_distance_sq = nav_snap_max_distance * nav_snap_max_distance

func _unhandled_input(event: InputEvent) -> void:
	if _player == null:
		return
	if not event is InputEventMouseButton:
		return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	var hit: Variant = pick_ground_from_screen(mouse.position)
	if hit == null:
		return
	_player.move_to(_navigation_target_from_hit(hit as Vector3))
	get_viewport().set_input_as_handled()

func pick_ground_from_screen(screen_pos: Vector2) -> Variant:
	var viewport := get_viewport()
	if viewport == null:
		return null
	var camera := viewport.get_camera_3d()
	if camera == null:
		return null
	var ground := _find_ground_mesh()
	if ground != null:
		return _pick_on_ground_plane(camera, screen_pos, ground)
	return _pick_with_physics_ray(camera, screen_pos)

func _pick_on_ground_plane(camera: Camera3D, screen_pos: Vector2, ground: MeshInstance3D) -> Variant:
	var plane := ground.mesh as PlaneMesh
	if plane == null:
		return null
	var origin := camera.project_ray_origin(screen_pos)
	var direction := camera.project_ray_normal(screen_pos)
	var ground_y := ground.global_position.y
	if absf(direction.y) < 0.00001:
		return null
	var t := (ground_y - origin.y) / direction.y
	if t < 0.0:
		return null
	var point := origin + direction * t
	var local := ground.global_transform.affine_inverse() * point
	var half_x := plane.size.x * 0.5
	var half_z := plane.size.y * 0.5
	if absf(local.x) > half_x or absf(local.z) > half_z:
		return null
	return point

func _pick_with_physics_ray(camera: Camera3D, screen_pos: Vector2) -> Variant:
	var origin := camera.project_ray_origin(screen_pos)
	var target := origin + camera.project_ray_normal(screen_pos) * click_ray_length
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = ground_collision_mask
	if _player != null:
		query.exclude = [_player.get_rid()]
	var space_state: PhysicsDirectSpaceState3D = _physics_space_state()
	if space_state == null:
		return null
	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		return null
	if not result.collider is StaticBody3D:
		return null
	return result.position

func _navigation_target_from_hit(hit: Vector3) -> Vector3:
	var map_rid: RID = _player.get_world_3d().get_navigation_map()
	var snapped: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, hit)
	if _is_usable_nav_snap(hit, snapped):
		return snapped
	return Vector3(hit.x, _player.global_position.y, hit.z)

func _is_usable_nav_snap(hit: Vector3, snapped: Vector3) -> bool:
	if snapped == Vector3.ZERO and hit.distance_squared_to(Vector3.ZERO) > 1.0:
		return false
	return snapped.distance_squared_to(hit) <= _nav_snap_max_distance_sq

func _find_ground_mesh() -> MeshInstance3D:
	for node: Node in get_tree().get_nodes_in_group(GROUND_PICK_GROUP):
		if node is MeshInstance3D:
			return node as MeshInstance3D
		if node is StaticBody3D:
			var parent := node.get_parent()
			if parent is MeshInstance3D:
				return parent as MeshInstance3D
	return null

func _physics_space_state() -> PhysicsDirectSpaceState3D:
	var body := get_parent() as Node3D
	if body == null:
		return null
	var world: World3D = body.get_world_3d()
	if world == null:
		return null
	return world.direct_space_state
