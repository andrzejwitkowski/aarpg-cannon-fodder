extends Node

signal character_moved(new_position: Vector3)
signal hit_received(target: Node, by: Node, damage: float)
signal enemy_hit(enemy: Node, by: Node, damage: float)
