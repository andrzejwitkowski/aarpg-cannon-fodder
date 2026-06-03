class_name EnemyUtils extends RefCounted

static func instance_nearest(from: Vector3) -> Node3D:
	var tree := Engine.get_main_loop() as SceneTree
	var enemies := tree.get_nodes_in_group(EnemyPaths.GROUP)
	var best: Node3D = null
	var best_dist_sq := INF
	for node: Node in enemies:
		if node is Node3D:
			var enemy := node as Node3D
			var dist_sq := enemy.global_position.distance_squared_to(from)
			if dist_sq < best_dist_sq:
				best_dist_sq = dist_sq
				best = enemy
	return best
