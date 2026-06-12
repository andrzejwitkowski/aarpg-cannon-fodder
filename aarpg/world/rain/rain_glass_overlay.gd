@tool
class_name RainGlassOverlay extends CanvasLayer

const GROUP := &"rain_glass_overlay"
const GLASS_SHADER := preload("res://assets/shaders/rain/rain_glass.gdshader")

const INTENSITY_EPSILON := 0.01

@export var params: RainParams:
	set(v):
		_disconnect_params()
		params = v if v != null else RainParams.new()
		if _params_ready():
			_connect_params()
			_push_shader_uniforms()

@export var always_active: bool = false:
	set(v):
		always_active = v
		_apply_intensity()
		_push_shader_uniforms()

@export_category("Editor Preview")
@export_range(0.0, 1.0, 0.01) var editor_preview_intensity: float = 0.0:
	set(v):
		editor_preview_intensity = clampf(v, 0.0, 1.0)
		_apply_intensity()
		_push_shader_uniforms()

var _glass_rect: ColorRect
var _material: ShaderMaterial
var _contributions: Dictionary = {}
var _target_intensity: float = 0.0
var _display_intensity: float = 0.0
var _last_emitted_intensity: float = -1.0
var _time_elapsed: float = 0.0

func _ready() -> void:
	add_to_group(GROUP)
	layer = 100
	process_priority = -100
	follow_viewport_enabled = true
	if params == null:
		params = RainParams.new()
	_ensure_nodes()
	if _params_ready():
		_connect_params()
	_apply_intensity()
	_push_shader_uniforms()

func _exit_tree() -> void:
	_disconnect_params()

func _process(delta: float) -> void:
	_time_elapsed += delta
	_aggregate_intensity()
	_update_display_intensity(delta)
	_apply_intensity()
	_push_shader_uniforms()

func register_emitter_intensity(emitter_id: int, value: float) -> void:
	_contributions[emitter_id] = clampf(value, 0.0, 1.0)

func set_rain_intensity(value: float) -> void:
	_target_intensity = clampf(value, 0.0, 1.0)
	_display_intensity = _target_intensity
	_apply_intensity()
	_push_shader_uniforms()

func get_rain_intensity() -> float:
	return _target_intensity

func _shader_intensity() -> float:
	if always_active:
		return 1.0
	if Engine.is_editor_hint() and editor_preview_intensity > INTENSITY_EPSILON:
		return editor_preview_intensity
	return _display_intensity

func _params_ready() -> bool:
	return RainParams.is_instance_ready(params)

func _ensure_nodes() -> void:
	_glass_rect = get_node_or_null("GlassRect") as ColorRect
	if _glass_rect == null:
		_glass_rect = ColorRect.new()
		_glass_rect.name = "GlassRect"
		_glass_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_glass_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_glass_rect)
	_glass_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	if _glass_rect.material is ShaderMaterial:
		_material = _glass_rect.material as ShaderMaterial
	elif _material == null:
		_material = ShaderMaterial.new()
		_material.shader = GLASS_SHADER
		_glass_rect.material = _material

func _connect_params() -> void:
	if not _params_ready():
		return
	if not params.params_changed.is_connected(_on_params_changed):
		params.params_changed.connect(_on_params_changed)

func _disconnect_params() -> void:
	if params != null and params.params_changed.is_connected(_on_params_changed):
		params.params_changed.disconnect(_on_params_changed)

func _on_params_changed() -> void:
	_push_shader_uniforms()

func _aggregate_intensity() -> void:
	if _contributions.is_empty():
		return
	var max_intensity := 0.0
	for value: float in _contributions.values():
		max_intensity = maxf(max_intensity, value)
	_contributions.clear()
	_target_intensity = max_intensity

func _update_display_intensity(delta: float) -> void:
	if always_active:
		_display_intensity = 1.0
		_emit_intensity_if_changed()
		return
	if Engine.is_editor_hint() and editor_preview_intensity > INTENSITY_EPSILON:
		_display_intensity = editor_preview_intensity
		return
	var fade := clampf(params.overlay_fade_speed * delta, 0.0, 1.0)
	_display_intensity = lerpf(_display_intensity, _target_intensity, fade)
	_emit_intensity_if_changed()

func _emit_intensity_if_changed() -> void:
	if Engine.is_editor_hint():
		return
	if absf(_display_intensity - _last_emitted_intensity) <= INTENSITY_EPSILON:
		return
	EventBus.rain_intensity_changed.emit(_display_intensity)
	_last_emitted_intensity = _display_intensity

func _apply_intensity() -> void:
	if _glass_rect == null:
		return
	var intensity := _shader_intensity()
	_glass_rect.visible = always_active or intensity > INTENSITY_EPSILON

func _push_shader_uniforms() -> void:
	if _material == null or not _params_ready():
		return
	var intensity := _shader_intensity()
	_material.set_shader_parameter("rain_intensity", intensity)
	_material.set_shader_parameter("time", _time_elapsed)
	_material.set_shader_parameter("drop_density", params.drop_density)
	_material.set_shader_parameter("streak_speed", params.streak_speed)
	_material.set_shader_parameter("distortion_strength", params.distortion_strength * intensity)
	_material.set_shader_parameter("blur_lod", params.blur_lod * intensity)
	_material.set_shader_parameter("condensation_strength", params.condensation_strength * intensity)
	_material.set_shader_parameter("impact_rate", params.impact_rate)
