class_name GrassInteractors extends RefCounted

const MAX_INTERACTORS := 8

static func collect(
	params: GrassParams,
	sort_origin: Vector3,
	tree: SceneTree,
	editor_preview: bool,
	editor_origin: Vector3
) -> Dictionary:
	var positions := PackedVector3Array()
	var radii := PackedFloat32Array()
	positions.resize(MAX_INTERACTORS)
	radii.resize(MAX_INTERACTORS)
	var count := 0

	if Engine.is_editor_hint() and editor_preview:
		if count < MAX_INTERACTORS:
			positions[count] = editor_origin
			radii[count] = params.interactor_radius
			count += 1
	elif tree != null:
		var player := PlayerUtils.instance()
		if is_instance_valid(player) and count < MAX_INTERACTORS:
			positions[count] = player.global_position
			radii[count] = params.interactor_radius
			count += 1

		var enemies: Array[Node3D] = []
		for node: Node in tree.get_nodes_in_group(EnemyPaths.GROUP):
			if node is Node3D:
				enemies.append(node as Node3D)
		enemies.sort_custom(func(a: Node3D, b: Node3D) -> bool:
			return a.global_position.distance_squared_to(sort_origin) < b.global_position.distance_squared_to(sort_origin)
		)
		var enemy_slots := mini(enemies.size(), params.max_enemy_interactors)
		for i in enemy_slots:
			if count >= MAX_INTERACTORS:
				break
			var enemy := enemies[i] as Node3D
			positions[count] = enemy.global_position
			radii[count] = params.interactor_radius
			count += 1

	positions.resize(count)
	radii.resize(count)
	return {"count": count, "positions": positions, "radii": radii}
