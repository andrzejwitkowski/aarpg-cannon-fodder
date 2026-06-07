extends GdUnitTestSuite

const HIT_BOX_SCENE := "res://combat/hit_box/hit_box.tscn"

func test_uses_combat_target_mask_after_ready() -> void:
	var hit_box: HitBox = (load(HIT_BOX_SCENE) as PackedScene).instantiate()
	auto_free(hit_box)
	add_child(hit_box)
	await await_idle_frame()
	assert_int(hit_box.collision_mask).is_equal(PhysicsLayers.COMBAT_TARGET_MASK)

func test_idle_inactive() -> void:
	var hit_box: HitBox = (load(HIT_BOX_SCENE) as PackedScene).instantiate()
	auto_free(hit_box)
	add_child(hit_box)
	await await_idle_frame()
	assert_bool(hit_box.monitoring).is_false()
	assert_int(hit_box.collision_layer).is_equal(0)
