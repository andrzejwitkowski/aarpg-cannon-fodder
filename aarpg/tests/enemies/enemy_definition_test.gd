extends GdUnitTestSuite

func test_resolve_anim_returns_extra_or_shared() -> void:
	var def := EnemyDefinition.new()
	def.extra_anim_names = PackedStringArray(["special_attack"])
	assert_str(def.resolve_anim(&"special_attack")).is_equal("special_attack")
	assert_str(def.resolve_anim(EnemyAnimNames.IDLE)).is_equal("idle")

func test_resolve_anim_falls_back_to_idle() -> void:
	var def := EnemyDefinition.new()
	assert_str(def.resolve_anim(&"unknown_anim")).is_equal("idle")
