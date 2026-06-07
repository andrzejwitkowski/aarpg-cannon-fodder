extends GdUnitTestSuite

const CLUB_SCENE := "res://weapons/kinds/club/club.tscn"

func test_swing_enables_hitbox() -> void:
	var club: Club = (load(CLUB_SCENE) as PackedScene).instantiate()
	auto_free(club)
	add_child(club)
	await await_idle_frame()
	club.swing()
	assert_bool(club.hit_box.monitoring).is_true()

func test_idle_hitbox_off() -> void:
	var club: Club = (load(CLUB_SCENE) as PackedScene).instantiate()
	auto_free(club)
	add_child(club)
	await await_idle_frame()
	assert_bool(club.hit_box.monitoring).is_false()

func test_swing_finishes_idle() -> void:
	var club: Club = (load(CLUB_SCENE) as PackedScene).instantiate()
	auto_free(club)
	add_child(club)
	await await_idle_frame()
	club.swing()
	await await_millis(250)
	assert_bool(club.hit_box.monitoring).is_false()
