extends Node

@export_category("Click navigation")
@export var click_ray_length: float = 1000.0
@export_flags_3d_physics var ground_collision_mask: int = PhysicsLayers.WORLD_MASK

var _player: CharacterBody3D

func _ready() -> void:
	_player = get_parent() as CharacterBody3D

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
	return snapped.distance_squared_to(hit) <= 4.0

func _physics_space_state() -> PhysicsDirectSpaceState3D:
	var body := get_parent() as Node3D
	if body == null:
		return null
	var world: World3D = body.get_world_3d()
	if world == null:
		return null
	return world.direct_space_state
