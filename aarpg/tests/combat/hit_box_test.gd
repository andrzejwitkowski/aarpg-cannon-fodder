extends GdUnitTestSuite

const __source = "res://combat/hit_box/hit_box.gd"

func test_is_hitbox_class() -> void:
	var packed := load("res://combat/hit_box/hit_box.tscn") as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	assert_object(scene).is_instanceof(HitBox)

func test_set_shape() -> void:
	var packed := load("res://combat/hit_box/hit_box.tscn") as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	add_child(scene)
	await await_idle_frame()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 2.0
	scene.set_shape(shape)
	var collider: CollisionShape3D = scene.get_node("CollisionShape3D")
	assert_object(collider.shape).is_same(shape)

func test_has_collision_shape_child() -> void:
	var packed := load("res://combat/hit_box/hit_box.tscn") as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	assert_bool(scene.has_node("CollisionShape3D")).is_true()
