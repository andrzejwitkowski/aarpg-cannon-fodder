extends GdUnitTestSuite

func test_hit_state_returns_to_idle() -> void:
	var hit := EnemyHitState.new()
	hit.hit_duration = 0.05
	var ctx := EnemyContext.new()
	hit.enter(ctx)
	var next := hit.tick(ctx, 0.1)
	assert_str(next).is_equal(EnemyFsm.STATE_IDLE)

func test_fsm_transitions_to_hit_on_notify() -> void:
	var enemy_packed := load(EnemyPaths.DUMMY_SCENE) as PackedScene
	var enemy: EnemyBase = enemy_packed.instantiate()
	auto_free(enemy)
	add_child(enemy)
	await await_idle_frame()
	enemy.fsm.notify_hurt(enemy, 0.0)
	assert_str(enemy.fsm.current_state_name).is_equal(EnemyFsm.STATE_HIT)
