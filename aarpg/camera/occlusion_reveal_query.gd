class_name OcclusionRevealQuery extends RefCounted

const MAX_HITS := 8
const RAY_EPSILON := 0.05

static func collect_blockers(
	space_state: PhysicsDirectSpaceState3D,
	from: Vector3,
	to: Vector3,
	collision_mask: int,
	ray_query: Callable = Callable()
) -> Array[CollisionObject3D]:
	if ray_query.is_valid():
		return _collect_blockers(from, to, ray_query)
	if space_state == null:
		return []
	var query := func(origin: Vector3, target: Vector3) -> Dictionary:
		var params := PhysicsRayQueryParameters3D.create(origin, target)
		params.collision_mask = collision_mask
		return space_state.intersect_ray(params)
	return _collect_blockers(from, to, query)

static func _collect_blockers(
	from: Vector3,
	to: Vector3,
	intersect_ray: Callable
) -> Array[CollisionObject3D]:
	var blockers: Array[CollisionObject3D] = []
	var segment := to - from
	var length_sq := segment.length_squared()
	if length_sq <= RAY_EPSILON * RAY_EPSILON:
		return blockers
	var direction := segment / sqrt(length_sq)
	var origin := from
	for i in MAX_HITS:
		var hit: Dictionary = intersect_ray.call(origin, to)
		if hit.is_empty():
			break
		var collider: Object = hit.get("collider")
		if collider is CollisionObject3D and collider not in blockers:
			blockers.append(collider)
		origin = hit.position + direction * RAY_EPSILON
		if origin.distance_to(to) <= RAY_EPSILON:
			break
	return blockers
