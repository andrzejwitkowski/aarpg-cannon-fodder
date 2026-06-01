extends GdUnitTestSuite

const CAMERA_SCENE = "res://camera/camera_controller.gd"

func test_has_exported_offset() -> void:
	var camera: Camera3D = auto_free(Camera3D.new())
	camera.set_script(load(CAMERA_SCENE) as Script)
	assert_vector(camera.offset).is_equal(Vector3(0.0, 14.0, 8.0))

func test_has_exported_follow_speed() -> void:
	var camera: Camera3D = auto_free(Camera3D.new())
	camera.set_script(load(CAMERA_SCENE) as Script)
	assert_float(camera.follow_speed).is_equal(5.0)

func test_process_returns_early_without_target() -> void:
	var camera: Camera3D = auto_free(Camera3D.new())
	camera.set_script(load(CAMERA_SCENE) as Script)
	add_child(camera)
	await await_idle_frame()
