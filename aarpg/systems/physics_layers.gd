class_name PhysicsLayers extends RefCounted

const WORLD: int = 1
const COMBAT: int = 2
const PLAYER_BODY: int = 4
const ENEMY: int = 8

const WORLD_MASK: int = WORLD
const ENEMY_MASK: int = ENEMY
const COMBAT_TARGET_MASK: int = WORLD | COMBAT | ENEMY
