class_name EnemyFsm extends Node

const STATE_IDLE := &"idle"
const STATE_HIT := &"hit"
const STATE_CHASE := &"chase"
const STATE_DEATH := &"death"

@export var idle_state: EnemyState
@export var hit_state: EnemyState
@export var chase_state: EnemyState
@export var death_state: EnemyState

var context: EnemyContext
var current_state_name: StringName = STATE_IDLE

var _states: Dictionary = {}
var _enemy: EnemyBase

func setup(enemy: EnemyBase, ctx: EnemyContext) -> void:
	_enemy = enemy
	context = ctx
	_states[STATE_IDLE] = idle_state if idle_state != null else EnemyIdleState.new()
	_states[STATE_HIT] = hit_state if hit_state != null else EnemyHitState.new()
	_states[STATE_CHASE] = chase_state if chase_state != null else EnemyChaseState.new()
	_states[STATE_DEATH] = death_state if death_state != null else EnemyDeathState.new()
	_change_state(STATE_IDLE)

func notify_hurt(by: Node, damage: float) -> void:
	if context == null:
		return
	context.last_hit_by = by
	context.last_damage = damage
	if _enemy != null:
		_enemy.play_animation(EnemyAnimNames.HIT)
		_enemy.trigger_hit_flash()
	if current_state_name != STATE_DEATH:
		_change_state(STATE_HIT)

func _physics_process(delta: float) -> void:
	var state: EnemyState = _states.get(current_state_name) as EnemyState
	if state == null:
		return
	var next: StringName = state.tick(context, delta)
	if next != &"":
		_change_state(next)

func _change_state(state_name: StringName) -> void:
	if state_name == current_state_name and current_state_name != STATE_IDLE:
		var same: EnemyState = _states.get(current_state_name) as EnemyState
		if same != null:
			same.exit(context)
			same.enter(context)
		return
	var previous: EnemyState = _states.get(current_state_name) as EnemyState
	if previous != null:
		previous.exit(context)
	current_state_name = state_name
	var next_state: EnemyState = _states.get(state_name) as EnemyState
	if next_state != null:
		next_state.enter(context)
