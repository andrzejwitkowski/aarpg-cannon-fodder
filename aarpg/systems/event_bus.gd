extends Node

signal character_moved(new_position: Vector3)
signal hit_received(target: Node, by: Node, damage: float)
signal enemy_hit(enemy: Node, by: Node, damage: float)
signal rain_intensity_changed(intensity: float)
signal rain_zone_entered(zone: Node)
signal rain_zone_exited(zone: Node)
