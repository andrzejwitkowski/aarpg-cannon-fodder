extends GdUnitTestSuite

func test_equip_finds_socket() -> void:
	var mount := WeaponMount.new()
	auto_free(mount)
	var sockets := Node3D.new()
	auto_free(sockets)
	var marker := Marker3D.new()
	marker.name = str(EnemyPaths.SOCKET_WEAPON_MAIN)
	sockets.add_child(marker)
	var weapon_scene := load("res://weapons/kinds/melee_weapon.tscn") as PackedScene
	var def := WeaponDefinition.new()
	def.scene = weapon_scene
	def.socket_name = EnemyPaths.SOCKET_WEAPON_MAIN
	var weapon := mount.equip(def, sockets)
	assert_object(weapon).is_not_null()
	assert_int(marker.get_child_count()).is_equal(1)
