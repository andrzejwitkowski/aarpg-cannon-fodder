class_name RainShelterQuery extends RefCounted

const OVERHEAD_MAX_DISTANCE := 12.0

static func compute_shelter_factor(
	space_state: PhysicsDirectSpaceState3D,
	origin: Vector3,
	height: float,
	collision_mask: int,
	ray_query: Callable = Callable()
) -> float:
	if ray_query.is_valid():
		return clampf(float(ray_query.call(origin, height, collision_mask)), 0.0, 1.0)
	if space_state == null or height <= 0.0:
		return 1.0
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.UP * height)
	query.collision_mask = collision_mask
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return 1.0
	return _shelter_from_hit(origin, hit)

static func _shelter_from_hit(origin: Vector3, hit: Dictionary) -> float:
	var distance := origin.distance_to(hit.position)
	if distance > OVERHEAD_MAX_DISTANCE:
		return 1.0
	var normal: Vector3 = hit.normal
	if normal.dot(Vector3.DOWN) > 0.35:
		return 0.0
	return 1.0
