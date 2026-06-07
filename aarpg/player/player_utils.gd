class_name PlayerUtils
extends RefCounted

const GROUP := &"player"

static func instance() -> CharacterBody3D:
	var tree := Engine.get_main_loop() as SceneTree
	var players := tree.get_nodes_in_group(GROUP)
	return players[0] if players.size() > 0 else null

static func from_node(node: Node) -> CharacterBody3D:
	var current: Node = node
	while current != null:
		if current.is_in_group(GROUP) and current is CharacterBody3D:
			return current as CharacterBody3D
		current = current.get_parent()
	return null

static func global_position() -> Vector3:
	var p := instance()
	return p.global_position if p else Vector3.ZERO

static func rotate_player(x: float, y: float, z: float) -> void:
	var p := instance()
	if p:
		p.rotate_x(deg_to_rad(x))
		p.rotate_y(deg_to_rad(y))
		p.rotate_z(deg_to_rad(z))
