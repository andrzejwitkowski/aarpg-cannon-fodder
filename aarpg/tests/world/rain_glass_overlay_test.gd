extends GdUnitTestSuite

const OVERLAY_SCENE := "res://world/rain/rain_glass_overlay.tscn"
const GLASS_SHADER := "res://assets/shaders/rain/rain_glass.gdshader"

func test_overlay_scene_loads() -> void:
	var packed := load(OVERLAY_SCENE) as PackedScene
	assert_object(packed).is_not_null()

func test_set_rain_intensity_updates_shader_uniform() -> void:
	var packed := load(OVERLAY_SCENE) as PackedScene
	var overlay := packed.instantiate() as RainGlassOverlay
	auto_free(overlay)
	overlay.always_active = false
	add_child(overlay)
	overlay.set_rain_intensity(0.5)
	var rect := overlay.get_node("GlassRect") as ColorRect
	var material := rect.material as ShaderMaterial
	assert_float(material.get_shader_parameter("rain_intensity")).is_equal(0.5)

func test_zero_intensity_hides_overlay() -> void:
	var packed := load(OVERLAY_SCENE) as PackedScene
	var overlay := packed.instantiate() as RainGlassOverlay
	auto_free(overlay)
	overlay.always_active = false
	add_child(overlay)
	overlay.set_rain_intensity(0.0)
	var rect := overlay.get_node("GlassRect") as ColorRect
	assert_bool(rect.visible).is_false()

func test_register_emitter_intensity_takes_max() -> void:
	var packed := load(OVERLAY_SCENE) as PackedScene
	var overlay := packed.instantiate() as RainGlassOverlay
	auto_free(overlay)
	overlay.always_active = false
	add_child(overlay)
	overlay.register_emitter_intensity(1, 0.2)
	overlay.register_emitter_intensity(2, 0.7)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(overlay.get_rain_intensity()).is_equal(0.7)

func test_always_active_keeps_overlay_visible() -> void:
	var packed := load(OVERLAY_SCENE) as PackedScene
	var overlay := packed.instantiate() as RainGlassOverlay
	auto_free(overlay)
	overlay.always_active = true
	add_child(overlay)
	overlay.set_rain_intensity(0.0)
	var rect := overlay.get_node("GlassRect") as ColorRect
	var material := rect.material as ShaderMaterial
	assert_bool(rect.visible).is_true()
	assert_float(material.get_shader_parameter("rain_intensity")).is_equal(1.0)

func test_display_intensity_fades_toward_target() -> void:
	var packed := load(OVERLAY_SCENE) as PackedScene
	var overlay := packed.instantiate() as RainGlassOverlay
	auto_free(overlay)
	overlay.always_active = false
	overlay.params.overlay_fade_speed = 8.0
	add_child(overlay)
	var rect := overlay.get_node("GlassRect") as ColorRect
	var material := rect.material as ShaderMaterial
	var start_intensity := material.get_shader_parameter("rain_intensity") as float
	for _i in 60:
		overlay.register_emitter_intensity(1, 1.0)
		await get_tree().process_frame
	var end_intensity := material.get_shader_parameter("rain_intensity") as float
	assert_float(overlay.get_rain_intensity()).is_equal(1.0)
	assert_float(end_intensity).is_greater(start_intensity)
	assert_float(end_intensity).is_equal_approx(1.0, 0.08)

func test_glass_shader_loads() -> void:
	var shader := load(GLASS_SHADER) as Shader
	assert_object(shader).is_not_null()

func test_glass_shader_compiles() -> void:
	var loaded := load(GLASS_SHADER) as Shader
	assert_object(loaded).is_not_null()
	var material := ShaderMaterial.new()
	material.shader = loaded
	assert_object(material.shader).is_same(loaded)
