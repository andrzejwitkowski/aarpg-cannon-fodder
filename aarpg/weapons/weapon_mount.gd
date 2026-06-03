class_name WeaponMount extends Node

var _equipped: Dictionary = {}

func equip(definition: WeaponDefinition, sockets_root: Node3D) -> WeaponBase:
	if definition == null or definition.scene == null:
		return null
	var socket := sockets_root.find_child(str(definition.socket_name), true, false) as Node3D
	if socket == null:
		return null
	unequip(definition.socket_name)
	var weapon := definition.scene.instantiate() as WeaponBase
	if weapon == null:
		return null
	weapon.definition = definition
	socket.add_child(weapon)
	_equipped[definition.socket_name] = weapon
	return weapon

func unequip(socket_name: StringName) -> void:
	var existing: WeaponBase = _equipped.get(socket_name) as WeaponBase
	if existing != null and is_instance_valid(existing):
		existing.queue_free()
	_equipped.erase(socket_name)

func get_weapon(socket_name: StringName) -> WeaponBase:
	return _equipped.get(socket_name) as WeaponBase
