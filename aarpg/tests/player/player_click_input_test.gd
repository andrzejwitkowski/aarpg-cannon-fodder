extends GdUnitTestSuite

const CLICK_INPUT_SCRIPT := "res://player/player_click_input.gd"
const PLAYER_SCENE := "res://player/player.tscn"
const WORLD_SCENE := "res://world/test_scene.tscn"

func test_pick_ground_hits_static_body() -> void:
	var packed := load(WORLD_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	add_child(scene)
	await await_idle_frame()
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var player: CharacterBody3D = scene.get_node("Player")
	var click_input: Node = player.get_node("ClickInput")
	var screen_center := get_viewport().get_visible_rect().size * 0.5
	var hit: Variant = click_input.pick_ground_from_screen(screen_center)
	assert_that(hit).is_not_null()
	assert_that(hit is Vector3).is_true()
	var ground: StaticBody3D = scene.get_node("NavigationRegion3D/Ground/GroundStaticBody")
	assert_int(ground.collision_layer).is_equal(PhysicsLayers.WORLD)

func test_pick_ground_ignores_non_static_collider() -> void:
	var root := Node3D.new()
	auto_free(root)
	add_child(root)
	var obstacle := CharacterBody3D.new()
	obstacle.collision_layer = PhysicsLayers.WORLD
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	collider.shape = capsule
	obstacle.add_child(collider)
	root.add_child(obstacle)
	var camera := Camera3D.new()
	camera.current = true
	root.add_child(camera)
	camera.global_position = Vector3(0.0, 5.0, 5.0)
	camera.look_at(obstacle.global_position)
	var click_input := Node.new()
	click_input.set_script(load(CLICK_INPUT_SCRIPT) as Script)
	obstacle.add_child(click_input)
	await await_idle_frame()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var screen_center := get_viewport().get_visible_rect().size * 0.5
	assert_that(click_input.pick_ground_from_screen(screen_center)).is_null()

func test_click_sets_navigation_target() -> void:
	var packed := load(WORLD_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	add_child(scene)
	await await_idle_frame()
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var player: CharacterBody3D = scene.get_node("Player")
	var nav: NavigationAgent3D = player.get_node("NavigationAgent3D")
	var initial_target := nav.target_position
	var click_input: Node = player.get_node("ClickInput")
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = get_viewport().get_visible_rect().size * 0.5
	click_input._unhandled_input(event)
	assert_bool(player._is_moving_to_target).is_true()
	assert_vector(nav.target_position).is_not_equal(initial_target)
	assert_float(player._target_position.y).is_equal(player.global_position.y)

func test_pick_on_plane_reaches_mesh_edge() -> void:
	var packed := load(WORLD_SCENE) as PackedScene
	var scene := packed.instantiate()
	auto_free(scene)
	add_child(scene)
	await await_idle_frame()
	await get_tree().physics_frame
	var player: CharacterBody3D = scene.get_node("Player")
	var ground: MeshInstance3D = scene.get_node("NavigationRegion3D/Ground")
	var click_input: Node = player.get_node("ClickInput")
	var plane := ground.mesh as PlaneMesh
	var edge_local := Vector3(plane.size.x * 0.5 - 0.5, 0.0, 0.0)
	var edge_global: Vector3 = ground.global_transform * edge_local
	var camera: Camera3D = scene.get_node("Camera3D")
	var screen_pos: Vector2 = camera.unproject_position(edge_global)
	var hit: Variant = click_input.pick_ground_from_screen(screen_pos)
	assert_that(hit).is_not_null()
	assert_vector(hit as Vector3).is_equal_approx(edge_global, Vector3(1.5, 0.5, 1.5))

func test_click_ignores_sky_without_move() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	var scene: CharacterBody3D = packed.instantiate()
	auto_free(scene)
	add_child(scene)
	var camera := Camera3D.new()
	camera.current = true
	scene.add_child(camera)
	camera.global_position = Vector3(0.0, 10.0, 10.0)
	camera.look_at(scene.global_position)
	await await_idle_frame()
	var click_input: Node = scene.get_node("ClickInput")
	var nav: NavigationAgent3D = scene.get_node("NavigationAgent3D")
	var initial_target := nav.target_position
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(-1.0, -1.0)
	click_input._unhandled_input(event)
	assert_bool(scene._is_moving_to_target).is_false()
	assert_vector(nav.target_position).is_equal(initial_target)
