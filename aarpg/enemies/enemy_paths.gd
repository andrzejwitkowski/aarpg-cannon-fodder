class_name EnemyPaths extends RefCounted

const GROUP := &"enemies"
const BASE_SCENE := "res://enemies/enemy_base.tscn"
const DUMMY_SCENE := "res://enemies/types/dummy/dummy_enemy.tscn"

const SOCKET_WEAPON_MAIN := &"Socket_WeaponMain"
const SOCKET_WEAPON_OFF := &"Socket_WeaponOff"
const SOCKET_THROWABLE := &"Socket_Throwable"

static func hurt_box_relative() -> String:
	return "Body/HurtBox"
