class_name RainVisibility extends RefCounted

static func is_aabb_in_frustum(camera: Camera3D, aabb: AABB) -> bool:
	if camera == null or aabb.size == Vector3.ZERO:
		return false
	var half := aabb.size * 0.5
	var center := aabb.position + half
	if camera.is_position_in_frustum(center):
		return true
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var corner := center + Vector3(half.x * sx, half.y * sy, half.z * sz)
				if camera.is_position_in_frustum(corner):
					return true
	return false

static func distance_factor(camera_pos: Vector3, target_pos: Vector3, max_distance: float) -> float:
	if max_distance <= 0.0:
		return 0.0
	if camera_pos.distance_to(target_pos) >= max_distance:
		return 0.0
	return 1.0
